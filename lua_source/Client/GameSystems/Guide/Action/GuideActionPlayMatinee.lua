-----------------------------------------------------
--File Name    : GuideActionPlayMatinee.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideAction = require("GuideAction")
local GuideActionPlayMatinee = luaclass("GuideActionPlayMatinee",GuideAction)

-- local InteractionHelper = require("InteractionHelper")
-- local ClientEventDef = require("ClientEventDef")
-- local UIManager = require("UIManager")
-- local UIDef = require("UIDef")


-- function GuideActionPlayMatinee:Begin()
--     GuideActionPlayMatinee.super.Begin(self)
--     UIManager:CloseWnd(UIDef.UI_GUIDE)
--     self.EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_EXIT, self, self.OnInteractionEnd)
--     local nMatineeId = self.tbTemplate.nMatineeId
--     if nMatineeId then
--         InteractionHelper:CreateMatinee(nMatineeId)
--     else
--         self:LogError("GuideActionPlayMatinee:invalid matinee id,group,step=",self.tbGuideTemplate.nGroup, self.tbGuideTemplate.nStep)
--     end
-- end

-- function GuideActionPlayMatinee:OnInteractionEnd()
--     self:EndAction()
-- end

return GuideActionPlayMatinee
