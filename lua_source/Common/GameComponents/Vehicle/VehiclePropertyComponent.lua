local luaclass = require("luaclass")
local BattlePropertyComponentBase = require("BattlePropertyComponentBase")
local VehiclePropertyComponent = luaclass("VehiclePropertyComponent",BattlePropertyComponentBase)
local VehicleDataTable = require("VehicleDataTable")
local PropName = require("PropName")
local DamageTypeEx = require("DamageTypeEx")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local HumanVehicleHelper = require("HumanVehicleHelper")
local PropNameVehicle = require("PropNameVehicle")
local BPDamageType = require("BPDamageType")
local DungeonIni = require("DungeonIni")
local DelayTimer = require("DelayTimer")
local D2CHelper = require("D2CHelper")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local HumanVehicleStateDef = require("HumanVehicleStateDef")

VehiclePropertyComponent.tbTemplateData = nil
VehiclePropertyComponent.tbDelayHideActorHandle = nil

--[[
    override super
]]
-- VehiclePropertyComponent.nEpId                      = PropName.nVehicleEp
VehiclePropertyComponent.nMaxHpBaseId               = PropName.nVehicleMaxHpBase
VehiclePropertyComponent.nHpId                      = PropName.nVehicleHp
VehiclePropertyComponent.nMaxHpId                   = PropName.nVehicleMaxHp
VehiclePropertyComponent.nMaxEpId                   = PropName.nVehicleMaxEp
-- VehiclePropertyComponent.nHpShieldId                = PropName.nVehicleHpShield
-- VehiclePropertyComponent.nIsDyingId                 = PropName.bIsVehicleDying
-- VehiclePropertyComponent.nIsRescuingId              = PropName.bIsVehicleRescuing
VehiclePropertyComponent.nIsDeadId                  = PropName.bVehicleDead
VehiclePropertyComponent.nIsAlreadyDeadId           = PropName.bVehicleDead
VehiclePropertyComponent.nMinHpRatioId              = PropName.nVehicleMinHpRatio
VehiclePropertyComponent.nDamageRatioFromNpcId      = PropName.nVehicleDamageRatioFromNpc
VehiclePropertyComponent.nDamageRatioToNpcId        = PropName.nVehicleDamageRatioToNpc
VehiclePropertyComponent.nDamageRatioId             = PropName.nVehicleDamageRatio

--[[
    vehicle only properties
]]
VehiclePropertyComponent.nVehicleOwnerId            = PropName.nVehicleOwnerId

VehiclePropertyComponent.bInvincibleToPoisonCircle  = true
VehiclePropertyComponent.nHideVehicleActorDelayTime = 5

VehiclePropertyComponent.pTakeRadialDamage = nil

local DEAD_HP = 0.001

local CALC_DAMAGE   = {
    [BPDamageType.ShipBullet]       = require("VDC_ShipBullet"),                    -- 船的子弹伤害
    [BPDamageType.ShipThrownItem]   = require("VDC_ShipThrownItem"),                -- 船的投掷物
    [BPDamageType.HumanGrenade]     = require("HDC_HumanGrenade"),                  -- 人的手雷伤害
    [BPDamageType.HumanThrowWeapon] = require("HDC_HumanThrowWeapon"),              -- 飞刀飞斧
}

local function LOG(self, ...)
    log("[VehiclePropertyComponent]", self.Owner:GetServerInstanceId(), ...)
end

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
    end
    return false
end

local function DelayDestroyActor(self)
    if self.tbDelayHideActorHandle then
        return
    end
    local fnDestoryActor = function()
        self.tbDelayHideActorHandle = nil

        if not (self.Owner and self.Owner.pUEActor) then
            return
        end
        GameObjectSystem:RemoveByServerInstanceId(self.Owner:GetServerInstanceId())
    end
    local nHideVehicleActorDelayTime = DungeonIni.tbDead.nHideVehicleActorDelayTime
    if nHideVehicleActorDelayTime > 0 then
        self.tbDelayHideActorHandle = DelayTimer:DelayRun(fnDestoryActor, 10)
    else
        fnDestoryActor()
    end
end

