-----------------------------------------------------
--File Name    : BattlePropertyComponentBase.lua
--Author       : Song Fuhao
--Create Time  : 2018-09-10
--Description  : 战斗内业务逻辑相关的通用属性、方法定义
-----------------------------------------------------
local luaclass = require("luaclass")
local PropertyComponentBaseClass = require("PropertyComponentBase")
local BattlePropertyComponentBase = luaclass("BattlePropertyComponentBase", PropertyComponentBaseClass)

local AIHelper = require("AIHelper")
local D2CHelper = require("D2CHelper")
local DungeonIni = require("DungeonIni")
local LuaDelegate = require("LuaDelegate")
local DamageTypeEx = require("DamageTypeEx")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local DamageHurtDef = require("DamageHurtDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SelfEventHelperClass = require("SelfEventHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local IGNORE_POISON_DAMAGE_WHEN_BE_RESCUED = DungeonIni.tbDying.bIgnorePoisonDamageWhenBeRescued

-- 护盾不能抵挡的伤害类型
local tbShieldIgnoreDamageType      = {
    [DamageTypeEx.POISON_CIRCLE]    = true,
    [DamageTypeEx.DYING_REDUCE]     = true,
    [DamageTypeEx.KILL_SELF]        = true
}

-- 最小血量保护下可受伤害类型
local tbValidDamageTypeInMinHp      = {
    [DamageTypeEx.DYING_REDUCE]     = true,
    [DamageTypeEx.POISON_CIRCLE]    = true,
    -- [DamageTypeEx.DROWN]            = true,
    [DamageTypeEx.KILL_SELF]        = true
}

-- 匿名伤害类型
local tbAnonymousDamageType         = {
    [DamageTypeEx.DYING_REDUCE]     = true,
    [DamageTypeEx.KILL_SELF]        = true
}

-- 用于定义人船都有，值不同，但逻辑相同属性Id
-- 子类必须Override
BattlePropertyComponentBase.nHpId                       = -1
BattlePropertyComponentBase.nEpId                       = -1
BattlePropertyComponentBase.nMaxHpBaseId                = -1
BattlePropertyComponentBase.nMaxHpId                    = -1
BattlePropertyComponentBase.nMaxEpId                    = -1
BattlePropertyComponentBase.nHpShieldId                 = -1
BattlePropertyComponentBase.nIsDyingId                  = -1
BattlePropertyComponentBase.nIsRescuingId               = -1
BattlePropertyComponentBase.nIsDeadId                   = -1
BattlePropertyComponentBase.nIsAlreadyDeadId            = -1
BattlePropertyComponentBase.nMinHpRatioId               = -1
BattlePropertyComponentBase.nDamageRatioFromNpcId       = -1
BattlePropertyComponentBase.nDamageRatioToNpcId         = -1
BattlePropertyComponentBase.nDamageRatioId              = -1

-- 相关事件
BattlePropertyComponentBase.OnHpChanged                 = nil
BattlePropertyComponentBase.OnEpChanged                 = nil
BattlePropertyComponentBase.OnIsDyingChanged            = nil
BattlePropertyComponentBase.OnIsRescuingChanged         = nil

-- 上次伤害信息
BattlePropertyComponentBase.LastDamageCauser            = nil
BattlePropertyComponentBase.nLastDamageType             = DamageTypeEx.UNKNOWN
BattlePropertyComponentBase.tbLastDamageExtraData       = nil

-- 测试专用
BattlePropertyComponentBase.bInvincible                 = false
BattlePropertyComponentBase.bInvincibleToPoisonCircle   = false
BattlePropertyComponentBase.bPhoenix                    = false

-- 其他属性
BattlePropertyComponentBase.EventHelper                 = nil
BattlePropertyComponentBase.bIsDying                    = false
BattlePropertyComponentBase.bIsRescuing                 = false

local function LOG(self, ...)
    log("[BattlePropertyComponentBase]", self.Owner.szName, ...)
end

local function OnCharacterDead(self)
    LOG(self, "OnPawnPreDead begin")
    self.Owner.DelegateComponent.OnCharacterPreDead:Fire()
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self.Owner, self.LastDamageCauser, self.nLastDamageType)
    LOG(self, "OnPawnPreDead end")
    if GlobalVariableSystem:IsServerLogic() then
        self:SetPropOriginValue(self.nIsDeadId, true)
        self:SetPropOriginValue(self.nIsAlreadyDeadId, true)
    end
    self:HandleIsDeadChanged()
    LOG(self, "OnPawnPostDead begin")
    self.Owner.DelegateComponent.OnCharacterPostDead:Fire()
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self.Owner, self.LastDamageCauser, self.nLastDamageType)
    LOG(self, "OnPawnPostDead end")
