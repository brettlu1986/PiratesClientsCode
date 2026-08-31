-----------------------------------------------------
--File Name    : BattleItemDropSystem.lua
--Author       : luyue
--Create Time  : 2018-08-20
--Description  : 整个游戏世界的物品掉落System
-----------------------------------------------------

local BattleItemDropDataTable = require("BattleItemDropDataTable")
local BattleItemDropGroupDataTable = require("BattleItemDropGroupDataTable")
local BattleItemDropSystem = {}

function BattleItemDropSystem:Init()
    return true
end

-- 有放回的随机
local function DropItemsWithReplacement(tbDropGroupElements, nCount)
    local tbResult = {}
    local nTotalWeight = 0
    for _, tbDropGroupElement in ipairs(tbDropGroupElements) do
        nTotalWeight = nTotalWeight + tbDropGroupElement.nWeight
    end
    for i=1, nCount do
        local nRandom = math.random(1, nTotalWeight)
        local nSumWeight = 0
        for _, tbDropGroupElement in ipairs(tbDropGroupElements) do
            nSumWeight = nSumWeight + tbDropGroupElement.nWeight
            if nRandom <= nSumWeight then
                table.insert(tbResult, tbDropGroupElement.tbItems)
                break
            end
        end
    end
    return tbResult
end

-- 无放回的随机
-- 执行后 tbDropGroupElements 会乱序
local function DropItemsWithoutReplacement(tbDropGroupElements, nCount)
    assert(nCount <= #tbDropGroupElements)
    local tbResult = {}

    local CalculateMaxWeight = function(nElementCount)
        local nTotalWeight = 0
        for i=1, nElementCount do
            local tbDropGroupElement = tbDropGroupElements[i]
            nTotalWeight = nTotalWeight + tbDropGroupElement.nWeight
        end
        return nTotalWeight
    end
    for i=1, nCount do
        local nRestCount = #tbDropGroupElements - i + 1
        local nMaxWeight = CalculateMaxWeight(nRestCount)
        local nRandom = math.random(1, nMaxWeight)
        local nSumWeight = 0
        for j=1, nRestCount do
            local tbDropGroupElement = tbDropGroupElements[j]
            nSumWeight = nSumWeight + tbDropGroupElement.nWeight
            if nSumWeight >= nRandom then
                table.insert(tbResult, tbDropGroupElement.tbItems)
                tbDropGroupElements[j], tbDropGroupElements[nRestCount] = tbDropGroupElements[nRestCount], tbDropGroupElements[j]
                break
            end
        end
    end
    return tbResult
end

local function Drop(tbDropGroupElements, nCount, bReplacement)
    if bReplacement then
        return DropItemsWithReplacement(tbDropGroupElements, nCount)
    else
        return DropItemsWithoutReplacement(tbDropGroupElements, nCount)
    end
end

local function Merge(tbRawResult)
    local tbResult = {}
    local tbMerged = {}
    table.insert(tbResult, tbMerged)
    for _, tbGroupResult in ipairs(tbRawResult) do
        for _, tbItem in ipairs(tbGroupResult) do
            table.insert(tbMerged, tbItem)
        end
    end
    return tbResult
end

local function ShuffleInplace(tbArray)
    for i = #tbArray, 1, -1 do
        local j = math.random(i)
        tbArray[i], tbArray[j] = tbArray[j], tbArray[i]
    end
    return tbArray
end

-- 随机物品入口
-- @param nDropGroupId 掉落组Id 索引 item_drop.tab
-- @return => {tbItemGroup1, tbItemGroup2} => array 当 bMerge 为 true 的时候，这里只会有一个元素返回，全部做了合并操作
--   tbItemGroup1 => {tbItemInfo1, tbItemInfo2} => array 枪1 + 子弹1，配置在 drop_group.tab 中的组合
--     tbItemInfo1 => {nItemTemplateId = 1, nItemCount = 2} => table
-- return 第二个参数为 nSceneItemPackage 类型，索引 scene_item_package.tab 表，若没填，返回 nil
function BattleItemDropSystem:DropItems(nDropId)
    local tbDropRule = BattleItemDropDataTable:GetDropRule(nDropId)
    if tbDropRule == nil then
        error("BattleItemDropSystem nothing drop. No drop id: "..nDropId)
        return
    end

    local nSceneItemPackage = tbDropRule.nSceneItemPackage
    if nSceneItemPackage and nSceneItemPackage <= 0 then
        nSceneItemPackage = nil
    end

    local bMerge = tbDropRule.bMerge
    local bReplacement = tbDropRule.bReplacement
    local tbRawResult = {}
    -- log("BattleItemDropSystem:DropItems nDropId:", nDropId)
    for _, tbDropGroup in ipairs(tbDropRule.tbDropGroups) do
        local nCount = math.random(tbDropGroup.nMinCount, tbDropGroup.nMaxCount)
        -- log("BattleItemDropSystem drop", nCount, " item groups in group", tbDropGroup.nDropGroupId)
        local tbDropGroupElements = BattleItemDropGroupDataTable:GetDropGroup(tbDropGroup.nDropGroupId)
        assert(tbDropGroupElements ~= nil, "DropGroup not exist. nDropGroupId: "..tbDropGroup.nDropGroupId)
        local tbGroupResult = Drop(tbDropGroupElements, nCount, bReplacement)
        for _, tbItems in ipairs(tbGroupResult) do
            table.insert(tbRawResult, tbItems)
            -- for _, v in pairs(tbItems) do
            --     log("BattleItemDropSystem:DropItems", v.nItemTemplateId, bReplacement, nDropId, tbDropGroup.nDropGroupId, tbDropGroup.nMinCount, tbDropGroup.nMaxCount, nCount)
            -- end
        end
    end
    if bMerge then
        return Merge(tbRawResult), nSceneItemPackage
    else
        return ShuffleInplace(tbRawResult), nSceneItemPackage
    end
end

return BattleItemDropSystem
