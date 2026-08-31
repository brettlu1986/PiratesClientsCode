-----------------------------------------------------
--File Name    : ULLobbySeason.lua
--Author       : Ranjie
--Create Time  : 2020-4-20
--Description  : ULLobbySeason
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbySeason = luaclass("ULLobbySeason", UILogicBase)


local ClientEventDef = require("ClientEventDef")
local LobbySubTypeDef = require("LobbySubTypeDef")
local LobbySystem = require("LobbySystem")
local SeasonSystem = require("SeasonSystem")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")

local function OnClickedSeasonPass(self)
    local Component = SeasonSystem:GetComponent()
    if Component:GetBattlePass() then
        LobbySystem:Activate(LobbySubTypeDef.SEASON, {szUIName = UIDef.UI_SEASON_BATTLEPASS})
    else
        UIUtils.ShowToast(UITextDef.LOBBY_NET_WORK_WEAKNESS)
    end
end

local function OnClickedSeasonRank(self)
    local Component = SeasonSystem:GetComponent()
    if Component:GetBattlePass() then
        LobbySystem:Activate(LobbySubTypeDef.SEASON, {szUIName = UIDef.UI_SEASON_RANK})
    else
        UIUtils.ShowToast(UITextDef.LOBBY_NET_WORK_WEAKNESS)
    end
end

local function OnRefreshSeasonRankDailyChest(self)
    local Component = SeasonSystem:GetComponent()
    if Component ~= nil then
        self.pWidgetRef.btnSeasonRank:HideTipIcon(not Component:IsHasDailyChest())
    else
        self.pWidgetRef.btnSeasonRank:HideTipIcon(true)
    end
end

local function OnRefreshSeasonPass(self)
    local Component = SeasonSystem:GetComponent()
    local pWidgetRef = self.pWidgetRef
    if Component:HasBattleTierAwards() or Component:GetChallengeAwardStatus() then
        pWidgetRef.btnSeasonPass:HideTipIcon(false)
    else
        pWidgetRef.btnSeasonPass:HideTipIcon(true)
    end
end

function ULLobbySeason:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSeasonPass.OnClicked, self, OnClickedSeasonPass)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSeasonRank.OnClicked, self, OnClickedSeasonRank)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_CHALLENGE_AWARD_STATUS, self, OnRefreshSeasonPass)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK, self, OnRefreshSeasonRankDailyChest)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_PASS, self, OnRefreshSeasonPass)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_GET_SEASON_DATA, self, OnRefreshSeasonPass)
end

function ULLobbySeason:OnShow()
    OnRefreshSeasonPass(self)
    OnRefreshSeasonRankDailyChest(self)
end

return ULLobbySeason