end

local function OnEpChanged(self)
    self.OnEpChanged:Fire(self:GetEp(), self:GetMaxEp(), self:GetEpPercent())
end

local function OnHpChanged(self)
    -- 因为血量变化事件非常的频繁，所以不开放全局血量变化事件，需要监听血量变化按需从人船各自的PropertyComponent处监听
    self.OnHpChanged:Fire(self:GetHp(), self:GetMaxHp(), self:GetHpPercent())
end

local function OnMaxHpBaseChanged(self, nMaxHpBase)
    self:SetPropOriginValue(self.nMaxHpId, nMaxHpBase)
    self:SetPropOriginValue(self.nHpId, self:GetMaxHp())
end

local function OnIsDyingChanged(self, bIsDying)
    if (not bIsDying) and (not self.bIsDying) then
        return
    end
    LOG(self, "OnIsDyingChanged bIsDying =", bIsDying)
    self.bIsDying = bIsDying
    self:HandleIsDyingChanged(bIsDying)
    self.OnIsDyingChanged:Fire(bIsDying)
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED, self.Owner, bIsDying)
end

local function OnIsRescuingChanged(self, bIsRescuing)
    if (not bIsRescuing) and (not self.bIsRescuing) then
        return
    end
    LOG(self, "OnIsRescuingChanged bIsRescuing =", bIsRescuing)
    self.bIsRescuing = bIsRescuing
    self:HandleIsRescuingChanged(bIsRescuing)
    self.OnIsRescuingChanged:Fire(bIsRescuing)
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_RESCUING_CHANGED, self.Owner, bIsRescuing)
end

local function OnIsDeadChanged(self, bIsDead)
    if (not bIsDead)
    or self:GetIsAlreadyDead()
    or (not GlobalVariableSystem:IsDedicatedClient()) then
        return
    end
    LOG(self, "OnIsDeadChanged bIsDead =", bIsDead)
    OnCharacterDead(self)
end

local function OnIsAlreadyDeadChanged(self, bIsAlreadyDead)
    if (not bIsAlreadyDead)
    or (not GlobalVariableSystem:IsDedicatedClient()) then
        return
    end
    LOG(self, "OnIsAlreadyDeadChanged bIsAlreadyDead =", bIsAlreadyDead)
    self:HandleIsAlreadyDead()
end

function BattlePropertyComponentBase:OnResetBattleProperties()
    self:SetPropOriginValue(self.nHpId, self:GetMaxHp())
    self:SetPropOriginValue(self.nEpId, 0)
end

-- 检查是否忽略伤害
local function CheckIgnoreDamage(self, nDamageType, tbCauser)
    -- 不免疫自杀伤害
    if nDamageType == DamageTypeEx.KILL_SELF then
        return false
    end
    -- 检查现在是否可以受伤
    if not GlobalVariableSystem:GetDungeonDamageEnabled() then
        return true
    end

    if nDamageType == DamageTypeEx.POISON_CIRCLE then
        -- 免疫毒圈伤害(测试用逻辑)
        if self.bInvincibleToPoisonCircle then
            LOG(self, "Character is invincible to PoisonCircle.")
            return true
        end
        -- 重伤被救援时，免疫毒圈伤害
        if IGNORE_POISON_DAMAGE_WHEN_BE_RESCUED and self.Owner.BattleDyingComponent:IsBeingRescued() then
            return true
        end
    end

    -- 是否无敌(测试用逻辑)
    if self.bInvincible then
        LOG(self, "Character is invincible.")
        return true
    end
    return false
