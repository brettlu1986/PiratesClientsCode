-----------------------------------------------------
--File Name    : UIBuildItemTipsNew.lua
--Author       : chenyixin
--Description  : 建造舰船的tips
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIBuildItemTipsNew = luaclass("UIBuildItemTipsNew", WndBase)

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local ShipItemHelper = require("ShipItemHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

UIBuildItemTipsNew.pbBuildShipTips = nil
UIBuildItemTipsNew.pbCurrentShipTips = nil

function UIBuildItemTipsNew:ShowBuildShipTips(nSelectedItemTemplateId)
    local nCurrentShipItemTemplateId = ShipItemHelper.GetCurrentShipItemTemplateIdOnClient()
    local bShowDetailBtn = nil
    if nCurrentShipItemTemplateId and nSelectedItemTemplateId ~= nCurrentShipItemTemplateId then
        self.pbCurrentShipTips:Refresh(nCurrentShipItemTemplateId, true)
    else
        if not nCurrentShipItemTemplateId then
            local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
            local ActiveShipItem = ShipItemHelper.GetCurrentShipItem(nCharacterInstanceId, true)
            logerror("[UIBuildItemTipsNew] nCurrentShipItemTemplateId is nil, nCharacterInstanceId=", nCharacterInstanceId, "ActiveShipItem=", ActiveShipItem)
        end
        self.pbCurrentShipTips:Collapsed()
        bShowDetailBtn = true
    end
    self.pbBuildShipTips:Refresh(nSelectedItemTemplateId, nil, bShowDetailBtn)
end

function UIBuildItemTipsNew:OnLoad()
    log("[DEBUG_UI] UIBuildItemTipsNew:OnLoad")
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)

    self.pbBuildShipTips = PrefabHelper:BindPrefab(pWidgetRef.pbBuildShipTips, UIDef.UP_BUILD_SHIP_TIPS_NEW)
    self.pbCurrentShipTips = PrefabHelper:BindPrefab(pWidgetRef.pbCurrentBuildShipTips, UIDef.UP_BUILD_SHIP_TIPS_NEW)
end

function UIBuildItemTipsNew:OnUnload()
end

function UIBuildItemTipsNew:OnShow()
    log("[DEBUG_UI] UIBuildItemTipsNew:OnShow")

    local tbOpenArgs = self.tbOpenArgs
    
    if not (tbOpenArgs and tbOpenArgs.nSelectedItemTemplateId)then
        logerror("[UIBuildItemTipsNew] invalid tbOpenArgs:", t2s(tbOpenArgs))
        return
    end

    self:ShowBuildShipTips(tbOpenArgs.nSelectedItemTemplateId)
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
