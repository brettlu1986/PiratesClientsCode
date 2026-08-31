-----------------------------------------------------
--File Name    : UPMailListItem.lua
--Author       : WuJizhou
--Create Time  : 3/11/2019, 3:00:41 PM
--Description  : UPMailListItem
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")

local UPMailListItem = luaclass("UPMailListItem", ListItemBase)

local MailSystem = require("MailSystem")
local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local UIDef = require("UIDef")
local UITextDef = require("UITextDef")
local UIManager = require("UIManager")
local TeamSystem = require("TeamSystem")
local AvatarDataTable = require("AvatarDataTable")
local HumanDataTable = require("HumanDataTable")
local GenderTypeDefine = require("GenderTypeDefine")
local MailParameterMaker = require("MailParameterMaker")
local MailMiscDefine = require("MailMiscDefine")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local TEMPLATE_PARAM_KEY = MailMiscDefine.TEMPLATE_PARAM_KEY
local PlayerStatus = MailSystem.PlayerStatus
local MAX_TEAM_MEMBER_COUNT = 4
UPMailListItem.tbMail = nil
UPMailListItem.nPlayerId = nil
UPMailListItem.pbPlayerHead = nil


local MailType = MailMiscDefine.MailType
local MailDisplayType = MailMiscDefine.MailDisplayType

-- local PATTERN = "{(.-)}"
local SECONDS_PER_MINUTE = 60
local MINUTES_PER_HOUR = 60
local HOURS_PER_DAY = 24
local SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR
local SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY


-- return string
local function FormatSendTime(nCurTime, nSendTime)
    local nTime = nCurTime - nSendTime
    nTime = nTime > 0 and nTime or 0
    if nTime < SECONDS_PER_MINUTE then -- xxx秒前
        return L10N:Format(UITextDef.MAIL_TIME_SECONDS_AGO, nTime)
    end
    if nTime < SECONDS_PER_HOUR then -- xxx分钟前
        local nMinute = nTime // SECONDS_PER_MINUTE
        return L10N:Format(UITextDef.MAIL_TIME_MINUTES_AGO, nMinute)
    end
    if nTime < SECONDS_PER_DAY then -- xxx小时前
        local nHour = nTime // SECONDS_PER_HOUR
        return L10N:Format(UITextDef.MAIL_TIME_HOURS_AGO, nHour)
    end
    -- xxx 天前
    local nDay = nTime // SECONDS_PER_DAY
    return L10N:Format(UITextDef.MAIL_TIME_DAYS_AGO, nDay)
end

-- return string
local function FormatRemainingTime(nCurTime, nTTL)
    local nRemainingTime = nTTL - nCurTime
    if nRemainingTime <= 0 then -- 已过期
        return UITextDef.MAIL_OUT_OF_DATE
    end
    if nRemainingTime < SECONDS_PER_MINUTE then -- 剩余xxx秒
        return L10N:Format(UITextDef.MAIL_TIME_SECONDS_REMAINING, nRemainingTime)
    end
    if nRemainingTime < SECONDS_PER_HOUR then -- 剩余xxx分钟
        local nMinute = nRemainingTime // SECONDS_PER_MINUTE
        return L10N:Format(UITextDef.MAIL_TIME_MINUTES_REMAINING, nMinute)
    end
    if nRemainingTime < SECONDS_PER_DAY then -- 剩余xxx小时
        local nHour = nRemainingTime // SECONDS_PER_HOUR
        return L10N:Format(UITextDef.MAIL_TIME_HOURS_REMAINING, nHour)
    end
    -- 剩余xxx天
    local nDay = nRemainingTime // SECONDS_PER_DAY
    return L10N:Format(UITextDef.MAIL_TIME_DAYS_REMAINING, nDay)
end


local fnShowTextMail = function (self, tbMail, tbTemplate)
    local Collapsed = ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvp1:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.cvp2:SetVisibility(Collapsed)
    --阅读状态
    local szReadImg = tbMail.read and UIResourceDef.MAIL_READ_ICON or UIResourceDef.MAIL_UNREAD_ICON
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRead, szReadImg:load())

    local tbNames, tbArgs = MailParameterMaker:MakeTwoListParams(tbMail)
    local l10nTitle = L10N:FormatByName(tbTemplate.l10nTitle, tbNames, tbArgs)
    --设置title
    pWidgetRef.vbFriendSend:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.richTextTitle:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.richTextTitle:SetText(l10nTitle)
    --隐藏附件
    pWidgetRef.btnAttachment:SetVisibility(Collapsed)
    pWidgetRef.txtAttachmentCount:SetVisibility(ESlateVisibility.Collapsed)
    --设置剩余时间
    local nExpiredTime = tbMail.ttl
    local nCurTime = GlobalVariableSystem:GetServerTimeUtc()
    pWidgetRef.txtRemainingTime:SetText(FormatRemainingTime(nCurTime, nExpiredTime))
    pWidgetRef.txtSendTime:SetVisibility(Collapsed)
