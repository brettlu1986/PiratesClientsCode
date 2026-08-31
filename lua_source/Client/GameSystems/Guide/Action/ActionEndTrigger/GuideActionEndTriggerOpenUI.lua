-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerOpenUI           = luaclass("GuideActionEndTriggerOpenUI", GuideActionEndTriggerBase)

local ClientEventDef        = require("ClientEventDef")
-----------------------------------------------------

local function OnOpenUI(self, szWndName)
    local szUIName = self.tbParam[1]
    if szWndName == szUIName then
        self:Triggered()
    end
end

function GuideActionEndTriggerOpenUI:BindEvent(tbParam)
    GuideActionEndTriggerOpenUI.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, OnOpenUI)
end

return GuideActionEndTriggerOpenUI
