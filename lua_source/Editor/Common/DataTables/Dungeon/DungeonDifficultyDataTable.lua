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
local DungeonDifficultyDataTable = {}

DungeonDifficultyDataTable.szFileName = "common/dungeon/dungeon_difficulty.tab"

function DungeonDifficultyDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nLevel1", "level1", -1, Parser.TypeInt)
    Parser:Define("nLevel2", "level2", -1, Parser.TypeInt)
    Parser:Define("nLevel3", "level3", -1, Parser.TypeInt)
    Parser:Define("nLevel4", "level4", -1, Parser.TypeInt)
    Parser:Define("nLevel5", "level5", -1, Parser.TypeInt)
    Parser:Define("nLevel6", "level6", -1, Parser.TypeInt)
    Parser:Define("nLevel7", "level7", -1, Parser.TypeInt)
    Parser:Define("nLevel8", "level8", -1, Parser.TypeInt)
    Parser:Define("nLevel9", "level9", -1, Parser.TypeInt)
    Parser:Define("nLevel10", "level10", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function DungeonDifficultyDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function DungeonDifficultyDataTable:GetNpc(nID, nLevel)
    local key = "nLevel"..nLevel
    if self.tbContainer[nID] and self.tbContainer[nID][key] then
        return self.tbContainer[nID][key]
    end
    return -1
end
-- [EXPORT END]

return DungeonDifficultyDataTable
