-----------------------------------------------------
--File Name    : SkillDataTable.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-18
--Description  : 技能配置表
-----------------------------------------------------

local SkillDataTable = {}

SkillDataTable.szFileName = "common/battle_ability/skill.tab"

function SkillDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                 , "id"                      , -1    , Parser.TypeInt)
    Parser:Define("nType"               , "type"                    , -1    , Parser.TypeInt)
    Parser:Define("nMaxLevel"           , "max_level"               , -1    , Parser.TypeInt)
    Parser:Define("szActionGroupList"   , "magic_list"              , ""    , Parser.TypeString)
    Parser:Define("nTargetType"         , "target_type"             , -1    , Parser.TypeInt)
    Parser:Define("nEffectiveTargetType", "effective_target_type"   , 0     , Parser.TypeInt)
    Parser:Define("nRangeType"          , "range_type"              , -1    , Parser.TypeInt)
    Parser:Define("tbRangeParams"       , "range_params"            , -1    , Parser.TypeArrayInt)
    Parser:Define("nCenterTarget"       , "center_target"           , -1    , Parser.TypeInt)
    Parser:Define("nCenterOffset"       , "center_offset"           , -1    , Parser.TypeInt)
    Parser:Define("nCenterAngleOffset"  , "center_angle_offset"     , -1    , Parser.TypeInt)
    Parser:Define("nMaxEffectCount"     , "max_effect_count"        , -1    , Parser.TypeInt)
    Parser:Define("nCdTime"             , "cd_time"                 , -1    , Parser.TypeInt)
    Parser:Define("bImmediatelyCd"      , "immediately_cd"          , true  , Parser.TypeBool)
    Parser:Define("nMaxCastCount"       , "max_cast_count"          , -1    , Parser.TypeInt)
    Parser:Define("szConditionList"     , "condition_list"          , ""    , Parser.TypeString)
    Parser:Define("szConsumableList"    , "consumable_list"         , ""    , Parser.TypeString)
    Parser:Define("szEventList"         , "event_list"              , ""    , Parser.TypeString)
    Parser:Define("nSubSkillId"         , "sub_skill_id"            , -1    , Parser.TypeInt)
    Parser:Define("bUseTimeline"        , "use_timeline"            , false , Parser.TypeBool)
    Parser:Define("nResId"              , "res_id"                  , -1    , Parser.TypeInt)
    Parser:Define("nTriggerType"        , "trigger_type"            , -1    , Parser.TypeInt)
    Parser:Define("bIgnoreGlobalCD"     , "ignore_global_cd"        , false , Parser.TypeBool)
    Parser:Define("bHideSkillRange"     , "hide_skill_range"        , false , Parser.TypeBool)
end

-- [EXPORT BEGIN]
local StringUtil = require("StringUtil")
local AbilityParamParseUtils = require("AbilityParamParseUtils")

local SPLIT_CHAR = ";"
local ABILITY_EVENT_PREFIX = "Event"
local ABILITY_CONDITION_PREFIX = "Condition"
local ABILITY_CONSUMABLE_PREFIX = "Consumable"
local ABILITY_ACTION_PREFIX = "Action"
local ABILITY_CONDITION_CD_SUFFIX = "CD"
local ABILITY_CONDITION_MAX_CAST_COUNT_SUFFIX = "MaxCastCount"
local ABILITY_ACTION_GROUP_PATTERN = "(%d+)={(.-)}"
local FILENAME_FORMAT = "Ability%s_%s"
-- [EXPORT END]

-- local nTempTemplateId = -1

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
local function ParseEvent(tbNewTemplate)
    local tbEventList = {}
    if ParseParamString(ABILITY_EVENT_PREFIX, tbNewTemplate.szEventList, tbEventList) == false then
        return false
    end
    -- tbNewTemplate.tbEventList = tbEventList
    -- tbNewTemplate.szEventList = nil
    return true
end

