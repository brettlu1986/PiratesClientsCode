local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingPickUp = luaclass("UPSettingPickUp", PrefabBase)
local SettingClassType = require("SettingClassType")
local SettingSystemNew = require("SettingSystemNew")
local SettingKeyDef    = require("SettingKeyDef")
local SettingPickUpDataTable = require("SettingPickUpDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ConsumableItemDef = require("ConsumableItemDef")
local UIDef = require("UIDef")

local LocalKeys= SettingKeyDef.LocalKeys
local MAX_AUTO = 1
local MAX_CHANGE_SAIL = 1
local MIN_PICKUP_COUNT = 0
local CHECKED, UNCHECKED = ECheckBoxState.Checked, ECheckBoxState.Unchecked

UPSettingPickUp.tbInstance = nil
UPSettingPickUp.tbConsumablePrefab= nil
UPSettingPickUp.tbThrowPrefab= nil
UPSettingPickUp.tbShipThrowPrefab = nil

local function RefreshAuto(self)
    local pWidgetRef = self.pWidgetRef
    local nCurValue = self.tbInstance:Get(LocalKeys.PICK_UP_AUTO)

    for i = 0, MAX_AUTO do
        pWidgetRef["cbAutoPick"..i]:SetCheckedState(nCurValue == i and CHECKED or UNCHECKED)
    end
end

local function RefreshAutoChangeSail(self)
    local pWidgetRef = self.pWidgetRef
    local nCurValue = self.tbInstance:Get(LocalKeys.PICK_UP_AUTO_CHANGE_SAIL)

    for i = 0, MAX_CHANGE_SAIL do
        pWidgetRef["cbAutoChangeSail"..i]:SetCheckedState(nCurValue == i and CHECKED or UNCHECKED)
    end
end

local function RefreshAutoList(self)
    local pWidgetRef = self.pWidgetRef
    local nCurValue = self.tbInstance:Get(LocalKeys.PICK_UP_LIST_AUTO)

    for i = 0, MAX_AUTO do
        pWidgetRef["cbListAutoPick"..i]:SetCheckedState(nCurValue == i and CHECKED or UNCHECKED)
    end
end

local function RefreshConsumable(self)
    for i, v in ipairs(self.tbConsumablePrefab) do
        local nId = v:GetData()
        local nValue = self.tbInstance:GetValue(nId)
        v:OnRefresh(nValue)
    end
end

local function RefreshThrow(self)
    for i, v in ipairs(self.tbThrowPrefab) do
        local nId = v:GetData()
        local nValue = self.tbInstance:GetValue(nId)
        v:OnRefresh(nValue)
    end
end

local function RefreshShipThrow(self)
    for i, v in ipairs(self.tbShipThrowPrefab) do
        local nId = v:GetData()
        local nValue = self.tbInstance:GetValue(nId)
        v:OnRefresh(nValue)
    end
end

local function RefreshUI(self)
    RefreshAuto(self)
    RefreshAutoChangeSail(self)
    RefreshAutoList(self)
    RefreshConsumable(self)
    RefreshThrow(self)
    RefreshShipThrow(self)
end

local function ChangeValue(self, nIndex, bActivate, nKey, szWidgetName)
    local nCurValue = self.tbInstance:Get(nKey)
    if nCurValue == nIndex then
        if not bActivate then
            self.pWidgetRef[szWidgetName..nIndex]:SetCheckedState(CHECKED)
        end
    else
        self.tbInstance:Set(nKey, nIndex)
        SettingSystemNew:SaveLocalData()
        return true
    end
    return false
end

local function OnClickedAutoPick(self, nIndex, bActivate)
    if ChangeValue(self, nIndex, bActivate, LocalKeys.PICK_UP_AUTO, "cbAutoPick") then
        RefreshAuto(self)
    end
end

local function OnClickedAutoChangeSail(self, nIndex, bActivate)
    if ChangeValue(self, nIndex, bActivate, LocalKeys.PICK_UP_AUTO_CHANGE_SAIL, "cbAutoChangeSail") then
        RefreshAutoChangeSail(self)
    end
end

local function OnClickedListAutoPick(self, nIndex, bActivate)
    if ChangeValue(self, nIndex, bActivate, LocalKeys.PICK_UP_LIST_AUTO, "cbListAutoPick") then
        RefreshAutoList(self)
    end
end

function UPSettingPickUp:OnLoad()
    local tbConsumableItems, tbThrowItems, tbShipThrowItems = {}, {}, {}

    local tbPickUpDatas = SettingPickUpDataTable:GetAll()
    local ConsumableSubType = ConsumableItemDef.ConsumableSubType

    local tbItemData
    for k, v in pairs(tbPickUpDatas) do
        if v.nSettingType > 0 then
            tbItemData = BattleItemDataTable:GetTemplate(v.nItemId)
            if tbItemData then
                if (tbItemData.nCategory == BattleItemCategoryDef.HUMAN_CONSUMABLE
                    and (tbItemData.nSubCategory == ConsumableSubType.MEDICINE or tbItemData.nSubCategory == ConsumableSubType.FOOD_AND_DRINK)) then
                    table.insert(tbConsumableItems, {nId = v.nId, tbItemData = tbItemData, nMaxCount = v.nMaxCount})
                elseif (tbItemData.nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
                    table.insert(tbThrowItems, {nId = v.nId, tbItemData = tbItemData, nMaxCount = v.nMaxCount})
                elseif (tbItemData.nCategory == BattleItemCategoryDef.SHIP_THROWN_ITEM) then
                    table.insert(tbShipThrowItems, {nId = v.nId, tbItemData = tbItemData, nMaxCount = v.nMaxCount})
                end
            end
        end
    end

    self.tbConsumablePrefab, self.tbThrowPrefab, self.tbShipThrowPrefab = {}, {}, {}
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    local Prefab
    for i, v in ipairs(tbConsumableItems) do
        Prefab = PrefabHelper:CreatePrefab(UIDef.UP_SETTING_PICKUP_SUB)
        Prefab:SetData(self, v.nId, v.tbItemData, MIN_PICKUP_COUNT, v.nMaxCount)
        pWidgetRef.wbConsumable:AddChildToWrapBox(Prefab.pWidgetRef)
        table.insert(self.tbConsumablePrefab, Prefab)
    end
    for i, v in ipairs(tbThrowItems) do
        Prefab = PrefabHelper:CreatePrefab(UIDef.UP_SETTING_PICKUP_SUB)
        Prefab:SetData(self, v.nId, v.tbItemData, MIN_PICKUP_COUNT, v.nMaxCount)
        pWidgetRef.wbThrow:AddChildToWrapBox(Prefab.pWidgetRef)
        table.insert(self.tbThrowPrefab, Prefab)
    end
    for i, v in ipairs(tbShipThrowItems) do
        Prefab = PrefabHelper:CreatePrefab(UIDef.UP_SETTING_PICKUP_SUB)
        Prefab:SetData(self, v.nId, v.tbItemData, MIN_PICKUP_COUNT, v.nMaxCount)
        pWidgetRef.wbShipThrow:AddChildToWrapBox(Prefab.pWidgetRef)
        table.insert(self.tbShipThrowPrefab, Prefab)
    end
end

function UPSettingPickUp:OnShow()
    RefreshUI(self)
end

function UPSettingPickUp:OnCreate()
    self.tbInstance = SettingSystemNew:GetInstance(SettingClassType.Setting_PickUp)
end

function UPSettingPickUp:OnDestroy()
    self.tbInstance = nil
    self.tbConsumablePrefab= nil
    self.tbThrowPrefab= nil
end

function UPSettingPickUp:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    for i = 0, MAX_AUTO do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbAutoPick"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickedAutoPick(self, i, bActivate)
        end)
    end
    for i = 0, MAX_CHANGE_SAIL do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbAutoChangeSail"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickedAutoChangeSail(self, i, bActivate)
        end)
    end
    for i = 0, MAX_AUTO do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbListAutoPick"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickedListAutoPick(self, i, bActivate)
        end)
    end
end

function UPSettingPickUp:Activate()
    self.pWidgetRef.scrollPanel:ScrollToStart()
end

function UPSettingPickUp:SetValue(Prefab, nId, nValue)
    self.tbInstance:SetValue(nId, nValue)
    SettingSystemNew:SaveLocalData()
    Prefab:OnRefresh(self.tbInstance:GetValue(nId))
end

return UPSettingPickUp