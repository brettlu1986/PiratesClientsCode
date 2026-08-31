-----------------------------------------------------
--File Name    : BattleBuffDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-21
--Description  : 战斗Buff配置表
-----------------------------------------------------

local BattleBuffDataTable = {}

BattleBuffDataTable.szFileName = "common/battle_ability/battle_buff.tab"

function BattleBuffDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                 , "id"                      , -1    , Parser.TypeInt)
    Parser:Define("nTime"               , "time"                    , -1    , Parser.TypeInt)
    Parser:Define("nType"               , "type"                    , -1    , Parser.TypeInt)
    Parser:Define("nGroupId"            , "group_id"                , -1    , Parser.TypeInt)
    Parser:Define("tbMutexs"            , "mutex_list"              , nil   , Parser.TypeArrayInt)
    Parser:Define("nMaxOverlap"         , "max_overlap"             , 1     , Parser.TypeInt)
    Parser:Define("nIndividualType"     , "individual_type"         , 0     , Parser.TypeInt)
    Parser:Define("bEffectToInstigator" , "effect_to_instigator"    , false , Parser.TypeBool)
    Parser:Define("szEventList"         , "event_list"              , nil   , Parser.TypeString)
    Parser:Define("szActionList"        , "action_list"             , nil   , Parser.TypeString)
    Parser:Define("szConditionList"     , "condition_list"          , nil   , Parser.TypeString)
    Parser:Define("szPostCheckList"     , "post_check_list"         , nil   , Parser.TypeString)
    Parser:Define("nResId"              , "res_id"                  , -1    , Parser.TypeInt)
    Parser:Define("nAddableTargetType"  , "addable_target_type"     , 0     , Parser.TypeInt)
    Parser:Define("nRemoveTypeOnSwitch" , "remove_type_on_switch"   , 0     , Parser.TypeInt)
    Parser:Define("nEffectiveTargetType", "effective_target_type"   , 0     , Parser.TypeInt)
end

-- [EXPORT BEGIN]
local L10N = require("L10N")
local StringUtil = require("StringUtil")
local PropertyComboDataTable = require("PropertyComboDataTable")
local AbilityParamParseUtils = require("AbilityParamParseUtils")
local BattleBuffResDataTable = require("BattleBuffResDataTable")

local STATUS_PARAM_SPLIT_CHAR   = ";"
local PROP_COMBO_DESC_KEY       = "PropCombo"
local PROP_COMBO_DESC_SUB_KEY   = "Id"

function BattleBuffDataTable:GetTemplate( nTemplateId )
    return self.tbContainer[nTemplateId]
end

function BattleBuffDataTable:GetResTemplate( nTemplateId )
    local tbTemplate = self:GetTemplate(nTemplateId)
    if tbTemplate then
        local nResTemplateId = tbTemplate.nResId
        return BattleBuffResDataTable:GetTemplate(nResTemplateId)
    else
        logerror("Cannot find buff template with template_id:", nTemplateId)
    end
end

function BattleBuffDataTable:GetBuffParam( nBuffId, nLevel, szDescKey, szDescSubKey )
    local tbStatusTemplate = BattleBuffDataTable:GetTemplate(nBuffId)
    local tbSubBuffInfoList = StringUtil.Split(tbStatusTemplate.szActionList, STATUS_PARAM_SPLIT_CHAR)
    for _,szSubBuffInfo in ipairs(tbSubBuffInfoList) do
        local szSubBuffName, tbSubBuffParamList = AbilityParamParseUtils.GetParamListWithLevel(szSubBuffInfo, nLevel)
        if szSubBuffName == szDescKey then
            local varParam = tbSubBuffParamList[szDescSubKey]
            if varParam then
                return varParam
            elseif szDescKey == PROP_COMBO_DESC_KEY then
                local nComboId = tbSubBuffParamList[PROP_COMBO_DESC_SUB_KEY]
                local tbComboTemplate = PropertyComboDataTable:GetTemplate(nComboId)
                if tbComboTemplate then
                    local _, nValue = next(tbComboTemplate.tbProperties[szDescSubKey])
                    return nValue
                else
                    logerror("GetBuffParam failed, cannot find prop combo, nBuffId, nLevel, nComboId, szDescSubKey =", nBuffId, nLevel, nComboId, szDescSubKey)
                end
            end
        end
    end
    return nil
