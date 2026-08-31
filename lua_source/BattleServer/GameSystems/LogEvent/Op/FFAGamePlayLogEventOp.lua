local luaclass = require("luaclass")
local LogEventOpBase = dynamic_require("LogEventOpBase")
local FFAGamePlayLogEventOp = luaclass("FFAGamePlayLogEventOp", LogEventOpBase)

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local Analytics = require("DungeonAnalyticsProtoNames")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BotAISystem = dynamic_require("BotAISystem")
--local GameObjectSystem = dynamic_require("GameObjectSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
-- local DamageTypeEx = require("DamageTypeEx")
local CommonEventDef = require("CommonEventDef")
local BattlePrepareSystem = require("BattlePrepareSystem")
local BattleLandSystem = dynamic_require("BattleLandSystem")
local SelectionPointHelper = require("SelectionPointHelper")
local BattleResultSystem = dynamic_require("BattleResultSystem")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleItemSystemServer = require("BattleItemSystemServer")
local ParachutionSystem = dynamic_require("ParachutionSystem")

FFAGamePlayLogEventOp.nNPCCount = 0     --NPC刷新数量
FFAGamePlayLogEventOp.nNPCDeadCount = 0 --NPC被真人打死的数量
FFAGamePlayLogEventOp.nNPCKillCount = 0 --NPC击杀真人数量
FFAGamePlayLogEventOp.nBotDeadCount = 0 --真人击杀的Bot数量

FFAGamePlayLogEventOp.tbRecordBattleResultInstanceIdMap = nil --已经记录过的对局结束的玩家
FFAGamePlayLogEventOp.tbLoginInstanceId2TimeMap         = nil
FFAGamePlayLogEventOp.tbInstanceId2EquipMap             = nil
FFAGamePlayLogEventOp.tbInstanceId2DyingInfoMap         = nil
FFAGamePlayLogEventOp.tbInstanceId2WeaponDamageMap      = nil

local function IsRealPlayer(tbPlayer)
    if tbPlayer and
       tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf and 
       not BotAISystem:IsBot(tbPlayer) then
        return true
    end

    return false
end

local function TryAddPlayerResultRecord(self, tbPlayer)
    if not IsRealPlayer(tbPlayer) then
        return false
    end

    local nInstanceId = tbPlayer:GetServerInstanceId()
    if self.tbRecordBattleResultInstanceIdMap[nInstanceId] then
        return false
    end

    self.tbRecordBattleResultInstanceIdMap[nInstanceId] = true
    return true
end

local function GetEquipDescByPlayer(self, tbPlayer)
    local tbEquips = nil

    if tbPlayer:IsDead() then
        local nInstanceId = tbPlayer:GetServerInstanceId()
        tbEquips = self.tbInstanceId2EquipMap[nInstanceId]
    else
        tbEquips = BattleItemSystemServer:GetPlayerEquippedItemDetails(tbPlayer)
    end

    if tbEquips then
        local tbIds = {}
        for _, nCurId in pairs(tbEquips.tbHumanEquippedItemTemplateIds) do
            table.insert(tbIds, nCurId)
        end

        for _, nCurId in pairs(tbEquips.tbShipEquippedItemTemplateIds) do
            table.insert(tbIds, nCurId)
        end

        return self:ArrayToString(tbIds, ",")
    end

    return nil
end

--将player_name, team_id elapsed_time 存储到tbPacket中
local function SavePlayerResultCommonInfoToPacket(self, tbPlayer, tbPacket)
    local nPlayerId = tbPlayer:GetPlayerId()
    local nInstanceId = tbPlayer:GetServerInstanceId()

    self:SavePlayerCommonPropertysToPacket(nPlayerId, tbPacket)
    local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)
    if tbPrepareInfo then
        tbPacket.player_name = tbPrepareInfo.szPlayerName
        tbPacket.team_id = tbPrepareInfo.szLobbyTeamInfo
    end

    local nLoginTime = self.tbLoginInstanceId2TimeMap[nInstanceId]
    if nLoginTime then
        tbPacket.elapsed_time = math.floor(GlobalVariableSystem:GetLocalTime() - nLoginTime)
    end
end

