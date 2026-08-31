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

-- [EXPORT]
local L10N = require("L10N")

local DialogTextDataTable = {}
local DataTableExporter = require("DataTableExporter")

DialogTextDataTable.szFileName = "client/text/dialog_index.tab"
DialogTextDataTable.tbSubTable = {}
DialogTextDataTable.bLoadingSubFile = false

function DialogTextDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szText", "text", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nPreDialogId", "pre_dialog_id", -1, Parser.TypeInt, false)
end

local function OnEditorParseSubTableLine(self, Parser, tbContainer, tbNewTemplate)
    local nId = tbNewTemplate.nId
    if(nId < self.nMinId or nId > self.nMaxId) then
        logerror("DialogTextDataTable parse failed, the range of id is invalid", nId)
        return false
    end
    if(self.tbContainer[nId] ~= nil) then
        logerror("DialogTextDataTable parse failed, the id is duplicated", nId)
        return false
    end
    tbContainer[nId] = tbNewTemplate
    return true;
end

function DialogTextDataTable:OnEditorDefine(Parser)
    Parser:Define("nMinId", "id_begin", -1, Parser.TypeInt)
    Parser:Define("nMaxId", "id_end", -1, Parser.TypeInt)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
end

function DialogTextDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if(self.bLoadingSubFile) then
        return OnEditorParseSubTableLine(self, Parser, tbContainer, tbNewTemplate)
    end

    table.insert(self.tbSubTable, tbNewTemplate)
    return true;
end

-- [EXPORT BEGIN]
function DialogTextDataTable:GetTemplate(ID)
    return self.tbContainer[ID]
end
-- [EXPORT END]

function DialogTextDataTable:OnEditorParseFinished()
    if(self.bLoadingSubFile) then
        return
    end

    local szOldPath = self.szFileName
    self.bLoadingSubFile = true
    local OnEditorfnOldDefine = self.OnEditorDefine

    -- local tbData
    local tbDatas = self.tbSubTable
    local nCount = #tbDatas
    for i=1, nCount do
        local tbData = tbDatas[i]
        self.nMinId = tbData.nMinId
        self.nMaxId = tbData.nMaxId
        self.szFileName = tbData.szPath
        self.OnEditorDefine = self.OnEditorSubTableDefine
        if(not DataTableExporter:Load(self)) then
            logerror("DialogTextDataTable load sub table failed", self.szFileName)
            assert(false)
            return
        end
    end

    self.nMinId = nil
    self.nMaxId = nil
    self.bLoadingSubFile = false
    self.OnEditorDefine = OnEditorfnOldDefine
    self.szFileName = szOldPath
    self.tbSubTable = {}
end

-- [EXPORT BEGIN]
function DialogTextDataTable:GetText(nID)
    local tbDialog = self.tbContainer[nID]
    if tbDialog ~= nil then
        return tbDialog.szText -- 逻辑已经是l10n了，但是命名没改
    else
        logwarning("Dialog text not found. Id", nID)
        return L10N.NullString
    end
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function DialogTextDataTable:GetPreDialogId(nID)
    local tbDialog = self.tbContainer[nID]
    if tbDialog ~= nil then
        return tbDialog.nPreDialogId
    else
        logwarning("Dialog pre dialog id not found. Id", nID)
        return -1
    end
end
-- [EXPORT END]

return DialogTextDataTable
