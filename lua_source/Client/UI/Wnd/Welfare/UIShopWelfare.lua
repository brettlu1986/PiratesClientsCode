local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIShopWelfare = luaclass("UIShopWelfare", WndBase)

local WelfareDataTable = require("WelfareDataTable")
local SelfListHelperNew = require("SelfListHelperNew")
local ClientEventDef = require("ClientEventDef")
local WelfareHelper = require("WelfareHelper")

UIShopWelfare.pbWindowFrame = nil
UIShopWelfare.tbWindowFrameTabBarHelper = nil
UIShopWelfare.nTabIndex = -1

local TAB_PREFIX_NAME = "pbTabButton"
local DEFAULT_TAB = 1

local function RefreshWelfareNames(self)
    local tbWindowFrameTabBarHelper = self.tbWindowFrameTabBarHelper
    local pWidgetRef = self.pWidgetRef
    local nButtonCount = tbWindowFrameTabBarHelper:GetButtonCount()
    local tbWelfareTemplates = WelfareDataTable:GetAllWelfareData()

    local bCanGet = WelfareHelper.HasCanGetWelfare()

    for i = 1, nButtonCount do
        local tbWelfareTemplate = tbWelfareTemplates[i]
        if tbWelfareTemplate == nil then
            pWidgetRef[TAB_PREFIX_NAME..i]:SetVisibility(ESlateVisibility.Collapsed)
        else
            pWidgetRef[TAB_PREFIX_NAME..i]:SetVisibility(ESlateVisibility.Visible)
            tbWindowFrameTabBarHelper:SetTabText(i, tbWelfareTemplate.l10nName)
            tbWindowFrameTabBarHelper:SetTipIconVisible(i, bCanGet)
        end
    end
end

local function RefreshTabItems(self)
    local tbWelfareTemplates = WelfareDataTable:GetAllWelfareData()
    local tbItems = tbWelfareTemplates[self.nTabIndex].tbItems
    self.ListHelper:SetData(tbItems)
    -- self.ListHelper:ScrollToTopLeft(false)
end

local function RefreshCardItem(self, tbVipCard)
    WelfareHelper.AddWelfareItemData(tbVipCard)

    local bCanGet = WelfareHelper.HasCanGetWelfare()
    self.EventHelper:FireEvent(ClientEventDef.EV_REFRESH_WELFARE_TIP_ICON, bCanGet)
    RefreshWelfareNames(self)
    RefreshTabItems(self)
end

local function OnWelfareTabChanged(self, nTab)
    if self.nTabIndex ~= nTab then
        self.nTabIndex = nTab
        RefreshTabItems(self)
    end
end

function UIShopWelfare:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetSelectedTabChanged(OnWelfareTabChanged, self)
    self.tbWindowFrameTabBarHelper = self.pbWindowFrame:GeTabBarHelper()

    self.ListHelper = SelfListHelperNew()
    self.ListHelper:Init(self, self.pWidgetRef.listItems)
end

function UIShopWelfare:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UIShopWelfare:OnShow()
    RefreshWelfareNames(self)
    OnWelfareTabChanged(self, DEFAULT_TAB)
end

function UIShopWelfare:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_VIP_CARD_ITEM, self, RefreshCardItem)
end

return UIShopWelfare
