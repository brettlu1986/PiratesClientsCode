-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                          = require("luaclass")
local GuideActionEndTriggerBase                         = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerItemPanelArrowBtnClicked     = luaclass("GuideActionEndTriggerItemPanelArrowBtnClicked", GuideActionEndTriggerBase)

local ClientEventDef = require("ClientEventDef")
-----------------------------------------------------

local function CheckItemPanelExpanded(self, bExpanded)
    self:DebugLog("CheckItemPanelExpanded")
    local szType = self.tbParam[1]
    if szType == "true" and bExpanded then
        self:Triggered()
    elseif szType == "false" and not bExpanded then
        self:Triggered()
    end
end

function GuideActionEndTriggerItemPanelArrowBtnClicked:BindEvent(tbParam)
    GuideActionEndTriggerItemPanelArrowBtnClicked.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_ITEMPANEL_LIST_ARROW_BTN_CLICKED, self, CheckItemPanelExpanded)    
end

return GuideActionEndTriggerItemPanelArrowBtnClicked
