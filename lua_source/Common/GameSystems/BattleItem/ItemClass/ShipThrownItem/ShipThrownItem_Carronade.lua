-----------------------------------------------------
--File Name    : ShipThrownItem_Carronade.lua
--Author       : Song Fuhao
--Create Time  : 2020-02-20
--Description  : 臼炮类型的船投掷物
-----------------------------------------------------
local luaclass = require("luaclass")
local ShipThrownItem = require("ShipThrownItem")
local ShipThrownItem_Carronade = luaclass("ShipThrownItem_Carronade", ShipThrownItem)

local Timer = require("Timer")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local ShipWeaponTemplateDef = require("ShipWeaponTemplateDef")

function ShipThrownItem_Carronade:GetBPComponent()
    local pOwnerUEActor = self:GetOwnerShipUEActor()
    return pOwnerUEActor and pOwnerUEActor.CarronadeComponent
end

function ShipThrownItem_Carronade:GetTemplateType()
    return ShipWeaponTemplateDef.CARRONADE
end

function ShipThrownItem_Carronade:OnActivateWeapon()
    local tbTemplate = self:GetTemplate()
    self:GetBPComponent():SetupCarronade(tbTemplate.nGravityZ)
end

function ShipThrownItem_Carronade:SetTargetLocation(nX, nY, nZ)
    local pComponent = self:GetBPComponent()
    pComponent.IsBotOwned = true
    pComponent.TargetLocation = KismetMathLibrary.MakeVector(nX, nY, nZ)
end

local function OnPreFiringTimeEnd(self)
    self:Fire(ShipFiringOperationDef.END)
end

local function ThrownFinish(self)
    if self:IsServerInstance() then
        if self.tbCancelTimer then
            self.tbCancelTimer:Clear()
            self.tbCancelTimer = nil
        end
    else
        self:GetBPComponent():CancelFire()
    end
end

function ShipThrownItem_Carronade:OnStartFiring()
    if self:IsServerInstance() then
        self.tbCancelTimer = Timer.NewTimerMethod(self, OnPreFiringTimeEnd, self:GetTemplate().nMaxPreThrownItem)
    else
        self:GetBPComponent():PreFire()
    end
end

function ShipThrownItem_Carronade:OnCancelFiring()
    ThrownFinish(self)
end

function ShipThrownItem_Carronade:OnEndFiring()
    ThrownFinish(self)
    if self:IsServerInstance() then
        local tbTemplate = self:GetTemplate()
        local szBulletRes = tbTemplate.szBulletRes
        local nFiringCount = 1
        local nEffectBuffId = tbTemplate.nEffectBuffId
        local nDuration = tbTemplate.nEffectDuration
        local bCausingDamage = tbTemplate.bCausingDamage
        self:GetBPComponent():Fire(szBulletRes:load(), nFiringCount, nEffectBuffId, nDuration, bCausingDamage)
    end
end

function ShipThrownItem_Carronade:IsValidFiringState(nFiringOperation)
    return true
end

return ShipThrownItem_Carronade