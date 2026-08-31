-----------------------------------------------------
--File Name    : ULShipThrownItemPanel.lua
--Author       : Song Fuhao
--Create Time  : 2020-02-20
--Description  : 舰船投掷物Panel逻辑类
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULShipThrownItemPanel = luaclass("ULShipThrownItemPanel", UILogicBase)

local BaseUtil                      = require("BaseUtil")
local ClientEventDef                = require("ClientEventDef")
local CommonEventDef                = require("CommonEventDef")
local BattleItemDataTable           = require("BattleItemDataTable")
local BattleItemCategoryDef         = require("BattleItemCategoryDef")
local BattleItemSystemClient        = require("BattleItemSystemClient")
local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local ShipWeaponSlotDef             = require("ShipWeaponSlotDef")
local ShipWeaponTemplateDef         = require("ShipWeaponTemplateDef")
local ShipFiringOperationDef        = require("ShipFiringOperationDef")
local BattleShipWeaponSystem        = dynamic_require("BattleShipWeaponSystem")

local ITEM_CATEGORY                 = BattleItemCategoryDef.SHIP_THROWN_ITEM
local THROWN_ITEM_NAME              = "pbThrownItem0"
local MAX_ITEM_COUNT                = 8
local ARROW_ANGLE_EXPANDED          = 0
local ARROW_ANGLE_COLLAPSED         = 180
local DEFUALT_ITEM_INDEX            = 1

ULShipThrownItemPanel.bListExpanded     = false
ULShipThrownItemPanel.tbItemPrefabList  = nil
ULShipThrownItemPanel.tbItemInfoList    = nil
ULShipThrownItemPanel.pbProgressBarBoom = nil

local function SortItemInfoList(self)
    local EquippedThrownItem = BattleShipWeaponSystem:GetEquippedWeaponItem_C(ShipWeaponSlotDef.THROW)
    local nEquippedThrownItemTemplateId = EquippedThrownItem and EquippedThrownItem:GetTemplateId()
    local funcSort = function(tbItemInfo1, tbItemInfo2)
        if tbItemInfo1.nTemplateId == nEquippedThrownItemTemplateId then
            return true
        end
        if tbItemInfo2.nTemplateId == nEquippedThrownItemTemplateId then
            return false
        end
        if tbItemInfo1.nSortWeight ~= tbItemInfo2.nSortWeight then
            return tbItemInfo1.nSortWeight < tbItemInfo2.nSortWeight
        end
        return tbItemInfo1.nTemplateId < tbItemInfo2.nTemplateId
    end
    table.sort(self.tbItemInfoList, funcSort)
end

local function RefreshActiveState(self)
    local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem_C()
    local nActiveWeaponItemTemplateId = ActiveWeaponItem and ActiveWeaponItem:GetTemplateId()
    local tbItemInfo = self.tbItemInfoList[DEFUALT_ITEM_INDEX]
    local ItemPrefab = self.tbItemPrefabList[DEFUALT_ITEM_INDEX]
    local bThrownItemActived = tbItemInfo and (tbItemInfo.nTemplateId == nActiveWeaponItemTemplateId)
    ItemPrefab:SetSelected(bThrownItemActived)
end

local function RefreshItemPrefabList(self)
    SortItemInfoList(self)
    RefreshActiveState(self)
    local nCurrentItemMax = #self.tbItemInfoList
    for i = 1, MAX_ITEM_COUNT do
        local pbThrownItem = self.tbItemPrefabList[i]
        if i <= nCurrentItemMax then
            pbThrownItem:SetItemInfo(self.tbItemInfoList[i])
        else
            pbThrownItem:SetItemInfo(nil)
            pbThrownItem.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

-- 获取当前List中Item数量
local function GetListItemCount(self)
    return math.min(MAX_ITEM_COUNT, BaseUtil:GetTableCount(self.tbItemInfoList))
end

-- 根据TemplateId查找对应的ItemIndex
local function IndexItemByTemplateId(self, nTemplateId)
    for i,v in ipairs(self.tbItemInfoList) do
        if v.nTemplateId == nTemplateId then
            return i
        end
    end
    return -1
end

-- 更新列表展开箭头的显隐
local function UpdateArrowVisible(self, bForceCollapsed)
    local pVisibility = ESlateVisibility.Visible
    if bForceCollapsed or (GetListItemCount(self) <= 1) then
        pVisibility = ESlateVisibility.Collapsed
    end
    self.pWidgetRef.btnThrownItemMiniArrow:SetVisibility(pVisibility)
