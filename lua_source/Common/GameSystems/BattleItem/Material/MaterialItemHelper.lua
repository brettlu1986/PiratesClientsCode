-----------------------------------------------------
--File Name    : MaterialItemHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-09-20
--Description  : 材料物品的帮助方法
-----------------------------------------------------
local MaterialItemHelper = { }

local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

-- 通过index获得材料的物品templateId
-- @param nIndex 材料的index
-- @return 物品templateId， 如果nIndex非法就返回nil
function MaterialItemHelper:GetMaterialTemplateId(nIndex)
    local tbCostItemTemplates = BattleItemDataTable:GetTemplatesByCategory(BattleItemCategoryDef.MATERIAL)
    for _, tbItemTemplate in pairs(tbCostItemTemplates) do
        if tbItemTemplate.nIndex == nIndex then
            return tbItemTemplate.nId
        end
    end
    return nil
end

return MaterialItemHelper