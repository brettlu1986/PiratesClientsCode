-----------------------------------------------------
--File Name    : GuideActionFightBtnDragEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionFunctional             = require("GuideActionFunctional")
local GuideActionFightBtnDragEnable     = luaclass("GuideActionFightBtnDragEnable", GuideActionFunctional)

--import
local ClientEventDef        = require("ClientEventDef")

function GuideActionFightBtnDragEnable:DoAction(tbTemplate)
    GuideActionFightBtnDragEnable.super.DoAction(self, tbTemplate)
    local bEnable = tbTemplate.bEnable
    self.EventHelper:FireEvent(ClientEventDef.EV_SET_FIGHT_BTN_ENABLE, bEnable)
end

return GuideActionFightBtnDragEnable
