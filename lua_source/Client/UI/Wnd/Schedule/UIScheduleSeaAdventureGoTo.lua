local luaclass = require ("luaclass")
local WndBase = require("WndBase")

local UIScheduleSeaAdventureGoTo = luaclass("UIScheduleSeaAdventureGoTo", WndBase)
local TimeUtil = require("TimeUtil")
local SeaAdventureHelper = require("SeaAdventureHelper")
local ScheduleTypeDef = require("ScheduleTypeDef")
local ScheduleSystem = require("ScheduleSystem")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ScheduleTable = require("ScheduleTable")

local function OnClickClose(self)
    self:CloseSelf()
end

local function OnClickGo(self)
    local ScheduleTemp = ScheduleTable:GetTemplateByType(ScheduleTypeDef.ROLL)
    UIManager:OpenWnd(UIDef.UI_SCHEDULE_SEAADVENTURE, { nId = ScheduleTemp.nId})
    self:CloseSelf()
end

function UIScheduleSeaAdventureGoTo:OnBindEvent(EventHelper)
   
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, OnClickClose)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnGo2.OnClicked, self, OnClickGo)
end

function UIScheduleSeaAdventureGoTo:OnCreate()
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.ROLL)
end

function UIScheduleSeaAdventureGoTo:OnDestroy()
    self.tbInstance = nil
end

function UIScheduleSeaAdventureGoTo:OnShow()
    self:PlayAnimation("animSeaAdventureGoToIn", 0, 1,  EUMGSequencePlayMode.Forward, 1, function() 
        self:PlayAnimation("animSeaAdentureGoToLoop", 0, 0, EUMGSequencePlayMode.Forward, 1)
    end)

    local pWidgetRef = self.pWidgetRef
    local tbTemplate = self.tbInstance:GetTemplate()
    local nStartMonth, nStartDay = TimeUtil.GetMonthDay(tbTemplate.tbTime.nStartTime)
    local nEndMonth, nEndDay = TimeUtil.GetMonthDay(tbTemplate.tbTime.nStopTime)
    SeaAdventureHelper.SetMonthDayImageWithNum(pWidgetRef.ImgStartMon1, pWidgetRef.ImgStartMon2, pWidgetRef.ImgStartDay1, pWidgetRef.ImgStartDay2,
    nStartMonth, nStartDay)
    SeaAdventureHelper.SetMonthDayImageWithNum(pWidgetRef.ImgEndMon1, pWidgetRef.ImgEndMon2, pWidgetRef.ImgEndDay1, pWidgetRef.ImgEndDay2,
    nEndMonth, nEndDay)
end

return UIScheduleSeaAdventureGoTo
