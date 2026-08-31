local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UICountdown2 = luaclass("UICountdown2", WndBase)
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local ClientEventDef = require("ClientEventDef")

local DELAY_TIME = 1
local l10nTimeFormat = UISetUtils.GetL10NTextByKey("FFA_SELECTPOINT_COUNT_DOWN")

UICountdown2.OneSecondTimer = nil
UICountdown2.nEndTime = nil

local function OnTimeEnd(self)
    self:CloseSelf()
end

local function OnOneSecondPass(self)
    local txtCoolTime = self.pWidgetRef.cdtxtTimer

    local nTime = self.nEndTime
    if nTime >= 0 then
        local l10nTime = L10N:Format(l10nTimeFormat, nTime)
        txtCoolTime:SetText(l10nTime)
    else
        OnTimeEnd(self)
    end
end

local function StartTimer(self)
    if self.OneSecondTimer == nil then
        self.OneSecondTimer = self.TimerHelper:NewTimerMethod(self, function()
            self.nEndTime = self.nEndTime - DELAY_TIME 
            OnOneSecondPass(self)
        end, DELAY_TIME, true)
    end
    OnOneSecondPass(self)
end

local function OnEnterForeground(self)
    self.nEndTime = self.tbOpenArgs.nTime - GlobalVariableSystem_C:GetLocalTime()
end

function UICountdown2:OnBindEvent()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_APP_HAS_ENTERED_FOREGROUND, self, OnEnterForeground)
end

function UICountdown2:OnShow()
    self.nEndTime = self.tbOpenArgs.nTime - GlobalVariableSystem_C:GetLocalTime()
    StartTimer(self)
end

return UICountdown2
