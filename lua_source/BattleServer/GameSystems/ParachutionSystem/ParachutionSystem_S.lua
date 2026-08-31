local luaclass = require("luaclass")
local ParachutionSystem = require("ParachutionSystem")
local ParachutionSystem_S = luaclass("ParachutionSystem_S", ParachutionSystem)
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
-- local CommonEventDef = require("CommonEventDef")
-- local BotAISystem = dynamic_require("BotAISystem")

function ParachutionSystem_S:OnParachutionEnd(tbGameObject, bIsShip, bIsTransport, pTransportLocation)
    local tbPacket = {
        is_ship = bIsShip
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbGameObject:GetUEControllerUniqueId(), ProtoDC.d2c_ParachutionEnd, tbPacket)
    ParachutionSystem_S.super.OnParachutionEnd(self, tbGameObject, bIsShip, bIsTransport, pTransportLocation)
    -- local bIsBot = BotAISystem:IsBot(tbGameObject) 
    -- if not bIsBot then
    --     self.EventHelper:FireEvent(CommonEventDef.EV_LOG_DROP_LOCATION, tbGameObject)
    -- end
end

function ParachutionSystem_S:OnParachuteOpen(nUniqueId)
    local bResult = ParachutionSystem_S.super.OnParachuteOpen(self, nUniqueId)
    if bResult then
        NetworkManager:GetRPCNetworkProxy():SendToClient(nUniqueId, ProtoDC.d2c_ParachuteOpen)
    end
    return bResult
end

-- function ParachutionSystem_S:Init()
--     if not ParachutionSystem_S.super.Init(self) then
--         return false
--     end

--     return true
-- end

-- function ParachutionSystem_S:Uninit()
--     ParachutionSystem_S.super.Uninit(self)
-- end

return ParachutionSystem_S()