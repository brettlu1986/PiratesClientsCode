-----------------------------------------------------
--File Name    : BattleDataStatisticsSystem.lua
--Author       : Song Fuhao
--Create Time  : 2017-08-29
--Description  : 战斗内数据统计
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleDataStatisticsSystem = luaclass("BattleDataStatisticsSystem")

local CommonEventDef        = require("CommonEventDef")
local SceneItemHelper       = require("SceneItemHelper")
local GameObjectTypeDef     = require("GameObjectTypeDef")
local BattleStatsTypeDef    = require("BattleStatsTypeDef")
local GameObjectSystem      = dynamic_require("GameObjectSystem")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local PropertyDef           = require("BattleDataStatisticsPropertyFieldDef")
local BattleStatsHelper     = require("BattleStatsHelper")
local SelfEventHelper       = require("SelfEventHelper")
local BattlePrepareSystem   = require("BattlePrepareSystem")
local DamageTypeEx          = require("DamageTypeEx")

local tbClassMap = {}
tbClassMap[BattleStatsTypeDef.Player] = require("BattlePlayerStats")
tbClassMap[BattleStatsTypeDef.Combat] = require("BattleCombatStats")
tbClassMap[BattleStatsTypeDef.Team] = require("BattleTeamStats")
tbClassMap[BattleStatsTypeDef.Bot] = require("BattlePlayerStats")

BattleDataStatisticsSystem.bIsActive = false
BattleDataStatisticsSystem.EventHelper = nil
BattleDataStatisticsSystem.tbPlayerStatsMap = nil
BattleDataStatisticsSystem.tbBotStatsMap  = nil
BattleDataStatisticsSystem.tbTeamStatsMap = nil

local DAMAGE_SOURCE = {
    NONE  = 0,
    OTHER = 1,
    SHIP  = 2,
    HUMAN = 3
}

local function CreateStats(StatsType, ...)
    local StatsClass = tbClassMap[StatsType]
    if StatsClass then
        local tbStats = StatsClass()
        tbStats.StatsType = StatsType
        tbStats:Create(...)
        return tbStats
    else
        logerror("[BattleDataStatisticsSystem] create stats error, invalid stats type %d.", StatsType)
        return nil
    end
end

local function DestroyCombatStats(self)
    if self.tbCombatStats then
        self.tbCombatStats:Destroy()
        self.tbCombatStats = nil
    end
end

local function DestroyStats(self)
    if self.tbPlayerStatsMap then
        for _, v in pairs(self.tbPlayerStatsMap) do
            v:OnDestroy()
        end
        self.tbPlayerStatsMap = {}
    end

    if self.tbTeamStatsMap then
        for _, v in pairs(self.tbTeamStatsMap) do
            v:OnDestroy()
        end
        self.tbTeamStatsMap = {}
    end

    if self.tbBotStatsMap then
        for _, v in pairs(self.tbBotStatsMap) do
            v:OnDestroy()
        end
        self.tbBotStatsMap = {}
    end
end

local function RegisterTeam(self, nTeamId)
    if self.tbTeamStatsMap[nTeamId] == nil then
        local tbTeamStats = CreateStats(BattleStatsTypeDef.Team, nTeamId)
        self.tbTeamStatsMap[nTeamId] = tbTeamStats
    end
end

