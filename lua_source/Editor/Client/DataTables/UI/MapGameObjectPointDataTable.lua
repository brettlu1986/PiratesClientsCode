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
local MapGameObjectPointDataTable = {}


MapGameObjectPointDataTable.szFileName = "client/ui/map/ui_map_gameobject_point.tab"

-- [EXPORT BEGIN]
MapGameObjectPointDataTable.tbAllPoint = {}
-- [EXPORT END]

function MapGameObjectPointDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nObjectType", "object_type", -1, Parser.TypeInt)
    Parser:Define("l10nDisplayName", "display_name", "", Parser.TypeL10N, false)
    Parser:Define("szIconResPath", "icon_res", "", Parser.TypeString, false)
    Parser:Define("nFontSize", "font_size", 24, Parser.TypeInt, false)
    Parser:Define("nIconSizeX", "icon_size_x", -1, Parser.TypeInt, false)
    Parser:Define("nIconSizeY", "icon_size_y", -1, Parser.TypeInt, false)
end

function MapGameObjectPointDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbGameObjectTypeMap = self.tbAllPoint[tbNewTemplate.nObjectType]
        if not tbGameObjectTypeMap then
            tbGameObjectTypeMap = {}
            self.tbAllPoint[tbNewTemplate.nObjectType] = tbGameObjectTypeMap
        end
        tbGameObjectTypeMap[tbNewTemplate.nId] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function MapGameObjectPointDataTable:GetTemplate(nObjectType, nTemplateId)
    local tbGameObjectTypeMap = self.tbAllPoint[nObjectType]
    if tbGameObjectTypeMap then
        return tbGameObjectTypeMap[nTemplateId]
    end
    return nil
end
-- [EXPORT END]



return MapGameObjectPointDataTable
