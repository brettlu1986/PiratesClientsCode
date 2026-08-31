-----------------------------------------------------
--File Name    : LobbyChatPacketProcessor.lua
--Author       : Edward J
--Create Time  : 2019-04-01
--Description  : lobby Chat system processor
-----------------------------------------------------
local luaclass                 = require("luaclass")
local NetMessageProcessorBase  = require("NetMessageProcessorBase")
local LobbyChatPacketProcessor = luaclass("LobbyChatPacketProcessor", NetMessageProcessorBase)

local Proto                = require("ClientProtoNames")
local NetworkManager       = dynamic_require("NetworkManager")
local LobbyChatSystem      = require("LobbyChatSystem")
-----------------------------------------------------

local function OnRecievePacket(self, tbPacket, nSenderUniqueId)
    local eChannel = tbPacket.channel
    local nSenderId = tbPacket.sender_id
    local szSenderName = tbPacket.sender_name
    local szMsg = tbPacket.content
    local nSendTime = tbPacket.send_time
    local nFlags = tbPacket.flags
    LobbyChatSystem:OnRecieveMsg(eChannel, nSenderId, szSenderName, szMsg, nSendTime, nFlags)
end

local function OnRecieveErrorPacket(self, tbPacket, nSenderUniqueId)
    local returnCode = tbPacket.return_code
    local eChatChannel = tbPacket.channel
    local nRemainTime = tbPacket.remaining_cooldown_seconds
    LobbyChatSystem:OnRecieveErrorCode(returnCode, eChatChannel, nRemainTime)
end

local function OnRecieveLoopMsgGm(self, tbPacket, nSenderUniqueId)
    local tbLoopStrategy = tbPacket.strategy
    local szContent = tbPacket.content
    local nLoopCount = tbLoopStrategy.count
    local nInterval = tbLoopStrategy.interval_seconds
    local nPriority = tbLoopStrategy.priority
    LobbyChatSystem:SendToSystem(LobbyChatSystem.NOTIFY_TEXT, nLoopCount, nInterval, nPriority, szContent)
end

local function OnRecieveLoopMsgItem(self, tbPacket, nSenderUniqueId)
    local tbLoopStrategy = tbPacket.strategy
    local szPlayerName = tbPacket.player_name
    local Items = tbPacket.items
    local nLoopCount = tbLoopStrategy.count
    local nInterval = tbLoopStrategy.interval_seconds
    local nPriority = tbLoopStrategy.priority
    local tbItems = {}
    for i,v in ipairs(Items) do
        local nItemTemplateId = v.item_template_id
        local nItemCount = v.item_count
        LobbyChatSystem:CreateSystemItemsTab(tbItems, nItemTemplateId, nItemCount)
    end
    LobbyChatSystem:SendToSystem(LobbyChatSystem.SPECIAL_ITEM, nLoopCount, nInterval, nPriority, tbItems, szPlayerName)
end

local function OnRecieveRecruitTeammate(self, tbPacket, nSenderUniqueId)
    local nSenderId = tbPacket.player_id
    local szName = tbPacket.name
    local nMembers = tbPacket.member_count
    local nDungeonId = tbPacket.dungeon_id
    local tbChannel = {}
    local Channels = tbPacket.channel
    for i,v in ipairs(Channels) do
        table.insert(tbChannel, v)
    end
    local nTeamMode = tbPacket.team_mode
    LobbyChatSystem:OnRecieveTeamInvite(nSenderId, szName, nMembers, tbChannel, nDungeonId, nTeamMode)
end

local function OnRecieveBanChat(self, tbPacket, nSenderUniqueId)
    local tbBannedInfo = tbPacket["info"]
    local nSinceStamp = tbBannedInfo["since"]
    local nUntilStamp = tbBannedInfo["until"]
    local szReason = tbBannedInfo["reason"]
    LobbyChatSystem:OnRecieveBanChat(nSinceStamp, nUntilStamp, szReason)
end

local function OnRecieveUnbanChat(self, tbPacket, nSenderUniqueId)
    LobbyChatSystem:OnRecieveUnbanChat()
end

function LobbyChatPacketProcessor:Init()
    LobbyChatPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

function LobbyChatPacketProcessor:Uninit()
    LobbyChatPacketProcessor.super.Uninit(self)
end

function LobbyChatPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_Chat, self, OnRecievePacket)
    self:BindMethod(Proto.s2c_ChatError, self, OnRecieveErrorPacket)
    self:BindMethod(Proto.s2c_LoopMsgGM, self, OnRecieveLoopMsgGm)
    self:BindMethod(Proto.s2c_LoopMsgItem, self, OnRecieveLoopMsgItem)
    self:BindMethod(Proto.s2c_NotifyRecruitTeammate, self, OnRecieveRecruitTeammate)
    self:BindMethod(Proto.s2c_BanChat, self, OnRecieveBanChat)
    self:BindMethod(Proto.s2c_UnbanChat, self, OnRecieveUnbanChat)
end

return LobbyChatPacketProcessor()