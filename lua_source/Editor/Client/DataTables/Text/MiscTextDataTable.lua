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

local MiscTextDataTable = {}
local DataTableExporter = require("DataTableExporter")

MiscTextDataTable.szFileName = "client/text/misc_index.tab"
MiscTextDataTable.tbSubTable = {}
MiscTextDataTable.bLoadingSubFile = false

function MiscTextDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("szText", "text", L10N.NullString, Parser.TypeL10N)
end

local function OnEditorParseSubTableLine(self, Parser, tbContainer, tbNewTemplate)
    local nId = tbNewTemplate.nId
    if(nId < self.nMinId or nId > self.nMaxId) then
        logerror("MiscTextDataTable parse failed, the range of id is invalid", nId)
        return false
    end
    if(self.tbContainer[nId] ~= nil) then
        logerror("MiscTextDataTable parse failed, the id is duplicated", nId)
        return false
    end
    tbContainer[nId] = tbNewTemplate
    return true;
end

function MiscTextDataTable:OnEditorDefine(Parser)
    Parser:Define("nMinId", "id_begin", -1, Parser.TypeInt)
    Parser:Define("nMaxId", "id_end", -1, Parser.TypeInt)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
end

function MiscTextDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if(self.bLoadingSubFile) then
        return OnEditorParseSubTableLine(self, Parser, tbContainer, tbNewTemplate)
    end

    table.insert(self.tbSubTable, tbNewTemplate)
    return true;
end

-- [EXPORT BEGIN]
function MiscTextDataTable:GetTemplate(ID)
    return self.tbContainer[ID]
end
-- [EXPORT END]

function MiscTextDataTable:OnEditorParseFinished()
    if(self.bLoadingSubFile) then
        return
    end

    local szOldPath = self.szFileName
    self.bLoadingSubFile = true
    local OnEditorfnOldDefine = self.OnEditorDefine

    local tbData
    local tbDatas = self.tbSubTable
    local nCount = #tbDatas
    for i=1, nCount do
        tbData = tbDatas[i]
        self.nMinId = tbData.nMinId
        self.nMaxId = tbData.nMaxId
        self.szFileName = tbData.szPath
        self.OnEditorDefine = self.OnEditorSubTableDefine
        if(not DataTableExporter:Load(self)) then
            logerror("MiscTextDataTable load sub table failed", self.szFileName)
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
function MiscTextDataTable:GetText(nID)
    local tbMisc = self.tbContainer[nID]
    if tbMisc ~= nil then
        return tbMisc.szText -- 逻辑已经是l10n了，但是命名没改
    else
        logwarning("Misc text not found. Id", nID)
        return L10N.NullString
    end
end
-- [EXPORT END]

return MiscTextDataTable
