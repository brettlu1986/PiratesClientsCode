-----------------------------------------------------
--File Name    : TimeUtil.lua
--Author       : WuJizhou
--Create Time  : 4/24/2019, 8:48:08 PM
--Description  : TimeUtil
-----------------------------------------------------
local TimeUtil = {}

local ONEMINUTE_SECOND= 60
local ONEHOUR_MINUTE = 60
local ONEDAY_HOUR = 24
local ONEHOUR_SECOND  = ONEMINUTE_SECOND * ONEHOUR_MINUTE
local ONEDAY_SECOND   = ONEHOUR_SECOND * ONEDAY_HOUR

local UISetUtils = nil
local GlobalVariableSystem = nil

local nTimezoneOffsetSeconds = nil

-----------------------------------------local function---------------------------------------------
local function GetTimeWithTimeZone(nSecondsUtc)
    return nSecondsUtc + nTimezoneOffsetSeconds
end

local function IfReachRefreshTimeInSameDay(nLastRefreshHour, nLastRefreshMinute, nRefreshHours, nRefreshMinutes)
    if nLastRefreshHour < nRefreshHours then
        return false
    elseif nLastRefreshHour == nRefreshHours then
        if nLastRefreshMinute < nRefreshMinutes then
            return false
        else
            return true
        end
    else
        return true
    end
end

local function GetNextRefreshSeconds(nLastRefreshSeconds, nRefreshHours, nRefreshMinutes)
    local tbLastRefreshDate = os.date("!*t", nLastRefreshSeconds)
    if IfReachRefreshTimeInSameDay(tbLastRefreshDate.hour, tbLastRefreshDate.min, nRefreshHours, nRefreshMinutes) then
        return nLastRefreshSeconds - tbLastRefreshDate.hour * TimeUtil.GetOneHourSeconds() - tbLastRefreshDate.min * TimeUtil.GetOneMinuteSeconds() - tbLastRefreshDate.sec
                    + TimeUtil.GetOneDaySeconds() + nRefreshHours * TimeUtil.GetOneHourSeconds() + nRefreshMinutes * TimeUtil.GetOneMinuteSeconds()

    else
        return nLastRefreshSeconds - tbLastRefreshDate.hour * TimeUtil.GetOneHourSeconds() - tbLastRefreshDate.min * TimeUtil.GetOneMinuteSeconds() - tbLastRefreshDate.sec
                    + nRefreshHours * TimeUtil.GetOneHourSeconds() + nRefreshMinutes * TimeUtil.GetOneMinuteSeconds()
    end
end

-----------------------------------------Init function---------------------------------------------

-- 设置与服务器校准的时区，只在校准时间时才调用
function TimeUtil.SetTimezoneOffsetSeconds(nOffsetSeconds)
    nTimezoneOffsetSeconds = nOffsetSeconds
end

-----------------------------------------时区无关的工具方法---------------------------------------------

-- 获得nTotalSeconds对应的天(>=0)、小时(0-23)、分钟(0-59)、秒(0-59)
function TimeUtil.GetDayHourMinuteSecond(nTotalSeconds)
    local nDay = math.floor(nTotalSeconds / ONEDAY_SECOND)
    local nHour = math.floor(nTotalSeconds / ONEHOUR_SECOND % ONEDAY_HOUR)
    local nMinute = math.floor(nTotalSeconds / ONEMINUTE_SECOND % ONEHOUR_MINUTE)
    local nSecond = nTotalSeconds % ONEMINUTE_SECOND
    return nDay, nHour, nMinute, nSecond
end

function TimeUtil.GetTotalSeconds(nDay, nHour, nMinute, nSecond)
    return nDay * ONEDAY_SECOND + nHour * ONEHOUR_SECOND + nMinute * ONEMINUTE_SECOND + nSecond
end

--获得nTotalSeconds对应的总的分钟数（天 小时也都折算成分钟）
function TimeUtil.GetTotalMinutes(nTotalSeconds)
    return math.floor(nTotalSeconds / ONEMINUTE_SECOND)
end

--获得nTotalSeconds对应的分钟内的秒数部分, (0-59)
function TimeUtil.GetSeconds(nTotalSeconds)
    return nTotalSeconds % ONEMINUTE_SECOND
end

