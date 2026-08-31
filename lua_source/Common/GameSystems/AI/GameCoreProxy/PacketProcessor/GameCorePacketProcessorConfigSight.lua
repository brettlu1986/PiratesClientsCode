local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorConfigSight = luaclass("GameCorePacketProcessorConfigSight", GameCorePacketProcessorAction)


-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorConfigSight:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorConfigSight:DoAction(tbPacket)
    local tbAgent = self.tbAgent:GetGameObject()
    local pAIController = self.tbAgent.pAIController
    local nPawnSightDistance, nItemSightDistance, Fov =
    tbPacket.pawn_sight_distance, tbPacket.item_sight_distance, tbPacket.fov
    if nPawnSightDistance <= 0 or nItemSightDistance <= 0 or Fov <= 0 or Fov > 360 then
        logerror("GameCoreBotAgent-> config sight failed! param not valid",
            tbAgent:GetServerInstanceId(), nPawnSightDistance, nItemSightDistance, Fov)
        return
    end
    if not tbAgent:IsAlive() then
        logerror("GameCoreBotAgent-> config sight failed! agent is dead", tbAgent:GetServerInstanceId())
        return
    end
    if not pAIController then
        logerror("GameCoreBotAgent-> config sight failed! no pAIController", tbAgent:GetServerInstanceId())
        return
    end

    LOG("config sight:", nPawnSightDistance, nItemSightDistance, Fov)
    pAIController:SetSightParams(nPawnSightDistance, nItemSightDistance, Fov)
end


return GameCorePacketProcessorConfigSight