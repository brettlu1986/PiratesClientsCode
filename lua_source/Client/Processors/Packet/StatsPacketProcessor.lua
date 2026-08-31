local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local StatsPacketProcessor = luaclass("StatsPacketProcessor", NetMessageProcessorBase)
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local StatsSystem = require("StatsSystem")

local function OnRecvGetHistoryStats(self, tbPacket)
    StatsSystem:OnRecvGetHistoryStats(tbPacket)
end

local function OnRecvGetHistoryStatsDetail(self, tbPacket)
    StatsSystem:OnRecvGetHistoryStatsDetail(tbPacket)
end

-- 注册处理包
function StatsPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_GetHistoryStats, self, OnRecvGetHistoryStats)
    self:BindMethod(Proto.s2c_GetHistoryStatsDetail, self, OnRecvGetHistoryStatsDetail)
    
end

function StatsPacketProcessor:Init()
    StatsPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()

    return true
end

-- 结束
function StatsPacketProcessor:Uninit()
    StatsPacketProcessor.super.Uninit(self)
end

return StatsPacketProcessor
