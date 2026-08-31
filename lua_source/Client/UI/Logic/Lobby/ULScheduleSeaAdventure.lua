local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULScheduleSeaAdventure = luaclass("ULScheduleSeaAdventure", UILogicBase)
local ScheduleSystem = require("ScheduleSystem")
local ScheduleTypeDef = require("ScheduleTypeDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local TimeUtil = require("TimeUtil")
local SeaAdventureHelper = require("SeaAdventureHelper")
local ScheduleTable = require("ScheduleTable")

local SHOW_WIDGETS = {
    ["vboxNewActivity"] = true
}

function ULScheduleSeaAdventure:Activate(tbAllWidget)
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.ROLL)
    local pWidgetRef = self.pWidgetRef

    for i, v in ipairs(tbAllWidget) do
        pWidgetRef[v]:SetVisibility(SHOW_WIDGETS[v] and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    end    

    local tbTemplate = self.tbInstance:GetTemplate()
    local nStartMonth, nStartDay = TimeUtil.GetMonthDay(tbTemplate.tbTime.nStartTime)
    local nEndMonth, nEndDay = TimeUtil.GetMonthDay(tbTemplate.tbTime.nStopTime)
    SeaAdventureHelper.SetMonthDayImageWithNum(pWidgetRef.ImgStartMon1, pWidgetRef.ImgStartMon2, pWidgetRef.ImgStartDay1, pWidgetRef.ImgStartDay2,
    nStartMonth, nStartDay)
    SeaAdventureHelper.SetMonthDayImageWithNum(pWidgetRef.ImgEndMon1, pWidgetRef.ImgEndMon2, pWidgetRef.ImgEndDay1, pWidgetRef.ImgEndDay2,
    nEndMonth, nEndDay)
end

function ULScheduleSeaAdventure:Deactivate()
    self.tbInstance = nil
end

function ULScheduleSeaAdventure:OnLoad()
end

function ULScheduleSeaAdventure:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGoSea.OnClicked,  self, self.OnClickedGo)
end

function ULScheduleSeaAdventure:OnClickedGo()
    local ScheduleTemp = ScheduleTable:GetTemplateByType(ScheduleTypeDef.ROLL)
    UIManager:OpenWnd(UIDef.UI_SCHEDULE_SEAADVENTURE, {szFrom = UIDef.UI_SCHEDULE, nId = ScheduleTemp.nId})
    UIManager:CloseWnd(UIDef.UI_SCHEDULE)
end

return ULScheduleSeaAdventure