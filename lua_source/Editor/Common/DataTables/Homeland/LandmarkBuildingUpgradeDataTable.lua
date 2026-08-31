--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local LandmarkBuildingUpgradeDataTable = {}

local StringUtil = require("StringUtil")
local LandmarkBuildingTypeDataTable = require("LandmarkBuildingTypeDataTable")
local L10N = require("L10N")

LandmarkBuildingUpgradeDataTable.szFileName = "common/homeland/landmark_building_upgrade.tab"

local UNVALID_GRADE = -1
local UNLOCK_CONTENT_COUNT = 10
local UNLOCK_CONTENT_KEY_PREFIX = "l10nUnlockContent_"

-- [EXPORT]
LandmarkBuildingUpgradeDataTable.tbMinAndMaxGrades = {}

function LandmarkBuildingUpgradeDataTable:OnEditorDefine(Parser)
    Parser:Define("nTypeId"                    , "type_id"                      , -1              , Parser.TypeInt)
    Parser:Define("nGrade"                     , "grade"                        , -1              , Parser.TypeInt)
    Parser:Define("nCurrencyId"                , "currency_id"                  , -1              , Parser.TypeInt)
    Parser:Define("nCurrencyCost"              , "currency_cost"                , -1              , Parser.TypeInt)
    Parser:Define("nTimeCost"                  , "time_cost"                    , -1              , Parser.TypeInt)
    Parser:Define("szPrerequisiteLandmark"     , "prerequisite_landmark"        , ""              , Parser.TypeString)
    Parser:Define("nPropertyComboId"           , "property_combo_id"            , 0               , Parser.TypeInt)
    for i = 1, UNLOCK_CONTENT_COUNT do
        Parser:Define(UNLOCK_CONTENT_KEY_PREFIX..i  , "unlock_content_"..i           , L10N.NullString , Parser.TypeL10N)
    end
end

function LandmarkBuildingUpgradeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nTypeId = tbNewTemplate.nTypeId
    local tbTemplates = tbContainer[nTypeId]
    if tbTemplates == nil then
        tbContainer[nTypeId] = {}
        tbTemplates = tbContainer[nTypeId]
    end
    tbTemplates[tbNewTemplate.nGrade] = tbNewTemplate

    local nGrade = tbNewTemplate.nGrade
    local nGradeData = self.tbMinAndMaxGrades[nTypeId]
    if nGradeData == nil then
        self.tbMinAndMaxGrades[nTypeId] = {}
        nGradeData = self.tbMinAndMaxGrades[nTypeId]
        nGradeData.nMinGrade = UNVALID_GRADE
        nGradeData.nMaxGrade = 0
    end

    if nGrade > nGradeData.nMaxGrade then
        nGradeData.nMaxGrade = nGrade
    end

    if nGradeData.nMinGrade == UNVALID_GRADE or nGrade < nGradeData.nMinGrade then
        nGradeData.nMinGrade = nGrade
    end

    local nCurrencyCost = tbNewTemplate.nCurrencyCost
    if nCurrencyCost ~= nil and nCurrencyCost > 0 then
        local nCurrencyId = tbNewTemplate.nCurrencyId
        if nCurrencyId == nil or nCurrencyId <= 0 then
            error("cannot find currency id! nTypeId:"..nTypeId..",nGrade:"..nGrade)
        end
    end

    local szPrerequisiteLandmark = tbNewTemplate.szPrerequisiteLandmark

    if szPrerequisiteLandmark ~= nil and szPrerequisiteLandmark ~= "" then
        tbNewTemplate.tbPrerequisiteLandmarks = {}
        local tbLandmarks = StringUtil.Split(szPrerequisiteLandmark, ";")
        for _, v in ipairs(tbLandmarks) do
            local tbDatas = StringUtil.Split(v, ",")
            if #tbDatas ~= 2 then
                error("invalid Prerequisite Landmark! nTypeId:"..nTypeId..",nGrade:"..nGrade..", szPrerequisiteLandmark", szPrerequisiteLandmark)
            else
                local tbPrerequisite = {}
                tbPrerequisite.nPrerequisiteLandmarkType = tonumber(tbDatas[1])
                tbPrerequisite.nPrerequisiteLandmarkGrade = tonumber(tbDatas[2])
                table.insert(tbNewTemplate.tbPrerequisiteLandmarks, tbPrerequisite)
                local nPrerequisiteLandmarkType = tbPrerequisite.nPrerequisiteLandmarkType
                if not LandmarkBuildingTypeDataTable:GetTemplate(nPrerequisiteLandmarkType) then
                    error("Cannot find nPrerequisiteLandmarkType! nTypeId:"..nTypeId..",nGrade:"..nGrade
                    ..", nPrerequisiteLandmarkType"..nPrerequisiteLandmarkType..", szPrerequisiteLandmark", szPrerequisiteLandmark)
                end
            end
        end
    end
    local tbUnlockContents = {}
    for i = 1, UNLOCK_CONTENT_COUNT do
        table.insert(tbUnlockContents, tbNewTemplate[UNLOCK_CONTENT_KEY_PREFIX..i])
    end
    tbNewTemplate.tbUnlockContents = tbUnlockContents
    return true
end

-- [EXPORT BEGIN]
function LandmarkBuildingUpgradeDataTable:GetTemplate(nTypeId, nGrade)
    local tbTemplates = self.tbContainer[nTypeId]
    if tbTemplates == nil then
        error("Cannot find landmark building type!nTypeId:"..nTypeId..", nGrade:"..nGrade)
    end
    local tbTemplate = tbTemplates[nGrade]
    if tbTemplate == nil then
        error("Cannot find landmark building grade!nTypeId:"..nTypeId..", nGrade:"..nGrade)
    end
    return tbTemplate
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function LandmarkBuildingUpgradeDataTable:GetMaxGrade(nTypeId)
    local tbGradeData = self.tbMinAndMaxGrades[nTypeId]
    if tbGradeData == nil then
        error("Cannot find landmark building max grade!nTypeId:"..nTypeId)
    end
    return tbGradeData.nMaxGrade
end

-- [EXPORT BEGIN]
function LandmarkBuildingUpgradeDataTable:GetAllGradeData()
    return self.tbMinAndMaxGrades
end

function LandmarkBuildingUpgradeDataTable:GetPrerequisiteLandmarks(nTypeId, nGrade)
    local tbTemplate = self:GetTemplate(nTypeId, nGrade)
    if not tbTemplate then
        return
    end
    return tbTemplate.tbPrerequisiteLandmarks
end
-- [EXPORT END]

return LandmarkBuildingUpgradeDataTable
