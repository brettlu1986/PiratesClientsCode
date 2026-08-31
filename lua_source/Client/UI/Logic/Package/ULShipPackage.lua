
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULShipPackage = luaclass("ULShipPackage", UILogicBase)


local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local UIDef = require("UIDef")
local ShipPartTypeDef = require("ShipPartTypeDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemRoomDef = require("BattleItemRoomDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CommonEventDef = require("CommonEventDef")
local VerticalListHelper = require("SelfVerticalListHelper")
local UITextDef = require("UITextDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local ListItemTypeDef = {
    EQUIP = 1,
    CLOTH = 2,
}

ULShipPackage.tbWeaponSlots = { }
ULShipPackage.tbShipPartSlots = { }
ULShipPackage.nListType = ListItemTypeDef.EQUIP
ULShipPackage.ListHelper = nil


local function RefreshItemList(self)
    self.Owner.pbItemDetail:HideDetail()
    local ListHelper = self.ListHelper
    if self.nListType == ListItemTypeDef.EQUIP then
        local tbItems = BattleItemSystemClient:GetUnEquippedItems(BattleItemRoomDef.CABIN)
        local tbListItems = { }
        for _,v in pairs(tbItems) do
            table.insert( tbListItems, { nInstanceId = v.nInstanceId, pbDetail = self.Owner.pbItemDetail, pbDiscardPart = self.Owner.pbDiscardPart } )
        end
        local nMaxSlots = BattleItemSystemClient:GetPackageMax(BattleItemRoomDef.CABIN)
        local nUsedSots = BattleItemSystemClient:GetPackageUsed(BattleItemRoomDef.CABIN)
        nUsedSots = math.ceil(nUsedSots)
        self.pWidgetRef.txtPackageSize:SetText(string.format("%s/%s", tostring(nUsedSots), tostring(nMaxSlots)))
        ListHelper:SetData(tbListItems)
    elseif self.nListType == ListItemTypeDef.CLOTH then
        local tbListItems = { }
        self.pWidgetRef.txtPackageSize:SetText(string.format("%d/%d", #tbListItems, 999))
        ListHelper:SetData(tbListItems)
    end
    self.ListHelper:UnselectCurrentItem()
end


local function SetListItemType(self, nNewListItemType)
    self.nListType = nNewListItemType
    if self.bEnable then
        RefreshItemList(self)
    end
end


function ULShipPackage:OnRoomSwitched(bFlag)
    if bFlag then
        SetListItemType(self, ListItemTypeDef.CLOTH)
    else
        SetListItemType(self, ListItemTypeDef.EQUIP)
    end
end

local function RefreshCheckBox(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.chEquipRoom:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.txtEquipRoom:SetText(UITextDef.UI_STATIC_FFA_BACKPACK_EQUIP)
    -- pWidgetRef.chClothRoom:SetVisibility(ESlateVisibility.Visible)
    -- pWidgetRef.txtClothRoom:SetText(UITextDef.UI_STATIC_FFA_BACKPACK_CLOTH )
end

local function OnWeaponActive(self, tbCharacter, NewActiveWeaponItem, OldActiveWeaponItem)
    if GamePlayerSelfHelper:Get() == tbCharacter then
        local tbWeaponSlots = self.tbWeaponSlots
        local nActiveSlot = BattleShipWeaponSystem:GetActiveWeaponSlot_C()
        for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
            tbWeaponSlots[i]:SetActive(nActiveSlot == i)
        end
    end
end

local function RegisterEvent(self)
    if self.bEnable and not self.bLazyEventBinded then
        self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_ACTIVE_WEAPON_ITEM_CHANGED, self, OnWeaponActive)
        self.bLazyEventBinded = true
    end
end

local function UnregisterEvent(self)
    self.EventHelper:UnregisterAll()
    self.bLazyEventBinded = false
end

local function SetContentEnable(self, bEnable)
    if self.ListHelper then
        --self.ListHelper:SetData()
        self.ListHelper:SetEnable(bEnable)
    end
    if bEnable then
        RegisterEvent(self)
    else
        UnregisterEvent(self)
    end
    local tbWeaponSlots = self.tbWeaponSlots
    local tbShipPartSlots = self.tbShipPartSlots
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        tbWeaponSlots[i]:SetEnable(bEnable)
    end

    for i=1,ShipPartTypeDef.Max do
        tbShipPartSlots[i]:SetEnable(bEnable)
    end
end

function ULShipPackage:SetEnable(bEnable)
    self.bEnable = bEnable
    --logdebug("ULShipPackage:SetEnable",bEnable)
    SetContentEnable(self, bEnable)
    if self.bEnable == false then
        -- if self.ListHelper then
        --     --self.ListHelper:SetData()
        --     self.ListHelper:SetEnable(bEnable)
        -- end
        return
    end
    if not self.ListHelper then
        self.ListHelper = VerticalListHelper()
        self.ListHelper:Init(self, self.pWidgetRef.listItems2, { }, UIDef.UP_BATTLE_ITEM_LISTITEM)
        self.ListHelper:SetAutoScrollEnabled(false)
    end
    self.ListHelper:SetEnable(bEnable)
    self.pWidgetRef.vbxWeapon:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    self.pWidgetRef.humanSideList:SetVisibility(ESlateVisibility_SelfHitTestInvisible)

    -- local tbWeaponSlots = self.tbWeaponSlots
    -- local tbShipPartSlots = self.tbShipPartSlots
    -- for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
    --     tbWeaponSlots[i]:SetEnable(bEnable)
    -- end

    -- for i=1,ShipPartTypeDef.Max do
    --     tbShipPartSlots[i]:SetEnable(bEnable)
    -- end

    RefreshCheckBox(self)

    self:RefreshData()

    for n = ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        self.tbWeaponSlots[n].pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    end

    for n = 1, ShipPartTypeDef.Max do
        self.tbShipPartSlots[n].pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    end

    --logdebug("ULShipPackage:SetEnable end")
end

function ULShipPackage:OnLoad()
    --logdebug("ULShipPackage:OnLoad1")
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    local tbWeaponSlots = self.tbWeaponSlots
    local tbShipPartSlots = self.tbShipPartSlots
    --logdebug("ULShipPackage:OnLoad list start")
    -- self.ListHelper = VerticalListHelper()
    -- self.ListHelper:Init(self, self.pWidgetRef.listItems2, { }, UIDef.UP_BATTLE_ITEM_LISTITEM)
    -- self.ListHelper:SetAutoScrollEnabled(false)
    --logdebug("ULShipPackage:OnLoad list end")
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbWeaponSlot = PrefabHelper:BindPrefab(pWidgetRef["pbFightPackMan0" .. i],
        UIDef.UP_WEAPON_SLOT)
        if tbWeaponSlot then
            tbWeaponSlot:SetSlotId(i)
            tbWeaponSlots[i] = tbWeaponSlot
        end
    end

    for i=1,ShipPartTypeDef.Max do
        local tbShipPartSlot = PrefabHelper:BindPrefab(pWidgetRef["pb_ManItem_S" .. i],
        UIDef.UP_SHIP_PART_ITEM)
        if tbShipPartSlot then
            tbShipPartSlot:SetSlotId(i)
            tbShipPartSlots[i] = tbShipPartSlot
        end
    end
    --logdebug("ULShipPackage:OnLoad2")
end

function ULShipPackage:OnEnter()
    self:OnRoomSwitched(false)
end

function ULShipPackage:OnExit()
    self.bLazyEventBinded = false
end

function ULShipPackage:OnDestroy()
    if self.ListHelper then
        self.ListHelper:Uninit()
    end
end


function ULShipPackage:RefreshData()
    log("refresh ship packages")
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local tbWeaponSlots = self.tbWeaponSlots
    local nActiveSlot = BattleShipWeaponSystem:GetActiveWeaponSlot_C()
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbWeapon = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, tbPlayerSelf.nServerInstanceId, i)
        if tbWeapon then
            self:SetWeaponId(i, tbWeapon:GetInstanceId())
            tbWeaponSlots[i]:SetActive(i == nActiveSlot)
        else
            self:SetWeaponId(i, 0)
        end
    end

    for i=1,ShipPartTypeDef.Max do
        local tbShipPart = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_PART, tbPlayerSelf.nServerInstanceId, i)
        if tbShipPart then
            self:SetShipPartId(i, tbShipPart:GetInstanceId())
        else
            self:SetShipPartId(i, 0)
        end
    end

    RefreshItemList(self)
end

function ULShipPackage:OnItemAdd()
    self:RefreshData()
end

function ULShipPackage:OnItemRemove()
    self:RefreshData()
end

function ULShipPackage:OnItemPosChanged()
    self:RefreshData()
end

function ULShipPackage:OnItemStackCountChanged(nItemInstanceId, nStackCount)
    self:RefreshData()
end

function ULShipPackage:SetWeaponId(nSlotIndex, nWeaponId)
    if self.tbWeaponSlots[nSlotIndex] then
        self.tbWeaponSlots[nSlotIndex]:SetWeaponId(nWeaponId)
    end
end

function ULShipPackage:GetWeaponSlot(nSlotIndex)
    return self.tbWeaponSlots[nSlotIndex]
end

function ULShipPackage:SetShipPartId(nSlotIndex, nShipPartId)
    if self.tbShipPartSlots[nSlotIndex] then
        self.tbShipPartSlots[nSlotIndex]:SetItem(nShipPartId)
    end
end

function ULShipPackage:GetShipPartId(nSlotIndex)
    return self.tbShipPartSlots[nSlotIndex]
end

return ULShipPackage