local function OnCharacterDead(self)
    if GlobalVariableSystem:IsServerLogic() then
        self:SetPropOriginValue(self.nIsDeadId, true)
        self:SetPropOriginValue(self.nIsAlreadyDeadId, true)
    end
    self:HandleIsDeadChanged()
end
local function OnIsDeadChanged(self, bIsDead)
    if (not bIsDead)
    or self:GetIsAlreadyDead()
    or (not GlobalVariableSystem:IsDedicatedClient()) then
        return
    end
    OnCharacterDead(self)
end

local function OnHpChanged(self)
    self.OnHpChanged:Fire(self:GetHp(), self:GetMaxHp(), self:GetHpPercent())

    if (self:GetHp() <= DEAD_HP)
    and (self:GetMaxHp() > 0)
    and (not self.Owner:IsDead()) then
        OnCharacterDead(self)
    end
end

local function OnTakeRadialDamageEx(self, _, nActualDamage, pDamageType, _, pDamageCauser, pHitResult)
    local nDamageType = enumtoint(pDamageType.LuaEnum)
    LOG(self, "OnTakeRadialDamageEx nActualDamage:%f, nDamageType:%d", nActualDamage, nDamageType)
    local fnCalculate = CALC_DAMAGE[nDamageType]
    if fnCalculate then
        fnCalculate(self.Owner, nActualDamage, pDamageCauser, pHitResult)
    end
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

    D2CHelper:NotifyOnHitPlayer(self.Owner, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, nRegionType)
    EventManager:OnFireEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self.Owner, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, tbDamageExtraData)
end

function VehiclePropertyComponent:OnResetBattleProperties()
    self:SetPropOriginValue(self.nHpId, self:GetMaxHp())
end

function VehiclePropertyComponent:GetDefaultMaxHp()
    local nTemplateId = self.Owner:GetTemplateId()
    local tbTemplateData = VehicleDataTable:GetTemplate(nTemplateId)

    if tbTemplateData then
        -- logdebug("self.tbTemplateData.nMaxHp ", tbTemplateData.nMaxHp )
        return tbTemplateData.nMaxHp
    end
    return 0
end
function VehiclePropertyComponent:SetOwnerId(nOwnerId)
    if GlobalVariableSystem:IsServerLogic() then
        self:SetPropOriginValue(self.nVehicleOwnerId, nOwnerId)
    end
end

function VehiclePropertyComponent:GetDefaultMaxEp()
    return 0
end

function VehiclePropertyComponent:OnActorCreated(pUEActor)
    VehiclePropertyComponent.super.OnActorCreated(self, pUEActor)

    self:BindRepProperties(PropNameVehicle.GetRepIds())

    if not GlobalVariableSystem:IsServerLogic() then
        local nVehicleOwnerId = self:GetProp(self.nVehicleOwnerId)
        if nVehicleOwnerId ~= 0 then
            local tbPlayer = GameObjectSystem:FindByInstanceId(nVehicleOwnerId)
            if tbPlayer and tbPlayer.HumanMovementStateComponent then
                HumanVehicleHelper.AttachToVehicle(tbPlayer, self.Owner:GetServerInstanceId(), true)
            end
        end
    end

    local nTemplateId = self.Owner:GetTemplateId()
    local tbTemplateData = VehicleDataTable:GetTemplate(nTemplateId)
    self.bInvincibleToPoisonCircle = tbTemplateData.bInvincibleToPoisonCircle

    self.pTakeRadialDamage = self.EventHelper:RegisterCppDelegate(pUEActor.OnTakeRadialDamageEx, self, OnTakeRadialDamageEx)
end

function VehiclePropertyComponent:OnActorDestroyed(pUEActor)
    VehiclePropertyComponent.super.OnActorDestroyed(self, pUEActor)
    if self.pTakeRadialDamage then
        self.EventHelper:UnregisterCppDelegate(self.pTakeRadialDamage)
        self.pTakeRadialDamage = nil
    end
    if self.tbDelayHideActorHandle then
        DelayTimer:ClearTimer(self.tbDelayHideActorHandle)
        self.tbDelayHideActorHandle = nil
    end
end

