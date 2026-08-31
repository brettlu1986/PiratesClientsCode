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
local FFAMapPointCategoryDataTable = {}



FFAMapPointCategoryDataTable.szFileName = "client/ui/map/ui_ffa_map_point_category.tab"

-- [EXPORT BEGIN]
FFAMapPointCategoryDataTable.tbAllCategory = {}
-- [EXPORT END]


function FFAMapPointCategoryDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("l10nDisplayName", "display_name", "", Parser.TypeL10N, false)
    Parser:Define("szIconResPath", "icon_res", "", Parser.TypeString, false)
end

function FFAMapPointCategoryDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbAllCategory, tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function FFAMapPointCategoryDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

function FFAMapPointCategoryDataTable:GetAllCategory()
    return self.tbAllCategory
end
-- [EXPORT END]



return FFAMapPointCategoryDataTable
