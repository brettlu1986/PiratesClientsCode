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
local DungeonTypeDataTable = {}

DungeonTypeDataTable.szFileName = "common/dungeon/dungeon_type.tab"

function DungeonTypeDataTable:OnEditorDefine(Parser)
    Parser:Define("szGameModeClass", "game_mode_class", "", Parser.TypeString)
    Parser:Define("szGameStateClass", "game_state_class", "", Parser.TypeString)
    Parser:Define("szPlayerStateClass", "player_state_class", "", Parser.TypeString)
    Parser:Define("nMinID", "min_id", -1, Parser.TypeInt)
    Parser:Define("nMaxID", "max_id", -1, Parser.TypeInt)
end

function DungeonTypeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    table.insert(self.tbContainer, tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function DungeonTypeDataTable:GetTemplate(nID)
    local tbContainer = self.tbContainer
    local nCount = #tbContainer
    local tbTemplate
    for i=1, nCount do
        tbTemplate = tbContainer[i]
        if(nID >= tbTemplate.nMinID and nID <= tbTemplate.nMaxID) then
            return tbTemplate
        end
    end
    return nil
end
-- [EXPORT END]

return DungeonTypeDataTable
