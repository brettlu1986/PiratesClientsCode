local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataBuildlist = luaclass("SyncDataBuildlist", SyncDataBase)
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponSlotDef = require("HumanWeaponSlotDef")
local HumanArmorSlotDef = require("HumanArmorSlotDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")

SyncDataBuildlist.tbBuildListItems = nil
SyncDataBuildlist.bDirty = false

local function GetCanBuildItemInfo(tbGameObject)
    local nCharacterInstanceId = tbGameObject.nServerInstanceId
    local bClient = false
    local tbBuildList = { }

    local tbShips = {}
    tbShips.templateids = CheckCanBuildItemHelper.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, bClient)
    tbBuildList.ships = tbShips

    local tbShipParts = {}
    tbShipParts.templateids = CheckCanBuildItemHelper.GetCanBuildShipPartItemTemplateIds(nCharacterInstanceId, bClient)
    tbBuildList.ship_parts = tbShipParts

    local tbShipWeapons = {}
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbShipWeaponsOnSlot = { }
        tbShipWeaponsOnSlot.templateids = CheckCanBuildItemHelper.GetCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, i, bClient)
        table.insert( tbShipWeapons, tbShipWeaponsOnSlot)
    end
    tbBuildList.ship_weapons = tbShipWeapons

    local tbHumanWeapons = {}
    for i=1, HumanWeaponSlotDef:SlotCount() do
        local tbHumanWeaponTemplates = {}
        tbHumanWeaponTemplates.templateids = CheckCanBuildItemHelper.GetCanBuildHumanWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, i, bClient)
        table.insert( tbHumanWeapons, tbHumanWeaponTemplates)
    end
    tbBuildList.human_weapons = tbHumanWeapons

    local tbHumanArmorWeapons = {}
    for i=1, HumanArmorSlotDef:SlotCount() do
        local tbHumanArmorTemplates = {}
        tbHumanArmorTemplates.templateids  = CheckCanBuildItemHelper.GetCanBuildHumanArmorItemTemplateIdsOnSlot(nCharacterInstanceId, i, bClient)
        table.insert( tbHumanArmorWeapons, tbHumanArmorTemplates)
    end
    tbBuildList.human_armors = tbHumanArmorWeapons

    return tbBuildList
end

local tbBuildRelatedItemCategory = {
    BattleItemCategoryDef.MATERIAL,
    BattleItemCategoryDef.SHIP_WEAPON,
    BattleItemCategoryDef.SHIP_PART,
    BattleItemCategoryDef.HUMAN_WEAPON,
    BattleItemCategoryDef.HUMAN_ARMOR,
    BattleItemCategoryDef.SHIP,
    BattleItemCategoryDef.BUILD_KEY_ITEM,
    BattleItemCategoryDef.CONVERTIBLE_ITEM,
}

local function IsBuildRelatedItem(tbItem)
    local nCategory = tbItem:GetCategory()
    for i,v in ipairs(tbBuildRelatedItemCategory) do
        if v == nCategory then
            return true
        end
    end
    return false
end

local function IsBuildRelatedItem_TemplateId(nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbTemplate then
        local nCategory = tbTemplate.nCategory
        for i,v in ipairs(tbBuildRelatedItemCategory) do
            if v == nCategory then
                return true
            end
        end
    end
    return false
end

local function OnItemAdd(self, Item)
    if Item:GetOwnerCharacter() == self.tbOwner and IsBuildRelatedItem(Item)  then
        self.bDirty = true
    end
end

local function OnItemRemove(self, nItemInstanceId, nItemTemplateId, nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
    if nCharacterInstanceId == self.tbOwner:GetServerInstanceId() and IsBuildRelatedItem_TemplateId(nItemTemplateId) then
        self.bDirty = true
    end
end

local function OnItemStackCountChanged(self, Item)
    if Item:GetOwnerCharacter() == self.tbOwner and IsBuildRelatedItem(Item) then
        self.bDirty = true
    end
end

function SyncDataBuildlist:RefreshBuildList()
    self.tbBuildListItems = GetCanBuildItemInfo(self.tbOwner)
    self.bDirty = false
end

function SyncDataBuildlist:BindEvent(SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER, self, OnItemAdd)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER, self, OnItemRemove)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_SERVER, self, OnItemStackCountChanged)
end

function SyncDataBuildlist:UnbindEvent(SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

function SyncDataBuildlist:OnSync(tbPack)
    if self.bDirty then
        self:RefreshBuildList()
    end
    tbPack.build_list = self.tbBuildListItems
end


function SyncDataBuildlist:OnStart()
    self:RefreshBuildList()
end


function SyncDataBuildlist:OnStop()

end

return SyncDataBuildlist