end

-- 记录伤害信息
local function RecordDamageInfo(self, tbCauser, nDamageType, tbDamageExtraData)
    if not tbAnonymousDamageType[nDamageType] then
        self.LastDamageCauser = tbCauser
        self.nLastDamageType = nDamageType
        self.tbLastDamageExtraData = tbDamageExtraData
    end
end

-- 处理基础伤害倍率
local function HandleBaseDamage(self, nDamageType, nDamage)
    if DamageTypeEx.IsCausedByHuman(nDamageType) or DamageTypeEx.IsCausedByShip(nDamageType)then
        local nDamageRatio = self:GetDamageRatio()
        nDamage = nDamage * math.max(0, nDamageRatio)
    end
    return nDamage
end

-- 处理NPC相关伤害
local function HandleNpcDamage(self, tbCauser, nDamage)
    if tbCauser then
        if self.Owner:GetObjectType() == GameObjectTypeDef.Npc then
            local nDamageRatioToNpc = tbCauser:GetCurrentPropertyComponent():GetDamageRatioToNpc()
            nDamage = nDamage * math.max(0, nDamageRatioToNpc)
        end
        if tbCauser:GetObjectType() == GameObjectTypeDef.Npc then
            local nDamageRatioFromNpc = self:GetDamageRatioFromNpc()
            nDamage = nDamage * math.max(0, nDamageRatioFromNpc)
        end
    end
    return nDamage
end

-- 处理AI伤害减免
local function HandleAIDamage(self, tbCauser, nDamage)
    if tbCauser and AIHelper.IsAIControlled(tbCauser) and (not AIHelper.IsAIControlled(self.Owner)) then
        local AILogic = AIHelper:GetAILogic(tbCauser)
        if AILogic and AILogic:IsEnabled() then
            log("ai damage param:", tbCauser:IsShip(), AILogic:GetDamageParam())
            nDamage = nDamage * math.max(0, AILogic:GetDamageParam())
        end
    end
    return nDamage
end

-- 处理护盾伤害
local function HandleDamageToShield(self, nDamageType, nDamage)
    if not tbShieldIgnoreDamageType[nDamageType] then
        local nHpShield = self:GetHpShield()
        local nTransformToShield = math.min(nHpShield, nDamage)
        self:ConsumeProp(self.nHpShieldId, nTransformToShield)
        return nDamage - nTransformToShield
    end
    return nDamage
end

-- 处理最小血量保护
local function HandleDamageWithMinHp(self, nHp, nDamageType, nDamage)
    local nMinHpRatio = self:GetMinHpRatio()
    if (nMinHpRatio > 0) and (not tbValidDamageTypeInMinHp[nDamageType]) then
        local nMinHp = self:GetMaxHp() * nMinHpRatio
        if nHp > nMinHp then    -- 血量大于最小值时，允许非有效伤害类型将血量扣到最小值
            nDamage = math.min(nDamage, nHp - nMinHp)
        else                    -- 血量低于最小值时，非有效伤害直接为0
            nDamage = 0
        end
    end
    return nDamage
end

