-----------------------------------------------------
--File Name    : GuideActionSelectDialogOption.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideAction                   = require("GuideAction")
local GuideActionSelectDialogOption = luaclass("GuideActionSelectDialogOption",GuideAction)

-- local UIManager     = require("UIManager")
-- local UIDef         = require("UIDef")
-- local QuestDef      = require("QuestDef")
-- local L10N          = require("L10N")
-- -----------------------------------------------------
-- GuideActionSelectDialogOption.ListHelper = nil
-- -----------------------------------------------------
-- function GuideActionSelectDialogOption:Begin()
--     GuideActionSelectDialogOption.super.Begin(self)
--     local GuideWnd = self:GetGuideWnd()
--     if(self.tbGuideTemplate.bIsModal)then
--         GuideWnd:ShowSpaceScreen(true)
--     end
--     local InteractionWnd = UIManager:GetWnd(UIDef.UI_INTERACTION)
--     if(InteractionWnd == nil or not UIManager:IsWndOpen(UIDef.UI_INTERACTION))then
--         self:ForceEndCurrentGroup()
--         return
--     end
--     self.ListHelper = InteractionWnd.ListHelper
-- end

-- function GuideActionSelectDialogOption:DoAction(tbTemplate)
--     local ListHelper = self.ListHelper
--     local SelectScript = nil
--     for k,v in pairs(ListHelper.tbItemList)do
--         local tbInteractionData = v.tbInteractionData
--         --logdebug("tbInteractionData=",tbInteractionData)
--         if(tbInteractionData ~= nil)then
--             local nUIID = tbInteractionData.nUIID
--             --logdebug("nUIID,tbInteractionData.nType,tbTemplate.nOptionUIId=",nUIID,tbInteractionData.nType,tbTemplate.nOptionUIId)
--             if(tbInteractionData.nType == QuestDef.QuestAcceptType.SHOW_UI and nUIID == tbTemplate.nOptionUIId)then
--                 SelectScript = v
--                 break
--             end
--         end
--     end
--     --logdebug("GuideActionSelectDialogOption,SelectScript=",SelectScript)
--     if(SelectScript == nil)then 
--         self:ForceEndCurrentGroup()
--         return
--     end
--     self.szRelatedUIName = UIDef.UI_INTERACTION
--     local SelectWidget = SelectScript.pWidgetRef.Button
--     self.EventHelper:RegisterCppDelegate(SelectWidget.OnClicked, self, self.OnSelect)

--     local pGeometry = SelectWidget:GetCachedGeometry()
--     local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
--     local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
--     local GuideWnd = self:GetGuideWnd()
--     if not GuideWnd:SetSelectInfo(Pos, Size, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
--     tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self) then
--         self:ForceEndCurrentGroup()
--     end
-- end

-- function GuideActionSelectDialogOption:OnSelect()
--     self:EndAction()
-- end

return GuideActionSelectDialogOption