function BattleDataStatisticsSystem:RegisterCharacter(tbCharacter)
    if not tbCharacter then
        log("BattleDataStatisticsSystem:RegisterCharacter no character")
        return
    end
    local nPlayerId = tbCharacter.nPlayerId
    if BattlePrepareSystem:IsBot(nPlayerId) then
        if self.tbBotStatsMap[nPlayerId] == nil then
            local tbCharacterStats = CreateStats(BattleStatsTypeDef.Bot, tbCharacter)
            self.tbBotStatsMap[nPlayerId] = tbCharacterStats
            local nTeamId = tbCharacterStats:GetProperty(PropertyDef.TEAMID)
            log("BattleDataStatisticsSystem:RegisterCharacter is bot: ", tbCharacter.szName, nPlayerId, nTeamId)
            if nTeamId > 0 then
                RegisterTeam(self, nTeamId)
            end
        end
        return
    end
    if self.tbPlayerStatsMap[nPlayerId] == nil then
        if tbCharacter.ObjectType == GameObjectTypeDef.PlayerSelf then
            local tbCharacterStats = CreateStats(BattleStatsTypeDef.Player, tbCharacter)
            self.tbPlayerStatsMap[nPlayerId] = tbCharacterStats
            log("BattleDataStatisticsSystem:RegisterCharacter: ", tbCharacter.szName, nPlayerId)

            local nTeamId = tbCharacterStats:GetProperty(PropertyDef.TEAMID)
            if nTeamId > 0 then
                RegisterTeam(self, nTeamId)
            end

            local nGrade = tbCharacterStats:GetProperty(PropertyDef.GRADE)
            if nGrade > 0 then
                self.tbCombatStats:SetProperty(PropertyDef.TOTALGRADE, nGrade)
            end

            local nPlayerCount = self.tbCombatStats:GetProperty(PropertyDef.PLAYERCOUNT)
            nPlayerCount = nPlayerCount + 1
            self.tbCombatStats:SetProperty(PropertyDef.PLAYERCOUNT, nPlayerCount)
        else
            log("BattleDataStatisticsSystem:RegisterCharacter is not self : ", tbCharacter.szName)
        end
    end
end

local function ProgressiveIncreaseProperty(tbPlayerStats, szKey, nValue, nMinLimit, nMaxLimit)
    local nCurValue = tbPlayerStats:GetProperty(szKey)
    if nCurValue then
        nValue = nValue and nValue or 1
        local nFinalValue = nCurValue + nValue
        if nMinLimit and nFinalValue < nMinLimit then
            nFinalValue = nMinLimit
        elseif nMaxLimit and nFinalValue > nMaxLimit then
            nFinalValue = nMaxLimit
        end
        -- logdebug("battle stats change property ", szKey, nCurValue, nFinalValue)
        tbPlayerStats:SetProperty(szKey, nFinalValue)
    else
        logwarning("[ProgressiveIncreaseProperty] set property failed, this key is not register :", szKey)
    end
end

local function ProcessPlayerStatisticsEventFromLua(self, nPlayerId, szPropertyName, ...)
    if self.tbCombatStats == nil then
        return
    end
    if nPlayerId == nil then
        logwarning("[ProcessPlayerStatisticsEventFromLua] invalid playerid")
        return
    end
    local tbPlayerStats = self:GetCharacterStats(nPlayerId)
    if tbPlayerStats then
        ProgressiveIncreaseProperty(tbPlayerStats, szPropertyName, ...)
    else
        logwarning("[ProcessPlayerStatisticsEventFromLua] instanceId not found, the playerid is :", nPlayerId)
    end
end

local function ProcessPlayer1ToPlayer2Damage(self, nPlayerId1, nPlayerId2, szPropertyName, tbDamageData)
    if nPlayerId1 == nil then
        logwarning("[ProcessPlayer1ToPlayer2StaticsEventFromLua] invalid playerid")
        return
    end
    local tbPlayerStats = self:GetCharacterStats(nPlayerId1)
    if tbPlayerStats then
        tbPlayerStats:ProcessDamage(nPlayerId2, szPropertyName, tbDamageData)
    else
        logwarning("[ProcessPlayer1ToPlayer2StaticsEventFromLua] instanceId not found, the playerid is :", nPlayerId1)
    end
end

local function ProcessPlayerApplyedDamage(self, nPlayerId, tbDamageData, tbItems)
    if not nPlayerId then
        logwarning("[ProcessPlayerApplyedDamage] invalid playerid")
        return
    end

    local tbPlayerStats = self.tbPlayerStatsMap[nPlayerId]
    if tbPlayerStats then
        -- 玩家死亡回放受伤统计
        if tbItems == nil then
            tbPlayerStats:ProcessDamaged(tbDamageData)
        else
            -- 物资统计
            tbPlayerStats:RecordItems(tbItems)
            -- 助攻者统计
            local tbDamageArray = tbPlayerStats:GetDamagedStats()
            local tbAssist = {}
            for i, v in ipairs(tbDamageArray) do
                local nOtherPlayerId = BattleStatsHelper:GetPlayerId(v)
                if tbDamageData.nCauserId ~= nOtherPlayerId then
                    local tbOtherPlayerStats = nOtherPlayerId ~= nil and self.tbPlayerStatsMap[nOtherPlayerId]
                    if tbOtherPlayerStats then
                        if tbAssist[nOtherPlayerId] == nil then
                            tbAssist[nOtherPlayerId] = 1
                            ProcessPlayerStatisticsEventFromLua(self, nOtherPlayerId, PropertyDef.ASSISTCOUNT)
                        end
                    end
                end
            end
        end
    else
        local tbBotStats = self.tbBotStatsMap[nPlayerId]
        if tbBotStats then
            -- 机器人不需要死亡回放统计
            if tbItems ~= nil then
                -- 机器人物资统计
                tbBotStats:RecordItems(tbItems)
            end
        else
            logwarning("[ProcessPlayerApplyedDamage] instanceId not found, the playerid is :", nPlayerId)
        end
    end
