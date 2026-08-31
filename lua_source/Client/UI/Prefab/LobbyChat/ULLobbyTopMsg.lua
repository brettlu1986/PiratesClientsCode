-----------------------------------------------------
--File Name    : ULLobbyTopMsg.lua
--Author       : Edward J
--Create Time  : 2019-10-25
--Description  : ULLobbyTopMsg
-----------------------------------------------------
local luaclass          = require("luaclass")
local UILogicBase       = require("UILogicBase")
local ULLobbyTopMsg     = luaclass("ULLobbyTopMsg", UILogicBase)

local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local ClientEventDef    = require("ClientEventDef")
local LobbyChatSystem   = require("LobbyChatSystem")
local UIResourceDef     = require("UIResourceDef")
local UISetUtils        = require("UISetUtils")
local AvatarDataTable   = require("AvatarDataTable")
local HumanDataTable    = require("HumanDataTable")
local GenderTypeDefine  = require("GenderTypeDefine")
local UIUtils           = require("UIUtils")
local TeamSystem        = require("TeamSystem")
local FriendSystem      = require("FriendSystem")
local L10N              = require("L10N")
local UIManager         = require("UIManager")
local UIDef             = require("UIDef")
local Proto             = require("ClientProtoNames")
local SeasonHelper      = require("SeasonHelper")
-----------------------------------------------------
-- local SHOW_INTERVAL                 = ChatIni.tbHorn.nInterval
local Collapsed                     = ESlateVisibility.Collapsed
local Visible                       = ESlateVisibility.Visible
local BTN_INFO                      = 1
local BTN_FRIEND                    = 2
local BTN_TEAMING                   = 3
local BTN_BLOCK                     = 4
local BTN_REPORT                    = 5

-- ULLobbyTopMsg.tbMsgs                = nil
-- ULLobbyTopMsg.DelayTimerHandler     = nil
ULLobbyTopMsg.nCurrentPlayerId      = nil
ULLobbyTopMsg.pBaseWidget           = nil
ULLobbyTopMsg.bInShow               = nil
ULLobbyTopMsg.pPlayHeadScript       = nil
ULLobbyTopMsg.tbData                = nil
ULLobbyTopMsg.FriendComponent       = nil
ULLobbyTopMsg.pCommonListScript     = nil
ULLobbyTopMsg.bClickHead            = nil
-----------------------------------------------------
-- local function CloseDelayTimer(self)
--     local DelayTimerHandler = self.DelayTimerHandler
--     if DelayTimerHandler then
--         DelayTimer:ClearTimer(DelayTimerHandler)
--     end
--     self.DelayTimerHandler = nil
-- end

local function ReportPlayer(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 0.2)
end

local function BlockPlayer(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 0.2)
end

local function ApplyJoin(self, nPlayerId)
    TeamSystem:RequestApplyJoin(nPlayerId)
end

local function AddFriend(self, nPlayerId)
    local szApplyMsg = L10N:ToString(UISetUtils.GetL10NTextByKey("FFA_APPLYFRIEND_MESSAGE"))
    FriendSystem:RequestApplyFriend(nPlayerId, szApplyMsg, Proto.FriendSource.CHATTING)
end

local function OnPlayerInfoExitCallBack(eChannel)
    local tbArgs = {}
    tbArgs.eChannel = eChannel
    UIManager:OpenWnd(UIDef.UI_LOBBY_CHAT, tbArgs)
end

local function ShowPlayerInfo(self, nPlayerId)
    local Owner = self.Owner
    Owner:CloseSelf()
    local eCurrentChannel = Owner.eCurrentChannel
    eCurrentChannel = eCurrentChannel == nil and LobbyChatSystem.CHAT_WORLD or eCurrentChannel
    UIManager:OpenWnd(UIDef.UI_PLAYER_INFO, {nPlayerId = nPlayerId, callOnExit = function() OnPlayerInfoExitCallBack(eCurrentChannel) end})
end

local function InvitePlayer(self, nPlayerId, bIsFriend)
    local Invite_From = bIsFriend and LobbyChatSystem.FROM_FRIEND or LobbyChatSystem.FROM_CHAT
    TeamSystem:RequestInvitePlayer(nPlayerId, Invite_From)
end

local function OnBtnCallBack(self, btnType, nPlayerId)
    if btnType == BTN_INFO then
        ShowPlayerInfo(self, nPlayerId)
    elseif btnType == BTN_FRIEND then
        AddFriend(self, nPlayerId)
    elseif btnType == BTN_TEAMING then
        ApplyJoin(self, nPlayerId)
    elseif btnType == BTN_BLOCK then
        BlockPlayer(self, nPlayerId)
    elseif btnType == BTN_REPORT then
        ReportPlayer(self, nPlayerId)
    end
end

