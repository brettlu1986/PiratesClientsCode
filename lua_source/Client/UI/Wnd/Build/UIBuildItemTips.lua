-----------------------------------------------------
--File Name    : UIBuildItemTips.lua
--Author       : zhiyuan
--Create Time  : 2019-12-10
--Description  : 建造界面的tips
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIBuildItemTips = luaclass("UIBuildItemTips", WndBase)

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local ShipItemHelper = require("ShipItemHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")

local ITEMS_TIPS_INDEX = 0
local SHIP_TIPS_INDEX = 1

UIBuildItemTips.pbBuildItemTips = nil
UIBuildItemTips.pbCurrentItemTips = nil
UIBuildItemTips.pbBuildShipTips = nil
UIBuildItemTips.pbCurrentShipTips = nil

function UIBuildItemTips:ShowBuildShipTips(nSelectedItemTemplateId)
    self.pWidgetRef.wsTips:SetActiveWidgetIndex(SHIP_TIPS_INDEX)
    self.pbBuildShipTips:Refresh(nSelectedItemTemplateId)
    local nCurrentShipItemTemplateId = ShipItemHelper.GetCurrentShipItemTemplateIdOnClient()
    if nSelectedItemTemplateId ~= nCurrentShipItemTemplateId then
        self.pbCurrentShipTips:Refresh(nCurrentShipItemTemplateId, true)
    else
        self.pbCurrentShipTips:Collapsed()
    end
end

function UIBuildItemTips:ShowBuildItemTips(nSelectedItemTemplateId, nSlotIndex)
    self.pWidgetRef.wsTips:SetActiveWidgetIndex(ITEMS_TIPS_INDEX)
    self.pbBuildItemTips:Refresh(nSelectedItemTemplateId, false, nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nCompareItemTemplateId = CheckCanBuildItemHelper.GetSameSlotEquippedItemTemplateId(nCharacterInstanceId, nSelectedItemTemplateId, nSlotIndex, true)
    if nCompareItemTemplateId and nSelectedItemTemplateId ~= nCompareItemTemplateId then
        self.pbCurrentItemTips:Refresh(nCompareItemTemplateId, true, nSlotIndex)
    else
        self.pbCurrentItemTips:Collapsed()
    end
end

local function CollapsedTips(self)
    self.pbBuildItemTips:Collapsed()
    self.pbCurrentItemTips:Collapsed()
    self.pbBuildShipTips:Collapsed()
    self.pbCurrentShipTips:Collapsed()
end

function UIBuildItemTips:OnLoad()

    log("[DEBUG_UI] UIBuildItemTips:OnLoad")
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.pbBuildItemTips = PrefabHelper:BindPrefab(pWidgetRef.pbBuildItemTips, UIDef.UP_BUILD_ITEM_TIPS)
    self.pbCurrentItemTips = PrefabHelper:BindPrefab(pWidgetRef.pbCurrentBuildItemTips, UIDef.UP_BUILD_ITEM_TIPS)
    self.pbBuildShipTips = PrefabHelper:BindPrefab(pWidgetRef.pbBuildShipTips, UIDef.UP_BUILD_SHIP_TIPS)
    self.pbCurrentShipTips = PrefabHelper:BindPrefab(pWidgetRef.pbCurrentBuildShipTips, UIDef.UP_BUILD_SHIP_TIPS)
end

function UIBuildItemTips:OnUnload()
end

function UIBuildItemTips:OnShow()
    log("[DEBUG_UI] UIBuildItemTips:OnShow")
    CollapsedTips(self)
end

function UIBuildItemTips:OnEnter()
    log("[DEBUG_UI] UIBuildItemTips:OnEnter")
end

function UIBuildItemTips:OnBindEvent(EventHelper)
    log("[DEBUG_UI] UIBuildItemTips:OnBindEvent")
end

function UIBuildItemTips:CloseWnd()
    UIManager:CloseWnd(UIDef.UI_BUILD_ITEM_TIPS)
end

return UIBuildItemTips
