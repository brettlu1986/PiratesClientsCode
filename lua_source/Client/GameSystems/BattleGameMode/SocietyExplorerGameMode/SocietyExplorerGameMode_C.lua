local luaclass = require("luaclass")

local SocietyExplorerGameModeClass = require("SocietyExplorerGameMode")
local SocietyExplorerGameMode_C = luaclass("SocietyExplorerGameMode_C", SocietyExplorerGameModeClass)

local Proto = require("ClientProtoNames")

local NetworkManager = dynamic_require("NetworkManager")

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end

function SocietyExplorerGameMode_C:OnAllStepFinished()
    log("SocietyExplorerGameMode_C:OnAllStepFinished")

    SendPacket(Proto.c2s_LeaveLocalDungeon)

    SocietyExplorerGameMode_C.super.OnAllStepFinished()
end

return SocietyExplorerGameMode_C