local function OnRecievePlayerHeadBasicInfo(self, tbBasicInfo)
    local nPlayerId = self.nCurrentPlayerId
    if tbBasicInfo.nPlayerId ~= nPlayerId or not self.bClickHead then
        return
    end
    local tbFriend = self.FriendComponent:GetFriend(nPlayerId)
    local bIsFriend = tbFriend and true or false
    local nTeamSize = tbBasicInfo.nTeamSize
    local szText = ""
    local pFunc = nil
    local pBtnScript = self.pCommonListScript:GetButton(BTN_TEAMING)
    if nTeamSize > 0 then
        szText = UISetUtils.GetL10NTextByKey("UIPLAYERTIPS_L10N_APPLYJOINTEAM")
        pFunc = function () end
    else
        szText = UISetUtils.GetL10NTextByKey("UIPLAYERTIPS_L10N_INVITECREATETEAM")
        pFunc = function () InvitePlayer(self, nPlayerId, bIsFriend) end
        pBtnScript:SetFunc(pFunc)
    end
    pBtnScript:SetText(szText)
    pBtnScript:SetVisible(true)
    self.bClickHead = false
end

local function OnClickPlayHead(self)
    local pHeadRef = self.pPlayHeadScript.pWidgetRef
    local nPlayerId = self.nCurrentPlayerId
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf.nPlayerId == nPlayerId then
        return
    end 
    local tbFriend = self.FriendComponent:GetFriend(nPlayerId)
    local tbMemberData = TeamSystem:GetTeamMemberData(nPlayerId)
    local tbArgs = {}
    UIUtils.AddCommonBtnListArgs(tbArgs, nil, UISetUtils.GetL10NTextByKey("UIPLAYERINFO"), nil, function() OnBtnCallBack(self, BTN_INFO, nPlayerId) end)
    UIUtils.AddCommonBtnListArgs(tbArgs, nil, UISetUtils.GetL10NTextByKey("LOBBY_TEAM_ADD_FRIEND"), nil, function() OnBtnCallBack(self, BTN_FRIEND, nPlayerId) end)
    UIUtils.AddCommonBtnListArgs(tbArgs, nil, UISetUtils.GetL10NTextByKey("UIPLAYERTIPS_L10N_APPLYJOINTEAM"), nil, function() OnBtnCallBack(self, BTN_TEAMING, nPlayerId) end)
    -- UIUtils.AddCommonBtnListArgs(tbArgs, nil, UISetUtils.GetL10NTextByKey("UIBLOCKPLAYER"), nil, function() OnBtnCallBack(self, BTN_BLOCK, nPlayerId) end)
    -- UIUtils.AddCommonBtnListArgs(tbArgs, nil, UISetUtils.GetL10NTextByKey("UIREPORTPLAYER"), nil, function() OnBtnCallBack(self, BTN_REPORT, nPlayerId) end)
    local pCommonListScript = LobbyChatSystem.pButtonList:CreateBtnsList(pHeadRef, {tbBtnsArg = tbArgs})
    self.pCommonListScript = pCommonListScript
    if tbFriend then
        local pBtnScript = pCommonListScript:GetButton(BTN_FRIEND)
        if pBtnScript then
            pBtnScript:SetVisible(false)
        end
    end
    if tbMemberData then
        local pBtnScript = pCommonListScript:GetButton(BTN_TEAMING)
        if pBtnScript then
            pBtnScript:SetVisible(false)
        end
    else
        LobbyChatSystem:GetPlayerBaseInfoFromServer(nPlayerId)
    end
    self.bClickHead = true
end

local function GetGenderRes(nAvatarId)
    local tbAvatarData = AvatarDataTable:GetTemplate(nAvatarId)
    if tbAvatarData == nil then
        return UIResourceDef.GENDER_MALE
    end
    local tbHumanData = HumanDataTable:GetTemplate(tbAvatarData.nHumanId)
    if tbHumanData == nil then
        return UIResourceDef.GENDER_MALE
    end
    return tbHumanData.nGender == GenderTypeDefine.MALE and UIResourceDef.GENDER_MALE or UIResourceDef.GENDER_FEMALE
end

local function RefreshPlayerHeadInfo(self, nAvatarId, nLevel)
    local pPlayHead = self.pPlayHeadScript
    local nPlayerId = self.nCurrentPlayerId
    pPlayHead:SetPlayerId(nPlayerId)
    pPlayHead:SetPlayerHead(nAvatarId, nLevel)
    pPlayHead:BindHeadBtnOnClicked(function () OnClickPlayHead(self) end)
end

local function RefreshPlayerBaseInfo(self, nAvatarId, nRank, bBattlePassActive)
    local pWidgetRef = self.pWidgetRef
    local szGender = GetGenderRes(nAvatarId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgTopMsgGender, szGender:load(), true)
    local szRankImg, szRankNumImg = SeasonHelper.GetIcon(nRank)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgTopMsgRank, szRankImg:load())
    if szRankNumImg ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgRankNum, szRankNumImg:load())
    else
        pWidgetRef.imgRankNum:SetVisibility(ESlateVisibility_Collapsed)
    end
end

