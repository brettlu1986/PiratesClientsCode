-----------------------------------------------------
--File Name    : AbilityBuffClient.lua
--Author       : Song Fuhao
--Create Time  : 2019-07-10
--Description  : Buff客户端逻辑类，主要是处理特效逻辑和存储Buff数据
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityBuffClient = luaclass("AbilityBuffClient")

local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleAbilitySystem = require("BattleAbilitySystem")
local BattleBuffDataTable = require("BattleBuffDataTable")
local BattleAbilityDefine = require("BattleAbilityDefine")
local BattleBuffResDataTable = require("BattleBuffResDataTable")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local SoundManager = require("SoundManager")

local EffectiveTypeDefine = BattleAbilityDefine.EFFECTIVE_TARGET_TYPE
local SOUND_EFFECT_FADE_OUT_DURATION = 1

local FX_TYPE_BEGIN = 0
local FX_TYPE_PERSISTENT = 1
local FX_TYPE_END = 2

AbilityBuffClient.Owner = nil
AbilityBuffClient.OwnerPawn = nil
AbilityBuffClient.nTemplateId = 0
AbilityBuffClient.nLevel = 1
AbilityBuffClient.nUpdateTime = 0
AbilityBuffClient.nOverlapCount = 0
AbilityBuffClient.nInstanceId = 0

AbilityBuffClient.tbTemplate = nil
AbilityBuffClient.tbResTemplate = nil

AbilityBuffClient.tbPersistentFxRetIds = nil
AbilityBuffClient.nPersistentSoundRetId = nil
AbilityBuffClient.nPostProcessRetId = nil
AbilityBuffClient.nLensEffectId = nil
AbilityBuffClient.bWaitRestartOnSwitch = false

local function GetEffect(self, nFxType)
    if self.OwnerPawn:IsHuman() then
        if nFxType == FX_TYPE_BEGIN then
            return self.tbResTemplate.tbHumanBeginFxIds
        elseif nFxType == FX_TYPE_PERSISTENT then
            return self.tbResTemplate.tbHumanPersistentFxIds
        elseif nFxType == FX_TYPE_END then
            return self.tbResTemplate.tbHumanEndFxIds
        end
    else
        if nFxType == FX_TYPE_BEGIN then
            return self.tbResTemplate.tbShipBeginFxIds
        elseif nFxType == FX_TYPE_PERSISTENT then
            return self.tbResTemplate.tbShipPersistentFxIds
        elseif nFxType == FX_TYPE_END then
            return self.tbResTemplate.tbShipEndFxIds
        end
    end
    return nil
end

-- 是否为有效的目标状态
local function IsEffectiveTarget(self)
    local nEffectiveTargetType = self.tbTemplate.nEffectiveTargetType
    if nEffectiveTargetType == EffectiveTypeDefine.SHIP_AND_HUMAN then
        return true
    end
    local bIsHuman = self.OwnerPawn:IsHuman()
    if (bIsHuman and nEffectiveTargetType == EffectiveTypeDefine.HUMAN) or
        (not bIsHuman and nEffectiveTargetType == EffectiveTypeDefine.SHIP) then
        return true
    end
    return false
end

-- 播放开始特效
local function PlayStartEffect(self)
    if (not self.tbResTemplate) or (not IsEffectiveTarget(self)) then
        return
    end

    BattleAbilitySystem:PlayParticleEffects(self.OwnerPawn, GetEffect(self, FX_TYPE_BEGIN))
    -- if self.OwnerPawn:GetObjectType() == GameObjectTypeDef.PlayerSelf then
    --     BattleAbilitySystem:PlaySound(self.OwnerPawn, self.tbResTemplate.szBeginSoundRes, false)
    -- end
end

-- 播放结束特效
local function PlayEndEffect(self)
    if (not self.tbResTemplate) or (not IsEffectiveTarget(self)) then
        return
    end

    BattleAbilitySystem:PlayParticleEffects(self.OwnerPawn, GetEffect(self, FX_TYPE_END))
    -- if self.OwnerPawn:GetObjectType() == GameObjectTypeDef.PlayerSelf then
    --     BattleAbilitySystem:PlaySound(self.OwnerPawn, self.tbResTemplate.szEndSoundRes, false)
    -- end
end

