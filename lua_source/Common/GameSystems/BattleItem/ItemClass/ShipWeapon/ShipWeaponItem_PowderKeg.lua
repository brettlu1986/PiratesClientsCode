-----------------------------------------------------
--File Name    : ShipWeaponItem_PowderKeg.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-13
--Description  : 船只武器基类 - 火药桶（鱼雷）
-----------------------------------------------------
local luaclass = require("luaclass")
local ShipWeaponItem = require("ShipWeaponItem")
local ShipWeaponItem_PowderKeg = luaclass("ShipWeaponItem_PowderKeg", ShipWeaponItem)

local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")

-- @override
function ShipWeaponItem_PowderKeg:GetTemplateType()
    return ShipWeaponTemplateDef.POWDER_KEG
end

-- @protected
-- @override
function ShipWeaponItem_PowderKeg:OnActivateWeapon()
    local tbTemplate = self:GetTemplate()
    local nFiringAngle = tbTemplate.nFiringAngle
    self:GetBPComponent():SetupPowderKeg(nFiringAngle)
end

-- @override
function ShipWeaponItem_PowderKeg:OnStartFiring(nFiringCount)
    self:GetBPComponent():Fire(nFiringCount)
end

-- @override
function ShipWeaponItem_PowderKeg:SetTargetYaw(nYaw)
    self:GetBPComponent().TargetYaw = nYaw
end


return ShipWeaponItem_PowderKeg