-----------------------------------------------------
--File Name    : UPMaterialItemInPackageList.lua
--Author       : WuJizhou
--Create Time  : 9/5/2018, 1:10:34 PM
--Description  : UPMaterialItemInPackageList
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")

local UPMaterialItemInPackageList = luaclass("UPMaterialItemInPackageList", ListItemBase)
local BattleItemDataTable = require("BattleItemDataTable")
local UISetUtils = require("UISetUtils")
local BattleItemSystemClient = require("BattleItemSystemClient")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local UIDragDropUtils = require("UIDragDropUtils")
local ClientEventDef = require("ClientEventDef")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPMaterialItemInPackageList.tbItem = nil

local function DiscardSome(self)
    self.pbDiscardPart:ShowView(self.tbItem)
end

local function DiscardAll(self)
    local tbItem = self.tbItem
    if not tbItem then
        return
    end
    BattleItemSystemClient:RequestThrowAwayItem(tbItem:GetInstanceId(), tbItem.nStackCount)
    self.EventHelper:FireEvent(ClientEventDef.EV_REQUEST_THROW_AWAY_ITEM)
end

local function OnSelected(self)
    self:ToogleSelectItem()

    if self:IsSelected() then
        local tbItem = self.tbItem
        local tbTemplate = tbItem:GetTemplate()
        local nCount = tbItem:GetStackCount()
        self.pbDetail:ShowDetail(tbTemplate, nCount)
    else
        self.pbDetail:HideDetail()
    end
end

local function OnCreateVisual(self, pVisualWidget)
    local tbItem = self.tbItem
    if tbItem then
        local nTemplateId = tbItem:GetTemplateId()
        local tbRes = BattleItemDataTable:GetResTemplate(nTemplateId)
        if not tbRes then
            logerror("UPMaterialItemInPackageList OnCreateVisual: invalid res id ", nTemplateId)
            return
        end
        local szItemIconPath = tbRes.szIconPath
        local IconObj = szItemIconPath:load()
        if(IconObj == nil)then
            logwarning("UPMaterialItemInPackageList OnCreateVisual: icon is not found, path="..tostring(szItemIconPath))
            return
        end
        local pWidgetRef = self.pWidgetRef
        UISetUtils.SetImageBrushRes(pVisualWidget.imgContent, IconObj, false, true, pWidgetRef.DragSizeX, pWidgetRef.DragSizeY)
    end
end

local function ShowBaseInfo(self)
    local pWidgetRef = self.pWidgetRef
    local tbItem = self.tbItem
    local tbTemplate = tbItem:GetTemplate()

    -- 显示图标
    local nTemplateId = tbItem:GetTemplateId()
    local tbResTemplate = BattleItemDataTable:GetResTemplate(nTemplateId)
    local szRes = tbResTemplate.szIconPath
    local pRes = szRes:load()
    UISetUtils.SetButtonBrushRes(pWidgetRef.btnBlueprintItem, pRes)

    -- 显示颜色等级
    local nItemTemplateId = tbItem:GetTemplateId()
    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

    -- 显示名字
    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    -- pWidgetRef.txtDesc:SetText(tbTemplate.l10nDesc)
    pWidgetRef.txtDesc:SetVisibility(ESlateVisibility.Hidden)

    local nCount = tbItem:GetStackCount()
    if nCount > 1 then
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.txtCount:SetText(nCount == 1 and "" or nCount)
    else
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility_Collapsed)
    end

    pWidgetRef.imgForbid:SetVisibility(ESlateVisibility_Collapsed)
end

local function ShowButton(self, nCount)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnDiscardAll:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.btnUse:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.btnEquipment:SetVisibility(ESlateVisibility.Collapsed)
    if nCount > 1 then
        pWidgetRef.btnDiscard1:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.btnDiscard1:SetVisibility(ESlateVisibility.Collapsed)
    end
end

-- 设置拖拽
local function ShowDrag(self)
    local tbItem = self.tbItem
    local pWidgetRef = self.pWidgetRef
    local pbDrag = pWidgetRef
    pbDrag:SetVisibility(ESlateVisibility.Visible)
    pbDrag.bEnableDrag = true
    pbDrag.bEnableDrop = false
    pbDrag.DragId = tbItem:GetInstanceId()
    pbDrag.DragCategory = PackageDragCategoryDef.HUMAN_PACKAGE_ITEM
end

-- local function SetSelected(self)
--     local pWidgetRef = self.pWidgetRef
--     local bSelected = self:IsSelected()
--     local tbItem = self.tbItem
--     local nCount = tbItem:GetStackCount()

--     if bSelected then
--         pWidgetRef.vboxOperate:SetVisibility(ESlateVisibility.Visible)
--         ShowButton(self, nCount)
--     else
--         pWidgetRef.vboxOperate:SetVisibility(ESlateVisibility.Collapsed)
--     end
-- end

function UPMaterialItemInPackageList:OnLoad()
    self.pWidgetRef.btnSelect:SetVisibility(ESlateVisibility_Collapsed)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end

function UPMaterialItemInPackageList:OnRefresh(tbData)
    self.tbItem = tbData.tbItem
    self.pbDiscardPart = tbData.pbDiscardPart
    self.pbDetail = tbData.pbDetail

    ShowDrag(self)
    ShowBaseInfo(self)

    local bSelected = self:IsSelected()
    self:SetSelected(bSelected)
    self.pbDiscardPart:HideView()
end

function UPMaterialItemInPackageList:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDiscard1.OnClicked, self, DiscardSome)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDiscardAll.OnClicked, self, DiscardAll)

    local pbDrag = pWidgetRef
    EventHelper:RegisterCppDelegate(pbDrag.OnCreateVisual,self,OnCreateVisual)
    EventHelper:RegisterCppDelegate(pbDrag.OnClicked, self, OnSelected)
    UIDragDropUtils.EnableDragStartAndEndEvent(EventHelper, pbDrag)
end

function UPMaterialItemInPackageList:SetSelected(bSelected)
    local pWidgetRef = self.pWidgetRef
    local tbItem = self.tbItem
    local nCount = tbItem:GetStackCount()
    if bSelected then
        pWidgetRef.vboxOperate:SetVisibility(ESlateVisibility_Visible)
        pWidgetRef.csvOperate1:SetVisibility(ESlateVisibility_Visible)
        ShowButton(self, nCount)
    else
        pWidgetRef.vboxOperate:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.csvOperate1:SetVisibility(ESlateVisibility_Collapsed)
    end
end

return UPMaterialItemInPackageList