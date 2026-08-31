-----------------------------------------------------
--File Name    : MailPacketProcessor.lua
--Author       : WuJizhou
--Create Time  : 3/11/2019, 5:03:20 PM
--Description  : MailPacketProcessor
-----------------------------------------------------
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local MailPacketProcessor = luaclass("MailPacketProcessor", NetMessageProcessorBase)

local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local MailSystem = require("MailSystem")

local ReturnCode = Proto.ReturnCode

local function OnMailRetError(ErrorCode)
    if ErrorCode == ReturnCode.MAIL_NOT_EXIST or ErrorCode == ReturnCode.MAIL_OUT_OF_DATE then
        MailSystem:OnMailNotExist()
    end
    -- elseif ErrorCode == ReturnCode.MAIL_NOT_CLAIMED then
    -- elseif ErrorCode == ReturnCode.MAIL_NOT_READ then
    -- elseif ErrorCode == ReturnCode.MAIL_READ then
    -- elseif ErrorCode == ReturnCode.MAIL_NOT_HAS_ATTACHMENT then
    -- else
    -- end
end

local function OnAllMailsReceived(self, tbPacket, nSenderId)
    local nRetCode = tbPacket.return_code
    if nRetCode == ReturnCode.OK then
        MailSystem:OnAllMailsReceived(tbPacket.mailboxes, tbPacket.limits)
    else
        OnMailRetError(nRetCode)
    end
end

local function OnNewMailNotifyReceived(self, tbPacket, nSenderId)
    MailSystem:OnNewMailNotifyReceived()
end

local function OnMailMarkedRead(self, tbPacket, nSenderId)
    local nRetCode = tbPacket.return_code
    if nRetCode == ReturnCode.OK then
        local tbMailIds = tbPacket.mail_ids
        MailSystem:OnMailMarkedRead(tbMailIds)
    else
        OnMailRetError(nRetCode)
    end
end

local function OnMailDeleted(self, tbPacket, nSenderId)
    local nRetCode = tbPacket.return_code
    if nRetCode == ReturnCode.OK then
        local tbMailIds = tbPacket.mail_ids
        local nReason = tbPacket.reason
        MailSystem:OnMailDeleted(tbMailIds, nReason)
    else
        OnMailRetError(nRetCode)
    end
end

local function OnMailAttachmentGot(self, tbPacket, nSenderId)
    local nRetCode = tbPacket.return_code
    if nRetCode == ReturnCode.OK then
        local nMailId = tbPacket.mail_id
        MailSystem:OnMailAttachmentGot(nMailId)
    else
        OnMailRetError(nRetCode)
    end
end

local function OnInvitorInfoReceived(self, tbPacket, nSenderId)
    MailSystem:OnInvitorInfoReceived(tbPacket.invitor)
end

local function RegisterPackets(self)
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    self:SetBinder(HubServerProxy)
    self:BindMethod(Proto.s2c_PlayerMails, self, OnAllMailsReceived)
    self:BindMethod(Proto.s2c_NewMailNotify, self, OnNewMailNotifyReceived)
    self:BindMethod(Proto.s2c_MarkMailAsRead, self, OnMailMarkedRead)
    self:BindMethod(Proto.s2c_DeleteMail, self, OnMailDeleted)
    self:BindMethod(Proto.s2c_ClaimMailAttachments, self, OnMailAttachmentGot)
    self:BindMethod(Proto.s2c_getInvitorInfo, self, OnInvitorInfoReceived)
end

--------base api from NetMessageProcessorBase--------
function MailPacketProcessor:Init()
    self.super.Init(self)
    RegisterPackets(self)
    return true
end

-- function MailPacketProcessor:Uninit()
--     self.super.Uninit(self)

return MailPacketProcessor