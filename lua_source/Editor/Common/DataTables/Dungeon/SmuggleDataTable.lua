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
local SmuggleDataTable = {}

SmuggleDataTable.szFileName = "common/dungeon/smuggle.tab"

function SmuggleDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nMatineeId", "matinee_id", -1, Parser.TypeInt)
    Parser:Define("nDialogId", "dialog_id", -1, Parser.TypeInt)
    Parser:Define("nBuffId", "buff_id", -1, Parser.TypeInt)
    Parser:Define("nShowResultTime", "show_result_time", -1, Parser.TypeInt)
    Parser:Define("nNpcGroupIndex", "npc_groupindex", -1, Parser.TypeInt)
    Parser:Define("nFinishTriggerID", "finish_trigger_id", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function SmuggleDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

return SmuggleDataTable