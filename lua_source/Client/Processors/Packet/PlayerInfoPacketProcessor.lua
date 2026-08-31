-----------------------------------------------------
--File Name    : PlayerInfoPacketProcessor.lua
--Author       : WuJizhou
--Create Time  : 3/21/2019, 5:03:20 PM
--Description  : PlayerInfoPacketProcessor
-----------------------------------------------------
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local PlayerInfoPacketProcessor = luaclass("PlayerInfoPacketProcessor", NetMessageProcessorBase)

local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local PlayerInfoSystem = require("PlayerInfoSystem")


local function OnPlayerSummariesReceived(self, tbPacket, nSenderId)
    PlayerInfoSystem:OnPlayerSummariesReceived(tbPacket.summaries)
end

local function OnNotifyPlayerSummaryChanged(self, tbPacket, nSenderId)
    PlayerInfoSystem:OnPlayerSummaryChangeNotified(tbPacket.summary)
end

local function RegisterPackets(self)
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    self:SetBinder(HubServerProxy)
    self:BindMethod(Proto.s2c_PlayerSummaries, self, OnPlayerSummariesReceived)
    self:BindMethod(Proto.s2c_NotifyPlayerSummaryChange, self, OnNotifyPlayerSummaryChanged)
end

--------base api from NetMessageProcessorBase--------
function PlayerInfoPacketProcessor:Init()
    self.super.Init(self)
    RegisterPackets(self)
    return true
end

-- function PlayerInfoPacketProcessor:Uninit()
--     self.super.Uninit(self)

return PlayerInfoPacketProcessor