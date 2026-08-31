-----------------------------------------------------
--File Name    : UISailorMain.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-04
--Description  : 船水手界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISailorMain = luaclass("UISailorMain", WndBase)

local ClientEventDef = require("ClientEventDef")
local SailorRedDotDef = require("SailorRedDotDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local TAB_WIDGET_NAME = {
    "pbSailorEquipping",
    "pbSailorBag",
    "pbSailorSummoning",
}
local CURRENCY_ID = 1400003
local TAB_INDEX_SAILOR_SUMMONING = 3

UISailorMain.pbWindowFrame = nil

local function OnShowSailorSummon(self)
    self.pbWindowFrame:SetSelectedTab(TAB_INDEX_SAILOR_SUMMONING)
end

local function SetRedDotVisible(self, nIndex, bRedVisible)
    local TabBarHelper = self.pbWindowFrame:GeTabBarHelper()
    TabBarHelper:SetTipIconVisible(nIndex, bRedVisible)
end

local function RefreshRedDotVisible(self)
    local SailorComponent = GamePlayerSelfHelper:Get().SailorComponent
    for i=1, SailorRedDotDef.MAX do
        local bRedVisible = SailorComponent:GetSailorRedDotVisible(i)
        SetRedDotVisible(self, i, bRedVisible)
    end
end

local function OnRedDotVisibleChanged(self)
    RefreshRedDotVisible(self)
end

function UISailorMain:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:BindWidgetSwitcher(self.pWidgetRef.wsContent, TAB_WIDGET_NAME)
    self.pbWindowFrame:SetSpecialCurrency(CURRENCY_ID)
    RefreshRedDotVisible(self)
end

function UISailorMain:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHOW_SAILOR_SUMMONING, self, OnShowSailorSummon)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SAILOR_RED_DOT_VISIBLE_CHANGED, self, OnRedDotVisibleChanged)
end

return UISailorMain