--将wait_time存储到tbPacket中
local function SavePlayerResultWaitTimeInfoToPacket(self, tbPlayer, tbPacket)
    local wait_time = 0

    local nInstanceId = tbPlayer:GetServerInstanceId()
    local nLoginTime = self.tbLoginInstanceId2TimeMap[nInstanceId]
    if nLoginTime then
        local nBattleBeginTime = self.tbParam.nBattleBeginTime
        wait_time = nBattleBeginTime - nLoginTime
        if wait_time < 0 then
            wait_time = 0
        end
    end

    tbPacket.wait_time = wait_time
end

--将选点数据location, landing_point_count, landing_point_type数据存储到tbPacket中
local function SavePlayerResultSelectPointInfoToPacket(self, tbPlayer, tbPacket)
    local nInstanceId = tbPlayer:GetServerInstanceId()
    local tbInfo = SelectionPointHelper:GetPlayerSelectionInfo(nInstanceId)
    local tbPoint = ParachutionSystem:GetPlayerLandingPoint(nInstanceId)
    if tbInfo ~= nil then
        local szPoint = "0,0,0"
        if tbPoint ~= nil then
            szPoint = string.format("%f,%f,%f", tbPoint.nX, tbPoint.nY, tbPoint.nZ)
        end
        tbPacket.location = string.format("%d,%d,%d;%s", tbInfo.nX, tbInfo.nY, tbInfo.nZ, szPoint)
        tbPacket.landing_point_count = tbInfo.nCount
        tbPacket.landing_point_type = tbInfo.nSelectionType
    end
end

--将选点数据first_change_shape_time, change_shape_count数据存储到tbPacket中
local function SavePlayerResultChangeDisplayInfoToPacket(self, tbPlayer, tbPacket)
    local nPlayerId = tbPlayer:GetPlayerId()
    local tbInfo = BattleLandSystem:GetPlayerChangeDisplayInfo(nPlayerId)


    if tbInfo == nil then
        -- 没有进行过人船变换
        tbPacket.change_shape_count = 0
    else
        tbPacket.first_change_shape_time = tbInfo.nFirstChangeTime
        tbPacket.change_shape_count = tbInfo.nCount 
    end
end

--将ranking存储到tbPacket中
local function SavePlayerResultRankInfoToPacket(self, tbPlayer, tbPacket, bWin)
    local nInstanceId = tbPlayer:GetServerInstanceId()
    local tbGameState = BattleGameModeSystem:GetGameState()
    local nFFAAliveCount = tbGameState.nFFAAlivePlayerCount:Get()

    local ranking = -1

    if bWin then
        ranking = 1
    else
        if BattleResultSystem:IsPlayerBattleEnd(nInstanceId) then
            ranking = nFFAAliveCount + 1
        else
            ranking = nFFAAliveCount
        end
    end

    tbPacket.ranking = ranking
end

--将 death_reason, death_shape, death_location, direct_death, killer_equip, killer_shape death_equip 存储到tbPacket中
local function SavePlayerResultDeadInfoToPacket(self, tbPlayer, tbPacket, bWin, bExitDungeon)
    local death_shape = Analytics.PlayerBattleEnd_PlayerShape.HUMAN
    if tbPlayer:IsShip() then
        death_shape = Analytics.PlayerBattleEnd_PlayerShape.SHIP
    end

    tbPacket.death_shape = death_shape

    local pLocation = tbPlayer:GetLocation()
    tbPacket.death_location = string.format("%d,%d,%d", math.floor(pLocation.X), math.floor(pLocation.Y), math.floor(pLocation.Z))
    tbPacket.death_equip = GetEquipDescByPlayer(self, tbPlayer)

    if bWin then
        tbPacket.death_reason = -1
        tbPacket.direct_death = false
        return
    else
        if bExitDungeon then
            tbPacket.death_reason = -2
            tbPacket.direct_death = true
            return
        else
            local nDamageType = 0
            local tbDeadActorComponent = tbPlayer:GetCurrentPropertyComponent()
            if tbDeadActorComponent then
                nDamageType = tbDeadActorComponent:GetLastDamageType()
                tbPacket.death_reason = nDamageType

                local tbMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
                local bAllDyingOrDead = true
                for _, tbCurPlayer in pairs(tbMembers) do
                    if tbCurPlayer ~= tbPlayer then
                        if not BattleResultSystem:IsPlayerBattleEnd(tbCurPlayer:GetServerInstanceId()) and
                           not tbCurPlayer:IsDying() then
                            bAllDyingOrDead = false
                            break
                        end
                    end
                end

                tbPacket.direct_death = bAllDyingOrDead

                local tbKillerActor = tbDeadActorComponent:GetLastDamageCauser()
                if tbKillerActor then
                    local killer_shape = Analytics.PlayerBattleEnd_PlayerShape.HUMAN
                    if tbKillerActor:IsShip() then
                        killer_shape = Analytics.PlayerBattleEnd_PlayerShape.SHIP
                    end
                    tbPacket.killer_shape = killer_shape
                    tbPacket.killer_equip = GetEquipDescByPlayer(self, tbPlayer)
                end
            end
        end
    end
