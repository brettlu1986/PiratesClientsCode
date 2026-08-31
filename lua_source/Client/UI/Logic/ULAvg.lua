-----------------------------------------------------
--File Name    : ULAvg.lua
--Description  : 大厅界面的历险模块
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULAvg= luaclass("ULAvg", UILogicBase)

local ClientEventDef = require("ClientEventDef")

local AVGDataTable = require("AVGDataTable")
local DungeonDataTable = require("DungeonDataTable")

local SelfVerticalListHelper = require("SelfVerticalListHelper")

local UIUtils = require("UIUtils")

local SelfTimerHelper = require("SelfTimerHelper")

--local ArenaSystem = require("ArenaSystem")

local START_COOP_TEXT = "开始战斗"
local AVOID_ACTIVE_IN_MATCHMAKING = "匹配中禁止该操作"

local tbTimerHelper = nil
local nBeginTime = 0

ULAvg.ListHelper = nil

local function ClearTimer(self)
    if tbTimerHelper ~= nil then
        tbTimerHelper:ClearAllTimer()
        tbTimerHelper = nil
    end
end

local function SetMatchTimeText(self)
    nBeginTime = nBeginTime + 1

    local szMinutes = string.format("%02d", math.floor(nBeginTime / 60))
    local szSeconds = string.format("%02d", nBeginTime % 60)

    local szText = szMinutes .. ":" .. szSeconds
    if self.pWidgetRef then
        self.pWidgetRef.TextBlock_Timer:SetText(szText)
    end
end

local function ShowMatchTime(self)
    nBeginTime = 0
    if not tbTimerHelper then tbTimerHelper = SelfTimerHelper() end
    tbTimerHelper:NewTimerMethod(self, SetMatchTimeText, 1, true)
end

local function IsMatchmaking(self)
    return self.pWidgetRef.btnMatch:GetVisibility() == ESlateVisibility.Visible
end

local function OnRefreshAVG(self, nAVGProgressId)
    local tbDatas = {}
    for nAVGId, tbTemplate in pairs(AVGDataTable.tbContainer) do
        local tbDungeon = DungeonDataTable:GetTemplate(tbTemplate.nDungeonId)
        if tbDungeon then
            local tbData = {}
            tbData.nId = nAVGId
            tbData.szName = tbDungeon.szName
            tbData.bCanEnter = true

            if nAVGId > nAVGProgressId then
                tbData.bHasPass = false
            else
                tbData.bHasPass = true
            end

            if nAVGId > nAVGProgressId + 1 then
                tbData.bCanEnter = false
            end

            table.insert(tbDatas, tbData)
        end
    end

    self.ListHelper:SetData(tbDatas)
end

function ULAvg:OnLoad()
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.kmlist01)

    self.pWidgetRef.TextBlock_2:SetText(START_COOP_TEXT)
end

function ULAvg:OnUnload()
    self.ListHelper:Uninit()
end

function ULAvg:OnDestroy()
    ClearTimer(self)
end

function ULAvg:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_LOBBY_REFRESH_AVG, self, OnRefreshAVG)

    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, self.OnCloseClicked)

    EventHelper:RegisterCppDelegate(self.pWidgetRef.CheckBox_0.OnCheckStateChanged, self, self.OnAvgClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.CheckBox_1.OnCheckStateChanged, self, self.OnCoopClicked)

    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnStart.OnClicked, self, self.OnStartCoopClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnMatch.OnClicked, self, self.OnCancleClicked)

    EventHelper:RegisterEvent(ClientEventDef.EV_MATCH_MAKING_BEGIN, self, self.OnBeginMatch)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_ARENA_MATCH_MAKING_SUCCESS, self, self.OnMatchFinished)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_ARENA_MATCH_MAKING_CANCELLED, self, self.OnMatchFinished)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_ARENA_MATCH_MAKING_FAILED, self, self.OnMatchFinished)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_ARENA_MATCHING_PLAYER_COUNT, self, self.OnRefreshPlayerNumber)
