-----------------------------------------------------
--File Name    : UPLobbyChat.lua
--Author       : Edward J
--Create Time  : 2018-04-15
--Description  : UPLobbyChat
-----------------------------------------------------
local luaclass          = require("luaclass")
local UPFFABase         = require("UPFFABase")
local UPLobbyChat       = luaclass("UPLobbyChat", UPFFABase)

local LobbyChatSystem           = require("LobbyChatSystem")
local SelfTabBarHelper          = require("SelfTabBarHelper")
local SelfVerticalListHelper    = require("SelfVerticalListHelper")
local ClientEventDef            = require("ClientEventDef")
local UIUtils                   = require("UIUtils")
local UISetUtils                = require("UISetUtils")
local UIDef                     = require("UIDef")
local UIResourceDef             = require("UIResourceDef")
local FriendSystem              = require("FriendSystem")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local UITextDef                 = require("UITextDef")
local Proto                     = require("ClientProtoNames")
local EventManager              = require("EventManager")
local WidgetConfig              = require("WidgetDataTable")
local UIManager                 = require("UIManager")
local L10N                      = require("L10N")
local TeamSystem                = require("TeamSystem")
local ChatSystemHelper          = require("ChatSystemHelper")
local ItemSystem                = require("ItemSystem")
local DelayTimer                = require("DelayTimer")
local LobbySystem               = require("LobbySystem")
local LobbySubTypeDef           = require("LobbySubTypeDef")

-----------------------------------------------------
--系统频道
local CHAT_FRIEND               = LobbyChatSystem.CHAT_FRIEND
local CHAT_WORLD                = LobbyChatSystem.CHAT_WORLD
local CHAT_TEAM                 = LobbyChatSystem.CHAT_TEAM
-- local CHAT_ROOM     = LobbyChatSystem.CHAT_ROOM
local CHAT_CORPS                = LobbyChatSystem.CHAT_CORPS
local CHAT_SYSTEM               = LobbyChatSystem.CHAT_SYSTEM
local CHAT_TEAM_INVITE          = LobbyChatSystem.CHAT_TEAM_INVITE

--const param
local Visible                   = ESlateVisibility.Visible
local Collapsed                 = ESlateVisibility.Collapsed
local EXPRESSION_START_INDEX    = LobbyChatSystem.EXPRESSION_START_INDEX
local EXPRESSION_END_INDEX      = LobbyChatSystem.EXPRESSION_END_INDEX
local OFFLINE                   = Proto.PlayerStatus.OFFLINE
local BUBBLE_OFFSET             = Vector{X = 0, Y = -40, Z = 160}
local CHAT_ANIM_NAME            = "animChat"
local MAX_CHAT_LENGTH           = LobbyChatSystem.MAX_MSG_LENGTH
local DEFAULT_TAB_INDEX         = 1
local BIG_HORN_ID               = 1000003
local HORN_ID                   = 1000004

UPLobbyChat.tbViewParams            = nil
UPLobbyChat.TabBarHelper            = nil
UPLobbyChat.tbIndexToChannel        = nil
UPLobbyChat.CommonListHelper        = nil
UPLobbyChat.FriendListHelper        = nil
UPLobbyChat.FriendChatListHelper    = nil
UPLobbyChat.ExpressionListHelper    = nil
UPLobbyChat.eCurrentChannel         = CHAT_WORLD
UPLobbyChat.tbListChannelParam      = nil
UPLobbyChat.nLastTabIndex           = 1
UPLobbyChat.bVisible                = false
UPLobbyChat.tbExpression            = nil
UPLobbyChat.bChatWithFriend         = false
UPLobbyChat.nLastFriendId           = nil
UPLobbyChat.szLastFriendName        = nil
UPLobbyChat.nLastFriendIndex        = nil
UPLobbyChat.nNewMsgCount            = 0
UPLobbyChat.tbBubble                = nil
UPLobbyChat.szLastSendContent       = ""
UPLobbyChat.tbFriendListData        = nil
UPLobbyChat.bNewMsgTipShow          = false
UPLobbyChat.ulLobbyTopMsg           = nil
-----------------------------------------------------

local function OnBtnClose(self)
    self:Deactivate()
end

