-----------------------------------------------------
--File Name    : AbilityParamParseUtils.lua
--Author       : Song Fuhao
--Create Time  : 2017-05-03
--Description  :
-----------------------------------------------------
local AbilityParamParseUtils = {}

local StringUtil = require("StringUtil")

local KEY_AND_VALUE_FORMAT      = "(.+)=(.+)"
local KEY_AND_SUB_KEY_FORMAT    = "(.+)_(.+)"
local PARAM_LEVEL_VALUE_ORIGIN  = "L"
local PARAM_LEVEL_VALUE_START   = "LS"
local PARAM_LEVEL_VALUE_DELTA   = "LD"
local LIST_PARAM_SEPARATOR      = "|"

local function GetRealTypeValue(szValue)
    local tbParams = StringUtil.Split(szValue, LIST_PARAM_SEPARATOR)
    if #tbParams <= 1 then
        return StringUtil.GetRealTypeValue(szValue)
    end
    local tbResult = {}
    for _, v in ipairs(tbParams) do
        table.insert(tbResult,  StringUtil.GetRealTypeValue(v))
    end
    return tbResult
end

-- 解析参数列表
function AbilityParamParseUtils.GetParamList( szParams )
    local tbParamInfos = StringUtil.Split(szParams, ",")
    local tbParams = {}
    for i=2,#tbParamInfos do
        local szParam = tbParamInfos[i]
        local szKey, szValue = string.match(szParam, KEY_AND_VALUE_FORMAT)
        if szKey and szValue then
            local szRealKey, szSubKey = string.match(szKey, KEY_AND_SUB_KEY_FORMAT)
            if szRealKey and szSubKey then
                if not tbParams[szRealKey] then
                    tbParams[szRealKey] = {}
                end
                tbParams[szRealKey][szSubKey] = GetRealTypeValue(szValue)
            else
                tbParams[szKey] = GetRealTypeValue(szValue)
            end
        else
            tbParams[szParam] = true
        end
    end
    return tbParamInfos[1], tbParams
end

-- 根据等级解析参数列表
function AbilityParamParseUtils.GetParamListWithLevel( szParams, nLevel )
    local szName, tbParams = AbilityParamParseUtils.GetParamList(szParams)
    for k,v in pairs(tbParams) do
        if type(v) == "table" then
            if v[PARAM_LEVEL_VALUE_ORIGIN] then
                tbParams[k] = v[PARAM_LEVEL_VALUE_ORIGIN][nLevel]
            else
                local nStart = v[PARAM_LEVEL_VALUE_START]
                local nDelta = v[PARAM_LEVEL_VALUE_DELTA]
                if nStart and nDelta then
                    tbParams[k] = nStart + nDelta * (nLevel - 1)
                end
            end
        end
    end
    return szName, tbParams
end

return AbilityParamParseUtils
