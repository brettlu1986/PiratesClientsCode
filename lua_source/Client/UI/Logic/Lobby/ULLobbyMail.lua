-----------------------------------------------------
--File Name    : ULLobbyMail.lua
--Author       : WuJizhou
--Create Time  : 3/18/2019, 2:43:34 PM
--Description  : ULLobbyMail
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyMail = luaclass("ULLobbyMail", UILogicBase)


local MailSystem = require("MailSystem")
local ClientEventDef = require("ClientEventDef")
-- local Timer = require("Timer")


local function SetRedDotVisible(self, bVisible)
    self.pWidgetRef.btnMail:HideTipIcon(not bVisible)
end

local function OnNewMailNotified(self)
    SetRedDotVisible(self, MailSystem:HasUnreadMail())
end


local function OnMailSynced(self)
    SetRedDotVisible(self, MailSystem:HasUnreadMail())
end

local function OnMailRead(self)
    SetRedDotVisible(self, MailSystem:HasUnreadMail())
end

local function OnMailAttachmentGet(self)
    SetRedDotVisible(self, MailSystem:HasUnreadMail())
end

local function SyncMails()
    if not MailSystem:HasSynced() then
        MailSystem:RequestToSyncMails()
    end
end

function ULLobbyMail:OnShow()
    if MailSystem:HasSynced() then
        SetRedDotVisible(self, MailSystem:HasUnreadMail())
    else
        SyncMails() -- 暂时不加延时，测试服务端的问题
        -- Timer.StartOwnerTimer(self, "SyncMailTimer", SyncMails, 2, false)
    end
end

function ULLobbyMail:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_NEW_MAIL_NOTIFY_RECEIVED, self, OnNewMailNotified)
    EventHelper:RegisterEvent(ClientEventDef.EV_ALL_MAILS_RECEIVED, self, OnMailSynced)
    EventHelper:RegisterEvent(ClientEventDef.EV_MARK_MAIL_READ_RECEIVED, self, OnMailRead)
    EventHelper:RegisterEvent(ClientEventDef.EV_MAIL_ATTACHMENT_GOT_RECEIVED, self, OnMailAttachmentGet)
end


return ULLobbyMail