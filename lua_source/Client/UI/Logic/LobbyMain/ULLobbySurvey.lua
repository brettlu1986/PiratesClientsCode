-----------------------------------------------------
--File Name    : ULLobbySurvey.lua
--Author       : Edward J
--Create Time  : 2020-8-21
--Description  : ULLobbySurvey
-----------------------------------------------------
local luaclass      = require("luaclass")
local UILogicBase   = require("UILogicBase")
local ULLobbySurvey = luaclass("ULLobbySurvey", UILogicBase)

local SurveyHelper      = require("SurveyHelper")
local ClientEventDef    = require("ClientEventDef")
local UIDef             = require("UIDef")
local UIManager         = require("UIManager")
-----------------------------------------------------
local DEAFAULT_DELAY_TIME = 1

ULLobbySurvey.tbDelayTimerHandle    = nil
ULLobbySurvey.tbEventHandle         = nil
-----------------------------------------------------
--survey

local function ClearDelayTimer(self)
    if self.tbDelayTimerHandle then
        self.TimerHelper:ClearTimer(self.tbDelayTimerHandle)
        self.tbDelayTimerHandle = nil
    end
end

local function OnSurveyClicked(self)
    SurveyHelper.ShowSurveyDialog()
end

local function RefreshSurveyStatus(self)
    local EStatus = SurveyHelper.GetSurveyStatus()
    local pWidgetRef = self.pWidgetRef
    if EStatus == SurveyHelper.EBattleCountNotValid then
        pWidgetRef.btnSurvey:SetVisibility(ESlateVisibility_Collapsed)
    elseif EStatus == SurveyHelper.ENotFinish then
        pWidgetRef.btnSurvey:SetVisibility(ESlateVisibility_Visible)
        SurveyHelper.AutoPopSurveyDialog()
    elseif EStatus == SurveyHelper.EAllFinish then
        pWidgetRef.btnSurvey:SetVisibility(ESlateVisibility_Collapsed)
    end
end

local function DelayCheckLobbyMainIsTop(self)
    local bIsTop = UIManager:IsShowTopUI(UIDef.UI_LOBBY_MAIN)
    if not bIsTop then
        return
    end
    RefreshSurveyStatus(self)
    if not self.tbEventHandle then
        self.EventHelper:UnregisterEvent(ClientEventDef.EV_UI_STACK_TOP, self, self.CheckLobbyMainIsTop)
    end
end

local function CheckSurveyStatus(self)
    local bIsTop = UIManager:IsShowTopUI(UIDef.UI_LOBBY_MAIN)
    if not bIsTop then
        if not self.tbEventHandle then
            self.tbEventHandle = self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_STACK_TOP, self, self.CheckLobbyMainIsTop)
        end
    else
        RefreshSurveyStatus(self)
    end
end

function ULLobbySurvey:CheckLobbyMainIsTop(szWndName)
    if szWndName == UIDef.UI_LOBBY_MAIN then
        ClearDelayTimer(self)
        self.tbDelayTimerHandle = self.TimerHelper:NewDelayRunTimer(function() DelayCheckLobbyMainIsTop(self) end, DEAFAULT_DELAY_TIME)       
    end
end

function ULLobbySurvey:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    --调查问卷
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSurvey.OnClicked, self, OnSurveyClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_CLICK_SURVEY, self, RefreshSurveyStatus)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_ON_OVER_POP, self, RefreshSurveyStatus)
end

function ULLobbySurvey:OnShow()
    ClearDelayTimer(self)
    self.tbDelayTimerHandle = self.TimerHelper:NewDelayRunTimer(function() CheckSurveyStatus(self) end, DEAFAULT_DELAY_TIME)
end

function ULLobbySurvey:OnHide()
    ClearDelayTimer(self)
end

return ULLobbySurvey