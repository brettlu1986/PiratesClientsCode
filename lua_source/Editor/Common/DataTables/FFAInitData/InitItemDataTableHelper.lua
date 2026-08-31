-----------------------------------------------------
--File Name    : InitItemDataTableHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-09-28
--Description  : 读取初始物品配置的helper文件
-----------------------------------------------------
local InitItemDataTableHelper = {}

local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemCategoryDataTable = require("BattleItemCategoryDataTable")

local SORT_WEIGHTS = {}
SORT_WEIGHTS[BattleItemCategoryDef.SHIP] = 5
SORT_WEIGHTS[BattleItemCategoryDef.SHIP_WEAPON] = 4
SORT_WEIGHTS[BattleItemCategoryDef.SHIP_PART] = 3
SORT_WEIGHTS[BattleItemCategoryDef.HUMAN_WEAPON] = 2
SORT_WEIGHTS[BattleItemCategoryDef.HUMAN_ARMOR] = 1

local function GetSortWeight(nCategory)
    local nWeight = SORT_WEIGHTS[nCategory]
    if nWeight == nil then
        nWeight = 0
    end
    return nWeight
end

function InitItemDataTableHelper.Check(tbNewTemplate, szPath)
    local nItemTemplateId = tbNewTemplate.nId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate == nil then
        error("Parse "..szPath.." failed! tbItemTemplate is nil!"..nItemTemplateId)
    end
    if tbNewTemplate.nCount < 1 then
        error("Parse "..szPath.." failed! count less than 1!"
              ..nItemTemplateId..", "..tbNewTemplate.nCount)
    end
    local nCategory = tbItemTemplate.nCategory
    if BattleItemCategoryDataTable:CanInEquippedRoom(nCategory)
        and not BattleItemCategoryDataTable:CanInUnequippedRoom(nCategory)  then
        if not tbItemTemplate.bStackable then
            if tbNewTemplate.nCount ~= 1 then
                error("Parse "..szPath.." failed! count is more than stack limit!"
                      ..nItemTemplateId..", "..tbNewTemplate.nCount)
            end
        else
            if tbNewTemplate.nCount > tbItemTemplate.nStackLimit then
                error("Parse "..szPath.." failed! count is more than stack limit!"
                      ..nItemTemplateId..", "..tbNewTemplate.nCount..","..tbItemTemplate.nStackLimit)
            end
        end
    end
end

-- 初始物品的时候，有些物品需要按照顺序加否则装不上
function InitItemDataTableHelper.fnSort(tbTemplate1, tbTemplate2)
    local nItemTemplateId1 = tbTemplate1.nId
    local nItemTemplateId2 = tbTemplate2.nId

    local tbItemTemplate1 = BattleItemDataTable:GetTemplate(nItemTemplateId1)
    local tbItemTemplate2 = BattleItemDataTable:GetTemplate(nItemTemplateId2)

    local nCategory1 = tbItemTemplate1.nCategory
    local nCategory2 = tbItemTemplate2.nCategory

    local nWeight1 = GetSortWeight(nCategory1)
    local nWeight2 = GetSortWeight(nCategory2)

    if nWeight1 ~= nWeight2 then
        return nWeight1 > nWeight2
    end

    return nItemTemplateId1 < nItemTemplateId2
end

function InitItemDataTableHelper.GetItems(tbDatas)
    if tbDatas == nil then
        error("GetItems failed! data is nil!")
    end
    local tbItems = {}
    for _ , v in ipairs(tbDatas) do
        local tbItem = {}
        tbItem.nItemTemplateId = v.nId
        tbItem.nItemCount = v.nCount
        table.insert(tbItems, tbItem)
    end
    return tbItems
end

return InitItemDataTableHelper