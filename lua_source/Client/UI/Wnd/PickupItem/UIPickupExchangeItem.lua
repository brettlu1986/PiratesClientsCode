-----------------------------------------------------
--File Name    : UIPickupExchangeItem.lua
--Author       : zhiyuan
--Create Time  : 2019-06-04
--Description  : 材料拾取时背包已满，此时打开这个替换ui
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIPickupExchangeItem = luaclass("UIPickupExchangeItem", WndBase)
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local LuaDelegateClass = require("LuaDelegate")
local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local CommonEventDef = require("CommonEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")

UIPickupExchangeItem.nItemInstanceId = nil
UIPickupExchangeItem.nItemTemplateId = nil
UIPickupExchangeItem.nCount = nil
UIPickupExchangeItem.pbExchangeItems = nil
UIPickupExchangeItem.tbChosenItems = nil
UIPickupExchangeItem.OnCountChangedDelegate = nil

local EXCHANGE_ITEM_MAX = 3

local function CloseWnd()
    UIManager:CloseWnd(UIDef.UI_PICKUP_EXCHANGE_ITEM)
end

local function OnRemoveSceneItem(self, tbPacket)
    if tbPacket.instance_id == self.nItemInstanceId then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("PICKUP_EXCHANGE_ITEM_REMOVED"))
        log("[DebugPickupExchange] 场景内拾取物消失，关闭 UI_PickupExchangeItem")
        CloseWnd(self)
    end
end

local function GetChosenCount(self)
    local nChosenCount = 0
    for _, v in pairs(self.tbChosenItems) do
        nChosenCount = nChosenCount + v.nCount
    end
    return nChosenCount
end

local function RefreshData(self)
    local pWidgetRef = self.pWidgetRef
    if GetChosenCount(self) > 0 then
        pWidgetRef.btnCommit:SetIsEnabled(true)
    else
        pWidgetRef.btnCommit:SetIsEnabled(false)
    end
    local nChosenCount = GetChosenCount(self)

    pWidgetRef.ktxtCount:SetText(string.format("(%s/%s)", tostring(nChosenCount), tostring(self.nCount)))
end

local function OnCountChanged(self)
    RefreshData(self)
end

local function OnCommitClicked(self)
    if GetChosenCount(self) > 0 then
        local tbThrowItems = {}
        for _, v in pairs(self.tbChosenItems) do
            local tbThrowItem = {}
            tbThrowItem.instance_id = v.nItemInstanceId
            tbThrowItem.count = v.nCount
            table.insert(tbThrowItems, tbThrowItem)
        end
        BattleItemSystemClient:RequestThrowAwayAndPickupItem(tbThrowItems, self.nItemInstanceId)
    end
    log("[DebugPickupExchange] 提交材料替换，关闭 UI_PickupExchangeItem")
    CloseWnd(self)
end

local function OnCloseClicked(self)
    log("[DebugPickupExchange] 点击关闭按钮，关闭 UI_PickupExchangeItem")
    CloseWnd(self)
end

local function OnFFAAimStateChanged(self, bOpenAim)
    if bOpenAim then
        self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

local function OnLeavePickupTrigger(self, Owner, tbGameObject)
    if Owner ~= GamePlayerSelfHelper:Get() then
        return
    end
    if tbGameObject:GetObjectType() ~= GameObjectTypeDef.Trigger then
        return
    end
    local tbCustomProtoData = tbGameObject.tbCustomProtoData
    if not tbCustomProtoData then
        return
    end
    local scene_item_info = tbCustomProtoData.scene_item_info
    if not scene_item_info then
        return
    end
    local nInstanceId = scene_item_info.instance_id
    if nInstanceId == self.nItemInstanceId then
        log("[DebugPickupExchange] 离开时拾取Trigger范围，关闭 UI_PickupExchangeItem")
        CloseWnd(self)
    end
end

function UIPickupExchangeItem:RefreshData(tbArgs)
    self.nItemInstanceId = tbArgs.nItemInstanceId
    self.nItemTemplateId = tbArgs.nItemTemplateId
    self.nCount = tbArgs.nCount

    self.tbChosenItems = {}

    local tbItems = BattleItemSystemClient:GetUnequippedItemsByCategory(BattleItemCategoryDef.MATERIAL)
    local tbItemsNeedExchange = {}
    for _, v in ipairs(tbItems) do
        if v:GetTemplateId() ~= self.nItemTemplateId then
            table.insert(tbItemsNeedExchange, v)
        end
    end

    table.sort(tbItemsNeedExchange, function(A, B) return A:GetTemplateId() < B:GetTemplateId() end)

    local nItemCount = #tbItemsNeedExchange
    for i = 1 , EXCHANGE_ITEM_MAX do
        local pbExchangeItem = self.pbExchangeItems[i]
        if i <= nItemCount then
            pbExchangeItem:RefreshItem(tbItemsNeedExchange[i])
            pbExchangeItem:SetChosenItems(self.tbChosenItems)
            pbExchangeItem:SetTotalPickupCount(self.nCount)
            pbExchangeItem:SetCountChangedDelegate(self.OnCountChangedDelegate)
        else
            pbExchangeItem:RefreshItem(nil)
        end
    end

    RefreshData(self)
end

function UIPickupExchangeItem:OnEnter()
    self:RefreshData(self.tbOpenArgs)
end

function UIPickupExchangeItem:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    self.OnCountChangedDelegate = LuaDelegateClass()
    self.pbExchangeItems = {}
    for i = 1 , EXCHANGE_ITEM_MAX do
        self.pbExchangeItems[i] = PrefabHelper:BindPrefab(pWidgetRef["pbExchangeItem"..i])
    end
end

function UIPickupExchangeItem:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_SCENE_ITEM, self, OnRemoveSceneItem)
    EventHelper:RegisterEvent(CommonEventDef.EV_PLAYER_LEAVE_TRIGGER, self, OnLeavePickupTrigger)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_AIM_STATE_CHANGED, self, OnFFAAimStateChanged)
    EventHelper:RegisterLuaDelegate(self.OnCountChangedDelegate, OnCountChanged, self)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCommit.OnClicked, self, OnCommitClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, OnCloseClicked)
end

function UIPickupExchangeItem:OnDestroy()
end

return UIPickupExchangeItem