-- 通知玩家受到伤害
local function NotifyTakeDamage(self, tbCauser, nDamage, nDamageType, nHp, tbDamageExtraData)
    local nWeaponTemplateId = 0
    if tbDamageExtraData and tbDamageExtraData.nWeaponTemplateId then
        nWeaponTemplateId = tbDamageExtraData.nWeaponTemplateId
    end

    local nRegionType = 0
    if tbDamageExtraData and tbDamageExtraData.nRegionType then
        nRegionType = tbDamageExtraData.nRegionType
    end

    local nHurtTag = DamageHurtDef.HURT_NONE
    if tbDamageExtraData and tbDamageExtraData.nHurtTag then  
        nHurtTag = tbDamageExtraData.nHurtTag
    end
    D2CHelper:NotifyOnHitPlayer(self.Owner, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, nRegionType, nHurtTag)
    local bStandAloneServer = GlobalVariableSystem:IsStandaloneServer()
    if not bStandAloneServer then 
        EventManager:OnFireEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self.Owner, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, tbDamageExtraData)
    end
end

------------------------------------------
-- protected Begin
function BattlePropertyComponentBase:OnCreate(...)
    BattlePropertyComponentBase.super.OnCreate(self, ...)
    self.OnHpChanged = LuaDelegate()
    self.OnEpChanged = LuaDelegate()
    self.OnIsDyingChanged = LuaDelegate()
    self.OnIsRescuingChanged = LuaDelegate()
    self.EventHelper = SelfEventHelperClass()
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ENTER_TRANSPORT_STEP, self, self.OnResetBattleProperties)
end

function BattlePropertyComponentBase:OnDestroy(...)
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    self.OnIsRescuingChanged = nil
    self.OnIsDyingChanged = nil
    self.OnEpChanged = nil
    self.OnHpChanged = nil
    BattlePropertyComponentBase.super.OnDestroy(self, ...)
end

-- 定义Property属性
-- fnDefine(self, nPropId, varDefaultValue, fnCallback)
-- @ nPropId            PropName.lua中对应Id
-- @ varDefaultValue    默认值
-- @ fnCallback         值变化时触发的回调函数（可不传）
function BattlePropertyComponentBase:DefineProperties(fnDefine)
    local nDefaultMaxHp = self:GetDefaultMaxHp()
    local nDefaultMaxEp = self:GetDefaultMaxEp()
    fnDefine(self, self.nHpId                   , nDefaultMaxHp     , OnHpChanged           ) -- 血量
    fnDefine(self, self.nEpId                   , 0                 , OnEpChanged           ) -- 能量
    fnDefine(self, self.nMaxHpBaseId            , nDefaultMaxHp     , OnMaxHpBaseChanged    ) -- 基础最大血量，这个值是默认最大血量加上副本外数值修改，副本内的血量上限修改以此作为默认值
    fnDefine(self, self.nMaxHpId                , nDefaultMaxHp     , OnHpChanged           ) -- 最大血量
    fnDefine(self, self.nMaxEpId                , nDefaultMaxEp     , OnEpChanged           ) -- 最大能量
    fnDefine(self, self.nHpShieldId             , 0                 , nil                   ) -- 血量护盾
    fnDefine(self, self.nIsDyingId              , false             , OnIsDyingChanged      ) -- 重伤状态
    fnDefine(self, self.nIsRescuingId           , false             , OnIsRescuingChanged   ) -- 救援状态
    fnDefine(self, self.nIsDeadId               , false             , OnIsDeadChanged       ) -- 死亡状态（始终同步）
    fnDefine(self, self.nIsAlreadyDeadId        , false             , OnIsAlreadyDeadChanged) -- 是否早已死亡（Actor初次同步到客户端时同步此变量）
    fnDefine(self, self.nMinHpRatioId           , 0                 , nil                   ) -- 最小血量保护
    fnDefine(self, self.nDamageRatioFromNpcId   , 1                 , nil                   ) -- 角色对Npc造成的伤害倍率
    fnDefine(self, self.nDamageRatioToNpcId     , 1                 , nil                   ) -- Npc对角色造成的伤害倍率
    fnDefine(self, self.nDamageRatioId          , 1                 , nil                   ) -- 角色受到的伤害倍率
end

