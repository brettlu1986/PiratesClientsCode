local BattleTeamSystem = {}

local BattleAdditionalSuccessResultDef = require("BattleAdditionalSuccessResultDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleTeamCategoryDefine = require("BattleTeamCategoryDefine")
local BattlePrepareSystem = dynamic_require("BattlePrepareSystem")
local HumanMovementStateType = require("HumanMovementStateType")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BotAISystem  = dynamic_require("BotAISystem")
local SelfEventHelper = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local Proto = require("DungeonCommonProtoNames")
local HumanDataTable = require("HumanDataTable")
local CampDef = require("CampDefine")
local Timer = require("Timer")

local EState = Proto.TeamInfo_EState
local ECategoryType = BattleTeamCategoryDefine.tbCategoryType

local STATE_PRIORITY =
{
    [EState.NONE] = 1,
    [EState.DRIVING] = 1,
    [EState.INPLANE] = 1,
    [EState.PARACHUTING] = 1,
    [EState.ADDITIONALSUCCESS] = 1,
    [EState.DYING] = 1,
    [EState.OFFLINE] = 2,
    [EState.DEAD] = 3,
}

local nDefaultTeamId = 0
local SYNC_INTERVAL = 1

BattleTeamSystem.EventHelper    = nil
BattleTeamSystem.tbRefreshTimer = nil
BattleTeamSystem.tbTeams        = nil

BattleTeamSystem.tbInstanceId2HPFuncMap = nil
BattleTeamSystem.tbVehicleInstanceIdMap = nil

--人数多的队伍往前排，同一队伍的按照时间戳排序
--如果中间有机器人，则机器人排在最后
local function SortPlayerIds(tbPlayerIds)
    local tbTempData = {}
    local nCount = #tbPlayerIds

    local tbBotPlayerIds = {}

    for i = 1, nCount do
        local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(tbPlayerIds[i])
        if tbPrepareInfo then
           local szLobbyTeamInfo = tbPrepareInfo.szLobbyTeamInfo
           local nLobbyJoinTime  = tbPrepareInfo.nLobbyJoinTime

           if not szLobbyTeamInfo or
              not nLobbyJoinTime  or
              string.len(szLobbyTeamInfo) <= 0 or
              nLobbyJoinTime <= 0 then
                table.insert(tbBotPlayerIds, tbPlayerIds[i])
            else
                tbTempData[szLobbyTeamInfo] = tbTempData[szLobbyTeamInfo] or {}
                local tbCurTeam = tbTempData[szLobbyTeamInfo]
                local nCurTeamCount = #tbCurTeam
                local nInsertIndex = 1
                for j = 1, nCurTeamCount do
                    if tbCurTeam[j].nLobbyJoinTime > nLobbyJoinTime then
                        break
                    else
                        nInsertIndex = nInsertIndex + 1
                    end
                end
                local tbInsertData = {}
                tbInsertData.nLobbyJoinTime = nLobbyJoinTime
                tbInsertData.nIndex = i
                table.insert(tbCurTeam, nInsertIndex, tbInsertData)
            end
        else
            table.insert(tbBotPlayerIds, tbPlayerIds[i])
        end
    end

    local tbStatData = {}
    for k, v in pairs(tbTempData) do
        local curData = {}
        curData.szLobbyTeamInfo = k
        curData.nLobbyTeamMemberCount = #v
        table.insert(tbStatData, curData)
    end
    table.sort(tbStatData, function(a, b) return (a.nLobbyTeamMemberCount > b.nLobbyTeamMemberCount) end) --降序排序
    local tbRetPlayerIds = {}

    local nStatDataCount = #tbStatData
    for i = 1, nStatDataCount do
        local tbIndexArr = tbTempData[tbStatData[i].szLobbyTeamInfo]
        local nIndexCount = #tbIndexArr

        for j = 1, nIndexCount do
            local nCurIndex = tbIndexArr[j].nIndex
            table.insert(tbRetPlayerIds, tbPlayerIds[nCurIndex])
        end
    end

    --Append Bot
    local nBotCount = #tbBotPlayerIds
    for i = 1, nBotCount do
        table.insert(tbRetPlayerIds, tbBotPlayerIds[i])
    end

    return tbRetPlayerIds
end

local function GetBPTeamSystem()
    return GameplayStatics.GetGameState(GWorld).TeamSystem
end

local function GetMemberIndexInTeam(tbTeam, tbGamePlayer)
    local tbGameObjects = tbTeam.tbGameObjects
    local nCount = #tbGameObjects
    for i=1, nCount do
        if(tbGameObjects[i] == tbGamePlayer) then
            return i
        end
    end
    return -1
end

local function TryAppendBaseInfoByPlayerId(tbInfos, nPlayerId)
    for _, tbCurInfo in pairs(tbInfos) do
        if tbCurInfo.nPlayerId == nPlayerId then
            return
        end
    end

    local tbCurInfo = {}
    local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)

    tbCurInfo.nPlayerId   = nPlayerId
    tbCurInfo.name        = tbPrepareInfo.szPlayerName
    tbCurInfo.bIsBot      = tbPrepareInfo:IsBot()
    local tbHumanTemplate = HumanDataTable:GetTemplate(tbPrepareInfo.nHumanId)
    if tbHumanTemplate then
        tbCurInfo.nGenderType = tbHumanTemplate.nGender
    end
    table.insert(tbInfos, tbCurInfo)
