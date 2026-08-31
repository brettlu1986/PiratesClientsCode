local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataShipArmor = luaclass("SyncDataShipArmor", SyncDataBase)
local CommonEventDef = require("CommonEventDef")
local ShipPartTypeDef  = require("ShipPartTypeDef")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

SyncDataShipArmor.tbEquippedArmors = nil
SyncDataShipArmor.tbArmors = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SyncDataShipArmor:", ...)
end

-- luacheck: pop

function SyncDataShipArmor:OnArmorAdd(tbOwnerCharacter, nItemId)
    if self.tbOwner == tbOwnerCharacter then
        local tbItem = BattleItemSystemServer:GetItem(nItemId)
        local _, _, nSlotIndex = tbItem:SplitAndGetStorageLocation()
        self.tbEquippedArmors[nSlotIndex] = tbItem
        LOG("ship add armor at ", nSlotIndex)
    end
end

function SyncDataShipArmor:OnArmorRemove(tbOwnerCharacter, nItemId)
    if self.tbOwner == tbOwnerCharacter then
        for k,v in pairs(self.tbEquippedArmors) do
            if v and v:GetInstanceId() == nItemId then
                self.tbEquippedArmors[k] = nil
                LOG("ship remove armor at ", k)
                break
            end
        end
    end
end

function SyncDataShipArmor:BindEvent(SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_SHIP_ARMOR_ON_EQUIPED_SERVER, self, self.OnArmorAdd)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_SHIP_ARMOR_ON_UNEQUIPED_SERVER, self, self.OnArmorRemove)
end

function SyncDataShipArmor:UnbindEvent(SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

function SyncDataShipArmor:OnSync(tbPack)
    local tbArmors = self.tbArmors
    for i=1, ShipPartTypeDef.Max do
        local tbArmorItem = self.tbEquippedArmors[i]
        local tbArmor = tbArmors[i]
        if tbArmorItem then
            tbArmor.id = tbArmorItem.nInstanceId
            tbArmor.templateid = tbArmorItem:GetTemplateId()
            tbArmor.durability_percent = tbArmorItem:GetDurability() / tbArmorItem:GetTemplate().nDurability
        else
            tbArmor.id = 0
            tbArmor.templateid = 0
            tbArmor.durability_percent = 0
        end
    end
    if self.tbOwner:IsShip() then
        tbPack.equipments = self.tbArmors
    else
        tbPack.ship_stat_cache = tbPack.ship_stat_cache or {}
        tbPack.ship_stat_cache.equipments = self.tbArmors
    end
end


function SyncDataShipArmor:OnStart()
    self.tbEquippedArmors = {}
    self.tbArmors = {}
    local tbGameObject = self.tbOwner
    local nServerInstanceId = tbGameObject:GetServerInstanceId()
    for i=1, ShipPartTypeDef.Max do
        local tbArmorItem = BattleItemSystemServer:GetEquippedItem(nServerInstanceId, BattleItemCategoryDef.SHIP_PART, nServerInstanceId, i)
        self.tbEquippedArmors[i] = tbArmorItem
        local tbArmor = { }
        if tbArmorItem then
            tbArmor.id = tbArmorItem.nInstanceId
            tbArmor.templateid = tbArmorItem:GetTemplateId()
            tbArmor.durability_percent = tbArmorItem:GetDurability() / tbArmorItem:GetTemplate().nDurability
        else
            tbArmor.id = 0
            tbArmor.templateid = 0
            tbArmor.durability_percent = 0
        end
        self.tbArmors[i] = tbArmor
    end
end


function SyncDataShipArmor:OnStop()

end

return SyncDataShipArmor