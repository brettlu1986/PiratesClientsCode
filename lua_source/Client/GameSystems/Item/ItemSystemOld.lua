-----------------------------------------------------
--File Name    : ItemSystemOld.lua
--Description  : Item 整个游戏世界的item管理类
-----------------------------------------------------

-- local ItemDef   = require("ItemDefine")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
-- local DirectlyUsableItemDetailTypeDef = require("DirectlyUsableItemDetailTypeDefine")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ItemSystemOld = {}
-- local ModpartEffectsDataTable = require("ModpartEffectsDataTable")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

local DRESS_SELECT = 0
local DRESS_RESET  = 1

function ItemSystemOld:GetSelfItemComponent()
    local ItemComponentOld = nil
    local PlayerSelf = PlayerSelfHelper:Get()
    if(not PlayerSelf) then
        logerror("ItemSystemOld get playerself failed")
    else
        ItemComponentOld = PlayerSelf.ItemComponentOld
    end
    return ItemComponentOld
end

-- local function CreateItemInfo(fnNewCreate, tbNewDataTable, NewItemClass)
--     return {
--         fnCreate = fnNewCreate,
--         tbDataTable = tbNewDataTable,
--         ItemClass = NewItemClass
--     }
-- end

local tbCreateItemFunc = {}

-- local function CreateItemBase(self, tbItemData)
--     local tbItemCreateInfo = tbCreateItemFunc[tbItemData.genre]
--     if tbItemCreateInfo == nil then
--         logerror("ItemSystemOld:CreateItem() item info is nil, g, d, p : ",
--                     tbItemData.genre, tbItemData.detail_type, tbItemData.particular)
--         return nil
--     end

--     local template = tbItemCreateInfo.tbDataTable:GetTemplate(tbItemData.genre, tbItemData.detail_type, tbItemData.particular)
--     if not template then
--         logerror("ItemSystemOld:CreateItem() item template is nil, g, d, p : ",
--                     tbItemData.genre, tbItemData.detail_type, tbItemData.particular)
--         return nil
--     else
--         local NewItem = tbItemCreateInfo.ItemClass()
--         NewItem:SetTemplate(template)
--         NewItem:SetInstanceId(tbItemData.instance_id)
--         NewItem:SetStackCount(tbItemData.stack_count)
--         NewItem:SetCreateTime(tbItemData.create_time)
--         NewItem:SetFirstUseTime(tbItemData.first_use_time)
--         return NewItem
--     end
-- end

-- local function CreateAccessory(self, tbItemData)
--     local ItemAccessory = CreateItemBase(self, tbItemData)
--     if not ItemAccessory then
--         return nil
--     end
--     ItemAccessory:SetDurablity(tbItemData.durability)
--     ItemAccessory:SetProperties(tbItemData.properties)
--     return ItemAccessory
-- end

-- local function CreateCargo(self, tbItemData)
--     local ItemCargo = CreateItemBase(self, tbItemData)
--     if not ItemCargo then
--         return nil
--     end
--     ItemCargo:SetProperties(tbItemData.properties)
--     return ItemCargo
-- end