end

local fnShowAttachmentMail = function (self, tbMail, tbTemplate)
    local Collapsed = ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvp1:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.cvp2:SetVisibility(Collapsed)
    --阅读状态
    local szReadImg = tbMail.read and UIResourceDef.MAIL_READ_ICON or UIResourceDef.MAIL_UNREAD_ICON
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRead, szReadImg:load())
    --设置title
    local tbNames, tbArgs = MailParameterMaker:MakeTwoListParams(tbMail)
    local l10nTitle = L10N:FormatByName(tbTemplate.l10nTitle, tbNames, tbArgs)
    pWidgetRef.vbFriendSend:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.richTextTitle:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.richTextTitle:SetText(l10nTitle)
    local nCount = #(tbMail.attachments)
    --设置附件
    if tbMail.claimed then
        pWidgetRef.btnAttachment:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtAttachmentCount:SetVisibility(ESlateVisibility.Collapsed)

    else
        pWidgetRef.btnAttachment:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtAttachmentCount:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtAttachmentCount:SetText(" x ".. nCount)
        UISetUtils.SetButtonBrushRes(pWidgetRef.btnAttachment, UIResourceDef.MAIL_ATTACHMENT_ICON:load())
    end

    --设置剩余时间
    local nExpiredTime = tbMail.ttl
    local nCurTime = GlobalVariableSystem:GetServerTimeUtc()
    pWidgetRef.txtRemainingTime:SetText(FormatRemainingTime(nCurTime, nExpiredTime))
    pWidgetRef.txtSendTime:SetVisibility(Collapsed)
end

local fnShowCommonMail = function (self, tbMail, tbTemplate)
    if #(tbMail.attachments) > 0 then
        fnShowAttachmentMail( self, tbMail, tbTemplate)
    else
        fnShowTextMail(self, tbMail, tbTemplate)
    end
end

local fnShowInviteMail = function (self, tbMail, tbTemplate)
    local Collapsed = ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvp1:SetVisibility(Collapsed)
    pWidgetRef.cvp2:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local tbParams = MailParameterMaker:MakeTableParams(tbMail)
    -- 设置名字
    local szName = tbParams[TEMPLATE_PARAM_KEY.PLAYER_NAME]
    pWidgetRef.txtFriendName:SetText(szName)
    local nPlayerAvatarId = tbParams[TEMPLATE_PARAM_KEY.AVATAR_ID]
    -- 设置playerId
    self.nPlayerId = tbParams[TEMPLATE_PARAM_KEY.PLAYER_ID]
    -- 设置templateId
    self.pbPlayerHead:SetPlayerHead(nPlayerAvatarId, tbParams[TEMPLATE_PARAM_KEY.LEVEL])
    self.pbPlayerHead:SetPlayerId(tbParams[TEMPLATE_PARAM_KEY.PLAYER_ID])

    -- 设置性别符号
    local nHumanId = AvatarDataTable:GetHumanId(nPlayerAvatarId)
    local nGender = HumanDataTable:GetTemplate(nHumanId).nGender
    local szGenderIcon
    if nGender == GenderTypeDefine.MALE then
        szGenderIcon = UIResourceDef.GENDER_MALE
    else
        szGenderIcon = UIResourceDef.GENDER_FEMALE
    end
    UISetUtils.SetImageBrushRes(pWidgetRef.imgGender, szGenderIcon:load(), true)
    -- 设置title
    local tbNames, tbArgs = MailParameterMaker:MakeTwoListParams(tbMail)
    local l10nTitle = L10N:FormatByName(tbTemplate.l10nTitle, tbNames, tbArgs)
    pWidgetRef.richTxtFriendTitle:SetText(l10nTitle)
    --设置好友状态
    pWidgetRef.vboxInvite:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local nStatus = tbMail.nStatus
    local nTeamSize = tbMail.nTeamSize
    local bSameTeam = tbMail.bSameTeam
    if nStatus == PlayerStatus.IDLE then
        if nTeamSize == 0 then
            --空闲且team_size为0，显示空闲+邀请组队
            pWidgetRef.txtFriendState:SetText(UITextDef.MAIL_FRIEND_STATE_IDLE)
            pWidgetRef.txtBtnTeam:SetText(UITextDef.MAIL_TEAM_INVITE)
            pWidgetRef.kmbtnUse:SetVisibility(ESlateVisibility.Visible)
        else
            local l10nState = L10N:Format(UITextDef.MAIL_FRIEND_STATE_IN_TEAM, nTeamSize)
            pWidgetRef.txtFriendState:SetText(l10nState)
            if bSameTeam then --是否同队 确定是否显示按钮
                pWidgetRef.kmbtnUse:SetVisibility(ESlateVisibility.Collapsed)
            else
                if nTeamSize < MAX_TEAM_MEMBER_COUNT then
                    pWidgetRef.kmbtnUse:SetVisibility(ESlateVisibility.Visible)
                    pWidgetRef.txtBtnTeam:SetText(UITextDef.MAIL_TEAM_JOIN)
                else
                    pWidgetRef.kmbtnUse:SetVisibility(ESlateVisibility.Collapsed)
                end
            end
        end
    elseif nStatus == PlayerStatus.MATCHMAKING or nStatus == PlayerStatus.BATTLING then
        pWidgetRef.kmbtnUse:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtFriendState:SetText(UITextDef.MAIL_FRIEND_STATE_PLAYING)
    else --离线
        pWidgetRef.kmbtnUse:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtFriendState:SetText(UITextDef.MAIL_FRIEND_STATE_OFFLINE)
    end

    --设置发送时间
    local nSendTime = tbMail.send_time
    local nCurTime = GlobalVariableSystem:GetLocalTime()
    pWidgetRef.txtFriendSendTime:SetText(FormatSendTime(nCurTime, nSendTime))
    --隐藏附件
    pWidgetRef.btnFriendAttachment:SetVisibility(Collapsed)
