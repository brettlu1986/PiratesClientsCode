-----------------------------------------------------
--File Name    : ULHumanPackage.lua
--Author       : WuJizhou
--Create Time  : 9/4/2018, 2:43:34 PM
--Description  : ULHumanPackage
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULHumanPackage = luaclass("ULHumanPackage", UILogicBase)

local HumanWeaponSlotDef = require("HumanWeaponSlotDef")
local UIDef = require("UIDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemRoomDef = require("BattleItemRoomDef")
local SelfVerticalListHelper    = require("SelfVerticalListHelper")
local HumanArmorSlotDef = require("HumanArmorSlotDef")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local UITextDef = require("UITextDef")

local UI_WEAPON_FIXED_SLOT_COUNT = 3
local UI_ARMOR_FIXED_SLOT_COUNT = 3

ULHumanPackage.ListHelper = nil
ULHumanPackage.tbWeaponSlots = nil
ULHumanPackage.bFashion = false
ULHumanPackage.bEnable = false
ULHumanPackage.tbArmorSlots = nil
ULHumanPackage.tbBagSlots = nil

local function ShowFashion(self)
    --UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 1)
end

local function RefreshArmor(self)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local nPlayerInstanceId = tbPlayerSelf:GetServerInstanceId()
    local tbArmors = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_ARMOR, nPlayerInstanceId)
    for i = 1, HumanArmorSlotDef.MaxCount do
        self.tbArmorSlots[i]:ShowArmor(tbArmors[i])
        if not tbArmors[i] then
            self.tbArmorSlots[i]:SetSlotIndex(i)
        end
    end
end

local function GetHumanPackageCapacity(self)
    return BattleItemSystemClient:GetPackageMax(BattleItemRoomDef.HUMAN_INVENTORY)
end

local function GetHumanPackageCapacityUsed(self)
    return BattleItemSystemClient:GetPackageUsed(BattleItemRoomDef.HUMAN_INVENTORY)
end

local function ShowEquipment(self)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local nPlayerInstanceId = tbPlayerSelf:GetServerInstanceId()
    --刷武器位
    local tbEquips = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_WEAPON, nPlayerInstanceId)
    for k, v in pairs(self.tbWeaponSlots) do
        v:ShowWeapon(tbEquips[k])
    end

    local tbItems = BattleItemSystemClient:GetUnEquippedItems(BattleItemRoomDef.HUMAN_INVENTORY)
    local nUsedWeight = 0

    --刷背包列表
    local tbListDatas = {}
    for _, tbItem in ipairs(tbItems) do
        local tbData = {}
        tbData.tbItem = tbItem
        tbData.pbDetail = self.Owner.pbItemDetail
        tbData.pbDiscardPart = self.Owner.pbDiscardPart
        table.insert(tbListDatas, tbData)
        nUsedWeight = nUsedWeight + tbItem:GetTemplate().nWeight * tbItem:GetStackCount()
    end
    self.ListHelper:SetData(tbListDatas)

    --刷背包容量状况
    local nPackageCapacity = GetHumanPackageCapacity(self)
    local nUsedPackageCapacity = GetHumanPackageCapacityUsed(self)
    nUsedPackageCapacity = math.ceil(nUsedPackageCapacity)
    local szPackageState = string.format("%s/%s", tostring(nUsedPackageCapacity), tostring(nPackageCapacity))
    self.pWidgetRef.txtPackageSize:SetText(szPackageState)

    --刷头盔护甲
    RefreshArmor(self)
    --背包槽
    local tbBags = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_BACKPACK, nPlayerInstanceId)
    for k, v in pairs(self.tbBagSlots) do
        v:ShowBag(tbBags[k])
        v:SetSlotIndex(k)
    end
end

local function Refresh(self)
    self.Owner.pbItemDetail:HideDetail()
    if self.bFashion then
        ShowFashion(self)
    else
        ShowEquipment(self)
    end
    self.ListHelper:UnselectCurrentItem()
end

local function OnHumanCurrentWeaponChanged(self, _, _, nCharacterInstanceId)
    if GamePlayerSelfHelper:GetServerInstanceId() == nCharacterInstanceId then
        Refresh(self)
    end
end

function ULHumanPackage:OnRoomSwitched(bFashion)
    self:SetFashionFlag(bFashion)
end

----------public function-----
function ULHumanPackage:SetFashionFlag(bFashion)
    self.bFashion = bFashion
    if self.bEnable == false then
        return
    end
    Refresh(self)
end


function ULHumanPackage:OnItemAdd()
    Refresh(self)
end

function ULHumanPackage:OnItemRemove()
    Refresh(self)
end

function ULHumanPackage:OnItemPosChanged()
    Refresh(self)
end

function ULHumanPackage:OnItemStackCountChanged(nItemInstanceId, nStackCount)
    Refresh(self)
end

local function RefreshCheckBox(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.chEquipRoom:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.txtEquipRoom:SetText(UITextDef.UI_STATIC_FFA_BACKPACK_EQUIP)
    -- pWidgetRef.chClothRoom:SetVisibility(ESlateVisibility.Visible)
    -- pWidgetRef.txtClothRoom:SetText(UITextDef.UI_STATIC_FFA_BACKPACK_CLOTH )
end

local function RegisterEvent(self)
    if self.bEnable and not self.bLazyEventBinded then
        self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED,  self, OnHumanCurrentWeaponChanged)
        self.EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_DURABILITY_CLIENT, self, RefreshArmor)
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
    for k, v in pairs(self.tbWeaponSlots) do
        v:SetEnable(bEnable)
    end
    for k, v in pairs(self.tbBagSlots) do
        v:SetEnable(bEnable)
    end
    for k, v in pairs(self.tbArmorSlots) do
        v:SetEnable(bEnable)
    end
