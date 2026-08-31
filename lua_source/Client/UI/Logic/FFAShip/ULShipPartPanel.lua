
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULShipPartPanel = luaclass("ULShipPartPanel", UILogicBase)
local ClientEventDef = require("ClientEventDef")
local ShipPartTypeDef = require("ShipPartTypeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemRoomDef = require("BattleItemRoomDef")

ULShipPartPanel.tbSlots = { }

function ULShipPartPanel:OnLoad()
    self.tbSlots = {}
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    for i=1, ShipPartTypeDef.Max do
        self.tbSlots[i] = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbShipPartSlot0"..i])
        self.tbSlots[i]:Init(i)
        local tbShipPart = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_PART, tbPlayerSelf.nServerInstanceId, i)
        if tbShipPart then
            self.tbSlots[i]:SetShipPartInstanceId(tbShipPart:GetInstanceId())
        else
            self.tbSlots[i]:SetShipPartInstanceId(0)
        end
    end
end

local function OnBattleItemEquipped(self, Item, nOwnerInstanceId, nSlotIndex, nStackCount)
    if Item.tbTemplate.nCategory == BattleItemCategoryDef.SHIP_PART and self.tbSlots[nSlotIndex] then
        self.tbSlots[nSlotIndex]:SetShipPartInstanceId(Item:GetInstanceId())
    end
end


local function OnBattleItemUnequipped(self, nCharacterInstanceId, nItemInstanceId, nItemTemplateId, nRoomType, nOwnerInstanceId, nSlotIndex, nStackCount)
    if nRoomType == BattleItemRoomDef.SHIP_PART_ROOM and self.tbSlots[nSlotIndex] then
        self.tbSlots[nSlotIndex]:SetShipPartInstanceId(0)
    end
end


local function OnBattleItemChangeDurability(self, nItemInstanceId, nDurability)
    local tbItem = BattleItemSystemClient:GetItem(nItemInstanceId)
    if tbItem and tbItem.tbTemplate.nCategory == BattleItemCategoryDef.SHIP_PART then
        local nSlotIndex = tbItem.tbTemplate.nSubCategory
        self.tbSlots[nSlotIndex]:SetShipPartInstanceId(tbItem:GetInstanceId())
    end
end

local function BindGameLogicEvent(self)
    local EventHelper = self.EventHelper

    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_EQUIPED_CLIENT, self, OnBattleItemEquipped)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_UNEQUIPED_CLIENT, self, OnBattleItemUnequipped)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_DURABILITY_CLIENT, self, OnBattleItemChangeDurability)

end

function ULShipPartPanel:Activate()
    BindGameLogicEvent(self)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    for i=1, ShipPartTypeDef.Max do
        local tbShipPart = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_PART, tbPlayerSelf.nServerInstanceId, i)
        if tbShipPart then
            self.tbSlots[i]:SetShipPartInstanceId(tbShipPart:GetInstanceId())
        else
            self.tbSlots[i]:SetShipPartInstanceId(0)
        end
    end
end

function ULShipPartPanel:Deactivate()
    self.EventHelper:UnregisterAll()
end

function ULShipPartPanel:OnBindEvent(EventHelper)
end


return ULShipPartPanel