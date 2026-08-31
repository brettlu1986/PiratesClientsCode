-----------------------------------------------------
--File Name    : ULFFAItemPanel.lua
--Author       : Song Fuhao
--Create Time  : 2018-09-27
--Description  : FFA模式物品面板（消耗品快捷使用栏、背包按钮）
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULFFAItemPanel = luaclass("ULFFAItemPanel", UILogicBase)

local UIDef = require("UIDef")
local BaseUtil = require("BaseUtil")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local ControlModeDef = require("ControlModeDef")
-- local CommonEventDef = require("CommonEventDef")
local BattleItemRoomDef = require("BattleItemRoomDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIResourceDef = require("UIResourceDef")
-- local HumanMovementStateType = require("HumanMovementStateType")
-- local GameObjectTypeDef = require("GameObjectTypeDef")
local ClientEventDef = require("ClientEventDef")
local ProgressBarHelper = require("ProgressBarHelper")
local DelayTimer = require("DelayTimer")
local SettingIni = require("SettingIni")
local SettingSystemNew = require("SettingSystemNew")
local SettingKeyDef = require("SettingKeyDef")

local CONSUMABLE_MINI_ITEM_NAME         = "pbShortcutMenuItem0"
local MAX_ITEM_COUNT                    = 8
local ARROW_ANGLE_EXPANDED              = 0
local ARROW_ANGLE_COLLAPSED             = 180
local DEFUALT_ITEM_INDEX                = 1
local CONSUMABLE_SUB_CATEGORY_MEDICINE  = 1
local CONSUMABLE_SUB_CATEGORY_DRINK     = 2
local RECOMMEND_MEDICINE_ON_VALUE       = 1
local MEDICINE_PRIORITY_1 = {1, 2, 3}  --药瓶优先级：小-中-大
local MEDICINE_PRIORITY_2 = {3, 1, 2}  --药瓶优先级：中-大-小

ULFFAItemPanel.nCurrentItemCategory          = BattleItemCategoryDef.HUMAN_CONSUMABLE
ULFFAItemPanel.nCurrentItemRoomType          = BattleItemRoomDef.HUMAN_INVENTORY
ULFFAItemPanel.bListExpanded                 = false
ULFFAItemPanel.tbItemPrefabList              = nil
ULFFAItemPanel.tbItemInfoList                = nil
ULFFAItemPanel.nControlMode                  = nil
ULFFAItemPanel.nSelectedItemTemplateId       = nil
ULFFAItemPanel.nLastHpPercent                = nil
ULFFAItemPanel.tbSelectItemTimerHandle       = nil
ULFFAItemPanel.tbHpChangedHandle             = nil

local function SortItemInfoList(self)
    local funcSort = function(tbItemInfo1, tbItemInfo2)
        local nSelectedItemTemplateId = self.nSelectedItemTemplateId
        if nSelectedItemTemplateId ~= nil then
            if tbItemInfo1.nTemplateId == nSelectedItemTemplateId then
                return true
            end
            if tbItemInfo2.nTemplateId == nSelectedItemTemplateId then
                return false
            end
        end
        if tbItemInfo1.nSortWeight ~= tbItemInfo2.nSortWeight then
            return tbItemInfo1.nSortWeight < tbItemInfo2.nSortWeight
        end
        return tbItemInfo1.nTemplateId < tbItemInfo2.nTemplateId
    end
    table.sort(self.tbItemInfoList, funcSort)
end

local function RefreshItemPrefabList(self)
    SortItemInfoList(self)
    local nCurrentItemMax = #self.tbItemInfoList
    for i = 1, MAX_ITEM_COUNT do
        if i <= nCurrentItemMax then
            self.tbItemPrefabList[i]:SetItemInfo(self.tbItemInfoList[i])
        else
            self.tbItemPrefabList[i]:SetItemInfo(nil)
        end
    end
end

local function TryRecommendConsumableItem(self, nSubCategory, tbGradePriority)
    local tbItemList = BattleItemSystemClient:GetUnequippedItemsByCategory(BattleItemCategoryDef.HUMAN_CONSUMABLE)
    local tbSubItemList = {}
    for k, tbItem in pairs(tbItemList) do
        local tbTemplate = tbItem:GetTemplate()
        if tbTemplate.nSubCategory == nSubCategory then
            table.insert(tbSubItemList, tbTemplate)
        end
    end
    local nPriority = 999
    local nSelectedItemTemplateId = nil
    for k, v in pairs(tbSubItemList) do
        local nCurrentPriority = tbGradePriority[v.nColorGrade]
        if nCurrentPriority then
            if tbGradePriority[v.nColorGrade] < nPriority then
                nSelectedItemTemplateId = v.nId
                nPriority = tbGradePriority[v.nColorGrade]
            end
        else
            logerror("TryRecommendConsumableItem, nCurrentPriority is nil, item templateid, nColorGrade =", v.nId, v.nColorGrade)
        end
        
    end
    if nSelectedItemTemplateId ~= nil and nSelectedItemTemplateId ~= self.nSelectedItemTemplateId then
        self.nSelectedItemTemplateId = nSelectedItemTemplateId
        RefreshItemPrefabList(self)
    end
end

local function OnHpChanged(self, nHp, nMaxHp, nHpPercent)
    local nSettingValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.MEDICINE_RECOMMEND)
    local bAutoRecommend = nSettingValue == RECOMMEND_MEDICINE_ON_VALUE and true or false
    --logdebug("OnHpChanged,bAutoRecommend,self.tbSelectItemTimerHandle=",bAutoRecommend,self.tbSelectItemTimerHandle)
    if bAutoRecommend and not self.tbSelectItemTimerHandle then
        local PropertyComponent = GamePlayerSelfHelper:Get():GetCurrentPropertyComponent()
        nHp = nHp or PropertyComponent:GetHp()
        nMaxHp = nMaxHp or PropertyComponent:GetMaxHp()
        nHpPercent = nHpPercent or PropertyComponent:GetHpPercent()
        local nEp = PropertyComponent:GetEp()
        --logdebug("nHpPercent,SettingIni.tbMedicineRecommend.nMedicineMin=",nHpPercent,SettingIni.tbMedicineRecommend.nMedicineMin,nEp,SettingIni.tbMedicineRecommend.nDrinkMin)
        if nHpPercent < SettingIni.tbMedicineRecommend.nMedicineMin --[[and (self.nLastHpPercent == nil or self.nLastHpPercent >= 0.5)--]]then
            TryRecommendConsumableItem(self, CONSUMABLE_SUB_CATEGORY_MEDICINE, MEDICINE_PRIORITY_2)
        elseif nHpPercent >= SettingIni.tbMedicineRecommend.nMedicineMin and nHpPercent < SettingIni.tbMedicineRecommend.nMedicineMax then
            TryRecommendConsumableItem(self, CONSUMABLE_SUB_CATEGORY_MEDICINE, MEDICINE_PRIORITY_1)
        elseif nHpPercent >= SettingIni.tbMedicineRecommend.nMedicineMax --[[and (self.nLastHpPercent == nil or self.nLastHpPercent <= 0.75)--]] and nEp <= SettingIni.tbMedicineRecommend.nDrinkMin then
            TryRecommendConsumableItem(self, CONSUMABLE_SUB_CATEGORY_DRINK, MEDICINE_PRIORITY_1)
        end
    end
    self.nLastHpPercent = nHpPercent
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
    self.pWidgetRef.btnConsumableMiniArrow:SetVisibility(pVisibility)
