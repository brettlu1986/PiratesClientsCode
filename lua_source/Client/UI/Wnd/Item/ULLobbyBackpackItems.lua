-----------------------------------------------------
--File Name    : ULLobbyBackpackItems.lua
--Author       : zhiyuan
--Create Time  : 2019-02-22
--Description  : 大厅背包UI的道具列表逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyBackpackItems = luaclass("ULLobbyBackpackItems", UILogicBase)

local BackpackDataTable = require("BackpackDataTable")
local ItemSystem = require("ItemSystem")
local ItemDataTable = require("ItemDataTable")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIDef = require("UIDef")
local LuaDelegateClass = require("LuaDelegate")
local UILobbyBackpackTips = require("UILobbyBackpackTips")
local ClientEventDef = require("ClientEventDef")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local LobbyItemUseHelper = require("LobbyItemUseHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local UIManager = require("UIManager")
local ItemCategoryDef = require("ItemCategoryDef")
local DirectUseItemCategoryDef = require("DirectUseItemCategoryDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")

local DEFAULT_CHOOSE_ITEM_INDEX = 1

local HAS_ITEM_SWITCHER_INDEX = 0
local NOTHING_SWITCHER_INDEX = 1
local NON_LIST_WIDTH = 860 -- 除去列表之外的所有元素宽度总和，用于推算列表宽度
local LIST_ITEM_WITH_PADDING_WIDTH = 148

ULLobbyBackpackItems.ListHelper = nil

ULLobbyBackpackItems.OnItemPressedDelegate = nil
ULLobbyBackpackItems.OnItemUsePressedDelegate = nil
ULLobbyBackpackItems.OnItemSellPressedDelegate = nil

ULLobbyBackpackItems.pbLobbyBackpackSub = nil
ULLobbyBackpackItems.pbLobbyBackpackTips = nil

ULLobbyBackpackItems.pbRenamePlayer = nil

ULLobbyBackpackItems.nBackpackId = -1
ULLobbyBackpackItems.nChooseItemInstanceId = -1
ULLobbyBackpackItems.tbCurrentUseItemInfo = nil
ULLobbyBackpackItems.tbSelectedItem = nil

local function fnSort(tbItemDataA, tbItemDataB)
    local ItemA = tbItemDataA.Item
    local ItemB = tbItemDataB.Item

    local nCategoryA = ItemA:GetCategory()
    local nSortValueA = ItemDataTable:GetSortValue(nCategoryA)

    local nCategoryB = ItemB:GetCategory()

    local nSortValueB = ItemDataTable:GetSortValue(nCategoryB)

    if nSortValueA ~= nSortValueB then
        return nSortValueA > nSortValueB
    end

    if nCategoryA ~= nCategoryB then
        local nSubCategoryA = ItemA:GetSubCategory()
        local nSubCategoryB = ItemB:GetSubCategory()
        return nSubCategoryA < nSubCategoryB
    end

    local nGradeA = ItemA:GetGrade()
    local nGradeB = ItemB:GetGrade()
    if nGradeA ~= nGradeB then
        return nGradeA > nGradeB
    end

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

local function GetItemsByBackpackId(self, nBackpackId)
    local tbItems = {}
    local tbBackpackTemplate = BackpackDataTable:GetTemplate(nBackpackId)
    local nTimeLimitSeconds = tbBackpackTemplate.nTimeLimitSeconds
    local now = GlobalVariableSystem:GetServerTimeUtc()
    local tbItemCategorys = tbBackpackTemplate.tbItemCategorys
    local PlayerNewItemRecordComponent = GamePlayerSelfHelper:Get().PlayerNewItemRecordComponent
    if tbItemCategorys ~= nil then
        for _, v in ipairs(tbItemCategorys) do
            local tbItemsByCategory = ItemSystem:GetItemsByCategory(v)
            for _, Item in ipairs(tbItemsByCategory) do
                local nCreateTime = Item:GetCreateSeconds()
                if nTimeLimitSeconds <= 0 or (now - nCreateTime <= nTimeLimitSeconds) then
                    local tbItemData = {}
                    tbItemData.Item = Item
                    tbItemData.OnItemPressedDelegate = self.OnItemPressedDelegate
                    tbItemData.bShowNew = PlayerNewItemRecordComponent:IsItemInBackpackMarkedNew(Item:GetInstanceId())
                    table.insert(tbItems, tbItemData)
                end
            end
        end
    end
    SortItemList(tbItems)
    return tbItems
end

local function EmptyList(self)
    self.pWidgetRef.wsContent:SetActiveWidgetIndex(NOTHING_SWITCHER_INDEX)
    self.nChooseItemInstanceId = nil
end

local function OnItemSelected(self, Item)
    self.pbLobbyBackpackSub:SetData(Item)
    self.nChooseItemInstanceId = Item:GetInstanceId()
end

local function ShowRenamePlayer(self, nLastUseTime, nRenameTimes)
    UIManager:OpenWnd(UIDef.UI_RENAME_PLAYER, {nLastUseTime = nLastUseTime, nRenameTimes = nRenameTimes, Item = self.tbSelectedItem})
    --self.pbRenamePlayer:SetData(nLastUseTime, nRenameTimes)
    --self.pbRenamePlayer:SetVisible(true)
end

local function OnUseItemSuccess(self)
    local tbUseItemInfo = self.tbCurrentUseItemInfo
    local bShowSuccessTips = false
    if tbUseItemInfo and tbUseItemInfo.nCategory == ItemCategoryDef.DIRECTLY_USABLE then
        if tbUseItemInfo.nSubCategory == DirectUseItemCategoryDef.DIAMOND_CARD or tbUseItemInfo.nSubCategory == DirectUseItemCategoryDef.SAILOR_CARD then
            self.EventHelper:FireEvent(ClientEventDef.EV_REFRESH_WELFARE_TIP_ICON, true)
        elseif tbUseItemInfo.nSubCategory == DirectUseItemCategoryDef.ROSES then
            bShowSuccessTips = false
        end
    end

    if bShowSuccessTips then
        UIUtils.ShowToast(UITextDef.LOBBY_ITEM_USE_SUCCESS)
    end

    if tbUseItemInfo then
        self.EventHelper:FireEvent(ClientEventDef.EV_USE_LOBBY_ITEM_SUCCESS_ID, tbUseItemInfo.nId)
    end
end

local function OnItemUsePressed(self, Item)
    self.tbSelectedItem = Item
    local nCategory = Item:GetCategory()
    local DirectSubCategory = Item:GetSubCategory()

    self.tbCurrentUseItemInfo = {}
    self.tbCurrentUseItemInfo.nCategory = nCategory
    self.tbCurrentUseItemInfo.nSubCategory = DirectSubCategory
    self.tbCurrentUseItemInfo.nId = Item:GetTemplateId()

    if nCategory == ItemCategoryDef.DIRECTLY_USABLE then
       if DirectSubCategory == DirectUseItemCategoryDef.RENAME_CARD then
            --self.pbRenamePlayer:SetItem(Item)
            ItemSystem:RequestGetRenameTimes()
       elseif DirectSubCategory == DirectUseItemCategoryDef.SPEAKER then
            UIManager:OpenWnd(UIDef.UI_SPEAKER_CONTENT, { tbItem = Item })
       elseif DirectSubCategory == DirectUseItemCategoryDef.ROSES then
            UIManager:OpenWnd(UIDef.UI_ROSE_SELECT_FRIEND, { tbItem = Item })
       else
            LobbyItemUseHelper.UseItem(self.pbLobbyBackpackTips, Item)
       end
    else
        LobbyItemUseHelper.UseItem(self.pbLobbyBackpackTips, Item)
    end
end

local function OnItemSellPressed(self, Item)
    --self.pbLobbyBackpackTips:SetData(UILobbyBackpackTips.Type.SELL, Item)
    UIManager:OpenWnd(UIDef.UI_LOBBY_BACKPACK_TIPS, {nType = UILobbyBackpackTips.Type.SELL, Item = Item})
end

local function OnItemChanged(self)
    self:RefreshItems(self.nBackpackId)
end

local function RefreshItems(self, tbItems, nChooseItemIndex)
    self.pWidgetRef.wsContent:SetActiveWidgetIndex(HAS_ITEM_SWITCHER_INDEX)
    self.ListHelper:SetData(tbItems)
    self.ListHelper:SetSelectedIndex(nChooseItemIndex)
    local Item = tbItems[nChooseItemIndex].Item
    OnItemSelected(self, Item)
    self.nChooseItemInstanceId = Item:GetInstanceId()
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

local function AdjustCellInLineCountByListWidth(self)
    local nViewPortScale = WidgetLayoutLibrary.GetViewportScale(GWorld)
    local pViewportSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
    local pRealViewPortSize = KismetMathLibrary.Divide_Vector2DFloat(pViewportSize, nViewPortScale)
    local nViewportWidth = pRealViewPortSize.X
    local nListWidth = nViewportWidth - NON_LIST_WIDTH
    local nCellInLineCount = math.floor(nListWidth / LIST_ITEM_WITH_PADDING_WIDTH)
    self.ListHelper:SetCellInLineCount(nCellInLineCount)
end

function ULLobbyBackpackItems:RefreshItems(nBackpackId)
    local nChooseItemIndex = DEFAULT_CHOOSE_ITEM_INDEX
    local nOldBackpackId = self.nBackpackId
    self.nBackpackId = nBackpackId
    local tbItems = GetItemsByBackpackId(self, nBackpackId)
    if #tbItems == 0 then
        EmptyList(self)
    else
        if nOldBackpackId == self.nBackpackId then
            nChooseItemIndex = GetItemIndex(tbItems, self.nChooseItemInstanceId)
        end
        RefreshItems(self, tbItems, nChooseItemIndex)
    end
end

function ULLobbyBackpackItems:OnLoad()
    self.OnItemPressedDelegate = LuaDelegateClass()
    self.OnItemUsePressedDelegate = LuaDelegateClass()
    self.OnItemSellPressedDelegate = LuaDelegateClass()

    local pWidgetRef =self.pWidgetRef
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.kmlistItems, {}, UIDef.UP_LOBBY_BACKPACK_ITEM)
    AdjustCellInLineCountByListWidth(self)

    local PrefabHelper = self.PrefabHelper
    self.pbLobbyBackpackSub = PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyBackpackSub)
    self.pbLobbyBackpackSub:SetOnItemUsePressedDelegate(self.OnItemUsePressedDelegate)
    self.pbLobbyBackpackSub:SetOnItemSellPressedDelegate(self.OnItemSellPressedDelegate)

    -- self.pbLobbyBackpackTips = PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyBackpackTips)
    -- self.pbLobbyBackpackTips:Collapsed()

    -- self.pbRenamePlayer = PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyRenamePlayer)
    -- self.pbRenamePlayer:SetVisible(false)
end

function ULLobbyBackpackItems:OnUnload()
    self.ListHelper:Uninit()
end

function ULLobbyBackpackItems:OnBindEvent(EventHelper)
    EventHelper:RegisterLuaDelegate(self.OnItemPressedDelegate, OnItemSelected, self)
    EventHelper:RegisterLuaDelegate(self.OnItemUsePressedDelegate, OnItemUsePressed, self)
    EventHelper:RegisterLuaDelegate(self.OnItemSellPressedDelegate, OnItemSellPressed, self)

    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_REMOVE_LOBBY_ITEM, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT, self, OnItemChanged)

    EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_RENAME_PLAYER, self, ShowRenamePlayer)
    EventHelper:RegisterEvent(ClientEventDef.EV_USE_LOBBY_ITEM_SUCCESS, self, OnUseItemSuccess)
end


return ULLobbyBackpackItems