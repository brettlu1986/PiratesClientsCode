local luaclass = require("luaclass")
local UPBattleItem = require("UPBattleItem")
local UPWeaponAttachementItem = luaclass("UPWeaponAttachementItem", UPBattleItem)
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipWeaponAttachmentTypeDef = require("ShipWeaponAttachmentTypeDef")
local UIFFABackpackHelper = require("UIFFABackpackHelper")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local BattleItemSystemClient  = require("BattleItemSystemClient")
local ClientEventDef = require("ClientEventDef")
local UISetUtils = require("UISetUtils")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")
local UIDragDropUtils = require("UIDragDropUtils")

UPWeaponAttachementItem.nLimitItemCategory = BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT
UPWeaponAttachementItem.nOwnerInstanceId = -1
UPWeaponAttachementItem.bEnableClickUnequip = true
UPWeaponAttachementItem.bDropEventBinded = false

local ATTACHMENT_SLOT_NAME = {
    [ShipWeaponAttachmentTypeDef.MUZZLE]    = "炮口",
    [ShipWeaponAttachmentTypeDef.SIGHT]     = "准镜",
    [ShipWeaponAttachmentTypeDef.HOLDER]    = "支架",
    [ShipWeaponAttachmentTypeDef.AMMUNITION] = "弹药箱",
    [ShipWeaponAttachmentTypeDef.PEDESTAL]  = "底座"
}



function UPWeaponAttachementItem:OnLoad()
    UPWeaponAttachementItem.super.OnLoad(self)
    --self.pWidgetRef.DragCategory = PackageDragCategoryDef.SHIP_WEAPON_ATTACHMENT
end

function UPWeaponAttachementItem:OnEnter()
    UPWeaponAttachementItem.super.OnEnter(self)
    --self.pWidgetRef.txtName:SetText(ATTACHMENT_SLOT_NAME[self.nSlotIndex])
end


function UPWeaponAttachementItem:OnEquiped(tbItemObject)
    if tbItemObject then
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.DragId = self.nItemInstanceId
        pWidgetRef.DragCategory = PackageDragCategoryDef.SHIP_WEAPON_ATTACHMENT
        pWidgetRef:SetVisibility(ESlateVisibility_Visible)
        pWidgetRef.btnBlueprintItem:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.imgColour:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtName:SetVisibility(ESlateVisibility.Collapsed)
        UIFFABackpackHelper.SetItemIcon(pWidgetRef.btnBlueprintItem, tbItemObject.tbTemplate.nResId)

        local nItemTemplateId = tbItemObject:GetTemplateId()
        local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())
    end
end


function UPWeaponAttachementItem:OnUnequipped()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    pWidgetRef.btnBlueprintItem:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgColour:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtName:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtName:SetText(ATTACHMENT_SLOT_NAME[self.nSlotIndex])
end

function UPWeaponAttachementItem:CanEquip(tbItemObject)
    if UPWeaponAttachementItem.super.CanEquip(self, tbItemObject) then
        return tbItemObject.tbTemplate.nSubCategory == self.nSlotIndex
    end
    return false
end


local function OnAcceptDrop(self, nDragSourceCategory, nDragSourceId)
    if nDragSourceCategory == PackageDragCategoryDef.SHIP_WEAPON_ATTACHMENT and
        nDragSourceId ~= self.nItemInstanceId then
        local tbAttachmentItem = BattleItemSystemClient:GetItem(nDragSourceId)
        if tbAttachmentItem and tbAttachmentItem.tbTemplate.nSubCategory == self.nSlotIndex and self.nOwnerInstanceId > 0 then
            if self.nItemInstanceId > 0 then
                if BattleItemSystemClient:CanExchangeStorageLocation(tbAttachmentItem.nInstanceId, self.nItemInstanceId) then
                    BattleItemSystemClient:RequestExchangeStorageLocation(tbAttachmentItem.nInstanceId, self.nItemInstanceId)
                else
                    BattleItemSystemClient:RequestUnEquipItem(self.nItemInstanceId)
                    BattleItemSystemClient:TryToRequestEquipItem(self.nOwnerInstanceId, self.nSlotIndex, tbAttachmentItem)
                    log("unequip and then equip the new one...")
                end
            else
                BattleItemSystemClient:TryToRequestEquipItem(self.nOwnerInstanceId, self.nSlotIndex, tbAttachmentItem)
            end
        end
    elseif nDragSourceCategory == PackageDragCategoryDef.BATTLE_LIST_ITEM then
        if self.nOwnerInstanceId > 0 then
            local tbAttachmentItem = BattleItemSystemClient:GetItem(nDragSourceId)
            if tbAttachmentItem and tbAttachmentItem.tbTemplate.nCategory == self.nLimitItemCategory and
            tbAttachmentItem.tbTemplate.nSubCategory == self.nSlotIndex then
                BattleItemSystemClient:TryToRequestEquipItem(self.nOwnerInstanceId, self.nSlotIndex, tbAttachmentItem)
            end
        end
    end
