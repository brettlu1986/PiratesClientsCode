-----------------------------------------------------
--File Name    : GuideActionEndTriggerMidOnAttackFinished.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerMidOnAttackFinished  = luaclass("GuideActionEndTriggerMidOnAttackFinished", GuideActionEndTriggerBase)

local ClientEventDef    = require("ClientEventDef")
-----------------------------------------------------

local function MidOnAttackFinished(self, bFocus)
    if not bFocus then
        self:Triggered()
    end
end

function GuideActionEndTriggerMidOnAttackFinished:BindEvent(tbParam)
    GuideActionEndTriggerMidOnAttackFinished.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ACCUMULATE, self, MidOnAttackFinished)
end

return GuideActionEndTriggerMidOnAttackFinished
