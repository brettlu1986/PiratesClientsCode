-----------------------------------------------------
--File Name    : UPLobbyChatQuickView.lua
--Author       : Edward J
--Create Time  : 2019-04-04
--Description  : lobby Chat Quick View
-----------------------------------------------------
local luaclass              = require("luaclass")
local PrefabBase            = require("PrefabBase")
local UPLobbyChatQuickView  = luaclass("UPLobbyChatQuickView", PrefabBase)

local ClientEventDef            = require("ClientEventDef")
local LobbyChatSystem           = require("LobbyChatSystem")
local SelfVerticalListHelper    = require("SelfVerticalListHelper")
local TeamChatDataTable         = require("TeamChatDataTable")
local TeamSystem                = require("TeamSystem")
local UITextDef                 = require("UITextDef")
local L10N                      = require("L10N")
local EventManager              = require("EventManager")
local UIUtils                   = require("UIUtils")
local UISetUtils                = require("UISetUtils")
local UIDef                     = require("UIDef")
-----------------------------------------------------
local Visible               = ESlateVisibility.Visible
local Collapsed             = ESlateVisibility.Collapsed
local VOICEMSGTEMPLATE      = UITextDef.LOBBYCHAT_VOICEMSGTEMPLATE
local TEAMINGMSGTEMPLATE    = UITextDef.LOBBYCHAT_TEAMINGMSGTEMPLATE
local TEXTMSGTEMPLATE       = UITextDef.LOBBYCHAT_TEXTMSGTEMPLATE
local CHAT_FRIEND           = LobbyChatSystem.CHAT_FRIEND
local CHAT_TEAM             = LobbyChatSystem.CHAT_TEAM
local CHAT_SYSTEM           = LobbyChatSystem.CHAT_SYSTEM
local ChannelText           = 
{
    [LobbyChatSystem.CHAT_FRIEND]       = UITextDef.LOBBYCHAT_FRIEND_CHANNEL,
    [LobbyChatSystem.CHAT_WORLD]        = UITextDef.LOBBYCHAT_WORLD_CHANNEL,    
    [LobbyChatSystem.CHAT_TEAM]         = UITextDef.LOBBYCHAT_TEAM_CHANNEL,     
    [LobbyChatSystem.CHAT_ROOM]         = UITextDef.LOBBYCHAT_ROOM_CHANNEL,     
    [LobbyChatSystem.CHAT_CORPS]        = UITextDef.LOBBYCHAT_CORPS_CHANNEL,
    [LobbyChatSystem.CHAT_SYSTEM]       = UITextDef.LOBBYCHAT_SYSTEM
}

local TeamingText =
{
    ["2"] = UITextDef.LOBBYCHAT_TEAMINGMODE_TOW,
    ["4"] = UITextDef.LOBBYCHAT_TEAMINGMODE_CLASSIC
}

UPLobbyChatQuickView.pTxtMsg            = nil
UPLobbyChatQuickView.pQuickChatList     = nil
UPLobbyChatQuickView.ListHelper         = nil
UPLobbyChatQuickView.bShowList          = false
UPLobbyChatQuickView.eCurrentChannel    = nil
UPLobbyChatQuickView.nSenderId          = nil
UPLobbyChatQuickView.bUPChatActivate    = nil
-----------------------------------------------------

local function InitQuickChatList(self)
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.listQuickChat)
    local nAllCount = TeamChatDataTable:GetAllCount()
    local tbMsgs = {}
    for i = 1, nAllCount do
        local tbTemplate = TeamChatDataTable:GetTemplate(i)
        tbMsgs[i] = L10N:ToString(tbTemplate.l10nMsg)
    end
    local ListHelper = self.ListHelper
    ListHelper:SetData(tbMsgs)
    ListHelper:ScrollToTop(false)
end

local function ShowList(self)
    self.pListBorder:SetVisibility(Visible)
    self.bShowList = true
end

local function HideList(self)
    self.pListBorder:SetVisibility(Collapsed)
    self.bShowList = false
end

local function ToggelShowList(self)
    if self.bShowList then
        HideList(self)
    else
        ShowList(self)
    end
end

local function GetChannelTypeText( eChannel)
    local l10nText = ChannelText[eChannel]
    return l10nText
end

local function CreateTextMsg(szChannel, szName, tbMsgData)
    local szMsg = tbMsgData[2]
    local l10NTextMsg = L10N:Format(TEXTMSGTEMPLATE, szChannel, szName, szMsg)
    return l10NTextMsg
end

local function CreateVoiceMsg(szChannel, szName, tbMsgData)
    local szMsg = tbMsgData[2]
    local l10NTextMsg = L10N:Format(VOICEMSGTEMPLATE, szChannel, szName, szMsg)
    return l10NTextMsg
end

local function CreateTeamingMsg(szChannel, szName, tbMsgData)
    local nToatalCount = tbMsgData[3]
    local szTeamingMode = TeamingText[nToatalCount] 
    local nCurrentCount = tbMsgData[4]
    local szCurrentInfo = string.format( "%s/%s", nCurrentCount, nToatalCount)
    local l10NTextMsg = L10N:Format(TEAMINGMSGTEMPLATE, szChannel, szName, szTeamingMode, szCurrentInfo)
    return l10NTextMsg
end

local function CreateSytemMsg(szChannel, szContent)
    local szMsg = LobbyChatSystem:GetSystemContentText(szContent)
    if not szMsg then
        return ""
    end
    return L10N:Format(UITextDef.LOBBYCHAT_SYSTEMMSGTEMPLATE, szChannel, szMsg)
end