end

local function RegisterCombat(self)
    DestroyCombatStats(self)
    self.tbCombatStats = CreateStats(BattleStatsTypeDef.Combat)
    self.tbCombatStats:CaptureDungeonStartStatisticsData()
    DestroyStats(self)
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        self:RegisterCharacter(Object)
    end
end

local function PlayerLoginOut(self, tbGamePlayer)
    local nPlayerId = tbGamePlayer:GetPlayerId()
    local tbPlayerStats = self:GetCharacterStats(nPlayerId)
    if tbPlayerStats then
        tbPlayerStats:SetProperty(PropertyDef.LOGINOUT, 1)
    end
end

local function IsObjectValid(tbGameObject)
    if tbGameObject and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        return true
    end
    return false
end

local function IsAttackSelfTeam(self, nCauserPlayerId, nTakerPlayerId)
    if nCauserPlayerId == nTakerPlayerId then
        return true
    end

    local tbCauserStats = self:GetCharacterStats(nCauserPlayerId)
    local tbTakerStats = self:GetCharacterStats(nTakerPlayerId)
    if tbCauserStats  == nil or tbTakerStats == nil then
        return false
    end
    local nCauserTeamId = tbCauserStats:GetProperty(PropertyDef.TEAMID)
    local nTakerTeamId = tbTakerStats:GetProperty(PropertyDef.TEAMID)
    if nCauserTeamId == nTakerTeamId and nCauserTeamId > 0 then
        return true
    end

    return false
end

local function GetDamageSource(nDamageType)
    if nDamageType < DamageTypeEx.SHIP_BEGIN then
        return DAMAGE_SOURCE.OTHER
    elseif nDamageType >= DamageTypeEx.SHIP_BEGIN and nDamageType <= DamageTypeEx.SHIP_END then
        return DAMAGE_SOURCE.SHIP
    elseif nDamageType >= DamageTypeEx.HUMAN_BEGIN and nDamageType <= DamageTypeEx.HUMAN_END then
        return DAMAGE_SOURCE.HUMAN
    end
end

local function IsNeedStatistics(tbGameObject, bCareBot)
    if not IsObjectValid(tbGameObject) then
        return false
    end

    if bCareBot then
        if GlobalVariableSystem.bEnableAIGameCore and GlobalVariableSystem.EnableDLAgent then
            return true
        elseif BattlePrepareSystem:IsBot(tbGameObject.nPlayerId) then
            return false
        else
            return true
        end
    else
        return true
    end
end

