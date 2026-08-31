local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorLineTrace = luaclass("GameCorePacketProcessorLineTrace", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorLineTrace:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorLineTrace:DoAction(tbPacket)
    local tbGameObject  = self.tbAgent:GetGameObject()
    local nQueryId, nRadius, nSX, nSY, nSZ, nEX, nEY, nEZ =
    tbPacket.traceid, tbPacket.radius, tbPacket.start_x, tbPacket.start_y, tbPacket.start_z, tbPacket.end_x, tbPacket.end_y, tbPacket.end_z
    local pStart = Vector{X = nSX, Y = nSY, Z = nSZ}
    local pEnd   = Vector{X = nEX, Y = nEY, Z = nEZ}
    local nResult = ExtendBlueprintFunctions.GetCollisionDistance(tbGameObject.pUEActor, nRadius, pStart, pEnd)
    local tbRetPacket = { }
    tbRetPacket.id = nQueryId
    tbRetPacket.result = nResult
    self.tbGameCoreProxyClient:Send(Proto.c2s_linetrace, tbRetPacket)
    LOG("line trace ",nRadius, nSX, nSX, nSY, nSZ, nEX, nEY, nEZ, nQueryId, nResult)

end


return GameCorePacketProcessorLineTrace