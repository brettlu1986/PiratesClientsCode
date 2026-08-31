-----------------------------------------------------
--File Name    : GuideActionChangeFaction.lua
--Description  : 指引动作
--废弃 2020.8.31
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideAction               = require("GuideAction")
local GuideActionChangeFaction  = luaclass("GuideActionChangeFaction",GuideAction)

-- local UIManager             = require("UIManager")
-- local UIDef                 = require("UIDef")
-- local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-- local FactionDef            = require("FactionDef")
-- local L10N                  = require("L10N")

----------------------------------------------------------
-- GuideActionChangeFaction.SelectWidget = nil

----------------------------------------------------------
-- local function GetCurrentFactionID()
--     local FactionComponent = GamePlayerSelfHelper:Get().FactionComponent
--     local nCurrentID = FactionDef.Type.FACTION_NONE
--     if FactionComponent then 
--         nCurrentID = FactionComponent:GetCurrentFactionID()
--     end 
--     return nCurrentID
-- end 

-- local function RandomFaction()
--     local nCurrentID = GetCurrentFactionID()
    
--     local tbRandomPool = {}
--     for k, v in pairs(FactionDef.Type)do
--         if(v ~= FactionDef.Type.FACTION_NONE and v ~= FactionDef.Type.FACTION_SPAIN and v ~= nCurrentID)then
--             table.insert(tbRandomPool, v)
--         end
--     end
--     local nRandomIndex = math.random(1, #tbRandomPool)
--     return tbRandomPool[nRandomIndex]
-- end


-- function GuideActionChangeFaction:Begin()
--     GuideActionChangeFaction.super.Begin(self)
--     local tbTemplate = self.tbTemplate
--     local Wnd = UIManager:GetWnd( tbTemplate.szUIName )
--     if(Wnd == nil)then
--         self:LogError("wnd nil,uiname="..tostring(tbTemplate.szUIName))
--         return
--     end
--     local pWidgetRef = Wnd.pWidgetRef
    
--     for k,v in ipairs(tbTemplate.tbPrefabName)do
--         pWidgetRef = pWidgetRef[v]
--         if(pWidgetRef == nil)then
--             self:LogError("GuideActionChangeFaction:Begin,not found prefab,prefab name="..v)
--             return
--         end
--     end
--     local nRandomFactionId = RandomFaction()
--     local SelectWidget = pWidgetRef[tbTemplate.tbWidgetName[nRandomFactionId]] 
--     if(SelectWidget == nil)then
--         logwarning("GuideActionChangeFaction:Begin,SelectWidget is nil")
--         self:OnSelect()
--         return
--     end
    
--     self:DebugLog("GuideActionChangeFaction:Begin,szVisibility="..tostring(self.tbTemplate.szVisibility))
--     SelectWidget:SetVisibility(ESlateVisibility[self.tbTemplate.szVisibility])
--     if(SelectWidget.OnClicked ~= nil)then
--         self.EventHelper:RegisterCppDelegate(SelectWidget.OnClicked, self, self.OnSelect)
--     end
--     if(SelectWidget.OnDisableClicked ~= nil)then
--         self.EventHelper:RegisterCppDelegate(SelectWidget.OnDisableClicked, self, self.OnSelect)
--     end
--     if(SelectWidget.OnCheckStateChanged ~= nil)then
--         self.EventHelper:RegisterCppDelegate(SelectWidget.OnCheckStateChanged, self, self.OnSelect)
--     end
--     self.SelectWidget = SelectWidget
-- end

-- function GuideActionChangeFaction:End()
--     GuideActionChangeFaction.super.End(self)
-- end

-- function GuideActionChangeFaction:DoAction(tbTemplate)
--     local pGeometry = self.SelectWidget:GetCachedGeometry()
--     local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
--     local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X = 0, Y = 0})
--     local GuideWnd = UIManager:OpenWnd(UIDef.UI_GUIDE, {bIsModal = self.tbGuideTemplate.bIsModal})
--     if not GuideWnd:SetSelectInfo(Pos, Size, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
--     tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self)
--     then
--         self:ForceEndCurrentGroup()
--     end
--     self:DebugLog("tbTemplate.szSelectWidgetName="..tostring(tbTemplate.szSelectWidgetName))
--     if((tbTemplate.szSelectWidgetName == nil or tbTemplate.szSelectWidgetName == "") and (L10N:ToString(tbTemplate.l10nGuideText) ~= nil and L10N:ToString(tbTemplate.l10nGuideText) ~= "") )then
--         self:EndAction()
--     end
   
-- end

-- function GuideActionChangeFaction:OnClickAnywhere()
--     GuideActionChangeFaction.super.OnClickAnywhere(self)
--     self:OnSelect()
-- end

-- function GuideActionChangeFaction:OnSelect()
--     self:DebugLog("GuideActionChangeFaction:OnSelect")
--     if(not self.tbTemplate.bDoubleClick)then     
--         self:EndAction()       
--     end
-- end

return GuideActionChangeFaction
