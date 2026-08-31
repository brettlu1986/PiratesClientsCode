-----------------------------------------------------
--File Name    : ULLobbySchedule.lua
--Author       : Ranjie
--Create Time  : 2020-4-20
--Description  : ULLobbySchedule
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbySchedule = luaclass("ULLobbySchedule", UILogicBase)
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local DelayTimer = require("DelayTimer")
local ClientEventDef = require("ClientEventDef")
local ScheduleUITable  = require("ScheduleUITable")
local ScheduleSystem = require("ScheduleSystem")
local ScheduleHelper = require("ScheduleHelper")
local UISetUtils = require("UISetUtils")
local SelfListItemHelper = require("SelfListItemHelper")
local Timer = require("Timer")

ULLobbySchedule.tbList = nil
ULLobbySchedule.tbTimer = nil
ULLobbySchedule.nCurIndex = nil
ULLobbySchedule.ListItemHelper = nil
ULLobbySchedule.tbRefreshTimer = nil

local SCHEDULEWNDS = {
    [UIDef.UI_SCHEDULE] = 1,
    [UIDef.UI_SCHEDULE_NOOB_LOGIN] = 1,
    [UIDef.UI_SCHEDULE_CONTINUOUS] = 1,
    [UIDef.UI_SEASON_CHALLENGE] = 1,
    [UIDef.UI_SEVEN_DAY] = 1,
}

local MAX_COUNT = 8
local INTERVAL = 10
local UNSELECT_IMG = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonTips001_Normal.Spr_CommonTips001_Normal'"
local SELECT_IMG = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonTips001_Pressed.Spr_CommonTips001_Pressed'"

local function RefreshActivityTipIcon(self)
    local bTip = ScheduleSystem:HasTips()
    self.pWidgetRef.btnActivity:HideTipIcon(not bTip)
end

local function ClearTimer(self)
    if self.tbTimer ~= nil then  
        DelayTimer:ClearTimer(self.tbTimer)
        self.tbTimer = nil 
    end 
end

local function SetCurIndex(self, nIndex)
    if #self.tbList == 0 then 
        return
    end
    ClearTimer(self)

    if nIndex > #self.tbList then
        nIndex = 1
    end
    local nOldIndex = self.nCurIndex
    self.nCurIndex = nIndex

    local tbTemp = self.tbList[nIndex]
    local pWidgetRef = self.pWidgetRef
    if nOldIndex ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef["imgActivityDot"..nOldIndex], UNSELECT_IMG:load())
    end

    self.ListItemHelper:ScrollToIndexCenter(nIndex)
    UISetUtils.SetImageBrushRes(pWidgetRef["imgActivityDot"..nIndex], SELECT_IMG:load())
    pWidgetRef.txtActivityTitle:SetText(tbTemp.l10nName)

    self.tbTimer = DelayTimer:DelayRun(function()
        SetCurIndex(self, self.nCurIndex + 1)
    end, tbTemp.nLobbyTime)
end 

local function Refresh(self)
    RefreshActivityTipIcon(self)
    --SetCurIndex(self, self.nCurIndex or 1)
end

local function OnClickedActivity(self)
    if #self.tbList == 0 then 
        return
    end
    UIManager:OpenWnd(UIDef.UI_SCHEDULE, {nId = self.tbList[1].nId})
end

