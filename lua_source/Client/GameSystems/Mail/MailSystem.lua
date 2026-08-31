-----------------------------------------------------
--File Name    : MailSystem.lua
--Author       : WuJizhou
--Create Time  : 3/11/2019, 8:55:58 PM
--Description  : MailSystem
-----------------------------------------------------
local Proto = require("ClientProtoNames")
local ClientEventDef = require("ClientEventDef")
local MailTemplateDataTable = require("MailTemplateDataTable")
local NetworkManager = dynamic_require("NetworkManager")
local EventManager = require("EventManager")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local MailMiscDefine = require("MailMiscDefine")

local MailSystem = {}


MailSystem.PlayerStatus = Proto.PlayerStatus

MailSystem.MAIL_PARAM_KEY_PLAYER_ID = "player_id"
MailSystem.MAIL_PARAM_KEY_PLAYER_NAME = "player_name"
MailSystem.MAIL_PARAM_KEY_PLAYER_AVATAR_ID = "player_avatar_id"
MailSystem.MAIL_PARAM_KEY_PLAYER_LEVEL = "player_level"
MailSystem.MAIL_PARAM_KEY_ITEM_DESC = "item_desc"
MailSystem.MAIL_PARAM_KEY_ITEM_COUNT = "item_count"
MailSystem.MAIL_PARAM_KEY_ITEM_TEMPLATE_ID = "item_template_id"

--k : MailboxType, v : Mail list
MailSystem.tbBoxTypeToMails = {}

--k : mail id , v : Mail
MailSystem.tbIdToMails = {}

MailSystem.tbIdToBoxType = {}

MailSystem.nLastestMailSendTime = 0

MailSystem.bHasNewMail = false

MailSystem.bHasSynced = false

MailSystem.bNeedSyncAll = false

-- {int value : string value}
MailSystem.tbMailTypeVToKMap = {}

MailSystem.tbMailBoxAttris = {}


local MailType = MailMiscDefine.MailType
local BOX_ATTRI_KEY = MailMiscDefine.BOX_ATTRI_KEY


local function ConstructMailTypeVToKMap(self)
    for k, v in pairs(MailType) do
        self.tbMailTypeVToKMap[v] = k
    end
end

function MailSystem:GetMailTemplate(nType, nSubTemplateType)
    return MailTemplateDataTable:GetTemplate(nType, nSubTemplateType)
end

function MailSystem:CanMailBeDeleted(tbMail)
    if not tbMail.read then
        return false
    end
    if #(tbMail.attachments) > 0 then
        return tbMail.claimed
    else
        return true
    end
end

function MailSystem:GetMailType(tbMail)
    return tbMail.type
end

function MailSystem:GetMailDisplayType(tbMail)
    local tbTemplate = self:GetMailTemplate(tbMail.type)
    return tbTemplate.nMailDisplayType
end

function MailSystem:GetMailAttachmentMaxCount()
    return 5 --当前ui上的控件就是5，如果将来有需要需要改成list
end

function MailSystem:GetMailBoxCapacity(nBoxType)
    local tbAttri = self.tbMailBoxAttris[nBoxType]
    if not tbAttri then
        logerror("MailSystem, GetMailBoxCapacity, has no attri info, nBoxType is ", nBoxType)
        return 0
    else
        return tbAttri[BOX_ATTRI_KEY.LIMIT]
    end
end

function MailSystem:HasUnreadMail()
    if self.bHasNewMail then
        return true
    end
    for k, v in pairs(self.tbIdToMails) do
        if not v.read then
            return true
        end
    end
    return false
end

function MailSystem:HasSynced()
    return self.bHasSynced
end

function MailSystem:GetMailParams(tbMail)
    local tbParams = nil
    local nMailType = tbMail.type
    local szUpperKey = self.tbMailTypeVToKMap[nMailType]
    if not szUpperKey then
        logerror("MailSystem:GetMailParams error, the mail type does not exist, value is ", nMailType)
        return tbParams
    end
    local szLowerKey = string.lower(szUpperKey)
    local nIdx = string.find(szLowerKey, "_")
    szLowerKey = string.sub(szLowerKey, nIdx + 1)
    tbParams = tbMail.params[szLowerKey]
    return tbParams
end

------------api call back for packet received------------
function MailSystem:OnAllMailsReceived(tbBoxes, tbBoxAttris)
    local tbIdToMails = self.tbIdToMails

    for _, tbBox in ipairs(tbBoxes) do
        local nBoxType = tbBox.boxType
        local tbMails = tbBox.mails
        if tbMails then
            for _, tbMail in ipairs(tbMails) do
                local nId = tbMail.id
                if not tbIdToMails[nId] then
                    local tbSubLsit = self.tbBoxTypeToMails[nBoxType]
                    if not tbSubLsit then
                        tbSubLsit = {}
                        self.tbBoxTypeToMails[nBoxType] = tbSubLsit
                    end
                    table.insert(tbSubLsit, tbMail)
                    tbIdToMails[nId] = tbMail
                    self.tbIdToBoxType[nId] = nBoxType
                    if tbMail.send_time > self.nLastestMailSendTime then
                        self.nLastestMailSendTime = tbMail.send_time
                    end
                end
            end
        end
    end

    if tbBoxAttris then
        for _, tbBoxAttri in ipairs(tbBoxAttris) do
            local nBoxType = tbBoxAttri.boxType
            local tbAttri = self.tbMailBoxAttris[nBoxType]
            if not tbAttri then
                tbAttri = {}
                self.tbMailBoxAttris[nBoxType] = tbAttri
            end
            tbAttri[BOX_ATTRI_KEY.LIMIT] = tbBoxAttri.limit
        end
    end

    self.bHasSynced = false
    self.bHasNewMail = false
    self.bNeedSyncAll = false
    EventManager:OnFireEvent(ClientEventDef.EV_ALL_MAILS_RECEIVED)
