-----------------------------------------------------
--File Name    : BattleHumanDecorationDescParser.lua
--Author       : ZhangWei
--Create Time  : 2020-07-02
--Description  : 饰品附加描述（desc_append）解析器
-----------------------------------------------------
local BattleHumanDecorationDescParser = {}

local L10N = require("L10N")
local StringUtil = require("StringUtil")
local ItemSystem = require("ItemSystem")
local BattleBuffDataTable = require("BattleBuffDataTable")

-- DESC_APPEND_PARAM_PATTERN 支持 {MainKey.SubKey, Ratio} 的形式，其中 Ratio 可选，例如：“人船重伤血量流失速度减少{PropCombo.HumanDyingHpReduceSpeed,100}%” 
local DESC_APPEND_PARAM_PATTERN     = "{((.-)%.(.-),?(%d-))}"
local DESC_APPEND_ITEM_SPLIT_CHAR   = "|"
local DESC_APPEND_VALUE_START_CHAR  = "{"
local DESC_APPEND_PERCENT_PATTERN   = "}%"

local function GetDescAppendDisplayValue( nValue, bPercent )
    if type(nValue) ~= 'number' then
        return nil
    end

    local szRetValue = nil
    if not bPercent then
        if nValue % 1 == 0 then
            szRetValue = string.format("%d", nValue)
        else
            szRetValue = string.format("%.2f", nValue)
        end
    else
        szRetValue = string.format("%.2f%%", nValue * 100)
    end

    if nValue > 0 then
        szRetValue = "+" .. szRetValue
    end

    return szRetValue
end

function BattleHumanDecorationDescParser:GetDescAppendDisplayInfoList( nDecorationId )
    local tbDisplayInfoList = {}

    local tbDecorationTemplate = ItemSystem:GetItemTemplate(nDecorationId)
    if not tbDecorationTemplate then
        return tbDisplayInfoList
    end

    local nBuffId = tbDecorationTemplate.nBuffId
    local nLevel = tbDecorationTemplate.nLevel

    local tbDescAppendList = StringUtil.Split(L10N:ToString(tbDecorationTemplate.l10nDescAppend), DESC_APPEND_ITEM_SPLIT_CHAR)
    for _,szOneDescAppendItem in ipairs(tbDescAppendList) do
        local tbNames = {}
        local tbArgs = {}
        local iteratorFunc = string.gmatch(szOneDescAppendItem, DESC_APPEND_PARAM_PATTERN)    
        for szMatch, szMainKey, szSubKey, szRatio in iteratorFunc do
            local nParam = BattleBuffDataTable:GetBuffParam(nBuffId, nLevel, szMainKey, szSubKey)
            local nRatio = StringUtil.IsEmptyString(szRatio) and 1 or tonumber(szRatio)
            table.insert(tbNames, szMatch)
            table.insert(tbArgs, nParam and (math.abs(nParam) * nRatio) or "None")
        end

        local l10nOneItemFullDesc = L10N:FormatByName(szOneDescAppendItem, tbNames, tbArgs)
        local tbDisplayNameAndValue = StringUtil.Split(szOneDescAppendItem, DESC_APPEND_VALUE_START_CHAR)
        local bPercent = false
        local nPos = string.find(szOneDescAppendItem, DESC_APPEND_PERCENT_PATTERN, 1, true) -- plain find
        if nPos then
           bPercent = true 
        end
        local szOneItemValue = GetDescAppendDisplayValue(tbArgs[1], bPercent)

        table.insert(tbDisplayInfoList, {
            l10nFullDesc = l10nOneItemFullDesc,
            l10nDisplayName = tbDisplayNameAndValue[1],
            szDisplayValue = szOneItemValue
        })
    end

    return tbDisplayInfoList
end

return BattleHumanDecorationDescParser