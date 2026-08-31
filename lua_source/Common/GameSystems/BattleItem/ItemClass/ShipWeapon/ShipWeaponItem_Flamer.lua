-----------------------------------------------------
--File Name    : ShipWeaponItem_Flamer.lua
--Author       : Song Fuhao
--Create Time  : 2019-01-16
--Description  : 船只武器基类 - 喷火器
-----------------------------------------------------
local luaclass = require("luaclass")
local ShipWeaponItem = require("ShipWeaponItem")
local ShipWeaponItem_Flamer = luaclass("ShipWeaponItem_Flamer", ShipWeaponItem)

local PropName = require("PropName")
local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")

-- @override
function ShipWeaponItem_Flamer:GetTemplateType()
    return ShipWeaponTemplateDef.FLAMER
end

-- @override
function ShipWeaponItem_Flamer:OnActivateWeapon()
    local tbTemplate = self:GetTemplate()
    self:GetBPComponent():SetupFlamer(tbTemplate.nDamageInterval)
end

-- @override
function ShipWeaponItem_Flamer:OnStartFiring()
    local PropertyComponent = self:GetOwnerCharacter().ShipBattlePropertyComponent
    local nWeaponDamageIntervalRatio = PropertyComponent:GetProp(PropName.nWeaponDamageIntervalRatio)
    local nWeaponDamageIntervalDelta = PropertyComponent:GetProp(PropName.nWeaponDamageIntervalDelta)
    self:GetBPComponent():Fire(nWeaponDamageIntervalRatio, nWeaponDamageIntervalDelta)
end

-- @override
function ShipWeaponItem_Flamer:FireEndInternal()
    self:GetBPComponent():FireEnd()
end

return ShipWeaponItem_Flamer