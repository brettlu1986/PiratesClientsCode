-----------------------------------------------------
--File Name    : ULMailCommon.lua
--Author       : WuJizhou
--Create Time  : 3/11/2019, 2:43:34 PM
--Description  : ULMailCommon
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULMailCommon = luaclass("ULMailCommon", UILogicBase)


local ClientEventDef = require("ClientEventDef")
local MailSystem = require("MailSystem")
local MailMiscDefine = require("MailMiscDefine")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local MailParameterMaker = require("MailParameterMaker")

local MailType = MailMiscDefine.MailType
local MailboxType = MailMiscDefine.MailboxType

--比较已读状态
local ReadStateComparator = function(tbMail1, tbMail2)
    local bRead1 = tbMail1.read
    local bRead2 = tbMail2.read
    if bRead1 and not bRead2 then
        return -1
    elseif bRead2 and not bRead1 then
        return 1
    else
        return 0
    end
end
--比较领取状态
local GetStateComparator = function(tbMail1, tbMail2)
    local bClaimed1 = tbMail1.claimed
    local bClaimed2 = tbMail2.claimed
    if bClaimed1 and not bClaimed2 then
        return -1
    elseif bClaimed2 and not bClaimed1 then
        return 1
    else
        return 0
    end
end
--比较发送时间
local SendTimeComparator = function(tbMail1, tbMail2)
    local nSendTime1 = tbMail1.send_time
    local nSendTime2 = tbMail2.send_time
    if nSendTime1 > nSendTime2 then
        return 1
    elseif nSendTime1 < nSendTime2 then
        return -1
    else
        return 0
    end
end

local tbComparators = {}
tbComparators[1] = ReadStateComparator
tbComparators[2] = GetStateComparator
tbComparators[3] = SendTimeComparator

local fnMailCompare = function (tbMail1, tbMail2)
    for _, fnComparator in ipairs(tbComparators) do
        local nRet = fnComparator(tbMail1, tbMail2)
        if nRet > 0 then
            return true
        elseif nRet < 0 then
            return false
        end
    end
    return false
end

local function OnAllMailsReceived(self)
    if self.OnMailSynced then
        self.OnMailSynced()
    else
        logerror("ULMailCommon, OnMailSynced is nil ")
    end
end

local function OnMailAttachmentGet(self)
    if self.OnMailAttachmentGet then
        self.OnMailAttachmentGet()
    else
        logerror("ULMailCommon, OnMailAttachmentGet is nil ")
    end
end

local function OnMailMarked(self)
    if self.OnMailMarked then
        self.OnMailMarked()
    else
        logerror("ULMailCommon, OnMailMarked is nil ")
    end
end

local function OnMailDeleted(self)
    if self.OnMailDeleted then
        self.OnMailDeleted()
    else
        logerror("ULMailCommon, OnMailDeleted is nil ")
    end
end


local function RequestToEnableReceiveInviteMail(tbMails)
    local tbList = {}
    for _, tbMail in ipairs(tbMails) do
        local nMailType = MailSystem:GetMailType(tbMail)
        if nMailType == MailType.TYPE_TEAM_INVITATION then
            local nPlayerId = MailParameterMaker:GetMailParamsByKey(tbMail, MailSystem.MAIL_PARAM_KEY_PLAYER_ID)
            if nPlayerId then
                table.insert( tbList, nPlayerId )
            end
        end
    end
    if #tbList > 0 then
        MailSystem:RequestToEnableReceiveInviteMail(tbList)
    end
end

ULMailCommon.OnMailAttachmentGet = nil
ULMailCommon.OnMailSynced = nil
ULMailCommon.OnMailMarked = nil
ULMailCommon.OnMailDeleted = nil
ULMailCommon.nCurrentMailBoxCategory = MailboxType.MAIL_SYSTEM
ULMailCommon.tbMails = {}

function ULMailCommon:GetMailCompareFn()
    return fnMailCompare
end

function ULMailCommon:GetUnreadMailCount(nMailBoxType)
    local tbDatas = MailSystem:GetMailData(nMailBoxType)
    local nRet = 0
    for _, v in ipairs(tbDatas) do
        if not v.read then
            nRet = nRet + 1
        end
    end
    return nRet
end

