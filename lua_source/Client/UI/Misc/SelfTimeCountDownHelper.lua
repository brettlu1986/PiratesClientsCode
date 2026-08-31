-----------------------------------------------------
--File Name    : SelfTimeCountDownHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-02-27
--Description  : 倒计时helper
-----------------------------------------------------
local luaclass = require("luaclass")
local SelfTimeCountDownHelper = luaclass("SelfTimeCountDownHelper")
local Timer = require("Timer")
local UISetUtils = require("UISetUtils")
local TimeUtil = require("TimeUtil")
local GetTextByKey = UISetUtils.GetTextByKey

local MAX_PRECISION = 4

SelfTimeCountDownHelper.tbTimer = nil

SelfTimeCountDownHelper.CountDownType =
{
    FRONT                  = 1,                -- 显示最前面的
    FRONT_FULL_PRECISION   = 2,                -- 显示最前面的,补满精度
    NOT_ZERO               = 3,                -- 显示不为0的
}

local function GetDayHourMinuteSecond(nRemainSeconds)
    return TimeUtil.GetDayHourMinuteSecond(nRemainSeconds)
end

local function GetRefreshSeconds(nDay, nHour, nMinute, nSecond)
    return TimeUtil.GetTotalSeconds(nDay, nHour, nMinute, nSecond) + 1
end

local function EndTimer(self)
    if self.tbTimer ~= nil then
        self.tbTimer:Clear()
        self.tbTimer = nil
    end
end

local function StartTimer(self, nRemainSeconds, nInterval, nCountDownType, nPrecision, pTxtWidget, funTimeEndCallback)
    local funTimeCallBack = function()
        EndTimer(self)
        local nNextRemainSeconds = nRemainSeconds - nInterval
        if nNextRemainSeconds > 0 then
            self:StartCountDown(nNextRemainSeconds, nCountDownType, nPrecision, pTxtWidget, funTimeEndCallback)
        else
            if funTimeEndCallback ~= nil then
                funTimeEndCallback()
            end
        end
    end

    self.tbTimer = Timer.NewTimerMethod(self, funTimeCallBack, nInterval, false)
end

local function SetTextAndStartTimer(self, szRemainTime, nRemainSeconds, nRefreshSeconds, nCountDownType, nPrecision, pTxtWidget, funTimeEndCallback)
    pTxtWidget:SetText(szRemainTime)
    StartTimer(self, nRemainSeconds, nRefreshSeconds, nCountDownType, nPrecision, pTxtWidget, funTimeEndCallback)
end

local function StartCountDownPriorityFront(self, nDay, nHour, nMinute, nSecond, nPrecision)
    local szRemainTime = ""
    local nCount = 0
    if nDay > 0 then
        szRemainTime = szRemainTime..nDay..GetTextByKey("COMMON_TIME_DAY")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime, GetRefreshSeconds(0, nHour, nMinute, nSecond)
        end
    end
    if szRemainTime ~= "" or nHour > 0 then
        szRemainTime = szRemainTime..nHour..GetTextByKey("COMMON_TIME_HOUR")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime, GetRefreshSeconds(0, 0, nMinute, nSecond)
        end
    end
    if szRemainTime ~= "" or nMinute > 0 then
        szRemainTime = szRemainTime..nMinute..GetTextByKey("COMMON_TIME_MINUTE")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime, GetRefreshSeconds(0, 0, 0, nSecond)
        end
    end
    szRemainTime = szRemainTime..nSecond..GetTextByKey("COMMON_TIME_SECOND")
    return szRemainTime,  GetRefreshSeconds(0, 0, 0, 0)
end

local function StartCountDownPriorityFrontFullPrecision(self, nDay, nHour, nMinute, nSecond, nPrecision)
    local szRemainTime = ""
    local nCount = 0
    if nDay > 0 then
        szRemainTime = szRemainTime..nDay..GetTextByKey("COMMON_TIME_DAY")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime, GetRefreshSeconds(0, nHour, nMinute, nSecond)
        end
    end
    if szRemainTime ~= "" or nHour > 0 or (szRemainTime == "" and nPrecision == 3) then
        szRemainTime = szRemainTime..nHour..GetTextByKey("COMMON_TIME_HOUR")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime, GetRefreshSeconds(0, 0, nMinute, nSecond)
        end
    end
    if szRemainTime ~= "" or nMinute > 0 or (szRemainTime == "" and nPrecision == 2) then
        szRemainTime = szRemainTime..nMinute..GetTextByKey("COMMON_TIME_MINUTE")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime, GetRefreshSeconds(0, 0, 0, nSecond)
        end
    end
    szRemainTime = szRemainTime..nSecond..GetTextByKey("COMMON_TIME_SECOND")
    nCount = nCount + 1
    return szRemainTime,  GetRefreshSeconds(0, 0, 0, 0)
end

local function StartCountDownPriorityNotZero(self, nDay, nHour, nMinute, nSecond, nPrecision)
    local szRemainTime = ""
    local nCount = 0
    if nDay > 0 then
        szRemainTime = szRemainTime..nDay..GetTextByKey("COMMON_TIME_DAY")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime, GetRefreshSeconds(0, nHour, nMinute, nSecond)
        end
    end
    if nHour > 0 then
        szRemainTime = szRemainTime..nHour..GetTextByKey("COMMON_TIME_HOUR")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime, GetRefreshSeconds(0, 0, nMinute, nSecond)
        end
    end
    if nMinute > 0 then
        szRemainTime = szRemainTime..nMinute..GetTextByKey("COMMON_TIME_MINUTE")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime, GetRefreshSeconds(0, 0, 0, nSecond)
        end
    end
    szRemainTime = szRemainTime..nSecond..GetTextByKey("COMMON_TIME_SECOND")
    return szRemainTime,  GetRefreshSeconds(0, 0, 0, 0)
end

function SelfTimeCountDownHelper:StartCountDown(nRemainSeconds, nCountDownType, nPrecision, pTxtWidget, funTimeEndCallback)
    if nPrecision == nil then
        nPrecision = MAX_PRECISION
    end
    local nDay, nHour, nMinute, nSecond = GetDayHourMinuteSecond(nRemainSeconds)
    local szRemainTime, nRefreshSeconds = "", 0
    if nCountDownType == SelfTimeCountDownHelper.CountDownType.FRONT then
        szRemainTime, nRefreshSeconds = StartCountDownPriorityFront(self, nDay, nHour, nMinute, nSecond, nPrecision)
    elseif nCountDownType == SelfTimeCountDownHelper.CountDownType.FRONT_FULL_PRECISION then
        szRemainTime, nRefreshSeconds = StartCountDownPriorityFrontFullPrecision(self, nDay, nHour, nMinute, nSecond, nPrecision)
    elseif nCountDownType == SelfTimeCountDownHelper.CountDownType.NOT_ZERO then
        szRemainTime, nRefreshSeconds = StartCountDownPriorityNotZero(self, nDay, nHour, nMinute, nSecond, nPrecision)
    end
    SetTextAndStartTimer(self, szRemainTime, nRemainSeconds, nRefreshSeconds, nCountDownType, nPrecision, pTxtWidget, funTimeEndCallback)
end

function SelfTimeCountDownHelper:StopCountDown()
    EndTimer(self)
end

return SelfTimeCountDownHelper
