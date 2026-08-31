-----------------------------------------------------
--File Name    : BattleExperienceSystem.lua
--Author       : Song Fuhao
--Create Time  : 2020-09-15
--Description  : 战斗体验感受增量逻辑
-----------------------------------------------------
local BattleExperienceSystem = {}

local SelfTimerHelper = require("SelfTimerHelper")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local SoundExperienceHelper = require("SoundExperienceHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local DamageHurtDef = require("DamageHurtDef")
local DungeonCommonProtoNames = require("DungeonCommonProtoNames")
local BattleTeammateSystem = require("BattleTeammateSystem")
local BattleExperienceIni = require("BattleExperienceIni")
local GameCameraShakeHelper = require("GameCameraShakeHelper")
local ShipWeaponSubCategoryDef = require("ShipWeaponSubCategoryDef")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local BattleAbilitySystem = require("BattleAbilitySystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local GenderTypeDefine = require("GenderTypeDefine")
local SoundManager = require("SoundManager")
local TutorialDungeonIni = require("TutorialDungeonIni")
local DungeonRepProtoNames = require("DungeonRepProtoNames")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

local EXPERIENCE_SOUND_ENABLED              = BattleExperienceIni.tbSound.bEnabled
local EXPERIENCE_SHAKE_ENABLED              = BattleExperienceIni.tbShake.bEnabled
local EXPERIENCE_POST_PROCESS_ENABLED       = BattleExperienceIni.tbPostProcess.bEnabled

local REPEAT_HIT_CORE_DURATION              = BattleExperienceIni.tbSound.nRepeatHitCoreDuration
local REPEAT_HIT_CORE_COUNT                 = BattleExperienceIni.tbSound.nRepeatHitCoreCount

local LOW_LEVEL_HP_PERCENT                  = BattleExperienceIni.tbPostProcess.nLowLevelHpPercent

local ENTER_LOW_LEVEL_HP_SHIP_SOUND_ID      = BattleExperienceIni.tbSoundIds.nEnterLowLevelHPShipSound
local ENTER_LOW_LEVEL_HP_MALE_SOUND_ID      = BattleExperienceIni.tbSoundIds.nEnterLowLevelHPMaleSound
local ENTER_LOW_LEVEL_HP_FEMALE_SOUND_ID    = BattleExperienceIni.tbSoundIds.nEnterLowLevelHPFemaleSound
local LOW_LEVEL_HP_MALE_SOUND_ID            = BattleExperienceIni.tbSoundIds.nLowLevelHPMaleSound
local LOW_LEVEL_HP_FEMALE_SOUND_ID          = BattleExperienceIni.tbSoundIds.nLowLevelHPFemaleSound

local SOUND_HIT_CORE                        = BattleExperienceIni.tbSoundIds.nHitCore
local SOUND_REPEAT_HIT_CORE                 = BattleExperienceIni.tbSoundIds.nRepeatHitCore
local SOUND_ENEMY_DEAD_SHIP                 = BattleExperienceIni.tbSoundIds.nEnemyDead
local SOUND_ENEMY_INJURY_SHIP               = BattleExperienceIni.tbSoundIds.nEnemyInjury
local SOUND_HUMAN_CHANGE_TO_SHIP            = BattleExperienceIni.tbSoundIds.nHumanChangeToShip

local SHAKE_BE_HIT_CORE                     = BattleExperienceIni.tbShakeIds.nBeHitCore
local SHAKE_SAKER_FIRING                    = BattleExperienceIni.tbShakeIds.nFiringWithSaker
local SHAKE_SNIPE_GUN_FIRING                = BattleExperienceIni.tbShakeIds.nFiringWithSnipeGun

local POST_PROCESS_BE_HIT_CORE              = BattleExperienceIni.tbPostProcessIds.nBeHitCore
local POST_PROCESS_SNIPE_GUN_FIRING         = BattleExperienceIni.tbPostProcessIds.nFiringWithSnipeGun
local POST_PROCESS_SNIPE_GUN_FIRING_SPRAY   = BattleExperienceIni.tbPostProcessIds.nFiringSprayWithSnipeGun
local POST_PROCESS_LOW_LEVEL_HP             = BattleExperienceIni.tbPostProcessIds.nLowLevelHp

BattleExperienceSystem.bInLowLevelHP        = false
BattleExperienceSystem.bLastIsHuman         = false
BattleExperienceSystem.tbLowLevelHPSound    = nil

local function LOG(...)
    log("[BattleExperienceSystem]", ...)
end

local function PlayCameraShake(nShakeId)
    if EXPERIENCE_SHAKE_ENABLED and (nShakeId > 0) then
        LOG("PlayCameraShake", nShakeId)
        GameCameraShakeHelper.GameShake(nShakeId)
    end
end

local function PlayExperienceSound(nExperienceSoundId)
    if EXPERIENCE_SOUND_ENABLED and (nExperienceSoundId > 0) then
        LOG("PlayExperienceSound", nExperienceSoundId)
        SoundExperienceHelper:PlaySound(nExperienceSoundId)
    end
end

local function PlayPostProcessEffect(nPostProcessEffect)
    if EXPERIENCE_POST_PROCESS_ENABLED and (nPostProcessEffect > 0) then
        LOG("PlayPostProcessEffect", nPostProcessEffect)
        BattleAbilitySystem:PlayPostProcessEffect(GamePlayerSelfHelper:Get(), nPostProcessEffect)
    end
end

local function ResetHitCoreData(self)
    LOG("ResetHitCoreData")
    self.TimerHelper:ClearTimer(self.tbHitCoreTimer)
    self.tbHitCoreTimer = nil
    self.nHitCoreCount = 0
end

-- 命中敌方核心区
local function OnHitCore(self)
    self.nHitCoreCount = self.nHitCoreCount and (self.nHitCoreCount + 1) or 1
    LOG("play hit core sound, nHitCoreCount =", self.nHitCoreCount)
    PlayExperienceSound(SOUND_HIT_CORE)
    -- 倒计时结束前，连续多次命中核心区
    if self.tbHitCoreTimer and (self.nHitCoreCount >= REPEAT_HIT_CORE_COUNT) then
        ResetHitCoreData(self)
        LOG("play repeat hit core sound")
        PlayExperienceSound(SOUND_REPEAT_HIT_CORE)
    else
        self.tbHitCoreTimer = self.TimerHelper:NewTimerMethod(self, ResetHitCoreData, REPEAT_HIT_CORE_DURATION)
    end
end

local function OnBeHitCore(self)
    LOG("play be hit core shake")
    PlayCameraShake(SHAKE_BE_HIT_CORE)
    PlayPostProcessEffect(POST_PROCESS_BE_HIT_CORE)
end

local function OnTakeDamage(self, tbTaker, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, tbDamageExtraData)
    if tbDamageExtraData.nHurtTag ~= DamageHurtDef.HURT_CORE then
        return
    end
    if GamePlayerSelfHelper:IsPlayerSelf(tbCauser) then
        if tbTaker and (not BattleTeammateSystem:CheckTeammateWithSelf(tbTaker:GetServerInstanceId())) then
            OnHitCore(self)
        end
    elseif GamePlayerSelfHelper:IsPlayerSelf(tbTaker) then
        if tbCauser and (not BattleTeammateSystem:CheckTeammateWithSelf(tbCauser:GetServerInstanceId())) then
            OnBeHitCore(self)
        end
    end
end

local function OnFFABattleToast(self, nKillType, szKillerName, szDeadName, nKillerInstanceId, nDeadInstanceId, nAttackMethod, nWeaponTemplateId)
    local tbKiller = GameObjectSystem:FindByInstanceId(nKillerInstanceId)
    if GamePlayerSelfHelper:IsPlayerSelf(tbKiller) then
        if BattleTeammateSystem:CheckTeammateWithSelf(nDeadInstanceId) then
            return
        end
        local tbDead = GameObjectSystem:FindByInstanceId(nDeadInstanceId)
        if (not tbDead) or (not tbDead:IsShip()) then
            return
        end
        local tbKillToastType = DungeonCommonProtoNames.d2c_BattleKillToast_EType
        if nKillType == tbKillToastType.KILL then -- 击杀敌方
            LOG("play enemy dead sound")
            PlayExperienceSound(SOUND_ENEMY_DEAD_SHIP)
        elseif nKillType == tbKillToastType.INJURY then -- 重伤敌方
            LOG("play enemy injury sound")
            PlayExperienceSound(SOUND_ENEMY_INJURY_SHIP)
        end
    end
end

local function OnShipWeaponFiringOperationChanged(self, tbCharacter, WeaponItem, nFiringOperation)
    if GamePlayerSelfHelper:IsPlayerSelf(tbCharacter)
    and (nFiringOperation == ShipFiringOperationDef.START) then
        local nSubCategory = WeaponItem:GetSubCategory()
        -- 开镜时霰弹炮和长管炮需要震屏
        if BattleShipWeaponSystem:GetIsInAim_C() then
            if nSubCategory == ShipWeaponSubCategoryDef.SAKER then
                LOG("play saker firing shake")
                PlayCameraShake(SHAKE_SAKER_FIRING)
            elseif nSubCategory == ShipWeaponSubCategoryDef.SNIPE_GUN then
                LOG("play snipe gun firing shake")
                PlayCameraShake(SHAKE_SNIPE_GUN_FIRING)
            end
        end
        -- 长管炮开火时要带虚化
        if nSubCategory == ShipWeaponSubCategoryDef.SNIPE_GUN then
            LOG("play snipe gun firing post effect")
            PlayPostProcessEffect(POST_PROCESS_SNIPE_GUN_FIRING)
        end
    end
end

local function PlayEnterLowLevelHpSound()
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer:IsHuman() then
        local nGender = GamePlayerSelfHelper:GetGenderInBattle()
        if nGender == GenderTypeDefine.MALE then
            SoundManager:PlaySoundEffect(ENTER_LOW_LEVEL_HP_MALE_SOUND_ID, true)
        else
            SoundManager:PlaySoundEffect(ENTER_LOW_LEVEL_HP_FEMALE_SOUND_ID, true)
        end
    else
        SoundManager:PlaySoundEffect(ENTER_LOW_LEVEL_HP_SHIP_SOUND_ID, true)
    end
end

local function DestroyLowLevelHPSound(self)
    if self.tbLowLevelHPSound then
        SoundManager:DeleteSound(self.tbLowLevelHPSound)
        self.tbLowLevelHPSound = nil
    end
end

local function IsLowLevelHp(self, nMaxHp, nHpPercent)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if not tbPlayer:IsDead() and not tbPlayer:IsDying() then
        return (nMaxHp > 0) and (nHpPercent <= LOW_LEVEL_HP_PERCENT)
    end
    return false
end

local function SetIsInLowLevelHP(self, bInLowLevelHP, bReset)
    if (bInLowLevelHP == self.bInLowLevelHP) and (not bReset) then
        return
    end
    self.bInLowLevelHP = bInLowLevelHP
    LOG("SetIsInLowLevelHP: ", bInLowLevelHP)

    if not EXPERIENCE_SOUND_ENABLED then
        return
    end

    if bInLowLevelHP and (not bReset) then
        PlayEnterLowLevelHpSound()
        PlayPostProcessEffect(POST_PROCESS_LOW_LEVEL_HP)
    end

    DestroyLowLevelHPSound(self)

    if bInLowLevelHP then
        local tbPlayer = GamePlayerSelfHelper:Get()
        if tbPlayer:IsHuman() then
            local nGender = GamePlayerSelfHelper:GetGenderInBattle()
            if nGender == GenderTypeDefine.MALE then
                self.tbLowLevelHPSound = SoundManager:NewSound2D(LOW_LEVEL_HP_MALE_SOUND_ID, false)
            else
                self.tbLowLevelHPSound = SoundManager:NewSound2D(LOW_LEVEL_HP_FEMALE_SOUND_ID, false)
            end
            self.tbLowLevelHPSound:Play()
        end
    end
end

local function OnHpChanged(self, nHp, nMaxHp, nHpPercent)
    LOG("OnHpChanged", nHp, nMaxHp, nHpPercent)
    local bInLowLevelHP = IsLowLevelHp(self, nMaxHp, nHpPercent)
    SetIsInLowLevelHP(self, bInLowLevelHP)
end

local function OnPawnDead(self, tbDead)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbDead == tbPlayerSelf then
        SetIsInLowLevelHP(self, false)
    end
end

local function ResetLowLevelFlag(self, PropertyComponent)
    local nMaxHp = PropertyComponent:GetMaxHp()
    local nHpPercent = PropertyComponent:GetHpPercent()
    local bInLowLevelHP = IsLowLevelHp(self, nMaxHp, nHpPercent)
    SetIsInLowLevelHP(self, bInLowLevelHP, true)
end

local function IsTutorialDungeon()
    local nDungeonId = BattleGameModeSystem:GetDungeonId()
    return nDungeonId == TutorialDungeonIni.nDungeonId
end

local function OnRollForceBack(self, nRollDirection)
    if BattleShipWeaponSystem:GetIsInAim_C() then
        LOG("play snipe gun firing spray post effect")
        -- 长管炮开火后如果是开镜状态需要有水花后处理
        PlayPostProcessEffect(POST_PROCESS_SNIPE_GUN_FIRING_SPRAY)
    end
end

local function OnPlayerSelfReady(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local PropertyComponent = tbPlayer and tbPlayer:GetCurrentPropertyComponent()
    if PropertyComponent then
        ResetLowLevelFlag(self, PropertyComponent)
        LOG("Register OnHpChanged")
        self.EventHelper:RegisterLuaDelegate(PropertyComponent.OnHpChanged, OnHpChanged, self)
    end
    local DelegateComponent = tbPlayer and tbPlayer.DelegateComponent
    if DelegateComponent then
        self.EventHelper:RegisterLuaDelegate(DelegateComponent.OnRollForceBack, OnRollForceBack, self)
    end
    -- 硬代码写死。。。新手本屏蔽扬帆起航音效，避免与引导音效冲突
    if not IsTutorialDungeon() then
        if tbPlayer:IsShip() and self.bLastIsHuman then
            PlayExperienceSound(SOUND_HUMAN_CHANGE_TO_SHIP)
        end
        self.bLastIsHuman = tbPlayer:IsHuman()
    end
end

local function OnPlayerSelfUnready(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local PropertyComponent = tbPlayer and tbPlayer:GetCurrentPropertyComponent()
    if PropertyComponent then
        LOG("Unregister OnHpChanged")
        self.EventHelper:UnregisterLuaDelegate(PropertyComponent.OnHpChanged, OnHpChanged, self)
    end
    local DelegateComponent = tbPlayer and tbPlayer.DelegateComponent
    if DelegateComponent then
        self.EventHelper:UnregisterLuaDelegate(DelegateComponent.OnRollForceBack, OnRollForceBack, self)
    end
end

local function OnFFAProcessStateChanged(self, nState)
    if nState == DungeonRepProtoNames.rFFAProcessState_EState.PARACHUTING then
        -- 开始跳伞后重置标记，保证跳伞直接变船时不播放起航音效
        self.bLastIsHuman = false
    end
end

local function BindEvent(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE                                  , self, OnTakeDamage)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD                        , self, OnPawnDead)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_BATTLE_TOAST                                , self, OnFFABattleToast)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRING_OPERATION_CHANGED_CLIENT  , self, OnShipWeaponFiringOperationChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY                                , self, OnPlayerSelfReady)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_UNREADY                              , self, OnPlayerSelfUnready)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED                       , self, OnFFAProcessStateChanged)
end

function BattleExperienceSystem:Init()
    SoundExperienceHelper:Init()
    self.EventHelper = SelfEventHelper()
    self.TimerHelper = SelfTimerHelper()
    BindEvent(self)

    self.tbLowLevelHPSound = nil
end

function BattleExperienceSystem:Uninit()
    DestroyLowLevelHPSound(self)

    self.EventHelper:UnregisterAll()
    self.TimerHelper:ClearAllTimer()
    self.EventHelper = nil
    self.TimerHelper = nil
    SoundExperienceHelper:Uninit()
end

return BattleExperienceSystem