-- 解析Condition参数
local function ParseCondition(tbNewTemplate)
    local tbConditionList = {}
    if ParseParamString(ABILITY_CONDITION_PREFIX, tbNewTemplate.szConditionList, tbConditionList) == false then
        return false
    end
    local nMaxCastCount = tbNewTemplate.nMaxCastCount
    if nMaxCastCount > 0 then
        local szScriptName = string.format(FILENAME_FORMAT, ABILITY_CONDITION_PREFIX, ABILITY_CONDITION_MAX_CAST_COUNT_SUFFIX)
        tbConditionList[szScriptName] = nMaxCastCount
    end

    local nCdTime = tbNewTemplate.nCdTime
    if nCdTime > 0 then
        local szScriptName = string.format(FILENAME_FORMAT, ABILITY_CONDITION_PREFIX, ABILITY_CONDITION_CD_SUFFIX)
        tbConditionList[szScriptName] = nCdTime
    end
    -- tbNewTemplate.tbConditionList = tbConditionList
    -- tbNewTemplate.szConditionList = nil
    return true
end

-- 解析Consumable参数
local function ParseConsumable(tbNewTemplate)
    local tbConsumableList = {}
    if ParseParamString(ABILITY_CONSUMABLE_PREFIX, tbNewTemplate.szConsumableList, tbConsumableList) == false then
        return false
    end
    -- tbNewTemplate.tbConsumableList = tbConsumableList
    -- tbNewTemplate.szConsumableList = nil
    return true
end

-- 解析Action参数
local function ParseActionGroup(tbNewTemplate)
    -- local tbActionGroupList = {}
    local iteratorFunc = string.gmatch(tbNewTemplate.szActionGroupList, ABILITY_ACTION_GROUP_PATTERN) -- 返回的迭代器用于给Action分组
    for szIndex, szActionInfos in iteratorFunc do
        local tbActionList = {}
        if ParseParamString(ABILITY_ACTION_PREFIX, szActionInfos, tbActionList) == false then
            return false
        end
        -- tbActionGroupList[tonumber(szIndex)] = tbActionList
    end
    -- tbNewTemplate.tbActionGroupList = tbActionGroupList
    -- tbNewTemplate.szActionGroupList = nil
    return true
end

-- 将Ability相关参数解析后导出
function SkillDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    -- nTempTemplateId = tbNewTemplate.nId
    if ParseEvent(tbNewTemplate) == false
    or ParseCondition(tbNewTemplate) == false
    or ParseConsumable(tbNewTemplate) == false
    or ParseActionGroup(tbNewTemplate) == false then
        return false
    end
    return true
end

-- 验证配置表填写是否正确
function SkillDataTable:OnEditorParseFinished()
    for nId, tbTemplate in pairs(self.tbContainer) do
        local tbSkillResTemplate = SkillDataTable:GetResTemplate(tbTemplate.nResId)
        if not tbSkillResTemplate then
            error("cannot find skill res ic, skill id:" .. nId)
        end
    end
end

-- [EXPORT BEGIN]
local SkillResDataTable = require("SkillResDataTable")
local SkillTriggerTypeDef = require("SkillTriggerTypeDefine")

function SkillDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end

-- 获取技能资源配置
function SkillDataTable:GetResTemplate(nTemplateId)
    local tbTemplate = self:GetTemplate(nTemplateId)
    if tbTemplate then
        local nSkillResTemplateId = tbTemplate.nResId
        return SkillResDataTable:GetTemplate(nSkillResTemplateId)
    elseif nTemplateId ~= -1 then
        logerror("Cannot find skill template with template_id:", nTemplateId)
    end
    return nil
end

function SkillDataTable:IsActiveSkill(nTemplateId)
    local bRet = false
    local tbTemplate = self:GetTemplate(nTemplateId)
    if tbTemplate then
        bRet = tbTemplate.nTriggerType == SkillTriggerTypeDef.ACTIVE
    end
    return bRet
end

function SkillDataTable:GetSkillActionList(nTemplateId)
    local tbActionList = {}
    local tbSkillTemplate = SkillDataTable:GetTemplate(nTemplateId)
    if tbSkillTemplate then
        local iteratorFunc = string.gmatch(tbSkillTemplate.szActionGroupList, ABILITY_ACTION_GROUP_PATTERN) -- 返回的迭代器用于给Action分组
        for szIndex, szActionInfos in iteratorFunc do
            local tbActionInfoList = StringUtil.Split(szActionInfos, ";") -- 分割多个Action
            for i,v in ipairs(tbActionInfoList) do
                local szName, tbParams = AbilityParamParseUtils.GetParamListWithLevel(v, self.nLevel)
                table.insert(tbActionList, {
                    szName = szName,
                    tbParams = tbParams
                })
            end
        end
    end
    return tbActionList
end
-- [EXPORT END]

return SkillDataTable
