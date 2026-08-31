-----------------------------------------------------
--File Name    : GuideActionChangeDisplayEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionFunctional             = require("GuideActionFunctional")
local GuideActionChangeDisplayEnable    = luaclass("GuideActionChangeDisplayEnable", GuideActionFunctional)

--import
local ClientEventDef        = require("ClientEventDef")

function GuideActionChangeDisplayEnable:DoAction(tbTemplate)
    GuideActionChangeDisplayEnable.super.DoAction(self, tbTemplate)
    local bEnable = tbTemplate.bEnable
    local EventHelper = self.EventHelper
    EventHelper:FireEvent(ClientEventDef.EV_FFA_CHANGE_DISPLAY_ENABLE, bEnable)
    if bEnable then
        EventHelper:FireEvent(ClientEventDef.EV_UI_CHANGE_DISPLAY, bEnable)
    end
end


return GuideActionChangeDisplayEnable