-- 播放持续状态特效
local function PlayPersistentEffect(self)
    if (not self.tbResTemplate) or (not IsEffectiveTarget(self)) then
        return
    end

    BattleAbilitySystem:PlayMaterialEffect(self.OwnerPawn, self.tbResTemplate.nMaterialEffectType, self.tbTemplate.nTime)
    self.tbPersistentFxRetIds = BattleAbilitySystem:PlayParticleEffects(self.OwnerPawn, GetEffect(self, FX_TYPE_PERSISTENT))

    -- 玩家自己的Buff才有后处理
    if self.OwnerPawn:GetObjectType() == GameObjectTypeDef.PlayerSelf then
        -- self.nPersistentSoundRetId = BattleAbilitySystem:PlaySound(self.OwnerPawn, self.tbResTemplate.szPersistentSoundRes, false, false)
        self.nPostProcessRetId = BattleAbilitySystem:PlayPostProcessEffect(self.OwnerPawn, self.tbResTemplate.nPostProcessEffectId)
        self.nLensEffectId = BattleAbilitySystem:PlayLensEffect(self.OwnerPawn, self.tbResTemplate.szLensEffectRes)
        EventManager:OnFireEvent(ClientEventDef.EV_POST_PROCESS_EFFECT, true)
        if self.tbResTemplate.nPersistentSoundEffectId > 0 then
            self.tbPersistentSoundEffect = SoundManager:PlaySound2D(self.tbResTemplate.nPersistentSoundEffectId, true)
        end
    end
end

-- 更新持续状态特效(主要是刷新时长)
local function UpdatePersistentEffect(self)
    if (not self.tbResTemplate) or (not IsEffectiveTarget(self)) then
        return
    end

    BattleAbilitySystem:UpdateParticleEffects(self.OwnerPawn, self.tbPersistentFxRetIds)
    BattleAbilitySystem:UpdateMaterialEffect(self.OwnerPawn)

    -- 玩家自己的Buff才有后处理
    if self.OwnerPawn:GetObjectType() == GameObjectTypeDef.PlayerSelf then
        -- BattleAbilitySystem:UpdateSound(self.OwnerPawn, self.nPersistentSoundRetId)
        BattleAbilitySystem:UpdatePostProcessEffect(self.OwnerPawn, self.nPostProcessRetId)
    end
end

-- 停止持续状态特效
local function StopPersistentEffect(self)
    if not self.tbResTemplate then
        return
    end

    BattleAbilitySystem:StopParticleEffects(self.OwnerPawn, self.tbPersistentFxRetIds)
    BattleAbilitySystem:StopMaterialEffect(self.OwnerPawn)

    -- 玩家自己的Buff才有后处理
    if self.OwnerPawn:GetObjectType() == GameObjectTypeDef.PlayerSelf then
        -- BattleAbilitySystem:StopSound(self.OwnerPawn, self.nPersistentSoundRetId)
        BattleAbilitySystem:StopPostProcessEffect(self.OwnerPawn, self.nPostProcessRetId)
        BattleAbilitySystem:StopLensEffect(self.OwnerPawn, self.nLensEffectId)
        EventManager:OnFireEvent(ClientEventDef.EV_POST_PROCESS_EFFECT, false)
        if self.tbPersistentSoundEffect then
            self.tbPersistentSoundEffect:FadeOut(SOUND_EFFECT_FADE_OUT_DURATION)
            self.tbPersistentSoundEffect = nil
        end
    end

    self.tbPersistentFxRetIds = nil
    self.nPersistentSoundRetId = nil
    self.nPostProcessRetId = nil
end

function AbilityBuffClient:Create(Owner, nInstanceId, nTemplateId, nLevel, nOverlapCount, nUpdateTime)
    self.Owner = Owner
    self.OwnerPawn = Owner.Owner
    self.nInstanceId = nInstanceId
    self.nTemplateId = nTemplateId
    self.nLevel = nLevel
    self.nOverlapCount = nOverlapCount
    self.nUpdateTime = nUpdateTime

    self.tbTemplate = BattleBuffDataTable:GetTemplate(nTemplateId)
    if not self.tbTemplate then
        logerror('AbilityBuffClient Create failed, cannot find template. nTemplateId =', nTemplateId)
        return
    end

    self.tbResTemplate = BattleBuffResDataTable:GetTemplate(self.tbTemplate.nResId)

    PlayStartEffect(self)
    PlayPersistentEffect(self)
end

function AbilityBuffClient:Update(nOverlapCount, nUpdateTime)
    self.nOverlapCount = nOverlapCount
    self.nUpdateTime = nUpdateTime
    UpdatePersistentEffect(self)
end

function AbilityBuffClient:Destroy(bImmediate)
    StopPersistentEffect(self)
    if not bImmediate then
        PlayEndEffect(self)
    end
end

-- @public
-- 用于人船切换后继续启用特效
function AbilityBuffClient:StartOnSwitch()
    if self.bWaitRestartOnSwitch then
        self.bWaitRestartOnSwitch = false
        PlayPersistentEffect(self)
    end
end

-- @public
-- 用于人船切换后停止特效
function AbilityBuffClient:StopOnSwitch()
    StopPersistentEffect(self)
    self.bWaitRestartOnSwitch = true
end

return AbilityBuffClient