end

local function TryRemoveBaseInfoByPlayerId(tbInfos, nPlayerId)
    for nIndex, tbCurInfo in pairs(tbInfos) do
        if tbCurInfo.nPlayerId == nPlayerId then
            table.remove(tbInfos, nIndex)
            return
        end
    end
end

local function InitNewTeamByTeamId(tbTeam, nTeamId)
    tbTeam.nTeamId             = nTeamId
    tbTeam.tbPlayerIds         = {}
    tbTeam.tbSortedBaseInfos   = {}
    tbTeam.tbGameObjects       = {}
    tbTeam.tbInstanceIds       = {}
    tbTeam.tbTeamData          = {}
    tbTeam.nPlayerCount        = 0

    local tbPlayerIds = BattlePrepareSystem:GetPlayerIdsByGroupIndex(nTeamId)
    if tbPlayerIds then
        tbTeam.nPlayerCount      = #tbPlayerIds
        local tbSortedPlayerIds  = SortPlayerIds(tbPlayerIds)
        
        for _, nPlayerId in pairs(tbSortedPlayerIds) do
            TryAppendBaseInfoByPlayerId(tbTeam.tbSortedBaseInfos, nPlayerId)
        end
    end
end

local function GetOrAddTeamByTeamId(self, nTeamId)
    local tbTeam = self.tbTeams[nTeamId]
    if(tbTeam == nil) then
        tbTeam = {}
        InitNewTeamByTeamId(tbTeam, nTeamId)
        self.tbTeams[nTeamId] = tbTeam
    end

    return tbTeam
end

local function GetTeamByGamePlayer(self, tbGamePlayer)
    local nTeamId = self:FindTeamId(tbGamePlayer)
    return self.tbTeams[nTeamId]
end

local function GetPlayerData(self, tbGamePlayer, tbTeamData)
    local nInstanceId = tbGamePlayer:GetServerInstanceId()
    for Key, Value in pairs(tbTeamData) do
        if Value.nInstanceId == nInstanceId then
            return Value
        end
    end

    return nil
end

local function GetPlayerDataByPlayer(self, tbPlayer)
    local tbTeam = GetTeamByGamePlayer(self, tbPlayer)
    if tbTeam then
        return GetPlayerData(self, tbPlayer, tbTeam.tbTeamData)
    end
    
    return nil
end

local function LogErrorGetPlayerData(nInstanceId)
    logerror("GetPlayerDataByPlayer return nil, nInstanceId:", nInstanceId)
end

function BattleTeamSystem:GetDataByTeamId(nTeamId)
    return self.tbTeams[nTeamId]
end

local function NotifyAllTeammateDataChanged(self, tbGamePlayer, eCategoryType)
    if(GlobalVariableSystem:IsServerLogic()) then
        local tbTeam = GetTeamByGamePlayer(self, tbGamePlayer)
        if tbTeam then
            local tbGameObjects = tbTeam.tbGameObjects
            for _, tbCurPlayer in pairs(tbGameObjects) do
                if tbCurPlayer then
                    tbCurPlayer.BattleTeamComponent:OnDataChanged(eCategoryType)
                end
            end
        end
    end
end

local function RefreshPlayerInfo(self, tbPlayerData, tbGamePlayer, eCategoryType)
    if eCategoryType & ECategoryType.HealthInfo > 0 then
        if tbGamePlayer:IsHuman() then
            tbPlayerData.nHp = math.floor(tbGamePlayer.HumanBattlePropertyComponent:GetHp())
            tbPlayerData.nMaxHp = math.floor(tbGamePlayer.HumanBattlePropertyComponent:GetMaxHp())
        else
            tbPlayerData.nHp = math.floor(tbGamePlayer.ShipBattlePropertyComponent:GetHp())
            tbPlayerData.nMaxHp = math.floor(tbGamePlayer.ShipBattlePropertyComponent:GetMaxHp())
        end
    end

    if eCategoryType & ECategoryType.PosInfo > 0 then
        local X, Y, Z = EngineExtActorShell.GetActorLocationXYZ(tbGamePlayer.pUEActor)
        local Yaw     = EngineExtActorShell.GetActorRotationYawPitchRoll(tbGamePlayer.pUEActor)

        tbPlayerData.nPlayerX   = math.floor(X)
        tbPlayerData.nPlayerY   = math.floor(Y)
        tbPlayerData.nPlayerZ   = math.floor(Z)
        tbPlayerData.nPlayerYaw = math.floor(Yaw)
    end
