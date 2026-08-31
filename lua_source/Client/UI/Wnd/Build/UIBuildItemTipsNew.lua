-----------------------------------------------------
--File Name    : UIBuildItemTipsNew.lua
--Author       : chenyixin
--Description  : 建造界面舰船物品的tips
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIBuildItemTipsNew = luaclass("UIBuildItemTipsNew", WndBase)

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local ShipItemHelper = require("ShipItemHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")

local ITEMS_TIPS_NEW_INDEX = 0
local SHIP_TIPS_INDEX = 1
local SHIP_PART_TIPS_INDEX = 2

UIBuildItemTipsNew.pbBuildItemTips = nil
UIBuildItemTipsNew.pbCurrentItemTips = nil
UIBuildItemTipsNew.pbBuildShipTips = nil
UIBuildItemTipsNew.pbCurrentShipTips = nil
UIBuildItemTipsNew.pbBuildShipPartTips = nil
UIBuildItemTipsNew.pbCurrentShipPartTips = nil

function UIBuildItemTipsNew:ShowBuildItemTips(nSelectedItemTemplateId, nSlotIndex)
    self.pWidgetRef.wsTips:SetActiveWidgetIndex(SHIP_PART_TIPS_INDEX)
    self.pbBuildShipPartTips:Refresh(nSelectedItemTemplateId, false, nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nCompareItemTemplateId = CheckCanBuildItemHelper.GetSameSlotEquippedItemTemplateId(nCharacterInstanceId, nSelectedItemTemplateId, nSlotIndex, true)
    if nCompareItemTemplateId and nSelectedItemTemplateId ~= nCompareItemTemplateId then
        self.pbCurrentShipPartTips:Refresh(nCompareItemTemplateId, true, nSlotIndex)
    else
        self.pbCurrentShipPartTips:Collapsed()
    end
end

function UIBuildItemTipsNew:ShowBuildShipTips(nSelectedItemTemplateId)
    self.pWidgetRef.wsTips:SetActiveWidgetIndex(SHIP_TIPS_INDEX)
    local nCurrentShipItemTemplateId = ShipItemHelper.GetCurrentShipItemTemplateIdOnClient()
    local bShowDetailBtn = nil
    if nSelectedItemTemplateId ~= nCurrentShipItemTemplateId then
        self.pbCurrentShipTips:Refresh(nCurrentShipItemTemplateId, true)
    else
        self.pbCurrentShipTips:Collapsed()
        bShowDetailBtn = true
    end
    self.pbBuildShipTips:Refresh(nSelectedItemTemplateId, nil, bShowDetailBtn)
end

function UIBuildItemTipsNew:ShowBuildItemTipsNew(nSelectedItemTemplateId, nSlotIndex)
    self.pWidgetRef.wsTips:SetActiveWidgetIndex(ITEMS_TIPS_NEW_INDEX)
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
    self.pbBuildShipPartTips:Collapsed()
    self.pbCurrentShipPartTips:Collapsed()
end

function UIBuildItemTipsNew:OnLoad()
    log("[DEBUG_UI] UIBuildItemTipsNew:OnLoad")
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.pbBuildItemTips = PrefabHelper:BindPrefab(pWidgetRef.pbBuildItemTips, UIDef.UP_BUILD_ITEM_TIPS_NEW)
    self.pbCurrentItemTips = PrefabHelper:BindPrefab(pWidgetRef.pbCurrentItemTips, UIDef.UP_BUILD_ITEM_TIPS_NEW)
    self.pbBuildShipPartTips = PrefabHelper:BindPrefab(pWidgetRef.pbBuildShipPartTips, UIDef.UP_BUILD_ITEM_TIPS)
    self.pbCurrentShipPartTips = PrefabHelper:BindPrefab(pWidgetRef.pbCurrentShipPartTips, UIDef.UP_BUILD_ITEM_TIPS)
    self.pbBuildShipTips = PrefabHelper:BindPrefab(pWidgetRef.pbBuildShipTips, UIDef.UP_BUILD_SHIP_TIPS_NEW)
    self.pbCurrentShipTips = PrefabHelper:BindPrefab(pWidgetRef.pbCurrentBuildShipTips, UIDef.UP_BUILD_SHIP_TIPS_NEW)
end

function UIBuildItemTipsNew:OnUnload()
end

function UIBuildItemTipsNew:OnShow()
    log("[DEBUG_UI] UIBuildItemTipsNew:OnShow")
    CollapsedTips(self)

    local tbOpenArgs = self.tbOpenArgs
    
    if not (tbOpenArgs and tbOpenArgs.tbParams) then
        logerror("[UIBuildItemTipsNew, Show tips params is nil, szFunctionName=", tbOpenArgs.szFunctionName)
    end
    -- 目前传进来的参数最多两个
    self[tbOpenArgs.szFunctionName](self, tbOpenArgs.tbParams[1], tbOpenArgs.tbParams[2])
end

function UIBuildItemTipsNew:OnEnter()
    log("[DEBUG_UI] UIBuildItemTipsNew:OnEnter")
end

function UIBuildItemTipsNew:OnBindEvent(EventHelper)
    log("[DEBUG_UI] UIBuildItemTipsNew:OnBindEvent")
    self.pbBuildShipTips:BindOnBtnDetailClicked(function()
        self.pbCurrentShipTips:ToggleShowDetailedInfo()
    end)
end

function UIBuildItemTipsNew:CloseWnd()
    UIManager:CloseWnd(UIDef.UI_BUILD_ITEM_TIPS_NEW)
end

return UIBuildItemTipsNew
