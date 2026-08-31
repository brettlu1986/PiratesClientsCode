-----------------------------------------------------
--File Name    : GuideActionEndTriggerOnMovementChange.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerEnterRescue          = luaclass("GuideActionEndTriggerEnterRescue", GuideActionEndTriggerBase)

local ClientEventDef        = require("ClientEventDef")
-----------------------------------------------------

function GuideActionEndTriggerEnterRescue:BindEvent(tbParam)
    GuideActionEndTriggerEnterRescue.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_ON_ENTER_RESCUING_TRIGGER, self, self.Triggered)
end

return GuideActionEndTriggerEnterRescue
