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
local BotNameDataTable = {}

-- [EXPORT]
local L10N = require("L10N")

BotNameDataTable.szFileName = "common/ffa/ai/bot/bot_name.tab"

function BotNameDataTable:OnEditorDefine(Parser)
    Parser:Define("nIndex", "index", -1, Parser.TypeInt)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
end

function BotNameDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    table.insert(tbContainer, tbNewTemplate.l10nName)
    return true
end

-- [EXPORT BEGIN]
function BotNameDataTable:RandomName(nNameCount)
    local tbContainer = self.tbContainer
    local nTotalNameCount = #(tbContainer)
    if nNameCount > nTotalNameCount then
        error("Random count too big!".. nNameCount)
    end
    if nNameCount == nTotalNameCount then
        return tbContainer
    end

    local tbRandomNames = {}
    for i = 1, nNameCount do
        local nRandomIndex = math.random(i, nTotalNameCount)
        local l10nRandomName = tbContainer[nRandomIndex]
        tbContainer[nRandomIndex] = tbContainer[i]
        tbContainer[i] = l10nRandomName
        table.insert(tbRandomNames, L10N:ToString(l10nRandomName))
    end
    return tbRandomNames
end
-- [EXPORT END]

return BotNameDataTable
