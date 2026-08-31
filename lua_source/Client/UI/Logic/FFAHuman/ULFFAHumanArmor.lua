-----------------------------------------------------
--File Name    : ULFFAHumanArmor.lua
--Author       : WuJizhou
--Create Time  : 3/18/2019, 9:48:15 PM
--Description  : ULFFAHumanArmor
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULFFAHumanArmor = luaclass("ULFFAHumanArmor", UILogicBase)
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local HumanArmorSlotDef = require("HumanArmorSlotDef")
local ClientEventDef = require("ClientEventDef")
local UIDef = require("UIDef")

local UI_FIXED_ARMOR_SLOT_COUNT = 2

local function RefreshArmorSlots(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nPlayerId = PlayerSelf:GetServerInstanceId()
    local tbArmors = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_ARMOR, nPlayerId)
    local nSlotCount = HumanArmorSlotDef:SlotCount()
    for nSlotIdx = 1, nSlotCount do
        if nSlotIdx <= nSlotCount then
            self.tbArmorSlots[nSlotIdx]:ShowArmor(tbArmors[nSlotIdx])
        else
            self.tbArmorSlots[nSlotIdx]:ShowArmor(nil)
        end
    end
end

local function BindGameLogicEvent(self)
    local EventHelper = self.EventHelper

    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_DURABILITY_CLIENT, self, RefreshArmorSlots)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_ADDED, self, RefreshArmorSlots)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_REMOVED, self, RefreshArmorSlots)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_STACK_COUNT_CHANGED, self, RefreshArmorSlots)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_EXCHANGE, self, RefreshArmorSlots)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_CLIENT, self, RefreshArmorSlots)

end

function ULFFAHumanArmor:Activate()
    BindGameLogicEvent(self)
    RefreshArmorSlots(self)
end

function ULFFAHumanArmor:Deactivate()
    self.EventHelper:UnregisterAll()
end

----------life cycle----------
function ULFFAHumanArmor:OnCreate()
    self.tbArmorSlots = {}
end

-- function ULFFAHumanArmor:OnDestroy()
-- end

function ULFFAHumanArmor:OnLoad()
    local pWidgetRef = self.pWidgetRef
    for i = 1, UI_FIXED_ARMOR_SLOT_COUNT do
        local tbArmorSlot = self.PrefabHelper:BindPrefab(pWidgetRef["pbEmquieTip0" .. i],  UIDef.UP_HUMAN_ARMOR_SLOT_IN_MAIN)
        if tbArmorSlot then
            tbArmorSlot:SetSlotIndex(i)
            tbArmorSlot.pWidgetRef:SetVisibility(ESlateVisibility.Hidden)
            self.tbArmorSlots[i] = tbArmorSlot
        end
    end
end

-- function ULFFAHumanArmor:OnUnload()
-- end

-- function ULFFAHumanArmor:OnEnter()
-- end

-- function ULFFAHumanArmor:OnShow()
-- end

-- function ULFFAHumanArmor:OnHide()
-- end

-- function ULFFAHumanArmor:OnExit()
-- end

function ULFFAHumanArmor:OnBindEvent( EventHelper )

end

-- function ULFFAHumanArmor:OnUnbindEvent( EventHelper )
-- end

return ULFFAHumanArmor