local luaclass          = require ("luaclass")
local PrefabBase        = require("PrefabBase")
local UPLobbyBackpackSub    = luaclass("UPLobbyBackpackSub", PrefabBase)

local UIDef = require("UIDef")
local SelfTimeCountDownHelper = require("SelfTimeCountDownHelper")
local LobbyItemUiHelper = require("LobbyItemUiHelper")
local ClientEventDef = require("ClientEventDef")
local CurrencySystem = require("CurrencySystem")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")

UPLobbyBackpackSub.Item = nil
UPLobbyBackpackSub.pbLobbyDisplayItem = nil
UPLobbyBackpackSub.tbTimeCountDownHelper = nil

UPLobbyBackpackSub.OnItemUsePressedDelegate = nil
UPLobbyBackpackSub.OnItemSellPressedDelegate = nil

local COUNT_DOWN_PRECISION = 2
local RefreshUseAndSellInfo = nil

local function OnClickedBtnSell(self)
    if self.OnItemSellPressedDelegate then
        self.OnItemSellPressedDelegate:Fire(self.Item)
    end
end

local function OnClickedBtnUse(self)
    if self.OnItemUsePressedDelegate then
        self.OnItemUsePressedDelegate:Fire(self.Item)
    end
end

local function SetName(self, l10nName)
    self.pWidgetRef.txtName:SetText(l10nName)
end

local function SetDesc(self, l10nDesc)
    self.pWidgetRef.kmtxtDesc:SetText(l10nDesc)
end

local function CollapsedExpiration(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrRemainTime:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgClock:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtRemainTimeTitle:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtRemainTime:SetVisibility(ESlateVisibility.Collapsed)
end

local function StopTimeCountDown(self)
    self.tbTimeCountDownHelper:StopCountDown()
end

local function SetExpirationTime(self, nRemainUseSeconds)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrRemainTime:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.imgClock:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.txtRemainTimeTitle:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.txtRemainTime:SetVisibility(ESlateVisibility.HitTestInvisible)

    StopTimeCountDown(self)
    local RefreshRemainTime = function()
        RefreshUseAndSellInfo(self)
    end
    self.tbTimeCountDownHelper:StartCountDown(
        nRemainUseSeconds, SelfTimeCountDownHelper.CountDownType.FRONT_FULL_PRECISION, COUNT_DOWN_PRECISION,
        self.pWidgetRef.txtRemainTime, RefreshRemainTime)
end

local function CollapsedSellButton(self)
    self.pWidgetRef.kmbtnSell:SetVisibility(ESlateVisibility.Collapsed)
end

local function ShowSellButton(self)
    self.pWidgetRef.kmbtnSell:SetVisibility(ESlateVisibility.Visible)
end

local function CollapsedSellPrice(self)
    self.pWidgetRef.hboxSell:SetVisibility(ESlateVisibility.Collapsed)
end

local function ShowSellPrice(self, nCurrencyId, nPrice)
    self.pWidgetRef.hboxSell:SetVisibility(ESlateVisibility.HitTestInvisible)
    self.pWidgetRef.txtPrice:SetText(nPrice)

    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgCurrency, szCurrencySmallIcon:load())
end

local function CollapsedCannotSell(self)
    self.pWidgetRef.txtCannotSell:SetVisibility(ESlateVisibility.Collapsed)
end

local function ShowCannotSell(self)
    self.pWidgetRef.txtCannotSell:SetVisibility(ESlateVisibility.HitTestInvisible)
end

local function ShowCanSellState(self, nCurrencyId, nPrice)
    CollapsedCannotSell(self)
    ShowSellPrice(self, nCurrencyId, nPrice)
    ShowSellButton(self)
end

local function ShowCannotSellState(self)
    CollapsedSellPrice(self)
    CollapsedSellButton(self)
    ShowCannotSell(self)
end

local function CollapsedUseButton(self)
    self.pWidgetRef.kmbtnUse:SetVisibility(ESlateVisibility.Collapsed)
end

local function ShowUseButton(self)
    self.pWidgetRef.kmbtnUse:SetVisibility(ESlateVisibility.Visible)
end

