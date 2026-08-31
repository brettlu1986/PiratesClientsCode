-----------------------------------------------------
--File Name    : UISevenDay2.lua
--Author       : lu zheng
--Create Time  : 2019-5-16
--Description  : 7天登陆
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISevenDay2 = luaclass("UISevenDay2", WndBase)
local UIDef = require("UIDef")
local TimeUtil = require("TimeUtil")
local ClientEventDef = require("ClientEventDef")
local ScheduleSystem = require("ScheduleSystem")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local UIManager = require("UIManager")

local ITEM_COUNT = 7

UISevenDay2.nCheckInCount = -1
UISevenDay2.bCanAward = false
UISevenDay2.tbItems = nil

local function HasAward(self, nIndex)
    return nIndex <= self.nCheckInCount
end

local function CanAward(self, nIndex)
    return self.bCanAward and nIndex == self.nCheckInCount + 1
end

local function UnAward(self, nIndex)
    if self.bCanAward then
        return nIndex > self.nCheckInCount + 1
    else
        return nIndex > self.nCheckInCount
    end
end

local function InitSevenItems(self)
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    self.tbItems = {}
    local pbSubItem = nil
    for i = 1, ITEM_COUNT do
        if i < ITEM_COUNT then 
            pbSubItem = PrefabHelper:BindPrefab(pWidgetRef["pbSevenDaySub0"..i], UIDef.UP_SEVENDAY_SUB_NORMAL)
        else   
            pbSubItem = PrefabHelper:BindPrefab(pWidgetRef["pbSevenDaySub0"..i], UIDef.UP_SEVENDAY_SUB_SPECIAL)
        end
        
        table.insert(self.tbItems, pbSubItem)
    end
end

--OnLoad -> OnEnter
function UISevenDay2:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    InitSevenItems(self)
end

function UISevenDay2:OnEnter() 
end

local function WeekDays()
    local monday = TimeUtil.GetTimeFormatString(TimeUtil.GetDayBeginTimeInCurrentWeek(1), "%Y.%m.%d")
    local sunday = TimeUtil.GetTimeFormatString(TimeUtil.GetDayBeginTimeInCurrentWeek(7), "%Y.%m.%d")
    return monday .. "-" .. sunday
end

local function OnRefresh(self)
    self.pWidgetRef.txtTime:SetText(WeekDays())

    local Component = ScheduleSystem:GetComponent()
    local tbData = Component:GetSevenDayCheckIn()
    if not tbData then
        UIUtils.ShowToast(UITextDef.LOBBY_NET_WORK_WEAKNESS)
        return
    end
    self.nCheckInCount = tbData.check_in_count
    self.bCanAward = tbData.can_award
    for i = 1, ITEM_COUNT do
        local tbParams = {}
        tbParams.nIndex = i
        tbParams.bHasAward = HasAward(self, i)
        tbParams.bCanAward = CanAward(self, i)
        tbParams.bUnAward = UnAward(self, i)
        tbParams.nCheckInCount = self.bCanAward and self.nCheckInCount + 1 or self.nCheckInCount
        tbParams.bAllCanAward = self.bCanAward

        self.tbItems[i]:SetData(tbParams)
    end
end

function UISevenDay2:OnShow()
    OnRefresh(self)    
    self:PlayAnimation("animSevenDayIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

local function OnBtnClose(self)
    self:CloseSelf()
    if self.tbOpenArgs.szFrom ~= nil and self.tbOpenArgs.szFrom ~= "LobbyMain" then
        UIManager:OpenWnd(self.tbOpenArgs.szFrom, {szFrom = UIDef.UI_SEVENDAY, nId = self.tbOpenArgs.nId})
    end 
end

function UISevenDay2:OnBindEvent()
    local EventHelper = self.EventHelper
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, OnBtnClose)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_NEXT_DAY, self, OnRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_CHECKIN, self, OnRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_GETREWARD, self, OnRefresh)
end

function UISevenDay2:OnDestroy()
    self.tbItems = nil
end


function UISevenDay2:OnPause()
    local nSubSystem = LobbySystem:GetActiveSub()
    log("UISevenDay2:OnPause:nSubSystem.nSubType=",nSubSystem.nSubType)
    if nSubSystem and (nSubSystem.nSubType == LobbySubTypeDef.AWARD) then
        self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    end
end

function UISevenDay2:OnResume()
    log("UISevenDay2:OnResume")
    if not self.pWidgetRef:IsVisible() then
        self.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        -- UIUtils.BottomMenuUnselectAll()
    end
end

return UISevenDay2