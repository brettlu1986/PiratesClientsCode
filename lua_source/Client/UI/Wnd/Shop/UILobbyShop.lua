-----------------------------------------------------
--File Name    : UILobbyShop.lua
--Author       : zhiyuan
--Create Time  : 2019-07-19
--Description  : 商店的UI
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILobbyShop = luaclass("UILobbyShop", WndBase)
local ShopDataTable = require("ShopDataTable")
local SelfTabBarHelper = require("SelfTabBarHelper")
local ClientEventDef = require("ClientEventDef")
local UIUtils = require("UIUtils")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local CostCurrencyHelper = require("CostCurrencyHelper")
local UIToolTipHelper = require("UIToolTipHelper")

UILobbyShop.pbWindowFrame = nil
UILobbyShop.tbWindowFrameTabBarHelper = nil
UILobbyShop.tbTabBarHelper = nil
UILobbyShop.ulLobbyShopGoodsList = nil

UILobbyShop.tbShopIndexToShopId = nil
UILobbyShop.tbShopIdToShopIndex = nil
UILobbyShop.nShopIndex = nil
UILobbyShop.nShopTabIndex = nil

local DEFAULT_SHOP_INDEX = 1
local DEFAULT_SHOP_TAB_INDEX = 1
local SHOP_BUTTON_NAME_PREFEX = "pbTabButton"
local SHOP_TAB_BUTTON_NAME_PREFEX = "chk0"

local function GetCurrentShopId(self)
    return self.tbShopIndexToShopId[self.nShopIndex]
end

local function GetShopIndex(self, nShopId)
    return self.tbShopIdToShopIndex[nShopId]
end

local function RefreshGoods(self, bSort)
    local nShopId = GetCurrentShopId(self)
    self.ulLobbyShopGoodsList:RefreshGoods(nShopId, self.nShopTabIndex, bSort)
end

local function OnShopTabSelected(self, nShopTabIndex)
    if self.nShopTabIndex ~= nShopTabIndex then
        self.nShopTabIndex = nShopTabIndex
        
        RefreshGoods(self, true)
    end
end

local function RefreshTabNames(self)
    local nShopId = GetCurrentShopId(self)
    local tbTabNames = ShopDataTable:GetShopTabNames(nShopId)

    local tbTabBarHelper = self.tbTabBarHelper
    local pWidgetRef = self.pWidgetRef
    local nNameCount = #tbTabNames
    local nButtonCount = tbTabBarHelper:GetButtonCount()
    for i = 1, nButtonCount do
        if i <= nNameCount then
            local l10nName = tbTabNames[i]
            pWidgetRef[SHOP_TAB_BUTTON_NAME_PREFEX..i]:SetVisibility(ESlateVisibility.Visible)
            tbTabBarHelper:SetTabText(i, l10nName)
        else
            pWidgetRef[SHOP_TAB_BUTTON_NAME_PREFEX..i]:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

local function OnShopChanged(self, nShopIndex)
    if self.nShopIndex ~= nShopIndex then
        self.nShopIndex = nShopIndex
        self.nShopTabIndex = DEFAULT_SHOP_TAB_INDEX
        UIToolTipHelper:HideTip()
        RefreshTabNames(self)
        self.tbTabBarHelper:SelectByIndex(self.nShopTabIndex)
        RefreshGoods(self, true)
    end
end

local function InitFirstShop(self)
    if self.tbOpenArgs.nDefaultShop then
        self.nShopIndex = GetShopIndex(self, self.tbOpenArgs.nDefaultShop)
    else
        self.nShopIndex = DEFAULT_SHOP_INDEX
    end
    self.tbWindowFrameTabBarHelper:SelectByIndex(self.nShopIndex)

    self.nShopTabIndex = DEFAULT_SHOP_TAB_INDEX
    RefreshTabNames(self)
    self.tbTabBarHelper:SelectByIndex(self.nShopTabIndex)

    RefreshGoods(self, true)
end

