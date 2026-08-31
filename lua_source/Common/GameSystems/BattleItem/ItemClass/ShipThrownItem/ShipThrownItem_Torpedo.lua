-----------------------------------------------------
--File Name    : ShipThrownItem_Torpedo.lua
--Author       : Song Fuhao
--Create Time  : 2020-02-20
--Description  : 陷阱类型的船投掷物
-----------------------------------------------------
local luaclass = require("luaclass")
local ShipThrownItem = require("ShipThrownItem")
local ShipThrownItem_Torpedo = luaclass("ShipThrownItem_Torpedo", ShipThrownItem)

local ShipFiringOperationDef = require("ShipFiringOperationDef")
local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")

function ShipThrownItem_Torpedo:GetBPComponent()
    local pOwnerUEActor = self:GetOwnerShipUEActor()
    return pOwnerUEActor and pOwnerUEActor.TorpedoComponent
end

function ShipThrownItem_Torpedo:GetTemplateType()
    return ShipWeaponTemplateDef.TORPEDO
end

function ShipThrownItem_Torpedo:OnActivateWeapon()
    local tbTemplate = self:GetTemplate()
    self:GetBPComponent():SetupTorpedo(tbTemplate.nBoomWaitTime)
end

function ShipThrownItem_Torpedo:OnStartFiring()
    if self:IsServerInstance()then
        local tbTemplate = self:GetTemplate()
        local nFiringCount = 1
        local nBulletLifeSpan = tbTemplate.nBulletLifeSpan
        self:GetBPComponent():Fire(nFiringCount, nBulletLifeSpan)
        self:Fire(ShipFiringOperationDef.END)
    end
end

function ShipThrownItem_Torpedo:IsValidFiringState(nFiringOperation)
    return self:IsServerInstance() or (nFiringOperation == ShipFiringOperationDef.START)
end

return ShipThrownItem_Torpedo