function BattlePropertyComponentBase:GetDefaultMaxHp()
    error("derived class must implement it")
end

function BattlePropertyComponentBase:GetDefaultMaxEp()
    error("derived class must implement it")
end

function BattlePropertyComponentBase:HandleIsDeadChanged(bIsDead)
    error("derived class must implement it")
end

function BattlePropertyComponentBase:HandleIsDyingChanged(bIsDying)
    error("derived class must implement it")
end

function BattlePropertyComponentBase:HandleIsRescuingChanged(bIsRescuing)
    -- error("derived class must implement it")
end

function BattlePropertyComponentBase:HandleIsAlreadyDead(bIsAlreadyDead)
    error("derived class must implement it")
end
-- protected End
------------------------------------------

------------------------------------------
-- public Begin
function BattlePropertyComponentBase:ApplyDamage(tbCauser, nDamageType, nDamage, tbDamageExtraData)
    assert(GlobalVariableSystem:IsServerLogic(), "ApplyDamage is a server only function.")
    assert(nDamage >= 0)
    if self.Owner:IsDead() then
        LOG(self, "ApplyDamage failed, character is dead.")
        return
    end
    LOG(self, "ApplyDamage", tbCauser and tbCauser.szName, nDamageType, nDamage, t2s(tbDamageExtraData))

    local nHp = self:GetHp()
    if CheckIgnoreDamage(self, nDamageType) then
        -- 伤害被免疫时也发通知
        local nNotifyDamage = 0
        if GlobalVariableSystem:IsNotifyDamageWhenIgnoreDamage() then
            nNotifyDamage = nDamage
        end

        NotifyTakeDamage(self, tbCauser, nNotifyDamage, nDamageType, nHp, tbDamageExtraData)
    else
        RecordDamageInfo(self, tbCauser, nDamageType, tbDamageExtraData)
        nDamage = HandleBaseDamage(self, nDamageType, nDamage)
        nDamage = HandleNpcDamage(self, tbCauser, nDamage)
        nDamage = HandleAIDamage(self, tbCauser, nDamage)
        nDamage = HandleDamageToShield(self, nDamageType, nDamage)
        nDamage = HandleDamageWithMinHp(self, nHp, nDamageType, nDamage)
        -- 先通知受到伤害，再真正扣血，避免扣血死亡后，收到受伤事件很多逻辑不对
        NotifyTakeDamage(self, tbCauser, math.min(nHp, nDamage), nDamageType, nHp, tbDamageExtraData)
        -- 新血量大于0；或者已经是重伤状态；两者都不是时尝试进入重伤状态，进入失败
        nHp = nHp - nDamage
        if (nHp > GDefaultTolerance)
        or self:GetIsDying()
        or (not self.Owner.BattleDyingComponent:TryToEnterDying(nDamageType, nHp)) then
            nHp = math.max(nHp, 0)
            self:SetPropOriginValue(self.nHpId, nHp)

            LOG(self, "Check character dead", nHp)
            if nHp <= GDefaultTolerance then
                if self.bPhoenix and (nDamageType ~= DamageTypeEx.KILL_SELF) then
                    LOG(self, "character is phoenix, reviving")
                    self.Owner.BattleDyingComponent:ForceExitDyingState()
                    self:ApplyCure(self.Owner, self:GetMaxHp())
                else
                    -- jira PIRATES-12052 用于debug触发两次死亡逻辑的问题
                    LOG(self, "character go die", debug.traceback())
                    OnCharacterDead(self)
                end
            end
        end
        AIHelper.ReportDamageEvent(self.Owner, tbCauser, nDamage)
    end
end

