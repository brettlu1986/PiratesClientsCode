local luaclass          = require ("luaclass")
local WndBase        = require("WndBase")
local UILobbyBackpackTips    = luaclass("UILobbyBackpackTips", WndBase)

local ItemSystem = require("ItemSystem")
local MathUtil = require("MathUtil")
local UIDef = require("UIDef")
local SelfTimeCountDownHelper = require("SelfTimeCountDownHelper")
local UISetUtils = require("UISetUtils")
local GetL10NTextByKey = UISetUtils.GetL10NTextByKey
local LobbyItemUiHelper = require("LobbyItemUiHelper")
local CurrencySystem = require("CurrencySystem")
local HomelandSystem = require("HomelandSystem")
local ItemCategoryDef = require("ItemCategoryDef")
local LobbyItemIni = require("LobbyItemIni")

UILobbyBackpackTips.Type = {
    USE = 1,
    SELL = 2
}

local SELL_TITLE = GetL10NTextByKey("UP_LOBBY_BACKPACK_TIPS_SELL_TITLE")
local USE_TITLE = GetL10NTextByKey("UP_LOBBY_BACKPACK_TIPS_USE_TITLE")
local SELL_BUTTON_NAME = GetL10NTextByKey("UP_LOBBY_BACKPACK_TIPS_SELL_BUTTON_NAME")
local USE_BUTTON_NAME = GetL10NTextByKey("UP_LOBBY_BACKPACK_TIPS_USE_BUTTON_NAME")

UILobbyBackpackTips.Item = nil
UILobbyBackpackTips.nAvailableCount = nil
UILobbyBackpackTips.nMaxChooseCount = nil
UILobbyBackpackTips.nType = nil
UILobbyBackpackTips.nCurrentCount = -1
UILobbyBackpackTips.nStepSize = -1
UILobbyBackpackTips.pbLobbyDisplayItem = nil

local function SetButtonTxt(self, szButtonText)
    self.pWidgetRef.txtButton:SetText(szButtonText)
end

local function ShowTotalMoney(self, nCurrencyId, nTotalMoney)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.hboxTotalMoney:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.txtTotalMoney:SetText(nTotalMoney)

    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgTotalCurrency, szCurrencySmallIcon:load())
end

local function CollapsedTotalMoney(self)
    self.pWidgetRef.hboxTotalMoney:SetVisibility(ESlateVisibility.Collapsed)
end

local function SetTitle(self, szTitle)
    self.pWidgetRef.rtxtTitle:SetText(szTitle)
end

local function SetName(self, szName)
    self.pWidgetRef.txtName:SetText(szName)
end

local function SetChooseCount(self, nCount)
    local Item = self.Item
    local nCurrentMaxCount = self.nMaxChooseCount
    local nCurrentCount = MathUtil.Clamp(nCount, 1, nCurrentMaxCount)
    local nPercent = nCurrentCount / nCurrentMaxCount
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pgbCount:SetPercent(nPercent)
    pWidgetRef.sldrCount:SetValue(nPercent)

    local szChooseCount = nCurrentCount .."/".. self.nMaxChooseCount
    self.pWidgetRef.txtChooseCount:SetText(szChooseCount)

    if self.nType == UILobbyBackpackTips.Type.SELL then
        local nTotalMoney = nCurrentCount * Item:GetSellPrice()
        ShowTotalMoney(self, Item:GetCurrencyId(), nTotalMoney)
    end

    self.nCurrentCount = nCurrentCount
end


local function OnClickedBtnAdd(self)
    if self.nCurrentCount < self.nMaxChooseCount then
        SetChooseCount(self, self.nCurrentCount + 1)
    end
end

local function OnClickedBtnMinus(self)
    SetChooseCount(self, self.nCurrentCount - 1)
end

local function OnSldrCountValueChanged(self, nValue)
    local nCount = MathUtil.Round(nValue / self.nStepSize)
    SetChooseCount(self, nCount)
end

local function OnClickedBtnBack(self)
    self:CloseSelf()
end