end

local fnShowTextMailNoParam = function(self, tbMail, tbTemplate)
    local Collapsed = ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvp1:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.cvp2:SetVisibility(Collapsed)
    --阅读状态
    local szReadImg = tbMail.read and UIResourceDef.MAIL_READ_ICON or UIResourceDef.MAIL_UNREAD_ICON
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRead, szReadImg:load())
    -- --设置title
    -- pWidgetRef.vbFriendSend:SetVisibility(ESlateVisibility.Collapsed)
    -- pWidgetRef.richTextTitle:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    -- pWidgetRef.richTextTitle:SetText(tbTemplate.l10nTitle)
    --隐藏附件
    pWidgetRef.btnAttachment:SetVisibility(Collapsed)
    pWidgetRef.txtAttachmentCount:SetVisibility(ESlateVisibility.Collapsed)
    --设置剩余时间
    local nExpiredTime = tbMail.ttl
    local nCurTime = GlobalVariableSystem:GetServerTimeUtc()
    pWidgetRef.txtRemainingTime:SetText(FormatRemainingTime(nCurTime, nExpiredTime))
    pWidgetRef.txtSendTime:SetVisibility(Collapsed)
end

local fnShowGetIntimacy = function (self, tbMail, tbTemplate)
    local Collapsed = ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvp1:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.cvp2:SetVisibility(Collapsed)
    --阅读状态
    local szReadImg = tbMail.read and UIResourceDef.MAIL_READ_ICON or UIResourceDef.MAIL_UNREAD_ICON
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRead, szReadImg:load())
    --设置title
    
    pWidgetRef.vbFriendSend:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.richTextTitle:SetVisibility(ESlateVisibility.Collapsed)
    if tbMail.params and tbMail.params.use_friendship_card then
        pWidgetRef.txtSendName:SetText(tbMail.params.use_friendship_card.player_name)
    end
    pWidgetRef.txtSendTextTitle:SetText(tbTemplate.l10nTitle)
    --隐藏附件
    pWidgetRef.btnAttachment:SetVisibility(Collapsed)
    pWidgetRef.txtAttachmentCount:SetVisibility(ESlateVisibility.Collapsed)
    --设置剩余时间
    local nExpiredTime = tbMail.ttl
    local nCurTime = GlobalVariableSystem:GetServerTimeUtc()
    pWidgetRef.txtRemainingTime:SetText(FormatRemainingTime(nCurTime, nExpiredTime))
    pWidgetRef.txtSendTime:SetVisibility(Collapsed)
end

local fnShowGetFriendGift = function(self, tbMail, tbTemplate)
    local Collapsed = ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvp1:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.cvp2:SetVisibility(Collapsed)
    --阅读状态
    local szReadImg = tbMail.read and UIResourceDef.MAIL_READ_ICON or UIResourceDef.MAIL_UNREAD_ICON
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRead, szReadImg:load())
    --设置title
    pWidgetRef.vbFriendSend:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.richTextTitle:SetVisibility(ESlateVisibility.Collapsed)
    if tbMail.params and tbMail.params.send_friend_gift then
        pWidgetRef.txtSendName:SetText(tbMail.params.send_friend_gift.player_name)
    end
    pWidgetRef.txtSendTextTitle:SetText(tbTemplate.l10nTitle)
    local nCount = #(tbMail.attachments)
    --设置附件
    if tbMail.claimed then
        pWidgetRef.btnAttachment:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtAttachmentCount:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.btnAttachment:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtAttachmentCount:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtAttachmentCount:SetText(" x ".. nCount)
        UISetUtils.SetButtonBrushRes(pWidgetRef.btnAttachment, UIResourceDef.MAIL_ATTACHMENT_ICON:load())
    end

    --设置剩余时间
    local nExpiredTime = tbMail.ttl
    local nCurTime = GlobalVariableSystem:GetServerTimeUtc()
    pWidgetRef.txtRemainingTime:SetText(FormatRemainingTime(nCurTime, nExpiredTime))
    pWidgetRef.txtSendTime:SetVisibility(Collapsed)