end

--将 dying_equip, hiter_equip 存储到tbPacket中
local function SavePlayerResultEquipInfoToPacket(self, tbPlayer, tbPacket)
    local nInstanceId = tbPlayer:GetServerInstanceId()
    local tbDyingMap = self.tbInstanceId2DyingInfoMap[nInstanceId]
    if tbDyingMap and 
       tbDyingMap.tbDyingEquip and
       tbDyingMap.tbHiterEquip then
        tbPacket.dying_equip = self:ArrayToString(tbDyingMap.tbDyingEquip, ";")
        tbPacket.hiter_equip = self:ArrayToString(tbDyingMap.tbHiterEquip, ";")
    end
end

--将 weapon_damage 存储到tbPacket中
local function SavePlayerResultWeaponDamageInfoToPacket(self, tbPlayer, tbPacket)
    local nInstanceId = tbPlayer:GetServerInstanceId()
    local tbWeaponDamageMap = self.tbInstanceId2WeaponDamageMap[nInstanceId]

    if tbWeaponDamageMap then
        tbPacket.weapon_damage = self:MapToString(tbWeaponDamageMap, ",")
    end
end

local function LogPlayerLoginEvent(self, tbPlayer)
    if IsRealPlayer(tbPlayer) and not self:IsBattleBegin() then
        local nInstanceId = tbPlayer:GetServerInstanceId()
        self.tbLoginInstanceId2TimeMap[nInstanceId] = GlobalVariableSystem:GetLocalTime()
    end
end

local function OnTakeDamage(self, tbTaker, tbCauser, nDamage, nDamageType, nHp, nItemTemplateId, tbDamageExtraData)
    if IsRealPlayer(tbCauser) and nItemTemplateId then
        local nInstanceId = tbCauser:GetServerInstanceId()

        self.tbInstanceId2WeaponDamageMap[nInstanceId] = self.tbInstanceId2WeaponDamageMap[nInstanceId] or {}
        local tbWeaponDamageMap = self.tbInstanceId2WeaponDamageMap[nInstanceId]
    
        tbWeaponDamageMap[nItemTemplateId] = tbWeaponDamageMap[nItemTemplateId] or 0
        tbWeaponDamageMap[nItemTemplateId] = tbWeaponDamageMap[nItemTemplateId] + nDamage
    end
end

--真人玩家死亡
local function OnRealPlayerDead(self, tbPlayer)
    if not TryAddPlayerResultRecord(self, tbPlayer) then
        return
    end

    local tbPacket = {}
    
    SavePlayerResultCommonInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultRankInfoToPacket(self, tbPlayer, tbPacket, false)
    SavePlayerResultDeadInfoToPacket(self, tbPlayer, tbPacket, false, false)
    SavePlayerResultEquipInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultWaitTimeInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultSelectPointInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultWeaponDamageInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultChangeDisplayInfoToPacket(self, tbPlayer, tbPacket)
    
    tbPacket.battle_result = Analytics.PlayerBattleEnd_BattleResult.RESULT_DEAD
    self:LogEvent(Analytics.PlayerBattleEnd, tbPacket)
end

local function OnPawnPreDead(self, tbPlayer)
    local nInstanceId = tbPlayer:GetServerInstanceId()
    self.tbInstanceId2EquipMap[nInstanceId] = BattleItemSystemServer:GetPlayerEquippedItemDetails(tbPlayer)
end

