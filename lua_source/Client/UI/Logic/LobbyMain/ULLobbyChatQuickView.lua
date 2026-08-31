-----------------------------------------------------
--File Name    : ULLobbyChatQuickView.lua
--Author       : Edward J
--Create Time  : 2020-05-22
--Description  : lobby Chat Quick View
-----------------------------------------------------
local luaclass              = require("luaclass")
local UILogicBase           = require("UILogicBase")
local ULLobbyChatQuickView  = luaclass("ULLobbyChatQuickView", UILogicBase)

local ClientEventDef            = require("ClientEventDef")
local LobbyChatSystem           = require("LobbyChatSystem")
local SelfVerticalListHelper    = require("SelfVerticalListHelper")
local TeamChatDataTable         = require("TeamChatDataTable")
local TeamSystem                = require("TeamSystem")
local UITextDef                 = require("UITextDef")
local L10N                      = require("L10N")
local UIUtils                   = require("UIUtils")
local UISetUtils                = require("UISetUtils")
local UIDef                     = require("UIDef")
local UIManager                 = require("UIManager")
local UIResourceDef              = require("UIResourceDef")
local EventManager              = require("EventManager")
local LobbySystem               = require("LobbySystem")
local LobbySubTypeDef           = require("LobbySubTypeDef")
-----------------------------------------------------
local Visible               = ESlateVisibility.Visible
local Collapsed             = ESlateVisibility.Collapsed
local VOICEMSGTEMPLATE      = UITextDef.LOBBYCHAT_VOICEMSGTEMPLATE
local TEAMINGMSGTEMPLATE    = UITextDef.LOBBYCHAT_TEAMINGMSGTEMPLATE
local TEXTMSGTEMPLATE       = UITextDef.LOBBYCHAT_TEXTMSGTEMPLATE
local CHAT_FRIEND           = LobbyChatSystem.CHAT_FRIEND
local CHAT_TEAM             = LobbyChatSystem.CHAT_TEAM
local CHAT_SYSTEM           = LobbyChatSystem.CHAT_SYSTEM
local BUBBLE_Z_OFFSET       = 85
local ChannelText           = 
{
    [LobbyChatSystem.CHAT_FRIEND]       = UITextDef.LOBBYCHAT_FRIEND_CHANNEL,
    [LobbyChatSystem.CHAT_WORLD]        = UITextDef.LOBBYCHAT_WORLD_CHANNEL,    
    [LobbyChatSystem.CHAT_TEAM]         = UITextDef.LOBBYCHAT_TEAM_CHANNEL,     
    [LobbyChatSystem.CHAT_ROOM]         = UITextDef.LOBBYCHAT_ROOM_CHANNEL,     
    [LobbyChatSystem.CHAT_CORPS]        = UITextDef.LOBBYCHAT_CORPS_CHANNEL,
    [LobbyChatSystem.CHAT_SYSTEM]       = UITextDef.LOBBYCHAT_SYSTEM,
    [LobbyChatSystem.CHAT_TEAM_INVITE]  = UITextDef.LOBBYCHAT_TEAM_INVITE,
}

local TeamingText =
{
    ["2"] = UITextDef.LOBBYCHAT_TEAMINGMODE_TOW,
    ["4"] = UITextDef.LOBBYCHAT_TEAMINGMODE_FOUR,
}
-- local DEFAULT_VECTOR        = Vector2D()

ULLobbyChatQuickView.pTxtMsg            = nil
ULLobbyChatQuickView.pQuickChatList     = nil
ULLobbyChatQuickView.ListHelper         = nil
ULLobbyChatQuickView.bShowList          = false
ULLobbyChatQuickView.eCurrentChannel    = nil
ULLobbyChatQuickView.nSenderId          = nil
ULLobbyChatQuickView.bUPChatActivate    = nil
ULLobbyChatQuickView.tbBubble           = nil
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

