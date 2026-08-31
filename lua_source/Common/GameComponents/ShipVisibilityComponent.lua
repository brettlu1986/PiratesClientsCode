local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ShipVisibilityComponent = luaclass("ShipVisibilityComponent", GameComponentBase)

local Timer = require("Timer")
local PropName = require("PropName")
local DungeonIni = require("DungeonIni")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local MAX_VISIBLE_DISTANCE = DungeonIni.tbFFA.nShipMaxVisibleDistance -- 最大可见距离
local EXIT_FIGHTING_STATE_TIME = DungeonIni.tbFFA.nShipExitFightingStateTime -- 退出作战状态事件

ShipVisibilityComponent.nOverrideId = nil
ShipVisibilityComponent.bFightingState = false

local function SetIsFightingState(self, bFightingState)
    if self.bFightingState == bFightingState then
        return
    end
    self.bFightingState = bFightingState
    if bFightingState then
        self.nOverrideId = self.Owner.ShipBattlePropertyComponent:PropOverlap_Override(PropName.nShipVisibleDistance, MAX_VISIBLE_DISTANCE)
    elseif self.nOverrideId then
        self.Owner.ShipBattlePropertyComponent:RemovePropOverlap(PropName.nShipVisibleDistance, self.nOverrideId)
        self.nOverrideId = nil
    end
end

local function ClearTimer(self)
    if self.tbExitFightingStateTimer then
        self.tbExitFightingStateTimer:Clear()
        self.tbExitFightingStateTimer = nil
    end
end

local function RefreshTimer(self)
    self.tbExitFightingStateTimer = Timer.StartTimer(self.tbExitFightingStateTimer, function()
        self.tbExitFightingStateTimer = nil
        SetIsFightingState(self, false)
    end, EXIT_FIGHTING_STATE_TIME, false)
end

local function OnShipWeaponFringSucceed(self, tbCharacter, tbWeaponItem, nFiringCount)
    if self.Owner ~= tbCharacter then
        return
    end
    SetIsFightingState(self, true)
    RefreshTimer(self)
end

local function OnTakeDamage(self, tbPlayer)
    if self.Owner ~= tbPlayer then
        return
    end
    RefreshTimer(self)
end

function ShipVisibilityComponent:OnActorCreated(...)
    ShipVisibilityComponent.super.OnActorCreated(self, ...)
    if self.Owner:IsShip() then
        EventManager:BindEventMethod(CommonEventDef.EV_ON_SHIP_WEAPON_FIRED_SERVER, self, OnShipWeaponFringSucceed)
        EventManager:BindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
    end
end

function ShipVisibilityComponent:OnActorDestroyed(...)
    if self.Owner:IsShip() then
        EventManager:UnBindEventMethod(CommonEventDef.EV_ON_SHIP_WEAPON_FIRED_SERVER, self, OnShipWeaponFringSucceed)
        EventManager:UnBindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
        SetIsFightingState(self, false)
        ClearTimer(self)
    end
    ShipVisibilityComponent.super.OnActorDestroyed(self, ...)
end

return ShipVisibilityComponent