end

function MailSystem:OnNewMailNotifyReceived()
    self.bHasNewMail = true
    EventManager:OnFireEvent(ClientEventDef.EV_NEW_MAIL_NOTIFY_RECEIVED)
end

function MailSystem:OnInvitorInfoReceived(tbInvitorInfos)
    EventManager:OnFireEvent(ClientEventDef.EV_INVITOR_INFO_RECEIVED, tbInvitorInfos)
end

function MailSystem:OnMailMarkedRead(tbMailIds)
    local tbIdToMails = self.tbIdToMails
    for _, nId in ipairs(tbMailIds) do
        local tbMail = tbIdToMails[nId]
        if tbMail then
            tbMail.read = true
        end
    end
    EventManager:OnFireEvent(ClientEventDef.EV_MARK_MAIL_READ_RECEIVED)
end

function MailSystem:OnMailDeleted(tbMailIds, nReason)
    if nReason == Proto.s2c_DeleteMail_DeleteMailReason.USER then
        local tbIdToMails = self.tbIdToMails
        local tbIdToBoxType = self.tbIdToBoxType
        for _, nId in ipairs(tbMailIds) do
            local tbMail = tbIdToMails[nId]
            if tbMail then
                tbIdToMails[nId] = nil
                tbIdToBoxType[nId] = nil
            end
        end

        local tbBoxTypeToMails = {}
        for nId, tbMail in pairs(tbIdToMails) do
            local nBoxType = self.tbIdToBoxType[nId]
            local tbSubLsit = tbBoxTypeToMails[nBoxType]
            if not tbSubLsit then
                tbSubLsit = {}
                tbBoxTypeToMails[nBoxType] = tbSubLsit
            end
            table.insert(tbSubLsit, tbMail)
        end
        self.tbBoxTypeToMails = tbBoxTypeToMails
        EventManager:OnFireEvent(ClientEventDef.EV_NEW_MAIL_DELETE_RECEIVED)
    else
        self.bNeedSyncAll = true
    end
end

function MailSystem:OnMailAttachmentGot(nMailId)
    local tbIdToMails = self.tbIdToMails
    local tbMail = tbIdToMails[nMailId]
    if tbMail then
        tbMail.read = true
        tbMail.claimed = true
    end
    EventManager:OnFireEvent(ClientEventDef.EV_MAIL_ATTACHMENT_GOT_RECEIVED, nMailId)
end

function MailSystem:OnMailNotExist()
    self.bNeedSyncAll = true
    self.nLastestMailSendTime = 0
    UIUtils.ShowToast(UITextDef.MAIL_DATA_ERROR)
end

------------------------------------------------

------------api local function------------
function MailSystem:GetMailData(nBoxType)
    local tbRet = self.tbBoxTypeToMails[nBoxType]
    if not tbRet then
        tbRet = {}
        self.tbBoxTypeToMails[nBoxType] = tbRet
    end
    return tbRet
end
------------------------------------------------

------------api request to server------------
function MailSystem:RequestToSyncMails()
    local c2s_PlayerMails = {}
    if not self:HasSynced() then
        self.tbBoxTypeToMails = {}
        self.tbIdToMails = {}
        self.tbIdToBoxType = {}
        c2s_PlayerMails.last_send_time = 0
        c2s_PlayerMails.include_limit = true
    else
        c2s_PlayerMails.last_send_time = self.nLastestMailSendTime
    end
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_PlayerMails, c2s_PlayerMails)
end

function MailSystem:RequestToMarkMailRead(tbMailIdList)
    local c2s_MarkMailAsRead = {}
    c2s_MarkMailAsRead.mail_ids = tbMailIdList
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_MarkMailAsRead, c2s_MarkMailAsRead)
end

function MailSystem:RequestToDeleteMail(tbMailIdList)
    local c2s_DeleteMail = {}
    c2s_DeleteMail.mail_ids = tbMailIdList
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_DeleteMail, c2s_DeleteMail)
end

function MailSystem:RequestToGetMailAttachment(nMailId)
    local c2s_ClaimMailAttachments = {}
    c2s_ClaimMailAttachments.mail_id = nMailId
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ClaimMailAttachments, c2s_ClaimMailAttachments)
end

function MailSystem:RequestToGetInvitorInfo(tbPlayerIds)
    local c2s_getInvitorInfo = {}
    c2s_getInvitorInfo.player_id = tbPlayerIds
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_getInvitorInfo, c2s_getInvitorInfo)
end

function MailSystem:RequestToEnableReceiveInviteMail(tbPlayerIdList)
    local c2s_EnableReceiveInviteMail = {}
    c2s_EnableReceiveInviteMail.player_ids = tbPlayerIdList
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_EnableReceiveInviteMail, c2s_EnableReceiveInviteMail)
end

------------------------------------------------

function MailSystem:Init()
    self.tbBoxTypeToMails = {}
    self.tbIdToMails = {}
    self.tbIdToBoxType = {}
    self.bHasSynced = false
    self.bHasNewMail = false
    self.nLastestMailSendTime = 0
    ConstructMailTypeVToKMap(self)
    return true
end

function MailSystem:Uninit()
    self.bHasSynced = false
    self.bHasNewMail = false
    self.tbBoxTypeToMails = {}
    self.tbIdToMails = {}
    self.tbIdToBoxType = {}
    self.tbMailTypeVToKMap = {}
    self.nLastestMailSendTime = 0
end

return MailSystem