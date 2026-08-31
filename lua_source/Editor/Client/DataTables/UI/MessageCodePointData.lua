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
local MessageCodePointData = {}

MessageCodePointData.szFileName = "client/ui/message_code_point.tab"


function MessageCodePointData:OnEditorDefine(Parser)
    Parser:Define("nRangeBegin", "range_begin", "", Parser.TypeInt)
    Parser:Define("nRangeEnd", "range_end", "", Parser.TypeInt)
    Parser:Define("nDisplayWidth", "display_width", -1, Parser.TypeInt)
end

function MessageCodePointData:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    -- logdebug("tbNewTemplate.nRangeBegin " ..tbNewTemplate.nRangeBegin , " tbNewTemplate.nRangeEnd " .. tbNewTemplate.nRangeEnd)
    
    table.insert( self.tbContainer, tbNewTemplate )
    return true
end

-- [EXPORT BEGIN]
function MessageCodePointData:GetTemplate()
    return self.tbContainer
end
-- [EXPORT END]

return MessageCodePointData