local function OnTookDamage(self, tbTaker, tbCauser, nDamage, nDamageType)
    if nDamage == nil or nDamage <= 0 then
        return
    end

    if IsNeedStatistics(tbTaker) then
        local nTakerPlayerId = tbTaker.nPlayerId
        local tbDamageData = BattleStatsHelper.MakeDamageData(tbTaker, tbCauser, nDamage, nDamageType)

        if IsNeedStatistics(tbCauser, true) then
            local nCauserPlayerId = tbCauser.nPlayerId
            local bSelfTeam = IsAttackSelfTeam(self, nCauserPlayerId, nTakerPlayerId)
            if (not bSelfTeam) then
                local nDamageSource = GetDamageSource(nDamageType)
                -- if tbCauser:IsShip() then
                if nDamageSource == DAMAGE_SOURCE.SHIP then
                    ProcessPlayerStatisticsEventFromLua(self, nCauserPlayerId, PropertyDef.SHIPHITCOUNT)
                    ProcessPlayerStatisticsEventFromLua(self, nCauserPlayerId, PropertyDef.APPLYDAMAGETOSHIP, math.floor(nDamage))
                    if tbDamageData.bIsCoreRegion then
                        ProcessPlayerStatisticsEventFromLua(self, nCauserPlayerId, PropertyDef.HITSHIPCORECOUNT)
                    end
                    ProcessPlayer1ToPlayer2Damage(self, nCauserPlayerId, nTakerPlayerId, PropertyDef.APPLYDAMAGETOSHIP, tbDamageData)
                -- elseif tbCauser:IsHuman() then
                elseif nDamageSource == DAMAGE_SOURCE.HUMAN then
                    ProcessPlayerStatisticsEventFromLua(self, nCauserPlayerId, PropertyDef.HUMANHITCOUNT)
                    ProcessPlayerStatisticsEventFromLua(self, nCauserPlayerId, PropertyDef.APPLYDAMAGETOHUMAN, math.floor(nDamage))
                    if tbDamageData.bIsCoreRegion then
                        ProcessPlayerStatisticsEventFromLua(self, nCauserPlayerId, PropertyDef.HITHUMANCORECOUNT)
                    end
                    ProcessPlayer1ToPlayer2Damage(self, nCauserPlayerId, nTakerPlayerId, PropertyDef.APPLYDAMAGETOHUMAN, tbDamageData)
                end
            end
        end

        if IsNeedStatistics(tbTaker, true) then
            if tbTaker:IsShip() then
                ProcessPlayerStatisticsEventFromLua(self, nTakerPlayerId, PropertyDef.SHIPAPPLIEDDAMAGE, math.floor(nDamage))
            else
                ProcessPlayerStatisticsEventFromLua(self, nTakerPlayerId, PropertyDef.HUMANAPPLIEDDAMAGE, math.floor(nDamage))
            end
            ProcessPlayerApplyedDamage(self, nTakerPlayerId, tbDamageData)
        end
    end
end

local function OnTookCure(self, tbTaker, tbCauser, nCure)
    if nCure == nil or nCure <= 0 then
        return
    end
    if IsNeedStatistics(tbCauser) and IsNeedStatistics(tbTaker, true) then
        nCure = math.floor(nCure)
        local nPlayerId = tbTaker.nPlayerId
        if tbTaker:IsShip() then
            ProcessPlayerStatisticsEventFromLua(self, nPlayerId, PropertyDef.APPLYCURETOSHIP , nCure)
        elseif tbTaker:IsHuman() then
            ProcessPlayerStatisticsEventFromLua(self, nPlayerId, PropertyDef.APPLYCURETOHUMAN , nCure)
        end
        -- log("[stats] --- cure ", nPlayerId, nCure)
    end
end

local function OnRescuing(self, tbTaker, bIsRescuing)
    if bIsRescuing and IsNeedStatistics(tbTaker, true) then
        ProcessPlayerStatisticsEventFromLua(self, tbTaker.nPlayerId, PropertyDef.RESCUINGCOUNT)
    end
end

local function OnDyingChange(self, tbTaker, bIsDying)
    if IsObjectValid(tbTaker) then
        -- 机器人不做死亡统计
        if not BattlePrepareSystem:IsBot(tbTaker.nPlayerId) then
            local tbPlayerStats = self:GetPlayerStats(tbTaker.nPlayerId)
            if tbPlayerStats ~= nil then
                local tbPropertyComponent = tbTaker:GetCurrentPropertyComponent()
                local nCurHp = tbPropertyComponent:GetHp()
                if nCurHp == 0 and not bIsDying then
                    log("OnDyingChange dead", tbTaker.nPlayerId)
                else
                    log("OnDyingChange ", tbTaker.nPlayerId, nCurHp, tbTaker:IsDead())
                    tbPlayerStats:HitDown(bIsDying)
                end
            else
                logwarning("[OnDyingChange] stats not found, the playerid is :", tbTaker.nPlayerId)
            end
        end
    end
end

local function OnDecreasePlayerBattleItem(self, tbPlayer, nItemTemplateId, nCount)
    if IsNeedStatistics(tbPlayer, true) then
        local nPlayerId = tbPlayer.nPlayerId

        local tbPlayerStats = self:GetCharacterStats(nPlayerId)
        if tbPlayerStats then
            tbPlayerStats:ConsumeItem(nItemTemplateId, nCount)
        else
            logwarning("[OnDecreasePlayerBattleItem] instanceId not found, the playerid is :", nPlayerId)
        end
    end
