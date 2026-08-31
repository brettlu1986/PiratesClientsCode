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
local AITypeDataTable = {}

AITypeDataTable.szFileName = "common/ffa/ai/ai_type.tab"

function AITypeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nType")
    Parser:Define("nType", "ai_type", -1, Parser.TypeInt)
    Parser:Define("szControllerClass", "controller_class", "", Parser.TypeString)
    Parser:Define("szHumanBTClass", "human_behavior_tree_class", "", Parser.TypeString)
    Parser:Define("szShipBTClass", "ship_behavior_tree_class", "", Parser.TypeString)
    Parser:Define("szBlackboardClass", "blackboard_class", "", Parser.TypeString)
    Parser:Define("szSquadControllerClass", "squad_controller_class", "", Parser.TypeString)
    Parser:Define("szSquadBTClass", "squad_behavior_tree_class", "", Parser.TypeString)
    Parser:Define("szSquadBlackboardClass", "squad_blackboard_class", "", Parser.TypeString)
end

-- [EXPORT BEGIN]
function AITypeDataTable:GetTemplate(nType)
    return self.tbContainer[nType]
end
-- [EXPORT END]

return AITypeDataTable
