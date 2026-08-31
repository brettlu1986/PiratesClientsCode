-----------------------------------------------------
--File Name    : BattleItemFactory.lua
--Author       : zhiyuan
--Create Time  : 2018-08-13
--Description  : 游戏世界中的物品工厂类
-----------------------------------------------------
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemFactory = {}

local nMaxItemInstanceId = 0

local function AssignNextItemInstanceId(self)
    nMaxItemInstanceId = nMaxItemInstanceId + 1
    return nMaxItemInstanceId
end

local function CreateItem(nCategory, nSubCategory)
    local ItemClass = BattleItemSystemHelper:GetItemClass(nCategory, nSubCategory)
    return ItemClass()
end

function BattleItemFactory:CreateItem(nTemplateId, nStackCount, bOnServer)
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if tbTemplate == nil then
        error("BattleItemSystem:CreateItem() item template is nil, templateId: " .. nTemplateId)
    end
    local NewItem = CreateItem(tbTemplate.nCategory, tbTemplate.nSubCategory)
    local nInstanceId = AssignNextItemInstanceId(self)
    NewItem:Init(nInstanceId, tbTemplate, nStackCount, bOnServer)
    NewItem:ClearStorageLocation()
    return NewItem
end

-- run on client
function BattleItemFactory:CreateItemWithProtoData(tbPlayer, tbItemProtoData)
    local nTemplateId = tbItemProtoData.template_id
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if tbTemplate == nil then
        error("BattleItemSystem:ParseItem() item template is nil, templateId: " .. nTemplateId)
    end
    local NewItem = CreateItem(tbTemplate.nCategory, tbTemplate.nSubCategory)
    NewItem:InitWithProtoData(tbPlayer, tbItemProtoData)
    return NewItem
end

return BattleItemFactory