end

local fnShowRelationChange = function(self, tbMail, tbTemplate)
    fnShowTextMailNoParam(self, tbMail, tbTemplate)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.vbFriendSend:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.richTextTitle:SetVisibility(ESlateVisibility.Collapsed)
    if tbMail.params and tbMail.params.friend_relationship then
        pWidgetRef.txtSendName:SetText(tbMail.params.friend_relationship.player_name)
    end
    pWidgetRef.txtSendTextTitle:SetText(tbTemplate.l10nTitle)
end

local fnShowRelationLevelUp = function(self, tbMail, tbTemplate)
    fnShowTextMailNoParam(self, tbMail, tbTemplate)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.vbFriendSend:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.richTextTitle:SetVisibility(ESlateVisibility.Collapsed)
    if tbMail.params and tbMail.params.friend_relationship_level then
        pWidgetRef.txtSendName:SetText(tbMail.params.friend_relationship_level.player_name)
    end
    pWidgetRef.txtSendTextTitle:SetText(tbTemplate.l10nTitle)
end

local tbMailShowFunctions = {}
tbMailShowFunctions[MailDisplayType.Common] = fnShowCommonMail
tbMailShowFunctions[MailDisplayType.Invite] = fnShowInviteMail
tbMailShowFunctions[MailDisplayType.ItemExpired] = fnShowCommonMail
tbMailShowFunctions[MailDisplayType.GetIntimacy] = fnShowGetIntimacy
tbMailShowFunctions[MailDisplayType.FriendGift] = fnShowGetFriendGift
tbMailShowFunctions[MailDisplayType.RelationChange] = fnShowRelationChange
tbMailShowFunctions[MailDisplayType.RelationLevelUp] = fnShowRelationLevelUp


local function OnClicked(self)
    local nMailType = MailSystem:GetMailType(self.tbMail)
    if nMailType == MailType.TYPE_TEAM_INVITATION then
        return
    end
    if not self.tbMail.read then
        MailSystem:RequestToMarkMailRead({self.tbMail.id})
    end
    UIManager:OpenWnd(UIDef.UI_MAIL_TIP, {tbMail = self.tbMail})
end


local function OnFriendBtnClicked(self)
    local tbMail = self.tbMail
    local nMailType = MailSystem:GetMailType(tbMail)
    if nMailType ~= MailType.TYPE_TEAM_INVITATION then
        logerror("UPMailListItem OnFriendBtnClicked, type illegal", nMailType)
        return
    end
    local nStatus = tbMail.nStatus
    local nTeamSize = tbMail.nTeamSize
    local bSameTeam = tbMail.bSameTeam
    if nStatus ~= PlayerStatus.IDLE then
        logerror("UPMailListItem OnFriendBtnClicked, status illegal", nStatus)
        return
    end
    local nPlayerId = MailParameterMaker:GetMailParamsByKey(tbMail, MailSystem.MAIL_PARAM_KEY_PLAYER_ID)
    if not nPlayerId then
        logerror("UPMailListItem, invite friend error, player_id is nil, the mail id is ", tbMail.id)
        return
    end
    if nTeamSize == 0 then
        TeamSystem:RequestInvitePlayer(nPlayerId)
    else
        if not bSameTeam and nTeamSize < MAX_TEAM_MEMBER_COUNT then --是否同队 确定是否显示按钮
            TeamSystem:RequestApplyJoin(nPlayerId)
        end
    end
end

function UPMailListItem:OnRefresh(tbMail)
    if not tbMail then
        return
    end
    self.tbMail = tbMail
    local tbTemplate = MailSystem:GetMailTemplate(tbMail.type)
    local nDisplayType = tbTemplate.nMailDisplayType
    local fnShow = tbMailShowFunctions[nDisplayType]
    if fnShow then
        fnShow(self, tbMail, tbTemplate)
    else
        logerror("UPMailListItem, OnRefresh, ShowFunction not defined")
    end

end


----------life cycle----------

function UPMailListItem:OnLoad()
    self.pbPlayerHead = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayHead, UIDef.UP_PLAYHEAD )
end

function UPMailListItem:OnBindEvent( EventHelper )
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSelect.OnClicked, self, OnClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.kmbtnUse.OnClicked, self, OnFriendBtnClicked)
end

return UPMailListItem