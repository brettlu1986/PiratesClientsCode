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
local BattleItemDataTable = require("BattleItemDataTable")

local BattleDropGroupDataTable = {}
local nMaxItemCount = 5

BattleDropGroupDataTable.szFileName = "common/ffa/item/item_drop/drop_group.tab"

function BattleDropGroupDataTable:OnEditorDefine(Parser)
    Parser:Define("nId", "id", -1, Parser.TypeInt)
    Parser:Define("nWeight", "weight", -1, Parser.TypeInt)

    for i=1, nMaxItemCount do
        local szVarItem = "nItem"..i
        local szColItem = "item_"..i
        Parser:Define(szVarItem, szColItem, -1, Parser.TypeInt)
        local szVarCount = "nCount"..i
        local szColCount = "count_"..i
        Parser:Define(szVarCount, szColCount, 0, Parser.TypeInt)
    end
end

function BattleDropGroupDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nId = tbNewTemplate.nId
    local tbGroup = tbContainer[nId]
    if not tbGroup then
        tbContainer[nId] = {}
        tbGroup = tbContainer[nId]
    end
    local tbItems = {}
    tbItems.nWeight = tbNewTemplate.nWeight
    tbItems.tbItems = {}
    for i=1,nMaxItemCount do
        local szVarItem = "nItem"..i
        local szVarCount = "nCount"..i
        local nItemTemplateId = tbNewTemplate[szVarItem]
        if nItemTemplateId > 0 then
            if BattleItemDataTable:GetTemplate(nItemTemplateId) == nil then
                error("BattleDropGroupDataTable:OnEditorParseLine ItemId invalid. nItemTemplateId: "..nItemTemplateId)
                return false
            end
            local item = {
                nItemTemplateId = nItemTemplateId,
                nItemCount = tbNewTemplate[szVarCount]
            }
            table.insert(tbItems.tbItems, item)
        end
    end
    table.insert(tbGroup, tbItems)
    return true
end

-- {
--     nWeight
--     tbItems {
--         {
--             nItemTemplateId,
--             nItemCount
--         },
--         ...
--     }
-- }
-- [EXPORT BEGIN]
function BattleDropGroupDataTable:GetDropGroup(nDropGroupId)
    return self.tbContainer[nDropGroupId]
end
-- [EXPORT END]

return BattleDropGroupDataTable