end

local function OnBuildBattleItem(self, tbPlayer, nItemInstanceId, nItemTemplateId)
    if IsNeedStatistics(tbPlayer, true) then
        local nPlayerId = tbPlayer.nPlayerId
        local tbPlayerStats = self:GetCharacterStats(nPlayerId)
        if tbPlayerStats then
            tbPlayerStats:BuildItem(nItemTemplateId, 1)
        else
            logwarning("[OnBuildBattleItem] instanceId not found, the playerid is :", nPlayerId)
        end
    end
end

local function OnMeleeAttack(self, tbCauser)
    if IsNeedStatistics(tbCauser, true) then
        ProcessPlayerStatisticsEventFromLua(self, tbCauser.nPlayerId, PropertyDef.MELEEATTACKCOUNT)
    end
end

local function OnEnterPoisonCircle(self, tbPlayer)
    if not tbPlayer:IsDead() and IsNeedStatistics(tbPlayer, true) then
        local tbPlayerStats = self:GetCharacterStats(tbPlayer.nPlayerId)
        if not tbPlayerStats then
            return
        end
        local nLeaveTime = tbPlayerStats:GetProperty(PropertyDef.POISONCIRCLELEAVETIME)
        if nLeaveTime <= 0 then
            return
        end
        local nTime = tbPlayerStats:GetProperty(PropertyDef.POISONCIRCLETIME)
        local nEnterTime = GlobalVariableSystem:GetLocalTime()
        if nEnterTime - nLeaveTime > nTime then
            tbPlayerStats:SetProperty(PropertyDef.POISONCIRCLETIME, nEnterTime - nLeaveTime)
        end
        tbPlayerStats:SetProperty(PropertyDef.POISONCIRCLELEAVETIME, 0)
    end
end

local function OnLeavePoisonCircle(self, tbPlayer)
    if not tbPlayer:IsDead() and IsNeedStatistics(tbPlayer, true) then
        local tbPlayerStats = self:GetCharacterStats(tbPlayer.nPlayerId)
        if not tbPlayerStats then
            return
        end
        tbPlayerStats:SetProperty(PropertyDef.POISONCIRCLELEAVETIME, GlobalVariableSystem:GetLocalTime())
    end
end

local function OnChangeDisplay(self, tbPlayer)
    -- 人船切换，清除被击统计，机器人不统计
    if not IsObjectValid(tbPlayer) or BattlePrepareSystem:IsBot(tbPlayer.nPlayerId) then
        return
    end
    local tbPlayerStats = self:GetPlayerStats(tbPlayer.nPlayerId)
    if not tbPlayerStats then
        return
    end
    tbPlayerStats:ClearDamaged()
end

local function OnPawnDead(self, tbDead, tbCauser)
    if tbDead == nil then
        return
    end
    if tbDead.ObjectType ~= GameObjectTypeDef.PlayerSelf and tbDead.ObjectType ~= GameObjectTypeDef.Npc then
        return
    end
    local tbDamageData = BattleStatsHelper.MakeDamageData(tbDead, tbCauser, 0)
    local bDeadNPC = tbDead:GetObjectType() == GameObjectTypeDef.Npc
    if IsNeedStatistics(tbCauser, true) then
        if not IsAttackSelfTeam(self, tbCauser.nPlayerId, tbDead.nPlayerId) then
            if not bDeadNPC then
                ProcessPlayerStatisticsEventFromLua(self, tbCauser.nPlayerId, PropertyDef.KILL)
                ProcessPlayer1ToPlayer2Damage(self, tbCauser.nPlayerId, tbDead.nPlayerId, PropertyDef.KILL, tbDamageData)
                if tbCauser:IsShip() then
                    if tbDead:IsShip() then
                        ProcessPlayerStatisticsEventFromLua(self, tbCauser.nPlayerId, PropertyDef.SHIPKILLSHIP)
                    else
                        ProcessPlayerStatisticsEventFromLua(self, tbCauser.nPlayerId, PropertyDef.SHIPKILLHUMAN)
                    end
                elseif tbCauser:IsHuman() then
                    if tbDead:IsHuman() then
                        ProcessPlayerStatisticsEventFromLua(self, tbCauser.nPlayerId, PropertyDef.HUMANKILLHUMAN)
                    end
                end
            else
                local tbMemberIds = BattleStatsHelper:GetTeamMemberIds(tbCauser)
                if tbMemberIds ~= nil then
                    for i, v in ipairs(tbMemberIds) do
                        ProcessPlayerStatisticsEventFromLua(self, v, PropertyDef.KILLNPC)
                    end
                end
                -- ProcessPlayerStatisticsEventFromLua(self, tbCauser.nPlayerId, PropertyDef.KILLNPC)
            end
        end
    end
    if IsNeedStatistics(tbDead, true) and not bDeadNPC then
        if self.tbCombatStats then
            local nSurvivalTime = self.tbCombatStats:GetDungeonElapsedTime()
            ProcessPlayerStatisticsEventFromLua(self, tbDead.nPlayerId, PropertyDef.SURVIVALTIME, nSurvivalTime)
        end
        -- 死后停止在毒圈外的计时
        OnEnterPoisonCircle(self, tbDead)

        ProcessPlayerStatisticsEventFromLua(self, tbDead.nPlayerId, PropertyDef.DEATH)
        ProcessPlayerApplyedDamage(self, tbDead.nPlayerId, tbDamageData, BattleStatsHelper.GetAllItems(tbDead))
    end
