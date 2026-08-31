local BattlePlayerHelper = {}

local D2CHelper = require("D2CHelper")

local pTempVector = Vector()

BattlePlayerHelper.DeadList = nil

function BattlePlayerHelper:Init()
    self.DeadList = {}
end

function BattlePlayerHelper:Uninit()
    self.DeadList = nil
end

function BattlePlayerHelper:AddDeadList(nPlayerId)
    if self:CheckInDeadList(nPlayerId) == false then
        self.DeadList[nPlayerId]= nPlayerId
    end
end

function BattlePlayerHelper:CheckInDeadList(nPlayerId)
    if self.DeadList[nPlayerId] == nil then
        return false
    end
    return true
end

function BattlePlayerHelper:Teleport(tbPlayer, tbTransform, bResetMovement)
    assert(tbPlayer)
    assert(tbPlayer.pUEActor)
    assert(tbTransform)
    pTempVector.X = tbTransform.X ~= nil and tbTransform.X or 0
    pTempVector.Y = tbTransform.Y ~= nil and tbTransform.Y or 0
    pTempVector.Z = tbTransform.Z ~= nil and tbTransform.Z or 0
    local nYaw = tbTransform.Yaw ~= nil and tbTransform.Yaw or 0
    bResetMovement = bResetMovement == nil or bResetMovement

    if (tbPlayer:IsShip()) then
        local pShipMovementComponent = tbPlayer.pUEActor.ShipMovementComponent
        assert(isvalidhandle(pShipMovementComponent))
        pShipMovementComponent:TeleportShip(pTempVector, nYaw, bResetMovement)
    else
        local pCharacterMovement = tbPlayer.pUEActor.CharacterMovement
        assert(isvalidhandle(pCharacterMovement))
        pCharacterMovement:TeleportHuman(pTempVector, nYaw, bResetMovement, true)
    end

    D2CHelper:PlayerSetCameraYaw(tbPlayer, nYaw)
end

return BattlePlayerHelper