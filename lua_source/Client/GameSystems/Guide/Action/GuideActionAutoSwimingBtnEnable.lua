-----------------------------------------------------
--File Name    : GuideActionAutoSwimingBtnEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionFunctional             = require("GuideActionFunctional")
local GuideActionAutoSwimingBtnEnable   = luaclass("GuideActionAutoSwimingBtnEnable", GuideActionFunctional)

--import
local ClientEventDef        = require("ClientEventDef")

function GuideActionAutoSwimingBtnEnable:DoAction(tbTemplate)
    GuideActionAutoSwimingBtnEnable.super.DoAction(self, tbTemplate)
    local bEnable = tbTemplate.bEnable
    self.EventHelper:FireEvent(ClientEventDef.EV_SET_AIM_BTN_ENABLE, bEnable)
end

return GuideActionAutoSwimingBtnEnable
