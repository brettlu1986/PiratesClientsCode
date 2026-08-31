-----------------------------------------------------
--File Name    : GuideActionSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionFunctional                     = require("GuideActionFunctional")
local GuideActionEnableShipMovementTick         = luaclass("GuideActionEnableShipMovementTick", GuideActionFunctional)

local PlayerSelfHelper = require("GamePlayerSelfHelper")
----------------------------------------------------------
----------------------------------------------------------

function GuideActionEnableShipMovementTick:DoAction(tbTemplate)
    GuideActionEnableShipMovementTick.super.DoAction(self, tbTemplate)
    local pSelfActor = PlayerSelfHelper:GetUEActor()
    local bEnable = tbTemplate.bEnable
    local pShipMovementComponent = pSelfActor.ShipMovementComponent
    if pShipMovementComponent then
        pShipMovementComponent:SetComponentTickEnabled(bEnable)
    end
end

return GuideActionEnableShipMovementTick
