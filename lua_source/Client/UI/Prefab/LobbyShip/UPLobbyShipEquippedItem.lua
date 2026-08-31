-----------------------------------------------------
--File Name    : UPLobbyShipEquippedItem.lua
--Author       : chenyixin
--Description  : 船体界面装配UP
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipEquippedItem = luaclass("UPLobbyShipEquippedItem", PrefabBase)

local ItemSystem = require("ItemSystem")

local UISetUtils = require("UISetUtils")

local UIResourceDef = require("UIResourceDef")

local LOCKED = -1
local EMPTY = 0

-- local SELECTED_SHADOW_COLOR = KMUMGLibrary.GetLinearColor(0.0, 0.0, 0.0, 0.0)

UPLobbyShipEquippedItem.nIndex = 0
-- 记录装配的船Id，-1为未解锁, 0为未装配
UPLobbyShipEquippedItem.nShipItemId = 0
UPLobbyShipEquippedItem.tbShipTemplate = nil
UPLobbyShipEquippedItem.tbShipResTemplate = nil

UPLobbyShipEquippedItem.fnOnCheckStateChanged = nil
UPLobbyShipEquippedItem.fnOnBtnDeleteEquipmentClicked = nil
UPLobbyShipEquippedItem.fnOnBuyClicked = nil
UPLobbyShipEquippedItem.fnOnChecked = nil

local function SetEquippedTab(self, nShipItemId)
    local pWidgetRef = self.pWidgetRef
    local tbTemplate = ItemSystem:GetItemTemplate(nShipItemId)
    if not tbTemplate then
        logerror("Cannot find item template, id=", nShipItemId)
        return
    end
    self.tbShipTemplate = tbTemplate

    local nSkinItemId = self.OwnerSub:GetShipPreparationComponent():GetEquippedShipSkinId(nShipItemId)
    nShipItemId = nSkinItemId and nSkinItemId or nShipItemId

    local tbItemRes = ItemSystem:GetItemResTemplate(nShipItemId)
    if not tbItemRes then
        logerror("Cannot find item res template, id=", nShipItemId)
        return
    end
    self.tbShipResTemplate = tbItemRes
    
    local szImgPath = tbItemRes.szIconPath

    UISetUtils.SetImageBrushRes(pWidgetRef.imgTitle, szImgPath:load())
    pWidgetRef.imgTitle:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.txtShipName:SetText(tbTemplate.l10nName)
    pWidgetRef.txtShipName:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.txtLockandAdd:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.btnLockandAdd:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnTabCheckStateChanged(self, bChecked)
    if self.fnOnCheckStateChanged then
        self.fnOnCheckStateChanged(self)
    end
end

local function OnBtnDeleteEquipmentClicked(self)
    if self.fnOnBtnDeleteEquipmentClicked then
        self.fnOnBtnDeleteEquipmentClicked(self)
    end
end

local function OnBuyClicked(self, tbMeta)
    if self.fnOnBuyClicked then
        self.fnOnBuyClicked(self)
    end
end

function UPLobbyShipEquippedItem:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
end

function UPLobbyShipEquippedItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.KMCheckBox_0.OnCheckStateChanged, self, OnTabCheckStateChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDeleteEquipment.OnClicked, self, OnBtnDeleteEquipmentClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnNoEquippableShip.OnClicked, self, OnBuyClicked)
end

----------------- 接口 ----------------------------------------------------------