end

local function AddBaseInfoToPlayerData(self, tbGamePlayer, tbTeam, tbPlayerData)
    local tbSortedBaseInfos = tbTeam.tbSortedBaseInfos
    local nPlayerId = tbGamePlayer:GetPlayerId()

    local bFound = false
    for _, tbCurInfo in pairs(tbSortedBaseInfos) do
        if tbCurInfo.nPlayerId == nPlayerId then
            bFound = true
            for Key, Value in pairs(tbCurInfo) do
                tbPlayerData[Key] = Value
            end
            break
        end
    end
    
    if not bFound then
        error("BattleTeamSystem:AddBaseInfoToPlayerData Player not found. ".. nPlayerId)
    end
end

--添加玩家的基础信息到TeamData中
local function AddMemmberToTeamData(self, tbTeam, tbGamePlayer)
    local tbPlayerData = {}
    tbPlayerData.nInstanceId = tbGamePlayer:GetServerInstanceId()
    tbPlayerData.nPlayerId   = tbGamePlayer:GetPlayerId()
    tbPlayerData.nState      = EState.NONE
    tbPlayerData.nVehicleId  = 0

    AddBaseInfoToPlayerData(self, tbGamePlayer, tbTeam, tbPlayerData)

    table.insert(tbTeam.tbTeamData, tbPlayerData)
    RefreshPlayerInfo(self, tbPlayerData, tbGamePlayer, ECategoryType.PosInfo | ECategoryType.HealthInfo)
end

local function RemoveMemberFromTeamData(self, tbTeamData, tbGamePlayer)
    local nInstanceId = tbGamePlayer:GetServerInstanceId()
    for Key, Value in pairs(tbTeamData) do
        if Value.nInstanceId == nInstanceId then
            table.remove( tbTeamData, Key )
            return
        end
    end
end

local function AddMemberToTeam(self, tbTeam, tbGamePlayer)
    local nIndex = GetMemberIndexInTeam(tbTeam, tbGamePlayer)
    if(nIndex > 0) then
        logerror("BattleTeamSystem:AddMemberToTeam failed, has duplicated player",
        tbTeam.nTeamId, tbGamePlayer:GetUEActorUniqueId())
        return false
    end

    local nUniqueId = tbGamePlayer.nUniqueId
    local nTeamId = tbTeam.nTeamId
    local nServerInstanceId = tbGamePlayer.nServerInstanceId
    local nPlayerId = tbGamePlayer.nPlayerId
    table.insert(tbTeam.tbGameObjects, tbGamePlayer)       -- 这个是为了访问方便
    assert(nPlayerId ~= nil, "BattleTeamSystem::AddMemberToTeam error. Game player id nil")
    table.insert(tbTeam.tbPlayerIds, nPlayerId)            -- 这个是为了结算
    table.insert(tbTeam.tbInstanceIds, nServerInstanceId)  -- 这个是为了同步

    TryAppendBaseInfoByPlayerId(tbTeam.tbSortedBaseInfos, nPlayerId)

    AddMemmberToTeamData(self, tbTeam, tbGamePlayer)

    -- 需要先往蓝图刷，再调BattleTeamComponent，因为BattleTeamComponent会发TeamIDChanged事件
    GetBPTeamSystem():AddMemberToTeam(nServerInstanceId, nTeamId)
    tbGamePlayer.BattleTeamComponent:AddToTeam(nTeamId)
    tbGamePlayer.BattleTeamComponent:SetTeamData(tbTeam)

    NotifyAllTeammateDataChanged(self, tbGamePlayer, ECategoryType.All)

    log("AddMemberToTeam TeamId:", nTeamId, "ServerInstanceId:", nServerInstanceId, tbGamePlayer.szName, nUniqueId, nPlayerId)
    return true
end