function ULMailCommon:GetMails(nMailBoxType)
    return MailSystem:GetMailData(nMailBoxType)
end

function ULMailCommon:HasUngotAttachment(nMailBoxType)
    local bResult = false
    local tbMails = MailSystem:GetMailData(nMailBoxType)
    for _, tbMail in ipairs(tbMails) do
        if #tbMail.attachments > 0 and not tbMail.claimed then
            bResult = true
            break
        end
    end
    return bResult
end

function ULMailCommon:RequestToSyncMails()
    MailSystem:RequestToSyncMails()
end

function ULMailCommon:MarkAllMailsRead(bNotToast)
    local nMailBoxCategory = self.nCurrentMailBoxCategory
    local tbMails = MailSystem:GetMailData(nMailBoxCategory)
    local tbToBeReadList = {}
    for _, tbMail in ipairs(tbMails) do
        if not tbMail.read then
            table.insert(tbToBeReadList, tbMail.id)
        end
    end
    if #tbToBeReadList > 0 then
        MailSystem:RequestToMarkMailRead(tbToBeReadList)
    else
        if not bNotToast then
            UIUtils.ShowToast(UITextDef.MAIL_NO_MAIL_TO_READ)
        end
    end
end

function ULMailCommon:DeleteAllMails()
    local nMailBoxCategory = self.nCurrentMailBoxCategory
    local tbMails = MailSystem:GetMailData(nMailBoxCategory)
    local tbToBeDeleteList = {}
    for _, tbMail in ipairs(tbMails) do
        local bCanDeleted = MailSystem:CanMailBeDeleted(tbMail)
        if bCanDeleted then
            table.insert(tbToBeDeleteList, tbMail.id)
        end
    end
    if #tbToBeDeleteList > 0 then
        MailSystem:RequestToDeleteMail(tbToBeDeleteList)
        RequestToEnableReceiveInviteMail(tbMails)
    else
        UIUtils.ShowToast(UITextDef.MAIL_NO_MAIL_TO_DELETE)
    end
end

function ULMailCommon:GetAllMailAttachmentsAndGiveBack()
    --todo @WuJizhou 现在没有回赠接口
end

function ULMailCommon:GetAllMailAttachments()
    local nMailBoxCategory = self.nCurrentMailBoxCategory
    -- if nMailBoxCategory == MailboxType.MAIL_FRIEND then
    --     self:GetAllMailAttachmentsAndGiveBack()
    -- else
        local tbMails = MailSystem:GetMailData(nMailBoxCategory)
        local bFlag = false
        for _, tbMail in ipairs(tbMails) do
            if #tbMail.attachments > 0 and not tbMail.claimed then
                MailSystem:RequestToGetMailAttachment(tbMail.id)
                bFlag = true
            end
        end
        if not bFlag then
            UIUtils.ShowToast(UITextDef.MAIL_NO_MAIL_ATTACHMENT_TO_GET)
        end
    -- end
end

function ULMailCommon:SetOnMailSyncedCallback(fnCallback)
    self.OnMailSynced = fnCallback
end

function ULMailCommon:SetOnMailMarkedCallback(fnCallback)
    self.OnMailMarked = fnCallback
end

function ULMailCommon:SetOnMailDeletedCallback(fnCallback)
    self.OnMailDeleted = fnCallback
end

function ULMailCommon:SetOnMailAttachmentGetCallback(fnCallback)
    self.OnMailAttachmentGet = fnCallback
end

----------life cycle----------

function ULMailCommon:OnEnter()
    self.pWidgetRef.bdrNoting:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.pWidgetRef.bdrFriend:SetVisibility(ESlateVisibility.Collapsed)
    self:RequestToSyncMails()
end

function ULMailCommon:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ALL_MAILS_RECEIVED, self, OnAllMailsReceived)
    EventHelper:RegisterEvent(ClientEventDef.EV_MARK_MAIL_READ_RECEIVED, self, OnMailMarked)
    EventHelper:RegisterEvent(ClientEventDef.EV_NEW_MAIL_DELETE_RECEIVED, self, OnMailDeleted)
    EventHelper:RegisterEvent(ClientEventDef.EV_MAIL_ATTACHMENT_GOT_RECEIVED, self, OnMailAttachmentGet)
end

return ULMailCommon