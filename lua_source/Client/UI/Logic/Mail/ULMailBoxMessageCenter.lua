-----------------------------------------------------
--File Name    : ULMailBoxMessageCenter.lua
--Author       : WuJizhou
--Create Time  : 3/11/2019, 2:43:34 PM
--Description  : ULMailBoxMessageCenter
-----------------------------------------------------
local luaclass = require("luaclass")
local ULMailBoxBase = require("ULMailBoxBase")
local ULMailBoxMessageCenter = luaclass("ULMailBoxMessageCenter", ULMailBoxBase)

local MailSystem = require("MailSystem")
local ClientEventDef = require("ClientEventDef")
local MailMiscDefine = require("MailMiscDefine")
local MailParameterMaker = require("MailParameterMaker")

local MailboxType = MailMiscDefine.MailboxType
local MailType = MailMiscDefine.MailType

ULMailBoxMessageCenter.tbInvitorInfos = nil

local function SyncFriendState(self)
    local tbMails = self.ULMailCommon:GetMails(self:GetMailBoxType())
    local tbInvitorIds = {}
    for _, tbMail in ipairs(tbMails) do
        local nMailType = MailSystem:GetMailType(tbMail)
        if nMailType == MailType.TYPE_TEAM_INVITATION then
            local nPlayerId = MailParameterMaker:GetMailParamsByKey(tbMail, MailSystem.MAIL_PARAM_KEY_PLAYER_ID)
            table.insert(tbInvitorIds, nPlayerId)
        end
    end
    if #tbInvitorIds > 0 then
        MailSystem:RequestToGetInvitorInfo(tbInvitorIds)
    end
end

local function OnInvitorInfoSynced(self, tbInvitorInfos)
    local tbInvitorMap = {}
    for _, tbInvitor in ipairs(tbInvitorInfos) do
        local nPlayerId = tbInvitor.player_id
        tbInvitorMap[nPlayerId] = tbInvitor
    end

    local tbMails = self:GetMails()
    for _, tbMail in ipairs(tbMails) do
        local nMailType = MailSystem:GetMailType(tbMail)
        if nMailType == MailType.TYPE_TEAM_INVITATION then
            local nPlayerId = MailParameterMaker:GetMailParamsByKey(tbMail, MailSystem.MAIL_PARAM_KEY_PLAYER_ID)
            local tbInvitor = tbInvitorMap[nPlayerId]
            if tbInvitor then
                tbMail.nStatus = tbInvitor.status
                tbMail.nTeamSize = tbInvitor.team_size
                tbMail.bSameTeam = tbInvitor.is_same_team
            end
        end
    end
    self.Owner.ListHelper:SetData(tbMails)
end

local function RefreshContent(self)
    local tbMails = self:GetMails()
    local nCount = #tbMails
    if nCount > 0 then
        self.Owner.ListHelper:SetData(tbMails)
        self.pWidgetRef.bdrFriend:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.pWidgetRef.bdrNoting:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.hboxOperate:SetVisibility(ESlateVisibility.Visible)
        SyncFriendState(self)
    else
        self.pWidgetRef.bdrNoting:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.pWidgetRef.bdrFriend:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.hboxOperate:SetVisibility(ESlateVisibility.Collapsed)
    end

end

local function OnTeamChanged(self)
    RefreshContent(self)
end

function ULMailBoxMessageCenter:Activate()
    if self.bActivate then
        return
    end
    local tbMails = self:GetMails()
    RefreshContent(self)
    self.ULMailCommon.nCurrentMailBoxCategory = self:GetMailBoxType()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_INVITOR_INFO_RECEIVED, self, OnInvitorInfoSynced)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED, self, OnTeamChanged)
    self.ULMailCommon:MarkAllMailsRead(true)
    self:RefreshMailBasicInfo(#tbMails)

    self.bActivate = true
end

function ULMailBoxMessageCenter:Deactivate()
    if not self.bActivate then
        return
    end
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_INVITOR_INFO_RECEIVED)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_TEAM_CHANGED)
    self.Owner.ListHelper:SetData(nil)
    self.bActivate = false
end

function ULMailBoxMessageCenter:GetMailBoxType()
    return MailboxType.MAIL_MESSAGE_CENTER
end

return ULMailBoxMessageCenter