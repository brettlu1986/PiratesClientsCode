--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]
--]]
local BuildingExchangeDataTable = {}

BuildingExchangeDataTable.szFileName = "common/homeland/building_exchange.tab"

function BuildingExchangeDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId"                  , "id"                     , -1, Parser.TypeInt)
    Parser:Define("nItemTemplateId"      , "item_template_id"       , -1, Parser.TypeInt)
    Parser:Define("nCount"               , "count"                  , -1, Parser.TypeInt)
    Parser:Define("nCostTemplateId1"     , "cost_template_id_1"     , -1, Parser.TypeInt)
    Parser:Define("nCostCount1"          , "cost_count_1"           , -1, Parser.TypeInt)
    Parser:Define("nCostTemplateId2"     , "cost_template_id_2"     , -1, Parser.TypeInt)
    Parser:Define("nCostCount2"          , "cost_count_2"           , -1, Parser.TypeInt)
    Parser:Define("nCostTemplateId3"     , "cost_template_id_3"     , -1, Parser.TypeInt)
    Parser:Define("nCostCount3"          , "cost_count_3"           , -1, Parser.TypeInt)
    Parser:Define("nCostTemplateId4"     , "cost_template_id_4"     , -1, Parser.TypeInt)
    Parser:Define("nCostCount4"          , "cost_count_4"           , -1, Parser.TypeInt)
end

local function AddCostItem(tbCostItems, nItemTemplateId, nCost)
    if nItemTemplateId > 0 and nCost > 0 then
        local tbCost = {}
        tbCost.nItemTemplateId = nItemTemplateId
        tbCost.nCost = nCost
        table.insert(tbCostItems, tbCost)
    end
end

function BuildingExchangeDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local tbCostItems = {}
    tbNewTemplate.tbCostItems = tbCostItems
    AddCostItem(tbCostItems, tbNewTemplate.nCostTemplateId1, tbNewTemplate.nCostCount1)
    AddCostItem(tbCostItems, tbNewTemplate.nCostTemplateId2, tbNewTemplate.nCostCount2)
    AddCostItem(tbCostItems, tbNewTemplate.nCostTemplateId3, tbNewTemplate.nCostCount3)
    AddCostItem(tbCostItems, tbNewTemplate.nCostTemplateId4, tbNewTemplate.nCostCount4)

    if #tbCostItems == 0 then
        error("Cannot find cost item!"..tbNewTemplate.nId)
    end
    return true
end

-- [EXPORT BEGIN]
function BuildingExchangeDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end
-- [EXPORT END]

-- [EXPORT BEGIN]
function BuildingExchangeDataTable:GetAllTemplates()
    return self.tbContainer
end
-- [EXPORT END]

return BuildingExchangeDataTable