local function RefreshPlayerBasicInfo(self, tbBasicInfo)
    OnRecievePlayerHeadBasicInfo(self, tbBasicInfo)
    local nPlayerId = tbBasicInfo.nPlayerId
    if nPlayerId ~= self.nCurrentPlayerId then
        return
    end
    local nTargetPlayerId = self.nCurrentPlayerId
    if nPlayerId ~= nTargetPlayerId then
        return
    end
    local nAvatarId = tbBasicInfo.nAvatarId
    local nLevel = tbBasicInfo.nLevel
    local nRank = tbBasicInfo.nRank
    local bBattlePassActive = tbBasicInfo.bBattlePassActive
    RefreshPlayerHeadInfo(self, nAvatarId, nLevel)
    RefreshPlayerBaseInfo(self, nAvatarId, nRank, bBattlePassActive)
end

local function RequestBasicInfo(self, nPlayerId)
    local tbBasicInfo = LobbyChatSystem:GetPlayerBaseInfo(nPlayerId)
    if tbBasicInfo then
        RefreshPlayerBasicInfo(self, tbBasicInfo)
    end
end

-- local function OnRecieveTopMsg(self, tbMsg)
--     self:AddMsg(tbMsg)
--     UIUtils.ShowTopMsgNotifaction(tbMsg)
--     if not self.bInShow then
--         self:ShowTopMsg()
--     end
-- end

local function OnDeactiveTopMsg(self)
    self:HideTopMsg()
end

local function RecoverTopMsgState(self)
    local Wnd = UIManager:GetWnd(UIDef.UI_TOPMSGNOTIFACTION)
    if not Wnd then
        self:HideTopMsg()
        return
    end
    local tbCurrentMsg = Wnd:GetCurrentMsg()
    if tbCurrentMsg then
        self:ShowTopMsg(tbCurrentMsg)
    else
        self:HideTopMsg()
    end
end

function ULLobbyTopMsg:OnCreate()
    self.bInShow = false
end

function ULLobbyTopMsg:OnLoad()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrTopMsg:SetVisibility(Collapsed)
    self.pPlayHeadScript = self.PrefabHelper:BindPrefab(pWidgetRef.pbTopMsgPlayHead)
    self.FriendComponent = FriendSystem:GetComponent()
end

function ULLobbyTopMsg:OnUnload()
    -- CloseDelayTimer(self)
    self:HideTopMsg()
end

function ULLobbyTopMsg:OnShow()
    -- self.tbMsgs = {}
    RecoverTopMsgState(self)
end

function ULLobbyTopMsg:OnHide()
    -- self.tbMsgs = {}
    -- CloseDelayTimer(self)
    self:HideTopMsg()
end

function ULLobbyTopMsg:BindEvent()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_PLAYER_BASEINFO, self, RefreshPlayerBasicInfo)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_TOP_MSG, self, self.ShowTopMsg)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_DEACTIVE_TOP_MSG, self, OnDeactiveTopMsg)
    -- self.EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_PLAYER_BASEINFO, self, OnRecievePlayerHeadBasicInfo)
end

function ULLobbyTopMsg:ShowTopMsg(tbMsg)
    self.nCurrentPlayerId = nil
    -- local tbMsg = self:GetMsg()
    -- if not tbMsg then
    --     self.bInShow = false
    --     self:HideTopMsg()
    --     return
    -- end
    self.bInShow = true
    self:RefreshTopMsg(tbMsg)
    -- CloseDelayTimer(self)
    -- self.DelayTimerHandler = DelayTimer:DelayRun(function() self:ShowTopMsg() end, SHOW_INTERVAL)
end

-- function ULLobbyTopMsg:AddMsg(tbMsg)
--     table.insert(self.tbMsgs, tbMsg)
-- end

-- function ULLobbyTopMsg:GetMsg()
--     if not self.tbMsgs then
--         return nil
--     end
--     return table.remove(self.tbMsgs, 1)
-- end

function ULLobbyTopMsg:RefreshTopMsg(tbMsg)
    local Owner = self.Owner
    if Owner.eCurrentChannel ~= LobbyChatSystem.CHAT_WORLD then
        return
    end
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrTopMsg:SetVisibility(Visible)
    local nSenderId = tbMsg.nSenderId
    self.nCurrentPlayerId = nSenderId
    local szContent = tbMsg.szContent
    local szName = tbMsg.szName
    -- local eChannel = tbMsg.eChannel
    -- local bSelf = tbMsg.bSelf
    -- local nTime = tbMsg.nTime
    -- local nFlags = tbMsg.nFlags
    -- local tbContentData = LobbyChatSystem:UnpackContent(szContent)
    RequestBasicInfo(self, nSenderId)
    pWidgetRef.txtTopMsgContent:SetText(szContent)
    pWidgetRef.txtTopMsgPlayerName:SetText(szName)
end

function ULLobbyTopMsg:HideTopMsg()
    self.bInShow = false
    self.pWidgetRef.bdrTopMsg:SetVisibility(Collapsed)
end

return ULLobbyTopMsg