local function OnBtnTeaming(self)
    local pLobbyChatTeaming = self.PrefabHelper:CreatePrefab(UIDef.UP_LOBBY_TEAMING)
    local Dialog = UIUtils.CreateDialog(UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAMING_TITLE"))
    Dialog:SetView(pLobbyChatTeaming.pWidgetRef)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:SetPositiveButtonCallback(function () pLobbyChatTeaming:OnBtnSend() end)
    Dialog:ShowDialog()
end

local function ShowExpressions(self, bActivate)
    self.pWidgetRef.cvsFace:SetVisibility(bActivate and Visible or Collapsed)
end

--Tab操作

local function SetHornBtnEnable(self, bEnable, bBigEnable)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnHorn:SetIsEnabled(bEnable)
    pWidgetRef.btnBigHorn:SetIsEnabled(bBigEnable)
    pWidgetRef.txtHornCount:SetIsEnabled(bEnable)
    pWidgetRef.txtBigHornCount:SetIsEnabled(bBigEnable)
end

local function RefreshHornCount(self, eChannel)
    local pWidgetRef = self.pWidgetRef
    local tbHorn = ItemSystem:GetItemsByTemplateId(HORN_ID)
    local tbBigHorn = ItemSystem:GetItemsByTemplateId(BIG_HORN_ID)
    local bHornEnable = false
    local bBigHornEnable = false
    local nHornStackCount = 0
    if tbHorn then
        for _, v in ipairs(tbHorn) do
            local nStackCount = v:GetStackCount()
            nHornStackCount = nStackCount
            bHornEnable = true
        end
    end
    pWidgetRef.txtHornCount:SetText(nHornStackCount)
    local nBigHornStackCount = 0
    if tbBigHorn then
        for _, v in ipairs(tbBigHorn) do
            local nStackCount = v:GetStackCount()
            nBigHornStackCount = nStackCount
            bBigHornEnable = true
        end
    end
    pWidgetRef.txtBigHornCount:SetText(nBigHornStackCount)
    if eChannel == CHAT_WORLD then
        SetHornBtnEnable(self, bHornEnable, bBigHornEnable)
    else
        SetHornBtnEnable(self, false, false)
    end
end

local function OnItemChanged(self)
    -- if self.eCurrentChannel == CHAT_WORLD then
    RefreshHornCount(self, self.eCurrentChannel)
end

local function OnTabBarSelectedChanged(self, nIndex)
    local eChannel = self.tbIndexToChannel[nIndex]
    if eChannel > CHAT_TEAM_INVITE or eChannel < CHAT_FRIEND then
        return
    end
    local pWidgetRef = self.pWidgetRef
    if eChannel == CHAT_SYSTEM then
        pWidgetRef.inputBar:SetIsEnabled(false)
    else
        pWidgetRef.inputBar:SetIsEnabled(true)
    end

    if eChannel ~= CHAT_WORLD then
        pWidgetRef.bdrTopMsg:SetVisibility(Collapsed)
    end
    local pchkFace = pWidgetRef.chkFace
    local bChecked = pchkFace:IsChecked()
    if bChecked then
        pchkFace:SetCheckedState(ECheckBoxState.Unchecked)
        ShowExpressions(self, false)
    end
    RefreshHornCount(self, eChannel)

    self.eCurrentChannel = eChannel
    if self.tbListChannelParam then
        self.tbListChannelParam.Hide()
    end
    local tbParams =  self.tbViewParams[eChannel]
    if not tbParams then
        return
    end
    tbParams.Show()
    self:ShowViewByChannel(eChannel, tbParams)
    self.tbListChannelParam = tbParams
    self.nLastTabIndex = nIndex
    --由于切换频道标签后会将聊天内容自动拉到最新，所以是可以关闭新消息提示btn的
    self:RestNewMsgTip()
end

local function RefreshTeamTab(self)
    local pWidgetRef = self.pWidgetRef
    if self.eCurrentChannel == CHAT_TEAM then
        self.TabBarHelper:SelectByIndex(DEFAULT_TAB_INDEX)
        --这是个tabbar的bug ，动态的隐藏tab后 setindex 不会调用回调，暂时用此方法
        OnTabBarSelectedChanged(self, DEFAULT_TAB_INDEX)
    end
    pWidgetRef.chkTeam:SetVisibility(TeamSystem:IsInTeam() and Visible or Collapsed)
end


local function InitTabBtns(self)
    local pWidgetRef = self.pWidgetRef
    self.TabBarHelper = SelfTabBarHelper()
    local Helper = self.TabBarHelper
    Helper:Init(self, pWidgetRef.hboxTopButton, 1)
    Helper.OnSelectedChangedDelegate:Bind(OnTabBarSelectedChanged, self)
    RefreshTeamTab(self)
end

local function UninitTabBtns(self)
    self.TabBarHelper:Uninit()
    self.TabBarHelper = nil
end

--Input操作
local function AppendToMsg(self, szMsg)
    local pWidgetRef = self.pWidgetRef
    local szContent = L10N:ToString(pWidgetRef.txtChatContent:GetText())
    szContent = szContent .. szMsg
    pWidgetRef.txtChatContent:SetText(szContent)
end

local function OnClickExpression(self, nId)
    local szExpression = "#" .. nId
    AppendToMsg(self, szExpression)
end

local function InitInputBar(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.InputBar:SetVisibility(Visible)
    pWidgetRef.cvsFace:SetVisibility(Collapsed)
end

local function InitExpression(self)
    local tbExpression = {}
    for i = EXPRESSION_START_INDEX, EXPRESSION_END_INDEX do
        local tbTemp = {}
        tbTemp["nId"] = i
        tbTemp["szRes"] = string.format(UIResourceDef.CHAT_EXPRESSION_TEMPLATE, i, i)
        table.insert(tbExpression, tbTemp)
    end
    self.ExpressionListHelper:SetData(tbExpression)
end

local function OnBtnSend(self)
    local pWidgetRef = self.pWidgetRef
    local szContent = L10N:ToString(pWidgetRef.txtChatContent:GetText())
    szContent = string.gsub(szContent, " ", "")
    local eCheckResult = ChatSystemHelper.CheckLengthValid(szContent)
    if eCheckResult == ChatSystemHelper.eCheckResult.TooShort then
        UIUtils.ShowToast(UITextDef.CHAT_NOT_EMPTY)
        return
    elseif eCheckResult == ChatSystemHelper.eCheckResult.TooLong then
        UIUtils.ShowToast(UITextDef.CHAT_LENGTH_LIMITE)
        return
    end
    szContent = ChatSystemHelper.CheckSpecialCharacter(szContent)
    self.szLastSendContent = szContent
    local eCurrentChannel = self.eCurrentChannel
    local bSendResult = true
    if eCurrentChannel == CHAT_FRIEND then
        local nLastFriendId = self.nLastFriendId
        if nLastFriendId then
            bSendResult = LobbyChatSystem:SendMsg(self.eCurrentChannel, LobbyChatSystem:PackTextMsg(szContent), self.nLastFriendId)
        else
            UIUtils.ShowToast(UITextDef.CHAT_CLICK_TO_CHAT)
        end
    else
        bSendResult = LobbyChatSystem:SendMsg(self.eCurrentChannel, LobbyChatSystem:PackTextMsg(szContent))
    end
    if eCurrentChannel ~= CHAT_WORLD and bSendResult then
        pWidgetRef.txtChatContent:SetText("")
    end
    if not bSendResult then
        return
    end

    local pchkFace = pWidgetRef.chkFace
    local bChecked = pchkFace:IsChecked()
    if bChecked then
        pchkFace:SetCheckedState(ECheckBoxState.Unchecked)
        ShowExpressions(self, false)
    end
end

local function OnSendFailed(self)

end

local function OnVoiceBtnClicked(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 0.2)
end

local function OnInputTextChange(self, l10nText)
    local szContent = L10N:ToString(l10nText)
    local eCheckResult = ChatSystemHelper.CheckLengthValid(szContent)
    if eCheckResult == ChatSystemHelper.eCheckResult.TooLong then
        UIUtils.ShowToast(UITextDef.CHAT_LENGTH_LIMITE)
        local tbCharIndex = {}
        local nIndex = 1
        for p, c in utf8.codes(szContent) do
            tbCharIndex[nIndex] = p
            nIndex = nIndex + 1
        end
        szContent = string.sub(szContent, 1, tbCharIndex[MAX_CHAT_LENGTH+1]-1)
        self.pWidgetRef.txtChatContent:SetText(szContent)
    end
end

local function OpenHornPanel(Item)
    if Item then
        for __,v in pairs(Item) do
            UIManager:OpenWnd(UIDef.UI_SPEAKER_CONTENT, {tbItem = v})    
        end
    end
end

local function OnHornBtnClick(self)
    local tbItem = ItemSystem:GetItemsByTemplateId(HORN_ID)
    OpenHornPanel(tbItem)
end

local function OnBigHornBtnClick(self)
    local tbItem = ItemSystem:GetItemsByTemplateId(BIG_HORN_ID)
    OpenHornPanel(tbItem)
end

local function RunScrollNextTick(self, listHelper)
    if not listHelper then
        return
    end
    DelayTimer:RunNextTick(function() listHelper:ScrollToBottom(false) end)
end

--View操作
function UPLobbyChat:RestNewMsgTip()
    self.pWidgetRef.ovlNews:SetVisibility(Collapsed)
    self.nNewMsgCount = 0
    self.bNewMsgTipShow = false 
end
local function GoToNewMsg(self)
    RunScrollNextTick(self, self.tbListChannelParam.ListHelper)
    self:RestNewMsgTip()
end

local function SetNewMsgTipBtn(self, ListHelper, bSelf)
    local nListCount = #ListHelper.tbDataList - 2
    nListCount = nListCount < -1 and -1 or nListCount
    ListHelper:RequestListRefresh()
    local bIsBottom = ListHelper:IsItemInView(nListCount)
    if bIsBottom or bSelf then
        RunScrollNextTick(self, ListHelper)
        self.pWidgetRef.ovlNews:SetVisibility(Collapsed)
    else
        self.bNewMsgTipShow = true
        self.pWidgetRef.ovlNews:SetVisibility(Visible)
        self.nNewMsgCount = self.nNewMsgCount + 1
        local l10nTemp = UISetUtils.GetL10NTextByKey("LOBBYCHAT_NEW_MSG")
        self.pWidgetRef.ktxtNewMsg:SetText(L10N:Format(l10nTemp, self.nNewMsgCount))
    end
end

local function AddToBubbleCache(self, nPlayerId, pHeadInfo, pWidgetRef)
    if not nPlayerId then
        return
    end
    local tbTemp = {}
    tbTemp.pHeadInfo = pHeadInfo
    tbTemp.pWidgetRef = pWidgetRef
    self.tbBubble[nPlayerId] = tbTemp
end

local function GetBubbleFromCache(self, nPlayerId)
    return self.tbBubble[nPlayerId]
end

local function DestoryMemberActor(self, nPlayerId)
    self.tbBubble[nPlayerId] = nil
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
    local tbBubbleCache = GetBubbleFromCache(self, nPlayerId)
    local pWidgetComponent = nil
    local pWidgetRef = nil
    if not tbBubbleCache then
        local pHuman = nil
        pHuman = LobbySystem:GetSub(LobbySubTypeDef.MAIN):GetTeamMemberActor(nPlayerId)
        if not pHuman then
            return
        end
        local tbTemplate = WidgetConfig:GetTemplate(UIDef.UW_LOBBY_CHAT_BUBBLE)
        pWidgetRef = UIManager:CreateUMG(tbTemplate.szUIPath)
        pWidgetComponent = pHuman.HeadInfo
        if not pWidgetComponent then
            error('CreateSinglePlayer CreateWidget failed, WidgetComponent is nil. nAvatarId ')
        end
        pWidgetComponent:K2_AttachToComponent(pHuman.Mesh, "root01", EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, false)
        pWidgetComponent:K2_SetRelativeLocation(BUBBLE_OFFSET)
        pWidgetComponent:SetWidget(pWidgetRef)
        pWidgetComponent.Space = EWidgetSpace.Screen
        AddToBubbleCache(self, nPlayerId, pWidgetComponent, pWidgetRef)
    else
        pWidgetComponent = tbBubbleCache.pHeadInfo
        pWidgetRef = tbBubbleCache.pWidgetRef
    end
    local szMsg = GetBubbleMsg(tbData)
    pWidgetRef.ktxtMsg:SetText(szMsg)
    local pAnimRef = pWidgetRef["AutoHide"]
    pWidgetRef:PlayAnimation(pAnimRef, 0, 1, EUMGSequencePlayMode.Forward, 1)
end

local function SetFriendUnreadMsgCount(tbFriends)
    for nIndex, tbFriend in pairs(tbFriends) do
        local nUnreadMsgCount = LobbyChatSystem:GetUnreadMsgFriendById(tbFriend.id)
        tbFriend.nUnreadMsgCount = nUnreadMsgCount
    end
end

local function RefreshFriendUnreadMsgCount(self)
    SetFriendUnreadMsgCount(self.tbFriendListData)
end

local function OnRecieveMsg(self, eChannel, tbData, bFriendRecord)
    local pWidgetRef = self.pWidgetRef
    local nPlayerId = tbData.nSenderId
    if eChannel == CHAT_TEAM then
        ShowTeamBubble(self, nPlayerId, tbData)
    end
    if not self.bVisible or self.eCurrentChannel ~= eChannel then
        if eChannel == CHAT_FRIEND and not bFriendRecord then
            self.TabBarHelper:SetTipIconVisible(3, true)
        end
        return
    end
    local nPlayerSelfId = GamePlayerSelfHelper:Get().nPlayerId
    local bSelf = nPlayerSelfId == nPlayerId
    local eMsgType = LobbyChatSystem:GetMsgType(tbData.szContent)
    if bSelf and eMsgType ~= LobbyChatSystem.EMsgType_Teaming then
        pWidgetRef.txtChatContent:SetText("")
    end
    if eChannel == CHAT_FRIEND then
        local nIndex = self.nLastFriendIndex
        local nFriendId = self.nLastFriendId
        local szFriendName = self.szLastFriendName
        if not nIndex then
            return
        end

        if bSelf or nPlayerId == self.nLastFriendId then
            self:RefreshFriendChatList(nIndex, nFriendId, szFriendName)
        elseif nPlayerId ~= self.nLastFriendId then
            RefreshFriendUnreadMsgCount(self)
            self.FriendListHelper:RefreshItemInView()
        end
    else
        local ListHelper = self.tbListChannelParam.ListHelper
        SetNewMsgTipBtn(self, ListHelper, bSelf)
    end
end

local function SetWidgetVisible(tbWidgets, eVisible)
    for k, widget in pairs(tbWidgets) do
        widget:SetVisibility(eVisible)
    end
end

local function AddViewParam(self, eChannel, ListHelper, ...) -- ...是所有需要控制显隐的控件
    assert(self.tbViewParams, "[UI] UPLobbyChat, AddViewParam, tbViewParams is nil")
    local tbShowWidgets = { ... }
    local tbTemp = {}
    tbTemp.tbWidgets = tbShowWidgets
    tbTemp.ListHelper = ListHelper
    tbTemp.Hide = function() SetWidgetVisible(tbTemp.tbWidgets, Collapsed) end
    tbTemp.Show = function() SetWidgetVisible(tbTemp.tbWidgets, Visible) end
    self.tbViewParams[eChannel] = tbTemp
end

local function InitViews(self)
    local tbTemp = self.tbIndexToChannel
    ChatSystemHelper.AddKeyAndValueToTab(tbTemp, 1, CHAT_WORLD)
    ChatSystemHelper.AddKeyAndValueToTab(tbTemp, 2, CHAT_TEAM)
    ChatSystemHelper.AddKeyAndValueToTab(tbTemp, 3, CHAT_FRIEND)
    ChatSystemHelper.AddKeyAndValueToTab(tbTemp, 5, CHAT_CORPS)
    ChatSystemHelper.AddKeyAndValueToTab(tbTemp, 4, CHAT_SYSTEM)

    local pWidgetRef = self.pWidgetRef
    self.CommonListHelper = SelfVerticalListHelper()
    self.CommonListHelper:Init(self, pWidgetRef.commonList)
    self.FriendListHelper = SelfVerticalListHelper()
    self.FriendListHelper:Init(self, pWidgetRef.friendList)
    self.FriendChatListHelper = SelfVerticalListHelper()
    self.FriendChatListHelper:Init(self, pWidgetRef.friendChatList)
    self.ExpressionListHelper = SelfVerticalListHelper()
    self.ExpressionListHelper:Init(self, pWidgetRef.expressionList)

    AddViewParam(self, CHAT_WORLD, self.CommonListHelper, pWidgetRef.commonList)
    AddViewParam(self, CHAT_FRIEND, self.FriendChatListHelper, pWidgetRef.hboxFriend)
    AddViewParam(self, CHAT_TEAM, self.CommonListHelper, pWidgetRef.commonList)
    AddViewParam(self, CHAT_SYSTEM, self.CommonListHelper, pWidgetRef.commonList)
end

local function GetOnlineFriend(tbFriend)
    if not tbFriend then
        return
    end
    local nCount = 0
    for k, tbData in pairs(tbFriend) do
        local nStatus = tbData.status
        if nStatus ~= OFFLINE then
            nCount = nCount + 1
        end
    end
    return nCount
end


local function ShowFriendListWidget(self, bShow)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.vboxChatToFirendTag:SetVisibility(bShow and Collapsed or Visible)
    pWidgetRef.hboxFriendInfo:SetVisibility(bShow and Visible or Collapsed)
    pWidgetRef.btnFriend:SetVisibility(bShow and Visible or Collapsed)
    pWidgetRef.imgBtnFriend:SetVisibility(bShow and Visible or Collapsed)

end

local function ResetFriendChatView(self)
    self.bChatWithFriend = false
    ShowFriendListWidget(self, false)
    self.nLastFriendId = nil
    self.nLastFriendIndex = nil
    self.szLastFriendName = nil
    local FriendChatListHelper = self.FriendChatListHelper
    FriendChatListHelper.pListRef:SetVisibility(Collapsed)
    local FriendListHelper = self.FriendListHelper
    FriendListHelper:UnselectCurrentItem()
    FriendListHelper:ScrollToTop(false)
end

local function RefreshFriendList(self, nPlayerId)
    if self.eCurrentChannel ~= CHAT_FRIEND then
        return
    end
    local pWidgetRef = self.pWidgetRef
    local FriendComponent = FriendSystem:GetComponent()
    local tbFriendSummaries = FriendComponent:GetFriendSummaries()
    local FriendListHelper = self.FriendListHelper
    if not tbFriendSummaries then
        ResetFriendChatView(self)
        return
    end
    --刷新某个玩家并显示
    if nPlayerId then
        for nIndex, tbFriend in pairs(tbFriendSummaries) do
            if tbFriend.id == nPlayerId then
                self.nLastFriendId = nPlayerId
                self.nLastFriendIndex = nIndex
                self.szLastFriendName = tbFriend.name
                break
            end
        end
    end

    SetFriendUnreadMsgCount(tbFriendSummaries)

    self.tbFriendListData = tbFriendSummaries
    FriendListHelper:SetData(tbFriendSummaries)

    local nfriendCount = #tbFriendSummaries
    local nOnlineCount = GetOnlineFriend(tbFriendSummaries)
    pWidgetRef.ktxtFriendCount:SetText(string.format( "%d/%d",nOnlineCount, nfriendCount))
    local nLastFriendId = self.nLastFriendId
    local nLastFriendIndex = self.nLastFriendIndex
    --当当前好友被删除时，需要重新设置好友列表，去掉选中效果、并隐藏右侧聊天信息
    if nLastFriendId then
        local tbFriend = FriendComponent:GetFriend(nLastFriendId)
        if tbFriend then
            if nLastFriendIndex then
                FriendListHelper:SetSelectedIndex(nLastFriendIndex)
            end
        else
            ResetFriendChatView(self)
        end
    else
        FriendListHelper:ScrollToTop(false)
    end
end

local function RefreshFriendView(self, nFriendId)
    RefreshFriendList(self, nFriendId)
    local bChatWithFriend = self.bChatWithFriend
    ShowFriendListWidget(self, bChatWithFriend)
    self:RefreshFriendChatList(self.nLastFriendIndex, self.nLastFriendId, self.szLastFriendName)
end

-- local function BlockPlayer(self)
--     UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 0.2)
-- end

local function InvitePlayer(self)
    local nPlayerId = self.nLastFriendId
    TeamSystem:RequestInvitePlayer(nPlayerId, LobbyChatSystem.FROM_CHAT)
end

local function ApplyJoin(self)
    local nPlayerId = self.nLastFriendId
    TeamSystem:RequestApplyJoin(nPlayerId)
end

local function ShowPlayerInfo(self)
    local nPlayerId = self.nLastFriendId
    UIManager:OpenWnd(UIDef.UI_PLAYER_INFO, {nPlayerId = nPlayerId})
end

local function OnBtnFriendClicked(self)
    local tbMemberData = TeamSystem:GetTeamMemberData(self.nLastFriendId)
    local tbArgs = {}
    UIUtils.AddCommonBtnListArgs(tbArgs, nil, UISetUtils.GetL10NTextByKey("UIPLAYERINFO"), nil, function() ShowPlayerInfo(self) end)
    if tbMemberData then
        UIUtils.AddCommonBtnListArgs(tbArgs, nil, UISetUtils.GetL10NTextByKey("UIPLAYERTIPS_L10N_APPLYJOINTEAM"), nil, function() ApplyJoin(self) end)
    else
        UIUtils.AddCommonBtnListArgs(tbArgs, nil, UISetUtils.GetL10NTextByKey("UIPLAYERTIPS_L10N_INVITECREATETEAM"), nil, function() InvitePlayer(self) end)
    end
    --UIUtils.AddCommonBtnListArgs(tbArgs, nil, UISetUtils.GetL10NTextByKey("UIBLOCKPLAYER"), nil, function() BlockPlayer(self) end)
    LobbyChatSystem.pButtonList:CreateBtnsList(self.pWidgetRef.btnFriend, {tbBtnsArg = tbArgs})
end

local function OnListViewScrolled(self, nScrollOffset)
    if self.bNewMsgTipShow then
        local bBottom = self.CommonListHelper:IsBottom()
        if bBottom then
            self:RestNewMsgTip()
        end
    end
end

function UPLobbyChat:RefreshFriendChatList(nIndex, nFriendId, szFriendName)
    local pWidgetRef = self.pWidgetRef
    local ListHelper = self.FriendChatListHelper
    if self.eCurrentChannel ~= CHAT_FRIEND then
        return
    end
    if nFriendId == nil then
        ListHelper.pListRef:SetVisibility(Collapsed)
        return
    end
    RefreshFriendUnreadMsgCount(self)
    self.bChatWithFriend = true
    self.nLastFriendIndex = nIndex
    self.nLastFriendId = nFriendId
    self.szLastFriendName = szFriendName
    self.FriendListHelper:SetSelectedIndex(nIndex)
    ShowFriendListWidget(self, self.bChatWithFriend)
    local tbChatHistory = LobbyChatSystem:GetFriendHistoryById(nFriendId)
    pWidgetRef.vboxChatToFirendTag:SetVisibility(Collapsed)
    pWidgetRef.ktxtFriendName:SetText(szFriendName)
    if tbChatHistory then
        ListHelper.pListRef:SetVisibility(Visible)
        ListHelper:SetData(tbChatHistory)
        RunScrollNextTick(self, ListHelper)
    else
        ListHelper.pListRef:SetVisibility(Collapsed)
    end
end

function UPLobbyChat:ShowViewByChannel(eChannel, tbParams)
    if eChannel == CHAT_FRIEND then
        self.TabBarHelper:SetTipIconVisible(3, false)
    end
    local tblistData = LobbyChatSystem:GetHistory(eChannel)
    if eChannel == CHAT_FRIEND then
        RefreshFriendView(self)
    else
        tbParams.ListHelper:SetData(tblistData)
        RunScrollNextTick(self, tbParams.ListHelper)
    end
end

function UPLobbyChat:Activate(eChannel)
    self.super.Activate(self)
    if eChannel then
        self.nLastTabIndex = self:GetChannelIndex(eChannel)
    end
    self.pWidgetRef:SetVisibility(Visible)
    self.bVisible = true
    EventManager:OnFireEvent(ClientEventDef.EV_UI_GUIDE_ON_SHOW_CHAT, true)
    self.Owner:PlayAnimation(CHAT_ANIM_NAME, 0, 1, EUMGSequencePlayMode.Forward, 1)
    self.TabBarHelper:SelectByIndex(self.nLastTabIndex)
    OnTabBarSelectedChanged(self, self.nLastTabIndex)
end

function UPLobbyChat:ActiveWithFriendId(nFriendId)
    self:Activate(CHAT_FRIEND)
    RefreshFriendView(self, nFriendId)
end

function UPLobbyChat:GetChannelIndex(eChannel)
    local tbIndexToChannel = self.tbIndexToChannel
    if not tbIndexToChannel then
        return DEFAULT_TAB_INDEX
    end

    for k,v in pairs(tbIndexToChannel) do
        if v == eChannel then
            return k
        end
    end
    return DEFAULT_TAB_INDEX
end

function UPLobbyChat:Deactivate()
    self.super.Deactivate(self)
    EventManager:OnFireEvent(ClientEventDef.EV_CHAT_CLOSE_BTNLIST)
    self.pWidgetRef:SetVisibility(Collapsed)
    self.bVisible = false
    EventManager:OnFireEvent(ClientEventDef.EV_UI_GUIDE_ON_SHOW_CHAT, false)
end

function UPLobbyChat:OnLoad()
    self.super.OnLoad(self)
    self.tbViewParams = {}
    self.tbIndexToChannel = {}
    self.tbBubble = {}
    self.ulLobbyTopMsg = self.UILogicHelper:CreateUILogic("ULLobbyTopMsg")
    LobbyChatSystem.pButtonList = self.PrefabHelper:BindPrefab(self.pWidgetRef.upButtonListContent)
    InitTabBtns(self)
    InitViews(self)
    InitInputBar(self)
    InitExpression(self)
    self:Deactivate()
end

function UPLobbyChat:OnUnload()
    self.super.OnUnload()
    self.tbViewParams = nil
    self.tbIndexToChannel = nil
    self.CommonListHelper:Uninit()
    self.FriendListHelper:Uninit()
    self.FriendChatListHelper:Uninit()
    self.ExpressionListHelper:Uninit()
    UninitTabBtns(self)
end

function UPLobbyChat:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_LOBBY_CHAT, self, self.Activate)
    EventHelper:RegisterEvent(ClientEventDef.EV_RECEIVE_CHAT_MESSAGE, self, OnRecieveMsg)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLICK_EXPRESSION, self, OnClickExpression)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS, self, RefreshFriendList)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_LOBBY_CHAT_FRIEND, self, self.ActiveWithFriendId)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHAT_CLICK_FRIEND, self, self.RefreshFriendChatList)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_DESTORY_MEMBER_ACTOR, self, DestoryMemberActor)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHAT_SEND_FAILED, self, OnSendFailed)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED,  self, RefreshTeamTab)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_SYNC, self, RefreshTeamTab)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT, self, OnItemChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnBtnClose)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTeaming.OnClicked, self, OnBtnTeaming)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSend.OnClicked, self, OnBtnSend)
    EventHelper:RegisterCppDelegate(pWidgetRef.chkFace.OnCheckStateChanged, self, ShowExpressions)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGoToNewMsg.OnClicked, self, GoToNewMsg)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnVoiceOpen.OnClicked, self, OnVoiceBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFriend.OnClicked, self, OnBtnFriendClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtChatContent.OnTextChanged, self, OnInputTextChange)
    EventHelper:RegisterCppDelegate(pWidgetRef.commonlist.OnListViewScrolled, self, OnListViewScrolled)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnHorn.OnClicked, self, OnHornBtnClick)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBigHorn.OnClicked, self, OnBigHornBtnClick)
