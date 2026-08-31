local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local PVPOccupyGameMode = luaclass("PVPOccupyGameMode", BattleGameModeBaseClass)

local BattleTimerStepClass = require("BattleTimerStep")
local PVPOccupyStepClass = require("PVPOccupyStep")
local WaitingPlayerJoinStepClass = require("BattleWaitingPlayerJoinStep")
local PVPOccupyTutorialResultStepClass = require("PVPOccupyTutorialResultStep")

local PVPOccupyDataTable = require("PVPOccupyDataTable")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleItemSystemServer = require("BattleItemSystemServer")
local GameObjectTypeDef = require("GameObjectTypeDef")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local PropertyDef  = require("BattleDataStatisticsPropertyFieldDef")
local D2CHelper = require("D2CHelper")
local TeamWatchServerHelper = require("TeamWatchServerHelper")

PVPOccupyGameMode.tbUsedPlayerStarts = nil
PVPOccupyGameMode.nTutorialLoginDialog = nil
PVPOccupyGameMode.nTutorialResultDialog = nil
PVPOccupyGameMode.bTutorial = nil
PVPOccupyGameMode.tbShipIdList = nil
PVPOccupyGameMode.tbPlayerShipId = nil
PVPOccupyGameMode.tbPlayerResultData = nil            -- 结算数据

--local TOAST_SHOW_TIME = 5                         -- toast显示时间
local MAX_MEMBER_COUNT = 4

function PVPOccupyGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    if not PVPOccupyGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile) then
        return false
    end

    local tbTemplateData = PVPOccupyDataTable:GetTemplate(nSubDungonId)
    if(tbTemplateData == nil) then
        logerror("PVPOccupyGameMode init failed, can not find id", nSubDungonId)
        return false
    end

    self.tbUsedPlayerStarts = {}
    self.tbShipIdList = {{1,2,2,3},{1,2,2,3}}
    self.tbPlayerShipId = {}
    self.tbPlayerResultData = {}
    self.bTutorial = BattleGameModeSystem:GetGameInitData().tutorial
    self.nTutorialLoginDialog = tbTemplateData.nTutorialLoginDialog
    self.nTutorialResultDialog = tbTemplateData.nTutorialResultDialog
    tbGameState.rGameStateBaseInfo.bCanQuit = not self.bTutorial
    log("PVPOccupyGameMode init with tutorial:", self.bTutorial)
    self:AddSteps(tbTemplateData, tbGameState)

    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    return true
end

function PVPOccupyGameMode:AddSteps(tbTemplateData, tbGameState)
    local tbStep
    local rBattleTimerStepInfo = tbGameState.rBattleTimerStepInfo
    local rStepRemainTime = tbGameState.rStepRemainTime

    tbStep = self:CreateStep(WaitingPlayerJoinStepClass, tbGameState.nWaitForPlayerJoinStepId)
    tbStep:SetParams(rBattleTimerStepInfo, tbTemplateData.nWaitForPlayerJoinTime, MAX_MEMBER_COUNT * 2)

    tbStep = self:CreateStep(BattleTimerStepClass, tbGameState.nCountDownStepId)
    tbStep:SetParams(rBattleTimerStepInfo, rStepRemainTime, tbTemplateData.nCountDownTime)

    tbStep = self:CreateStep(PVPOccupyStepClass, tbGameState.nMatchStepId)
    tbStep:SetParams(tbGameState, tbTemplateData, self.tbJsonTableFile)

    if self.bTutorial then
        tbStep = self:CreateStep(PVPOccupyTutorialResultStepClass, tbGameState.nTutorialResultStepId)
        tbStep:SetParams(self.nTutorialResultDialog)
    end
end

function PVPOccupyGameMode:Uninit()
    self.tbUsedPlayerStarts = nil
    self.tbShipIdList = nil
    self.tbPlayerShipId = nil
    self.tbPlayerResultData = nil
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    PVPOccupyGameMode.super.Uninit(self)
end


local function AddUsedPlayerStart(self, nGroupIndex, nInstanceId, tbJsonStart)
    local tbNewStart = {}
    tbNewStart.tbJsonStart = tbJsonStart
    tbNewStart.nGroupIndex = nGroupIndex
    tbNewStart.nInstanceId = nInstanceId
    table.insert(self.tbUsedPlayerStarts, tbNewStart)
    return tbNewStart
end

