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
local L10N = require("L10N")
local BattlePassRewardDataTable = {}

BattlePassRewardDataTable.szFileName = "client/season2/battle_pass/battle_pass_reward.tab"
-- [EXPORT]
BattlePassRewardDataTable.tbAll = {}

function BattlePassRewardDataTable:OnEditorDefine(Parser)
    Parser:Define("szRewardIcon", "reward_icon", "", Parser.TypeString)
    Parser:Define("l10nDesc", "desc", L10N.NullString, Parser.TypeL10N)
end

function BattlePassRewardDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(self.tbAll, tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function BattlePassRewardDataTable:GetContainer()
    return self.tbAll
end
-- [EXPORT END]

return BattlePassRewardDataTable
