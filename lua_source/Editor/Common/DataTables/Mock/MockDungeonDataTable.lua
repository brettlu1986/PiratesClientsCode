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
local MockDungeonDataTable = {}

MockDungeonDataTable.szFileName = "common/mock/mock_dungeon.tab"

function MockDungeonDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nPlayerId")
    Parser:Define("nPlayerId", "player_id", -1, Parser.TypeInt)
    Parser:Define("szPlayerName", "player_name", "", Parser.TypeString)
    Parser:Define("nGroupIndex", "group_index", -1, Parser.TypeInt)
    Parser:Define("nShipTemplateId", "ship_template_id", -1, Parser.TypeInt)
    Parser:Define("nToken", "player_token", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function MockDungeonDataTable:GetAllTemplates()
    return self.tbContainer
end
-- [EXPORT END]

return MockDungeonDataTable