end

-- 更新列表UI（Item新增时触发）
local function UpdateListUIByAdd(self, nItemIndex, tbItemInfo)
    RefreshItemPrefabList(self)
    if self.bListExpanded or (nItemIndex == DEFUALT_ITEM_INDEX) then
        local ItemPrefab = self.tbItemPrefabList[nItemIndex]
        ItemPrefab.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
    UpdateArrowVisible(self)
    OnHpChanged(self)
end

-- 更新列表UI（Item数量改变时触发）
local function UpdateListUIByChange(self, nItemIndex, nItemCount)
    local ItemPrefab = self.tbItemPrefabList[nItemIndex]
    ItemPrefab:SetItemCount(nItemCount)
end

-- 更新列表UI（Item移除时触发）
local function UpdateListUIByRemove(self, nItemIndex)
    if nItemIndex == DEFUALT_ITEM_INDEX then
        self.nSelectedItemTemplateId = nil
    end
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
    OnHpChanged(self)
end

-- 更新列表UI（Item被选中时触发）
local function UpdateListUIBySelect(self, nItemIndex)
    local tbSelectedItemInfo = self.tbItemInfoList[nItemIndex]
    self.nSelectedItemTemplateId = tbSelectedItemInfo.nTemplateId
    RefreshItemPrefabList(self)
    if self.tbSelectItemTimerHandle then
        DelayTimer:ClearTimer(self.tbSelectItemTimerHandle)
        self.tbSelectItemTimerHandle = nil
    end
    self.tbSelectItemTimerHandle = DelayTimer:DelayRun(function()
        self.tbSelectItemTimerHandle = nil
        OnHpChanged(self)
    end, SettingIni.tbMedicineRecommend.nRecommendDelayTime)