local function CreateQuickViewText(eChannel, tbData)
    local szChannel = GetChannelTypeText(eChannel)
    local l10NMsg
    local szName = tbData.szName
    local szContent = tbData.szContent
    if eChannel == CHAT_SYSTEM then
        return CreateSytemMsg(szChannel, szContent)
    end
    local tbMsgData = LobbyChatSystem:UnpackContent(szContent)
    local eMsgType = tonumber(tbMsgData[1])
    if eMsgType == LobbyChatSystem.EMsgType_Text then
        l10NMsg = CreateTextMsg(szChannel, szName, tbMsgData)
    elseif eMsgType == LobbyChatSystem.EMsgType_Voice then
        l10NMsg = CreateVoiceMsg(szChannel, szName, tbMsgData)
    elseif eMsgType == LobbyChatSystem.EMsgType_Teaming then
        l10NMsg = CreateTeamingMsg(szChannel, szName, tbMsgData)
    end
    return l10NMsg
end

local function RefreshFriendMsgInfo(self)
    local nUnreadMsgFriendCount = LobbyChatSystem:GetUnreadMsgFriendCount()
    local szInfo = ""
    if nUnreadMsgFriendCount > 0 then
        szInfo = L10N:Format(UISetUtils.GetL10NTextByKey("UI_LOBBY_CHAT_FRIEND_MSG"), nUnreadMsgFriendCount)
    end
    self.pWidgetRef.txtUnreadFriendMsg:SetText(szInfo)
end

local function OnRecieveMsg(self, eChannel, tbData, bFriendRecord)
    if bFriendRecord then
        return
    end
    self.eCurrentChannel = eChannel
    self.nSenderId = tbData.nSenderId
    local l10NMsg = CreateQuickViewText(eChannel, tbData)
    self.pTxtMsg:SetText(l10NMsg)
    if eChannel == CHAT_FRIEND and not self.bUPChatActivate then
        RefreshFriendMsgInfo(self)
    end
end

local function OnClickMsg(self)
    local eCurrentChannel = self.eCurrentChannel
    self.pWidgetRef.txtUnreadFriendMsg:SetText("")
    if eCurrentChannel == CHAT_FRIEND then
        EventManager:OnFireEvent(ClientEventDef.EV_OPEN_LOBBY_CHAT_FRIEND, self.nSenderId)
    else
        local eChannel = eCurrentChannel
        if eCurrentChannel == CHAT_TEAM then
            eChannel = TeamSystem:IsInTeam() and eChannel or nil
        end
        EventManager:OnFireEvent(ClientEventDef.EV_OPEN_LOBBY_CHAT, eChannel)
    end
    
end

local function OnClickTeamMsg(self, szMsg)
    local szContent = LobbyChatSystem:PackTextMsg(szMsg)
    LobbyChatSystem:SendMsg(LobbyChatSystem.CHAT_TEAM, szContent)
    HideList(self)
end

local function OnClickFunc(self)
    local bInTeam = TeamSystem:IsInTeam()
    if bInTeam then
        ToggelShowList(self)
    else
        EventManager:OnFireEvent(ClientEventDef.EV_OPEN_LOBBY_CHAT, self.eCurrentChannel)
        self.pWidgetRef.txtUnreadFriendMsg:SetText("")
    end
end

local function OnClickConscribe(self)
    local pLobbyChatTeaming = self.PrefabHelper:CreatePrefab(UIDef.UP_LOBBY_TEAMING)
    local Dialog = UIUtils.CreateDialog(UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAMING_TITLE"))
    Dialog:SetView(pLobbyChatTeaming.pWidgetRef)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:SetPositiveButtonCallback(function () pLobbyChatTeaming:OnBtnSend() end)
    Dialog:ShowDialog()
end

local function SetUPChatActivateState(self, bState)
    self.bUPChatActivate = bState
end

local function OnTeamChanged(self)
    local bInTeam = TeamSystem:IsInTeam()
    if not bInTeam and self.bShowList then
        HideList(self)
    end
end

function UPLobbyChatQuickView:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.pTxtMsg = pWidgetRef.txtMsg
    self.pQuickChatList = pWidgetRef.listQuickChat
    self.pListBorder = pWidgetRef.bdrChatTip
    self.bUPChatActivate = false
    InitQuickChatList(self)
    HideList(self)
    RefreshFriendMsgInfo(self)
end

function UPLobbyChatQuickView:OnUnload()
    self.pTxtMsg = nil
    self.pQuickChatList = nil
    self.ListHelper:Uninit()
    self.pListBorder = nil
end

function UPLobbyChatQuickView:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterEvent(ClientEventDef.EV_RECEIVE_CHAT_MESSAGE, self, OnRecieveMsg)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLICK_TEAM_CHAT, self, OnClickTeamMsg)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED, self, OnTeamChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_GUIDE_ON_SHOW_CHAT, self, SetUPChatActivateState) -- 需要知道聊天界面的开启、关闭状态，这个事件虽然名字有歧义，但是满足需求
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFunc.OnClicked, self, OnClickFunc)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnConscribe.OnClicked, self, OnClickConscribe)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnMsg.OnClicked, self, OnClickMsg)
end

function UPLobbyChatQuickView:OnUnbindEvent(EventHelper)
    EventHelper:UnregisterEvent(ClientEventDef.EV_RECEIVE_CHAT_MESSAGE, self, OnRecieveMsg)
    EventHelper:UnregisterEvent(ClientEventDef.EV_CLICK_TEAM_CHAT, self, OnClickTeamMsg)
    EventHelper:UnregisterEvent(ClientEventDef.EV_TEAM_CHANGED, self, OnTeamChanged)
    EventHelper:UnregisterEvent(ClientEventDef.EV_UI_GUIDE_ON_SHOW_CHAT, self, SetUPChatActivateState)
end

return UPLobbyChatQuickView