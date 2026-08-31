-----------------------------------------------------
--File Name    : GuideActionSelectWidgetWithInterval.lua
--Author       : Edward J
--Create Time  : 2019-09-03
--Description  : 没有点击效果的SelectWidget
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionSelectWidgetEffect         = require("GuideActionSelectWidgetEffect")
local GuideActionSelectWidgetWithInterval   = luaclass("GuideActionSelectWidgetWithInterval", GuideActionSelectWidgetEffect)

-----------------------------------------------------
local TIME_TICK     = 0.5
local TIME_COUNT    = 0
local nInterval     = 0

GuideActionSelectWidgetWithInterval.pPressedTimer = nil
-----------------------------------------------------

local function ClearPressedTimer(self)
    if self.pPressedTimer then
        self.TimerHelper:ClearTimer(self.pPressedTimer)
        self.pPressedTimer = nil
    end
end

function GuideActionSelectWidgetWithInterval:Begin()
    GuideActionSelectWidgetWithInterval.super.Begin(self)
    TIME_COUNT = 0
    local tbParam = self.tbTemplate.tbParam
    if tbParam and tbParam[1] then
        nInterval = tonumber(tbParam[1])
    end
end

function GuideActionSelectWidgetWithInterval:ExeOnece(tbTemplate)
    GuideActionSelectWidgetWithInterval.super.ExeOnece(self, tbTemplate)
    for k, v in ipairs(self.tbSelectWidgets)do
        self.EventHelper:RegisterCppDelegate(v.OnPressed, self, self.OnPressed)
        self.EventHelper:RegisterCppDelegate(v.OnReleased, self, self.OnReleased)
    end
end

function GuideActionSelectWidgetWithInterval:OnPressed()
    ClearPressedTimer(self)
    self.pPressedTimer = self.TimerHelper:NewTimerMethod(self,self.OnPressedTimerFunc, TIME_TICK, true)
end

function GuideActionSelectWidgetWithInterval:OnReleased()
    ClearPressedTimer(self)
end

function GuideActionSelectWidgetWithInterval:OnPressedTimerFunc(deltal)
    TIME_COUNT = TIME_COUNT + TIME_TICK
    if TIME_COUNT >= nInterval then
        ClearPressedTimer(self)
        TIME_COUNT = 0
        self:EndAction()
    end
end

return GuideActionSelectWidgetWithInterval
