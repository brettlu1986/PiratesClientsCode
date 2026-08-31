-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerEnterInshore     = luaclass("GuideActionEndTriggerEnterInshore", GuideActionEndTriggerBase)

local ClientEventDef        = require("ClientEventDef")
-----------------------------------------------------

local function OnEnterInshore(self, bVisible)
    local bShowed = tonumber(self.tbParam[1]) > 0
    self:DebugLog("OnEnterInshore bVisible = " .. tostring(bVisible) .. " bShowed = " .. tostring(bShowed))
    if bShowed and bVisible then
        self:Triggered()
    end
end

function GuideActionEndTriggerEnterInshore:BindEvent(tbParam)
    GuideActionEndTriggerEnterInshore.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_CHANGE_DISPLAY, self, OnEnterInshore)
end

return GuideActionEndTriggerEnterInshore