end

local function OnDragStart(self, nDragSourceCategory, nDragSourceId)
    if nDragSourceCategory == PackageDragCategoryDef.BATTLE_LIST_ITEM
        and self.nOwnerInstanceId > 0 then
        local tbAttachmentItem = BattleItemSystemClient:GetItem(nDragSourceId)
        if tbAttachmentItem == nil then
            logwarning("cannot find attachment item", nDragSourceId)
            return
        end
        if tbAttachmentItem.tbTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT and
        tbAttachmentItem.tbTemplate.nSubCategory == self.nSlotIndex and self.nItemInstanceId <= 0 and
        BattleItemSystemClient:CheckItemSlotCompatibility(self.nOwnerInstanceId, self.nSlotIndex, tbAttachmentItem) then
            self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    elseif nDragSourceCategory == PackageDragCategoryDef.SHIP_WEAPON_ATTACHMENT
        and self.nOwnerInstanceId > 0 and nDragSourceId ~= self.nItemInstanceId then
        local tbAttachmentItem = BattleItemSystemClient:GetItem(nDragSourceId)
        if tbAttachmentItem == nil then
            logwarning("cannot find attachment item", nDragSourceId)
            return
        end
        if tbAttachmentItem and tbAttachmentItem.tbTemplate.nSubCategory == self.nSlotIndex and
        BattleItemSystemClient:CheckItemSlotCompatibility(self.nOwnerInstanceId, self.nSlotIndex, tbAttachmentItem) then
            self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

local function OnDragEnd(self, nDragSourceCategory, nDragSourceId)
    self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnListItemSelected(self, nItemInstanceId, bSelected)
    if bSelected then
        local tbAttachmentItem = BattleItemSystemClient:GetItem(nItemInstanceId)
        if tbAttachmentItem and tbAttachmentItem.tbTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT and
        tbAttachmentItem.tbTemplate.nSubCategory == self.nSlotIndex and self.nItemInstanceId <= 0 and
        BattleItemSystemClient:CheckItemSlotCompatibility(self.nOwnerInstanceId, self.nSlotIndex, tbAttachmentItem) then
            self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    else
        self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.Collapsed)
    end
end


function UPWeaponAttachementItem:OnBindEvent(EventHelper)

end


function UPWeaponAttachementItem:RegisterDropEvent()
    if not self.bDropEventBinded and self.bEnabled and self.nOwnerInstanceId > 0 then
        local EventHelper = self.EventHelper
        local pbDrag = self.pWidgetRef
        EventHelper:RegisterCppDelegate(pbDrag.OnAcceptDrop, self, OnAcceptDrop)
        EventHelper:RegisterEvent(ClientEventDef.EV_UI_DRAG_START, self, OnDragStart)
        EventHelper:RegisterEvent(ClientEventDef.EV_UI_DRAG_END, self, OnDragEnd)
        EventHelper:RegisterEvent(ClientEventDef.EV_BACKPACK_LISTITEM_SELECTED, self, OnListItemSelected)
        UIDragDropUtils.FireEventWhenItemDropped(EventHelper, pbDrag)
        self.bDropEventBinded = true
    end
end

function UPWeaponAttachementItem:OnExit()
    UPWeaponAttachementItem.super.OnExit(self)
    self.bDropEventBinded = false
end

function UPWeaponAttachementItem:SetEnable(bEnabled)
    UPWeaponAttachementItem.super.SetEnable(self, bEnabled)
    if not bEnabled then
        self.bDropEventBinded = false
    end
end


return UPWeaponAttachementItem