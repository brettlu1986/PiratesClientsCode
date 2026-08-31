-----------------------------------------------------
--File Name    : UIWaiting.lua
--Author       : Ran Jie
--Create Time  : 2018-02-22
--Description  : 等待网络回包界面
-----------------------------------------------------

local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIWaiting = luaclass("UIWaiting", WndBase)

local TICK_TIME = 0.2
local TIME_OUT = 15

UIWaiting.bHideAim = false

local function OnShowTimerFunc(self)
    self.pWidgetRef.cirWaitting:SetVisibility(ESlateVisibility.Visible)
end

local function OnCloseTimerFunc(self)
    self:CloseSelf()
end

-- public function
function UIWaiting:OnShow()
    self.bHideAim = false
    self.TimerHelper:NewTimerMethod(self, OnShowTimerFunc, TICK_TIME, false)
    self.TimerHelper:NewTimerMethod(self, OnCloseTimerFunc, TIME_OUT, false)
end




return UIWaiting
