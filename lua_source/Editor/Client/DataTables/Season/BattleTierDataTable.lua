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
local BattleTierDataTable = {}

BattleTierDataTable.szFileName = "common/season2/battle_pass/battle_tier.tab"

function BattleTierDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nTier")
    Parser:Define("nTier", "tier", -1, Parser.TypeInt)
    Parser:Define("nBattleStar", "battle_star", -1, Parser.TypeInt)
    -- Parser:Define("nInheritTier", "inherit_tier", -1, Parser.TypeInt)
    Parser:Define("nCurrencyId", "currency_id", -1, Parser.TypeInt)
    Parser:Define("nCurrencyCost", "currency_cost", -1, Parser.TypeInt)
end

-- [EXPORT BEGIN]
function BattleTierDataTable:GetTemplate(nID)
    return self.tbContainer[nID]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BattleTierDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

return BattleTierDataTable
