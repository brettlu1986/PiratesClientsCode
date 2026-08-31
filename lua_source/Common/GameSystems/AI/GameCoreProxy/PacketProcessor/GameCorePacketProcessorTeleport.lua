local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorTeleport = luaclass("GameCorePacketProcessorTeleport", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorTeleport:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorTeleport:DoAction(tbPacket)
    local tbPlayer = self.tbAgent:GetGameObject()
    local nResult = 1
    if tbPlayer then
        local pLocation = Vector{X = tbPacket.x, Y = tbPacket.y, Z = tbPacket.z}
        local nYaw = 0
        if tbPlayer:IsShip() then
            local ShipMovementComponent = tbPlayer.pUEActor.ShipMovementComponent
            if(isvalidhandle(ShipMovementComponent)) then
                ShipMovementComponent:TeleportShip(pLocation, nYaw, true)
                nResult = 0
            end
        else
            local tbAgent = self.tbAgent
            local CharacterMovement = tbPlayer.pUEActor.CharacterMovement
            if(isvalidhandle(CharacterMovement)) then
                CharacterMovement:TeleportHuman(pLocation, nYaw, true, true)
                tbAgent.bStucked = EngineExtActorShell.IsPawnLocationBlocked(GWorld, tbPlayer.pUEActor)
                LOG("born stucked ", tbPlayer.szName, tbAgent.bStucked)
                nResult = 0
            end
        end
    end
    self:ReportActionResult(Proto.ActionType.Teleport, nResult)
end


return GameCorePacketProcessorTeleport