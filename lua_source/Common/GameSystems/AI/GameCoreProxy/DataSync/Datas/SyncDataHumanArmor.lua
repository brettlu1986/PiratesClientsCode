local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataHumanArmor = luaclass("SyncDataHumanArmor", SyncDataBase)
local CommonEventDef = require("CommonEventDef")
local HumanArmorSlotDef  = require("HumanArmorSlotDef")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

SyncDataHumanArmor.tbEquippedArmors = nil
SyncDataHumanArmor.tbArmors = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SyncDataHumanArmor:", ...)
end

-- luacheck: pop


function SyncDataHumanArmor:OnArmorAdd(nOwnerCharacterInstanceId, nItemId)
    if self.tbOwner:GetServerInstanceId() == nOwnerCharacterInstanceId then
        local tbItem = BattleItemSystemServer:GetItem(nItemId)
        local _, _, nSlotIndex = tbItem:SplitAndGetStorageLocation()
        self.tbEquippedArmors[nSlotIndex] = tbItem
        LOG("human add armor at ", nSlotIndex)
    end
end

function SyncDataHumanArmor:OnArmorRemove(nOwnerCharacterInstanceId, nItemId)
    if self.tbOwner:GetServerInstanceId() == nOwnerCharacterInstanceId then
        for k,v in pairs(self.tbEquippedArmors) do
            if v and v:GetInstanceId() == nItemId then
                self.tbEquippedArmors[k] = nil
                LOG("human remove armor at ", k)
                break
            end
        end
    end
end

function SyncDataHumanArmor:BindEvent(SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_ARMOR_ON_EQUIPED_SERVER, self, self.OnArmorAdd)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_ARMOR_ON_UNEQUIPED_SERVER, self, self.OnArmorRemove)
end

function SyncDataHumanArmor:UnbindEvent(SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

function SyncDataHumanArmor:OnSync(tbPack)
    local tbArmors = self.tbArmors
    for i=1, HumanArmorSlotDef:SlotCount() do
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
    if self.tbOwner:IsHuman() then
        tbPack.equipments = self.tbArmors
    else
        tbPack.human_stat_cache = tbPack.human_stat_cache or {}
        tbPack.human_stat_cache.equipments = self.tbArmors
    end
end


function SyncDataHumanArmor:OnStart()
    self.tbEquippedArmors = {}
    self.tbArmors = {}
    local tbGameObject = self.tbOwner
    local nServerInstanceId = tbGameObject:GetServerInstanceId()
    for i=1, HumanArmorSlotDef:SlotCount() do
        local tbArmorItem = BattleItemSystemServer:GetEquippedItem(nServerInstanceId, BattleItemCategoryDef.HUMAN_ARMOR, nServerInstanceId, i)
        self.tbEquippedArmors[i] = tbArmorItem
        local tbArmor = {}
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


function SyncDataHumanArmor:OnStop()

end

return SyncDataHumanArmor