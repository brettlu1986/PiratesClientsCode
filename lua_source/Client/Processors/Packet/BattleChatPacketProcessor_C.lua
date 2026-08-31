-----------------------------------------------------
--File Name    : BattleChatPacketProcessor_C.lua
--Author       : Edward J
--Create Time  : 2019-03-19
--Description  : Chat system processor client
-----------------------------------------------------
local luaclass                    = require("luaclass")
local BattleChatPacketProcessor   = require("BattleChatPacketProcessor")
local BattleChatPacketProcessor_C = luaclass("BattleChatPacketProcessor_C",BattleChatPacketProcessor)

local ProtoD               = require("DungeonCommonProtoNames")
local BattleChatSystem     = dynamic_require("BattleChatSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-----------------------------------------------------

local function OnRecieveTeamPacket(self, tbPacket)
    local nInstanceId = tbPacket.instance_id
    local szContend = tbPacket.content
    local BattleTeamComponent = GamePlayerSelfHelper:Get().BattleTeamComponent
    local tbMemberInfo = BattleTeamComponent:GetMemberInfo(nInstanceId)
    if not tbMemberInfo then
        return
    end
    local szSenderName = tbMemberInfo.name
    local nSoundId = tbPacket.sound_id
    BattleChatSystem:OnRecieveTeamMsg(szSenderName, szContend, nSoundId)
end

local function OnRecieveChatRoomMemberId(self, tbPacket)
    local nInstanceId = tbPacket.instance_id
    local nMemberId = tbPacket.member_Id
    BattleChatSystem:OnRecieveVoiceRoomMemberId(nInstanceId, nMemberId)
end

local function OnRecievePointLocation(self, tbPacket)
    local nInstanceId = tbPacket.instance_id
    local pos = Vector()
    pos.X = tbPacket.posX
    pos.Y = tbPacket.posY
    pos.Z = tbPacket.posZ
    local pointType = tbPacket.point_type
    BattleChatSystem:OnRecievePointLocation(nInstanceId, pos, pointType)
end

function BattleChatPacketProcessor_C:RegisterPackets()
    self:BindMethod(ProtoD.d2c_Chat, self, OnRecieveTeamPacket)
    self:BindMethod(ProtoD.d2c_ChatRoomMemberId, self, OnRecieveChatRoomMemberId)
    self:BindMethod(ProtoD.d2c_PointLocation, self, OnRecievePointLocation)
end

return BattleChatPacketProcessor_C