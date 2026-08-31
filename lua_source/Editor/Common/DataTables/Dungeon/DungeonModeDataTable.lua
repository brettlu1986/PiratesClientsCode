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
local DungeonModeDataTable = {}

DungeonModeDataTable.szFileName = "common/dungeon/dungeon_mode.tab"

function DungeonModeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nID")
    Parser:Define("nID", "id", -1, Parser.TypeInt)
    Parser:Define("nResID", "res_id", -1, Parser.TypeInt)
    Parser:Define("szLogicLevelName", "logic_level_name", "", Parser.TypeString)
    Parser:Define("nUIRadarMapId", "ui_radar_map_id", -1, Parser.TypeInt)
    Parser:Define("nUIMapId", "ui_map_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function DungeonModeDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

return DungeonModeDataTable
