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
local NpcLevelDataTable = {}

NpcLevelDataTable.szFileName = "common/ffa/ai/npc/npc_level.tab"

function NpcLevelDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nNpcLevel")
    Parser:Define("nNpcLevel", "npc_level", -1, Parser.TypeInt)
    Parser:Define("szAimHumanPart",  "aim_human_part", "", Parser.TypeString)
    Parser:Define("nAimShipPart",  "aim_ship_part", -1, Parser.TypeInt)
    Parser:Define("nHumanHitProbability", "human_hit_probability", -1, Parser.TypeFloat)
    Parser:Define("nHumanDamageParam", "human_damage_param", -1, Parser.TypeFloat)
    Parser:Define("nShipHitProbability", "ship_hit_probability", -1, Parser.TypeFloat)
    Parser:Define("nShipDamageParam", "ship_damage_param", -1, Parser.TypeFloat)
end

-- [EXPORT BEGIN]
function NpcLevelDataTable:GetTemplate(nNpcLevel)
    return self.tbContainer[nNpcLevel]
end
-- [EXPORT END]

return NpcLevelDataTable