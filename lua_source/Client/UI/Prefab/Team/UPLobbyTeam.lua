-----------------------------------------------------
--File Name    : UPLobbyTeam.lua
--Author       : Ran Jie
--Create Time  : 2019-03-12
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyTeam = luaclass("UPLobbyTeam", PrefabBase)


local SelfTabBarHelper = require("SelfTabBarHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local FriendSystem = require("FriendSystem")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local Proto = require("ClientProtoNames")
local StatsSystem = require("StatsSystem")
local UIUtils = require("UIUtils")

local DEFAULT_TAB_INDEX = 1
local SELF_HIT_TEST_INVISIBLE = ESlateVisibility.SelfHitTestInvisible
local COLLAPSED = ESlateVisibility.Collapsed
local HIT_TEST_INVISIBLE = ESlateVisibility.HitTestInvisible

UPLobbyTeam.tbTabBarHelper = nil
UPLobbyTeam.tbListHelper = nil
UPLobbyTeam.tbMemberTitlePrefab = nil
UPLobbyTeam.pbPopMenu = nil
UPLobbyTeam.tbListData = nil
UPLobbyTeam.nTabIndex = nil

local Refresh_Field = {
    ["fashion"] = 1,
    ["status"] = 1,
    ["status_time"] = 1,
    ["dungeon_id"] = 1,
    ["dungeon_team_mode"] = 1,
    ["team_size"] = 1
}

local function RefreshListData(self, nPlayerId)
    if not self.tbListData or #self.tbListData == 0 then
        self.tbListHelper:SetData(self.tbListData)
        return
    end
    if nPlayerId then
        local nRefreshIndex = nil
        for k, v in ipairs(self.tbListData) do
            if v.id == nPlayerId then
                nRefreshIndex = k
                break
            end
        end
        if nRefreshIndex then
            self.tbListHelper:RefreshItemByIndex(nRefreshIndex)
        end
    else
        self.tbListHelper:SetData(self.tbListData)
    end
end

local function RefreshFriendList(self)
    if self.nTabIndex ~= 1 then
        return
    end
    local FriendComponent = FriendSystem:GetComponent()
    local tbFriendSummaries = FriendComponent:GetFriendSummaries()
    -- local tbFriendsData = {}
    -- for k, v in ipairs(tbFriendSummaries) do
    --     local tbData = {}
    --     for key, value in pairs(v.player_summary) do
    --         tbData[key] = value
    --     end
    --     -- local tbPlayerSummary = v.player_summary
    --     -- tbData.id = tbPlayerSummary.id
    --     -- tbData.name = tbPlayerSummary.name
    --     -- tbData.avatar_id = tbPlayerSummary.avatar_id
    --     -- tbData.level = tbPlayerSummary.level
    --     -- tbData.exp = tbPlayerSummary.exp
    --     -- tbData.rank = tbPlayerSummary.rank
    --     -- tbData.fashion = tbPlayerSummary.fashion
    --     -- tbData.status_time = tbPlayerSummary.status_time
    --     table.insert(tbFriendsData, tbData)
    -- end
    self.tbListData = tbFriendSummaries
    self.pWidgetRef.vbxEmpty:SetVisibility(COLLAPSED)
    RefreshListData(self)
end

local function RefreshRecentlyList(self, tbTeam)
    if tbTeam == nil then
        self.tbListData = {}
    else
        self.tbListData = tbTeam
        local tbPlayerIds = {}
        for i, v in ipairs(tbTeam) do
            table.insert(tbPlayerIds, v.id)
        end
        if #tbPlayerIds > 0 then
            FriendSystem:RequestPlayerSummarier(tbPlayerIds)
        end
    end
    self.pWidgetRef.vbxEmpty:SetVisibility(COLLAPSED)
    RefreshListData(self)
end

local function RefreshRecentlyStatusList(self, tbSummarys)
    if self.nTabIndex ~= 2 then
        return
    end
    local fnGetCurSummary = function(nId)
        for i, v in ipairs(tbSummarys) do
            if v.id == nId then
                return v
            end
        end
    end
    for i, v in ipairs(self.tbListData) do
        local tbSummary = fnGetCurSummary(v.id)
        if tbSummary then
            for key, value in pairs(tbSummary) do
                if Refresh_Field[key] ~= nil then
                    v[key] = value
                end
            end
        end
    end
    RefreshListData(self)
end

local function RefreshNearbyList(self)
    self.tbListData = {}
    self.pWidgetRef.vbxEmpty:SetVisibility(HIT_TEST_INVISIBLE)
    RefreshListData(self)
end

local function OnTeamChanged(self, tbPacket)
    if tbPacket.change_type == Proto.ChangeType.DISMISS then
        RefreshListData(self)
    else
        RefreshListData(self, tbPacket.id)
    end
end

local function OnTeamMemberSummaryChanged(self, tbSummary)
    RefreshListData(self, tbSummary.id)
end

local function OnTabSelected(self, nTabIndex)
    if self.nTabIndex == nTabIndex then
        return
    end
    self.nTabIndex = nTabIndex
    --self.pbPopMenu:HideMenu()
    UIUtils.DestroyAllCommonBtnList()
    local pTipTextWidget = self.pWidgetRef.txtTip
    if nTabIndex == 1 then
        RefreshFriendList(self)
        pTipTextWidget:SetVisibility(COLLAPSED)
    elseif nTabIndex == 2 then
        pTipTextWidget:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_RECENTLY_PLAYER"))
        pTipTextWidget:SetVisibility(SELF_HIT_TEST_INVISIBLE)
        -- StatsSystem:RequestGetHistoryStats()
        RefreshRecentlyList(self, FriendSystem:GetRecentlyTeam())
    elseif nTabIndex == 3 then
        pTipTextWidget:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_NEARBY_PLAYER"))
        pTipTextWidget:SetVisibility(SELF_HIT_TEST_INVISIBLE)
        RefreshNearbyList(self)
    end
end

function UPLobbyTeam:OnCreate()
    self.tbListHelper = SelfVerticalListHelper()
end
function UPLobbyTeam:OnDestroy()
    self.tbListHelper:Uninit()
end

function UPLobbyTeam:OnLoad()
    self.tbMemberTitlePrefab = {}
    self.tbTabBarHelper = SelfTabBarHelper()
    local pWidgetRef = self.pWidgetRef
    self.tbTabBarHelper:Init(self, pWidgetRef.hbxTab)
    self.tbListHelper:Init(self, pWidgetRef.vlistPlayer, { })
    --local PrefabHelper = self.PrefabHelper
    --self.pbPopMenu = PrefabHelper:BindPrefab(pWidgetRef.pbPopMenu)
end

function UPLobbyTeam:OnUnload()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

function UPLobbyTeam:OnBindEvent(EventHelper)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnTabSelected, self)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS, self, RefreshFriendList)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED, self, OnTeamChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MEMBER_SUMMARY_CHANGED, self, OnTeamMemberSummaryChanged)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_RECENT_TEAM, self, RefreshRecentlyList)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_RECENT_TEAM_STATE, self, RefreshRecentlyStatusList)
end

function UPLobbyTeam:OnShow()
    --OnTabSelected(self, DEFAULT_TAB_INDEX)
end

function UPLobbyTeam:ShowTeam()
    self.tbTabBarHelper:SelectByIndex(DEFAULT_TAB_INDEX, true)
    StatsSystem:RequestGetHistoryStats()
end

function UPLobbyTeam:HideTeam()
    self.nTabIndex = nil
end

return UPLobbyTeam