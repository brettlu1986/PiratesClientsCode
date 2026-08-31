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

    DataTableExporter.TypeInt = 0
    DataTableExporter.TypeString = 1
    DataTableExporter.TypeFloat = 2
    DataTableExporter.TypeBool = 3
    DataTableExporter.TypeL10N = 4
    DataTableExporter.TypeArrayInt = 5
    DataTableExporter.TypeArrayString = 6
    DataTableExporter.TypeArrayFloat = 7
    DataTableExporter.TypeArrayBool = 8
    DataTableExporter.TypeArrayL10N = 9
--]]
local NotifyItemDataTable = {}

NotifyItemDataTable.szFileName = "common/item2/item_chat_system_channel.tab"

function NotifyItemDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szDes", "des", "", Parser.TypeString)
end

-- [EXPORT BEGIN]
function NotifyItemDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

function NotifyItemDataTable:IsContain(nId)
    local bResult = true
    if not self.tbContainer[nId] then
        bResult = false
    end
    return bResult
end

-- [EXPORT END]


return NotifyItemDataTable
