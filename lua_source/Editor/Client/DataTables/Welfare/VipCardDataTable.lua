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
local VipCardDataTable = {}

local DataTableExporter = require("DataTableExporter")

VipCardDataTable.szFileName = "common/item2/sub/usable/vipcard/vip_card_index.tab"
local bLoadingSubFile = false
local nCurrentType = -1
-- [EXPORT]
VipCardDataTable.tbCardInfos = {}

function VipCardDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nTypeId")
    Parser:Define("nTypeId", "type", -1, Parser.TypeInt)
    Parser:Define("szPath", "path", nil, Parser.TypeString)
end

function VipCardDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    self.tbCardInfos[tbNewTemplate.nTypeId] = tbNewTemplate
    return true
end

function VipCardDataTable:OnEditorSubTableDefine(Parser)
    Parser:Define("nPeriod", "period", -1, Parser.TypeInt)
    Parser:Define("nAwardId", "award_id", -1, Parser.TypeInt)
end

function VipCardDataTable:OnEditorParseSubLine(Parser, tbContainer, tbNewTemplate)
    if self.tbCardInfos[nCurrentType].tbDayRewards == nil then  
        self.tbCardInfos[nCurrentType].tbDayRewards = {}
    end
    table.insert(self.tbCardInfos[nCurrentType].tbDayRewards, tbNewTemplate)
    return true
end

function VipCardDataTable:OnEditorParseFinished()
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
        nCurrentType = v.nTypeId
        if not DataTableExporter:Load(self) then
            error("VipCardDataTable load sub table failed".. self.szFileName)
        end
    end

    bLoadingSubFile = false
    self.OnEditorDefine = fnOldDefine
    self.OnEditorParseLine = fnOldParseLine
    self.szFileName = szOldPath
end

-- [EXPORT BEGIN]
function VipCardDataTable:GetRewardItemId(nType, nDay)
    return self.tbCardInfos[nType].tbDayRewards[nDay].nAwardId
end

function VipCardDataTable:GetRewardDays(nType)
    return #self.tbCardInfos[nType].tbDayRewards
end
-- [EXPORT END]

return VipCardDataTable
