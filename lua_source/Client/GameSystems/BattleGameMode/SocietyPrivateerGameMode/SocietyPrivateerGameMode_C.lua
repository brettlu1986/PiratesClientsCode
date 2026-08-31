local luaclass = require("luaclass")

local SocietyPrivateerGameModeClass = require("SocietyPrivateerGameMode")
local SocietyPrivateerGameMode_C = luaclass("SocietyPrivateerGameMode_C", SocietyPrivateerGameModeClass)

local Proto = require("ClientProtoNames")

local NetworkManager = dynamic_require("NetworkManager")

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end


function SocietyPrivateerGameMode_C:OnAllStepFinished()
    log("SocietyPrivateerGameMode_C:OnAllStepFinished")

    SendPacket(Proto.c2s_LeaveLocalDungeon)

    SocietyPrivateerGameMode_C.super.OnAllStepFinished()
end

return SocietyPrivateerGameMode_C