local function SetFuncBtnColor(self, bShowList)
    self.pWidgetRef.btnFunc:SetBackgroundColor(bShowList and UIResourceDef.COLOR.YELLOW.LINEAR_COLOR or UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
end

local function ShowList(self)
    self.pListBorder:SetVisibility(Visible)
    self.bShowList = true
    SetFuncBtnColor(self, self.bShowList)
end

local function HideList(self)
    self.pListBorder:SetVisibility(Collapsed)
    self.bShowList = false
    SetFuncBtnColor(self, self.bShowList)
end

local function ToggelShowList(self)
    local bShowList = self.bShowList
    if bShowList then
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
    local szToatalCount = tbMsgData[3]
    local szTeamingMode = TeamingText[szToatalCount]
    local nCurrentCount = tbMsgData[4]
    local szCurrentInfo = string.format( "%s/%s", nCurrentCount, szToatalCount)
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

local function DestoryMemberActor(self, nPlayerId)
    self.tbBubble[nPlayerId] = nil
end

local function AddToBubbleCache(self, nPlayerId, pWorldPos)
    if not nPlayerId then
        return
    end
    self.tbBubble[nPlayerId] = pWorldPos
end

local function GetBubbleFromCache(self, nPlayerId)
    return self.tbBubble[nPlayerId]
end

local function CleanBubbleCache(self)
    self.tbBubble = {}
end

local function GetBubbleMsg(tbData)
    local szContent = tbData.szContent
    local tbMsgData = LobbyChatSystem:UnpackContent(szContent)
    local eMsgType = tonumber(tbMsgData[1])
    local szMsg
    if eMsgType == LobbyChatSystem.EMsgType_Text then
        szMsg = tbMsgData[2]
    end
    return szMsg
end

local function ShowTeamBubble(self, nPlayerId, tbData)
    local pWorldPos = GetBubbleFromCache(self, nPlayerId)
    local LobbyMain = LobbySystem:GetSub(LobbySubTypeDef.MAIN)
    if not pWorldPos then
        local pHuman = nil
        pHuman = LobbyMain:GetTeamMemberActor(nPlayerId)
        if not pHuman then
            return
        end
        pWorldPos = pHuman:K2_GetActorLocation()
        pWorldPos =  Vector{X=pWorldPos.X,Y=pWorldPos.Y,Z=pWorldPos.Z+BUBBLE_Z_OFFSET}
        AddToBubbleCache(self, nPlayerId, pWorldPos)
    end
    local szMsg = GetBubbleMsg(tbData)
    -- pWidgetRef.ktxtMsg:SetText(szMsg)
    -- local pAnimRef = pWidgetRef["AutoHide"]
    -- pWidgetRef:PlayAnimation(pAnimRef, 0, 1, EUMGSequencePlayMode.Forward, 1)
    EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_CHAT_BUBBLE, nPlayerId, pWorldPos, szMsg)
end

local function OnRecieveMsg(self, eChannel, tbData, bFriendRecord)
    if bFriendRecord then
        return
    end
    self.eCurrentChannel = eChannel
    local nSenderId = tbData.nSenderId
    self.nSenderId = nSenderId
    local l10NMsg = CreateQuickViewText(eChannel, tbData)
    self.pTxtMsg:SetText(l10NMsg)
    if eChannel == CHAT_FRIEND and not self.bUPChatActivate then
        RefreshFriendMsgInfo(self)
    end
    if eChannel == CHAT_TEAM then
        ShowTeamBubble(self, nSenderId, tbData)
    end
end

local function OnClickExp(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 0.2)
end

local function OnClickMsg(self)
    local eCurrentChannel = self.eCurrentChannel
    self.pWidgetRef.txtUnreadFriendMsg:SetText("")
    local eChannel = eCurrentChannel
    if eCurrentChannel == CHAT_FRIEND then
        local nSenderId = self.nSenderId
        local tbArgs = {}
        tbArgs.eChannel = eChannel
        tbArgs.nFriendId = nSenderId
        UIManager:OpenWnd(UIDef.UI_LOBBY_CHAT, tbArgs)
        HideList(self)
    else
        if eCurrentChannel == CHAT_TEAM then
            eChannel = TeamSystem:IsInTeam() and eChannel or nil
        end
        local tbArgs = {}
        tbArgs.eChannel = eChannel
        UIManager:OpenWnd(UIDef.UI_LOBBY_CHAT, tbArgs)
        HideList(self)
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
        local tbArgs = {}
        tbArgs.eChannel = self.eCurrentChannel
        UIManager:OpenWnd(UIDef.UI_LOBBY_CHAT, tbArgs)
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
    CleanBubbleCache(self)
    if not bInTeam and self.bShowList then
        HideList(self)
    end
end

function ULLobbyChatQuickView:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.pTxtMsg = pWidgetRef.txtMsg
    self.pQuickChatList = pWidgetRef.listQuickChat
    self.pListBorder = pWidgetRef.bdrChatTip
    self.bUPChatActivate = false
    self.tbBubble = {}
    pWidgetRef.btnExp:SetIsEnabled(false)
    InitQuickChatList(self)
    HideList(self)
    RefreshFriendMsgInfo(self)
    pWidgetRef.btnExp:SetVisibility(Collapsed)
end

function ULLobbyChatQuickView:OnUnload()
    self.pTxtMsg = nil
    self.pQuickChatList = nil
    self.ListHelper:Uninit()
    self.pListBorder = nil
end

function ULLobbyChatQuickView:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterEvent(ClientEventDef.EV_RECEIVE_CHAT_MESSAGE,               self, OnRecieveMsg)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLICK_TEAM_CHAT,                    self, OnClickTeamMsg)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED,                       self, OnTeamChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_GUIDE_ON_SHOW_CHAT,              self, SetUPChatActivateState) -- 需要知道聊天界面的开启、关闭状态，这个事件虽然名字有歧义，但是满足需求
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_DESTORY_MEMBER_ACTOR,          self, DestoryMemberActor)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFunc.OnClicked,                   self, OnClickFunc)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnConscribe.OnClicked,              self, OnClickConscribe)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnMsg.OnClicked,                    self, OnClickMsg)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnExp.OnClicked,                    self, OnClickExp)
end

return ULLobbyChatQuickView