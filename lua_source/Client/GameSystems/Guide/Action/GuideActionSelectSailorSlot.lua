-----------------------------------------------------
--File Name    : GuideActionSelectSailorSlot.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionSelectWidget       = require("GuideActionSelectWidget")
local GuideActionSelectSailorSlot   = luaclass("GuideActionSelectSailorSlot", GuideActionSelectWidget)

local ClientEventDef    = require("ClientEventDef")
----------------------------------------------------------
GuideActionSelectWidget.szRelatedWidgetName = nil
GuideActionSelectWidget.tbSelectWidgets     = nil
----------------------------------------------------------

function GuideActionSelectSailorSlot:BindClickDelegate()
    GuideActionSelectSailorSlot.super.BindClickDelegate(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_CLICK_BORDER, self, self.OnSelect)
end

return GuideActionSelectSailorSlot
