-----------------------------------------------------
--File Name    : GuideActionSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionSelectWidget           = require("GuideActionSelectWidget")
local GuideActionSelectVisibleWidget    = luaclass("GuideActionSelectVisibleWidget", GuideActionSelectWidget)
----------------------------------------------------------
local TIME_TICK = 1 / 30

GuideActionSelectVisibleWidget.bTargetUIVisible     = nil
GuideActionSelectVisibleWidget.pCheckTimerHandle    = nil
----------------------------------------------------------
local function ClearCheckTimer(self)
    if self.pCheckTimerHandle then
        self.TimerHelper:ClearTimer(self.pCheckTimerHandle)
        self.pCheckTimerHandle = nil
    end
end

function GuideActionSelectVisibleWidget:AfterShow()
    ClearCheckTimer(self)
    self.pCheckTimerHandle = self.TimerHelper:NewTimerMethod(self, self.CheckWidgetVisible, TIME_TICK, true)
end

function GuideActionSelectVisibleWidget:CheckWidgetVisible()
    if not self.SelectWidget then
        self:EndAction()
        return
    end
    local bVisible = self.SelectWidget:IsVisible()
    self:DebugLog("CheckWidgetVisible bVisible = " .. tostring(bVisible))
    if bVisible ~= self.bTargetUIVisible then
        self.bTargetUIVisible = bVisible
        self:ActiveGuideWnd(bVisible)
    end
end

return GuideActionSelectVisibleWidget