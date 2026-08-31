-----------------------------------------------------
--File Name    : GuideActionShowDialogue.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideAction = require("GuideAction")
local GuideActionShowDialogue = luaclass("GuideActionShowDialogue",GuideAction)

-- local InteractionHelper = require("InteractionHelper")
-- local ClientEventDef = require("ClientEventDef")
-- local UIManager = require("UIManager")
-- local UIDef = require("UIDef")


-- function GuideActionShowDialogue:Begin()
--     GuideActionShowDialogue.super.Begin(self)
--     self.EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_EXIT, self, self.OnInteractionEnd)
--     local nDialogId = self.tbTemplate.nDialogId
--     if(nDialogId == nil or nDialogId == -1)then
--         self:LogError("GuideActionShowDialogue error,nDialogId="..tostring(nDialogId))
--         return
--     end
--     local tbInteractinIns = InteractionHelper:CreatePortrait(nDialogId, self.tbTemplate.bDialogState)
--     if not tbInteractinIns then
--         UIManager:CloseWnd(UIDef.UI_GUIDE)
--     end
--     --logdebug("GuideActionShowDialogue:Begin,tbInteractinIns=",tbInteractinIns)
-- end

-- function GuideActionShowDialogue:OnCloseUI(szWndName)
--     GuideActionShowDialogue.super.OnCloseUI(self, szWndName)
--     if(szWndName == UIDef.UI_INTERACTION)then
--         --logdebug("GuideActionShowDialogue:OnCloseUI,szWndName="..szWndName.." ngroup="..tostring(self.tbGuideTemplate.nGroup).." nStep="..tostring(self.tbGuideTemplate.nStep))
--         local GuideWnd = self:GetGuideWnd()
--         if(GuideWnd ~= nil)then
--             GuideWnd:ShowSpaceScreen(true)
--         end
        
--     end
-- end

-- function GuideActionShowDialogue:OnOpenUI(szWndName)
--     if(szWndName == UIDef.UI_INTERACTION)then
--         UIManager:CloseWnd(UIDef.UI_GUIDE)
--     end
-- end

-- function GuideActionShowDialogue:OnInteractionEnd()
--     self:EndAction()
-- end


return GuideActionShowDialogue