end

function ULHumanPackage:SetEnable(bEnable)
    self.bEnable = bEnable
    --logdebug("ULHumanPackage:SetEnable",bEnable)
    SetContentEnable(self, bEnable)
    if self.bEnable == false then
        return
    end
    self.pWidgetRef.vbxWeapon:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    self.pWidgetRef.humanSideList:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    if not self.ListHelper then
        self.ListHelper = SelfVerticalListHelper()
        self.ListHelper:Init(self, self.pWidgetRef.listItems2, {}, UIDef.UP_HUMAN_ITEM_IN_PACKAGE_LIST)
        self.ListHelper:SetAutoScrollEnabled(false)
        --self.ListHelper:SetEnable(bEnable)
    end

    -- for k, v in pairs(self.tbWeaponSlots) do
    --     v:SetEnable(bEnable)
    -- end
    -- for k, v in pairs(self.tbBagSlots) do
    --     v:SetEnable(bEnable)
    -- end
    -- for k, v in pairs(self.tbArmorSlots) do
    --     v:SetEnable(bEnable)
    -- end

    RefreshCheckBox(self)

    Refresh(self)
    --logdebug("ULHumanPackage:SetEnable end")

    local nActiveCount = HumanWeaponSlotDef:SlotCount()
    for n = 1, UI_WEAPON_FIXED_SLOT_COUNT do
        if n <= nActiveCount then
            self.tbWeaponSlots[n].pWidgetRef:SetVisibility(ESlateVisibility.Visible)
        else
            self.tbWeaponSlots[n].pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
    nActiveCount = HumanArmorSlotDef:SlotCount()
    for n = 1, UI_ARMOR_FIXED_SLOT_COUNT do
        if n <= nActiveCount then
            self.tbArmorSlots[n].pWidgetRef:SetVisibility(ESlateVisibility.Visible)
        else
            self.tbArmorSlots[n].pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

function ULHumanPackage:GetListData()
    local tbItems = BattleItemSystemClient:GetUnEquippedItems(BattleItemRoomDef.HUMAN_INVENTORY)
    local nUsedWeight = 0

    --刷背包列表
    local tbListDatas = {}
    for _, tbItem in ipairs(tbItems) do
        local tbData = {}
        tbData.tbItem = tbItem
        tbData.pbDetail = self.Owner.pbItemDetail
        tbData.pbDiscardPart = self.Owner.pbDiscardPart
        table.insert(tbListDatas, tbData)
        nUsedWeight = nUsedWeight + tbItem:GetTemplate().nWeight * tbItem:GetStackCount()
    end
    return tbListDatas
end

----------life cycle----------

function ULHumanPackage:OnCreate()
    if self.tbWeaponSlots == nil then
        self.tbWeaponSlots = {}
    end

    if self.tbArmorSlots == nil then
        self.tbArmorSlots = {}
    end

    if self.tbBagSlots == nil then
        self.tbBagSlots = {}
    end

    self.bFashion = false;

end

function ULHumanPackage:OnLoad()
    --logdebug("ULHumanPackage:OnLoad1")
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    local nSlotCount = HumanWeaponSlotDef:SlotCount()
    for i=1, UI_WEAPON_FIXED_SLOT_COUNT do
        local tbWeaponSlot = PrefabHelper:BindPrefab(pWidgetRef["pbFightPackMan0" .. i],  UIDef.UP_HUMAN_WEAPON_SLOT)
        if tbWeaponSlot then
            if i <= nSlotCount then
                tbWeaponSlot:SetSlotIndex(i)

            else
                tbWeaponSlot:Disable()
            end
            self.tbWeaponSlots[i] = tbWeaponSlot
        end
    end

    nSlotCount = UI_ARMOR_FIXED_SLOT_COUNT
    for i = 1, nSlotCount do
        local tbArmorSlot = PrefabHelper:BindPrefab(pWidgetRef["pb_ManItem_S" .. i],  UIDef.UP_HUMAN_ARMOR_SLOT)
        if tbArmorSlot then
            --tbArmorSlot:SetSlotIndex(i)
            self.tbArmorSlots[i] = tbArmorSlot
        end
    end

    local tbBagSlot = PrefabHelper:BindPrefab(pWidgetRef["pb_ManItem_S3"],  UIDef.UP_HUMAN_BAG_SLOT)
    if tbBagSlot then
        --tbBagSlot:SetSlotIndex(1)
        self.tbBagSlots[1] = tbBagSlot
    end
    -- self.ListHelper = SelfVerticalListHelper()
    -- self.ListHelper:Init(self, self.pWidgetRef.listItems2, {}, UIDef.UP_HUMAN_ITEM_IN_PACKAGE_LIST)
    -- self.ListHelper:SetAutoScrollEnabled(false)
    --logdebug("ULHumanPackage:OnLoad2")
end

function ULHumanPackage:OnEnter()
    if self.bEnable then
        Refresh(self)
    end
end

-- function ULHumanPackage:OnShow()
-- end

-- function ULHumanPackage:OnHide()
-- end

function ULHumanPackage:OnExit()
    self.bLazyEventBinded = false
end

-- function ULHumanPackage:OnUnload()
-- end

function ULHumanPackage:OnDestroy()
    if self.ListHelper then
        self.ListHelper:Uninit()
    end
end

-- function ULHumanPackage:OnBindEvent(EventHelper)
--     EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED,  self, OnHumanCurrentWeaponChanged)
--     EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_DURABILITY_CLIENT, self, RefreshArmor)
-- end

-- function ULHumanPackage:OnUnbindEvent(EventHelper)
-- end
return ULHumanPackage