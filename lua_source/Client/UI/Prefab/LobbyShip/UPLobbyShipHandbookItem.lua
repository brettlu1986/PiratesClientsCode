-----------------------------------------------------
--File Name    : UPLobbyShipPartDetailItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 舰船图鉴Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipHandbookItem = luaclass("UPLobbyShipHandbookItem", PrefabBase)

local UIDef = require("UIDef")
local UITextDef = require("UITextDef")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local Expiration_Time_REFRESH_INTERVAL = 1

UPLobbyShipHandbookItem.nTemplateId = nil

local function GetShipPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function OnClickedBtnItem(self)
    if UIManager:IsWndOpen(UIDef.UI_LOBBY_SHIP_DETAIL) then
        UIManager:CloseWnd(UIDef.UI_LOBBY_SHIP_DETAIL)
    end
    UIManager:OpenWnd(UIDef.UI_LOBBY_SHIP_DETAIL, {nShipTemplateId = self.nTemplateId})
end

local function OnExpirationTimeEnd(self)
    self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.imgLocked:SetVisibility(ESlateVisibility.HitTestInvisible)
end

function UPLobbyShipHandbookItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClickedBtnItem)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.txtExpirationTime.OnCompleteTimer, self, OnExpirationTimeEnd)
end

function UPLobbyShipHandbookItem:OnLoad()
    self.pWidgetRef.txtExpirationTime:SetPrecision(2)
end

function UPLobbyShipHandbookItem:UnlockShip()
    self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.imgLocked:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.txtExpirationTime:StopTimer()
end

function UPLobbyShipHandbookItem:SetShipItemTemplate(tbTemplate)
    self.nTemplateId = tbTemplate.nId
    self.pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    self:UpdateShipSkin()
    local ShipPreparationComponent = GetShipPreparationComponent()
    if ShipPreparationComponent:IsItemUnlocked(self.nTemplateId) then
        self:UnlockShip()
        local nExpirationTime = ShipPreparationComponent:GetItemExpirationTime(self.nTemplateId)
        if nExpirationTime > 0 then
            self.pWidgetRef.txtExpirationTime:StartTimer(nExpirationTime, Expiration_Time_REFRESH_INTERVAL, UITextDef.TIMER_TEXT_BLOCK_FORMAT_FULL, EMinTimeUnit.Second)
            self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.HitTestInvisible)
        else
            self.pWidgetRef.txtExpirationTime:StopTimer()
            self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
        end
        local bEquippedShip = ShipPreparationComponent:IsEquippedShip(self.nTemplateId)
        self.pWidgetRef.imgEquipped:SetVisibility(bEquippedShip and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    end
    if tbTemplate.bDefaultUnlocked then
        self.pWidgetRef.imgDefault:SetVisibility(ESlateVisibility.HitTestInvisible)
    end
end

function UPLobbyShipHandbookItem:UpdateShipSkin(nShipSkinId)
    local szPosterPath = GetShipPreparationComponent():GetHorizontalPosterPath(self.nTemplateId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, szPosterPath:load())
end

return UPLobbyShipHandbookItem