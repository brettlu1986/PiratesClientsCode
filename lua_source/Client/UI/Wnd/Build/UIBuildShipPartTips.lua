-----------------------------------------------------
--File Name    : UIBuildShipPartTips.lua
--Author       : chenyixin
--Description  : 建造舰船零件的tips
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIBuildShipPartTips = luaclass("UIBuildShipPartTips", WndBase)

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")

UIBuildShipPartTips.pbBuildShipPartTips = nil
UIBuildShipPartTips.pbCurrentShipPartTips = nil

function UIBuildShipPartTips:ShowBuildShipPartTips(nSelectedItemTemplateId, nSlotIndex)
    self.pbBuildShipPartTips:Refresh(nSelectedItemTemplateId, false, nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nCompareItemTemplateId = CheckCanBuildItemHelper.GetSameSlotEquippedItemTemplateId(nCharacterInstanceId, nSelectedItemTemplateId, nSlotIndex, true)
    if nCompareItemTemplateId and nSelectedItemTemplateId ~= nCompareItemTemplateId then
        self.pbCurrentShipPartTips:Refresh(nCompareItemTemplateId, true, nSlotIndex)
    else
        self.pbCurrentShipPartTips:Collapsed()
    end
end

function UIBuildShipPartTips:OnLoad()
    log("[DEBUG_UI] UIBuildShipPartTips:OnLoad")
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.pbBuildShipPartTips = PrefabHelper:BindPrefab(pWidgetRef.pbBuildShipPartTips, UIDef.UP_BUILD_ITEM_TIPS)
    self.pbCurrentShipPartTips = PrefabHelper:BindPrefab(pWidgetRef.pbCurrentShipPartTips, UIDef.UP_BUILD_ITEM_TIPS)
end

function UIBuildShipPartTips:OnUnload()
end

function UIBuildShipPartTips:OnShow()
    log("[DEBUG_UI] UIBuildShipPartTips:OnShow")

    local tbOpenArgs = self.tbOpenArgs
    
    if not (tbOpenArgs and tbOpenArgs.nSelectedItemTemplateId)then
        logerror("[UIBuildShipPartTips] invalid tbOpenArgs:", t2s(tbOpenArgs))
        return
    end

    self:ShowBuildShipPartTips(tbOpenArgs.nSelectedItemTemplateId, tbOpenArgs.nSlotIndex)
end

function UIBuildShipPartTips:OnEnter()
    log("[DEBUG_UI] UIBuildShipPartTips:OnEnter")
end

function UIBuildShipPartTips:OnBindEvent(EventHelper)
    log("[DEBUG_UI] UIBuildShipPartTips:OnBindEvent")
end

function UIBuildShipPartTips:CloseWnd()
    UIManager:CloseWnd(UIDef.UI_BUILD_ITEM_TIPS_NEW)
end

return UIBuildShipPartTips