-- tbCreateItemFunc[ItemDef.GEN_SPECIAL]          =  CreateItemInfo(CreateItemBase,  require("ItemSpecialDataTable"),        require("ItemOld"))
-- tbCreateItemFunc[ItemDef.GEN_MATERIAL]         =  CreateItemInfo(CreateItemBase,  require("ItemMaterialDataTable"),       require("ItemOld"))
-- tbCreateItemFunc[ItemDef.GEN_CARGO]            =  CreateItemInfo(CreateCargo,     require("ItemCargoDataTable"),          require("ItemCargo"))
-- tbCreateItemFunc[ItemDef.GEN_CONSUMABLE]       =  CreateItemInfo(CreateItemBase,  require("ItemConsumableDataTable"),     require("ItemOld"))
-- tbCreateItemFunc[ItemDef.GEN_ACCESSORY]        =  CreateItemInfo(CreateAccessory, require("ItemAccessoryDataTable"),      require("ItemAccessory"))
-- tbCreateItemFunc[ItemDef.GEN_DRESS]            =  CreateItemInfo(CreateItemBase,  require("ItemDressDataTable"),          require("ItemOld"))
-- tbCreateItemFunc[ItemDef.GEN_QUEST]            =  CreateItemInfo(CreateItemBase,  require("ItemQuestDataTable"),          require("ItemOld"))
-- tbCreateItemFunc[ItemDef.GEN_DIRECTLY_USABLE]  =  CreateItemInfo(CreateItemBase,  require("ItemDirectlyUsableDataTable"), require("ItemOld"))
-- tbCreateItemFunc[ItemDef.GEN_EQUIPMENT]        =  CreateItemInfo(CreateItemBase,  require("ItemEquipmentDataTable"),      require("ItemOld"))
-- tbCreateItemFunc[ItemDef.GEN_MODPART]          =  CreateItemInfo(CreateItemBase,  require("ItemModpartDataTable"),        require("ItemOld"))

-- local function Init

function ItemSystemOld:Init()
    return true
end

function ItemSystemOld:Uninit()
end

-- public definition
-- 创建物品
-- @param nGenre 	        物品的大类
-- @param nDetailType    	大类里的副类
-- @param nParticular       具体的
-- @return Item
function ItemSystemOld:CreateItem(tbItemData)
    local tbItemInfo = tbCreateItemFunc[tbItemData.genre]

    if tbItemInfo == nil then
        logerror("ItemSystemOld:CreateItem() item info is nil, g, d, p : ",
                    tbItemData.genre, tbItemData.detail_type, tbItemData.particular)
        return nil
    end

    local NewItem = tbItemInfo.fnCreate(self, tbItemData)

    return NewItem
end

function ItemSystemOld:GetItemTemplate(nGenre, nDetailType, nParticular)
    local tbItemInfo = tbCreateItemFunc[nGenre]
    if tbItemInfo == nil then
        logerror("ItemSystemOld:GetItemTemplate() item info is nil, g, d, p : ",
                    nGenre, nDetailType, nParticular)
        return nil
    end

    local tbTemplate = tbItemInfo.tbDataTable:GetTemplate(nGenre, nDetailType, nParticular)
    return tbTemplate
end

-- 使用图纸解锁配件
function ItemSystemOld:UseUnlockItem(nGenre, nDetailType, nParticular)
    -- if nGenre ~= ItemDef.GEN_DIRECTLY_USABLE or nDetailType ~= DirectlyUsableItemDetailTypeDef.UNLOCK_ITEM then
    --     logerror("Use unlock item failed! type not valid!", nGenre, nDetailType, nParticular)
    -- end
    local ItemComponentOld = self:GetSelfItemComponent()
    local tbItems = ItemComponentOld:GetBackpackItemsByType(nGenre, nDetailType, nParticular)
    if #tbItems < 1 then
        logerror("Use unlock item failed! cannot find this kind of item!", nGenre, nDetailType, nParticular)
    end
    local tbItem = tbItems[1]
    local nInstanceId = tbItem:GetInstanceId()
    self:UseItem(nInstanceId)
end

function ItemSystemOld:UseItem(nItemInstanceID, nParam1, nParam2, nParam3)
    local c2s_UseItem = {
        instance_id = nItemInstanceID,
        param1      = nParam1,
        param2      = nParam2,
        param3      = nParam3
    }
    local Socket = NetworkManager:GetHubServerProxy()
    if not Socket:SendPacket(Proto.c2s_UseItem, c2s_UseItem) then
        logwarning("ItemSystemOld:UseItem failed, nItemInstanceID : ", nItemInstanceID)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_REQUEST_USE_ITEM, nItemInstanceID)
end