end

local function OnShipWeaponFired(self, tbCharacter, tbShipWeaponItem, nFiringCount)
    if IsNeedStatistics(tbCharacter, true) then
        ProcessPlayerStatisticsEventFromLua(self, tbCharacter.nPlayerId, PropertyDef.SHIPLAUNCHCOUNT, nFiringCount)
    end
end

local function OnStatsMovementDistance(self, tbPlayer)
    if IsNeedStatistics(tbPlayer, true) and tbPlayer.pUEActor ~= nil then
        local nDistance = 0
        if tbPlayer:IsHuman() then
            local CharacterMovement = tbPlayer.pUEActor.CharacterMovement
            if CharacterMovement then
                nDistance = CharacterMovement:GetTotalDistance()
                if nDistance > 0 then
                    ProcessPlayerStatisticsEventFromLua(self, tbPlayer.nPlayerId, PropertyDef.HUMANMOVEDISTANCE, nDistance)
                end
            end
        elseif tbPlayer:IsShip() then
            local ShipMovement = tbPlayer.pUEActor.ShipMovementComponent
            if ShipMovement then
                nDistance = ShipMovement:GetTotalDistance()
                if nDistance > 0 then
                    ProcessPlayerStatisticsEventFromLua(self, tbPlayer.nPlayerId, PropertyDef.SHIPMOVEDISTANCE, nDistance)
                end
            end
        end
    end
end

local function OnStatsPaidRevive(self, tbPlayer)
    if IsNeedStatistics(tbPlayer, true) then
        ProcessPlayerStatisticsEventFromLua(self, tbPlayer.nPlayerId, PropertyDef.PAIDREVIVE)
    end
end

local function OnPickUpItem(self, tbPlayer, tbItem, bOk, nChestInstanceId)
    if not bOk or not nChestInstanceId then
        return
    end
    if self.tbCombatStats == nil then
        return
    end
    if not IsNeedStatistics(tbPlayer, true) then
        return
    end
    if not SceneItemHelper.IsAirDrop(nChestInstanceId) then
        return
    end

    local tbPlayerStats = self:GetCharacterStats(tbPlayer.nPlayerId)
    if not tbPlayerStats then
        return
    end

    local nTeamId = self.tbCombatStats:GetProperty(PropertyDef.FIRSTAIRDROP)
    if nTeamId <= 0 then
        nTeamId = tbPlayerStats:GetProperty(PropertyDef.TEAMID)
        self.tbCombatStats:SetProperty(PropertyDef.FIRSTAIRDROP, nTeamId)
    end
end

