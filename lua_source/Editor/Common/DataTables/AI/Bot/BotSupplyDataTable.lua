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
local BotSupplyDataTable = {}

BotSupplyDataTable.szFileName = "common/ffa/ai/bot/bot_supply.tab"

function BotSupplyDataTable:OnEditorDefine(Parser)
    Parser:Define("nBotLevel", "bot_level", -1, Parser.TypeInt)
    Parser:Define("nPoisonCircleIndex", "poison_circle_index", -1, Parser.TypeInt)
    Parser:Define("nSupplyItemRandomId",  "supply_item_random_id", -1, Parser.TypeInt)
    Parser:Define("nDelayTimeMin",  "delay_time_min", -1, Parser.TypeInt)
    Parser:Define("nDelayTimeMax",  "delay_time_max", -1, Parser.TypeInt)
end


function BotSupplyDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbLevelTemplates = tbContainer[tbNewTemplate.nBotLevel]
    if not tbLevelTemplates then
        tbLevelTemplates = {}
        tbContainer[tbNewTemplate.nBotLevel] = tbLevelTemplates
    end
    tbLevelTemplates[tbNewTemplate.nPoisonCircleIndex] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function BotSupplyDataTable:GetTemplate(nBotLevel, nPoisonCircleIndex)
    local tbLevelTemplates = self.tbContainer[nBotLevel]
    if tbLevelTemplates then
        return tbLevelTemplates[nPoisonCircleIndex]
    end
    return nil
end
-- [EXPORT END]

return BotSupplyDataTable