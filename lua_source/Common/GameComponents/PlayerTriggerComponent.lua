local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local PlayerTriggerComponent = luaclass("PlayerTriggerComponent", GameComponentBaseClass)
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local PropName = require("PropName")

local HUMAN_DEVIATION = 150
local SHIP_DEVIATION = 500
local TRIGGER_OFFSET_HEIGHT = 200

PlayerTriggerComponent.EventHelper = nil

local function Init(self, pUEActor)
    if pUEActor == nil then
        return
    end
    local nRadius, nDeviation = 0, 0
    if self.Owner:IsShip() then
        nRadius = self.Owner.ShipBattlePropertyComponent:GetProp(PropName.nShipPickupRange)
        nDeviation = SHIP_DEVIATION
    elseif self.Owner:IsHuman() then
        nRadius = self.Owner.HumanBattlePropertyComponent:GetProp(PropName.nHumanPickupRange)
        nDeviation = HUMAN_DEVIATION
    end
    pUEActor:CreatePickUpComponent(nRadius, nDeviation)
end

local function Uninit(self)

end

local function OnAirDropEnd(self, tbGameObject)
    if tbGameObject == nil then
        return
    end

    local nX1, nY1, nZ1 = self.Owner:GetLocationXYZ()
    local nX2, nY2, nZ2 = tbGameObject:GetLocationXYZ()

    local nRadius = 0
    local bInTrigger = false
    if self.Owner:IsShip() then
        nRadius = self.Owner.ShipBattlePropertyComponent:GetProp(PropName.nShipPickupRange)
        if (nX1 - nX2) * (nX1 - nX2) + (nY1 - nY2) * (nY1 - nY2) <= nRadius * nRadius then
            bInTrigger = true
        end
    else
        nRadius = self.Owner.HumanBattlePropertyComponent:GetProp(PropName.nHumanPickupRange)
        if (nX1 - nX2) * (nX1 - nX2) + (nY1 - nY2) * (nY1 - nY2) <= nRadius * nRadius then
            bInTrigger = math.abs(nZ1 - nZ2) <= TRIGGER_OFFSET_HEIGHT
        end
    end

    if not bInTrigger then
        return
    end

    EventManager:OnFireEvent(CommonEventDef.EV_PLAYER_ENTER_TRIGGER, self.Owner, tbGameObject)
end

function PlayerTriggerComponent:OnCreate(Owner, tbParams)
    EventManager:BindEventMethod(CommonEventDef.EV_FFA_AIRDROP_END, self, OnAirDropEnd)

    return PlayerTriggerComponent.super.OnCreate(self, Owner, tbParams)
end

function PlayerTriggerComponent:OnDestroy()
    EventManager:UnBindEventMethod(CommonEventDef.EV_FFA_AIRDROP_END, self, OnAirDropEnd)

    PlayerTriggerComponent.super.OnDestroy(self)
end

function PlayerTriggerComponent:OnActorPreCreated(pUEActor)
    PlayerTriggerComponent.super.OnActorCreated(self, pUEActor)

    log("PlayerTriggerComponent:OnActorPreCreated", pUEActor)
    if(pUEActor) then
        Init(self, pUEActor)
    end
end

function PlayerTriggerComponent:OnActorDestroyed(pUEActor)
    log("PlayerTriggerComponent:OnActorDestroyed")
    Uninit(self)
    PlayerTriggerComponent.super.OnActorDestroyed(self, pUEActor)
end

return PlayerTriggerComponent