local function InitShopIndexToShopId(self)
    self.tbShopIndexToShopId = {}
    self.tbShopIdToShopIndex = {}
    local tbShopTemplates = ShopDataTable:GetAllShopInfoArray()
    for i, v in ipairs(tbShopTemplates) do
        self.tbShopIndexToShopId[i] = v.nShopId
        self.tbShopIdToShopIndex[v.nShopId] = i
    end
end

local function RefreshShopNames(self)
    local tbWindowFrameTabBarHelper = self.tbWindowFrameTabBarHelper
    local pWidgetRef = self.pWidgetRef
    local nButtonCount = tbWindowFrameTabBarHelper:GetButtonCount()
    local tbShopTemplates = ShopDataTable:GetAllShopInfoArray()
    for i = 1, nButtonCount do
        local tbShopTemplate = tbShopTemplates[i]
        if tbShopTemplate == nil then
            pWidgetRef[SHOP_BUTTON_NAME_PREFEX..i]:SetVisibility(ESlateVisibility.Collapsed)
        else
            pWidgetRef[SHOP_BUTTON_NAME_PREFEX..i]:SetVisibility(ESlateVisibility.Visible)
            tbWindowFrameTabBarHelper:SetTabText(i, tbShopTemplate.l10nName)
        end
    end
end

local function OnGoShoppingSuccess(self)
    RefreshGoods(self, false)
end

local function OnRefreshShop(self)
    RefreshGoods(self, true)
end

local function OnBack(self)
    self:CloseSelf()
    local tbSubSystem = LobbySystem:GetActiveSub()
    if tbSubSystem then
        UIUtils.BottomMenuSelect(tbSubSystem.nSubType)
    end
    --LobbySystem:ReturnToPrevSub()
end

local function OnLobbySubsystemActivate(self, nType)
    if nType == LobbySubTypeDef.AWARD then
        self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UILobbyShop:OnPause()
    local nSubSystem = LobbySystem:GetActiveSub()
    log("UILobbyShop:OnPause:nSubSystem.nSubType=",nSubSystem.nSubType)
    if nSubSystem and (nSubSystem.nSubType == LobbySubTypeDef.SHOW or nSubSystem.nSubType == LobbySubTypeDef.AWARD --[[or nSubSystem.nSubType == LobbySubTypeDef.SHIP--]]) then
        self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UILobbyShop:OnResume()
    log("UILobbyShop:OnResume")
    if not self.pWidgetRef:IsVisible() then
        self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        UIUtils.BottomMenuUnselectAll()
    end
end

function UILobbyShop:OnLoad()
    local UILogicHelper = self.UILogicHelper
    self.ulLobbyShopGoodsList = UILogicHelper:CreateUILogic("ULLobbyShopGoodsList")

    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetSelectedTabChanged(OnShopChanged, self)
    self.tbWindowFrameTabBarHelper = self.pbWindowFrame:GeTabBarHelper()

    self.tbTabBarHelper = SelfTabBarHelper()
    local pWidgetRef = self.pWidgetRef
    self.tbTabBarHelper:Init(self, pWidgetRef.hboxTabs)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnShopTabSelected, self)
    self.pbWindowFrame:SetBackDelegate(OnBack, self)

    InitShopIndexToShopId(self)
end

function UILobbyShop:OnUnload()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

function UILobbyShop:OnShow()
    RefreshShopNames(self)
    InitFirstShop(self)
    UIUtils.BottomMenuUnselectAll()
    self:PlayAnimation("animShopStart", 0, 1,  EUMGSequencePlayMode.Forward, 1)
end

local function OnShopNotEnoughCurrency(self, tbShoppingGoods)
    if not tbShoppingGoods.currency_auto_exchange then
        CostCurrencyHelper:FirstCostFailed()
    else
        CostCurrencyHelper:SecondCostFailed()
    end
end

function UILobbyShop:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_GO_SHOPPING_SUCCESS, self, OnGoShoppingSuccess)
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_SHOP_FINISH, self, OnRefreshShop)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_SUB_SYSTEM_ACTIVATE, self, OnLobbySubsystemActivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHOP_NOT_ENOUGH_CURRENCY, self, OnShopNotEnoughCurrency)
end

return UILobbyShop