function PVPOccupyGameMode:FindPlayerNewJsonStart(nGroupIndex)
    local tbJsonStarts = self.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    local nJsonCount = #tbJsonStarts
    local tbUsedStarts = self.tbUsedPlayerStarts
    local nUsedCount = #tbUsedStarts

    -- 没有的话直接用第一个
    if(nUsedCount == 0) then
        return tbJsonStarts[1]
    end

    -- 先看第一个，nSelfTeamIndex或者nOtherTeamIndex必定有一个有效
    local nSelfTeamIndex = nil
    local tbUsedStart = tbUsedStarts[1]
    if(tbUsedStart.nGroupIndex == nGroupIndex) then
        nSelfTeamIndex = tbUsedStart.tbJsonStart.TeamIndex
    else
        local nOtherTeamIndex = tbUsedStart.tbJsonStart.TeamIndex
        for i=2, nJsonCount do
            if(tbJsonStarts[i].TeamIndex ~= nOtherTeamIndex) then
                nSelfTeamIndex = tbJsonStarts[i].TeamIndex
                break
            end
        end
    end
    assert(nSelfTeamIndex)

    local bCanUse, tbJsonStart
    for i=2, nJsonCount do
        -- 判断是可用
        bCanUse = true
        tbJsonStart = tbJsonStarts[i]
        for j=1, nUsedCount do
            tbUsedStart = tbUsedStarts[j]
            if(tbUsedStart.tbJsonStart == tbJsonStart) then
                bCanUse = false
                break
            end
        end

        if(bCanUse and tbJsonStart.TeamIndex == nSelfTeamIndex) then
            return tbJsonStart
        end
    end

    error("PVPOccupyGameMode:FindPlayerStart failed, can not find other team index2")
    return nil
end

function PVPOccupyGameMode:FindPlayerStartJsonData(tbGamePlayer)
    local nGroupIndex = BattleTeamSystem:FindTeamId(tbGamePlayer)
    if nGroupIndex < 0 then
        error("PVPOccupyGameMode:FindPlayerStartJsonData find team id failed. ".. tbGamePlayer.nPlayerId.." ,".. tbGamePlayer.nServerInstanceId)
        return
    end

    local nInstanceId = tbGamePlayer.nServerInstanceId

    local tbUsed = self.tbUsedPlayerStarts
    if(tbUsed) then
        local nUsedCount = #tbUsed
        for i=1, nUsedCount do
            if(tbUsed[i].nInstanceId == nInstanceId) then
                return tbUsed[i].tbJsonStart
            end
        end
    end

    local tbJsonStart = self:FindPlayerNewJsonStart(nGroupIndex)
    if(tbJsonStart == nil) then
        error("PVPOccupyGameMode:FindPlayerStartJsonData failed")
        return
    end
    AddUsedPlayerStart(self, nGroupIndex, nInstanceId, tbJsonStart)

    local tbTans = tbJsonStart.Transform
    log("PVPOccupyGameMode:FindPlayerStartJsonData", nGroupIndex, nInstanceId, tbGamePlayer.nPlayerId,
        tbTans.X, tbTans.Y, tbTans.Z, tbTans.Yaw)
    return tbJsonStart
end

function PVPOccupyGameMode:GetQuitDungeonDialogType(tbPlayer)
    if not tbPlayer then
        return DungeonQuitDialogType.ArenaDead
    end
    log("PVPOccupyGameMode:GetQuitDungeonDialogType")
    if tbPlayer:IsDead() then
        return DungeonQuitDialogType.ArenaDead
    else
        return DungeonQuitDialogType.ArenaAlive
    end
end

function PVPOccupyGameMode:OnPlayerLogin(tbGamePlayer)
    PVPOccupyGameMode.super.OnPlayerLogin(self, tbGamePlayer)
    local nTutorialLoginDialog = self.nTutorialLoginDialog
    if self.bTutorial and nTutorialLoginDialog > 0 then
        BattleInteractionHelper:PlayerShowDialog(tbGamePlayer, nTutorialLoginDialog)
    end
end

local function GetShipId(self, tbGamePlayer)
    local nGroupIndex = BattleTeamSystem:FindTeamId(tbGamePlayer)
    if nGroupIndex < 0 then
        return nil
    end

    local nInstanceId = tbGamePlayer.nServerInstanceId

    local tbPlayerShipId = self.tbPlayerShipId
    if tbPlayerShipId then
        for nId, nShipId in pairs(tbPlayerShipId) do
            if nId == nInstanceId then
                return nShipId
            end
        end
    end

    local tbShipId = self.tbShipIdList[nGroupIndex]
    local nShipGroupId = nil
    if tbShipId then
        local nCount = #tbShipId
        if nCount > 0 then
            local nRandIndex = math.random(1, nCount)
            nShipGroupId = tbShipId[nRandIndex]
            self.tbPlayerShipId[nInstanceId] = nShipGroupId
            table.remove(tbShipId, nRandIndex)
        end
    end
    return nShipGroupId
end

function PVPOccupyGameMode:SpawnPlayerPawn(tbGamePlayer, bPossess)
    local nGroupId = GetShipId(self, tbGamePlayer)
    if nGroupId == nil then
        nGroupId = 1
    end
    BattleItemSystemServer:InitPlayerItemsByGroupId(tbGamePlayer:GetServerInstanceId(), nGroupId)
    PVPOccupyGameMode.super.SpawnPlayerPawn(self, tbGamePlayer, bPossess)
