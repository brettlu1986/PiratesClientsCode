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
local GMIDiomDataTable = {}

GMIDiomDataTable.szFileName = "client/ui/debug/gm_idiom.tab"

function GMIDiomDataTable:OnEditorDefine(Parser)
    Parser:Define("szGMName", "GMName", "", Parser.TypeString)
    Parser:Define("szUsage", "Usage", "", Parser.TypeString)
    Parser:Define("nMode", "Mode", 0, Parser.TypeInt)
    Parser:Define("nInstanceType", "Instance", 0, Parser.TypeInt)
end

function GMIDiomDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)

    -- logdebug("GMIDiomDataTable: " .. tbNewTemplate.nMode)
    table.insert(self.tbContainer, tbNewTemplate)
    return true
end

-- [EXPORT BEGIN]
function GMIDiomDataTable:GetContainer()
    return self.tbContainer
end
-- [EXPORT END]

return GMIDiomDataTable
