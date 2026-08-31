local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local ConvertibleItemOperationHelper = luaclass("ConvertibleItemOperationHelper", ItemCategoryOperationHelperBase)
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemDataTable = require("BattleItemDataTable")
local PropName = require("PropName")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local function GetConvertItemTemplateAndCount(self, nCharacterInstanceId, Item)
    local tbTemplate = Item:GetTemplate()
    local nConvertItemTemplateId = tbTemplate.nConvertItemTemplateId
    local nConvertItemCount = tbTemplate.nConvertItemCount

    local tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    local tbMaterialCollector = tbPlayer.ShipBattlePropertyComponent:GetProp(PropName.tbMaterialCollector)
    if tbMaterialCollector ~= nil then
        local tbCollectorData = tbMaterialCollector[nConvertItemTemplateId]
        if tbCollectorData ~= nil then
            local BattleItemComponentServer = tbPlayer.BattleItemComponentServer
            local nTotalExtraAddCount = BattleItemComponentServer:GetExtraAddMaterial(nConvertItemTemplateId)
            if nTotalExtraAddCount < tbCollectorData.nMaxCount then
                local nExtraAdd = math.min(tbCollectorData.nCount, tbCollectorData.nMaxCount - nTotalExtraAddCount)
                if nExtraAdd > 0 then
                    nConvertItemCount = nConvertItemCount + nExtraAdd
                    BattleItemComponentServer:RecordExtraAddMaterial(nConvertItemTemplateId, nExtraAdd)
                end
            end
        end
    end

    return nConvertItemTemplateId, nConvertItemCount
end

-- 是否可以自动拾取
function ConvertibleItemOperationHelper:CanAutoPickUpOnClient(Item)
    local tbTemplate = Item:GetTemplate()
    local tbItemProtoData = {
        template_id = tbTemplate.nConvertItemTemplateId,
        stack_count = tbTemplate.nConvertItemCount,
        storage_location = {}
    }
    local BattleItemSystemClient = BattleItemSystemHelper:GetBattleItemSystemClient()
    local bIsBatter, bAutoPickUp, nAutoPickUpCount = BattleItemSystemClient:CanAutoPickUp(tbItemProtoData)
    return bIsBatter, bAutoPickUp, nAutoPickUpCount
end

-- 是否可以手动拾取
function ConvertibleItemOperationHelper:CanManuallyPickUpOnClient(Item)
    local tbTemplate = Item:GetTemplate()
    local tbItemProtoData = {
        template_id = tbTemplate.nConvertItemTemplateId,
        stack_count = tbTemplate.nConvertItemCount,
        storage_location = {}
    }
    local BattleItemSystemClient  = BattleItemSystemHelper:GetBattleItemSystemClient()
    return BattleItemSystemClient:CanManuallyPickUp(tbItemProtoData)
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function ConvertibleItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    local tbTemplate = Item:GetTemplate()
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local TempItem = BattleItemSystemServer:CreateTempItem(tbTemplate.nConvertItemTemplateId, tbTemplate.nConvertItemCount)
    return BattleItemSystemServer:CanAutoPickUp(nCharacterInstanceId, TempItem)
end

-- 加到玩家身上之前的处理
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param Item 准备增加的物品
-- @return Item 最终加给玩家的物品
function ConvertibleItemOperationHelper:BeforeAddedToCharacterOnServer(nCharacterInstanceId, Item)
    local nTemplateId, nStackCount = GetConvertItemTemplateAndCount(self, nCharacterInstanceId, Item)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()

    local NewItem = BattleItemSystemServer:CreateItem(nTemplateId, nStackCount)
    BattleItemSystemServer:DestroyItem(Item:GetInstanceId())
    return NewItem
end

-- 是否玩家可见
function ConvertibleItemOperationHelper:CanKnownByPlayer(nItemTemplateId)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nConvertItemTemplateId = tbItemTemplate.nConvertItemTemplateId
    return BattleItemSystemHelper:CanKnownByPlayer(nConvertItemTemplateId)
end

return ConvertibleItemOperationHelper