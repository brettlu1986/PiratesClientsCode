-----------------------------------------------------
--File Name    : GuideActionShipDeactivate.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionShipDeactivate = luaclass("GuideActionShipDeactivate",GuideActionFunctional)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

function GuideActionShipDeactivate:DoAction(tbTemplate)
    GuideActionShipDeactivate.super.DoAction(self, tbTemplate)
    local SelfObj = GamePlayerSelfHelper:Get()
    local ShipActor = SelfObj:GetModelActor()
    ShipActor.ShipMovementComponent:Deactivate()
end

return GuideActionShipDeactivate
