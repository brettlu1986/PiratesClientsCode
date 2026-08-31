-----------------------------------------------------
--File Name    : GuideActionSelectList.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFullUIControl      = require("GuideActionFullUIControl")
local GuideActionPriceListGo        = luaclass("GuideActionPriceListGo",GuideActionFullUIControl)

-- local UIManager         = require("UIManager")
-- local ClientEventDef    = require("ClientEventDef")
-- local L10N              = require("L10N")
-- -----------------------------------------------------
-- GuideActionPriceListGo.ClickDelegate    = nil
-- GuideActionPriceListGo.ListHelper       = nil
-- -----------------------------------------------------
-- function GuideActionPriceListGo:Begin()
--     GuideActionPriceListGo.super.Begin(self)
--     local tbTemplate = self.tbTemplate
--     local Wnd = UIManager:GetWnd( tbTemplate.szUIName )
--     if(Wnd == nil or not Wnd:IsVisible())then
--         self:LogError("wnd nil,uiname="..tostring(tbTemplate.szUIName))
--         self:ForceEndCurrentGroup()
--         return
--     end
--     local ScriptRef = Wnd
    
--     for k,v in ipairs(tbTemplate.tbPrefabName)do
--         ScriptRef = ScriptRef[v]
--         if(ScriptRef == nil)then
--             self:LogError("GuideActionPriceListGo:Begin,not found prefab,prefab name="..v)
--             self:ForceEndCurrentGroup()
--             return
--         end
--     end

--     local ListHelper = ScriptRef[tbTemplate.tbWidgetName[1]]
    
--     if(ListHelper == nil)then
--         self:ForceEndCurrentGroup()
--         return
--     end
--     self.ListHelper = ListHelper
-- 	local tbListData = tbTemplate.tbListData
-- 	local nScrollIndex = 1
--     for k,tbData in pairs(ListHelper.tbDataList)do
--         if(tbData ~= nil and tbData.tbSellData.nShopID == tbListData[1])then
--             nScrollIndex = k
--             break
--         end
--     end
--     self:DebugLog("GuideActionPriceListGo:nScrollIndex=",nScrollIndex)
-- 	ListHelper:ScrollToIndex(nScrollIndex, false)
--     self.EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_CLICK_SELECT, self, self.OnSelect)

-- end

-- function GuideActionPriceListGo:End()
--     GuideActionPriceListGo.super.End(self)
-- end

-- function GuideActionPriceListGo:DoAction(tbTemplate)
--     GuideActionPriceListGo.super.DoAction(self, tbTemplate)
--     local SelectWidget = nil
--     local ListHelper = self.ListHelper
--     local tbListData = tbTemplate.tbListData
--     for _,ItemScript in pairs(ListHelper.tbItemList)do
--         local tbData = ItemScript.tbData
--         if(tbData ~= nil)then
--             if(tbData ~= nil and tbData.tbSellData.nShopID == tbListData[1])then
--                 SelectWidget = ItemScript.pWidgetRef.btnSellPort
--                 break
--             end
--         end
--     end
--     if(SelectWidget == nil)then
--         self:DebugLog("GuideActionPriceListGo,SelectWidget=nil")
--         self:ForceEndCurrentGroup()
--         return
--     end
--     local pGeometry = SelectWidget:GetCachedGeometry()
--     local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
--     local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
            
--     self:ForceEndCurrentGroup()
--     local GuideWnd = self:GetGuideWnd()
--     if not GuideWnd:SetSelectInfo(Pos, Size, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText), 
--     tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self) then
--         self:ForceEndCurrentGroup()
--     end
--     if(SelectWidget.OnClicked ~= nil)then
--         if(self.ClickDelegate ~= nil)then
--             self.EventHelper:UnregisterCppDelegate(self.ClickDelegate)
--             self.ClickDelegate = nil
--         end
--         self.ClickDelegate = self.EventHelper:RegisterCppDelegate(SelectWidget.OnClicked, self, self.OnSelect)
--     end
-- end

-- function GuideActionPriceListGo:OnClickAnywhere()
--     self:EndAction()
-- end

-- function GuideActionPriceListGo:OnSelect()
--     self:EndAction()
-- end




return GuideActionPriceListGo