local function RemoveMemberFromTeam(self, tbTeam, tbGamePlayer)
    local nIndex = GetMemberIndexInTeam(tbTeam, tbGamePlayer)
    if(nIndex < 0) then
        logerror("BattleTeamSystem:RemoveMemberFromTeam failed, can not find player",
                tbTeam.nTeamId, tbGamePlayer:GetUEActorUniqueId())
        return false
    end

    local nUniqueId = tbGamePlayer.nUniqueId
    local nTeamId = tbTeam.nTeamId
    local nPlayerId = tbGamePlayer.nPlayerId
    local nServerInstanceId = tbGamePlayer.nServerInstanceId

    table.remove(tbTeam.tbGameObjects, nIndex)
    table.remove(tbTeam.tbInstanceIds, nIndex)
    table.remove(tbTeam.tbPlayerIds,   nIndex)

    TryRemoveBaseInfoByPlayerId(tbTeam.tbSortedBaseInfos, nPlayerId)

    RemoveMemberFromTeamData(self, tbTeam.tbTeamData, tbGamePlayer)

    GetBPTeamSystem():RemoveMemberFromTeam(nServerInstanceId, nTeamId)

    if #tbTeam.tbGameObjects > 0 then
        NotifyAllTeammateDataChanged(self, tbTeam.tbGameObjects[1], ECategoryType.All)
    end

    tbGamePlayer.BattleTeamComponent:RemoveFromTeam()

    log("RemoveMemberFromTeam", nTeamId, nServerInstanceId, nUniqueId, nPlayerId)
    return true
end

local function OnGameObjectPreDestroy(self, tbDestroyObject)
    local tbAllTeamsInfo = self:GetAllTeamInfo()
    for nTeamId, tbTeamInfo in pairs(tbAllTeamsInfo) do
        for _, tbObject in pairs(tbTeamInfo.tbGameObjects) do
            if tbDestroyObject == tbObject then
                log("BattleTeamSystem OnGameObjectPreDestroy remove tbObject", tbObject.nServerInstanceId, tbObject.nPlayerId, nTeamId)
                self:RemoveMember(tbObject, nTeamId)
                return
            end
        end
    end
end

local function OnFFAMapSign(self, tbPacket)
    local nInstanceId = tbPacket.nInstanceId
    local tbGamePlayer = GameObjectSystem:FindByInstanceId(nInstanceId)
    local tbPlayerData = GetPlayerDataByPlayer(self, tbGamePlayer)
    if not tbPlayerData then
        LogErrorGetPlayerData(nInstanceId)
        return
    end

    tbPlayerData.SignType = tbPacket.SignType
    tbPlayerData.nSignX   = math.floor(tbPacket.nX)
    tbPlayerData.nSignY   = math.floor(tbPacket.nY)

    NotifyAllTeammateDataChanged(self, tbGamePlayer, ECategoryType.SignInfo)
end

local function TeamStateChanged(self, tbPlayer, eState, nVehicleId, bIngnorePriority)
    local tbPlayerData = GetPlayerDataByPlayer(self, tbPlayer)
    if not tbPlayerData then
        LogErrorGetPlayerData(tbPlayer:GetServerInstanceId())
        return
    end

    if bIngnorePriority then
        tbPlayerData.nState = eState
    else
        if STATE_PRIORITY[tbPlayerData.nState] <= STATE_PRIORITY[eState] then
            tbPlayerData.nState = eState
        end
    end

    if nVehicleId then
        tbPlayerData.nVehicleId = nVehicleId
    end

    NotifyAllTeammateDataChanged(self, tbPlayer, ECategoryType.StateInfo)
end

local function OnPawnDyingChanged(self, tbPlayer, bIsDying)
    if bIsDying then
        TeamStateChanged(self, tbPlayer, EState.DYING)
    else
        if not tbPlayer:IsDead() then
            TeamStateChanged(self, tbPlayer, EState.NONE)
        end
    end
end

local function OnPawnDead(self, tbPlayer)
    if tbPlayer.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end

    TeamStateChanged(self, tbPlayer, EState.DEAD)
end

local function OnPlayerLogout(self, tbPlayer)
    TeamStateChanged(self, tbPlayer, EState.OFFLINE)
end

local function OnPlayerReLogin(self, tbPlayer)
    if not tbPlayer:IsDead() then
        if tbPlayer:IsDying() then
            TeamStateChanged(self, tbPlayer, EState.DYING, nil, true)
        else
            TeamStateChanged(self, tbPlayer, EState.NONE, nil, true)
        end
    else
        TeamStateChanged(self, tbPlayer, EState.DEAD, nil, true)
    end
end

local function OnAdditionalSuccessResult(self, nReturnCode, tbPlayer)
    if nReturnCode == BattleAdditionalSuccessResultDef.EXIT_BATTLE then
        TeamStateChanged(self, tbPlayer, EState.ADDITIONALSUCCESS)
    end
end

