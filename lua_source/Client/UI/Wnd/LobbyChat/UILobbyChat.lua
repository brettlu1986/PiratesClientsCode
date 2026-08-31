-----------------------------------------------------
--File Name    : UILobbyChat.lua
--Author       : Edward J
--Create Time  : 2020-05-22
--Description  : UILobbyChat
-----------------------------------------------------
local luaclass          = require("luaclass")
local WndBase           = require("WndBase")
local UILobbyChat       = luaclass("UILobbyChat", WndBase)

local LobbyChatSystem           = require("LobbyChatSystem")
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
local UIManager                 = require("UIManager")
local L10N                      = require("L10N")
local TeamSystem                = require("TeamSystem")
local ChatSystemHelper          = require("ChatSystemHelper")
local ItemSystem                = require("ItemSystem")
local DelayTimer                = require("DelayTimer")
local SelfTabBarHelper          = require("SelfTabBarHelper")
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
local CHAT_ANIM_NAME            = "animStart"
-- local TEAMING_ANIM_NAME         = "animTeaming"
local MAX_CHAT_LENGTH           = LobbyChatSystem.MAX_MSG_LENGTH
local DEFAULT_TAB_INDEX         = 1
local BIG_HORN_ID               = 1000003
local HORN_ID                   = 1000004
local TEAM_TAB_INDEX            = 3
local CORPS_TAB_INDEX           = 4


UILobbyChat.tbViewParams            = nil
UILobbyChat.TabBarHelper            = nil
UILobbyChat.tbIndexToChannel        = nil
UILobbyChat.CommonListHelper        = nil
UILobbyChat.FriendListHelper        = nil
UILobbyChat.FriendChatListHelper    = nil
UILobbyChat.ExpressionListHelper    = nil
UILobbyChat.TeamInviteListHelper    = nil
UILobbyChat.eCurrentChannel         = CHAT_WORLD
UILobbyChat.tbListChannelParam      = nil
UILobbyChat.nLasteChannel           = CHAT_WORLD
UILobbyChat.tbExpression            = nil
UILobbyChat.bChatWithFriend         = false
UILobbyChat.nLastFriendId           = nil
UILobbyChat.szLastFriendName        = nil
UILobbyChat.nLastFriendIndex        = nil
UILobbyChat.nNewMsgCount            = 0
UILobbyChat.szLastSendContent       = ""
UILobbyChat.tbFriendListData        = nil
UILobbyChat.bNewMsgTipShow          = false
UILobbyChat.ulLobbyTopMsg           = nil
UILobbyChat.tbTabBtns               = nil
UILobbyChat.tbTabBarHelper          = nil
-----------------------------------------------------

