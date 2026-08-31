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
local PvpInitItemDataTable = {}

-- [EXPORT]
local InitItemDataTableHelper = require("InitItemDataTableHelper")

PvpInitItemDataTable.szFileName = "common/ffa/initdata/pvp_init_item.tab"

function PvpInitItemDataTable:OnEditorDefine(Parser)
    Parser:Define("nGroupId", "group_id", -1, Parser.TypeInt)
    Parser:Define("nId", "template_id", -1, Parser.TypeInt)
    Parser:Define("nCount", "count", -1, Parser.TypeInt)
end

function PvpInitItemDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    InitItemDataTableHelper.Check(tbNewTemplate, self.szFileName)
    local tbGroup = tbContainer[tbNewTemplate.nGroupId]
    if not tbGroup then
        tbGroup = {}
        tbContainer[tbNewTemplate.nGroupId] = tbGroup
    end
    table.insert(tbGroup, tbNewTemplate)
    return true
end

function PvpInitItemDataTable:OnEditorParseFinished()
    for _, tbGroup in pairs(self.tbContainer) do
        table.sort(tbGroup, InitItemDataTableHelper.fnSort)
    end
end

-- [EXPORT BEGIN]
function PvpInitItemDataTable:GetGroup(nGroupId)
    return self.tbContainer[nGroupId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function PvpInitItemDataTable:GetGroupItems(nGroupId)
    return InitItemDataTableHelper.GetItems(self.tbContainer[nGroupId])
end
-- [EXPORT END]

return PvpInitItemDataTable
