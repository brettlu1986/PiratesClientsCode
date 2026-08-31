-----------------------------------------------------
--File Name    : AbilityAction_EarlyEndWithMoveCheck.lua
--Author       : Song Fuhao
--Create Time  : 2019-01-21
--Description  : 每次触发时检测移动，如果移动为true，减少一定buff时间(只能给buff使用)
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_EarlyEndWithMoveCheck = luaclass("AbilityAction_EarlyEndWithMoveCheck", AbilityActionBase)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

AbilityAction_EarlyEndWithMoveCheck.nDecreasingTime = 1
AbilityAction_EarlyEndWithMoveCheck.nTotalDecreasingTime = 0

local function IsMoving(self)
    local OwnerPawn = self.OwnerPawn
    local pOwnerActor = OwnerPawn.pUEActor
    if OwnerPawn:IsHuman() then
        return KismetMathLibrary.VSize(pOwnerActor:GetVelocity()) > 0
    else
        return pOwnerActor.ShipMovementComponent:IsShipMoving()
    end
end

function AbilityAction_EarlyEndWithMoveCheck:OnCreate(Owner, tbInitParams)
    if tbInitParams.DecreasingTime then
        self.nDecreasingTime = tbInitParams.DecreasingTime
    end
end

function AbilityAction_EarlyEndWithMoveCheck:OnDo(tbParams)
    if IsMoving(self) then
        self.nTotalDecreasingTime = self.nTotalDecreasingTime + self.nDecreasingTime
        if self.nTotalDecreasingTime > self.Owner:GetRemainingTime() then
            EventManager:OnFireEvent(CommonEventDef.EV_TRIGGER_REMOVE_BUFF, self.Owner)
        end
    end
end

return AbilityAction_EarlyEndWithMoveCheck
