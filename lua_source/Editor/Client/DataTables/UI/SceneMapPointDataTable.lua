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
local SceneMapPointDataTable = {}



SceneMapPointDataTable.szFileName = "client/ui/map/ui_scene_map_point.tab"

-- [EXPORT BEGIN]
SceneMapPointDataTable.tbAllDungeonPoint = {}
-- [EXPORT END]

function SceneMapPointDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nSceneId", "scene_id", -1, Parser.TypeInt)
    Parser:Define("szPointKey", "point_key", "unknown", Parser.TypeString)
    Parser:Define("szDisplayName", "display_name", "", Parser.TypeString, false)
    Parser:Define("szIconResPath", "icon_res", "", Parser.TypeString, false)
    Parser:Define("nFontSize", "font_size", 24, Parser.TypeInt, false)
    Parser:Define("nIconSizeX", "icon_size_x", 50, Parser.TypeInt, false)
    Parser:Define("nIconSizeY", "icon_size_y", 75, Parser.TypeInt, false)
end

function SceneMapPointDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbDungeonPoint = self.tbAllDungeonPoint[tbNewTemplate.nSceneId]
    if not tbDungeonPoint then
        tbDungeonPoint = {}
        self.tbAllDungeonPoint[tbNewTemplate.nSceneId] = tbDungeonPoint
    end
    table.insert(tbDungeonPoint, tbNewTemplate)
    return true;
end

-- [EXPORT BEGIN]
function SceneMapPointDataTable:GetTemplate(nId)
    return self.tbContainer[nId] 
end

function SceneMapPointDataTable:GetSceneAllPoint(nSceneId)
    return self.tbAllDungeonPoint[nSceneId]
end
-- [EXPORT END]



return SceneMapPointDataTable 
