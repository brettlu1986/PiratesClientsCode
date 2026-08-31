-----------------------------------------------------
--File Name    : BattleItemInitHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-08-28
--Description  : 初始化副本内道具的helper
-----------------------------------------------------

local BattleItemInitHelper = {}

local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

function BattleItemInitHelper.GetShipTypeId(tbSourceItems)
    assert(tbSourceItems ~= nil)
    local nShipId = -1
    for _,v in ipairs(tbSourceItems) do
        local tbItemTemplate = BattleItemDataTable:GetTemplate(v.nItemTemplateId)
        if tbItemTemplate.nCategory == BattleItemCategoryDef.SHIP then
            nShipId = tbItemTemplate.nShipId
            break
        end
    end
    if nShipId < 0 then
        error("Cannot find player formal scene ship!")
    end
    return nShipId
end

return BattleItemInitHelper