-----------------------------------------------------
--File Name    : UPLobbyShipMiniItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 舰船小Item，用于舰船列表和舰船图鉴
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyShipMiniItem = luaclass("UPLobbyShipMiniItem", ListItemBase)

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local UITextDef = require("UITextDef")
local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local Expiration_Time_REFRESH_INTERVAL = 1

local function GetShipPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function OnClickedItem(self)
    self:SelectItem()
end

local function OnClickedDetail(self)
    if UIManager:IsWndOpen(UIDef.UI_LOBBY_SHIP_DETAIL) then
        UIManager:CloseWnd(UIDef.UI_LOBBY_SHIP_DETAIL)
    end
    UIManager:OpenWnd(UIDef.UI_LOBBY_SHIP_DETAIL, {nShipTemplateId = self.tbData.nId})
end

local function OnExpirationTimeEnd(self)
    self.ListHelper.tbExtraDatas.fnShipExpired()
end

function UPLobbyShipMiniItem:OnLoad()
    self.pWidgetRef.txtExpirationTime:SetPrecision(2)
end

function UPLobbyShipMiniItem:OnRefresh(tbData)
    self.pWidgetRef.txtName:SetText(tbData.l10nName)
    local szPosterPath = GetShipPreparationComponent():GetHorizontalPosterPath(tbData.nId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, szPosterPath:load())
    local ShipPreparationComponent = GetShipPreparationComponent()
    local nExpirationTime = ShipPreparationComponent:GetItemExpirationTime(tbData.nId)
    if nExpirationTime > 0 then
        self.pWidgetRef.txtExpirationTime:StartTimer(nExpirationTime, Expiration_Time_REFRESH_INTERVAL, UITextDef.TIMER_TEXT_BLOCK_FORMAT_FULL, EMinTimeUnit.Second)
        self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.pWidgetRef.txtExpirationTime:StopTimer()
        self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPLobbyShipMiniItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClickedItem)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnDetail.OnClicked, self, OnClickedDetail)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.txtExpirationTime.OnCompleteTimer, self, OnExpirationTimeEnd)
end

return UPLobbyShipMiniItem