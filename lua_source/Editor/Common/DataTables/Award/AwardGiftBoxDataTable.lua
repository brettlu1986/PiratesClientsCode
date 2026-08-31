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

local AwardGiftBoxDataTable = {}

local bLoadingSubFile = false

AwardGiftBoxDataTable.szFileName = "common/award2/common/drop_common.tab"

local szSubFileName = "common/award2/common/drop_group_common.tab"

AwardGiftBoxDataTable.tbDropCommon = nil

function AwardGiftBoxDataTable:OnEditorDefine(Parser)
    Parser:Define("nDropId", "drop_id", - 1, Parser.TypeInt)
    Parser:Define("nDropGroupId", "drop_group_id", - 1, Parser.TypeInt)
end

function AwardGiftBoxDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    if self.tbDropCommon == nil then
        self.tbDropCommon = {}
    end

    if self.tbDropCommon[tbNewTemplate.nDropId] == nil then 
        self.tbDropCommon[tbNewTemplate.nDropId] = {}
    end
    table.insert(self.tbDropCommon[tbNewTemplate.nDropId], tbNewTemplate.nDropGroupId)
    return true
end

function AwardGiftBoxDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nDropGroupId", "drop_group_id", - 1, Parser.TypeInt)
    Parser:Define("nItemId", "item_id", - 1, Parser.TypeInt)    
    Parser:Define("nCount", "count_param_1", - 1, Parser.TypeInt)    
end

function AwardGiftBoxDataTable:OnEditorParseSubLine(Parser, tbContainer, tbNewTemplate)

    local nAwardId = -1
    for nId, v in pairs(self.tbDropCommon) do   
        for k, value in ipairs(v) do  
            if tbNewTemplate.nDropGroupId == value then   
                nAwardId = nId
                if self.tbContainer[nAwardId] == nil then
                    self.tbContainer[nAwardId] = {}
                end 

                local tbNew = {}
                tbNew.nAwardId = nAwardId
                tbNew.nItemId = tbNewTemplate.nItemId
                tbNew.nCount = tbNewTemplate.nCount
                table.insert(self.tbContainer[nAwardId], tbNew)
            end
        end
    end
    
    return true
end

function AwardGiftBoxDataTable:OnEditorParseFinished()
    if bLoadingSubFile then
        return
    end
    local szOldPath = self.szFileName
    bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine
    local fnOldParseLine = self.OnEditorParseLine

    self.szFileName = szSubFileName
    self.OnEditorDefine = self.OnEditorSubTableDefine
    self.OnEditorParseLine = self.OnEditorParseSubLine
    if not DataTableExporter:Load(self) then
        error("AwardGiftBoxDataTable load sub table failed".. self.szFileName)
    end

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.OnEditorParseLine = fnOldParseLine
    self.szFileName = szOldPath
end

-- [EXPORT BEGIN]
function AwardGiftBoxDataTable:GetAwardItem(nAwardId)
    if nAwardId ~= nil then
        return self.tbContainer[nAwardId]
    end
end

-- [EXPORT END]

return AwardGiftBoxDataTable
