--[[    DataTable类中必须有的成员变量与函数
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
local DataTableExporter = require("DataTableExporter")

local AwardDataTable = {}

local bLoadingSubFile = false

AwardDataTable.szFileName = "common/award2/drop_index.tab"

AwardDataTable.tbAwardTable = nil

function AwardDataTable:OnEditorDefine(Parser)
    Parser:Define("nMinId", "id_begin", - 1, Parser.TypeInt)
    Parser:Define("nMaxId", "id_end", - 1, Parser.TypeInt)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
    Parser:Define("nDropTab", "drop_tab", - 1, Parser.TypeInt)
end

function AwardDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if tbNewTemplate.nDropTab > 0 then
        -- 只读固定奖励
        return true
    end

    if self.tbAwardTable == nil then
        self.tbAwardTable = {}
    end
    table.insert(self.tbAwardTable, tbNewTemplate)
    return true
end

function AwardDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nAwardId", "award_id", - 1, Parser.TypeInt)
    Parser:Define("nItemId", "item_id", - 1, Parser.TypeInt)    
    Parser:Define("nCount", "count", - 1, Parser.TypeInt)    
end

function AwardDataTable:OnEditorParseSubLine(Parser, tbContainer, tbNewTemplate)
    if self.tbContainer[tbNewTemplate.nAwardId] == nil then
        self.tbContainer[tbNewTemplate.nAwardId] = {}
    end 
    table.insert(self.tbContainer[tbNewTemplate.nAwardId], tbNewTemplate)
    return true
end

function AwardDataTable:OnEditorParseFinished()
    if bLoadingSubFile then
        return
    end
    local szOldPath = self.szFileName
    bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine
    local fnOldParseLine = self.OnEditorParseLine

    for i, v in ipairs(self.tbAwardTable) do
        self.szFileName = v.szPath
        self.OnEditorDefine = self.OnEditorSubTableDefine
        self.OnEditorParseLine = self.OnEditorParseSubLine
        if not DataTableExporter:Load(self) then
            error("AwardDataTable load sub table failed".. self.szFileName)
        end
    end  

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.OnEditorParseLine = fnOldParseLine
    self.szFileName = szOldPath
end

-- [EXPORT BEGIN]
function AwardDataTable:GetAwardItem(nAwardId)
    if nAwardId ~= nil then
        return self.tbContainer[nAwardId]
    end
end
-- [EXPORT END]

return AwardDataTable
