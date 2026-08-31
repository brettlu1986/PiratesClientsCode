-----------------------------------------------------
--File Name    : GuideTriggerSelectShipWeapon.lua
--Description  : 船选择武器触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerSelectShipWeapon  = luaclass("GuideTriggerSelectShipWeapon", GuideTrigger)

local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local BattleItemSystemClient    = require("BattleItemSystemClient")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local ShipWeaponSlotDef         = require("ShipWeaponSlotDef")
local CommonEventDef            = require("CommonEventDef")
local ClientEventDef            = require("ClientEventDef")
local Timer                     = require("Timer")
local BattleShipWeaponSystem    = dynamic_require("BattleShipWeaponSystem")

-----------------------------------------------------
GuideTriggerSelectShipWeapon.tbParam         = nil
GuideTriggerSelectShipWeapon.nActivePlayerLv = nil
GuideTriggerSelectShipWeapon.nWaitSec        = nil
GuideTriggerSelectShipWeapon.bTriggerTimer   = false

local TRIGGER_SELECT = "TriggerSelect"
-----------------------------------------------------

local function IsShipSlotEmpty()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local bEquipHead = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, PlayerSelf.nServerInstanceId, ShipWeaponSlotDef.HEAD) ~= nil
    local bEquipSide = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, PlayerSelf.nServerInstanceId, ShipWeaponSlotDef.SIDE) ~= nil
    local bEquipDeck = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, PlayerSelf.nServerInstanceId, ShipWeaponSlotDef.DECK) ~= nil
    return not bEquipHead and not bEquipSide and not bEquipDeck
end

local function StartTriggerTimer(self)
    self.bTriggerTimer = true
    Timer.StartOwnerTimer(self, TRIGGER_SELECT, function() 
        self:DebugLog("StartTriggerTimer 11111")
        if not IsShipSlotEmpty() then
            local nActiveWeaponSlot = BattleShipWeaponSystem:GetActiveWeaponSlot_C()
            self:DebugLog("StartTriggerTimer 222", nActiveWeaponSlot)
            if nActiveWeaponSlot == ShipWeaponSlotDef.UNKNOWN then  
                self:DebugLog("StartTriggerTimer 3333")
                self:Trigger()
            end
        end
        self.bTriggerTimer = false
    end, self.nWaitSec )
end 

--变船检查一次
local function CheckNeedSelectShipWeapon(self, tbGameObject)
    local nInsId = tbGameObject:GetServerInstanceId()
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    --切船成功
    if nInsId == nCharacterInstanceId and tbGameObject:IsShip() then  
        if not IsShipSlotEmpty() then   
            StartTriggerTimer(self)
        end
    end
end

--建造船装倍或者捡起其他武器检查一次
local function OnShipWeaponEquipped(self, tbCharacter, nSlot, WeaponItem)
    local nInsId = tbCharacter:GetServerInstanceId()
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    self:DebugLog("euip item equip 1 ", self.bTriggerTimer)
    if nInsId == nCharacterInstanceId and tbCharacter:IsShip() and not self.bTriggerTimer then  
        self:DebugLog("euip item equip 2")
        StartTriggerTimer(self)
    end
end

function GuideTriggerSelectShipWeapon:End()
    Timer.StopOwnerAllTimer(self, true)
    GuideTriggerSelectShipWeapon.super.End(self)
end
--override
function GuideTriggerSelectShipWeapon:Begin()
    GuideTriggerSelectShipWeapon.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam 
    if tbParam and tbParam[1] then
        self.tbParam = tbParam
        self.nWaitSec = tonumber(tbParam[1])  --等待时间
    end
    self.bTriggerTimer = false
end

function GuideTriggerSelectShipWeapon:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, CheckNeedSelectShipWeapon)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_EQUIPPED_CLIENT, self, OnShipWeaponEquipped)
end

return GuideTriggerSelectShipWeapon
