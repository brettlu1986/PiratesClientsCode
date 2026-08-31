-----------------------------------------------------
--File Name    : ULHomePackItems.lua
--Author       : zhiyuan
--Create Time  : 2019-05-06
--Description  : 家园仓库的道具列表ui逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULHomePackItems = luaclass("ULHomePackItems", UILogicBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIDef = require("UIDef")
local LuaDelegateClass = require("LuaDelegate")
local UPLobbyBackpackTips = require("UPLobbyBackpackTips")
local HomelandSystem = require("HomelandSystem")

local DEFAULT_CHOOSE_ITEM_INDEX = 1

local HAS_ITEM_SWITCHER_INDEX = 0
local NOTHING_SWITCHER_INDEX = 2

ULHomePackItems.ListHelper = nil

ULHomePackItems.OnItemPressedDelegate = nil
ULHomePackItems.OnItemSellPressedDelegate = nil

ULHomePackItems.pbHomepackSub = nil
ULHomePackItems.pbLobbyBackpackTips = nil

ULHomePackItems.nChooseItemInstanceId = -1

local function fnSort(tbItemDataA, tbItemDataB)
    local ItemA = tbItemDataA.Item
    local ItemB = tbItemDataB.Item

    local nTemplateIdA = ItemA:GetTemplateId()
    local nTemplateIdB = ItemB:GetTemplateId()
    if nTemplateIdA ~= nTemplateIdB then
        return nTemplateIdA < nTemplateIdB
    end

    local nCreateTimeA = ItemA:GetCreateSeconds()
    local nCreateTimeB = ItemB:GetCreateSeconds()
    return nCreateTimeA < nCreateTimeB
end

local function SortItemList(tbItems)
    table.sort(tbItems, fnSort)
end

local function GetHomePackItems(self)
    local tbHomelandItems = {}
    local HomelandItemSystem = HomelandSystem:GetSubSystem("HomelandItemSystem")
    local tbAvailableItems = HomelandItemSystem:GetAllAvailableItems()
    for _, tbHomelandItemData in ipairs(tbAvailableItems) do
        local tbItemData = {}
        tbItemData.Item = tbHomelandItemData.Item
        tbItemData.nAvailableCount = tbHomelandItemData.nAvailableCount
        tbItemData.OnItemPressedDelegate = self.OnItemPressedDelegate
        table.insert(tbHomelandItems, tbItemData)
    end
    SortItemList(tbHomelandItems)
    return tbHomelandItems
end

local function EmptyList(self)
    self.pWidgetRef.wsContent:SetActiveWidgetIndex(NOTHING_SWITCHER_INDEX)
    self.nChooseItemInstanceId = nil
end

local function OnItemSelected(self, Item, nAvailableCount)
    self.pbHomepackSub:SetData(Item, nAvailableCount)
    self.nChooseItemInstanceId = Item:GetInstanceId()
end

local function OnItemSellPressed(self, Item, nAvailableCount)
    self.pbLobbyBackpackTips:SetData(UPLobbyBackpackTips.Type.SELL, Item, nAvailableCount)
end

local function GetItemIndex(tbItems, nItemInstanceId)
    local nItemIndex = DEFAULT_CHOOSE_ITEM_INDEX
    for i, v in ipairs(tbItems) do
        local Item = v.Item
        if Item:GetInstanceId() == nItemInstanceId then
            nItemIndex = i
            break
        end
    end
    return nItemIndex
end

local function RefreshItems(self, tbItems, nChooseItemIndex)
    self.pWidgetRef.wsContent:SetActiveWidgetIndex(HAS_ITEM_SWITCHER_INDEX)
    self.ListHelper:SetData(tbItems)
    self.ListHelper:SetSelectedIndex(nChooseItemIndex)
    local tbChooseItemData = tbItems[nChooseItemIndex]
    local Item = tbChooseItemData.Item
    local nAvailableCount = tbChooseItemData.nAvailableCount
    OnItemSelected(self, Item, nAvailableCount)
    self.nChooseItemInstanceId = Item:GetInstanceId()
end

function ULHomePackItems:OnItemChanged()
    self:RefreshItems()
end

function ULHomePackItems:RefreshItems()
    local nChooseItemIndex = DEFAULT_CHOOSE_ITEM_INDEX
    local tbItems = GetHomePackItems(self)
    if #tbItems == 0 then
        EmptyList(self)
    else
        if self.nChooseItemInstanceId ~= nil then
            nChooseItemIndex = GetItemIndex(tbItems, self.nChooseItemInstanceId)
        end
        RefreshItems(self, tbItems, nChooseItemIndex)
    end
end

function ULHomePackItems:OnLoad()
    self.OnItemPressedDelegate = LuaDelegateClass()
    self.OnItemSellPressedDelegate = LuaDelegateClass()

    local pWidgetRef =self.pWidgetRef
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.kmlistItems, {}, UIDef.UP_LOBBY_BACKPACK_ITEM)

    local PrefabHelper = self.PrefabHelper
    self.pbHomepackSub = PrefabHelper:BindPrefab(self.pWidgetRef.pbHomePackSub)
    self.pbHomepackSub:SetOnItemSellPressedDelegate(self.OnItemSellPressedDelegate)

    self.pbLobbyBackpackTips = PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyBackpackTips)
    self.pbLobbyBackpackTips:Collapsed()
end

function ULHomePackItems:OnUnload()
    self.ListHelper:Uninit()
end

function ULHomePackItems:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.OnItemPressedDelegate, OnItemSelected, self)
    EventHelper:RegisterLuaDelegate(self.OnItemSellPressedDelegate, OnItemSellPressed, self)
end

return ULHomePackItems