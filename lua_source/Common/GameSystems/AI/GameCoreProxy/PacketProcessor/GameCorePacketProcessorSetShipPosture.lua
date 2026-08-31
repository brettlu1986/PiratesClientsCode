local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorSetShipPosture = luaclass("GameCorePacketProcessorSetShipPosture", GameCorePacketProcessorAction)
local ShipMovementDef               = require("ShipMovementDef")
local ShipPostureDef = ShipMovementDef.ShipPostureDef

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorSetShipPosture:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorSetShipPosture:DoAction(tbPacket)
    local tbPlayer = self.tbAgent:GetGameObject()
    local nShipPosture = tbPacket.ship_posture
    if not tbPlayer:IsShip() then
        logerror("GameCoreBotAgent-> set ship posture failed! Bot is not ship!", tbPlayer:GetServerInstanceId())
        return
    end
    local BattleShipMovementComponent = tbPlayer.BattleShipMovementComponent
    if not BattleShipMovementComponent then
        logerror("GameCoreBotAgent-> set ship posture failed! Cannot find BattleShipMovementComponent!", tbPlayer:GetServerInstanceId())
        return
    end

    if tbPlayer:IsDead() or tbPlayer:IsDying() then
        logerror("GameCoreBotAgent-> set ship posture failed! Bot is dead or dying!", tbPlayer:GetServerInstanceId())
        return
    end

    if nShipPosture ~= ShipPostureDef.FullSail
        and nShipPosture ~= ShipPostureDef.HalfSail
        and nShipPosture ~= ShipPostureDef.Reef then
            logerror("GameCoreBotAgent-> set ship posture failed! Posture is not valid!", tbPlayer:GetServerInstanceId(), nShipPosture)
            return
    end

    local nCurrentPosture = BattleShipMovementComponent:GetPosture()

    if nCurrentPosture == nShipPosture then
        log("GameCoreBotAgent-> set ship posture failed! Postures are same!", tbPlayer:GetServerInstanceId(), nShipPosture)
        return
    end

    BattleShipMovementComponent:SetPosture(nShipPosture)
    LOG("Set ship posture", tbPlayer:GetServerInstanceId(), nShipPosture)
end


return GameCorePacketProcessorSetShipPosture