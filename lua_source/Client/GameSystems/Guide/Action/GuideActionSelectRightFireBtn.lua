-----------------------------------------------------
--File Name    : GuideActionSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionSelectVisibleWidget        = require("GuideActionSelectVisibleWidget")
local GuideActionSelectRightFireBtn         = luaclass("GuideActionSelectRightFireBtn", GuideActionSelectVisibleWidget)

local ClientEventDef    = require("ClientEventDef")
----------------------------------------------------------
function GuideActionSelectRightFireBtn:BindEvent()
    GuideActionSelectRightFireBtn.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_ON_FIGHTBDR_MOUSE_DOWN, self, self.OnSelect)
end

return GuideActionSelectRightFireBtn