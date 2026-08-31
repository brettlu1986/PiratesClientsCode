-----------------------------------------------------
--File Name    : UPPlayerRecentGameScore.lua
--Author       : WuJizhou
--Create Time  : 3/21/2019, 8:38:30 PM
--Description  : UPPlayerRecentGameScore
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPPlayerRecentGameScore = luaclass("UPPlayerRecentGameScore", PrefabBase)
local SelfVerticalListHelper  = require("SelfVerticalListHelper")
local StatsSystem = require("StatsSystem")
local UIUtils = require("UIUtils")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

UPPlayerRecentGameScore.nPlayerId      = nil
UPPlayerRecentGameScore.tbListHelper   = nil
UPPlayerRecentGameScore.tbPacket       = nil

local function OnRefreshStats(self, tbPacket, nCount, bSuccess)
    self.tbPacket = tbPacket
    local pWidgetRef = self.pWidgetRef
    if tbPacket == nil 
        or tbPacket.player_id ~= self.nPlayerId then
        if bSuccess == false then
            UIUtils.HideLoadingDialog()
        else
            UIUtils.ShowLoadingDialog()
            pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
            StatsSystem:RequestGetHistoryStats(self.nPlayerId)
        end
    else
        UIUtils.HideLoadingDialog()
        if bSuccess then
            pWidgetRef:SetVisibility(ESlateVisibility.Visible)
            self.tbListHelper:SetData(tbPacket.stats)
            if #tbPacket.stats == 0 then
                pWidgetRef.vbBlank:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            else
                pWidgetRef.vbBlank:SetVisibility(ESlateVisibility.Collapsed)
            end
        end
    end
end

function UPPlayerRecentGameScore:OnCreate()
    self.ulPlayerInfo = self.Owner.ulPlayerInfo
    self.tbListHelper = SelfVerticalListHelper()
end

function UPPlayerRecentGameScore:OnEnter()
    self.nPlayerId = self.Owner.nPlayerId
end

function UPPlayerRecentGameScore:Activate()
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf.nPlayerId == self.nPlayerId then
        local Component = StatsSystem:GetComponent()
        local tbPacket = {}
        tbPacket.stats = Component:GetHistoryStats()
        tbPacket.last_evaluated_key = Component:GetLastEvaluatedKey()
        tbPacket.player_id = self.nPlayerId
        if tbPacket.stats ~= nil then
            OnRefreshStats(self, tbPacket, #tbPacket.stats, true)
        else
            OnRefreshStats(self, self.tbPacket)
        end
    else
        OnRefreshStats(self, self.tbPacket)
    end
end

function UPPlayerRecentGameScore:OnDestroy()
    -- local Component = StatsSystem:GetComponent()
    -- if Component ~= nil then
    --     Component:ClearHistoryStats()
    -- end

    self.tbListHelper:Uninit()
    self.tbListHelper = nil
    self.nPlayerId = nil
    self.ulPlayerInfo = nil
end

function UPPlayerRecentGameScore:OnLoad()
    self.tbListHelper:Init(self, self.pWidgetRef.kmList)
 end

function UPPlayerRecentGameScore:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_HISTORY_STATS, self, OnRefreshStats)   
end

return UPPlayerRecentGameScore