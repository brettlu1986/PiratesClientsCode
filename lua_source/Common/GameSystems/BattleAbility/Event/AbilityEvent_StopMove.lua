-----------------------------------------------------
--File Name    : AbilityEvent_StopMove.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-11
--Description  : 停船时触发Do；从停船状态移动时触发Undo
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_StopMove = luaclass("AbilityEvent_StopMove", AbilityEventBaseClass)

AbilityEvent_StopMove.bDone = false

local function OnShipMoveStateChanged(self, bMoving)
    if bMoving and self.bDone then
        self.bDone = false
        self:TriggerUndo()
    else
        self.bDone = true
        self:TriggerDo()
    end
end

function AbilityEvent_StopMove:OnActivate()
    if self.OwnerPawn:IsShip() then
        local bMoving = self.OwnerPawn.pUEActor.ShipMovementComponent:IsShipMoving()
        OnShipMoveStateChanged(self, bMoving)
        self.OwnerPawn.DelegateComponent.OnShipMoveStateChanged:Bind(OnShipMoveStateChanged, self)
    end
end

function AbilityEvent_StopMove:OnDeactivate()
    if self.OwnerPawn:IsShip() then
        self.OwnerPawn.DelegateComponent.OnShipMoveStateChanged:Unbind(OnShipMoveStateChanged, self)
    end
    if self.bDone then
        self.bDone = false
        self:TriggerUndo()
    end
end

return AbilityEvent_StopMove
