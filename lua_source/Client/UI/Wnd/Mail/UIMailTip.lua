-----------------------------------------------------
--File Name    : UIMailTip.lua
--Author       : WuJizhou
--Create Time  : 3/11/2019, 3:02:59 PM
--Description  : UIMailTip
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIMailTip = luaclass("UIMailTip", WndBase)

local MailSystem = require("MailSystem")
local MailMiscDefine = require("MailMiscDefine")
local UITextDef = require("UITextDef")
local UIDef = require("UIDef")
local L10N = require("L10N")
local MailParameterMaker = require("MailParameterMaker")

local MailDisplayType = MailMiscDefine.MailDisplayType

UIMailTip.pbDialogFrame = nil
UIMailTip.tbAttachmentPrefabs = nil
UIMailTip.tbAttachmentGetImages = nil


--删除邮件
local function DeleteMail(tbMail)
    local tbList = {}
    table.insert(tbList, tbMail.id)
    MailSystem:RequestToDeleteMail(tbList)
end

--领取赠品
local function GetAttachment(tbMail)
    MailSystem:RequestToGetMailAttachment(tbMail.id)
end

local function ShowTitleAndContent(self, tbMail, tbTemplate)
    self.pbDialogFrame:SetTitle(tbTemplate.l10nTipTitle)
    local tbNames, tbArgs = MailParameterMaker:MakeTwoListParams(tbMail)
    local l10nTitle = L10N:FormatByName(tbTemplate.l10nTitle, tbNames, tbArgs)
    self.pWidgetRef.ktxtTitle:SetText(l10nTitle)
    local l10nContent = L10N:FormatByName(tbTemplate.l10nContent, tbNames, tbArgs)
    self.pWidgetRef.ktxtContent:SetText(l10nContent)
end

local function ShowAttachment(self, tbMail, tbTemplate)
    self.pWidgetRef.txtStaticAttachment:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.pWidgetRef.ovlAttachment:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local tbAttachments = tbMail.attachments
    local nMaxCount = MailSystem:GetMailAttachmentMaxCount()
    local VisibleState = tbMail.claimed and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed
    for idx = 1, nMaxCount do
        local tbAttachment = tbAttachments[idx]
        if tbAttachment then
            local nTemplateId = tbAttachment.item_template_id
            local nCount = tbAttachment.count
            self.tbAttachmentPrefabs[idx]:SetDisplayItemData(nTemplateId, nCount, true)
            self.tbAttachmentPrefabs[idx]:SetVisible(true)
            self.pWidgetRef["imgAttachmentGot"..idx]:SetVisibility(VisibleState)
        else
            self.tbAttachmentPrefabs[idx]:SetVisible(false)
            self.pWidgetRef["imgAttachmentGot"..idx]:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

local function HideAttachment(self)
    self.pWidgetRef.txtStaticAttachment:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.ovlAttachment:SetVisibility(ESlateVisibility.Collapsed)
end

local fnShowTextMail = function (self, tbMail, tbTemplate)
    ShowTitleAndContent(self, tbMail, tbTemplate)
    HideAttachment(self)
    self.pbDialogFrame:SetNegativeButtonCallback(
        function ()
            DeleteMail(tbMail)
        end
    )
    self.pbDialogFrame:SetPositiveButtonVisible(false)
    self.pbDialogFrame:SetNegativeButtonVisible(true)
end

local fnShowInviteMail = function  (self, tbMail, tbTemplate)
    logerror("UIMailTip, invite mail should not be opened to this view")
end

local fnShowAttachmentMail = function (self, tbMail, tbTemplate)
    ShowTitleAndContent(self, tbMail, tbTemplate)
    ShowAttachment(self, tbMail, tbTemplate)
    if not tbMail.claimed then
        self.pbDialogFrame:SetPositiveButtonCallback(
            function ()
                GetAttachment(tbMail)
            end
        )
        self.pbDialogFrame:SetPositiveText(UITextDef.MAIL_GET_ATTACHMENT)
        self.pbDialogFrame:SetPositiveButtonVisible(true)
        self.pbDialogFrame:SetNegativeButtonVisible(false)
    else
        self.pbDialogFrame:SetNegativeButtonCallback(
            function ()
                DeleteMail(tbMail)
            end
        )
        self.pbDialogFrame:SetPositiveButtonVisible(false)
        self.pbDialogFrame:SetNegativeButtonVisible(true)
    end
end



