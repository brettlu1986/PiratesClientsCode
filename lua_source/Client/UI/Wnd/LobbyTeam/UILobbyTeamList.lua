-----------------------------------------------------
--File Name    : UILobbyTeamList.lua
--Author       : Ran Jie
--Create Time  : 2020-05-09
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILobbyTeamList = luaclass("UILobbyTeamList", WndBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local FriendSystem = require("FriendSystem")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local Proto = require("ClientProtoNames")
local StatsSystem = require("StatsSystem")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local FriendIni = require("FriendIni")
local L10N = require("L10N")
local SelfTabBarHelper = require("SelfTabBarHelper")

local DEFAULT_TAB_INDEX = 1
local SELF_HIT_TEST_INVISIBLE = ESlateVisibility.SelfHitTestInvisible
local COLLAPSED = ESlateVisibility.Collapsed
local HIT_TEST_INVISIBLE = ESlateVisibility.HitTestInvisible

UILobbyTeamList.tbTabBarHelper = nil
UILobbyTeamList.tbListHelper = nil
UILobbyTeamList.tbMemberTitlePrefab = nil
UILobbyTeamList.tbListData = nil
UILobbyTeamList.nTabIndex = nil

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
    if self.tbTabBarHelper.nSelectedIdx ~= 1 then
        return
    end
    local FriendComponent = FriendSystem:GetComponent()
    local tbFriendSummaries = FriendComponent:GetFriendSummaries()
    -- local tbFriendsData = {}
    -- for k, v in ipairs(tbFriends) do
    --     local tbData = {}
    --     for key, value in pairs(v.player_summary) do
    --         tbData[key] = value
    --     end
    --     table.insert(tbFriendsData, tbData)
    -- end
    self.tbListData = tbFriendSummaries
    self.pWidgetRef.vbxNearbyEmpty:SetVisibility(COLLAPSED)
    if #tbFriendSummaries == 0 then
        self.pWidgetRef.btnFriendEmpty:SetVisibility(ESlateVisibility_Visible)
    else
        self.pWidgetRef.btnFriendEmpty:SetVisibility(ESlateVisibility_Collapsed)
    end
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
    self.pWidgetRef.vbxNearbyEmpty:SetVisibility(COLLAPSED)
    self.pWidgetRef.btnFriendEmpty:SetVisibility(COLLAPSED)
    RefreshListData(self)
end

local function RefreshRecentlyStatusList(self, tbSummarys)
    if self.tbTabBarHelper.nSelectedIdx ~= 2 then
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
    self.pWidgetRef.vbxNearbyEmpty:SetVisibility(HIT_TEST_INVISIBLE)
    self.pWidgetRef.btnFriendEmpty:SetVisibility(COLLAPSED)
    RefreshListData(self)
end

local function OnTeamChanged(self, tbPacket)
    if self.tbTabBarHelper.nSelectedIdx == 1 then
        if tbPacket.change_type == Proto.ChangeType.DISMISS then
            RefreshListData(self)
        else
            RefreshListData(self, tbPacket.id)
        end
    elseif self.tbTabBarHelper.nSelectedIdx == 2 then
        RefreshRecentlyList(self, FriendSystem:GetRecentlyTeam())
    end
end

local function OnTeamMemberSummaryChanged(self, tbSummaryArray)
    for k, v in ipairs(tbSummaryArray) do
        RefreshListData(self, v.id)
    end
end

local function OnCheckBoxSelectChanged(self, nIndex)
    UIUtils.DestroyAllCommonBtnList()
    local pTipTextWidget = self.pWidgetRef.txtTip
    if nIndex == 1 then
        RefreshFriendList(self)
        local l10nStr = UISetUtils.GetL10NTextByKey("UI_RELATION_TIPS_ORDER")
        l10nStr = L10N:Format(l10nStr, FriendIni.nOrderInimacy)
        pTipTextWidget:SetText(l10nStr)
        pTipTextWidget:SetVisibility(SELF_HIT_TEST_INVISIBLE)
    elseif nIndex == 2 then
        pTipTextWidget:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_RECENTLY_PLAYER"))
        pTipTextWidget:SetVisibility(SELF_HIT_TEST_INVISIBLE)
        -- StatsSystem:RequestGetHistoryStats()
        RefreshRecentlyList(self, FriendSystem:GetRecentlyTeam())
    elseif nIndex == 3 then
        pTipTextWidget:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_NEARBY_PLAYER"))
        pTipTextWidget:SetVisibility(SELF_HIT_TEST_INVISIBLE)
        RefreshNearbyList(self)
    end
end

local function OnMouseButtonDown(self)
    self:CloseSelf()
    UIUtils.DestroyAllCommonBtnList()
    return WidgetBlueprintLibrary.Unhandled()
end

local function OnFriendEmptyClicked(self)
    self:CloseSelf()
    UIManager:OpenWnd(UIDef.UI_LOBBY_FRIEND, {nSelectTab = 4})
end

function UILobbyTeamList:OnCreate()
    self.tbListHelper = SelfVerticalListHelper()
end
function UILobbyTeamList:OnDestroy()
    self.tbListHelper:Uninit()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

function UILobbyTeamList:OnLoad()
    self.tbMemberTitlePrefab = {}
    local pWidgetRef = self.pWidgetRef
    self.PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.hbxTab, -1)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnCheckBoxSelectChanged, self)
    self.tbListHelper:Init(self, pWidgetRef.vlistPlayer, nil)
end


function UILobbyTeamList:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnFriendEmpty.OnClicked, self, OnFriendEmptyClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.bdrBg.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS, self, RefreshFriendList)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED, self, OnTeamChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MEMBER_SUMMARY_CHANGED, self, OnTeamMemberSummaryChanged)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_RECENT_TEAM, self, RefreshRecentlyList)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_RECENT_TEAM_STATE, self, RefreshRecentlyStatusList)
    
end

function UILobbyTeamList:OnShow()
    self.tbTabBarHelper:SelectByIndex(DEFAULT_TAB_INDEX, true)
    StatsSystem:RequestGetHistoryStats()
    self:PlayAnimation("animTeamListIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end



return UILobbyTeamList