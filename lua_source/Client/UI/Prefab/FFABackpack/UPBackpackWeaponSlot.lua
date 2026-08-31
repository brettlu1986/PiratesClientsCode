local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBackpackWeaponSlot = luaclass("UPBackpackWeaponSlot", PrefabBase)

local L10N = require("L10N")
local UIDef = require("UIDef")
local UITextDef = require("UITextDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local ShipWeaponAttachmentTypeDef = require("ShipWeaponAttachmentTypeDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemResDataTable = require("BattleItemResDataTable")
local UISetUtils = require("UISetUtils")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIDragDropUtils = require("UIDragDropUtils")
local ClientEventDef = require("ClientEventDef")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipWeaponAttachmentHelper = require("ShipWeaponAttachmentHelper")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPBackpackWeaponSlot.nSlotIndex = 0
UPBackpackWeaponSlot.nWeaponId = 0
UPBackpackWeaponSlot.tbAttachmentSlots = { }
UPBackpackWeaponSlot.bLazyDragEventBinded = false
UPBackpackWeaponSlot.bLazyDropEventBinded = false
UPBackpackWeaponSlot.bEnabled = false

function UPBackpackWeaponSlot:OnLoad()
    for i=1,ShipWeaponAttachmentTypeDef.Max do
        local tbAttachementSlot = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbPackItem0" .. i],
        UIDef.UP_WEAPON_ATTACHEMENT_ITEM)
        if tbAttachementSlot then
            tbAttachementSlot:SetSlotId(i)
            self.tbAttachmentSlots[i] = tbAttachementSlot
        end
    end
    --self.pWidgetRef.pbDrag:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    self:SetWeaponId(0)
    self:SetActive(false)
end

function UPBackpackWeaponSlot:SetSlotId(nSlotIndex)
    local pWidgetRef = self.pWidgetRef
    self.nSlotIndex = nSlotIndex
    pWidgetRef.txtWeaponName:SetText(UITextDef.SHIP_WEAPON_SLOT_NAME[self.nSlotIndex])
    --pWidgetRef.pbDrag.DragCategory = PackageDragCategoryDef.SHIP_WEAPON_SLOT
    self.pWidgetRef.DragCategory = PackageDragCategoryDef.SHIP_WEAPON_SLOT
end


local function OnCreateVisual(self, pVisualWidget)
    if self.nWeaponId > 0 then
        local tbWeaponItem = BattleItemSystemClient:GetItem(self.nWeaponId)
        if tbWeaponItem then
            local tbRes = BattleItemResDataTable:GetTemplate(tbWeaponItem.tbTemplate.nResId)
            if not tbRes then
                logerror("UPBattleItemListItem OnCreateVisual: invalid res id ", tbWeaponItem.tbTemplate.nResId)
                return
            end
            local szItemIconPath = tbRes.szEquipmentDisplayPath
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


local function OnAcceptDrop(self, nDragSourceCategory, nDragSourceId)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local nOwnerInstanceId = tbPlayerSelf:GetServerInstanceId()
    -- drag from other weapon slot
    if nDragSourceCategory == PackageDragCategoryDef.SHIP_WEAPON_SLOT and nDragSourceId ~= self.nWeaponId then
        local tbWeaponItem = BattleItemSystemClient:GetItem(nDragSourceId)
        if tbWeaponItem then
            if self.nWeaponId > 0 then
                if BattleItemSystemClient:CanExchangeStorageLocation(tbWeaponItem.nInstanceId, self.nWeaponId) then
                    BattleItemSystemClient:RequestExchangeStorageLocation(tbWeaponItem.nInstanceId, self.nWeaponId)
                else
                    log("exchange item not acceptable...")
                end
            else
                BattleItemSystemClient:TryToRequestEquipItem(nOwnerInstanceId, self.nSlotIndex, tbWeaponItem)
            end
        end
    -- drag from list item include weapon and attachement
    elseif nDragSourceCategory == PackageDragCategoryDef.BATTLE_LIST_ITEM then
        local tbItem = BattleItemSystemClient:GetItem(nDragSourceId)
        if tbItem then
            if tbItem.tbTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT then
                if self.nWeaponId > 0 then
                    BattleItemSystemClient:TryToRequestEquipItem(self.nWeaponId, tbItem.tbTemplate.nSubCategory, tbItem)
                end
            elseif tbItem.tbTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON then
                if nOwnerInstanceId > 0 then
                    BattleItemSystemClient:TryToRequestEquipItem(nOwnerInstanceId, self.nSlotIndex, tbItem)
                end
            end
        end
    -- drag from other attachment
    elseif nDragSourceCategory == PackageDragCategoryDef.SHIP_WEAPON_ATTACHMENT then
        local tbItem = BattleItemSystemClient:GetItem(nDragSourceId)
        if tbItem and self.nWeaponId > 0 then
            if tbItem.tbTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT then
                BattleItemSystemClient:TryToRequestEquipItem(self.nWeaponId, tbItem.tbTemplate.nSubCategory, tbItem)
            end
        end
    end