function BattleDataStatisticsSystem:BindEvent()
    local EventHelper = self.EventHelper
    -- EventManager:BindEventMethod(CommonEventDef.EV_ENTER_TRANSPORT_STEP, self, RegisterCombat)
    -- EventManager:BindEventMethod(CommonEventDef.EV_ENTER_PVPOCCUPY_STEP, self, RegisterCombat)
    EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, PlayerLoginOut)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTookDamage)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_CURE, self, OnTookCure)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, OnPawnDead)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_FIRED_SERVER, self, OnShipWeaponFired)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_RESCUING_CHANGED, self, OnRescuing)
    EventHelper:RegisterEvent(CommonEventDef.EV_DECREASE_PLAYER_BATTLE_ITEM_SERVER, self, OnDecreasePlayerBattleItem)
    EventHelper:RegisterEvent(CommonEventDef.EV_CONSUMABLE_ITEM_CONSUME_SUCCESS, self, OnDecreasePlayerBattleItem)
    EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_BUILD_FINISH_SERVER, self, OnBuildBattleItem)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_MELEE_ATTACK, self, OnMeleeAttack)
    EventHelper:RegisterEvent(CommonEventDef.EV_STATS_MOVEMENTDISTANCE, self, OnStatsMovementDistance)
    EventHelper:RegisterEvent(CommonEventDef.EV_STATS_PAIDREVIVE, self, OnStatsPaidRevive)
    EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_FINISH_SERVER, self, OnPickUpItem)
    EventHelper:RegisterEvent(CommonEventDef.EV_FFA_ENTER_POISONCIRCLE, self, OnEnterPoisonCircle)
    EventHelper:RegisterEvent(CommonEventDef.EV_FFA_LEAVE_POISONCIRCLE, self, OnLeavePoisonCircle)
    EventHelper:RegisterEvent(CommonEventDef.EV_END_CHANGEDISPLAY, self, OnChangeDisplay)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED, self, OnDyingChange)
end

function BattleDataStatisticsSystem:UnBindEvent()
    if self.EventHelper ~= nil then
    	self.EventHelper:UnregisterAll()
    end
    -- -- EventManager:UnBindEventMethod(CommonEventDef.EV_ENTER_TRANSPORT_STEP, self, RegisterCombat)
    -- -- EventManager:UnBindEventMethod(CommonEventDef.EV_ENTER_PVPOCCUPY_STEP, self, RegisterCombat)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, PlayerLoginOut)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTookDamage)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_ON_TAKE_CURE, self, OnTookCure)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, OnPawnDead)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_ON_SHIP_WEAPON_FIRED_SERVER, self, OnShipWeaponFired)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_RESCUING_CHANGED, self, OnRescuing)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_DECREASE_PLAYER_BATTLE_ITEM_SERVER, self, OnDecreasePlayerBattleItem)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_CONSUMABLE_ITEM_CONSUME_SUCCESS, self, OnDecreasePlayerBattleItem)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_BUILD_FINISH_SERVER, self, OnBuildBattleItem)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_ON_MELEE_ATTACK, self, OnMeleeAttack)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_STATS_MOVEMENTDISTANCE, self, OnStatsMovementDistance)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_STATS_PAIDREVIVE, self, OnStatsPaidRevive)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_FINISH_SERVER, self, OnPickUpItem)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_FFA_ENTER_POISONCIRCLE, self, OnEnterPoisonCircle)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_FFA_LEAVE_POISONCIRCLE, self, OnLeavePoisonCircle)
end

function BattleDataStatisticsSystem:Init()
    self.bIsActive = false
    self.tbPlayerStatsMap = {}
    self.tbTeamStatsMap = {}
    self.tbBotStatsMap = {}
	self.EventHelper = SelfEventHelper()

    if GlobalVariableSystem:IsServerLogic() then
        self:Activate()
    end

    return true
end

function BattleDataStatisticsSystem:Uninit()
    if GlobalVariableSystem:IsServerLogic() and self.bIsActive then
        self:Deactivate()
    end
    self.tbPlayerStatsMap = nil
    self.tbTeamStatsMap = nil
    self.tbBotStatsMap = nil
end

function BattleDataStatisticsSystem:Activate()
    log("BattleDataStatisticsSystem:Activate")
    if(self.bIsActive) then
        return
    end

    self.bIsActive = true

    RegisterCombat(self)

    self:BindEvent()
end

function BattleDataStatisticsSystem:Deactivate()
    log("BattleDataStatisticsSystem:Deactivate")
    self.bIsActive = false

    DestroyStats(self)
    DestroyCombatStats(self)

    self:UnBindEvent()
end

function BattleDataStatisticsSystem:IsActivated()
    return self.bIsActive
end