local function BuidRollover(self)
    local nCount = self.tbList and #self.tbList or 0
    self.tbList = {}
    local tbAll = ScheduleUITable:GetContainer()
    for i, v in pairs(tbAll) do
        if v.nLobbyTime > 0 and v.nLobbyOrder > 0 and v.szLobbyImgPath ~= nil then
            if ScheduleSystem:IsOpen(v.nId) then
                table.insert(self.tbList, v)
                if #self.tbList >= MAX_COUNT then
                    break
                end
            end
        end
    end
    local fnSort = function(a, b)
        if a.nLobbyOrder < b.nLobbyOrder then
            return true
        elseif b.nLobbyOrder < a.nLobbyOrder then
            return false
        else
            return a.nId < b.nId
        end
    end
    table.sort(self.tbList, fnSort)

    local SelfHitTestInvisible, Collapsed = ESlateVisibility_SelfHitTestInvisible, ESlateVisibility_Collapsed
    local pWidgetRef = self.pWidgetRef
    for i = 1, #self.tbList do
        pWidgetRef["imgActivityDot"..i]:SetVisibility(SelfHitTestInvisible)
    end
    for i = #self.tbList + 1, MAX_COUNT do
        pWidgetRef["imgActivityDot"..i]:SetVisibility(Collapsed)
    end

    Refresh(self)
    if #self.tbList ~= nCount then
        SetCurIndex(self, 1)
    end
    self.ListItemHelper:SetData(self.tbList)
end

local function OnRefresh(self)
    BuidRollover(self)
    RefreshActivityTipIcon(self)
end

local function OnScrollStarted(self)
    ClearTimer(self)
end

local function OnScrollStopped(self)
    if self.tbTimer == nil then
        SetCurIndex(self, self.nCurIndex)
    end
end

local function OnExitUI(self, szWndName)
    if SCHEDULEWNDS[szWndName] ~= nil then
        SetCurIndex(self, 1)
    end
end

local function OnSelectedChangedDelegate(self, nIndex)
    SetCurIndex(self, nIndex)
end

local function OnRefreshTime(self)
    local Component = ScheduleSystem:GetComponent()
    ScheduleHelper:TimerProcessFixed(Component)
end

function ULLobbySchedule:OnLoad()
    self.ListItemHelper = SelfListItemHelper()
    self.ListItemHelper:Init(self, self.pWidgetRef.listActivity)
end

function ULLobbySchedule:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnActivity.OnClicked,  self, OnClickedActivity)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_NOOB_LOGIN_REFRESH, self, OnRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_BATTLE_STAR_REFRESH, self, OnRefresh)

    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_CHECKIN, self, OnRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_GETREWARD, self, RefreshActivityTipIcon)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_NEXT_DAY, self, RefreshActivityTipIcon)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_CONTINUOUS_REFRESH, self, OnRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_FIXED_TIME_AWARD_REFRESH, self, OnRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_POST_EXIT_UI, self, OnExitUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_CHEST_REFRESH, self, OnRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEA_ADVENTURE_REFRESH, self, OnRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_QUESTION_REFRESH, self, OnRefresh)
    
    
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_ROULETTE_REFRESH, self, OnRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_ITEM_UPDATE, self, RefreshActivityTipIcon)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_DEACTIVATE, self, OnRefresh)
    

    local ListItemHelper = self.ListItemHelper
    EventHelper:RegisterLuaDelegate(ListItemHelper.OnScrollStartedDelegate, OnScrollStarted, self)
    EventHelper:RegisterLuaDelegate(ListItemHelper.OnScrollStopedDelegate, OnScrollStopped, self)
    EventHelper:RegisterLuaDelegate(ListItemHelper.OnSelectedChangedDelegate, OnSelectedChangedDelegate, self)
end

function ULLobbySchedule:OnShow()
    if self.tbRefreshTimer == nil then
        self.tbRefreshTimer = Timer.NewTimerMethod(self, OnRefreshTime, INTERVAL, true)
    end
    if self.tbList ~= nil then
        Refresh(self)             
    end
    BuidRollover(self)
end

function ULLobbySchedule:OnHide()
    if self.tbRefreshTimer then
        self.tbRefreshTimer:Clear()
        self.tbRefreshTimer = nil
    end
    -- self.nCurIndex = nil 
    self.tbList = nil
    ClearTimer(self)
end

function ULLobbySchedule:OnDestroy()
    self.ListItemHelper:Uninit()
    self.ListItemHelper = nil
end

return ULLobbySchedule