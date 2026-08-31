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
local FFAMapPointDataTable = {}
local FFAMapPointCategoryDataTable = require("FFAMapPointCategoryDataTable")


FFAMapPointDataTable.szFileName = "client/ui/map/ui_ffa_map_point.tab"

-- [EXPORT BEGIN]
FFAMapPointDataTable.tbAllDungeonPoint = {}
-- [EXPORT END]

function FFAMapPointDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nDungeonId", "dungeon_id", -1, Parser.TypeInt)
    Parser:Define("szPointKey", "point_key", "unknown", Parser.TypeString)
    Parser:Define("l10nDisplayName", "display_name", "", Parser.TypeL10N, false)
    Parser:Define("szDisplayName", "display_name", "", Parser.TypeString, false)
    Parser:Define("szIconResPath", "icon_res", "", Parser.TypeString, false)
    Parser:Define("nFontSize", "font_size", 24, Parser.TypeInt, false)
    Parser:Define("nIconSizeX", "icon_size_x", 50, Parser.TypeInt, false)
    Parser:Define("nIconSizeY", "icon_size_y", 75, Parser.TypeInt, false)
    Parser:Define("nCategoryId", "category_id", -1, Parser.TypeInt, false)
    Parser:Define("bHide", "is_hide", false, Parser.TypeBool, false)
end

function FFAMapPointDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if not tbNewTemplate.szIconResPath or tbNewTemplate.szIconResPath == "" then
        local tbCategoryTemplate = FFAMapPointCategoryDataTable:GetTemplate(tbNewTemplate.nCategoryId)
        if tbCategoryTemplate then
            tbNewTemplate.szIconResPath = tbCategoryTemplate.szIconResPath
        end
    end
    local tbDungeonPoint = self.tbAllDungeonPoint[tbNewTemplate.nDungeonId]
    if not tbDungeonPoint then
        tbDungeonPoint = {}
        self.tbAllDungeonPoint[tbNewTemplate.nDungeonId] = tbDungeonPoint
    end
    table.insert(tbDungeonPoint, tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function FFAMapPointDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

function FFAMapPointDataTable:GetDungeonAllPoint(nDungeonId)
    return self.tbAllDungeonPoint[nDungeonId]
end

function FFAMapPointDataTable:GetAllDungeonId()
    local tbAllDungeonId = {}
    for k, _ in pairs(self.tbAllDungeonPoint) do
        table.insert(tbAllDungeonId, k)
    end
    return tbAllDungeonId
end
-- [EXPORT END]



return FFAMapPointDataTable
