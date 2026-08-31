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
local BattleAwardDataTable = {}

BattleAwardDataTable.szFileName = "common/ffa/statistics/battle_award.tab"

function BattleAwardDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nRank")
    Parser:Define("nRank",       "rank",      -1, Parser.TypeInt)
    Parser:Define("nExp",        "exp",       -1, Parser.TypeInt)
    Parser:Define("nCurrency",   "currency",  -1, Parser.TypeInt)
    Parser:Define("nExtraKillCurrency",  "extra_kill_currency", -1, Parser.TypeInt)
    Parser:Define("nExtraKillCurrencyMax",  "extra_kill_currency_max", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function BattleAwardDataTable:GetTemplate(nRank)
    return self.tbContainer[nRank]
end
-- [EXPORT END]

return BattleAwardDataTable