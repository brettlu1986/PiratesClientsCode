-----------------------------------------------------
--File Name    : DisplayItemHelper.lua
--Author       : Chen Yixin
--Create Time  : 2019-09-26
--Description  : 大厅中展示相关helper
-----------------------------------------------------

local DisplayItemHelper = {}

local ItemSystem = require("ItemSystem")
local ItemCategoryDef = require("ItemCategoryDef")
local ItemDataTable = require("ItemDataTable")
local ShipResDataTable = require("ShipResDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipDataTable = require("ShipDataTable")

local Util = require("BaseUtil")

local function MakeDisplayFashionItemTemplate(tbFashionIds, nExpirationTime)
    local tbResult = {}
    tbResult.nExpirationTime = nExpirationTime
    tbResult.tbFashionIds = tbFashionIds
    tbResult.nCategory = ItemCategoryDef.FASHION
    return tbResult
end

local function UpdateDisplayFashionItemTemplate(tbOutDisplayFashionItemTemplate, nAppendFashionTemplateId, nExpirationTime)
    local tbResult = {}
    table.insert(tbOutDisplayFashionItemTemplate.tbFashionIds, nAppendFashionTemplateId)
    if nExpirationTime then
        if tbOutDisplayFashionItemTemplate.nExpirationTime and nExpirationTime < tbOutDisplayFashionItemTemplate.nExpirationTime then
            tbOutDisplayFashionItemTemplate.nExpirationTime = nExpirationTime
        end
    end
    return tbResult
end


local function PostProcessDisplayFashionSuitTemplates(tbDisplayFashionSuitTemplates)
    local tbResult = {}
    for nSuitId, tbDisplayFashionSuitTemplate in pairs(tbDisplayFashionSuitTemplates) do
        local tbFashionIds = tbDisplayFashionSuitTemplate.tbFashionIds
        local tbItemTemplate = ItemDataTable:GetTemplate(nSuitId)
        if #tbItemTemplate.tbSubItemTemplateIds == #tbFashionIds then
            table.insert(tbResult, tbDisplayFashionSuitTemplate)
        else
            for _, nItemTemplateId in pairs(tbFashionIds) do
                local tbTemplate = MakeDisplayFashionItemTemplate({nItemTemplateId}, tbDisplayFashionSuitTemplate.nExpirationTime)
                table.insert(tbResult, tbTemplate)
            end
        end
    end
    return tbResult
end

function DisplayItemHelper.CheckNeedDisplayItems(tbItems)
    if not tbItems then
        return false
    end
    for _, v in ipairs(tbItems) do
        local tbItemTemplate = ItemDataTable:GetTemplate(v.nItemTemplateId)
        if tbItemTemplate.nCategory == ItemCategoryDef.SHIP_SKIN 
        or tbItemTemplate.nCategory == ItemCategoryDef.SHIP
        or tbItemTemplate.nCategory == ItemCategoryDef.FASHION
        or tbItemTemplate.nCategory == ItemCategoryDef.SUIT then
            return true
        end
    end
    return false
end

-- 获取道具展示数据
function DisplayItemHelper.InitItemTemplates(tbItems)
    if not tbItems then
        log("ULLobbyDisplayAwardItem:Init, no tbOpenArgs")
        return
    end

    local tbItemsNew = {}
    -- local tbFashionIds = {}
    local tbDisplayFashionSuitTemplates = {}
    -- local tbFashionTemplate = {nCategory = ItemCategoryDef.FASHION}
    local tbDisplayItemTemplates = {}
    for _, v in ipairs(tbItems) do
        local tbItemTemplate = ItemDataTable:GetTemplate(v.nItemTemplateId)
        if v.nUnlockId then
            local tbTemplate = ItemDataTable:GetTemplate(v.nUnlockId)
            tbItemTemplate = Util:LightCopyTable(tbItemTemplate)
            tbItemTemplate.nExpirationTime = tbTemplate.nUnlockItemExpirationTime
        end
        if tbItemTemplate.nCategory == ItemCategoryDef.SHIP_SKIN or tbItemTemplate.nCategory == ItemCategoryDef.SHIP then
            table.insert(tbDisplayItemTemplates, tbItemTemplate)
        elseif tbItemTemplate.nCategory == ItemCategoryDef.FASHION then
            local nItemTemplateId = tbItemTemplate.nId
            local nExpirationTime = tbItemTemplate.nExpirationTime
            local nSuitId = tbItemTemplate.nSuitId
            if nSuitId then
                local tbSuitData = tbDisplayFashionSuitTemplates[nSuitId]
                if not tbSuitData then
                    tbSuitData = MakeDisplayFashionItemTemplate({nItemTemplateId}, nExpirationTime)
                    tbDisplayFashionSuitTemplates[nSuitId] = tbSuitData
                else
                    UpdateDisplayFashionItemTemplate(tbSuitData, nItemTemplateId, nExpirationTime)
                end
            else
                local tbDisplayFashionItemTemplate = MakeDisplayFashionItemTemplate({nItemTemplateId}, nExpirationTime)
                table.insert(tbDisplayItemTemplates, tbDisplayFashionItemTemplate)
            end
        elseif tbItemTemplate.nCategory == ItemCategoryDef.SUIT then
            local tbSuitTemplate = ItemDataTable:GetTemplate(tbItemTemplate.nId)
            local tbDisplayFashionItemTemplate = MakeDisplayFashionItemTemplate(tbSuitTemplate.tbSubItemTemplateIds, tbItemTemplate.nExpirationTime)
            table.insert(tbDisplayItemTemplates, tbDisplayFashionItemTemplate)
        else
            table.insert(tbItemsNew, v)
        end
    end
    -- 处理套装
    if next(tbDisplayFashionSuitTemplates) then
        tbDisplayFashionSuitTemplates = PostProcessDisplayFashionSuitTemplates(tbDisplayFashionSuitTemplates)
        table.move(tbDisplayFashionSuitTemplates, 1, #tbDisplayFashionSuitTemplates, #tbDisplayItemTemplates + 1, tbDisplayItemTemplates)
    end
    
    -- -- 将时装template放到展示列表末尾
    -- if #tbFashionIds > 0 then
    --     tbFashionTemplate.tbFashionIds = tbFashionIds
    --     -- {{tbFashionIds = {1, 2, 3}, nExpirationTime = xxx}, {tbFashionIds = {1, 2}, nExpirationTime = xxx}...}
    --     table.insert(tbDisplayItemTemplates, tbFashionTemplate)
    -- end

    return tbItemsNew, tbDisplayItemTemplates
end

-- 获取道具展示信息
function DisplayItemHelper.GetDisplayIteml10nName(tbItemTemplates)
    if tbItemTemplates.nCategory == ItemCategoryDef.FASHION then
        local nItemTemplateId = tbItemTemplates.tbFashionIds[1]
        local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
        local nSuitId = tbItemTemplate.nSuitId
        if nSuitId then
            local tbSuitTemplate = ItemDataTable:GetTemplate(nSuitId)
            if #tbSuitTemplate.tbSubItemTemplateIds == #tbItemTemplates.tbFashionIds then
                return tbSuitTemplate.l10nName
            else
                return ItemDataTable:GetTemplate(nItemTemplateId).l10nName
            end
        else
            return ItemDataTable:GetTemplate(nItemTemplateId).l10nName
        end
    else
        return tbItemTemplates.l10nName
    end
end

-- 根据船或船皮肤的ItemId获取船ResTemplate
function DisplayItemHelper.GetShipResTemplate(nShipItemId)
    local tbShipItemTemplate = ItemSystem:GetItemTemplate(nShipItemId)
    if tbShipItemTemplate == nil then
        error("tbShipItemTemplate is nil, nShipItemId is " .. tostring(nShipItemId))
    end
    if tbShipItemTemplate.nCategory == ItemCategoryDef.SHIP_SKIN then
        return ShipResDataTable:GetTemplate(tbShipItemTemplate.nShipResId)
    elseif tbShipItemTemplate.nCategory == ItemCategoryDef.SHIP then
        local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(tbShipItemTemplate.nBattleItemId)
        if tbBattleItemTemplate == nil then
            error("tbBattleItemTemplate is nil, nBattleItemId is " .. tostring(tbShipItemTemplate.nBattleItemId))
        end
        return ShipDataTable:GetResTemplate(tbBattleItemTemplate.nShipId)
    end
end

function DisplayItemHelper.GetExperienceCardDisplayTemplate(nId)
    local tbTemplate = ItemSystem:GetItemTemplate(nId)
    local tbUnlockItem = ItemSystem:GetItemTemplate(tbTemplate.nUnlockItemTemplateId)
    if not tbUnlockItem then
        return nil
    end
    local tbDisplayItem = {
        nItemTemplateId = tbUnlockItem.nId,
        nCategory = tbUnlockItem.nCategory,
        nExpireType = tbUnlockItem.nExpireType,
        nUnlockId = tbTemplate.nId
    }
    local tbDisplayItemTemplates = {}
    table.insert(tbDisplayItemTemplates, tbDisplayItem)
    return tbDisplayItemTemplates
end

return DisplayItemHelper