function ItemSystemOld:CreateAccessory(nGenre, nDetailType, nParticular)
    local c2s_CreateAccessory = {
        type = {
            genre           = nGenre,
            detail_type     = nDetailType,
            particular      = nParticular,
        }
    }
    local Socket = NetworkManager:GetHubServerProxy()
    if not Socket:SendPacket(Proto.c2s_CreateAccessory, c2s_CreateAccessory) then
        logwarning("ItemSystemOld:CreateAccessory failed, nGenre, nDetailType, nParticular : ", nGenre, nDetailType, nParticular)
    end
end

function ItemSystemOld:SelectDress(nItemInstanceID)
    self:UseItem(nItemInstanceID, DRESS_SELECT)
end

function ItemSystemOld:ResetDress(nItemInstanceID)
    self:UseItem(nItemInstanceID, DRESS_RESET)
end

function ItemSystemOld:SellItem(nItemInstanceID)
    local c2s_SellItem = {
        instance_id = nItemInstanceID
    }
    local Socket = NetworkManager:GetHubServerProxy()
    if not Socket:SendPacket(Proto.c2s_SellItem, c2s_SellItem) then
        logwarning("ItemSystemOld:SellItem failed, nItemInstanceID : ", nItemInstanceID)
    end
end

function ItemSystemOld:GetItem(nItemInstanceID)
    local ItemComponentOld = self:GetSelfItemComponent()
    return ItemComponentOld:GetItem(nItemInstanceID)
end

function ItemSystemOld:GetItemRemainExpireSeconds(nItemInstanceID)
    local ItemComponentOld = self:GetSelfItemComponent()
    local Item = ItemComponentOld:GetItem(nItemInstanceID)
    if Item == nil then
        return -1
    end
    return Item:GetRemainExpireSeconds()
end

function ItemSystemOld:OpenItemEquipToastBoardUI(tbArgs)
    if not UIManager:IsWndVisible(UIDef.UI_ITEM_EQUIP_TOAST_BOARD) then
        UIManager:OpenWnd(UIDef.UI_ITEM_EQUIP_TOAST_BOARD, tbArgs)
    else
        local tbWnd = UIManager:GetWnd(UIDef.UI_ITEM_EQUIP_TOAST_BOARD)
        tbWnd:SetDatas(tbArgs)
    end
end

function ItemSystemOld:OpenQuickUseItem(nGenre, nDetailType, nParticular)
    if not UIManager:IsWndVisible(UIDef.UI_EQUIPMENT_TIPS) then
        local tbOpenArgs = {}
        local tbQuickUseItem = {}
        tbQuickUseItem.nGenre = nGenre
        tbQuickUseItem.nDetailType = nDetailType
        tbQuickUseItem.nParticular = nParticular
        table.insert(tbOpenArgs, tbQuickUseItem)
        UIManager:OpenWnd(UIDef.UI_EQUIPMENT_TIPS, tbOpenArgs)
    else
        local tbWnd = UIManager:GetWnd(UIDef.UI_EQUIPMENT_TIPS)
        tbWnd:AddItem(nGenre, nDetailType, nParticular)
    end
end

function ItemSystemOld:SplitModpart(tbItemIds)
    local c2s_SplitModpart = {
        modpart_ids = tbItemIds
    }
    local Socket = NetworkManager:GetHubServerProxy()
    if not Socket:SendPacket(Proto.c2s_SplitModpart, c2s_SplitModpart) then
        logwarning("ItemSystemOld:SplitModpart failed")
    end
end

