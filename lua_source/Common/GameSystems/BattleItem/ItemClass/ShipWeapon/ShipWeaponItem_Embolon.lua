-----------------------------------------------------
--File Name    : ShipWeaponItem_Embolon.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-19
--Description  : 船只武器基类 - 撞角
-----------------------------------------------------
local luaclass = require("luaclass")
local ShipWeaponItem = require("ShipWeaponItem")
local ShipWeaponItem_Embolon = luaclass("ShipWeaponItem_Embolon", ShipWeaponItem)

local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")

-- @override
function ShipWeaponItem_Embolon:GetTemplateType()
    return ShipWeaponTemplateDef.EMBOLON
end

-- @override
function ShipWeaponItem_Embolon:OnEquipOnServer()
    ShipWeaponItem_Embolon.super.OnEquipOnServer(self)
    local pComponent = self:GetBPComponent()
    if pComponent then
        local tbTemplate = self:GetTemplate()
        local nWeaponId = self:GetInstanceId()
        local nBaseDamage = tbTemplate.nBaseDamage
        local pEffectDataRes = tbTemplate.szEffectDataRes and tbTemplate.szEffectDataRes:load()
        pComponent:EquipEmbolon(nWeaponId, nBaseDamage, pEffectDataRes)
    end
end

-- @override
function ShipWeaponItem_Embolon:OnUnequipOnServer()
    ShipWeaponItem_Embolon.super.OnUnequipOnServer(self)
    local pComponent = self:GetBPComponent()
    if pComponent then
        pComponent:UnequipEmbolon()
    end
end

-- @override
function ShipWeaponItem_Embolon:OnStartFiring(nFiringCount)
    local tbCharacter = self:GetOwnerCharacter()
    local nFiringBuffId = self:GetTemplate().nFiringBuffId
    if nFiringBuffId > 0 then
        tbCharacter.BuffComponentServer:AddBuffWithInstigator(tbCharacter, nFiringBuffId)
    end
end

return ShipWeaponItem_Embolon