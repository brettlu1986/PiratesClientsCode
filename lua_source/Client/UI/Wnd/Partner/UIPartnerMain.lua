-----------------------------------------------------
--File Name    : UIPartnerMain.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-05
--Description  : 伙伴主界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIPartnerMain = luaclass("UIPartnerMain", WndBase)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local TAB_WIDGET_NAME = {
    "pbPartnerEquipping",
    "pbPartnerBag",
    "pbPartnerSummoning",
}

local TAB_INDEX_PARTNER_BAG = 2

UIPartnerMain.pbWindowFrame = nil

local function OnRedDotVisibleChanged(self, bRedVisible)
    local TabBarHelper = self.pbWindowFrame:GeTabBarHelper()
    TabBarHelper:SetTipIconVisible(TAB_INDEX_PARTNER_BAG, bRedVisible)
end

local function RefreshRedDotVisible(self)
    local PartnerComponent = GamePlayerSelfHelper:Get().PartnerComponent
    local bRedVisible = PartnerComponent:GetPartnerRedDotVisible()
    OnRedDotVisibleChanged(self, bRedVisible)
end

function UIPartnerMain:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:BindWidgetSwitcher(self.pWidgetRef.wsContent, TAB_WIDGET_NAME)
    RefreshRedDotVisible(self)
end

function UIPartnerMain:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_PARTNER_RED_DOT_VISIBLE_CHANGED, self, OnRedDotVisibleChanged)
end

return UIPartnerMain