local function OnMovementStateChanged(self, tbCharacter, nOldState, nNewState)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end

    if tbCharacter:IsHuman() then
        if nNewState == HumanMovementStateType.InPlane_State then
            TeamStateChanged(self, tbCharacter, EState.INPLANE)
        elseif nNewState == HumanMovementStateType.Parachutine_State
            or nNewState == HumanMovementStateType.Falling_State
            or nNewState == HumanMovementStateType.Gliding_State then
            TeamStateChanged(self, tbCharacter, EState.PARACHUTING)
        elseif nNewState == HumanMovementStateType.Dying_State then
            TeamStateChanged(self, tbCharacter, EState.DYING)
        else
            if not tbCharacter:IsDead() then
                TeamStateChanged(self, tbCharacter, EState.NONE)
            end
        end
    end
end

local function OnEndChangeDisplay(self, tbPlayer)
    local tbPlayerData = GetPlayerDataByPlayer(self, tbPlayer)
    if not tbPlayerData then
        LogErrorGetPlayerData(tbPlayer:GetServerInstanceId())
        return
    end

    if tbPlayer:IsShip() and tbPlayerData.nState == EState.PARACHUTING then
        TeamStateChanged(self, tbPlayer, EState.NONE)
    end

    RefreshPlayerInfo(self, tbPlayerData, tbPlayer, ECategoryType.HealthInfo)
    NotifyAllTeammateDataChanged(self, tbPlayer, ECategoryType.HealthInfo)
end

local function OnParachutionEnd(self, tbPlayer, bIsShip, bIsTransport, pTransportLocation)
    self:DisablePlayerReplicate(tbPlayer)
end

local function OnVehicleStateChange(self, tbPlayer, nState, nVehicleInstanceId)
    if nState ~= HumanVehicleStateDef.AttachToVehicle and
       nState ~= HumanVehicleStateDef.DetachFromVehicle and
       nState ~= HumanVehicleStateDef.None then --上载具
        return
    end

    local nInstanceId = tbPlayer:GetServerInstanceId()
    local tbPlayerData = GetPlayerDataByPlayer(self, tbPlayer)
    if not tbPlayerData then
        LogErrorGetPlayerData(nInstanceId)
        return
    end

    if nState == HumanVehicleStateDef.AttachToVehicle then
        local nOldVehicleId = tbPlayerData.nVehicleId

        if nOldVehicleId > 0 then
            self.tbVehicleInstanceIdMap[nOldVehicleId] = self.tbVehicleInstanceIdMap[nOldVehicleId] or {}
            self.tbVehicleInstanceIdMap[nOldVehicleId][nInstanceId] = nil
        end

        TeamStateChanged(self, tbPlayer, EState.DRIVING, nVehicleInstanceId)

        self.tbVehicleInstanceIdMap[nVehicleInstanceId] = self.tbVehicleInstanceIdMap[nVehicleInstanceId] or {}
        self.tbVehicleInstanceIdMap[nVehicleInstanceId][nInstanceId] = true
    else
        if tbPlayer:IsDying() then
            TeamStateChanged(self, tbPlayer, EState.DYING)
        else
            TeamStateChanged(self, tbPlayer, EState.NONE)
        end
    end

    if nState == HumanVehicleStateDef.AttachToVehicle then
        local tbAllInstanceIds = self.tbVehicleInstanceIdMap[nVehicleInstanceId]
        if tbAllInstanceIds then
            for nCurInstanceId, _ in pairs(tbAllInstanceIds) do
                local tbItrPlayer = GameObjectSystem:FindByInstanceId(nCurInstanceId)
                if tbItrPlayer then
                    if not self:CheckTeammate(tbPlayer, tbItrPlayer) then
                        local tbCurPlayerData = GetPlayerDataByPlayer(self, tbItrPlayer)

                        if not tbCurPlayerData then
                            LogErrorGetPlayerData(nCurInstanceId)
                        else
                            TeamStateChanged(self, tbItrPlayer, tbCurPlayerData.nState, 0)
                            tbAllInstanceIds[nCurInstanceId] = nil
                        end
                    end
                end
            end
        end
    end
end

local function OnVehicleDead(self, tbVehicle, nDriverId)
    local nVehicleInstanceId = tbVehicle:GetServerInstanceId()

    if nVehicleInstanceId then
        local tbAllInstanceIds = self.tbVehicleInstanceIdMap[nVehicleInstanceId]
        if tbAllInstanceIds then
            for nCurInstanceId, _ in pairs(tbAllInstanceIds) do
                local tbItrPlayer = GameObjectSystem:FindByInstanceId(nCurInstanceId)
                if tbItrPlayer then
                    local tbCurPlayerData = GetPlayerDataByPlayer(self, tbItrPlayer)

                    if not tbCurPlayerData then
                        LogErrorGetPlayerData(nCurInstanceId)
                    else
                        TeamStateChanged(self, tbItrPlayer, tbCurPlayerData.nState, 0)
                        tbAllInstanceIds[nCurInstanceId] = nil
                    end
                end
            end
        end
    end
