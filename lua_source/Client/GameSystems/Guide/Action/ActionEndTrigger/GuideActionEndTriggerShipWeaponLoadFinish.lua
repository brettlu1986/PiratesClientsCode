-----------------------------------------------------
--File Name    : GuideActionEndTriggerShipWeaponLoadFinish.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerShipWeaponLoadFinish = luaclass("GuideActionEndTriggerShipWeaponLoadFinish", GuideActionEndTriggerBase)

local ClientEventDef            = require("ClientEventDef")
-----------------------------------------------------

function GuideActionEndTriggerShipWeaponLoadFinish:BindEvent(tbParam)
    GuideActionEndTriggerShipWeaponLoadFinish.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_WEAPON_LOAD_FINISH, self, self.Triggered)
end

return GuideActionEndTriggerShipWeaponLoadFinish
