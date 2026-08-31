-----------------------------------------------------
--File Name    : UICountdown.lua
--Author       : Song Fuhao
--Create Time  : 2016-12-17
--Description  : 倒计时
-----------------------------------------------------

local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UICountdown = luaclass("UICountdown", WndBase)

local WidgetAnimationHandle = require("WidgetAnimationHandle")

UICountdown.TimeEndTimer    = nil
UICountdown.TimePassTimer   = nil
UICountdown.bClosing        = false

local function OnTimeEnd(self)
    self:CloseSelf()
end

local function OnTimePass(self)
    local nRemainingTime = self.TimeEndTimer:GetRemainingTime()
    local nNumber = math.floor(nRemainingTime)
    if nNumber >= 0 and nNumber ~= self.nNumber then
        self.nNumber = nNumber
        self.pWidgetRef.txtNumber:SetText(nNumber)
        self:PlayAnimation("NumberChangedAnim", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
end

-- public function
function UICountdown:OnShow()
    self.TimeEndTimer = self.TimerHelper:NewTimerMethod(self, OnTimeEnd, self.tbOpenArgs.nTime)
    self.TimePassTimer = self.TimerHelper:NewTimerMethod(self, OnTimePass, 0.1, true)
    OnTimePass(self)
end

function UICountdown:OnHide()
    if self.bClosing then       -- 避免重复触发关闭
        return false
    end
    self.bClosing = true
    self.TimerHelper:ClearTimer(self.TimePassTimer)
    self.TimerHelper:ClearTimer(self.TimeEndTimer)
    if self.tbOpenArgs.szText then
        self.pWidgetRef.txtNumber:SetText(self.tbOpenArgs.szText)
    -- else
        -- self.pWidgetRef.txtNumber:SetText(0)
    end
    self:PlayAnimation("HideAnim", 0, 1, EUMGSequencePlayMode.Forward, 1)
    return false
end

function UICountdown:OnExit()
    self.bClosing = false
end

function UICountdown:OnBindEvent()
    self.EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.HideAnim, self.HideFinished, self))
end

return UICountdown