-- local function AddEffect(tbTargetEffect, tbEffect, nStackCount)
--     if tbTargetEffect.nParam1 == nil then
--         tbTargetEffect.nParam1 = tbEffect.nParam1 * nStackCount
--         tbTargetEffect.nParam2 = tbEffect.nParam2
--         return
--     end
--     if tbTargetEffect.nParam2 == tbEffect.nParam2 then
--         tbTargetEffect.nParam1 = tbTargetEffect.nParam1 + tbEffect.nParam1 * nStackCount
--         return
--     end
--     if tbTargetEffect.nParam2 == 0 then
--         tbTargetEffect.nParam2 = tbEffect.nParam2;
--         tbTargetEffect.nParam1 = tbTargetEffect.nParam1 * tbTargetEffect.nParam2 + tbEffect.nParam1 * nStackCount;
--         return
--     end
--     if tbEffect.nParam2 == 0 then
--         tbTargetEffect.nParam1 = tbTargetEffect.nParam1 + tbEffect.nParam1 * nStackCount * tbTargetEffect.nParam2;
--         return
--     end
--     if tbTargetEffect.nParam2 % tbEffect.nParam2 == 0 then
--         tbTargetEffect.nParam1 = tbTargetEffect.nParam1 + tbEffect.nParam1 * nStackCount * tbTargetEffect.nParam2 / tbEffect.nParam2;
--         return
--     end
--     if tbEffect.nParam2 % tbTargetEffect.nParam2 == 0 then
--         tbTargetEffect.nParam1 = tbTargetEffect.nParam1 * tbEffect.nParam2 / tbTargetEffect.nParam2 + tbEffect.nParam1 * nStackCount;
--         tbTargetEffect.nParam2 = tbEffect.nParam2;
--         return
--     end
--     local base = tbTargetEffect.nParam2 * tbEffect.nParam2;
--     tbTargetEffect.nParam1 = tbTargetEffect.nParam1 * tbEffect.nParam2 + tbEffect.nParam1 * nStackCount * tbTargetEffect.nParam2;
--     tbTargetEffect.nParam2 = base;
-- end

-- local function AddEffectToList(tbEffects, tbEffect, nStackCount)
--     local tbTargetEffect = nil
--     for k,v in pairs(tbEffects) do
--         if v.szEffectType == tbEffect.szEffectType then
--             tbTargetEffect = v
--             break
--         end
--     end
--     if tbTargetEffect == nil then
--         tbTargetEffect = {}
--         tbTargetEffect.szEffectType = tbEffect.szEffectType
--         table.insert(tbEffects, tbTargetEffect)
--     end
--     AddEffect(tbTargetEffect, tbEffect, nStackCount)
-- end

function ItemSystemOld:GetModpartEffects(nGenre, nDetailType, nParticular)
    -- local tbItemTemplate = self:GetItemTemplate(nGenre, nDetailType, nParticular)
    -- local tbModpartEffectTemplate = ModpartEffectsDataTable:GetTemplate(tbItemTemplate.nModPartEffect)
    -- return tbModpartEffectTemplate.tbEffects
    return nil
end

function ItemSystemOld:GetShipModpartEffects(nShipInstanceId)
    -- local PlayerSelf = PlayerSelfHelper:Get()
    -- local DockComponent = PlayerSelf.DockComponent
    -- local ShipData = DockComponent:GetShip(nShipInstanceId)
    -- local tbModparts = ShipData:GetModparts()

    -- local tbResultEffects = {}

    -- for i,tbItemModpart in ipairs(tbModparts) do
    --     local tbItemModpartTemplate = tbItemModpart:GetTemplate()
    --     local nModPartEffect = tbItemModpartTemplate.nModPartEffect
    --     local tbModpartTemplate = ModpartEffectsDataTable:GetTemplate(nModPartEffect)
    --     local tbEffects = tbModpartTemplate.tbEffects
    --     local nStackCount = tbItemModpart:GetStackCount()
    --     for k,v in pairs(tbEffects) do
    --         AddEffectToList(tbResultEffects, v, nStackCount)
    --     end
    -- end

    -- return tbResultEffects
    return nil
end

function ItemSystemOld:GetCurrencyItemTemplate(nParticular)
    return self:GetItemTemplate(0, 1, nParticular)
end

return ItemSystemOld
