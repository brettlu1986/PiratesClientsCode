-----------------------------------------------------
--File Name    : GuideActionCancelShipAttack.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional         = require("GuideActionFunctional")
local GuideActionCancelShipAttack   = luaclass("GuideActionCancelShipAttack", GuideActionFunctional)

--import
local ClientEventDef            = require("ClientEventDef")

function GuideActionCancelShipAttack:DoAction(tbTemplate)
    GuideActionCancelShipAttack.super.DoAction(self, tbTemplate)
    self.EventHelper:FireEvent(ClientEventDef.EV_RELEASE_FIGHT_BTN)
end

return GuideActionCancelShipAttack