end

function UPLobbyChat:OnUnbindEvent(EventHelper)
    --local pWidgetRef = self.pWidgetRef
    EventHelper:UnregisterEvent(ClientEventDef.EV_OPEN_LOBBY_CHAT, self, self.Activate)
    EventHelper:UnregisterEvent(ClientEventDef.EV_RECEIVE_CHAT_MESSAGE, self, OnRecieveMsg)
    EventHelper:UnregisterEvent(ClientEventDef.EV_CLICK_EXPRESSION, self, OnClickExpression)
    EventHelper:UnregisterEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS, self, RefreshFriendList)
    EventHelper:UnregisterEvent(ClientEventDef.EV_OPEN_LOBBY_CHAT_FRIEND, self, self.ActiveWithFriendId)
    EventHelper:UnregisterEvent(ClientEventDef.EV_CHAT_CLICK_FRIEND, self, self.RefreshFriendChatList)
    EventHelper:UnregisterEvent(ClientEventDef.EV_CHAT_SEND_FAILED, self, OnSendFailed)
    EventHelper:UnregisterEvent(ClientEventDef.EV_TEAM_CHANGED,  self, RefreshTeamTab)
    EventHelper:UnregisterEvent(ClientEventDef.EV_TEAM_SYNC, self, RefreshTeamTab)
    EventHelper:UnregisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT, self, OnItemChanged)
end

return UPLobbyChat