local function CollapsedExpired(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrRemainTime:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtExpired:SetVisibility(ESlateVisibility.Collapsed)
end

local function ShowExpired(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrRemainTime:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.txtExpired:SetVisibility(ESlateVisibility.HitTestInvisible)
end

local function RefreshStateItemExpired(self)
    CollapsedExpiration(self)
    CollapsedUseButton(self)

    local Item = self.Item
    ShowCanSellState(self, Item:GetCurrencyId(), Item:GetSellPrice())
    ShowExpired(self)
end

local function RefreshStateItemTimer(self, nRemainUseSeconds)
    CollapsedExpired(self)

    ShowCannotSellState(self)
    SetExpirationTime(self, nRemainUseSeconds)
    ShowUseButton(self)
end

local function RefreshStateNoExpirationAndCanSell(self)
    CollapsedExpiration(self)
    CollapsedExpired(self)

    local Item = self.Item
    ShowCanSellState(self, Item:GetCurrencyId(), Item:GetSellPrice())
    ShowUseButton(self)
end

local function RefreshStateNoExpirationAndCannotSell(self)
    CollapsedExpiration(self)
    CollapsedExpired(self)
    ShowCannotSellState(self)

    ShowUseButton(self)
end

local function RefreshStateOnlyCanSell(self)
    CollapsedExpiration(self)
    CollapsedExpired(self)
    CollapsedUseButton(self)

    local Item = self.Item
    ShowCanSellState(self, Item:GetCurrencyId(), Item:GetSellPrice())
end

local function RefreshStateCannotUseAndCannotSell(self)
    CollapsedExpiration(self)
    CollapsedExpired(self)
    CollapsedUseButton(self)
    ShowCannotSellState(self)
end

local function RefreshBaseInfo(self)
    local Item = self.Item
    self.pbLobbyDisplayItem:SetDisplayItemData(Item:GetTemplateId(), nil, false)
    SetName(self, Item:GetName())
    local pWidgetRef = self.pWidgetRef
    LobbyItemUiHelper.SetCountTitleAndCount(Item, pWidgetRef.txtCountTitle, pWidgetRef.txtCount)
    SetDesc(self, ItemSystem:GetItemIntro(Item:GetTemplateId()))
end


RefreshUseAndSellInfo = function(self)
    local Item = self.Item

    local bCanUseInBackpack = ItemSystem:CanUseInBackpack(Item:GetTemplateId())
    if bCanUseInBackpack then -- 可在背包使用
        if Item:HasExpiration() then -- 有使用期限（到期必须可以出售）
            local nRemainUseSeconds = Item:GetRemainCanUseSeconds()
            if nRemainUseSeconds <= 0 then -- 已经过期
                RefreshStateItemExpired(self)
            else -- 没有过期
                RefreshStateItemTimer(self, nRemainUseSeconds)
            end
        else -- 没有使用期限
            if Item:CanSell() then -- 可以出售
                RefreshStateNoExpirationAndCanSell(self)
            else -- 不可以出售
                RefreshStateNoExpirationAndCannotSell(self)
            end
        end
    else -- 不可在背包使用（必须可以出售）
        if Item:CanSell() then -- 可以出售
            RefreshStateOnlyCanSell(self)
        else -- 不可以出售
            RefreshStateCannotUseAndCannotSell(self)
        end
    end
end

function UPLobbyBackpackSub:OnCreate()
end

function UPLobbyBackpackSub:OnDestroy()
    StopTimeCountDown(self)
end

function UPLobbyBackpackSub:OnLoad()
    self.tbTimeCountDownHelper = SelfTimeCountDownHelper()
    self.pbLobbyDisplayItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyDisplayItem, UIDef.UP_LOBBY_DISPLAY_ITEM)
end

function UPLobbyBackpackSub:OnShow()
end

local function OnChangeItemExpireAtSeconds(self, nInstanceId)
    local Item = self.Item
    if Item:GetInstanceId() == nInstanceId then
        self:SetData(Item)
    end
end

function UPLobbyBackpackSub:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnSell.OnClicked, self, OnClickedBtnSell)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnUse.OnClicked, self, OnClickedBtnUse)

    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_EXPIRED_AT, self, OnChangeItemExpireAtSeconds)
end

function UPLobbyBackpackSub:SetData(Item)
    StopTimeCountDown(self)
    self.Item = Item

    RefreshBaseInfo(self)
    RefreshUseAndSellInfo(self)
end

function UPLobbyBackpackSub:SetOnItemUsePressedDelegate(OnItemUsePressedDelegate)
    self.OnItemUsePressedDelegate = OnItemUsePressedDelegate
end

function UPLobbyBackpackSub:SetOnItemSellPressedDelegate(OnItemSellPressedDelegate)
    self.OnItemSellPressedDelegate = OnItemSellPressedDelegate
end

return UPLobbyBackpackSub
