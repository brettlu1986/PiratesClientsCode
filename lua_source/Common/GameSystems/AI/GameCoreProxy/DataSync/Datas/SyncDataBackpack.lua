local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataBackpack = luaclass("SyncDataBackpack", SyncDataBase)
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleItemRoomDef = require("BattleItemRoomDef")
local CommonEventDef = require("CommonEventDef")
-- local BattleItemCategoryDef = require("BattleItemCategoryDef")

SyncDataBackpack.tbBackpackItems = nil
SyncDataBackpack.bDirty = false


local function CreateItemData(Item)
    local tbItem = {}
    tbItem.id = Item:GetInstanceId()
    tbItem.templateid = Item:GetTemplateId()
    tbItem.count = Item:GetStackCount()
    return tbItem
end

local function GetBackpackItems(tbGameObject)
    local nCharacterInstanceId = tbGameObject:GetServerInstanceId()
    local tbBackpack = {}
    local tbItems = {}
    local tbInventory = BattleItemSystemServer:GetUnEquippedItems(nCharacterInstanceId, BattleItemRoomDef.HUMAN_INVENTORY)
    for i,v in ipairs(tbInventory) do
        table.insert(tbItems, CreateItemData(v))
    end
    tbInventory = BattleItemSystemServer:GetUnEquippedItems(nCharacterInstanceId, BattleItemRoomDef.CABIN)
    for i,v in ipairs(tbInventory) do
        table.insert(tbItems, CreateItemData(v))
    end
    local tbMaterials = BattleItemSystemServer:GetUnEquippedItems(nCharacterInstanceId, BattleItemRoomDef.MATERIAL_ROOM)
    for i,v in ipairs(tbMaterials) do
        table.insert(tbItems, CreateItemData(v))
    end
    tbBackpack.items = tbItems
    return tbBackpack
end



local function OnItemAdd(self, Item)
    if Item:GetOwnerCharacter() == self.tbOwner then
        local nItemRoomType, _, _ = Item:SplitAndGetStorageLocation()
        if BattleItemRoomDef:IsInventoryRoom(nItemRoomType) then
            self.bDirty = true
        end
    end
end

local function OnItemRemove(self, nItemInstanceId, nItemTemplateId, nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
    if nCharacterInstanceId == self.tbOwner:GetServerInstanceId() then
        if BattleItemRoomDef:IsInventoryRoom(nRoomType) then
            self.bDirty = true
        end
    end
end

local function OnItemStackCountChanged(self, Item)
    if Item:GetOwnerCharacter() == self.tbOwner then
        local nItemRoomType, _, _ = Item:SplitAndGetStorageLocation()
        if BattleItemRoomDef:IsInventoryRoom(nItemRoomType) then
            self.bDirty = true
        end
    end
end

local function OnItemChangeStorageLocation(self, tbItem, OldItemRoomType)
    if tbItem:GetOwnerCharacter() == self.tbOwner then
        if OldItemRoomType and BattleItemRoomDef:IsInventoryRoom(OldItemRoomType) then
            self.bDirty = true
        else
            local nItemRoomType, _, _ = tbItem:SplitAndGetStorageLocation()
            if BattleItemRoomDef:IsInventoryRoom(nItemRoomType) then
                self.bDirty = true
            end
        end
    end
end

function SyncDataBackpack:RefreshBackpackItems()
    self.tbBackpackItems = GetBackpackItems(self.tbOwner)
    self.bDirty = false
end

function SyncDataBackpack:BindEvent(SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER, self, OnItemAdd)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER, self, OnItemRemove)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_SERVER, self, OnItemStackCountChanged)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_SERVER, self, OnItemChangeStorageLocation)
end

function SyncDataBackpack:UnbindEvent(SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

function SyncDataBackpack:OnSync(tbPack)
    if self.bDirty then
        self:RefreshBackpackItems()
    end
    tbPack.backpack = self.tbBackpackItems
end


function SyncDataBackpack:OnStart()
    self:RefreshBackpackItems()
end


function SyncDataBackpack:OnStop()

end

return SyncDataBackpack