-----------------------------------------------------
--File Name    : ULFFAHumanWeapon.lua
--Author       : WuJizhou
--Create Time  : 3/18/2019, 9:48:02 PM
--Description  : ULFFAHumanWeapon
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULFFAHumanWeapon = luaclass("ULFFAHumanWeapon", UILogicBase)


local UIDef                  = require("UIDef")
local ClientEventDef         = require("ClientEventDef")
local HumanWeaponSlotDef     = require("HumanWeaponSlotDef")
local GamePlayerSelfHelper   = require("GamePlayerSelfHelper")
local BattleItemCategoryDef  = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")


local UI_SLOT_COUNT = 2

local function RefreshWeaponSlots(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nPlayerId = PlayerSelf:GetServerInstanceId()
    local tbEquips = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_WEAPON, nPlayerId)
    local nSlotCount = HumanWeaponSlotDef:SlotCount()
    for nSlotIdx = 1, nSlotCount do
        self.tbWeaponSlots[nSlotIdx]:ShowWeapon(tbEquips[nSlotIdx])
    end
end

local function BindGameLogicEvent(self)
    local EventHelper = self.EventHelper

    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_ADDED, self, RefreshWeaponSlots)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_REMOVED, self, RefreshWeaponSlots)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_STACK_COUNT_CHANGED, self, RefreshWeaponSlots)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_EXCHANGE, self, RefreshWeaponSlots)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_CLIENT, self, RefreshWeaponSlots)

end

function ULFFAHumanWeapon:Refresh()
    RefreshWeaponSlots(self)
end

function ULFFAHumanWeapon:Activate()
    BindGameLogicEvent(self)
    RefreshWeaponSlots(self)
end

function ULFFAHumanWeapon:Deactivate()
    self.EventHelper:UnregisterAll()
end
----------life cycle----------
function ULFFAHumanWeapon:OnCreate()
    self.tbWeaponSlots = {}

end

-- function ULFFAHumanWeapon:OnDestroy()
-- end

function ULFFAHumanWeapon:OnLoad()

    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    local nSlotCount = HumanWeaponSlotDef:SlotCount()

    for i=1, UI_SLOT_COUNT do
        local tbWeaponSlot = PrefabHelper:BindPrefab(pWidgetRef["pbFFAHumanSub" .. i],  UIDef.UP_HUMAN_WEAPON_SLOT_IN_MAIN)
        if tbWeaponSlot then
            if i <= nSlotCount then
                self.tbWeaponSlots[i] = tbWeaponSlot
                tbWeaponSlot:SetSlotIndex(i)
            else
                tbWeaponSlot:Disable()
            end
        end
    end
end

-- function ULFFAHumanWeapon:OnUnload()
-- end

-- function ULFFAHumanWeapon:OnEnter()
-- end

function ULFFAHumanWeapon:OnShow()
    RefreshWeaponSlots(self)
end

-- function ULFFAHumanWeapon:OnHide()
-- end

-- function ULFFAHumanWeapon:OnExit()
-- end

function ULFFAHumanWeapon:OnBindEvent( EventHelper )
end

-- function ULFFAHumanWeapon:OnUnbindEvent( EventHelper )
-- end

return ULFFAHumanWeapon