end

function ULAvg:OnBeginMatch()
    self.pWidgetRef.btnStart:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.btnMatch:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.TextBlock_6:SetVisibility(ESlateVisibility.Visible)
    ShowMatchTime(self)

    self.pWidgetRef.TextBlock_Timer:SetText("00:00")
    self.pWidgetRef.TextBlock_6:SetText("")
end

function ULAvg:OnMatchFinished()
    self.pWidgetRef.btnStart:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.btnMatch:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.TextBlock_6:SetVisibility(ESlateVisibility.Collapsed)
    ClearTimer(self)
end

function ULAvg:OnRefreshPlayerNumber(current, max)
    local szText = string.format("当前匹配人数：%d/%d", current, max)
    if self.pWidgetRef then
        self.pWidgetRef.TextBlock_6:SetText(szText)
    end
end

function ULAvg:OnCloseClicked()
    if IsMatchmaking(self) then
        UIUtils.ShowToast(AVOID_ACTIVE_IN_MATCHMAKING, 0.2)
        return
    end

    self.Owner:PlayAnimation("animTips", 0, 1, EUMGSequencePlayMode.Reverse, 1000)

    self.Owner:PlayAnimation("animTips2", 0, 1, EUMGSequencePlayMode.Reverse, 1000)

    self.pWidgetRef.cvsTips01:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.hboxButton:SetVisibility(ESlateVisibility.Visible)

    self.Owner:PlayAnimation("animComeIn", 0, 1, EUMGSequencePlayMode.Forward, 1)

    self.pWidgetRef.btnStart:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.btnMatch:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.TextBlock_6:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.cvsPlayerHeadInfo:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.pWidgetRef.hboxStoryClose:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.pbLobbyChatQuickView:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

function ULAvg:OnAvgClicked()
    if IsMatchmaking(self) then
        UIUtils.ShowToast(AVOID_ACTIVE_IN_MATCHMAKING, 0.5)
        self.pWidgetRef.CheckBox_0:SetCheckedState(ECheckBoxState.Unchecked)
        return
    end

    self.pWidgetRef.CheckBox_0:SetVisibility(ESlateVisibility.HitTestInvisible)

    self.pWidgetRef.CheckBox_1:SetCheckedState(ECheckBoxState.Unchecked)
    self.pWidgetRef.CheckBox_1:SetVisibility(ESlateVisibility.Visible)

    self.Owner:PlayAnimation("animTips2", 0, 1, EUMGSequencePlayMode.Reverse, 1)

    self.pWidgetRef.imgBg:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.imgBg2:SetVisibility(ESlateVisibility.Collapsed)

    self.pWidgetRef.btnStart:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.btnMatch:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.TextBlock_6:SetVisibility(ESlateVisibility.Collapsed)



end

function ULAvg:OnCoopClicked()
    if IsMatchmaking(self) then
        UIUtils.ShowToast(AVOID_ACTIVE_IN_MATCHMAKING, 0.5)
        return
    end

    self.pWidgetRef.CheckBox_1:SetVisibility(ESlateVisibility.HitTestInvisible)

    self.pWidgetRef.CheckBox_0:SetCheckedState(ECheckBoxState.Unchecked)
    self.pWidgetRef.CheckBox_0:SetVisibility(ESlateVisibility.Visible)

    self.pWidgetRef.imgBg2:SetVisibility(ESlateVisibility.Visible)

    self.Owner:PlayAnimation("animTips2", 0, 1, EUMGSequencePlayMode.Forward, 1)

    self.pWidgetRef.btnStart:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.btnMatch:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.TextBlock_6:SetVisibility(ESlateVisibility.Collapsed)

    ClearTimer(self)
end

function ULAvg:OnStartCoopClicked()
    --ArenaSystem:FFARequestMatchMaking(14)
end

function ULAvg:OnCancleClicked()
    --ArenaSystem:FFACancelMatchmaking()
end

return ULAvg
