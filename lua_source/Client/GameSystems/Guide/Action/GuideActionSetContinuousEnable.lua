-----------------------------------------------------
--File Name    : GuideActionSetContinuousEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionFunctional             = require("GuideActionFunctional")
local GuideActionSetContinuousEnable    = luaclass("GuideActionSetContinuousEnable", GuideActionFunctional)

--import
local ClientEventDef        = require("ClientEventDef")
--local 

function GuideActionSetContinuousEnable:DoAction(tbTemplate)
    GuideActionSetContinuousEnable.super.DoAction(self, tbTemplate)
    local bEnable = tbTemplate.bEnable
    self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_ENABLE_CONTINOUS, bEnable)
end

return GuideActionSetContinuousEnable
