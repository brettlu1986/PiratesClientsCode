-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerCloseUI          = luaclass("GuideActionEndTriggerCloseUI", GuideActionEndTriggerBase)

local ClientEventDef        = require("ClientEventDef")
-----------------------------------------------------

local function OnCloseUI(self, szWndName)
    local szUIName = self.tbParam[1]
    if szWndName == szUIName then
        self:DebugLog("OnCloseUI OpenUI UIName = " .. tostring(szUIName))
        self:Triggered()
    end
end

function GuideActionEndTriggerCloseUI:BindEvent(tbParam)
    GuideActionEndTriggerCloseUI.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnCloseUI)
end

return GuideActionEndTriggerCloseUI
