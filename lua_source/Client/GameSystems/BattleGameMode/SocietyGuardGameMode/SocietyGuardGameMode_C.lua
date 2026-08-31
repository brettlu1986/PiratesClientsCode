local luaclass = require("luaclass")

local SocietyGuardGameModeClass = require("SocietyGuardGameMode")
local SocietyGuardGameMode_C = luaclass("SocietyGuardGameMode_C", SocietyGuardGameModeClass)
local Proto = require("ClientProtoNames")

local NetworkManager = dynamic_require("NetworkManager")
local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end

function SocietyGuardGameMode_C:OnAllStepFinished()
    log("SocietyGuardGameMode_C:OnAllStepFinished")
    SendPacket(Proto.c2s_LeaveLocalDungeon)
    SocietyGuardGameMode_C.super.OnAllStepFinished(self)
end

return SocietyGuardGameMode_C
