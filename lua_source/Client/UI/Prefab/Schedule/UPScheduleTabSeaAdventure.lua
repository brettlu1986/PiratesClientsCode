local luaclass = require("luaclass")
local UPScheduleTabBase = require("UPScheduleTabBase")
local UPScheduleTabSeaAdventure = luaclass("UPScheduleTabSeaAdventure", UPScheduleTabBase)
local ScheduleSystem = require("ScheduleSystem")
local ScheduleTypeDef = require("ScheduleTypeDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local TimeUtil = require("TimeUtil")
local SeaAdventureHelper = require("SeaAdventureHelper")
local ScheduleTable = require("ScheduleTable")


local function OnClickedGo()
    local ScheduleTemp = ScheduleTable:GetTemplateByType(ScheduleTypeDef.ROLL)
    UIManager:OpenWnd(UIDef.UI_SCHEDULE_SEAADVENTURE, {szFrom = UIDef.UI_SCHEDULE, nId = ScheduleTemp.nId})
    UIManager:CloseWnd(UIDef.UI_SCHEDULE)
end

function UPScheduleTabSeaAdventure:Activate()
    UPScheduleTabSeaAdventure.super.Activate(self)

    local pWidgetRef = self.pWidgetRef

    local tbTemplate = self.tbInstance:GetTemplate()
    local nStartMonth, nStartDay = TimeUtil.GetMonthDay(tbTemplate.tbTime.nStartTime)
    local nEndMonth, nEndDay = TimeUtil.GetMonthDay(tbTemplate.tbTime.nStopTime)
    SeaAdventureHelper.SetMonthDayImageWithNum(pWidgetRef.ImgStartMon1, pWidgetRef.ImgStartMon2, pWidgetRef.ImgStartDay1, pWidgetRef.ImgStartDay2,
    nStartMonth, nStartDay)
    SeaAdventureHelper.SetMonthDayImageWithNum(pWidgetRef.ImgEndMon1, pWidgetRef.ImgEndMon2, pWidgetRef.ImgEndDay1, pWidgetRef.ImgEndDay2,
    nEndMonth, nEndDay)
end

function UPScheduleTabSeaAdventure:Deactivate()
    UPScheduleTabSeaAdventure.super.Deactivate(self)
end

function UPScheduleTabSeaAdventure:OnLoad()
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.ROLL)
end

function UPScheduleTabSeaAdventure:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGoSea.OnClicked,  self, OnClickedGo)
end

return UPScheduleTabSeaAdventure