-----------------------------------------------------
--File Name    : AIPreparationHelper.lua
--Author       : zhiyuan
--Create Time  : 2020-08-11
--Description  : 生成ai可以建造的船相关道具列表
-----------------------------------------------------
local AIPreparationHelper = {}

local ItemDataTable         = require("ItemDataTable")
local ItemCategoryDef       = require("ItemCategoryDef")

local ADD_SHIP_COUNT = 4

local function FillShipWeapon(tbPreparations)
    local tbShipWeaponTemplates = ItemDataTable:GetTemplatesByCategory(ItemCategoryDef.SHIP_WEAPON)
    for _, v in pairs(tbShipWeaponTemplates) do
        if v.bDefaultOption then
            table.insert(tbPreparations, v.nId)
        end
    end
end

local function FillShipParts(tbPreparations)
    local tbShipPartTemplates = ItemDataTable:GetTemplatesByCategory(ItemCategoryDef.SHIP_PART)
    for _, v in pairs(tbShipPartTemplates) do
        if v.bDefaultOption then
            table.insert(tbPreparations, v.nId)
        end
    end
end

local function FillShips(tbPreparations)
    local tbShipTemplates = ItemDataTable:GetTemplatesByCategory(ItemCategoryDef.SHIP)
    local tbNotDefaultShipTemplateIds = {}
    for _, v in pairs(tbShipTemplates) do
        if v.bDefaultEquipped then
            table.insert(tbPreparations, v.nId)
        else
            table.insert(tbNotDefaultShipTemplateIds, v.nId)
        end
    end

    for i = 1,ADD_SHIP_COUNT do
        local nCount = #tbNotDefaultShipTemplateIds
        if nCount <= 0 then
            break
        end
        local nIndex = math.random(1, nCount)
        table.insert(tbPreparations, tbNotDefaultShipTemplateIds[nIndex])
        table.remove(tbNotDefaultShipTemplateIds, nIndex)
    end

end

function AIPreparationHelper.GetShipPreparation()
    local tbPreparations = {}
    FillShips(tbPreparations)
    FillShipWeapon(tbPreparations)
    FillShipParts(tbPreparations)

    return tbPreparations
end

return AIPreparationHelper