function BattlePropertyComponentBase:ApplyCure(tbCauser, nCure)
    assert(GlobalVariableSystem:IsServerLogic(), "ApplyCure is a server only function.")
    assert(nCure >= 0)
    if self.Owner:IsDead() then
        LOG(self, "ApplyCure failed, character is dead.")
        return
    end

    local nHp = self:GetHp()
    local nMaxHp = self:GetMaxHp()
    nHp = math.min(nHp + nCure, nMaxHp)
    self:SetPropOriginValue(self.nHpId, nHp)
    EventManager:OnFireEvent(CommonEventDef.EV_ON_TAKE_CURE, self.Owner, tbCauser, nCure)
end

function BattlePropertyComponentBase:ConsumeEp(nValue)
    assert(GlobalVariableSystem:IsServerLogic(), "ConsumeEp is a server only function.")
    assert(nValue >= 0)
    if self.Owner:IsDead() then
        LOG("ConsumeEp failed, character is dead.")
        return
    end

    local nEp = self:GetEp()
    if nEp > 0 then
        nEp = math.max(nEp - nValue, 0)
        self:SetPropOriginValue(self.nEpId, nEp)
    end
end

function BattlePropertyComponentBase:GainEp(nValue)
    assert(GlobalVariableSystem:IsServerLogic(), "GainEp is a server only function.")
    assert(nValue >= 0)
    if self.Owner:IsDead() then
        LOG("GainEp failed, character is dead.")
        return
    end

    local nEp = self:GetEp()
    local nMaxEp = self:GetMaxEp()
    nEp = math.min(nEp + nValue, nMaxEp)
    self:SetPropOriginValue(self.nEpId, nEp)
end

function BattlePropertyComponentBase:GetHpPercent()
    local nMaxHp = self:GetMaxHp()
    if nMaxHp > 0 then
        return self:GetHp() * 1.0 / nMaxHp
    end
    return 0
end

function BattlePropertyComponentBase:GetEpPercent()
    local nMaxEp = self:GetMaxEp()
    if nMaxEp > 0 then
        return self:GetEp() * 1.0 / nMaxEp
    end
    return 0
end

function BattlePropertyComponentBase:GetHp()
    return self:GetProp(self.nHpId)
end

function BattlePropertyComponentBase:GetEp()
    return self:GetProp(self.nEpId)
end

function BattlePropertyComponentBase:GetMaxHp()
    return self:GetProp(self.nMaxHpId)
end

function BattlePropertyComponentBase:GetMaxEp()
    return self:GetProp(self.nMaxEpId)
end

function BattlePropertyComponentBase:GetHpShield()
    return self:GetProp(self.nHpShieldId)
end

function BattlePropertyComponentBase:GetIsDying()
    return self:GetProp(self.nIsDyingId)
end

function BattlePropertyComponentBase:GetIsRescuing()
    return self:GetProp(self.nIsRescuingId)
end

function BattlePropertyComponentBase:GetIsDead()
    return self:GetProp(self.nIsDeadId)
end

function BattlePropertyComponentBase:GetIsAlreadyDead()
    return self:GetProp(self.nIsAlreadyDeadId)
end

function BattlePropertyComponentBase:GetMinHpRatio()
    return self:GetProp(self.nMinHpRatioId)
end

function BattlePropertyComponentBase:GetDamageRatioFromNpc()
    return self:GetProp(self.nDamageRatioFromNpcId)
end

function BattlePropertyComponentBase:GetDamageRatioToNpc()
    return self:GetProp(self.nDamageRatioToNpcId)
end

function BattlePropertyComponentBase:GetDamageRatio()
    return self:GetProp(self.nDamageRatioId)
end

function BattlePropertyComponentBase:GetLastDamageCauser()
    return self.LastDamageCauser
end

function BattlePropertyComponentBase:GetLastDamageType()
    return self.nLastDamageType
end

function BattlePropertyComponentBase:GetLastDamageExtraData()
    return self.tbLastDamageExtraData or {}
end

function BattlePropertyComponentBase:ClientSyncDamageInfo(tbCauser, nDamageType)
    RecordDamageInfo(self, tbCauser, nDamageType)
end
-- public End
------------------------------------------

return BattlePropertyComponentBase
