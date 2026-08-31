local luaclass = require("luaclass")
local UPScheduleTabBase = require("UPScheduleTabBase")
local UPScheduleTabSevenDay = luaclass("UPScheduleTabSevenDay", UPScheduleTabBase)
local TimeUtil = require("TimeUtil")
local ScheduleSystem = require("ScheduleSystem")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")

local function WeekDays()
    local monday = TimeUtil.GetTimeFormatString(TimeUtil.GetDayBeginTimeInCurrentWeek(1), "%Y.%m.%d")
    local sunday = TimeUtil.GetTimeFormatString(TimeUtil.GetDayBeginTimeInCurrentWeek(7), "%Y.%m.%d")
    return monday .. "-" .. sunday
end

function UPScheduleTabSevenDay:Activate()
    UPScheduleTabSevenDay.super.Activate(self)
    self.pWidgetRef.txtSevenTime:SetText(WeekDays())
end

function UPScheduleTabSevenDay:Deactivate()
    UPScheduleTabSevenDay.super.Deactivate(self)
end

local function OnClickGo(self)
    local Component = ScheduleSystem:GetComponent()
    local tbData = Component:GetSevenDayCheckIn()
    if tbData then
        UIManager:OpenWnd(UIDef.UI_SEVEN_DAY, { nCheckInCount = tbData.check_in_count, bCanAward = tbData.can_award, szFrom = UIDef.UI_SCHEDULE, nId = self.nId})
        UIManager:CloseWnd(UIDef.UI_SCHEDULE)
    else
        UIUtils.ShowToast(UITextDef.LOBBY_NET_WORK_WEAKNESS)
    end

    -- UIManager:CloseWnd(UIDef.UI_SCHEDULE)
end

function UPScheduleTabSevenDay:OnLoad()
end

function UPScheduleTabSevenDay:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGo1.OnClicked,  self, OnClickGo)
end

return UPScheduleTabSevenDay