end

-- 请求使用当前选中消耗品
local function RequestUseSelectedItem(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not ProgressBarHelper.CanStartHumanProgressBar(PlayerSelf, true) then
        return
    end
    -- self.EventHelper:FireEvent(CommonEventDef.EV_INTERRUPT_CONTINUOUS_RUN)
    local nSelectedItemInfo = self.tbItemInfoList[DEFUALT_ITEM_INDEX]
    if nSelectedItemInfo then
        local nSelectedTemplateId = nSelectedItemInfo.nTemplateId
        local nSelectedInstanceId = BattleItemSystemClient:GetUnequippedLeastStackCountInstanceId(nSelectedTemplateId)
        if nSelectedInstanceId then
            BattleItemSystemClient:RequestConsumeItem(nSelectedInstanceId)
        end
    end
end

-- 物品数量改变统一接口
local function OnItemCountChanged(self, nCategory, nTemplateId)
    if nCategory ~= self.nCurrentItemCategory then
        return
    end
    local tbItemInfoList = self.tbItemInfoList
    local nItemCount = BattleItemSystemClient:GetUnequippedItemCount(nTemplateId)
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

-- 更新背包占用百分比
local function UpdateInventoryPercent(self)
    local nItemRoomType = self.nCurrentItemRoomType
    local nMaxSlotCount = BattleItemSystemClient:GetPackageMax(nItemRoomType)
    local nUsedSlotCount = BattleItemSystemClient:GetPackageUsed(nItemRoomType)
    local nPercent = 1
    if nMaxSlotCount > 0 then
        nPercent = nUsedSlotCount / nMaxSlotCount
    end
    self.pWidgetRef.cpgbPack:SetPercent(nPercent)
end

-- return {normal, hovered, pressed, disabled}，可能为空
local function GetPackIcon(self, nControlMode)
    if nControlMode == ControlModeDef.HUMAN then
        local nPlayerInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
        local tbBags = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_BACKPACK, nPlayerInstanceId)
        local tbBag = tbBags and tbBags[1]
        local tbTemplate = tbBag and tbBag:GetTemplate()
        local nGrade = tbTemplate and tbTemplate.nGrade
        if nGrade then
            return UIResourceDef.FFA_HUMAN_PACK_ICON[nGrade]
        end
    end
    return UIResourceDef.FFA_COMMON_PACK_ICONS[nControlMode]
end

