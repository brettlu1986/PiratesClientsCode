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
local HumanFightDataTable = {}

HumanFightDataTable.szFileName = "common/human/human_fight.tab"

function HumanFightDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nHp", "hp", -1, Parser.TypeInt)
    Parser:Define("nEp", "ep", -1, Parser.TypeInt)

    Parser:Define("nCommonRecoverLimit", "common_recover_limit", -1, Parser.TypeInt)
    Parser:Define("nEpReduceSpeed", "ep_reduce_speed", -1, Parser.TypeInt)
    Parser:Define("nDyingHp", "dying_hp", -1, Parser.TypeInt)
    Parser:Define("nDyingHpReduceSpeed", "dying_hp_reduce_speed", -1, Parser.TypeInt)
    Parser:Define("nRescuedHp", "rescued_hp", -1, Parser.TypeInt)
    Parser:Define("nHeadInjuryRatio", "head_injury_ratio", -1, Parser.TypeFloat)
    Parser:Define("nBodyInjuryRatio", "body_injury_ratio", -1, Parser.TypeFloat)
    Parser:Define("nAllFoursInjuryRatio", "allfours_injury_ratio", -1, Parser.TypeFloat)
end

-- [EXPORT BEGIN]
function HumanFightDataTable:GetTemplate(nTemplateId)
    return self.tbContainer[nTemplateId]
end
-- [EXPORT END]

return HumanFightDataTable
