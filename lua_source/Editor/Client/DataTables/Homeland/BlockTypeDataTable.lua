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
local BlockTypeDataTable = {}

local L10N = require("L10N")
local BuildingTypeDataTable = require("BuildingTypeDataTable")

BlockTypeDataTable.szFileName = "common/homeland/block_type.tab"

function BlockTypeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                  , "id"             , -1, Parser.TypeInt)
    Parser:Define("l10nName"             , "name"           , L10N.NullString, Parser.TypeL10N)
    Parser:Define("bShowColor"           , "show_color"     , false, Parser.TypeBool)
    Parser:Define("bIsDork"              , "is_dork"        , false, Parser.TypeBool)
    Parser:Define("nLength"              , "length"         , -1, Parser.TypeInt)
    Parser:Define("nWidth"               , "width"          , -1, Parser.TypeInt)
    Parser:Define("nBuildingType"        , "building_type"  , -1, Parser.TypeInt)
    Parser:Define("szIcon"               , "icon"           , "", Parser.TypeString)
end

function BlockTypeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nId = tbNewTemplate.nId
    local nBuildingType = tbNewTemplate.nBuildingType

    if nBuildingType ~= nil and nBuildingType > 0 then
        tbNewTemplate.bCanPlaceBuilding = true
        if not BuildingTypeDataTable:GetTemplate(nBuildingType) then
            error("Cannot find nBuildingType!nId: "..nId.. ",nBuildingType,"..nBuildingType)
        end
    else
        tbNewTemplate.bCanPlaceBuilding = false
    end

    local nLength = tbNewTemplate.nLength
    local nWidth = tbNewTemplate.nWidth
    if nLength == nil or nLength <= 0 or nWidth == nil or nWidth <= 0 then
        error("length or width less than 0!nId: "..nId..", nLength:"..nLength..", nWidth:"..nWidth)
    end

    return true
end


-- [EXPORT BEGIN]
function BlockTypeDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return BlockTypeDataTable