-- 更新背包按钮图标
local function UpdatePackIcon(self, nControlMode)
    -- 背包图标显示非人即船
    nControlMode = (nControlMode == ControlModeDef.HUMAN) and ControlModeDef.HUMAN or ControlModeDef.SHIP
    local tbPackIcons = GetPackIcon(self, nControlMode)
    if tbPackIcons then
        local pNormal = tbPackIcons.szNormal and tbPackIcons.szNormal:load(true)
        local pPressed = tbPackIcons.szPressed and tbPackIcons.szPressed:load(true)
        local pDisabled = tbPackIcons.szDisabled and tbPackIcons.szDisabled:load(true)
        local pHovered = pPressed

        log("[ULFFAItemPanel] [UpdatePackIcon]", t2s(tbPackIcons))
        log("[ULFFAItemPanel] [UpdatePackIcon]", tbPackIcons.szNormal, pNormal)
        log("[ULFFAItemPanel] [UpdatePackIcon]", tbPackIcons.szPressed, pPressed)
        log("[ULFFAItemPanel] [UpdatePackIcon]", tbPackIcons.szDisabled, pDisabled)

        local pBtnPack = self.pWidgetRef.btnPack
        UISetUtils.SetButtonNormalBrushRes(pBtnPack, pNormal)
        UISetUtils.SetButtonPressedBrushRes(pBtnPack, pHovered)
        UISetUtils.SetButtonDisabledBrushRes(pBtnPack, pDisabled)
        UISetUtils.SetButtonHoveredBrushRes(pBtnPack, pHovered)
    end
end

-- 获得物品事件处理
function ULFFAItemPanel:OnBattleItemAdd(Item)
    OnItemCountChanged(self, Item:GetCategory(), Item:GetTemplateId())
    UpdateInventoryPercent(self)
    --UpdatePackIcon(self, self.nControlMode)
end

-- 移除物品事件处理
function ULFFAItemPanel:OnBattleItemRemove(nTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    OnItemCountChanged(self, tbTemplate.nCategory, nTemplateId)
    UpdateInventoryPercent(self)
    --UpdatePackIcon(self, self.nControlMode)
end

-- 物品堆叠数量变化处理
function ULFFAItemPanel:OnBattleItemChangeStackCount(Item)
    OnItemCountChanged(self, Item:GetCategory(), Item:GetTemplateId())
end

-- 物品位置变化处理（如装弹之后没有移除事件，只有位置改变事件）
function ULFFAItemPanel:OnBattleItemChangeStorageLocation()
    UpdateInventoryPercent(self)
end

-- 初始化当前分类的物品列表信息
local function UpdateItemInfoList(self)
    self.tbItemInfoList = {}
    local nCategory = self.nCurrentItemCategory
    local tbItemTemplates = BattleItemDataTable:GetTemplatesByCategory(nCategory)
    for k,v in pairs(tbItemTemplates) do
        OnItemCountChanged(self, nCategory, v.nId)
    end
end

-- 设置快捷使用列表展开/收缩
local function SetListExpanded(self, bListExpanded)
    self.bListExpanded = bListExpanded
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_ITEMPANEL_LIST_EXPANDED, bListExpanded)
    local pVisibility = bListExpanded and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed
    local nItemCount = GetListItemCount(self)
    for i=2, nItemCount do -- 第一个Item永远显示
        self.tbItemPrefabList[i].pWidgetRef:SetVisibility(pVisibility)
    end
    self.pWidgetRef.imgConsumableMiniArrow:SetRenderTransformAngle(bListExpanded and ARROW_ANGLE_EXPANDED or ARROW_ANGLE_COLLAPSED)
end

local function ResetItemList(self)
    self.tbItemPrefabList[DEFUALT_ITEM_INDEX]:SetItemInfo(nil)
    SetListExpanded(self, false)
    UpdateArrowVisible(self, true)
end

-- 点击快捷使用列表展开/收缩箭头
local function OnClickedBtnArrow(self)
    SetListExpanded(self, not self.bListExpanded)
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_ITEMPANEL_LIST_ARROW_BTN_CLICKED, self.bListExpanded)
end

-- 点击快捷使用列表Item
local function OnClickedItemPrefab(self, nIndex)
    if self.bListExpanded then
        UpdateListUIBySelect(self, nIndex)
        self.EventHelper:FireEvent(ClientEventDef.EV_UI_ON_ITEM_PANLE_CLICKED, nIndex)
        SetListExpanded(self, false)
    elseif nIndex == DEFUALT_ITEM_INDEX then
        RequestUseSelectedItem(self)
    end
end