end


local function OnDragStart(self, nDragSourceCategory, nDragSourceId)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local nOwnerInstanceId = tbPlayerSelf:GetServerInstanceId()
    if nDragSourceCategory == PackageDragCategoryDef.SHIP_WEAPON_SLOT
        and nDragSourceId ~= self.nWeaponId then
        local tbWeaponItem = BattleItemSystemClient:GetItem(nDragSourceId)
        if tbWeaponItem and BattleItemSystemClient:CheckItemSlotCompatibility(nOwnerInstanceId, self.nSlotIndex, tbWeaponItem) then
            self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    elseif nDragSourceCategory == PackageDragCategoryDef.BATTLE_LIST_ITEM then
        local tbWeaponItem = BattleItemSystemClient:GetItem(nDragSourceId)
        if tbWeaponItem and tbWeaponItem.tbTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON and
        BattleItemSystemClient:CheckItemSlotCompatibility(nOwnerInstanceId, self.nSlotIndex, tbWeaponItem) then
            self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

local function OnDragEnd(self, nDragSourceCategory, nDragSourceId)
    self.pWidgetRef.imgDropNotify:SetVisibility(ESlateVisibility.Collapsed)
end

local function IsAllowToDrag(tbWeaponItem)
    local tbTemplate = tbWeaponItem and tbWeaponItem.tbTemplate
    if tbTemplate.bDefaultWeapon == nil then
        return true
    else
        return not tbTemplate.bDefaultWeapon
    end
end

function UPBackpackWeaponSlot:RegisterDragEvent()
    if not self.bLazyDragEventBinded and self.bEnabled and self.nWeaponId > 0 then
        local EventHelper = self.EventHelper
        --local pbDrag = self.pWidgetRef.pbDrag
        local pbDrag = self.pWidgetRef
        EventHelper:RegisterCppDelegate(pbDrag.OnCreateVisual,self,OnCreateVisual)
        UIDragDropUtils.FireEventWhenItemDragged(EventHelper, pbDrag)
        self.bLazyDragEventBinded = true
    end
end

function UPBackpackWeaponSlot:RegisterDropEvent()
    if not self.bLazyDropEventBinded and self.bEnabled then
        local EventHelper = self.EventHelper
        --local pbDrag = self.pWidgetRef.pbDrag
        local pbDrag = self.pWidgetRef
        EventHelper:RegisterCppDelegate(pbDrag.OnAcceptDrop, self, OnAcceptDrop)
        EventHelper:RegisterEvent(ClientEventDef.EV_UI_DRAG_START, self, OnDragStart)
        EventHelper:RegisterEvent(ClientEventDef.EV_UI_DRAG_END, self, OnDragEnd)
        UIDragDropUtils.FireEventWhenItemDropped(EventHelper, pbDrag)
        self.bLazyDropEventBinded = true
    end
end

function UPBackpackWeaponSlot:SetEnable(bEnabled)
    self.bEnabled = bEnabled
    local tbAttachmentSlots = self.tbAttachmentSlots
    for i=1,ShipWeaponAttachmentTypeDef.Max do
        tbAttachmentSlots[i]:SetEnable(bEnabled)
    end
    if not bEnabled then
        self.bLazyDropEventBinded = false
        self.bLazyDragEventBinded = false
        self.EventHelper:UnregisterAll()
    end
end

function UPBackpackWeaponSlot:OnBindEvent(EventHelper)


end

