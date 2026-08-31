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
local BPTableRootDataTable = {}
local DataTableExporter = require("DataTableExporter")

local MATCH_FILENAME = ".+%/(.+)%..+$"
local szKeyFieldTemp = ""

BPTableRootDataTable.szFileName = "common/bp/bp_table_root.tab"

local function OnEditorParseSubTableLine(tbSubDataTable, Parser, tbContainer, tbNewTemplate)
    if(tbSubDataTable.tbKeys == nil) then
        local tbCurrentKeys = Parser:GetCurrentKeys()
        local tbKeys = {}
        for szKeyName, nIndex in pairs(tbCurrentKeys) do
            tbKeys[nIndex] = szKeyName
        end
        tbSubDataTable.tbKeys = tbKeys
    end
    local tbLineData = DataTableExporter:GetCurrentLineData()
    if #tbLineData ~= #tbSubDataTable.tbKeys then
        logerror("BPTableRootDataTable parse sub tabl failed, count num is not equal", tbNewTemplate.szFileName)
        return false
    end

    for i,v in ipairs(tbSubDataTable.tbKeys) do
        tbNewTemplate[v] = tbLineData[i]
    end
    tbSubDataTable.tbContainer[tbNewTemplate[szKeyFieldTemp]] = tbNewTemplate
    return true
end

local function GetSubDataTemplate(tbSubDataTable, nSubId)
    return tbSubDataTable.tbContainer[nSubId]
end
-- [EXPORT END]

local function LoadSubTab(self, tbSubTableInfo)
    szKeyFieldTemp = tbSubTableInfo.szKeyField

    local tbNewTable = {}
    tbNewTable.szFileName = tbSubTableInfo.szTablePath
    tbNewTable.OnEditorParseLine = OnEditorParseSubTableLine
    tbNewTable.GetTemplate = GetSubDataTemplate
    if(not DataTableExporter:Load(tbNewTable)) then
        logerror("BPTableRootDataTable load sub tabl failed,", tbNewTable.szFileName)
        return nil
    end
    return tbNewTable
end

function BPTableRootDataTable:OnEditorDefine(Parser)
    Parser:Define("szTablePath", "table_path", "", Parser.TypeString)
    Parser:Define("szKeyField", "key_field", "", Parser.TypeString)
end

function BPTableRootDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local szTableName = tbNewTemplate.szTablePath:match(MATCH_FILENAME)
    tbContainer[szTableName] = tbNewTemplate
    return true
end

-- [EXPORT BEGIN]
function BPTableRootDataTable:GetTemplate(nType)
    return self.tbContainer[nType]
end
-- [EXPORT END]

function BPTableRootDataTable:OnEditorParseFinished()
    for _, tbSubTableInfo in pairs(self.tbContainer) do
        local tbSubDataTable = LoadSubTab(self, tbSubTableInfo)
        assert(tbSubDataTable)
        tbSubTableInfo.tbSubDataTable = tbSubDataTable        
    end
end

return BPTableRootDataTable