end

local function OnPlayerLogin(self, tbGamePlayer)
    local tbPlayerData = GetPlayerDataByPlayer(self, tbGamePlayer)
    if not tbPlayerData then
        LogErrorGetPlayerData(tbGamePlayer:GetServerInstanceId())
        return
    end

    RefreshPlayerInfo(self, tbPlayerData, tbGamePlayer, ECategoryType.HealthInfo)
    NotifyAllTeammateDataChanged(self, tbGamePlayer, ECategoryType.HealthInfo)
    self:RefreshTeamMemberReplicate(self:FindTeamId(tbGamePlayer))
end

--周期刷新的有PosInfo
local function RefreshTeamInfo(self)
    --按照组信息进行遍历，然后刷新组内玩家信息，而后同步给所有组内玩家
    for _, tbTeam in pairs(self.tbTeams) do
        local tbValidPlayer = nil
        for _, tbGameObj in ipairs(tbTeam.tbGameObjects) do
            tbValidPlayer = tbGameObj
            local tbPlayerData = GetPlayerData(self, tbGameObj, tbTeam.tbTeamData)
            RefreshPlayerInfo(self, tbPlayerData, tbGameObj, ECategoryType.PosInfo)
        end

        if tbValidPlayer then
            NotifyAllTeammateDataChanged(self, tbValidPlayer, ECategoryType.PosInfo)
        end
    end
end

local function OnHpChanged(tbGamePlayer, bHuman, self, nHp, nMaxHp, nHpPercent)
    local bPlayerIsHuman = tbGamePlayer:IsHuman()
    if bPlayerIsHuman ~= bHuman then
        return
    end

    local tbPlayerData = GetPlayerDataByPlayer(self, tbGamePlayer)
    if not tbPlayerData then
        LogErrorGetPlayerData(tbGamePlayer:GetServerInstanceId())
        return
    end

    tbPlayerData.nHp    = math.floor(nHp)
    tbPlayerData.nMaxHp = math.floor(nMaxHp)

    NotifyAllTeammateDataChanged(self, tbGamePlayer, ECategoryType.HealthInfo)
end

local function BindPlayerHpChangedDelegate(self, tbPlayer)
    local ShipBattlePropertyComponent  = tbPlayer.ShipBattlePropertyComponent
    local HumanBattlePropertyComponent = tbPlayer.HumanBattlePropertyComponent

    local OnShipHpChangedFunc = function(...)
        OnHpChanged(tbPlayer, false, ...)
    end

    local OnHumanHpChangedFunc = function(...)
        OnHpChanged(tbPlayer, true, ...)
    end

    self.EventHelper:RegisterLuaDelegate(ShipBattlePropertyComponent.OnHpChanged,  OnShipHpChangedFunc, self)
    self.EventHelper:RegisterLuaDelegate(HumanBattlePropertyComponent.OnHpChanged, OnHumanHpChangedFunc, self)

    local nInstanceId = tbPlayer:GetServerInstanceId()
    local tbFunc = {}
    tbFunc.ShipFunc = OnShipHpChangedFunc
    tbFunc.HumanFunc = OnHumanHpChangedFunc

    self.tbInstanceId2HPFuncMap[nInstanceId] = tbFunc
end

local function UnBindPlayerHpChangedDelegate(self, tbPlayer)
    local ShipBattlePropertyComponent  = tbPlayer.ShipBattlePropertyComponent
    local HumanBattlePropertyComponent = tbPlayer.HumanBattlePropertyComponent

    local nInstanceId = tbPlayer:GetServerInstanceId()
    local OnShipHpChangedFunc = self.tbInstanceId2HPFuncMap[nInstanceId].ShipFunc
    local OnHumanHpChangedFunc = self.tbInstanceId2HPFuncMap[nInstanceId].HumanFunc

    self.EventHelper:UnregisterLuaDelegate(ShipBattlePropertyComponent.OnHpChanged,  OnShipHpChangedFunc, self)
    self.EventHelper:UnregisterLuaDelegate(HumanBattlePropertyComponent.OnHpChanged, OnHumanHpChangedFunc, self)
    self.tbInstanceId2HPFuncMap[nInstanceId] = nil
end

