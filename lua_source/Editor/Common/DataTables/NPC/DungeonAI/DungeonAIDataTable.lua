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
local DungeonAIDataTable = {}

-- [EXPORT] 
local DungeonAIParamParser = require("DungeonAIParamParser")
local DataTableExporter = require("DataTableExporter")

DungeonAIDataTable.szFileName = "common/npc/dungeon/ai.tab"

-- [EXPORT BEGIN]
--DungeonAIDataTable.tbParsers = nil
DungeonAIDataTable.tbKeys = nil
DungeonAIDataTable.tbParserLine = nil

DungeonAIDataTable.tbNewAITable = {}
-- [EXPORT END]

function DungeonAIDataTable:OnGameRequired()
    self.tbParsers = {}
    DungeonAIParamParser:Parse(self.tbParsers, self.tbParserLine)
    
    self.tbNewAITable.tbParsers = {}
    DungeonAIParamParser:Parse(self.tbNewAITable.tbParsers, self.tbNewAITable.tbParserLine)    
end

function DungeonAIDataTable:OnEditorParseAnnotation(tbLineData)
    if(#tbLineData > 0 and tbLineData[1] == '#AIParamType') then
        self.tbParserLine = tbLineData
    end
end

function DungeonAIDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nTemplateId")
    Parser:Define("nTemplateId", "Id", -1, Parser.TypeInt)
    Parser:Define("nType", "AIType", 1, Parser.TypeInt)
end

function DungeonAIDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    tbNewTemplate.tbLineData = DataTableExporter:GetCurrentLineData()

    if(self.tbKeys == nil) then
        local tbCurrentKeys = Parser:GetCurrentKeys()
        local tbKeys = {}
        for szKeyName, nIndex in pairs(tbCurrentKeys) do
            tbKeys[nIndex] = szKeyName
        end
        self.tbKeys = tbKeys
    end
    return true;
end

function DungeonAIDataTable:OnEditorParseFinished()
    -- Load 新表 
    local tbNewTable = {}
    tbNewTable.OnEditorParseAnnotation = self.OnEditorParseAnnotation
    tbNewTable.OnEditorDefine = self.OnEditorDefine
    tbNewTable.OnEditorParseLine = self.OnEditorParseLine
    tbNewTable.szFileName = "common/npc/dungeon/ai_new.tab"
    if(false == DataTableExporter:Load(tbNewTable)) then
        error("DungeonAIDataTable load new table failed: "..tbNewTable.szFileName)
    end 
    self.tbNewAITable = tbNewTable
end

-- [EXPORT BEGIN]
function DungeonAIDataTable:GetTemplate(nId)
    local tbFind = self.tbContainer[nId]
    if(tbFind) then
        return tbFind, self.tbKeys, self.tbParsers
    end
    if(self.tbNewAITable) then
        return self.GetTemplate(self.tbNewAITable, nId)
    end
    return nil
end
-- [EXPORT END]

return DungeonAIDataTable