local function OnClickedBtnDone(self)
    local Item = self.Item
    local nItemInstanceId = Item:GetInstanceId()
    local nCurrentCount = self.nCurrentCount
    self:CloseSelf()
    if self.nType == UILobbyBackpackTips.Type.USE then
        ItemSystem:RequestUseItem(nItemInstanceId, nCurrentCount)
    elseif self.nType == UILobbyBackpackTips.Type.SELL then
        if Item:GetCategory() == ItemCategoryDef.DECORATIVE_BUILDING then
            local HomelandItemSystem = HomelandSystem:GetSubSystem("HomelandItemSystem")
            HomelandItemSystem:RequestSellBuildingItem(nItemInstanceId, nCurrentCount)
        else
            ItemSystem:RequestSellItem(nItemInstanceId, nCurrentCount)
        end
    end
end

local function RefreshBaseInfo(self)
    local Item = self.Item
    self.pbLobbyDisplayItem:SetDisplayItemData(Item:GetTemplateId(), nil, false)
    SetName(self, Item:GetName())

    local nStackCount = self.nMaxChooseCount
    self.nStepSize = 1 / nStackCount
    self.pWidgetRef.sldrCount:SetStepSize(self.nStepSize)
    SetChooseCount(self, 1)
end

local function RefreshUseItemInfo(self)
    local pWidgetRef = self.pWidgetRef
    SetTitle(self, USE_TITLE)
    LobbyItemUiHelper.SetCountTitleAndCount(self.Item, pWidgetRef.txtCountTitle, pWidgetRef.txtCount)
    CollapsedTotalMoney(self)
    SetButtonTxt(self, USE_BUTTON_NAME)
end

local function RefreshSellItemInfo(self)
    local pWidgetRef = self.pWidgetRef
    SetTitle(self, SELL_TITLE)
    LobbyItemUiHelper.SetCountTitleAndCount(self.Item, pWidgetRef.txtCountTitle, pWidgetRef.txtCount)

    SetButtonTxt(self, SELL_BUTTON_NAME)
end

function UILobbyBackpackTips:OnCreate()
end

function UILobbyBackpackTips:OnDestroy()
end

function UILobbyBackpackTips:OnLoad()
    self.tbTimeCountDownHelper = SelfTimeCountDownHelper()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.pbLobbyDisplayItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyItem, UIDef.UP_LOBBY_DISPLAY_ITEM)
end

function UILobbyBackpackTips:OnEnter()
    local tbOpenArgs = self.tbOpenArgs
    local nType = tbOpenArgs.nType
    local Item = tbOpenArgs.Item
    local nAvailableCount = tbOpenArgs.nAvailableCount
    self:SetData(nType, Item, nAvailableCount)
end

function UILobbyBackpackTips:OnShow()

end

function UILobbyBackpackTips:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdd.OnClicked, self, OnClickedBtnAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnMinus.OnClicked, self, OnClickedBtnMinus)
    EventHelper:RegisterCppDelegate(pWidgetRef.sldrCount.OnValueChanged, self, OnSldrCountValueChanged)

    EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, OnClickedBtnBack)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDone.OnClicked, self, OnClickedBtnDone)
end

function UILobbyBackpackTips:SetData(nType, Item, nAvailableCount)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    self.Item = Item
    if nAvailableCount then
        self.nAvailableCount = nAvailableCount
    else
        self.nAvailableCount = Item:GetStackCount()
    end
    self.nType = nType
    if nType == UILobbyBackpackTips.Type.USE then
        self.nMaxChooseCount = math.min(self.nAvailableCount, LobbyItemIni.tbItemUse.nUseMax)
    elseif nType == UILobbyBackpackTips.Type.SELL then
        self.nMaxChooseCount = self.nAvailableCount
    end

    RefreshBaseInfo(self)

    if nType == UILobbyBackpackTips.Type.USE then
        RefreshUseItemInfo(self)
    elseif nType == UILobbyBackpackTips.Type.SELL then
        RefreshSellItemInfo(self)
    end
end

function UILobbyBackpackTips:Collapsed()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

return UILobbyBackpackTips
