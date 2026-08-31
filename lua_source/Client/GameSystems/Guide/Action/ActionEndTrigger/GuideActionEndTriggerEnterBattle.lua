-----------------------------------------------------
--File Name    : GuideActionEndTriggerEnterBattle.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerEnterBattle          = luaclass("GuideActionEndTriggerEnterBattle", GuideActionEndTriggerBase)

local ClientEventDef        = require("ClientEventDef")
-----------------------------------------------------

function GuideActionEndTriggerEnterBattle:BindEvent(tbParam)
    GuideActionEndTriggerEnterBattle.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_PRE_LEVEL_LOBBY, self, self.Triggered)
end

return GuideActionEndTriggerEnterBattle
