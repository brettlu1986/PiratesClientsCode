--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local BuildingUiDataTable = {}

local L10N = require("L10N")
local LandmarkBuildingTypeDataTable = require("LandmarkBuildingTypeDataTable")

BuildingUiDataTable.szFileName = "common/homeland/building_ui.tab"

function BuildingUiDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                     , "id"                            , -1, Parser.TypeInt)
    Parser:Define("nDisplayType"            , "display_type"                  ,  0, Parser.TypeInt)
    Parser:Define("szDisplayName"           , "display_name"                  , "", Parser.TypeString)
    Parser:Define("szParam1"                , "param1"                        , "", Parser.TypeString)
    Parser:Define("szParam2"                , "param2"                        , "", Parser.TypeString)
    Parser:Define("l10nDialogText"          , "dialog_text"                   , L10N.NullString, Parser.TypeL10N)
    Parser:Define("nLandmarkType"           , "landmark_type"                 , -1, Parser.TypeInt)
    Parser:Define("nLandmarkGrade"          , "landmark_grade"                , -1, Parser.TypeInt)
    Parser:Define("szPrerequisiteName"      , "prerequisite_script_name"      , nil, Parser.TypeString)
    Parser:Define("szPrerequisiteFunction"  , "prerequisite_script_function"  , nil, Parser.TypeString)
end

function BuildingUiDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nId = tbNewTemplate.nId
    local nLandMarkType = tbNewTemplate.nLandMarkType
    local nLandmarkGrade = tbNewTemplate.nLandmarkGrade

    if nLandMarkType ~= nil and nLandMarkType > 0 then
        if not LandmarkBuildingTypeDataTable:GetTemplate(nLandMarkType) then
            error("Cannot find nLandMarkType!nId: "..nId.. ",nLandMarkType,"..nLandMarkType)
        end
    end

    if nLandmarkGrade ~= nil and nLandmarkGrade > 0 then
        if nLandMarkType == nil or nLandMarkType <= 0 then
            error("nLandMarkType not valid!nId: "..nId.. ",nLandMarkType,"..nLandMarkType)
        end
        tbNewTemplate.bNeedUnlock = true
    else
        tbNewTemplate.bNeedUnlock = false
    end

    return true
end

-- [EXPORT BEGIN]
function BuildingUiDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return BuildingUiDataTable
