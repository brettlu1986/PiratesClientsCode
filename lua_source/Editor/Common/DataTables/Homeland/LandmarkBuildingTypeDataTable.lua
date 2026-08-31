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
local LandmarkBuildingTypeDataTable = {}

local L10N = require("L10N")

LandmarkBuildingTypeDataTable.szFileName = "common/homeland/landmark_building_type.tab"

function LandmarkBuildingTypeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nTypeId")
    Parser:Define("nTypeId"              , "type_id"        , -1             , Parser.TypeInt)
    Parser:Define("l10nName"             , "name"           , L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10nDesc"             , "desc"           , L10N.NullString, Parser.TypeL10N)
    Parser:Define("tbUiList"             , "ui"             , nil            , Parser.TypeArrayInt)
end

function LandmarkBuildingTypeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbUiList = tbNewTemplate.tbUiList
    tbNewTemplate.bCanTrigger = true
    if tbUiList == nil or #tbUiList == 0 then
        tbNewTemplate.bCanTrigger = false
    end

    return true
end

-- [EXPORT BEGIN]
function LandmarkBuildingTypeDataTable:GetTemplate(nTypeId)
    return self.tbContainer[nTypeId]
end
-- [EXPORT END]

return LandmarkBuildingTypeDataTable
