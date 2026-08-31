-----------------------------------------------------
local luaclass                  = require("luaclass")
local NetMessageProcessorBase   = require("NetMessageProcessorBase")
local GameCoreWatchPacketProcessor = luaclass("GameCoreWatchPacketProcessor", NetMessageProcessorBase)

local Proto            = require("DungeonCommonProtoNames")
local NetworkManager   = dynamic_require("NetworkManager")
local GameCoreWatchSystem = dynamic_require("GameCoreWatchSystem")
-----------------------------------------------------


local function ToggleBotByIndex(self, tbPacket, nSenderUniqueId)
    GameCoreWatchSystem:WatchBotByIndex(nSenderUniqueId, tbPacket.nBotIndex)
end

local function ToggleBotById(self, tbPacket, nSenderUniqueId)
    GameCoreWatchSystem:WatchBotById(nSenderUniqueId, tbPacket.nBotInstanceId)
end

function GameCoreWatchPacketProcessor:Init()
    GameCoreWatchPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

function GameCoreWatchPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.c2d_ToggleBotByIndex, self, ToggleBotByIndex)
    self:BindMethod(Proto.c2d_ToggleBotById, self, ToggleBotById)
end

return GameCoreWatchPacketProcessor