end

function BattleBuffDataTable:GetStatusDescTipData( nBuffId, nLevel )
    local tbResTemplate = self:GetResTemplate(nBuffId)
    if tbResTemplate then
        local l10nDetail = tbResTemplate.l10nDesc
        if tbResTemplate.tbDescInfos then
            local tbNames = {}
            local tbArgs = {}
            for _, tbDescInfo in pairs(tbResTemplate.tbDescInfos) do
                local nParam = self:GetBuffParam(nBuffId, nLevel, tbDescInfo.szMainKey, tbDescInfo.szSubKey)
                if tbDescInfo.fnCalcValue then
                    nParam = tbDescInfo.fnCalcValue(nParam)
                end
                table.insert(tbNames, tbDescInfo.szPlaceholder)
                table.insert(tbArgs, nParam or "None")
            end
            l10nDetail = L10N:FormatByName(l10nDetail, tbNames, tbArgs)
        end
        local tbRet = {}
        tbRet.szTitle = tbResTemplate.l10nName
        tbRet.szDetail = l10nDetail
        tbRet.szIconPath = tbResTemplate.szIconRes
        return tbRet
    end
    return nil
end
-- [EXPORT END]

--[[
    DataTable Export logic Begin
]]
local SPLIT_CHAR = ";"
local ABILITY_EVENT_PREFIX = "Event"
local ABILITY_CONDITION_PREFIX = "Condition"
local ABILITY_ACTION_PREFIX = "Action"
local FILENAME_FORMAT = "Ability%s_%s"

local nTempTemplateId = -1

-- 检查文件是否存在
local function IsFileExist(szAbilityPrefix, szScriptName)
    -- if require(szScriptName) then
    --     return true
    -- end
    -- logerror(string.format("Parse failed, Id = %s, FileName = %s", nTempTemplateId, szScriptName))
    -- return false
    return true
end

-- 解析参数
local function ParseParamString(szAbilityPrefix, szParamString, tbOutList)
    local tbParamList = StringUtil.Split(szParamString, SPLIT_CHAR)
    for i,v in ipairs(tbParamList) do
        local szName, tbParams = AbilityParamParseUtils.GetParamList(v)
        local szScriptName = string.format(FILENAME_FORMAT, szAbilityPrefix, szName)
        if IsFileExist(szAbilityPrefix, szScriptName) == false then
            return false
        end
        tbOutList[szScriptName] = tbParams
    end
    return true
end

-- 解析Event参数
local function ParseAbility(szAbilityPrefix, tbNewTemplate, szPramsStringName, szParamListName)
    local tbParamList = {}
    if ParseParamString(szAbilityPrefix, tbNewTemplate[szPramsStringName], tbParamList) == false then
        return false
    end
    -- tbNewTemplate[szParamListName] = tbParamList
    -- tbNewTemplate[szPramsStringName] = nil
    return true
end

-- 将Ability相关参数解析后导出
function BattleBuffDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    nTempTemplateId = tbNewTemplate.nId
    if ParseAbility(ABILITY_EVENT_PREFIX, tbNewTemplate, "szEventList", "tbEventList") == false
    or ParseAbility(ABILITY_CONDITION_PREFIX, tbNewTemplate, "szConditionList", "tbConditionList") == false
    or ParseAbility(ABILITY_CONDITION_PREFIX, tbNewTemplate, "szPostCheckList", "tbPostCheckList") == false
    or ParseAbility(ABILITY_ACTION_PREFIX, tbNewTemplate, "szActionList", "tbActionList") == false then
        return false
    end
    if tbNewTemplate.bIndividual and tbNewTemplate.nMaxOverlap ~= 1 then
        error("BattleBuffDataTable individual buff must be configurated with max_overlap 1. BuffId: "..nTempTemplateId)
        return false
    end
    return true
end
--[[
    DataTable Export logic End
]]

return BattleBuffDataTable
