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
local TextDataTable = {}
local DataTableExporter = require("DataTableExporter")
-- [EXPORT BEGIN]
local L10N = require("L10N")
-- [EXPORT END]

TextDataTable.szFileName = "client/ui/text/text_index.tab"
TextDataTable.bLoadingSubFile = false
TextDataTable.tbSubTable = {}

function TextDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("szKey", "key", nil, Parser.TypeString)
    Parser:Define("l10nText", "text", L10N.NullString, Parser.TypeL10N)
end

function TextDataTable:OnEditorDefine(Parser)
    Parser:Define("szTextPath", "path", nil, Parser.TypeString)
end

-- local function trim(str)
--     return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
-- end

local function OnEditorParseSubTableLine(self, Parser, tbContainer, tbNewTemplate)
    if tbContainer[tbNewTemplate.szKey] ~= nil then
        logerror("TextTable Duplicate key ", tbNewTemplate.szKey, L10N:ToString(tbContainer[tbNewTemplate.szKey].l10nText), L10N:ToString(tbNewTemplate.l10nText))
        assert(false)
    end
    -- tbNewTemplate.l10nText.sz Text = trim(tbNewTemplate.l10nText.sz Text)

    tbContainer[tbNewTemplate.szKey] = tbNewTemplate
    return true
end

function TextDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if self.bLoadingSubFile then
        return OnEditorParseSubTableLine(self, Parser, tbContainer, tbNewTemplate)
    end

    table.insert(self.tbSubTable, tbNewTemplate)
    return true
end

function TextDataTable:OnEditorParseFinished()
    if self.bLoadingSubFile then
        return
    end

    local szOldPath = self.szFileName
    self.bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine

    local tbDatas = self.tbSubTable
    local nCount = #tbDatas
    for i = 1, nCount do
        self.szFileName = tbDatas[i].szTextPath
        self.OnEditorDefine = self.OnEditorSubTableDefine
        if not DataTableExporter:Load(self) then
            logerror("TextDataTable load sub table failed", self.szFileName)
            assert(false)
        end
    end

    self.bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.szFileName = szOldPath

    self.tbSubTable = {}
    -- for k, v in pairs(self.tbContainer) do
    --     v.l10nText.sz Text = trim(v.l10nText.sz Text)
    -- end
end
-- [EXPORT BEGIN]
function TextDataTable:GetTemplate(szKey)
    return self.tbContainer[szKey]
end

function TextDataTable:GetL10NText(szKey)
    local tbTemplate = self.tbContainer[szKey]
    return tbTemplate and tbTemplate.l10nText
end

function TextDataTable:GetText(szKey)
    local l10nText = self:GetL10NText(szKey)
    return l10nText and L10N:ToString(l10nText)
end
-- [EXPORT END]

return TextDataTable