--获得一天有多少秒
function TimeUtil.GetOneDaySeconds()
    return ONEDAY_SECOND
end

--获得一小时有多少秒
function TimeUtil.GetOneHourSeconds()
    return ONEHOUR_SECOND
end

--获得一分钟有多少秒
function TimeUtil.GetOneMinuteSeconds()
    return ONEMINUTE_SECOND
end

--获得几天几小时几分几秒的字符串
function TimeUtil.GetTimeString(nTotalSecond)
    local nDay, nHour, nMinute, nSecond = TimeUtil.GetDayHourMinuteSecond(nTotalSecond)
    if UISetUtils == nil then
        UISetUtils = require("UISetUtils")
    end
    local GetTextByKey = UISetUtils.GetTextByKey
    local szRemainTime = ""
    if nDay > 0 then
        szRemainTime = szRemainTime..nDay..GetTextByKey("COMMON_TIME_DAY")
    end
    if nHour > 0 then
        szRemainTime = szRemainTime..nHour..GetTextByKey("COMMON_TIME_HOUR")
    end
    if nMinute > 0 then
        szRemainTime = szRemainTime..nMinute..GetTextByKey("COMMON_TIME_MINUTE")
    end
    if nSecond > 0 then
        szRemainTime = szRemainTime..nSecond..GetTextByKey("COMMON_TIME_SECOND")
    end
    return szRemainTime
end

-- 通过字符串获得时间
-- 此方法建议在配置表导出时使用，运行时不要用
-- @param 字符串时间 格式：2019-03-11T11:37:04+0800
-- @return 当前秒数 错误日志（如果第一个返回值是nil，表示格式出错，会有第二个参数是错误日志）
function TimeUtil.GetTimeByString(szTime)
    local pattern = "(%d+)%-(%d+)%-(%d+)%a(%d+)%:(%d+)%:([%d%.]+)([Z%+%-])(%d?%d?)%:?(%d?%d?)"
    local year, month, day, hour, minute,
        seconds, offsetsign, offsethour, offsetmin = szTime:match(pattern)
    local timestamp = os.time{year = year, month = month,
        day = day, hour = hour, min = minute, sec = seconds}
    local offset = 0
    if offsetsign ~= 'Z' then
      offset = tonumber(offsethour) * 3600 + tonumber(offsetmin)
    --   if xoffset == "-" then offset = offset * -1 end
    end

    if tonumber(month) > 12 or tonumber(day) > 31 or tonumber(hour) >= 24 or tonumber(minute) >= 60 or tonumber(seconds) >= 60 then
        error("get time failed!"..szTime)
    end

    local now = os.time()
    local nLocalTimeZoneOffset = now - os.time(os.date("!*t", now))
    local result = timestamp - nLocalTimeZoneOffset + offset
    --log("TimeUtil.GetTimeByString", szTime, os.date("!%Y-%m-%dT%H:%M:%S", result), TimeUtil.GetTimeFormatString(result, "%Y-%m-%dT%H:%M:%S"))

    return result
end

-----------------------------------------时区相关的工具方法(客户端当前时区)---------------------------------------------

-- 获得日期的字符串，客户端当前时区
-- @param nTimestampSecondsUtc 需要显示的时间戳，utc时间
-- @param szTimeFormat 日期显示的字符串格式，eg："%Y-%m-%dT%H:%M:%S"
function TimeUtil.GetTimeFormatString(nTimestampSecondsUtc, szTimeFormat)
    return os.date(szTimeFormat, nTimestampSecondsUtc)
end

-----------------------------------------时区相关的工具方法(服务器下发的时区)---------------------------------------------

-- 获得距离下次刷新时间还有多少秒，如果已经过了刷新时间就返回0(使用服务器下发的时区计算)
-- @param nLastRefreshSecondsUtc 上次刷新时间
-- @param nRefreshHours，nRefreshMinutes 几点几分刷新，如果不传会默认为0
function TimeUtil.CalRefreshRemainSeconds(nLastRefreshSecondsUtc, nRefreshHours, nRefreshMinutes)
    if not nRefreshHours then
        nRefreshHours = 0
    end
    if not nRefreshMinutes then
        nRefreshMinutes = 0
    end

    local nLastRefreshSeconds = GetTimeWithTimeZone(nLastRefreshSecondsUtc)
    local nNextRefreshSeconds = GetNextRefreshSeconds(nLastRefreshSeconds, nRefreshHours, nRefreshMinutes)
    if GlobalVariableSystem == nil then
        GlobalVariableSystem = require("GlobalVariableSystem_C")
    end
    local nNowSecondsUtc = GlobalVariableSystem:GetServerTimeUtc()
    local nNowSeconds = GetTimeWithTimeZone(nNowSecondsUtc)
    if nNowSeconds > nNextRefreshSeconds then
        return 0
    end
    return nNextRefreshSeconds - nNowSeconds