--public function.
function BattleTeamSystem:AddMember(tbGamePlayer, nTeamId)
    if(nTeamId == nil) then
        nTeamId = nDefaultTeamId
    end

    log("BattleTeamSystem:AddMember", nTeamId)
    local tbTeam = GetOrAddTeamByTeamId(self, nTeamId)
    if(not AddMemberToTeam(self, tbTeam, tbGamePlayer)) then
        return false
    end

    BindPlayerHpChangedDelegate(self, tbGamePlayer)

    if GlobalVariableSystem:IsServerLogic() then
        self:RefreshTeamMemberReplicate(nTeamId)
    end

    return true
end

function BattleTeamSystem:RemoveMember(tbGamePlayer, nTeamId)
    if(nTeamId == nil) then
        nTeamId = nDefaultTeamId
    end

    local tbTeam = self.tbTeams[nTeamId]
    if(tbTeam == nil) then
        -- logerror("BattleTeamSystem:RemoveMember failed, can not find team", nTeamId)
        return false
    end

    if(not RemoveMemberFromTeam(self, tbTeam, tbGamePlayer)) then
        return false
    end

    UnBindPlayerHpChangedDelegate(self, tbGamePlayer)

    if GlobalVariableSystem:IsServerLogic() then
        self:DisablePlayerReplicate(tbGamePlayer)
    end

    return true
end

function BattleTeamSystem:IsInTeam(tbGamePlayer, nTeamId)
    if(nTeamId == nil) then
        nTeamId = nDefaultTeamId
    end

    local tbTeam = self.tbTeams[nTeamId]
    if(tbTeam == nil) then
        return false
    end
    return GetMemberIndexInTeam(tbTeam, tbGamePlayer) > 0
end

function BattleTeamSystem:FindTeamId(tbGamePlayer)
    if tbGamePlayer and tbGamePlayer.BattleTeamComponent then
        return tbGamePlayer.BattleTeamComponent.nTeamId
    end
    return -1
end

function BattleTeamSystem:GetTeamMemberCount(nTeamId)
    local tbTeamInfo = self.tbTeams[nTeamId]
    if(tbTeamInfo) then
        return #tbTeamInfo.tbGameObjects
    end
    return 0
end

function BattleTeamSystem:GetCampTypeByTeamId(nTeamId)
    local tbTeamInfo = self.tbTeams[nTeamId]
    for _, tbObject in pairs(tbTeamInfo.tbGameObjects) do
        if tbObject.BattleCampComponent then
            return tbObject.BattleCampComponent:GetCampType()
        end
    end
    return CampDef.Type.CAMP_NONE
end

function BattleTeamSystem:GetTeamMembers(nTeamId)
    local tbTeamInfo = self.tbTeams[nTeamId]
    if(tbTeamInfo) then
        return tbTeamInfo.tbGameObjects
    end
    return nil
end

function BattleTeamSystem:GetTeamMembersByPlayer(tbGamePlayer)
    local nTeamId = self:FindTeamId(tbGamePlayer)
    return self:GetTeamMembers(nTeamId)
end

function BattleTeamSystem:GetAllTeamInfo()
    return self.tbTeams
end

function BattleTeamSystem:Init()
    self.tbTeams    = {}
    self.tbInstanceId2HPFuncMap = {}
    self.tbVehicleInstanceIdMap = {}

    if(GlobalVariableSystem:IsServerLogic()) then
        self.EventHelper = SelfEventHelper()
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_DESTORY, self, OnGameObjectPreDestroy)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_FFA_MAP_SIGN, self, OnFFAMapSign)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED , self, OnPawnDyingChanged)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD , self, OnPawnDead)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGOUT, self, OnPlayerLogout)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerReLogin)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_ADDITIONALSUCCESS_RESULT, self, OnAdditionalSuccessResult)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnMovementStateChanged)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_END_CHANGEDISPLAY, self, OnEndChangeDisplay)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_FFA_PARACHUTION_END, self, OnParachutionEnd)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, self, OnVehicleStateChange)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_DEAD, self, OnVehicleDead)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)

        self.tbRefreshTimer = Timer.NewTimerMethod(self, RefreshTeamInfo, SYNC_INTERVAL, true)
    end
    return true
end

function BattleTeamSystem:Uninit()
    self:Clear()
end

function BattleTeamSystem:Clear()
    if(GlobalVariableSystem:IsServerLogic()) then
        if self.EventHelper then
            self.EventHelper:UnregisterAll()
            self.EventHelper = nil
        end

        if self.tbRefreshTimer then
            self.tbRefreshTimer:Clear()
            self.tbRefreshTimer = nil
        end
    end

    self.tbTeams = {}
    self.tbInstanceId2HPFuncMap = {}
    self.tbVehicleInstanceIdMap = {}
end

