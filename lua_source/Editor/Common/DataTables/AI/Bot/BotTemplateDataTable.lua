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
local BotTemplateDataTable = {}

local BotLevelDataTable = require("BotLevelDataTable")

BotTemplateDataTable.szFileName = "common/ffa/ai/bot/bot_template.tab"

function BotTemplateDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nBotLevel",  "bot_level", -1, Parser.TypeInt)
    Parser:Define("nItemRandomId",  "item_random_id", -1, Parser.TypeInt)
    Parser:Define("tbHumanId",  "human_id", nil, Parser.TypeArrayInt)
    Parser:Define("nFashionPoolId",  "fashion_pool_id", -1, Parser.TypeInt)
end

function BotTemplateDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if BotLevelDataTable:GetTemplate(tbNewTemplate.nBotLevel) == nil then
        error("Cannot find bot level! bot template id:"..tbNewTemplate.nId..", level:"..tbNewTemplate.nBotLevel)
    end
    return true
end

-- [EXPORT BEGIN]
function BotTemplateDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BotTemplateDataTable:GetRandomHumanId(nId)
    local tbHumanId = self.tbContainer[nId].tbHumanId
    if tbHumanId and #tbHumanId > 0 then
        return tbHumanId[math.random( 1,#tbHumanId)]
    end
end
-- [EXPORT END]

return BotTemplateDataTable