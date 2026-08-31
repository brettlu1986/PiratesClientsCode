local luaclass = require("luaclass")
local GameCoreWatchPacketProcessor   = require("GameCoreWatchPacketProcessor")
local GameCoreWatchPacketProcessor_C = luaclass("GameCoreWatchPacketProcessor_C", GameCoreWatchPacketProcessor)
local Proto = require("DungeonCommonProtoNames")
local GameCoreWatchSystem = dynamic_require("GameCoreWatchSystem")

local NetworkManager = dynamic_require("NetworkManager")

-- 注册处理包
function GameCoreWatchPacketProcessor_C:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    self:BindMethod(Proto.d2c_GameCoreAIBotStatus, self, self.OnSyncWatchedBot)
    self:BindMethod(Proto.d2c_GameCoreTeammates, self, self.OnSyncBotTeamInfo)
    self:BindMethod(Proto.d2c_ToggleBotResult, self, self.ToggleBotResult)
    
end

function GameCoreWatchPacketProcessor_C:ToggleBotResult(tbPacket, nSenderUniqueId)
    GameCoreWatchSystem:TryChangeToWatchBot(tbPacket.nBotInstanceId, tbPacket.nVehicleInstanceId)
end

function GameCoreWatchPacketProcessor_C:OnSyncWatchedBot(tbPacket, nSenderUniqueId)
    GameCoreWatchSystem:SyncBot(tbPacket)
end

function GameCoreWatchPacketProcessor_C:OnSyncBotTeamInfo(tbPacket, nSenderUniqueId)
    GameCoreWatchSystem:SyncBotTeamInfo(tbPacket)
end


return GameCoreWatchPacketProcessor_C