-----------------------------------------------------
--File Name    : GuideActionShipCannonEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional         = require("GuideActionFunctional")
local GuideActionShipCannonEnable   = luaclass("GuideActionShipCannonEnable",GuideActionFunctional)

local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local ShipUtilityHelper     = require("ShipUtilityHelper")

function GuideActionShipCannonEnable:DoAction(tbTemplate)
    GuideActionShipCannonEnable.super.DoAction(self, tbTemplate)
    local SelfObj = GamePlayerSelfHelper:Get()
    local PlayerActor = SelfObj:GetModelActor()
    if PlayerActor then
        ShipUtilityHelper.SetShipWeaponEnabled(PlayerActor, tbTemplate.bEnable, GWorld)
    end
end

return GuideActionShipCannonEnable
