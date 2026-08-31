-----------------------------------------------------
--File Name    : UILobbyBackpack.lua
--Author       : zhiyuan
--Create Time  : 2019-02-25
--Description  : 大厅的背包界面
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILobbyBackpack = luaclass("UILobbyBackpack", WndBase)
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIUtils = require("UIUtils")

UILobbyBackpack.pbWindowFrame = nil
UILobbyBackpack.ulLobbyBackpackItems = nil

local ALL_ITEM_TAB_INDEX = 1

local function OnTabChanged(self, nTabIndex)
    self.ulLobbyBackpackItems:RefreshItems(nTabIndex)
    if nTabIndex == ALL_ITEM_TAB_INDEX then
        local PlayerNewItemRecordComponent = GamePlayerSelfHelper:Get().PlayerNewItemRecordComponent
        PlayerNewItemRecordComponent:UnmarkHasNewItemsInBackpack()
    end
end

local function HasNewInBackpack(self)
    local PlayerNewItemRecordComponent = GamePlayerSelfHelper:Get().PlayerNewItemRecordComponent
    return PlayerNewItemRecordComponent:HasNewItemInBackpack()
end

local function RefreshTipIcon(self)
    local tbTabBarHelper = self.pbWindowFrame:GeTabBarHelper()
    -- 策划需求是只有全部的标签页需要显示是否有新道具的黄点
    local bVisible = HasNewInBackpack(self)
    tbTabBarHelper:SetTipIconVisible(ALL_ITEM_TAB_INDEX, bVisible)
end

local function OnBack(self)
    UIUtils.BottomMenuSelect(1, true)
end

function UILobbyBackpack:OnLoad()
    local UILogicHelper = self.UILogicHelper
    self.ulLobbyBackpackItems = UILogicHelper:CreateUILogic("ULLobbyBackpackItems")
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetSelectedTabChanged(OnTabChanged, self)
    self.pbWindowFrame:SetBackDelegate(OnBack, self)
end

function UILobbyBackpack:OnShow()
    self.ulLobbyBackpackItems:RefreshItems(ALL_ITEM_TAB_INDEX)
    RefreshTipIcon(self)
    self:PlayAnimation("animLobbyBackpackIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UILobbyBackpack:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_NEW_STATE_IN_BACKPACK, self, RefreshTipIcon)
end


return UILobbyBackpack
