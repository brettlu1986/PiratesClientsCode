-----------------------------------------------------
--File Name    : BattleChatPacketProcessor.lua
--Author       : Edward J
--Create Time  : 2019-03-19
--Description  : Chat system processor battle server
-----------------------------------------------------
local luaclass                  = require("luaclass")
local NetMessageProcessorBase   = require("NetMessageProcessorBase")
local BattleChatPacketProcessor = luaclass("BattleChatPacketProcessor", NetMessageProcessorBase)

local Proto            = require("DungeonCommonProtoNames")
local NetworkManager   = dynamic_require("NetworkManager")
local BattleChatSystem = dynamic_require("BattleChatSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
-----------------------------------------------------

local function UniqueIdToInstanceId(nSenderUniqueId)
    local tbSender = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    return tbSender
end

local function OnRecievePacket(self, tbPacket, nSenderUniqueId)
    local tbSender = UniqueIdToInstanceId(nSenderUniqueId)
    BattleChatSystem:RouteMsgToTeamMembers(tbSender, tbPacket.content, tbPacket.sound_id)
end

local function OnRecieveChatRoomMemberId(self, tbPacket, nSenderUniqueId)
    local tbSender = UniqueIdToInstanceId(nSenderUniqueId)
    local nInstanceId = tbPacket.instance_id
    local nMemberId = tbPacket.member_Id
    BattleChatSystem:RouteVoiceRoomMemberIdToTeamMembers(tbSender, nInstanceId, nMemberId)
end

local function OnRecievePointLocation(self, tbPacket, nSenderUniqueId)
    local tbSender = UniqueIdToInstanceId(nSenderUniqueId)
    local pos = {}
    pos.X = tbPacket.posX
    pos.Y = tbPacket.posY
    pos.Z = tbPacket.posZ
    local pointType = tbPacket.point_type
    BattleChatSystem:RoutePointLocationToTeamMembers(tbSender, pos, pointType)
end

function BattleChatPacketProcessor:Init()
    BattleChatPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

function BattleChatPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.c2d_Chat, self, OnRecievePacket)
    self:BindMethod(Proto.c2d_ChatRoomMemberId, self, OnRecieveChatRoomMemberId)
    self:BindMethod(Proto.c2d_PointLocation, self, OnRecievePointLocation)
end

return BattleChatPacketProcessor