end

local function CreateStatisticsData(tbPacket, nPlayerId)
    local tbStats = BattleDataStatisticsSystem:GetPlayerStats(nPlayerId)
    tbPacket.nApplyDamageToShip = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.APPLYDAMAGETOSHIP)
    tbPacket.nApplyDamageToHuman = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.APPLYDAMAGETOHUMAN)
    tbPacket.nApplyCureToShip = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.APPLYCURETOSHIP)
    tbPacket.nApplyCureToHuman = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.APPLYCURETOHUMAN)
    tbPacket.nMoveDistance = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.SHIPMOVEDISTANCE) + tbStats:GetProperty(PropertyDef.HUMANMOVEDISTANCE)
    tbPacket.nShipLaunchCount = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.SHIPLAUNCHCOUNT)
    tbPacket.nShipHitCount = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.SHIPHITCOUNT)
    tbPacket.nHumanLaunchCount = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.HUMANLAUNCHCOUNT)
    tbPacket.nHumanHitCount = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.HUMANHITCOUNT)
    tbPacket.nHitShipCoreCount = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.HITSHIPCORECOUNT)
    tbPacket.nHitHumanCoreCount = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.HITHUMANCORECOUNT)
    tbPacket.nSaveTeamateCount = tbStats == nil and 0 or tbStats:GetProperty(PropertyDef.SAVETEAMATECOUNT)
end

-- 结算
function PVPOccupyGameMode:OnGameOver(tbResults)
    local tbResultData = self.tbPlayerResultData
    local nCount = #tbResults
    local tbResult
    for i=1, nCount do
        tbResult = tbResults[i]
        local nPlayerId = tbResult.nPlayerId
        local nResult = tbResult.nResult
        local tbPacket = {}
        local nKillCount = 0

        tbPacket.nRank = nResult
        local GamePlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
        if GamePlayer then
            local nInstanceId = GamePlayer:GetServerInstanceId()
            if tbResultData[nInstanceId] then
                if tbResultData[nInstanceId].nKillCount then
                    nKillCount = tbResultData[nInstanceId].nKillCount
                end
            end
            tbPacket.nKillCount = nKillCount
            CreateStatisticsData(tbPacket, nPlayerId)
            NetworkManager:GetRPCNetworkProxy():SendToClient(GamePlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFAPlayerResult, tbPacket)
        end
    end
end

function PVPOccupyGameMode:OnPawnDead(tbDeadObject)
    PVPOccupyGameMode.super.OnPawnDead(self, tbDeadObject)
    if tbDeadObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        local nDeadInstanceId = tbDeadObject:GetServerInstanceId()
        local szKillerName = nil
        local tbResultData = self.tbPlayerResultData
        local tbKillerActor = nil
        local tbDeadObjectComponent = nil
        local nDamageType = nil
        if tbDeadObject:IsShip() then
            tbDeadObjectComponent = tbDeadObject.ShipBattlePropertyComponent
        else
            tbDeadObjectComponent = tbDeadObject.HumanBattlePropertyComponent
        end
        local nKillerInstanceId = nil
        if tbDeadObjectComponent then
            tbKillerActor = tbDeadObjectComponent:GetLastDamageCauser()
            nDamageType = tbDeadObjectComponent:GetLastDamageType()
            if tbKillerActor then
                szKillerName = tbKillerActor.szName
                nKillerInstanceId = tbKillerActor:GetServerInstanceId()
                if tbResultData[nKillerInstanceId] == nil then
                    tbResultData[nKillerInstanceId] = {}
                    tbResultData[nKillerInstanceId].nKillCount = 0
                end
                local nKillerKillCount = tbResultData[nKillerInstanceId].nKillCount
                if nKillerInstanceId ~= nDeadInstanceId then
                    nKillerKillCount = nKillerKillCount + 1
                    tbResultData[nKillerInstanceId].nKillCount = nKillerKillCount
                end
                -- 击杀方提示
                local tbKillerKillPacket = {}
                tbKillerKillPacket.nKillCount = nKillerKillCount
                TeamWatchServerHelper.NotifyViewersKillInfo(tbKillerActor, nKillerKillCount)
                NetworkManager:GetRPCNetworkProxy():SendToClient(tbKillerActor:GetUEControllerUniqueId(), ProtoDC.d2c_FFAKillInfo, tbKillerKillPacket)
            end
        end
        D2CHelper:MulticastKillToast(ProtoDC.d2c_BattleKillToast_EType.KILL,
            szKillerName, tbDeadObject.szName,
            nKillerInstanceId, tbDeadObject:GetServerInstanceId(),
            nDamageType)
    end
end

-- function PVPOccupyGameMode:OnPlayerLogout(tbGamePlayer)
--     PVPOccupyGameMode.super.OnPlayerLogout(self, tbGamePlayer)
-- end

return PVPOccupyGameMode
