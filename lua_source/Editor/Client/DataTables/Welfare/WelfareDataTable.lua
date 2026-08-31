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
local WelfareDataTable = {}

local DataTableExporter = require("DataTableExporter")
local L10N= require("L10N")

WelfareDataTable.szFileName = "common/welfare/welfare.tab"
local bLoadingSubFile = false

local nCurrentMinId = -1
local nCurrentMaxId = -1
local nCurrentTab = -1

-- [EXPORT]
WelfareDataTable.tbWelfareTabItems = {}

function WelfareDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nMinId", "min_id", -1, Parser.TypeInt)
    Parser:Define("nMaxId", "max_id", -1, Parser.TypeInt)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
end

function WelfareDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    self.tbWelfareTabItems[tbNewTemplate.nId] = tbNewTemplate
    return true
end

function WelfareDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nSubCategory", "sub_category", -1, Parser.TypeInt)
    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nCardIndex", "usage_param_1", -1, Parser.TypeInt) -- vip_card_index的索引id
    Parser:Define("nCurrencyId", "currency_id", -1, Parser.TypeInt)
    Parser:Define("nCurrencyCount", "sell_price", -1, Parser.TypeInt)
    Parser:Define("l10nIntro", "intro", L10N.NullString, Parser.TypeL10N)
end

function WelfareDataTable:OnEditorParseSubLine(Parser, tbContainer, tbNewTemplate)
    if tbNewTemplate.nId < nCurrentMinId or tbNewTemplate.nId > nCurrentMaxId then   
        return true
    end
    if self.tbWelfareTabItems[nCurrentTab].tbItems == nil then  
        self.tbWelfareTabItems[nCurrentTab].tbItems = {}
    end
    table.insert(self.tbWelfareTabItems[nCurrentTab].tbItems, tbNewTemplate)
    return true
end

function WelfareDataTable:OnEditorParseFinished()
    if bLoadingSubFile then
        return
    end

    local szOldPath = self.szFileName
    bLoadingSubFile = true
    local fnOldDefine = self.OnEditorDefine
    local fnOldParseLine = self.OnEditorParseLine

    for _, v in pairs(self.tbContainer) do
        self.szFileName = v.szPath
        self.OnEditorDefine = self.OnEditorSubTableDefine
        self.OnEditorParseLine = self.OnEditorParseSubLine
        nCurrentMinId = v.nMinId
        nCurrentMaxId = v.nMaxId
        nCurrentTab = v.nId
        if not DataTableExporter:Load(self) then
            error("WelfareDataTable load sub table failed".. self.szFileName)
        end
    end

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.OnEditorParseLine = fnOldParseLine
    self.szFileName = szOldPath
end

-- [EXPORT BEGIN]
function WelfareDataTable:GetWelfareTab(nTab)
    return self.tbWelfareTabItems[nTab]
end

function WelfareDataTable:GetAllWelfareData()
    return self.tbWelfareTabItems
end
-- [EXPORT END]

return WelfareDataTable