local fnShowItemExpiredMail = function (self, tbMail, tbTemplate)
    self.pbDialogFrame:SetTitle(tbTemplate.l10nTipTitle)
    local tbNames, tbArgs = MailParameterMaker:MakeTwoListParams(tbMail)
    local l10nTitle = L10N:FormatByName(tbTemplate.l10nTitle, tbNames, tbArgs)
    self.pWidgetRef.ktxtTitle:SetText(l10nTitle)
    local l10nContent = L10N:FormatByName(tbTemplate.l10nContent, tbNames, tbArgs)
    self.pWidgetRef.ktxtContent:SetText(l10nContent)
    HideAttachment(self)
    self.pbDialogFrame:SetNegativeButtonCallback(
        function ()
            DeleteMail(tbMail)
        end
    )
    self.pbDialogFrame:SetPositiveButtonVisible(false)
    self.pbDialogFrame:SetNegativeButtonVisible(true)
end

local fnShowCommonMail = function (self, tbMail, tbTemplate)
    if #(tbMail.attachments) > 0 then
        fnShowAttachmentMail( self, tbMail, tbTemplate)
    else
        fnShowTextMail(self, tbMail, tbTemplate)
    end
end

local fnShowNoParamTitleNoAttachMail = function(self, tbMail, tbTemplate)
    self.pbDialogFrame:SetTitle(tbTemplate.l10nTitle)
    self.pWidgetRef.ktxtTitle:SetText(tbTemplate.l10nTitle)

    local tbNames, tbArgs = MailParameterMaker:MakeTwoListParams(tbMail)
    local l10nContent = L10N:FormatByName(tbTemplate.l10nContent, tbNames, tbArgs)

    self.pWidgetRef.ktxtContent:SetText(l10nContent)
    HideAttachment(self)
    self.pbDialogFrame:SetNegativeButtonCallback(
        function ()
            DeleteMail(tbMail)
        end
    )
    self.pbDialogFrame:SetPositiveButtonVisible(false)
    self.pbDialogFrame:SetNegativeButtonVisible(true)
end

local fnShowGetIntimacy = function(self, tbMail, tbTemplate)
    fnShowNoParamTitleNoAttachMail(self, tbMail, tbTemplate)
end

local fnShowGetFriendGift = function(self, tbMail, tbTemplate)
    fnShowCommonMail( self, tbMail, tbTemplate)
end

local fnShowRelationChanged = function(self, tbMail, tbTemplate)
    fnShowNoParamTitleNoAttachMail(self, tbMail, tbTemplate)
end

local fnShowRelationLevelUp = function(self, tbMail, tbTemplate)
    fnShowNoParamTitleNoAttachMail(self, tbMail, tbTemplate)
end

local tbMailShowFunctions = {}
tbMailShowFunctions[MailDisplayType.Common] = fnShowCommonMail
tbMailShowFunctions[MailDisplayType.Invite] = fnShowInviteMail
tbMailShowFunctions[MailDisplayType.ItemExpired] = fnShowItemExpiredMail
tbMailShowFunctions[MailDisplayType.GetIntimacy] = fnShowGetIntimacy
tbMailShowFunctions[MailDisplayType.FriendGift] = fnShowGetFriendGift
tbMailShowFunctions[MailDisplayType.RelationChange] = fnShowRelationChanged
tbMailShowFunctions[MailDisplayType.RelationLevelUp] = fnShowRelationLevelUp

----------life cycle----------

-- function UIMailTip:OnCreate()
-- end

function UIMailTip:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.pbDialogFrame = self.PrefabHelper:BindPrefab(pWidgetRef.pbDialogFrame, UIDef.UP_DIALOG_FRAME)
    self.pbDialogFrame:SetDialogClosedCallback(function () self:CloseSelf() end)
    local nAttachmentMaxCount = MailSystem:GetMailAttachmentMaxCount()
    local tbAttachmentPbs = {}
    for i = 1, nAttachmentMaxCount do
        local pb = self.PrefabHelper:BindPrefab(pWidgetRef["pbLobbyItem"..i], UIDef.UP_LOBBY_DISPLAY_ITEM)
        table.insert(tbAttachmentPbs, pb)
    end
    self.tbAttachmentPrefabs = tbAttachmentPbs
end

function UIMailTip:OnEnter()
    self.pbDialogFrame:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Forward, 1)
    local tbOpenArgs = self.tbOpenArgs
    local tbMail = tbOpenArgs.tbMail

    local tbTemplate = MailSystem:GetMailTemplate(tbMail.type)
    local nDisplayType = tbTemplate.nMailDisplayType
    local fnShow = tbMailShowFunctions[nDisplayType]

    if not fnShow then
        logerror("UIMailTip, fnShow does not have defination, the nMailType is ", tbTemplate.nMailType)
    else
        fnShow(self, tbMail, tbTemplate)
    end
end

return UIMailTip