-- 点击背包按钮
local function OnClickedBtnPack(self)
    local pbCurrrentVirtualStick = self.Owner.pbCurrrentVirtualStick
    -- 摇杆激活的时候不能打开背包
    if pbCurrrentVirtualStick and pbCurrrentVirtualStick.IsVirtualJoystickTouched then
        if pbCurrrentVirtualStick:IsVirtualJoystickTouched() then
            return
        end
    end
    UIManager:ToggleWnd(UIDef.UI_FFABACKPACK)
    if UIManager:IsWndVisible(UIDef.UI_BUILD_ITEM) then
        UIManager:CloseWnd(UIDef.UI_BUILD_ITEM)
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
end

-- local function OnHumanMovementStateChange(self, Player, nOldState, nNewState)
--     if not Player or Player.ObjectType ~= GameObjectTypeDef.PlayerSelf then
--         return
--     end
--     local pWidgetRef = self.pWidgetRef
--     if nNewState == HumanMovementStateType.Swimming then
--         pWidgetRef.gridConsumablePanel:SetVisibility(ESlateVisibility.Collapsed)
--     elseif nOldState == HumanMovementStateType.Swimming and nNewState ~= HumanMovementStateType.Swimming then
--         pWidgetRef.gridConsumablePanel:SetVisibility(ESlateVisibility.Visible)
--     end

-- end

function ULFFAItemPanel:OnLoad()
    self.tbItemPrefabList = {}
    self.tbItemInfoList = {}
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    for i=1, MAX_ITEM_COUNT do
        local ItemPrefab = PrefabHelper:BindPrefab(pWidgetRef[CONSUMABLE_MINI_ITEM_NAME..i])
        ItemPrefab.OnClickedButtonDelegate:Bind(function() OnClickedItemPrefab(self, i) end)
        self.tbItemPrefabList[i] = ItemPrefab
    end
end

function ULFFAItemPanel:OnDestroy()
    if self.tbSelectItemTimerHandle then
        DelayTimer:ClearTimer(self.tbSelectItemTimerHandle)
        self.tbSelectItemTimerHandle = nil
    end
end

local function OnFFAControlModeActivate(self, nControlMode)
    if nControlMode == ControlModeDef.SHIP then
        self.pWidgetRef.gridConsumablePanel:SetVisibility(ESlateVisibility.Visible)
    end
end

local function OnRecommendMedicineChanged(self)
    OnHpChanged(self)
end

local function BindDelegate(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local PropertyComponent = tbPlayer:GetCurrentPropertyComponent()
    self.tbHpChangedHandle = self.EventHelper:RegisterLuaDelegate(PropertyComponent.OnHpChanged, OnHpChanged, self)
end

local function UnBindDelegate(self)
    if self.tbHpChangedHandle then
        self.EventHelper:UnregisterLuaDelegate(self.tbHpChangedHandle, OnHpChanged, self)
        self.tbHpChangedHandle = nil
    end
end

function ULFFAItemPanel:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPack.OnClicked               , self, OnClickedBtnPack)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnConsumableMiniArrow.OnClicked, self, OnClickedBtnArrow)
    -- EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnHumanMovementStateChange)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, OnFFAControlModeActivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_RECOMMEND_MEDICINE_CHANGED, self, OnRecommendMedicineChanged)
end

function ULFFAItemPanel:OnUnbindEvent(EventHelper)
    self.tbHpChangedHandle = nil
end

-- 当前人/船控制模式变化
function ULFFAItemPanel:OnControlModeChanged(nControlMode)
    UnBindDelegate(self)
    self.nControlMode = nControlMode
    self.nLastHpPercent = nil
    self.nCurrentItemCategory = BattleItemCategoryDef.HUMAN_CONSUMABLE
    if nControlMode == ControlModeDef.HUMAN then
        self.nCurrentItemRoomType = BattleItemRoomDef.HUMAN_INVENTORY
    elseif nControlMode == ControlModeDef.SHIP then
        self.nCurrentItemRoomType = BattleItemRoomDef.CABIN
    else
        return
    end
    BindDelegate(self)
    -- 如果已经有数据，需要进行重置
    if self.tbItemInfoList then
        ResetItemList(self)
    end
    UpdateItemInfoList(self)
    UpdatePackIcon(self, nControlMode)
    UpdateInventoryPercent(self)
    OnHpChanged(self)
end


return ULFFAItemPanel