function BattleDataStatisticsSystem:GetPlayerStatsPropertyByPlayerId(nPlayerId, szKey)
    if self.tbPlayerStatsMap then
        local tbPlayerStats = self.tbPlayerStatsMap[nPlayerId]
        if tbPlayerStats then
            return tbPlayerStats:GetProperty(szKey)
        end
    end
    return nil
end

function BattleDataStatisticsSystem:GetCombatProperty(szKey)
    if self.tbCombatStats then
        return self.tbCombatStats:GetProperty(szKey)
    end
    return nil
end

function BattleDataStatisticsSystem:GetAllPlayerStats()
    return self.tbPlayerStatsMap
end

function BattleDataStatisticsSystem:ResetPlayer(nPlayerId)
    local tbPlayerStats = self.tbPlayerStatsMap[nPlayerId]
    if tbPlayerStats and tbPlayerStats.Reset then
        tbPlayerStats:Reset()
    end
end

function BattleDataStatisticsSystem:GetCharacterStats(nPlayerId)
    local tbPlayerStats = self:GetPlayerStats(nPlayerId)
    if tbPlayerStats ~= nil then
        return tbPlayerStats
    end
    tbPlayerStats = self:GetBotStats(nPlayerId)
    return tbPlayerStats
end

function BattleDataStatisticsSystem:GetPlayerStats(nPlayerId)
    return self.tbPlayerStatsMap[nPlayerId]
end

function BattleDataStatisticsSystem:GetTeamStats(nTeamId)
    return self.tbTeamStatsMap[nTeamId]
end

function BattleDataStatisticsSystem:GetBotStats(nPlayerId)
    return self.tbBotStatsMap[nPlayerId]
end

function BattleDataStatisticsSystem:StatisticsCharacterResult(tbPlayer, nRank)
    if not IsObjectValid(tbPlayer, true) then
        return
    end

    local nPlayerId = tbPlayer.nPlayerId
    local tbPlayerStats = self:GetCharacterStats(nPlayerId)
    if tbPlayerStats == nil then
        return
    end

    -- if tbPlayerStats:GetProperty(PropertyDef.PLAYERRANK) > 0 then
    --     log("StatisticsCharacterResult already ", tbPlayer.szName, tbPlayerStats:GetProperty(PropertyDef.PLAYERRANK), nRank)
    --     return
    -- end

    if self.tbCombatStats then
        local nSurvivalTime = self.tbCombatStats:GetDungeonElapsedTime()
        if tbPlayerStats ~= nil then
            local nTime = tbPlayerStats:GetProperty(PropertyDef.SURVIVALTIME)

            --结算时，玩家没死，则设置存活时间
            if nTime <= 0 then
                tbPlayerStats:SetProperty(PropertyDef.SURVIVALTIME, nSurvivalTime)
            end
            tbPlayerStats:SetProperty(PropertyDef.GAMETIME, nSurvivalTime)
        end

    end
    log("StatisticsCharacterResult", tbPlayer.szName, nRank)
    OnStatsMovementDistance(self, tbPlayer)
    OnEnterPoisonCircle(self, tbPlayer)

    -- if tbPlayer:IsShip() then
        ProcessPlayerStatisticsEventFromLua(self, nPlayerId, PropertyDef.GAMEOVERUSESHIP, tbPlayer:GetShipTemplateId())
    -- end

    if nRank then
        tbPlayerStats:SetProperty(PropertyDef.PLAYERRANK, nRank)
        if nRank ~= 1 then
            tbPlayerStats:SetProperty(PropertyDef.DEATH, 1)
        end
    end
    if tbPlayerStats:GetItems() == nil then
        local tbItems = BattleStatsHelper.GetAllItems(tbPlayer)
        tbPlayerStats:RecordItems(tbItems)
    end
end

function BattleDataStatisticsSystem:StatisticsTeamResult(nTeamId, nRank)
    local tbTeamStats = self.tbTeamStatsMap[nTeamId]
    if tbTeamStats then
        tbTeamStats:SetProperty(PropertyDef.TEAMRANK, nRank)
    end
end

function BattleDataStatisticsSystem:StatisticsPlayerProperty(nPlayerId, szPropertyName, ...)

end

function BattleDataStatisticsSystem:SendFinishPlayerStatisticsToClient(nPlayerId)

end

return BattleDataStatisticsSystem()