-----------------------------------------------------
--File Name    : ShipWeaponItem_Cannon.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-13
--Description  : 船只武器基类 - 火炮（通用型）
-----------------------------------------------------
local luaclass = require("luaclass")
local ShipWeaponItem = require("ShipWeaponItem")
local ShipWeaponItem_Cannon = luaclass("ShipWeaponItem_Cannon", ShipWeaponItem)

local PropName = require("PropName")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local nFiringidTop = 0

local function LOG(self, ...)
    log("[BattleShipWeapon][Item_Cannon]", self:GetInstanceId(), ...)
end

local function GetNextFiringId()
    nFiringidTop = nFiringidTop + 1
    return nFiringidTop
end

local function OnBpFiringEnd(self, nFiringId, nFiringCount)
    LOG(self, "OnBpFiringEnd")
    EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_CANNON_FIRING_END, self, nFiringId, nFiringCount)
    self:Fire(ShipFiringOperationDef.END)
end

function ShipWeaponItem_Cannon:GetTemplateType()
    return ShipWeaponTemplateDef.CANNON
end

function ShipWeaponItem_Cannon:GetBPComponent()
    local OwnerShipUEActor = self:GetOwnerShipUEActor()
    return OwnerShipUEActor and OwnerShipUEActor:GetCannonComponent()
end

function ShipWeaponItem_Cannon:IsValidFiringState(nFiringOperation)
    return self:IsServerInstance() or (nFiringOperation == ShipFiringOperationDef.START)
end

function ShipWeaponItem_Cannon:OnStartFiring(nFiringCount)
    LOG(self, "OnStartFiring")
    if not self:IsServerInstance() then
        return
    end
    local nFiringId = GetNextFiringId()
    local tbTemplate = self:GetTemplate()
    local OwnerCharacter = self:GetOwnerCharacter()
    local bIsInAim = BattleShipWeaponSystem:GetIsInAim(OwnerCharacter)
    local nDeviationX = tbTemplate.nDeviationX
    local nDeviationY = tbTemplate.nDeviationY
    local PropComponent = OwnerCharacter.ShipBattlePropertyComponent
    local nDeviationRatio = PropComponent:GetProp(PropName.nShipBulletDeviationRatio)
    if bIsInAim then
        nDeviationX = tbTemplate.nAimDeviationX
        nDeviationY = tbTemplate.nAimDeviationY
        nDeviationRatio = PropComponent:GetProp(PropName.nShipBulletAimDeviationRatio)
    end
    nDeviationX = nDeviationX * nDeviationRatio
    nDeviationY = nDeviationY * nDeviationRatio
    self:GetBPComponent():Fire(nFiringId, nFiringCount, nDeviationX, nDeviationY)
end

function ShipWeaponItem_Cannon:OnCancelFiring()
    LOG(self, "OnCancelFiring")
    self:GetBPComponent():InterruptFiring()
end

function ShipWeaponItem_Cannon:OnActivateWeapon()
    local tbTemplate = self:GetTemplate()
    local nGravityZ = tbTemplate.nGravityZ
    local nBulletLaunchInterval = tbTemplate.nBulletLaunchInterval
    local bConcentratedFiring = tbTemplate.bConcentratedFiring
    local nLeanFactorRatio = tbTemplate.nLeanFactorRatio
    self:GetBPComponent():SetupCannon(nGravityZ, nBulletLaunchInterval, bConcentratedFiring, nLeanFactorRatio)

    if not self:IsServerInstance() then
        return
    end
    local DelegateComponent = self:GetOwnerCharacter().DelegateComponent
    DelegateComponent.OnShipFireEnd:Bind(OnBpFiringEnd, self)
end

function ShipWeaponItem_Cannon:OnDeactivateWeapon()
    if not self:IsServerInstance() then
        return
    end
    local DelegateComponent = self:GetOwnerCharacter().DelegateComponent
    DelegateComponent.OnShipFireEnd:Unbind(OnBpFiringEnd, self)
end

function ShipWeaponItem_Cannon:SetTargetLocation(nX, nY, nZ)
    self:GetBPComponent().TargetLocation = KismetMathLibrary.MakeVector(nX, nY, nZ)
end

return ShipWeaponItem_Cannon