end

-- 更新列表UI（Item新增时触发）
local function UpdateListUIByAdd(self, nItemIndex, tbItemInfo)
    RefreshItemPrefabList(self)
    if self.bListExpanded or (nItemIndex == DEFUALT_ITEM_INDEX) then
        local ItemPrefab = self.tbItemPrefabList[nItemIndex]
        ItemPrefab.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
    UpdateArrowVisible(self)
end

-- 更新列表UI（Item数量改变时触发）
local function UpdateListUIByChange(self, nItemIndex, nItemCount)
    local ItemPrefab = self.tbItemPrefabList[nItemIndex]
    ItemPrefab:SetItemCount(nItemCount)
end

-- 更新列表UI（Item移除时触发）
local function UpdateListUIByRemove(self, nItemIndex)
    local nItemCount = GetListItemCount(self)
    for i=nItemIndex, nItemCount do
        local ItemPrefab = self.tbItemPrefabList[i]
        local tbItemInfo = self.tbItemInfoList[i]
        ItemPrefab:SetItemInfo(tbItemInfo)
    end
    local nLastIndex = nItemCount + 1
    local LastItemPrefab = self.tbItemPrefabList[nLastIndex]
    LastItemPrefab.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    UpdateArrowVisible(self)
end

-- 物品数量改变统一接口
local function OnItemCountChanged(self, nCategory, nTemplateId)
    if nCategory ~= ITEM_CATEGORY then
        return
    end
    local tbItemInfoList = self.tbItemInfoList
    local nItemCount = BattleItemSystemClient:GetItemCount(nTemplateId)
    local nItemIndex = IndexItemByTemplateId(self, nTemplateId)
    if nItemCount > 0 then
        if nItemIndex > 0 then
            tbItemInfoList[nItemIndex].nItemCount = nItemCount
            UpdateListUIByChange(self, nItemIndex, nItemCount)
        else
            local tbItemInfo = {}
            tbItemInfo.nTemplateId = nTemplateId
            tbItemInfo.nItemCount = nItemCount
            local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
            tbItemInfo.nSortWeight = tbTemplate.nConsumableBarSortWeight
            table.insert(tbItemInfoList, tbItemInfo)
            UpdateListUIByAdd(self, #tbItemInfoList, tbItemInfo)
        end
    elseif nItemIndex > 0 then
        table.remove(tbItemInfoList, nItemIndex)
        UpdateListUIByRemove(self, nItemIndex)
    end
end

-- 获得物品事件处理
local function OnBattleItemAdd(self, Item)
    OnItemCountChanged(self, Item:GetCategory(), Item:GetTemplateId())
end

-- 移除物品事件处理
local function OnBattleItemRemove(self, _, nTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if not tbTemplate then
        return
    end
    OnItemCountChanged(self, tbTemplate.nCategory, nTemplateId)
end

-- 物品堆叠数量变化处理
local function OnBattleItemChangeStackCount(self, Item)
    OnItemCountChanged(self, Item:GetCategory(), Item:GetTemplateId())
end

local function OnShipWeaponEquipped(self, tbCharacter, nWeaponSlot, WeaponItem)
    if GamePlayerSelfHelper:IsPlayerSelf(tbCharacter) and (nWeaponSlot == ShipWeaponSlotDef.THROW) then
        RefreshItemPrefabList(self)
    end
end

local function OnShipWeaponUnequipped(self, tbCharacter, nWeaponSlot, WeaponItem)
    if GamePlayerSelfHelper:IsPlayerSelf(tbCharacter) and (nWeaponSlot == ShipWeaponSlotDef.THROW) then
        RefreshItemPrefabList(self)
    end
end

local function OnShipWeaponFiringOperationChanged(self, tbCharacter, WeaponItem, nFiringOperation)
    if GamePlayerSelfHelper:IsNotPlayerSelf(tbCharacter) then
        return
    end
    if WeaponItem:GetTemplateType() ~= ShipWeaponTemplateDef.CARRONADE then
        return
    end
    if nFiringOperation == ShipFiringOperationDef.START then
        self.pWidgetRef.btnCancelFire:SetVisibility(ESlateVisibility.Visible)
        self.pbProgressBarBoom:StartProgress(WeaponItem:GetTemplate().nMaxPreThrownItem)
    else
        self.pWidgetRef.btnCancelFire:SetVisibility(ESlateVisibility.Collapsed)
        self.pbProgressBarBoom:StopProgress()
    end
end

-- 设置快捷使用列表展开/收缩
local function SetListExpanded(self, bListExpanded)
    self.bListExpanded = bListExpanded
    local pVisibility = bListExpanded and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed
    local nItemCount = GetListItemCount(self)
    for i=2, nItemCount do -- 第一个Item永远显示
        self.tbItemPrefabList[i].pWidgetRef:SetVisibility(pVisibility)
    end
    self.pWidgetRef.imgConsumableMiniArrow:SetRenderTransformAngle(bListExpanded and ARROW_ANGLE_EXPANDED or ARROW_ANGLE_COLLAPSED)
end

-- 点击快捷使用列表展开/收缩箭头
local function OnClickedBtnArrow(self)
    SetListExpanded(self, not self.bListExpanded)
end

local function RequestEquipThrownItem(self, nIndex)
    local tbSelectedItemInfo = self.tbItemInfoList[nIndex]
    if tbSelectedItemInfo then
        BattleShipWeaponSystem:RequestEquipThrownItem(tbSelectedItemInfo.nTemplateId)
    else
        logerror()
    end
end

-- 切换激活状态
local function RequestToggleActiveState(self)
    local tbSelectedItemInfo = self.tbItemInfoList[DEFUALT_ITEM_INDEX]
    if tbSelectedItemInfo then
        local WeaponItem
        local ItemPrefab = self.tbItemPrefabList[DEFUALT_ITEM_INDEX]
        if not ItemPrefab:IsSelected() then
            WeaponItem = BattleShipWeaponSystem:GetEquippedWeaponItem_C(ShipWeaponSlotDef.THROW)
        end
        BattleShipWeaponSystem:RequestActivateWeaponItem(WeaponItem)
    else
        logerror()
    end
end

-- 点击快捷使用列表Item
local function OnClickedItemPrefab(self, nIndex)
    if self.bListExpanded then
        SetListExpanded(self, false)
        RequestEquipThrownItem(self, nIndex)
    elseif nIndex == DEFUALT_ITEM_INDEX then
        RequestToggleActiveState(self)
    end
end

local function OnShipWeaponFiringCDBegan(self, WeaponItem, nDuration)
    if WeaponItem ~= BattleShipWeaponSystem:GetEquippedWeaponItem_C(ShipWeaponSlotDef.THROW) then
        return
    end
    local ItemPrefab = self.tbItemPrefabList[DEFUALT_ITEM_INDEX]
    ItemPrefab:StartCD(nDuration)
end

-- 初始化当前分类的物品列表信息
local function InitItemInfoList(self)
    self.tbItemInfoList = {}
    local tbItemTemplates = BattleItemDataTable:GetTemplatesByCategory(ITEM_CATEGORY)
    for _,v in pairs(tbItemTemplates) do
        OnItemCountChanged(self, ITEM_CATEGORY, v.nId)
    end
    RefreshItemPrefabList(self)
    UpdateArrowVisible(self)
end

function ULShipThrownItemPanel:OnLoad()
    self.tbItemPrefabList = {}
    for i=1, MAX_ITEM_COUNT do
        local ItemPrefab = self.PrefabHelper:BindPrefab(self.pWidgetRef[THROWN_ITEM_NAME..i])
        ItemPrefab.OnClickedButtonDelegate:Bind(function() OnClickedItemPrefab(self, i) end)
        self.tbItemPrefabList[i] = ItemPrefab
    end

    self.pbProgressBarBoom = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbProgressBarBoom)
end

function ULShipThrownItemPanel:Activate()
    InitItemInfoList(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT                          , self, OnBattleItemAdd)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT                       , self, OnBattleItemRemove)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT            , self, OnBattleItemChangeStackCount)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_EQUIPPED_CLIENT                  , self, OnShipWeaponEquipped)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_UNEQUIPPED_CLIENT                , self, OnShipWeaponUnequipped)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRING_OPERATION_CHANGED_CLIENT  , self, OnShipWeaponFiringOperationChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRING_CD_BEGAN_CLIENT           , self, OnShipWeaponFiringCDBegan)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_ACTIVE_WEAPON_ITEM_CHANGED              , self, RefreshActiveState)

    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnThrownItemMiniArrow.OnClicked            , self, OnClickedBtnArrow)
end

function ULShipThrownItemPanel:Deactivate()
    self.EventHelper:UnregisterAll()
end

return ULShipThrownItemPanel