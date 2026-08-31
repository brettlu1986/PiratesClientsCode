-----------------------------------------------------
--File Name    : UIHomePack.lua
--Author       : zhiyuan
--Create Time  : 2019-05-06
--Description  : 家园仓库界面
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIHomePack = luaclass("UIHomePack", WndBase)
local ClientEventDef = require("ClientEventDef")

UIHomePack.nTabIndex = nil
UIHomePack.pbWindowFrame = nil
UIHomePack.ulHomePackItems = nil
UIHomePack.ulHomeExchange = nil

local ITEMS_INDEX = 1
local EXCHANGE_INDEX = 2

local function SetShowIndex(self, nIndex)
    self.pWidgetRef.wsContent:SetActiveWidgetIndex(nIndex)
end

local function OnTabChanged(self, nTabIndex)
    self.nTabIndex = nTabIndex
    if nTabIndex == ITEMS_INDEX then
        self.ulHomePackItems:RefreshItems()
    elseif nTabIndex == EXCHANGE_INDEX then
        self.ulHomeExchange:Refresh()
        SetShowIndex(self, nTabIndex - 1)
    end
end

local function OnItemChanged(self)
    local nTabIndex = self.nTabIndex
    if nTabIndex == ITEMS_INDEX then
        self.ulHomePackItems:OnItemChanged()
    elseif nTabIndex == EXCHANGE_INDEX then
        self.ulHomeExchange:OnItemChanged()
    end
end

function UIHomePack:OnLoad()
    local UILogicHelper = self.UILogicHelper
    self.ulHomePackItems = UILogicHelper:CreateUILogic("ULHomePackItems")
    self.ulHomeExchange = UILogicHelper:CreateUILogic("ULHomeExchange")
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetSelectedTabChanged(OnTabChanged, self)
end

function UIHomePack:OnShow()
    OnTabChanged(self, ITEMS_INDEX)
end

function UIHomePack:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_REMOVE_LOBBY_ITEM, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT, self, OnItemChanged)
end

return UIHomePack