-----------------------------------------------------
--File Name    : GuideActionShowBoardDialogue.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideAction = require("GuideAction")
local GuideActionShowBoardDialogue = luaclass("GuideActionShowBoardDialogue",GuideAction)

-- local NpcDialogBoardHelper = require("NpcDialogBoardHelper")
-- local UIDef = require("UIDef")
-- local UIManager = require("UIManager")


-- function GuideActionShowBoardDialogue:Begin()
--     GuideActionShowBoardDialogue.super.Begin(self)
--     local nDialogId = self.tbTemplate.nDialogId
--     if(nDialogId == nil or nDialogId == -1)then
--         self:LogError("GuideActionShowBoardDialogue error,nDialogId="..tostring(nDialogId))
--         return
--     end
--     UIManager:CloseWnd(UIDef.UI_GUIDE)
--     NpcDialogBoardHelper:OpenDialogBoard(nDialogId)
-- end

-- function GuideActionShowBoardDialogue:OnCloseUI(szWndName)
--     GuideActionShowBoardDialogue.super.OnCloseUI(self, szWndName)
--     if(szWndName == UIDef.UI_NPC_DIALOG_BOARD)then
--         self:EndAction()
--     end
-- end

return GuideActionShowBoardDialogue