function UPBackpackWeaponSlot:SetWeaponId(nWeaponId)
    self.nWeaponId = nWeaponId
    local tbWeaponItem = BattleItemSystemClient:GetItem(nWeaponId)
    local pWidgetRef = self.pWidgetRef
    local pSelfHitTestInvisible = ESlateVisibility_SelfHitTestInvisible
    local pCollapsed = ESlateVisibility_Collapsed
    local tbAttachmentSlots = self.tbAttachmentSlots
    pWidgetRef.imgLevel:SetVisibility(pCollapsed)
    self:RegisterDropEvent()
    if tbWeaponItem then
        self:RegisterDragEvent()
        local tbTemplate = tbWeaponItem.tbTemplate
        -- pWidgetRef.pbDrag.DragId = nWeaponId
        -- pWidgetRef.pbDrag.bEnableDrag = true
        pWidgetRef.DragId = nWeaponId
        pWidgetRef.bEnableDrag = IsAllowToDrag(tbWeaponItem)
        pWidgetRef.txtWeaponName:SetVisibility(pSelfHitTestInvisible)
        pWidgetRef.txtWeaponName:SetText(tbTemplate.l10nName)
        pWidgetRef.imgIcon:SetVisibility(pSelfHitTestInvisible)
        pWidgetRef.imgColour:SetVisibility(pSelfHitTestInvisible)

        if tbTemplate.nBulletItemTemplateId > 0 then
            pWidgetRef.txtBulletName:SetVisibility(pSelfHitTestInvisible)
            local nLoadedCount = tbWeaponItem:GetBulletLoadedCount(true)
            local szCountDesc = nil
            if tbWeaponItem:IsInfiniteBullet() then
                local nMaxLoadedCount = tbWeaponItem:GetBulletMaxLoadingCount(true)
                szCountDesc = L10N:Format(UISetUtils.GetL10NTextByKey("UI_BULLET_COUNT"), nLoadedCount, nMaxLoadedCount)
                pWidgetRef.txtBulletName:SetText(szCountDesc)
            else
                local szUnloadedCount = tbWeaponItem:GetBulletUnloadedCount(true)
                szCountDesc = L10N:Format(UISetUtils.GetL10NTextByKey("UI_BULLET_COUNT"), nLoadedCount, szUnloadedCount)
                pWidgetRef.txtBulletName:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("UI_AMMO_STATE"),
                BattleItemDataTable:GetTemplate(tbTemplate.nBulletItemTemplateId).l10nName, szCountDesc))
            end

        else
            pWidgetRef.txtBulletName:SetVisibility(pCollapsed)
        end
        local tbResTemplate = BattleItemDataTable:GetResTemplate(tbWeaponItem:GetTemplateId())
        if tbResTemplate and tbResTemplate.szEquipmentDisplayPath then
            UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgIcon, tbResTemplate.szEquipmentDisplayPath, nil, true)
            --UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, tbResTemplate.szEquipmentDisplayPath:load(), true)
        end

        local nItemTemplateId = tbTemplate.nId
        local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

        --pWidgetRef.btnPass:SetVisibility(ESlateVisibility.Visible)
        for i=1,ShipWeaponAttachmentTypeDef.Max do
            local tbWeaponAttachment = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT, nWeaponId, i)
            if tbWeaponAttachment then
                self:SetAttachment(i, tbWeaponAttachment:GetInstanceId(), nWeaponId)
            else
                self:SetAttachment(i, 0, nWeaponId)
            end
            if ShipWeaponAttachmentHelper.IsWeaponAttachmentOpen(tbWeaponItem, i) then
                tbAttachmentSlots[i].pWidgetRef:SetVisibility(ESlateVisibility_Visible)
                tbAttachmentSlots[i]:RegisterDropEvent()
            else
                tbAttachmentSlots[i].pWidgetRef:SetVisibility(pCollapsed)
            end
        end
    else
        --pWidgetRef.pbDrag.bEnableDrag = false
        pWidgetRef.bEnableDrag = false
        --pWidgetRef.btnPass:SetVisibility(pCollapsed)
        pWidgetRef.txtWeaponName:SetText(UITextDef.SHIP_WEAPON_SLOT_NAME[self.nSlotIndex])
        -- pWidgetRef.txtWeaponName:SetVisibility(pCollapsed)
        pWidgetRef.txtBulletName:SetVisibility(pCollapsed)
        pWidgetRef.imgIcon:SetVisibility(pCollapsed)
        pWidgetRef.imgColour:SetVisibility(pCollapsed)
        for i=1,ShipWeaponAttachmentTypeDef.Max do
            self:SetAttachment(i, 0, 0)
            tbAttachmentSlots[i].pWidgetRef:SetVisibility(pCollapsed)
        end
        self:SetActive(false)
    end
end

function UPBackpackWeaponSlot:SetActive(bActive)
    if bActive then
        self.pWidgetRef.txtIsInUse:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.txtIsInUse:SetVisibility(ESlateVisibility.Collapsed)
    end

end

function UPBackpackWeaponSlot:OnExit()
    self.bLazyDragEventBinded = false
    self.bLazyDropEventBinded = false
end

function UPBackpackWeaponSlot:SetAttachment(nSlotIndex, nAttachementId, nOwnerInstanceId)
    local tbAttachmentSlots = self.tbAttachmentSlots
    if tbAttachmentSlots[nSlotIndex] then
        tbAttachmentSlots[nSlotIndex]:SetItem(nAttachementId)
        tbAttachmentSlots[nSlotIndex].nOwnerInstanceId = nOwnerInstanceId
    end
end


return UPBackpackWeaponSlot