function VehiclePropertyComponent:DefineProperties(fnDefine, tbParams)
    local nDefaultMaxHp = self:GetDefaultMaxHp()
    -- local nDefaultMaxEp = self:GetDefaultMaxEp()
    fnDefine(self, self.nHpId           , nDefaultMaxHp     , OnHpChanged           , true)     -- 血量
    fnDefine(self, self.nMaxHpId        , nDefaultMaxHp     , OnHpChanged        , true)     -- 最大血量
    -- fnDefine(self, self.nHpShieldId     , 0                 , nil                   , false)    -- 血量护盾
    fnDefine(self, self.nIsDeadId       , false             , OnIsDeadChanged       , true)     -- 血量
    -- fnDefine(self, self.nEpId           , 0                 , nil                   , false)    -- 能量

    fnDefine(self, self.nVehicleOwnerId , 0                 , nil                   , true)

    -- VehiclePropertyComponent.super.DefineProperties(self, fnDefine, tbParams)
 end

function VehiclePropertyComponent:HandleIsDeadChanged()
    local pUEActor = self.Owner.pUEActor
    if not pUEActor then
        return
    end

    LOG(self, "HandleIsDeadChanged")

    -- pUEActor:SetActorHiddenInGame(true)
    -- 通知蓝图
    pUEActor:OnDead()
    pUEActor.CharacterMovement.bIsDead = true

    local nDriverId = self:GetProp(self.nVehicleOwnerId)

    if GlobalVariableSystem:IsServerLogic() then
        if nDriverId then
            local tbDriver = GameObjectSystem:FindByInstanceId(nDriverId)
            if tbDriver and tbDriver:IsAlive() then
                LOG(self, "HandleIsDeadChanged Driver name is", tbDriver:GetName())
                HumanVehicleHelper.ClearVehicle(tbDriver, false, true)
            end
        end
        DelayDestroyActor(self)
    else
        if nDriverId then
            local tbDriver = GameObjectSystem:FindByInstanceId(nDriverId)
            if tbDriver and tbDriver:IsAlive() then
                local GameVehicleComponent = tbDriver.GameVehicleComponent
                if GameVehicleComponent then
                    local nVehicleState = GameVehicleComponent:GetVehicleState()
                    LOG(self, "HandleIsDeadChanged Driver is", tbDriver:GetName(), "VehicleState", nVehicleState)
                    if nVehicleState ~= HumanVehicleStateDef.None then
                        LOG(self, "HandleIsDeadChanged Driver is", tbDriver:GetName(), "requesting getting off vehicle")
                        HumanVehicleHelper.RequestVehicleState(HumanVehicleStateDef.None)
                    end
                end
            end
        end
    end
    self.Owner:OnDead()

    EventManager:OnFireEvent(CommonEventDef.EV_ON_VEHICLE_DEAD, self.Owner, nDriverId)
end

function VehiclePropertyComponent:HandleIsAlreadyDead()
    self:HandleIsDeadChanged()
end

function VehiclePropertyComponent:GetIsDying()
    return false
end

function VehiclePropertyComponent:ApplyDamage(tbCauser, nDamageType, nDamage, tbDamageExtraData)
    -- VehiclePropertyComponent.super.ApplyDamage(self, tbCauser, nDamageType, nDamage, tbDamageExtraData)
    assert(GlobalVariableSystem:IsServerLogic(), "ApplyDamage is a server only function.")
    assert(nDamage >= 0)

    LOG(self, "VehicleOnTakeDamage", self:GetHp(), nDamageType, nDamage, t2s(tbDamageExtraData))

    if self.Owner:IsDead() then
        LOG(self, "ApplyDamage failed, character is dead.")
        return
    end

    local nHp = self:GetHp()

    if not CheckIgnoreDamage(self, nDamageType) and nHp > DEAD_HP then
        NotifyTakeDamage(self, tbCauser, nDamage, nDamageType, nHp, tbDamageExtraData)
        nHp = nHp - nDamage
        nHp = math.max(nHp, 0)
        self:SetPropOriginValue(self.nHpId, nHp)
        if nHp <= DEAD_HP then
            OnCharacterDead(self)
        end
    else
        NotifyTakeDamage(self, tbCauser, 0, nDamageType, nHp, tbDamageExtraData)
    end
end

return VehiclePropertyComponent