local function OnPawnDyingChanged(self, tbPlayer, bIsDying)
    if IsRealPlayer(tbPlayer) and bIsDying then
        local tbHiterPlayer = nil
        local tbDyingActorComponent = tbPlayer:GetCurrentPropertyComponent()
        if tbDyingActorComponent then
            tbHiterPlayer = tbDyingActorComponent:GetLastDamageCauser()
            if tbHiterPlayer then
                local nInstanceId = tbPlayer:GetServerInstanceId()
                self.tbInstanceId2DyingInfoMap[nInstanceId] = self.tbInstanceId2DyingInfoMap[nInstanceId] or {}
                local tbDyingMap = self.tbInstanceId2DyingInfoMap[nInstanceId]
                tbDyingMap.tbDyingEquip = tbDyingMap.tbDyingEquip or {}
                tbDyingMap.tbHiterEquip = tbDyingMap.tbHiterEquip or {}

                local szDyingEquip = GetEquipDescByPlayer(self, tbPlayer)
                local szHiterEquip = GetEquipDescByPlayer(self, tbHiterPlayer)

                if szDyingEquip and szHiterEquip then
                    table.insert(tbDyingMap.tbDyingEquip, szDyingEquip)
                    table.insert(tbDyingMap.tbHiterEquip, szHiterEquip)
                end
            end
        end
    end
end

--玩家死亡数据埋点
local function LogPlayerDeadEvent(self, tbDeadActor)
    --真人击杀NPC的情况
    if tbDeadActor.ObjectType == GameObjectTypeDef.Npc then
        local tbDeadActorComponent = tbDeadActor:GetCurrentPropertyComponent()
        if tbDeadActorComponent then
            local tbKillerActor = tbDeadActorComponent:GetLastDamageCauser()
            if IsRealPlayer(tbKillerActor) then
                self.nNPCDeadCount = self.nNPCDeadCount + 1
            end
        end
    end

    if tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then
        local tbDeadActorComponent = tbDeadActor:GetCurrentPropertyComponent()
        if tbDeadActorComponent then
            local tbKillerActor = tbDeadActorComponent:GetLastDamageCauser()
            if BotAISystem:IsBot(tbDeadActor) then
                --真人击杀Bot的情况
                if IsRealPlayer(tbKillerActor) then
                    self.nBotDeadCount = self.nBotDeadCount + 1
                end
            else
                --NPC击杀真人的情况
                if tbKillerActor and tbKillerActor.ObjectType == GameObjectTypeDef.Npc then
                    self.nNPCKillCount = self.nNPCKillCount + 1
                end
    
                OnRealPlayerDead(self, tbDeadActor)
            end
        end
    end
end

local function LogNPCCreatedEvent(self, tbNPC)
    if tbNPC:IsBattleNPC() then
        self.nNPCCount = self.nNPCCount + 1
        log("LogNPCCreatedEvent: ", self.nNPCCount, tbNPC.szName)
    end
end

local function GetBotCount()
    local nBotCount = 0
    local tbPrepareInfos = BattlePrepareSystem:GetAllPlayerPrepareInfos()
    for nPlayerId, tbCurPrepareInfo in pairs(tbPrepareInfos) do
        if tbCurPrepareInfo:IsBot() then
            nBotCount = nBotCount + 1
        end
    end

    return nBotCount
end

local function LogPlayerPrepareEvent(self, _, tbPlayerIds)
    for _, nPlayerId in pairs(tbPlayerIds) do
        local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)
        if not tbPrepareInfo:IsBot() then
            local tbPacket = {}
            self:SavePlayerCommonPropertysToPacket(nPlayerId, tbPacket)
            tbPacket.matching_type = tbPrepareInfo.nMatchType
            tbPacket.rank = tbPrepareInfo.nGrade
    
            self:LogEvent(Analytics.PlayerBattleStart, tbPacket)
        end
    end
end

--集合区逃跑
local function OnWaitStageExitDungeon(self, tbPlayer)
    if not TryAddPlayerResultRecord(self, tbPlayer) then
        return
    end

    local tbPacket = {}
    SavePlayerResultCommonInfoToPacket(self, tbPlayer, tbPacket)
    tbPacket.battle_result = Analytics.PlayerBattleEnd_BattleResult.RESULT_WAIT_STAGE_EXIT

    self:LogEvent(Analytics.PlayerBattleEnd, tbPacket)