local function OnBtnClose(self)
    self:Deactivate()
    self:CloseSelf()
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
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrFace:SetVisibility(bActivate and Visible or Collapsed)
    pWidgetRef.imgChkFace:SetColorAndOpacity(bActivate and UIResourceDef.COLOR.BLACK.LINEAR_COLOR or UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
    pWidgetRef.btnCloseExpression:SetVisibility(bActivate and Visible or Collapsed)
end

local function OnCloseExpressionClicked(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.chkFace:SetCheckedState(ECheckBoxState.Unchecked)
    ShowExpressions(self, false)
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

--TabBtn操作
local function GetTabIndexByChannel(self, eChannel)
    if not eChannel then
        return
    end
    
    for index, channel in pairs(self.tbIndexToChannel) do
        if channel == eChannel then
            return index
        end
    end
    return
end

local function OnTabBarSelectedChanged(self, eChannel)
    local nIndex = GetTabIndexByChannel(self, eChannel)
    if not nIndex then
        return
    end
    if eChannel > CHAT_TEAM_INVITE or eChannel < CHAT_FRIEND then
        return
    end
    local pWidgetRef = self.pWidgetRef
    if eChannel == CHAT_SYSTEM then
        pWidgetRef.inputBar:SetIsEnabled(false)
        -- self:PlayAnimation(TEAMING_ANIM_NAME, 0, 1, EUMGSequencePlayMode.Forward, 1)
    else
        pWidgetRef.inputBar:SetIsEnabled(true)
        -- if self.eCurrentChannel == CHAT_SYSTEM then
        --     self:PlayAnimation(TEAMING_ANIM_NAME, 0, 1, EUMGSequencePlayMode.Reverse, 1)
        -- end
    end

    -- if eChannel ~= CHAT_WORLD then
    --     pWidgetRef.bdrTopMsg:SetVisibility(Collapsed)
    -- end
    
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
    self.nLasteChannel = eChannel
    --由于切换频道标签后会将聊天内容自动拉到最新，所以是可以关闭新消息提示btn的
    self:RestNewMsgTip()
end

local function SelectTabByeChannel(self, eChannel)
    local nIndex = GetTabIndexByChannel(self, eChannel)
    if not nIndex then
        return
    end
    OnTabBarSelectedChanged(self, eChannel)
end

local function MockTabClickByeChannel(self, eChannel)
    local nIndex = GetTabIndexByChannel(self, eChannel)
    if not nIndex then
        return
    end
    self.tbTabBarHelper:SelectByIndex(nIndex, true)
end

local function RefreshTeamTab(self)
    local eVisibility = TeamSystem:IsInTeam() and Visible or Collapsed
    self.tbTabBarHelper:SetVisibilityByIndex(TEAM_TAB_INDEX, eVisibility)
    if eVisibility == Collapsed and self.eCurrentChannel == CHAT_TEAM then
        MockTabClickByeChannel(self, CHAT_WORLD)
        self.eCurrentChannel = CHAT_WORLD
    end
end

local function InitTabBtns(self)
    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.hboxTopButton, -1)
    local tbTemp = self.tbIndexToChannel
    ChatSystemHelper.AddKeyAndValueToTab(tbTemp, 1, CHAT_WORLD)
    ChatSystemHelper.AddKeyAndValueToTab(tbTemp, 2, CHAT_FRIEND)
    ChatSystemHelper.AddKeyAndValueToTab(tbTemp, 3, CHAT_TEAM)
    ChatSystemHelper.AddKeyAndValueToTab(tbTemp, 4, CHAT_CORPS)
    ChatSystemHelper.AddKeyAndValueToTab(tbTemp, 5, CHAT_SYSTEM)
end
--TabBtn操作 end

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
    pWidgetRef.bdrFace:SetVisibility(Collapsed)
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

local function RunCheckNewMsgTipNextTick(self, listHelper)
    if not listHelper then
        return
    end
    
    DelayTimer:RunNextTick(function()
        local bIsBottom = listHelper:IsItemInView(#listHelper.tbDataList - 2) --检查倒数第二个item是否在view中 （注：index从0开始）
        if bIsBottom  then
            RunScrollNextTick(self, listHelper)
            self.pWidgetRef.ovlNewsFriend:SetVisibility(Collapsed)
        else
            self.bNewMsgTipShow = true
            self.pWidgetRef.ovlNewsFriend:SetVisibility(Visible)
            self.nNewMsgCount = self.nNewMsgCount + 1
            local l10nTemp = UISetUtils.GetL10NTextByKey("LOBBYCHAT_NEW_MSG")
            self.pWidgetRef.ktxtNewFriendMsg:SetText(L10N:Format(l10nTemp, self.nNewMsgCount))
        end
    end)
end



--View操作
function UILobbyChat:RestNewMsgTip()
    self.pWidgetRef.ovlNews:SetVisibility(Collapsed)
    self.pWidgetRef.ovlNewsFriend:SetVisibility(Collapsed)
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
    if eChannel == CHAT_TEAM_INVITE then
        local ListHelper = self.TeamInviteListHelper
        ListHelper:RequestListRefresh()
        RunScrollNextTick(self, ListHelper)
    end
    if self.eCurrentChannel ~= eChannel then
        -- if eChannel == CHAT_FRIEND and not bFriendRecord then
        --     self.TabBarHelper:SetTipIconVisible(3, true)
        -- end
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

        if bSelf then
            self:RefreshFriendChatList(nIndex, nFriendId, szFriendName, true)
        elseif nPlayerId == self.nLastFriendId then
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
    assert(self.tbViewParams, "[UI] UILobbyChat, AddViewParam, tbViewParams is nil")
    local tbShowWidgets = { ... }
    local tbTemp = {}
    tbTemp.tbWidgets = tbShowWidgets
    tbTemp.ListHelper = ListHelper
    tbTemp.Hide = function() SetWidgetVisible(tbTemp.tbWidgets, Collapsed) end
    tbTemp.Show = function() SetWidgetVisible(tbTemp.tbWidgets, Visible) end
    self.tbViewParams[eChannel] = tbTemp
end

local function InitViews(self)
    local pWidgetRef = self.pWidgetRef
    self.CommonListHelper = SelfVerticalListHelper()
    self.CommonListHelper:Init(self, pWidgetRef.commonList)
    self.FriendListHelper = SelfVerticalListHelper()
    self.FriendListHelper:Init(self, pWidgetRef.friendList)
    self.FriendChatListHelper = SelfVerticalListHelper()
    self.FriendChatListHelper:Init(self, pWidgetRef.friendChatList)
    self.ExpressionListHelper = SelfVerticalListHelper()
    self.ExpressionListHelper:Init(self, pWidgetRef.expressionList)
    self.TeamInviteListHelper = SelfVerticalListHelper()
    self.TeamInviteListHelper:Init(self, pWidgetRef.vlTeamInvite)

    AddViewParam(self, CHAT_WORLD, self.CommonListHelper, pWidgetRef.commonList, pWidgetRef.vbTeaming, pWidgetRef.imgCuttingLine)
    AddViewParam(self, CHAT_FRIEND, self.FriendChatListHelper, pWidgetRef.hboxFriend, pWidgetRef.vbTeaming, pWidgetRef.imgCuttingLine, pWidgetRef.hboxFriendInfo)
    AddViewParam(self, CHAT_TEAM, self.CommonListHelper, pWidgetRef.commonList, pWidgetRef.vbTeaming, pWidgetRef.imgCuttingLine)
    AddViewParam(self, CHAT_SYSTEM, self.CommonListHelper, pWidgetRef.commonList, pWidgetRef.vbTeaming, pWidgetRef.imgCuttingLine)
    AddViewParam(self, CHAT_CORPS, self.CommonListHelper, pWidgetRef.commonList, pWidgetRef.vbTeaming, pWidgetRef.imgCuttingLine)
    AddViewParam(self, CHAT_TEAM_INVITE, self.TeamInviteListHelper, pWidgetRef.vbTeaming)
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

local function GetFriendsCount(self)
    local nFriendsCount = 0
    local FriendComponent = FriendSystem:GetComponent()
    if not FriendComponent then
        return nFriendsCount
    end
    local tbFriends = FriendComponent:GetFriends()
    nFriendsCount = not tbFriends and 0 or #tbFriends
    return nFriendsCount
end

local function ShowFriendListWidget(self, bShow)
    local nFriendsCount = GetFriendsCount(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.vboxChatToFirendTag:SetVisibility((bShow or nFriendsCount <= 0) and Collapsed or Visible)
    pWidgetRef.hboxFriendInfo:SetVisibility(bShow and Visible or Collapsed)
    pWidgetRef.btnFriend:SetVisibility(bShow and Visible or Collapsed)
    pWidgetRef.imgFriendlist1:SetVisibility(bShow and Visible or Collapsed)
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
    local tbFriends = FriendComponent:GetFriendSummaries()
    local FriendListHelper = self.FriendListHelper
    if not tbFriends then
        ResetFriendChatView(self)
        return
    end
    --刷新某个玩家并显示
    if nPlayerId then
        for nIndex, tbFriend in pairs(tbFriends) do
            if tbFriend.id == nPlayerId then
                self.nLastFriendId = nPlayerId
                self.nLastFriendIndex = nIndex
                self.szLastFriendName = tbFriend.name
                break
            end
        end
    end

    SetFriendUnreadMsgCount(tbFriends)

    self.tbFriendListData = tbFriends
    FriendListHelper:SetData(tbFriends)

    local nfriendCount = #tbFriends
    local nOnlineCount = GetOnlineFriend(tbFriends)
    pWidgetRef.ktxtFriendCount:SetText(string.format( "%d/%d",nOnlineCount, nfriendCount))
    pWidgetRef.vbHaveNoFriend:SetVisibility(nfriendCount == 0 and Visible or Collapsed)
    --pWidgetRef.vboxChatToFirendTag:SetVisibility(nfriendCount == 0 and Collapsed or Visible)
    pWidgetRef.vboxChatToFirendTag:SetVisibility(self.nLastFriendIndex and Collapsed or Visible)
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
    self:RefreshFriendChatList(self.nLastFriendIndex, self.nLastFriendId, self.szLastFriendName, true)
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

local function OnPlayerInfoExitCallBack(nPlayerId)
    local tbArgs = {}
    tbArgs.eChannel = LobbyChatSystem.CHAT_FRIEND
    tbArgs.nFriendId = nPlayerId
    UIManager:OpenWnd(UIDef.UI_LOBBY_CHAT, tbArgs)
end

local function ShowPlayerInfo(self)
    local nPlayerId = self.nLastFriendId
    self:CloseSelf()
    UIManager:OpenWnd(UIDef.UI_PLAYER_INFO, {nPlayerId = nPlayerId, callOnExit = function() OnPlayerInfoExitCallBack(nPlayerId) end})
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

local function OnChanelTabSelected(self, nSelectIndex)
    local eChannel = self.tbIndexToChannel[nSelectIndex]
    if eChannel then
        SelectTabByeChannel(self, eChannel)
    end
end

function UILobbyChat:RefreshFriendChatList(nIndex, nFriendId, szFriendName, bForceRefreshToBottom)
    -- logerror("=======RefreshFriendChatList==========" .. debug.traceback())
    local pWidgetRef = self.pWidgetRef
    local ListHelper = self.FriendChatListHelper
    if self.eCurrentChannel ~= CHAT_FRIEND then
        return
    end
    if nFriendId == nil then
        ListHelper.pListRef:SetVisibility(Collapsed)
        return
    end
    local bSelectOther = self.nLastFriendIndex ~= nIndex
    if bSelectOther or bForceRefreshToBottom then
        self:RestNewMsgTip()
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
        if bSelectOther or bForceRefreshToBottom then
            RunScrollNextTick(self, ListHelper)
            self.pWidgetRef.ovlNewsFriend:SetVisibility(Collapsed)
        else
            RunCheckNewMsgTipNextTick(self, ListHelper)
        end
        -- RunScrollNextTick(self, ListHelper)
    else
        ListHelper.pListRef:SetVisibility(Collapsed)
    end
end

function UILobbyChat:ShowViewByChannel(eChannel, tbParams)
    -- if eChannel == CHAT_FRIEND then
    --     self.TabBarHelper:SetTipIconVisible(3, false)
    -- end
    local tblistData = LobbyChatSystem:GetHistory(eChannel)
    if eChannel == CHAT_FRIEND then
        RefreshFriendView(self)
    else
        tbParams.ListHelper:SetData(tblistData)
        RunScrollNextTick(self, tbParams.ListHelper)
    end
end

function UILobbyChat:OnShow()
    self:Activate(self.tbOpenArgs)
end

function UILobbyChat:Activate(tbOpenArgs)
    local eChannel = tbOpenArgs.eChannel
    if eChannel == CHAT_TEAM_INVITE then
        eChannel = CHAT_WORLD
    end
    if eChannel then
        self.nLasteChannel = eChannel
    end
    self.pWidgetRef:SetVisibility(Visible)
    EventManager:OnFireEvent(ClientEventDef.EV_UI_GUIDE_ON_SHOW_CHAT, true)
    self:PlayAnimation(CHAT_ANIM_NAME, 0, 1, EUMGSequencePlayMode.Forward, 1)
    MockTabClickByeChannel(self, self.nLasteChannel)
    local tblistData = LobbyChatSystem:GetHistory(CHAT_TEAM_INVITE)
    local TeamInviteListHelper = self.TeamInviteListHelper
    TeamInviteListHelper:SetData(tblistData)
    RunScrollNextTick(self, TeamInviteListHelper)
    if eChannel == CHAT_FRIEND then
        local nFriendId = tbOpenArgs.nFriendId
        RefreshFriendView(self, nFriendId)
    end
    RefreshTeamTab(self)
end

function UILobbyChat:GetChannelIndex(eChannel)
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

function UILobbyChat:Deactivate()
    EventManager:OnFireEvent(ClientEventDef.EV_CHAT_CLOSE_BTNLIST)
    self.pWidgetRef:SetVisibility(Collapsed)
    EventManager:OnFireEvent(ClientEventDef.EV_UI_GUIDE_ON_SHOW_CHAT, false)
end

function UILobbyChat:OnLoad()
    self.super.OnLoad(self)
    self.tbViewParams = {}
    self.tbIndexToChannel = {}
    self.tbTabBtns = {}
    local pWidgetRef = self.pWidgetRef
    self.PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.ulLobbyTopMsg = self.UILogicHelper:CreateUILogic("ULLobbyTopMsg")
    LobbyChatSystem.pButtonList = self.PrefabHelper:BindPrefab(pWidgetRef.upButtonListContent)
    InitTabBtns(self)
    InitViews(self)
    InitInputBar(self)
    InitExpression(self)
    --pWidgetRef.chkFirght:SetVisibility(Collapsed)
    self.tbTabBarHelper:SetVisibilityByIndex(CORPS_TAB_INDEX, Collapsed)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnChanelTabSelected, self)
end

function UILobbyChat:OnUnload()
    self.super.OnUnload()
    self.tbViewParams = nil
    self.tbIndexToChannel = nil
    self.CommonListHelper:Uninit()
    self.FriendListHelper:Uninit()
    self.FriendChatListHelper:Uninit()
    self.ExpressionListHelper:Uninit()
    self.TeamInviteListHelper:Uninit()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

function UILobbyChat:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_LOBBY_CHAT,                self, self.Activate)
    EventHelper:RegisterEvent(ClientEventDef.EV_RECEIVE_CHAT_MESSAGE,           self, OnRecieveMsg)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLICK_EXPRESSION,               self, OnClickExpression)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS,             self, RefreshFriendList)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHAT_CLICK_FRIEND,              self, self.RefreshFriendChatList)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHAT_SEND_FAILED,               self, OnSendFailed)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED,                   self, RefreshTeamTab)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_SYNC,                      self, RefreshTeamTab)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT,  self, OnItemChanged)
    -- EventHelper:RegisterEvent(ClientEventDef.TEST_TEST_TEST,                    self, MockTabClickByeChannel)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked,              self, OnBtnClose)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTeaming.OnClicked,            self, OnBtnTeaming)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSend.OnClicked,               self, OnBtnSend)
    EventHelper:RegisterCppDelegate(pWidgetRef.chkFace.OnCheckStateChanged,     self, ShowExpressions)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGoToNewMsg.OnClicked,         self, GoToNewMsg)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGoToNewFriendMsg.OnClicked,   self, GoToNewMsg)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnVoiceOpen.OnClicked,          self, OnVoiceBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFriend.OnClicked,             self, OnBtnFriendClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtChatContent.OnTextChanged,    self, OnInputTextChange)
    EventHelper:RegisterCppDelegate(pWidgetRef.commonlist.OnListViewScrolled,   self, OnListViewScrolled)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnHorn.OnClicked,               self, OnHornBtnClick)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBigHorn.OnClicked,            self, OnBigHornBtnClick)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCloseExpression.OnClicked,    self, OnCloseExpressionClicked)
end

return UILobbyChat