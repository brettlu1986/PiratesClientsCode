-----------------------------------------------------
--File Name    : SelfTimeCalculateHelper.lua
--Author       : Chang Nan
--Create Time  : 2017-03-28
--Description  : tbSelfTimeCalculateHelper
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfTimeCalculateHelper = luaclass("SelfTimeCalculateHelper")
local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local GetL10NTextByKey = UISetUtils.GetL10NTextByKey
local GetTextByKey = UISetUtils.GetTextByKey

local L10N_OUT_OF_TIME_SOON = GetL10NTextByKey("SELFTIMECALCULATEHELPER_L10N_OUT_OF_TIME_SOON")
local L10N_DAY = GetL10NTextByKey("SELFTIMECALCULATEHELPER_L10N_DAY")
local L10N_HOUR = GetL10NTextByKey("SELFTIMECALCULATEHELPER_L10N_HOUR")
local L10N_MIN = GetL10NTextByKey("SELFTIMECALCULATEHELPER_L10N_MIN")
-- local L10N_TIME_FORMAT = GetL10NTextByKey("SELFTIMECALCULATEHELPER_L10N_TIME_FORMAT")

local DEADLINE_THRESHOLD = 5
local ONEMINUTE_SECOND= 60
local ONEHOUR_SECOND  = ONEMINUTE_SECOND * 60
local ONEDAY_SECOND   = ONEHOUR_SECOND * 24

--得到最大单位的剩余时间（如一天零5小时则得到一天）,如果小于5分钟则返回“即将到期”
function SelfTimeCalculateHelper:GetMaxUnitLastTime(nTime)
    local nTimeResault = 0
    local nOneDaySecond = 3600*24
    local nOneHourSecond = 3600
    local nOneMinSecond = 60
    local szTiemResault = ""

    nTimeResault = math.floor(nTime/nOneDaySecond)
    if nTimeResault>0 then
        szTiemResault = L10N:ToString(L10N:Format(L10N_DAY, nTimeResault))
        return szTiemResault
    end

    nTimeResault = math.floor(nTime/nOneHourSecond)
    if nTimeResault>0 then
        szTiemResault = L10N:ToString(L10N:Format(L10N_HOUR, nTimeResault))
        return szTiemResault
    end

    nTimeResault = math.floor(nTime/nOneMinSecond)
    if nTimeResault>0 then
        if nTimeResault < DEADLINE_THRESHOLD then
            szTiemResault = L10N:ToString(L10N_OUT_OF_TIME_SOON)
            return szTiemResault
        end
        szTiemResault = L10N:ToString(L10N:Format(L10N_MIN, nTimeResault))
        return szTiemResault
    end

    szTiemResault = L10N:ToString(L10N_OUT_OF_TIME_SOON)
    return szTiemResault
end

function SelfTimeCalculateHelper:GetFormatRemainTime(nRemainTime, nPrecision)
    if nPrecision == nil then
        nPrecision = 4
    end
    local nDay, nHour, nMinute, nSecond = math.floor(nRemainTime/ONEDAY_SECOND), math.floor(nRemainTime/ONEHOUR_SECOND%24),
        math.floor(nRemainTime/ONEMINUTE_SECOND%60), nRemainTime%60
    local szRemainTime = ""
    local nCount = 0
    if nDay > 0 then
        szRemainTime = szRemainTime..nDay..GetTextByKey("COMMON_TIME_DAY")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime
        end
    end
    if nHour > 0 then
        szRemainTime = szRemainTime..nHour..GetTextByKey("COMMON_TIME_HOUR")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime
        end
    end
    if nMinute > 0 then
        szRemainTime = szRemainTime..nMinute..GetTextByKey("COMMON_TIME_MINUTE")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime
        end
    end
    if nSecond > 0 then
        szRemainTime = szRemainTime..nSecond..GetTextByKey("COMMON_TIME_SECOND")
        nCount = nCount + 1
        if nPrecision == nCount then
            return szRemainTime
        end
    end
    return szRemainTime
end


return SelfTimeCalculateHelper
