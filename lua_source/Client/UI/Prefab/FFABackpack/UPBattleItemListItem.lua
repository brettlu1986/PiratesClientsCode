local luaclass          = require("luaclass")
local ListItemBase      = require("ListItemBase")
local UPBattleItemListItem    = luaclass("UPBattleItemListItem", ListItemBase)


local BattleItemSystemClient  = require("BattleItemSystemClient")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIFFABackpackHelper = require("UIFFABackpackHelper")
local ShipWeaponAttachmentHelper = require("ShipWeaponAttachmentHelper")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
local BattleItemResDataTable = require("BattleItemResDataTable")
local UISetUtils = require("UISetUtils")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local UIDragDropUtils = require("UIDragDropUtils")
local ClientEventDef = require("ClientEventDef")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPBattleItemListItem.nItemInstanceId = 0

function UPBattleItemListItem:OnDestroy()

end


function UPBattleItemListItem:OnLoad()
    self.pWidgetRef.btnSelect:SetVisibility(ESlateVisibility_Collapsed)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end

local function CanEquipAttachement(self)
    local tbItemObject = BattleItemSystemClient:GetItem(self.nItemInstanceId)
    if not tbItemObject then
        return false
    end
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local bFoundWeaponItem = false
    local tbWeaponItems = { }
    for nSlotIndex=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbWeaponItem = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON,
        tbPlayerSelf:GetServerInstanceId(), nSlotIndex)
        if tbWeaponItem then
            tbWeaponItems[nSlotIndex] = tbWeaponItem
            bFoundWeaponItem = true
        end
    end
    if bFoundWeaponItem then
        for _,v in pairs(tbWeaponItems) do
            if v then
                if ShipWeaponAttachmentHelper.IsWeaponAttachmentCompatible(v, tbItemObject:GetTemplateId()) then
                    return true
                end
            end
        end
        local l10Desc = L10N:Format(UITextDef.FFA_ATTACHMENT_NOT_MATCH)
        UIUtils.ShowToast(l10Desc)
    else
        local l10Desc = L10N:Format(UITextDef.FFA_PACKAGE_NOT_FOUND_WEAPON)
        UIUtils.ShowToast(l10Desc)
    end
    return false


end

local function OnClickedBtnUse( self )
    local tbItem = BattleItemSystemClient:GetItem(self.nItemInstanceId)
    if tbItem then
        if tbItem:GetCategory() == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT then
            if CanEquipAttachement(self) then
                BattleItemSystemClient:RequestEquipItem(0, self.nItemInstanceId, 0)
            end
        end
    end
end

local function DisableClicked (self)
    local l10Desc = L10N:Format(UITextDef.FFA_ATTACHMENT_NOT_MATCH)
    UIUtils.ShowToast(l10Desc)
end

local function OnDisableClickedBtnDiscard( self )
    if self.nItemInstanceId > 0 then
        local tbItemObject = BattleItemSystemClient:GetItem(self.nItemInstanceId)
        self.pbDiscardPart:ShowView(tbItemObject)
    end
end

local function OnDisableClickedBtnDiscardAll( self )
    if self.nItemInstanceId > 0 then
        local tbItem = BattleItemSystemClient:GetItem(self.nItemInstanceId)
        if tbItem then
            BattleItemSystemClient:RequestThrowAwayItem(self.nItemInstanceId, tbItem.nStackCount)
            self.EventHelper:FireEvent(ClientEventDef.EV_REQUEST_THROW_AWAY_ITEM)
        end
    end
end

local function OnClickedBtnSelect( self )
    self:ToogleSelectItem()
    if self:IsSelected() then
        local tbItemObject = BattleItemSystemClient:GetItem(self.nItemInstanceId)
        local tbTemplate = tbItemObject:GetTemplate()
        local nCount = tbItemObject:GetStackCount()
        if self.pbDetail then
            self.pbDetail:ShowDetail(tbTemplate, nCount)
        else
            logerror("self.pbDetail is nil!")
        end
    else
        if self.pbDetail then
            self.pbDetail:HideDetail()
        else
            logerror("self.pbDetail is nil!")
        end
    end
end

local function OnCreateVisual(self, pVisualWidget)
    if self.nItemInstanceId > 0 then
        local tbItem = BattleItemSystemClient:GetItem(self.nItemInstanceId)
        if tbItem then
            local tbRes = BattleItemResDataTable:GetTemplate(tbItem.tbTemplate.nResId)
            if not tbRes then
                logerror("UPBattleItemListItem OnCreateVisual: invalid res id ", tbItem.tbTemplate.nResId)
                return
            end
            local szItemIconPath = tbRes.szIconPath
            local IconObj = szItemIconPath:load()
            if(IconObj == nil)then
                logwarning("UPBattleItemListItem OnCreateVisual: icon is not found,path="..tostring(szItemIconPath))
                return
            end
            local pWidgetRef = self.pWidgetRef
            UISetUtils.SetImageBrushRes(pVisualWidget.imgContent, IconObj, false, true, pWidgetRef.DragSizeX, pWidgetRef.DragSizeY)
        end
    end
end


local function OnItemStackCountChanged(self, Item)
    if Item:GetInstanceId() == self.nItemInstanceId then
        self:RefreshInfo()
    end
end


function UPBattleItemListItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUse.OnClicked, self, OnClickedBtnUse)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnEquipment.OnClicked, self, OnClickedBtnUse)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnEquipment.OnDisableClicked, self, DisableClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDiscard1.OnClicked, self, OnDisableClickedBtnDiscard)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDiscardAll.OnClicked, self, OnDisableClickedBtnDiscardAll)
    EventHelper:RegisterCppDelegate(pWidgetRef.OnClicked, self, OnClickedBtnSelect)
    EventHelper:RegisterCppDelegate(pWidgetRef.OnCreateVisual,self,OnCreateVisual)
    UIDragDropUtils.EnableDragStartAndEndEvent(EventHelper, self.pWidgetRef)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemStackCountChanged)