function BattleTeamSystem:VisitAllMembers(visitFunc)
    if visitFunc then
        for _, tbTeam in pairs(self.tbTeams) do
            for _, tbGameObj in ipairs(tbTeam.tbGameObjects) do
                visitFunc(tbGameObj)
            end
        end
    end
end

function BattleTeamSystem:CheckTeammate(tbGamePlayerA, tbGamePlayerB)
    local nTeamIdA = self:FindTeamId(tbGamePlayerA)
    local nTeamIdB = self:FindTeamId(tbGamePlayerB)
    return nTeamIdA == nTeamIdB
end

function BattleTeamSystem:FindTeamIdByInstanceId(nInstanceId)
    for _, tbTeam in pairs(self.tbTeams) do
        for _, nId in ipairs(tbTeam.tbInstanceIds) do
            if nId == nInstanceId then
                return tbTeam.nTeamId
            end
        end
    end
    return -1
end

function BattleTeamSystem:CheckTeammateByInstanceId(nInstanceIdA, nInstanceIdB)
    local nTeamIdA = self:FindTeamIdByInstanceId(nInstanceIdA)
    local nTeamIdB = self:FindTeamIdByInstanceId(nInstanceIdB)
    if nTeamIdA == -1 or nTeamIdB == -1 then
        return false
    end
    return nTeamIdA == nTeamIdB
end

function BattleTeamSystem:ChangeTeam(tbGamePlayer, nNewTeamId)
    self:RemoveMember(tbGamePlayer, self:FindTeamId(tbGamePlayer))
    self:AddMember(tbGamePlayer, nNewTeamId)
end

function BattleTeamSystem:GetTeamCount()
    local nCount = 0
    for _, tbTeam in pairs(self.tbTeams) do
        if tbTeam.tbGameObjects and #tbTeam.tbGameObjects > 0 then
            nCount = nCount + 1
        end
    end
    return nCount
end

function BattleTeamSystem:RefreshTeamMemberReplicate(nTeamId)
    local tbControllerValidPlayers = {}
    local tbControllerInValidPlayers = {}
    
    local tbTeam = self.tbTeams[nTeamId]
    if tbTeam ~= nil and #tbTeam.tbGameObjects >= 2 then
        for _, tbGamePlayer in pairs(tbTeam.tbGameObjects) do
            if BotAISystem:IsBot(tbGamePlayer) or not tbGamePlayer.pUEController then
                table.insert(tbControllerInValidPlayers, tbGamePlayer)
            else
                table.insert(tbControllerValidPlayers, tbGamePlayer)
            end
        end
    else
        return
    end

    for _, tbGamePlayer in pairs(tbControllerValidPlayers) do
        PiratesReplicationBPHelpers.SetTeamForPlayerController(tbGamePlayer.pUEController, nTeamId)
    end

    for _, tbBotGamePlayer in pairs(tbControllerInValidPlayers) do
        for _, tbRealGamePlayer in pairs(tbControllerValidPlayers) do
            local pController = tbRealGamePlayer.pUEController
            if tbBotGamePlayer.pUEActor then
                PiratesReplicationBPHelpers.SetActorReplicateToController(pController, tbBotGamePlayer.pUEActor, true)
            end
        end
    end
end

function BattleTeamSystem:DisablePlayerReplicate(tbPlayer)
    local tbControllerValidPlayers = {}
    local tbControllerInValidPlayers = {}
    
    local nTeamId = self:FindTeamId(tbPlayer)
    local tbTeam = self.tbTeams[nTeamId]
    if tbTeam ~= nil then
        for _, tbGamePlayer in pairs(tbTeam.tbGameObjects) do
            if BotAISystem:IsBot(tbGamePlayer) or not tbGamePlayer.pUEController then
                table.insert(tbControllerInValidPlayers, tbGamePlayer)
            else
                table.insert(tbControllerValidPlayers, tbGamePlayer)
            end
        end
    else
        return
    end

    if BotAISystem:IsBot(tbPlayer) or not tbPlayer.pUEController then
        if tbPlayer.pUEActor then
            for _, tbGamePlayer in pairs(tbControllerValidPlayers) do
                local pController = tbGamePlayer.pUEController
                PiratesReplicationBPHelpers.SetActorReplicateToController(pController, tbPlayer.pUEActor, false)
            end
        end
    else
        local pController = tbPlayer.pUEController
        PiratesReplicationBPHelpers.SetTeamForPlayerController(pController, 0)

        for _, tbBotGamePlayer in pairs(tbControllerInValidPlayers) do
            if tbBotGamePlayer.pUEActor then
                PiratesReplicationBPHelpers.SetActorReplicateToController(pController, tbBotGamePlayer.pUEActor, false)
            end
        end
    end
end

return BattleTeamSystem