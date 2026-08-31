-----------------------------------------------------
--File Name    : ShipItemHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-10-31
--Description  : 船物品的帮助方法
-----------------------------------------------------
local ShipItemHelper = { }

local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipSkinItemDataTableHelper = require("ShipSkinItemDataTableHelper")
local BattleItemDataTable = require("BattleItemDataTable")

function ShipItemHelper.GetCurrentShipItem(nCharacterInstanceId, bIsClient)
    local ActiveShipItem = BattleItemSystemHelper:GetEquippedItem(
        nCharacterInstanceId, BattleItemCategoryDef.SHIP, nCharacterInstanceId, 1, bIsClient)

    return ActiveShipItem
end

function ShipItemHelper.GetCurrentShipItemTemplateId(nCharacterInstanceId, bIsClient)
    local ActiveShipItem = BattleItemSystemHelper:GetEquippedItem(
        nCharacterInstanceId, BattleItemCategoryDef.SHIP, nCharacterInstanceId, 1, bIsClient)

    if not ActiveShipItem then
        return nil
    end

    return ActiveShipItem:GetTemplateId()
end

function ShipItemHelper.GetCurrentShipItemTemplateIdOnClient()
    local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    return ShipItemHelper.GetCurrentShipItemTemplateId(nCharacterInstanceId, true)
end

-- 获得舰船图标
function ShipItemHelper.GetShipIconPath(tbItemTemplate)
    local BattleItemSystemClient = BattleItemSystemHelper:GetBattleItemSystemClient()
    local tbShipSkinDatas = BattleItemSystemClient:GetShipSkinIds()
    local nShipSkinId = tbShipSkinDatas[tbItemTemplate.nId]
    if nShipSkinId then
        return ShipSkinItemDataTableHelper.GetHorizontalPosterPath(nShipSkinId)
    else
        local ShipResDataTable = require("ShipResDataTable")
        local tbShipResTemplate = ShipResDataTable:GetTemplate(tbItemTemplate.nShipId)
        return tbShipResTemplate.szIconPath
    end
end

-- 通过船的templateid获得道具的template
function ShipItemHelper.GetItemTemplateByShipTemplateId(nShipTemplateId)
    local tbTemplates = BattleItemDataTable:GetTemplatesByCategory(BattleItemCategoryDef.SHIP)
    for _, v in pairs(tbTemplates) do
        if v.nShipId == nShipTemplateId then
            return v
        end
    end
    return nil
end

return ShipItemHelper