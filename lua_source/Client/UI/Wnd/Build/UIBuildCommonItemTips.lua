-----------------------------------------------------
--File Name    : UIBuildCommonItemTips.lua
--Author       : chenyixin
--Description  : 建造人装备和舰船武器的tips
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIBuildCommonItemTips = luaclass("UIBuildCommonItemTips", WndBase)

local UIDef = require("UIDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")

UIBuildCommonItemTips.pbBuildItemTips = nil
UIBuildCommonItemTips.pbCurrentItemTips = nil

function UIBuildCommonItemTips:ShowBuildCommonItemTips(nSelectedItemTemplateId, nSlotIndex)
    self.pbBuildItemTips:Refresh(nSelectedItemTemplateId, false, nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nCompareItemTemplateId = CheckCanBuildItemHelper.GetSameSlotEquippedItemTemplateId(nCharacterInstanceId, nSelectedItemTemplateId, nSlotIndex, true)
    if nCompareItemTemplateId and nSelectedItemTemplateId ~= nCompareItemTemplateId then
        self.pbCurrentItemTips:Refresh(nCompareItemTemplateId, true, nSlotIndex)
    else
        self.pbCurrentItemTips:Collapsed()
    end
end

function UIBuildCommonItemTips:OnLoad()
    log("[DEBUG_UI] UIBuildCommonItemTips:OnLoad")
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.pbBuildItemTips = PrefabHelper:BindPrefab(pWidgetRef.pbBuildItemTips, UIDef.UP_BUILD_ITEM_TIPS_NEW)
    self.pbCurrentItemTips = PrefabHelper:BindPrefab(pWidgetRef.pbCurrentItemTips, UIDef.UP_BUILD_ITEM_TIPS_NEW)
end

function UIBuildCommonItemTips:OnUnload()
end

function UIBuildCommonItemTips:OnShow()
    log("[DEBUG_UI] UIBuildCommonItemTips:OnShow")

    local tbOpenArgs = self.tbOpenArgs
    
    if not (tbOpenArgs and tbOpenArgs.nSelectedItemTemplateId)then
        logerror("[UIBuildCommonItemTips] invalid tbOpenArgs:", t2s(tbOpenArgs))
        return
    end

    self:ShowBuildCommonItemTips(tbOpenArgs.nSelectedItemTemplateId, tbOpenArgs.nSlotIndex)
end

function UIBuildCommonItemTips:OnEnter()
    log("[DEBUG_UI] UIBuildCommonItemTips:OnEnter")
end

function UIBuildCommonItemTips:OnBindEvent(EventHelper)
    log("[DEBUG_UI] UIBuildCommonItemTips:OnBindEvent")
end

function UIBuildCommonItemTips:CloseWnd()
    self:CloseSelf()
end

return UIBuildCommonItemTips
