-----------------------------------------------------
--File Name    : UPLobbyShipEquippingItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 舰船上阵界面Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipEquippingItem = luaclass("UPLobbyShipEquippingItem", PrefabBase)

local UIDef = require("UIDef")
local UITextDef = require("UITextDef")
local UIManager = require("UIManager")
local ItemSystem = require("ItemSystem")
local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local TAB_INDEX_EMPTY = 0
local TAB_INDEX_SHIP = 1
local TAB_INDEX_LOCK = 2
local Expiration_Time_REFRESH_INTERVAL = 1

UPLobbyShipEquippingItem.bUnlocked = false
UPLobbyShipEquippingItem.nTemplateId = -1
UPLobbyShipEquippingItem.fnOnClickedEquip = nil
UPLobbyShipEquippingItem.fnOnClickedUnequip = nil
UPLobbyShipEquippingItem.fnOnClickedUnlock = nil

local function GetShipPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function OnClickedBtnEquip(self)
    if self.fnOnClickedEquip then
        self.fnOnClickedEquip()
    end
end

local function OnClickedBtnUnequip(self)
    if self.fnOnClickedUnequip then
        self.fnOnClickedUnequip()
    end
end

local function OnClickedBtnUnlock(self)
    if self.fnOnClickedUnlock then
        self.fnOnClickedUnlock()
    end
end

local function OnClickedBtnDetail(self)
    if UIManager:IsWndOpen(UIDef.UI_LOBBY_SHIP_DETAIL) then
        UIManager:CloseWnd(UIDef.UI_LOBBY_SHIP_DETAIL)
    end
    UIManager:OpenWnd(UIDef.UI_LOBBY_SHIP_DETAIL, {nShipTemplateId = self.nTemplateId})
end

function UPLobbyShipEquippingItem:OnLoad()
    self.pWidgetRef.txtExpirationTime:SetPrecision(2)
end

function UPLobbyShipEquippingItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnEquip.OnClicked, self, OnClickedBtnEquip)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUnequip.OnClicked, self, OnClickedBtnUnequip)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnReplace.OnClicked, self, OnClickedBtnEquip)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUnlock.OnClicked, self, OnClickedBtnUnlock)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnDetail.OnClicked, self, OnClickedBtnDetail)
end

function UPLobbyShipEquippingItem:SetOnClickedEquipCallback(fnOnClickedEquip)
    self.fnOnClickedEquip = fnOnClickedEquip
end

function UPLobbyShipEquippingItem:SetOnClickedUnequipCallback(fnOnClickedUnequip)
    self.fnOnClickedUnequip = fnOnClickedUnequip
end

function UPLobbyShipEquippingItem:SetOnClickedUnlockCallback(fnOnClickedUnlock)
    self.fnOnClickedUnlock = fnOnClickedUnlock
end

function UPLobbyShipEquippingItem:SetShipItemId(nTemplateId)
    -- 清除有效期UI
    self.pWidgetRef.txtExpirationTime:StopTimer()
    self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)

    self.nTemplateId = nTemplateId
    local tbTemplate = ItemSystem:GetItemTemplate(nTemplateId)
    if tbTemplate then
        self.pWidgetRef.txtName:SetText(tbTemplate.l10nName)
        self:UpdateShipSkin()
        self.pWidgetRef.wsContent:SetActiveWidgetIndex(TAB_INDEX_SHIP)

        local ShipPreparationComponent = GetShipPreparationComponent()
        local nExpirationTime = ShipPreparationComponent:GetItemExpirationTime(nTemplateId)
        if nExpirationTime > 0 then
            self.pWidgetRef.txtExpirationTime:StartTimer(nExpirationTime, Expiration_Time_REFRESH_INTERVAL, UITextDef.TIMER_TEXT_BLOCK_FORMAT_FULL, EMinTimeUnit.Second)
            self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.HitTestInvisible)
        end
    else
        self.pWidgetRef.wsContent:SetActiveWidgetIndex(TAB_INDEX_EMPTY)
    end
    self:PlayAnimation("animReplace", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPLobbyShipEquippingItem:GetShipTemplateId()
    return self.nTemplateId
end

function UPLobbyShipEquippingItem:SetSlotInfo(bUnlocked, nTemplateId)
    self.bUnlocked = bUnlocked
    if bUnlocked then
        self:SetShipItemId(nTemplateId)
    else
        self.pWidgetRef.wsContent:SetActiveWidgetIndex(TAB_INDEX_LOCK)
    end
end

function UPLobbyShipEquippingItem:Unlock()
    self.bUnlocked = true
    self.pWidgetRef.wsContent:SetActiveWidgetIndex(TAB_INDEX_EMPTY)
end

function UPLobbyShipEquippingItem:UnlockShip()
    self.pWidgetRef.txtExpirationTime:StopTimer()
    self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
end

function UPLobbyShipEquippingItem:IsUnlocked()
    return self.bUnlocked
end

function UPLobbyShipEquippingItem:UpdateShipSkin(nShipSkinId)
    local szPosterPath = GetShipPreparationComponent():GetVerticalPosterPath(self.nTemplateId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgShip, szPosterPath:load())
end

return UPLobbyShipEquippingItem