end

--战斗区逃跑
local function OnBattleStageExitDungeon(self, tbPlayer)
    if not TryAddPlayerResultRecord(self, tbPlayer) then
        return
    end

    local tbPacket = {}
    
    SavePlayerResultCommonInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultRankInfoToPacket(self, tbPlayer, tbPacket, false)
    SavePlayerResultDeadInfoToPacket(self, tbPlayer, tbPacket, false, true)
    SavePlayerResultEquipInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultWaitTimeInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultSelectPointInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultWeaponDamageInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultChangeDisplayInfoToPacket(self, tbPlayer, tbPacket)
    
    tbPacket.battle_result = Analytics.PlayerBattleEnd_BattleResult.RESULT_BATTLE_EXIT
    self:LogEvent(Analytics.PlayerBattleEnd, tbPacket)
end

--队伍胜利
local function OnPlayerWin(self, tbPlayer)
    if not TryAddPlayerResultRecord(self, tbPlayer) then
        return
    end

    local tbPacket = {}
    
    SavePlayerResultCommonInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultRankInfoToPacket(self, tbPlayer, tbPacket, true)
    SavePlayerResultDeadInfoToPacket(self, tbPlayer, tbPacket, true, false)
    SavePlayerResultEquipInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultWaitTimeInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultSelectPointInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultWeaponDamageInfoToPacket(self, tbPlayer, tbPacket)
    SavePlayerResultChangeDisplayInfoToPacket(self, tbPlayer, tbPacket)
    
    tbPacket.battle_result = Analytics.PlayerBattleEnd_BattleResult.RESULT_WIN
    self:LogEvent(Analytics.PlayerBattleEnd, tbPacket)
end

-------------------------------public function-----------------------------------------------------
function FFAGamePlayLogEventOp:Init()
    FFAGamePlayLogEventOp.super.Init(self)

    self.nRealPlayerCount = 0
    self.nNPCCount = 0     
    self.nNPCDeadCount = 0 
    self.nNPCKillCount = 0 
    self.nBotDeadCount = 0 

    self.tbRecordBattleResultInstanceIdMap = {}
    self.tbLoginInstanceId2TimeMap = {}
    self.tbInstanceId2EquipMap = {}
    self.tbInstanceId2DyingInfoMap = {}
    self.tbInstanceId2WeaponDamageMap = {}

    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, LogPlayerLoginEvent)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, LogPlayerDeadEvent)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_NPC_POST_CREATE, self, LogNPCCreatedEvent)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_PLAYER_PREPARE, self, LogPlayerPrepareEvent)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_FFA_WAIT_STAGE_LEAVE_DUNGEON, self, OnWaitStageExitDungeon)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_FFA_BATTLE_STAGE_LEAVE_DUNGEON, self, OnBattleStageExitDungeon)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_FFA_PLAYER_WIN, self, OnPlayerWin)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, OnPawnPreDead)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED , self, OnPawnDyingChanged)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)

end

function FFAGamePlayLogEventOp:Uninit()
    FFAGamePlayLogEventOp.super.Uninit(self)
    self.tbInstanceId2WeaponDamageMap = nil
    self.tbInstanceId2DyingInfoMap = nil
    self.tbLoginInstanceId2TimeMap = nil
    self.tbInstanceId2EquipMap = nil
    self.tbRecordBattleResultInstanceIdMap = nil
end

function FFAGamePlayLogEventOp:OnBattleBegin()
    FFAGamePlayLogEventOp.super.OnBattleBegin(self)
end

function FFAGamePlayLogEventOp:OnBattleEnd()
    local tbPacket = {}

    self:SaveDungeonCommonPropertysToPacket(tbPacket)
    tbPacket.elapsed_time = self:GetBattleElapsedTime()
    tbPacket.npc_count = self.nNPCCount
    tbPacket.npc_death = self.nNPCDeadCount
    tbPacket.npc_kill  = self.nNPCKillCount
    tbPacket.bot_count = GetBotCount()
    tbPacket.bot_death = self.nBotDeadCount

    self:LogEvent(Analytics.BattleState, tbPacket)

    FFAGamePlayLogEventOp.super.OnBattleEnd(self)
end

return FFAGamePlayLogEventOp