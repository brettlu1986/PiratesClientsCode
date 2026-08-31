-----------------------------------------------------
--File Name    : PlayerBasicInfoPacketProcessor.lua
--Author       : WuJizhou
--Create Time  : 3/21/2019, 5:03:20 PM
--Description  : PlayerBasicInfoPacketProcessor
-----------------------------------------------------
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local PlayerBasicInfoPacketProcessor = luaclass("PlayerBasicInfoPacketProcessor", NetMessageProcessorBase)

local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local PlayerBasicInfoSystem = require("PlayerBasicInfoSystem")
local ChannelSDKSystem  = require("ChannelSDKSystem")

local function OnExpSynced(self, tbPacket, nSenderId)
    local nExp = tbPacket.exp
    PlayerBasicInfoSystem:OnExpSynced(nExp)
end

local function OnLevelUp(self, tbPacket, nSenderId)
    local nNewLevel = tbPacket.new_level
    local nNewExp = tbPacket.new_exp
    PlayerBasicInfoSystem:OnLevelUp(nNewLevel, nNewExp)
    ChannelSDKSystem:TrackLevel_Five(nNewLevel)
end

local function OnNameChanged(self, tbPacket, nSenderId)
    PlayerBasicInfoSystem:OnNameChange(tbPacket.new_name)
end

local function RegisterPackets(self)
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    self:SetBinder(HubServerProxy)
    self:BindMethod(Proto.s2c_SyncExp, self, OnExpSynced)
    self:BindMethod(Proto.s2c_LevelUp, self, OnLevelUp)
    self:BindMethod(Proto.s2c_NameChanged, self, OnNameChanged)

end

--------base api from NetMessageProcessorBase--------
function PlayerBasicInfoPacketProcessor:Init()
    self.super.Init(self)
    RegisterPackets(self)
    return true
end

-- function PlayerBasicInfoPacketProcessor:Uninit()
--     self.super.Uninit(self)

return PlayerBasicInfoPacketProcessor