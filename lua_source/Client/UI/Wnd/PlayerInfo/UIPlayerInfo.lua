-----------------------------------------------------
--File Name    : UIPlayerInfo.lua
--Author       : WuJizhou
--Create Time  : 3/21/2019, 2:55:56 PM
--Description  : UIPlayerInfo
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local StatsSystem = require("StatsSystem")
local SeasonSystem = require("SeasonSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIUtils = require("UIUtils")

local UIPlayerInfo = luaclass("UIPlayerInfo", WndBase)

UIPlayerInfo.nPlayerId = nil
UIPlayerInfo.ulPlayerInfo = nil

local tbTabPrefabWidgetNames =
{
    "pbPlayerSystem01",
    "pbPlayerSystem02",
    "pbPlayerSystem03",
    "pbPlayerSystem04"
}


-- local function OnTabBarSelectedChanged(self, nTabIndex)
--     -- local nLastIndex = self.nCurrentTabCategory
--     -- self.nCurrentTabCategory = nTabIndex
--     -- self.tbULTabContent[nLastIndex]:Deactivate()
--     -- self.tbULTabContent[nTabIndex]:Activate()
-- end

local function InitWindowFrame(self)
    local pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    pbWindowFrame:BindWidgetSwitcher(self.pWidgetRef.wsContent, tbTabPrefabWidgetNames)
    self.pbWindowFrame = pbWindowFrame
end

local function InitParam(self)
    self.nPlayerId = self.tbOpenArgs.nPlayerId
    if not self.nPlayerId then
        logerror("UIPlayerInfo", "InitParam failed, nPlayerId is nil!")
    end
    self.pbWindowFrame:SetSelectedTab(1)
    SeasonSystem:RequestGetSeasonPointRanking()
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local bGet = true
    if self.nPlayerId == tbPlayerSelf.nPlayerId then
        StatsSystem:RequestGetHistoryStats(self.nPlayerId)
        local SeasonComponent = SeasonSystem:GetComponent()
        local tbStats = SeasonComponent:GetSeasonStats()
        local nCurSeasonId = SeasonComponent:GetSeasonId()
        bGet = tbStats == nil or tbStats[nCurSeasonId] == nil
        self.pbWindowFrame:HideCurrency(false)
    else
        UIUtils.BottomMenuHide(true)
        self.pbWindowFrame:HideCurrency(true)
    end
    if bGet then
        SeasonSystem:RequestGetSeasonStats(self.nPlayerId)
    end
end

local function InitUL(self)
    self.ulPlayerInfo = self.UILogicHelper:CreateUILogic("ULPlayerInfo")
end



----------life cycle----------

-- function UIPlayerInfo:OnCreate()
-- end

function UIPlayerInfo:OnLoad()
    InitUL(self)
    InitWindowFrame(self)
end

function UIPlayerInfo:OnEnter()
    InitParam(self)
    UIUtils.BottomMenuUnselectAll()
end

-- function UIPlayerInfo:OnShow()
-- end

-- function UIPlayerInfo:OnHide()
-- end

function UIPlayerInfo:OnExit()
    UIUtils.BottomMenuHide(false)
    local func = self.tbOpenArgs.callOnExit
    if func then
        func()
    end
end

-- function UIPlayerInfo:OnDestroy()
-- end

-- function UIPlayerInfo:OnUnload()
-- end

-- function UIPlayerInfo:OnBindEvent(EventHelper)
-- end

-- function UIPlayerInfo:OnUnbindEvent(EventHelper)
-- end

-- function UIPlayerInfo:OnLoadLevelFinished()
-- end


return UIPlayerInfo