end

function UPBattleItemListItem:OnRefresh(tbData)
    if not tbData then
        logerror("tbData is nil!", debug.traceback())
        return
    end

    self.nItemInstanceId = tbData.nInstanceId
    self.pbDiscardPart = tbData.pbDiscardPart
    self.pbDetail = tbData.pbDetail
    self:RefreshInfo()
    self.pWidgetRef:SetVisibility(ESlateVisibility_Visible)
    self.pWidgetRef.DragId = self.nItemInstanceId
    self.pWidgetRef.DragCategory = PackageDragCategoryDef.BATTLE_LIST_ITEM
    self.pWidgetRef.bEnableDrag = true
    self.pWidgetRef.bEnableDrop = false
    local bSelected = self:IsSelected()
    self:SetSelected(bSelected)
    self.pbDiscardPart:HideView()
end


function UPBattleItemListItem:RefreshInfo()
    local pWidgetRef = self.pWidgetRef
    local eHitTestInvisible = ESlateVisibility.SelfHitTestInvisible
    local eInvisible = ESlateVisibility.Collapsed
    local tbItemObject = BattleItemSystemClient:GetItem(self.nItemInstanceId)
    local tbItemTemplate = tbItemObject:GetTemplate()
    local nItemTemplateId = tbItemObject:GetTemplateId()
    if tbItemObject then
        if tbItemTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT and
        not tbItemObject:CompatibleWithCurrentWeapons(true) then
            pWidgetRef.imgForbid:SetVisibility(eHitTestInvisible)
            pWidgetRef.btnEquipment:SetIsEnabled(false)
            pWidgetRef.txtEquipment:SetText(UITextDef.UI_BACKPACK_EQUIPMENT_DISABLE)
        else
            pWidgetRef.imgForbid:SetVisibility(eInvisible)
            pWidgetRef.btnEquipment:SetIsEnabled(true)
            pWidgetRef.txtEquipment:SetText(UITextDef.UI_BACKPACK_EQUIPMENT_ENABLE)
        end
        pWidgetRef.btnBlueprintItem:SetVisibility(eHitTestInvisible)
        pWidgetRef.imgColour:SetVisibility(eHitTestInvisible)
        pWidgetRef.txtName:SetVisibility(eHitTestInvisible)
        pWidgetRef.txtDesc:SetVisibility(eInvisible)
        pWidgetRef.txtName:SetText(tbItemTemplate.l10nName)
        UIFFABackpackHelper.SetItemIcon(pWidgetRef.btnBlueprintItem, tbItemTemplate.nResId)

        local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

        if tbItemTemplate.nCategory == BattleItemCategoryDef.SHIP_PART or
        tbItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
            pWidgetRef.imgLevel:SetVisibility(eHitTestInvisible)
            UIFFABackpackHelper.SetPartLevel(pWidgetRef.imgLevel, tbItemTemplate.nGrade)
        else
            pWidgetRef.imgLevel:SetVisibility(eInvisible)
        end

        if tbItemObject.nStackCount > 1 then
            pWidgetRef.txtCount:SetVisibility(eHitTestInvisible)
            pWidgetRef.txtCount:SetText(tostring(tbItemObject.nStackCount))
        else
            pWidgetRef.txtCount:SetVisibility(eInvisible)
        end
    else
        pWidgetRef.txtName:SetVisibility(eInvisible)
        pWidgetRef.btnBlueprintItem:SetVisibility(eInvisible)
        pWidgetRef.imgColour:SetVisibility(eInvisible)
        pWidgetRef.txtCount:SetVisibility(eInvisible)
        pWidgetRef.txtDesc:SetVisibility(eInvisible)
    end
end

function UPBattleItemListItem:SetSelected(bSelected)
    local pWidgetRef = self.pWidgetRef
    local tbItemObject = BattleItemSystemClient:GetItem(self.nItemInstanceId)
    local eVisible = ESlateVisibility.Visible
    local eInvisible = ESlateVisibility.Collapsed
    if tbItemObject then
        self.EventHelper:FireEvent(ClientEventDef.EV_BACKPACK_LISTITEM_SELECTED, tbItemObject.nInstanceId, bSelected)
    end
    if bSelected and tbItemObject then
        if tbItemObject.tbTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT then
            pWidgetRef.btnEquipment:SetVisibility(eVisible)
            pWidgetRef.btnDiscard1:SetVisibility(eInvisible)
        else
            pWidgetRef.btnEquipment:SetVisibility(eInvisible)
            if tbItemObject.nStackCount > 1 then
                pWidgetRef.btnDiscard1:SetVisibility(eVisible)
            else
                pWidgetRef.btnDiscard1:SetVisibility(eInvisible)
            end
        end
        pWidgetRef.vboxOperate:SetVisibility(eVisible)
        pWidgetRef.csvOperate1:SetVisibility(eVisible)
        pWidgetRef.btnDiscardAll:SetVisibility(eVisible)
    else
        pWidgetRef.vboxOperate:SetVisibility(eInvisible)
        pWidgetRef.csvOperate1:SetVisibility(eInvisible)
        pWidgetRef.btnUse:SetVisibility(eInvisible)
        pWidgetRef.btnDiscard1:SetVisibility(eInvisible)
        pWidgetRef.btnDiscardAll:SetVisibility(eInvisible)
        pWidgetRef.btnEquipment:SetVisibility(eInvisible)
    end
end

return UPBattleItemListItem