function UPLobbyShipEquippedItem:SetShipInfoByItemId(nShipItemId)
    local pWidgetRef = self.pWidgetRef
    self.nShipItemId = nShipItemId
    if self:IsSelected() and self:IsEquipped() then
        pWidgetRef.btnDeleteEquipment:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.btnDeleteEquipment:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnNoEquippableShip:SetVisibility(ESlateVisibility.Collapsed)
    end

    if nShipItemId and nShipItemId > 0 then
        SetEquippedTab(self, nShipItemId)
        pWidgetRef.KMCheckBox_0:HideTipIcon(true)
    else
        pWidgetRef.txtShipName:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgTitle:SetVisibility(ESlateVisibility.Collapsed)

        pWidgetRef.txtLockandAdd:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.btnLockandAdd:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        
        -- 未装配
        if nShipItemId == EMPTY then
            pWidgetRef.txtLockandAdd:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_EQUIP_SHIP"))
            UISetUtils.SetImageBrushRes(self.pWidgetRef.imgLockandAdd, UIResourceDef.LOBBY_COMMON.ADD:load())
            local tbUnequippedShips = self.OwnerSub:GetShipPreparationComponent():GetUnequippedShipTemplates()
            pWidgetRef.KMCheckBox_0:HideTipIcon(#tbUnequippedShips == 0)
        end
        -- 未解锁
        if nShipItemId == LOCKED then
            pWidgetRef.txtLockandAdd:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_UNLOCK_SHIP_BERTH"))
            UISetUtils.SetImageBrushRes(self.pWidgetRef.imgLockandAdd, UIResourceDef.LOBBY_COMMON.LOCK:load())
            pWidgetRef.KMCheckBox_0:HideTipIcon(true)
        end
    end
end

function UPLobbyShipEquippedItem:BindCallbacks(fnOnCheckStateChanged, fnOnBtnDeleteEquipmentClicked, fnOnBuyClicked, fnOnChecked)
    self.fnOnCheckStateChanged = fnOnCheckStateChanged
    self.fnOnBtnDeleteEquipmentClicked = fnOnBtnDeleteEquipmentClicked
    self.fnOnBuyClicked = fnOnBuyClicked
    self.fnOnChecked = fnOnChecked
end

function UPLobbyShipEquippedItem:SetCheckedState(bChecked, bIgnoreCheck)
    local pCheckState = bChecked and ECheckBoxState.Checked or ECheckBoxState.Unchecked 
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.KMCheckBox_0:SetCheckedState(pCheckState)
    if not bChecked then
        pWidgetRef.btnNoEquippableShip:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnDeleteEquipment:SetVisibility(ESlateVisibility.Collapsed)
        -- pWidgetRef.txtShipName:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        -- pWidgetRef.txtShipName:SetShadowColorAndOpacity(UIResourceDef.COLOR.BLACK.LINEAR_COLOR)
    else
        -- pWidgetRef.txtShipName:SetColorAndOpacity(UIResourceDef.COLOR.BLACK.SLATE_COLOR)
        -- pWidgetRef.txtShipName:SetShadowColorAndOpacity(SELECTED_SHADOW_COLOR)
        if self:IsEquipped() then
            pWidgetRef.btnDeleteEquipment:SetVisibility(ESlateVisibility.Visible)
        end
    end

    if self.fnOnChecked and bChecked and not bIgnoreCheck then
        self.fnOnChecked(self)
    end
end

function UPLobbyShipEquippedItem:SetNoEquipableShip()
    self.pWidgetRef.btnNoEquippableShip:SetVisibility(ESlateVisibility.Visible)
end

function UPLobbyShipEquippedItem:SetEmpty()
    self:SetShipInfoByItemId(EMPTY)
end

function UPLobbyShipEquippedItem:RefreshDisplay()
    self:SetShipInfoByItemId(self.nShipItemId)
end

function UPLobbyShipEquippedItem:OnShipEquipped()
    self:PlayAnimation("anim_ShipEnable", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPLobbyShipEquippedItem:OnSkinChanged()
    self:PlayAnimation("anim_ShipSkinChange", 0, 1, EUMGSequencePlayMode.Forward, 1)
    self:RefreshDisplay()
end

function UPLobbyShipEquippedItem:GetBattleItemId()
    if not self:IsEquipped() then
        return nil
    end
    if not self.tbShipTemplate then
        return nil
    end
    return self.tbShipTemplate.nBattleItemId
end

function UPLobbyShipEquippedItem:IsUnlocked()
    if not self.nShipItemId then
        return false
    end
    return self.nShipItemId >= EMPTY
end

function UPLobbyShipEquippedItem:IsEquipped()
    if not self.nShipItemId then
        return false
    end
    return self.nShipItemId > EMPTY
end

function UPLobbyShipEquippedItem:IsSelected()
    return self.pWidgetRef.KMCheckBox_0:GetCheckedState() == ECheckBoxState.Checked
end

return  UPLobbyShipEquippedItem