-----------------------------------------------------
--File Name    : GuideActionSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionSelectWidget           = require("GuideActionSelectWidget")
local GuideActionSelectWidgetWithPress  = luaclass("GuideActionSelectWidgetWithPress", GuideActionSelectWidget)

local ClientEventDef    = require("ClientEventDef")
----------------------------------------------------------
GuideActionSelectWidget.szRelatedWidgetName = nil
GuideActionSelectWidget.tbSelectWidgets     = nil
----------------------------------------------------------

function GuideActionSelectWidgetWithPress:BindClickDelegate()
    local EventHelper = self.EventHelper
    if self.tbSelectWidgets then
        for k, v in ipairs(self.tbSelectWidgets)do
            if v then
                if v.OnClicked ~= nil then
                    EventHelper:RegisterCppDelegate(v.OnClicked,            self, self.OnSelect)
                end
                if v.OnDoubleClicked then
                    EventHelper:RegisterCppDelegate(v.OnDoubleClicked,      self, self.OnSelect)
                end
                if v.OnDisableClicked ~= nil then
                    EventHelper:RegisterCppDelegate(v.OnDisableClicked,     self, self.OnSelect)
                end
                if v.OnCheckStateChanged ~= nil then
                    EventHelper:RegisterCppDelegate(v.OnCheckStateChanged,  self, self.OnSelect)
                end
                self.EventHelper:RegisterCppDelegate(v.OnPressed,           self, self.OnPressed)
            end
        end
    end
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_DOUBLE_FIRED, self, self.OnDoubleClick)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_CLICK_ITEM,   self, self.OnItemClick)
    EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_CHANGE, self, self.OnInteractionVisible)
end

function GuideActionSelectWidgetWithPress:OnPressed()
    self:OnSelect()
end

return GuideActionSelectWidgetWithPress
