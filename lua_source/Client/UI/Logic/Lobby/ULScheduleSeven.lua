local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULScheduleSeven = luaclass("ULScheduleSeven", UILogicBase)
local ScheduleSystem = require("ScheduleSystem")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ScheduleUITable = require("ScheduleUITable")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local TimeUtil = require("TimeUtil")

local SHOW_WIDGETS = {
    ["hbSevenTime"] = true,
    ["btnGo1"] = true
}


local function WeekDays()
    local monday = TimeUtil.GetTimeFormatString(TimeUtil.GetDayBeginTimeInCurrentWeek(1), "%Y.%m.%d")
    local sunday = TimeUtil.GetTimeFormatString(TimeUtil.GetDayBeginTimeInCurrentWeek(7), "%Y.%m.%d")
    return monday .. "-" .. sunday
end

function ULScheduleSeven:Activate(tbAllWidget)
    local pWidgetRef = self.pWidgetRef

    for i, v in ipairs(tbAllWidget) do
        pWidgetRef[v]:SetVisibility(SHOW_WIDGETS[v] and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    end    

    local tbTemp = ScheduleUITable:GetTemplate(self.nId)
    if tbTemp.tbGoPos ~= nil then
        pWidgetRef.btnGo1:SetVisibility(ESlateVisibility_Visible)
        pWidgetRef.btnGo1.Slot:SetPosition(Vector2D{X=tbTemp.tbGoPos[1], Y=tbTemp.tbGoPos[2]})
    else
        pWidgetRef.btnGo1:SetVisibility(ESlateVisibility_Collapsed)
    end
    pWidgetRef.txtSevenTime:SetText(WeekDays())
end

local function OnClickedSevenGo(self)
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

function ULScheduleSeven:Deactivate()
end

function ULScheduleSeven:OnLoad()
end

function ULScheduleSeven:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGo1.OnClicked,  self, OnClickedSevenGo)
end

return ULScheduleSeven