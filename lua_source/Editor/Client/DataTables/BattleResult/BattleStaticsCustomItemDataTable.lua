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
local BattleStaticsCustomItemDataTable = {}

local L10N = require("L10N")

BattleStaticsCustomItemDataTable.szFileName = "client/battleresult/battle_statics_custom_items.tab"

-- [EXPORT BEGIN]
BattleStaticsCustomItemDataTable.tbAllCustomItems = {}
-- [EXPORT END]

function BattleStaticsCustomItemDataTable:OnEditorDefine(Parser)
    --Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("l10DisplayName", "display_name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("l10DisplayValueFormat", "display_value_format", L10N.NullString, Parser.TypeL10N, false)
    Parser:Define("tbMode", "mode", nil, Parser.TypeArrayInt, false)
    Parser:Define("szParamName", "param_name", "Unknown", Parser.TypeString)
    Parser:Define("nDecimalPointRemain", "decimal_point_remain", 0, Parser.TypeInt, false)
    Parser:Define("nMultiplyParam", "multiply_param", 1, Parser.TypeInt, false)
    Parser:Define("nDivideParam", "divide_param", 1, Parser.TypeInt, false)
end

function BattleStaticsCustomItemDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbAllCustomItems, tbNewTemplate)
    return true;
end

-- [EXPORT BEGIN]
function BattleStaticsCustomItemDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

function BattleStaticsCustomItemDataTable:GetAllCustomItems()
    return self.tbAllCustomItems
end
-- [EXPORT END]

return BattleStaticsCustomItemDataTable
