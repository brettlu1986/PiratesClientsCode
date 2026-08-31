-----------------------------------------------------
--File Name    : GuideActionCanBuildPromptAnim.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionFunctional             = require("GuideActionFunctional")
local GuideActionCanBuildPromptAnim     = luaclass("GuideActionCanBuildPromptAnim", GuideActionFunctional)

--import
local ClientEventDef = require("ClientEventDef")
--local 

function GuideActionCanBuildPromptAnim:DoAction(tbTemplate)
    GuideActionCanBuildPromptAnim.super.DoAction(self, tbTemplate)
    local bEnable = tbTemplate.bEnable
    self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_CAN_BUILD_ANIM_ENABLE, bEnable)
end

return GuideActionCanBuildPromptAnim
