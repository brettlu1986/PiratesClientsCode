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
local ResearchBuildingDescDataTable = {}

local L10N = require("L10N")

ResearchBuildingDescDataTable.szFileName = "common/homeland/research/research_building_desc.tab"

function ResearchBuildingDescDataTable:OnEditorDefine(Parser)
    Parser:Define("nTypeId"                    , "type_id"                      , -1              , Parser.TypeInt)
    Parser:Define("nGrade"                     , "grade"                        , -1              , Parser.TypeInt)
    Parser:Define("l10nContent"                , "content"                      , L10N.NullString , Parser.TypeL10N)
end

function ResearchBuildingDescDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nTypeId = tbNewTemplate.nTypeId
    local tbTemplates = tbContainer[nTypeId]
    if tbTemplates == nil then
        tbContainer[nTypeId] = {}
        tbTemplates = tbContainer[nTypeId]
    end
    tbTemplates[tbNewTemplate.nGrade] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function ResearchBuildingDescDataTable:GetTemplate(nTypeId, nGrade)
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
function ResearchBuildingDescDataTable:GetTemplatesByType(nTypeId)
    local tbTemplates = self.tbContainer[nTypeId]
    if tbTemplates == nil then
        error("Cannot find landmark building type!nTypeId:"..nTypeId)
    end
    return tbTemplates
end
-- [EXPORT END]

return ResearchBuildingDescDataTable
