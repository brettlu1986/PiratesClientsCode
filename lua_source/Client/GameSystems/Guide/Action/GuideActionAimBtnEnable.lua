-----------------------------------------------------
--File Name    : GuideActionAimBtnEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionFunctional             = require("GuideActionFunctional")
local GuideActionAimBtnEnable           = luaclass("GuideActionAimBtnEnable", GuideActionFunctional)

--import
local ClientEventDef = require("ClientEventDef")
--local 

function GuideActionAimBtnEnable:DoAction(tbTemplate)
    GuideActionAimBtnEnable.super.DoAction(self, tbTemplate)
    local bEnable = tbTemplate.bEnable
    self.EventHelper:FireEvent(ClientEventDef.EV_SET_AIM_BTN_ENABLE, bEnable)
end

return GuideActionAimBtnEnable
