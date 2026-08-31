-----------------------------------------------------
--File Name    : GuideActionGuideStepEnd.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideActionFunctional = require("GuideActionFunctional")
local GuideActionGuideStepEnd = luaclass("GuideActionGuideStepEnd",GuideActionFunctional)

local ClientEventDef = require("ClientEventDef")

function GuideActionGuideStepEnd:DoAction(tbTemplate)
    GuideActionGuideStepEnd.super.DoAction(self, tbTemplate)
    self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_STEP_END, self.tbTemplate.nDungeonStepIndex)
end

return GuideActionGuideStepEnd