end

-- 获得当前时间所在周的某一天的开始时间(使用服务器下发的时区计算)
-- @param nWday 周几,1~7
function TimeUtil.GetDayBeginTimeInCurrentWeek(nWday)
    if GlobalVariableSystem == nil then
        GlobalVariableSystem = require("GlobalVariableSystem_C")
    end
    local nNowSecondsUtc = GlobalVariableSystem:GetServerTimeUtc()
    local tbNowUtcDate = os.date("!*t", nNowSecondsUtc)
    local nTodayBeginSecondsUtc = nNowSecondsUtc - tbNowUtcDate.hour * TimeUtil.GetOneHourSeconds() - tbNowUtcDate.min * TimeUtil.GetOneMinuteSeconds() - tbNowUtcDate.sec
    local nTodayBeginSeconds = nTodayBeginSecondsUtc - nTimezoneOffsetSeconds
    local tbTodayDate = os.date("*t", nTodayBeginSeconds) 
    local wday = tbTodayDate.wday
    local nCurrentWday = nil
    if wday == 1 then
        nCurrentWday = 7
    else
        nCurrentWday = wday - 1
    end
    local nResultSecond = nil
    if nCurrentWday == nWday then
        nResultSecond = nTodayBeginSeconds
    elseif nCurrentWday > nWday then
        nResultSecond = nTodayBeginSeconds - (nCurrentWday - nWday) * TimeUtil.GetOneDaySeconds()
    else
        nResultSecond = nTodayBeginSeconds + (nWday - nCurrentWday) * TimeUtil.GetOneDaySeconds()
    end
    return nResultSecond
end

-- 获取nTimeStamp到所在周最后时间的时长 所在周起始为周1
function TimeUtil.GetWeekRemainTime(nTimeStamp)
    local tbUtcDate = os.date("!*t", nTimeStamp)
    local nBeginSecondsUtc = nTimeStamp - tbUtcDate.hour * TimeUtil.GetOneHourSeconds() - tbUtcDate.min * TimeUtil.GetOneMinuteSeconds() - tbUtcDate.sec
    local nBeginSeconds = nBeginSecondsUtc - nTimezoneOffsetSeconds
    local nEndSeconds = nBeginSeconds + ONEDAY_SECOND - 1
    local tbDate = os.date("*t", nBeginSeconds) 
    local nWday = 1 
    if tbDate.wday == 1 then
        nWday = 7
    else
        nWday = tbDate.wday - 1
    end
    local nRemainTime = (7 - nWday) * ONEDAY_SECOND + (nEndSeconds - nTimeStamp)
    

    return nRemainTime
end

function TimeUtil.TimeToDHMS(nTime)
    local nDay = math.floor(nTime / ONEDAY_SECOND)
    local nTemp = nTime - nDay * ONEDAY_SECOND
    local nHour = math.floor(nTemp / ONEHOUR_SECOND)
    nTemp = nTemp - nHour * ONEHOUR_SECOND
    local nMin = math.floor(nTemp / ONEMINUTE_SECOND)
    local nSec = nTemp - nMin * ONEMINUTE_SECOND
    return nDay, nHour, nMin, nSec
end

function TimeUtil.GetDayOfYearOffset(nInputTimeSec)
    local nNowSecondsUtc = GlobalVariableSystem:GetServerTimeUtc()
    local tbTodayDate = os.date("*t", nNowSecondsUtc) 

    local tbInputDate = os.date("*t", nInputTimeSec)  
    return tbTodayDate.yday -  tbInputDate.yday 
end

function TimeUtil.GetMonthDay(nInputTimeSec)
    local tbDate = os.date("*t", nInputTimeSec) 
    return tbDate.month, tbDate.day
end

return TimeUtil