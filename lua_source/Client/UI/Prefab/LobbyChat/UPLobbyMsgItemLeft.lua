-----------------------------------------------------
--File Name    : UPLobbyMsgItemLeft.lua
--Author       : Edward J
--Create Time  : 2018-04-16
--Description  : UPLobbyMsgItemLeft
-----------------------------------------------------
local luaclass              = require("luaclass")
local UPLobbyMsgItemBase    = require("UPLobbyMsgItemBase")
local UPLobbyMsgItemLeft    = luaclass("UPLobbyMsgItemLeft", UPLobbyMsgItemBase)

local UIUtils               = require("UIUtils")
local LobbyChatSystem       = require("LobbyChatSystem")
local UIManager             = require("UIManager")
local UIDef                 = require("UIDef")
local FriendSystem          = require("FriendSystem")
-- local PlayerInfoSystem      = require("PlayerInfoSystem")
local ClientEventDef        = require("ClientEventDef")
local TeamSystem            = require("TeamSystem")
local UISetUtils            = require("UISetUtils")
local Proto                 = require("ClientProtoNames")
local L10N                  = require("L10N")
-----------------------------------------------------
local EMsgType_Teaming      = LobbyChatSystem.EMsgType_Teaming
local BTN_INFO              = 1
local BTN_FRIEND            = 2
local BTN_TEAMING           = 3
local BTN_BLOCK             = 4
local BTN_REPORT            = 5

UPLobbyMsgItemLeft.FriendComponent      = nil
UPLobbyMsgItemLeft.pCommonListScript    = nil
-- UPLobbyMsgItemLeft.bIsFriend            = false
UPLobbyMsgItemLeft.tbBasicInfoEvent     = false
-----------------------------------------------------

local function ReportPlayer(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 0.2)
end

local function BlockPlayer(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 0.2)
end

local function InvitePlayer(self, nPlayerId, bIsFriend)
    -- local nPlayerId = self.tbBasicInfo.nPlayerId
    local Invite_From = bIsFriend and LobbyChatSystem.FROM_FRIEND or LobbyChatSystem.FROM_CHAT
    TeamSystem:RequestInvitePlayer(nPlayerId, Invite_From)
end

local function ApplyJoin(self, nPlayerId)
    -- local nPlayerId = self.tbBasicInfo.nPlayerId
    TeamSystem:RequestApplyJoin(nPlayerId)
end

local function AddFriend(self, nPlayerId)
    -- local nPlayerId = self.tbBasicInfo.nPlayerId
    local szApplyMsg = L10N:ToString(UISetUtils.GetL10NTextByKey("FFA_APPLYFRIEND_MESSAGE"))
    FriendSystem:RequestApplyFriend(nPlayerId, szApplyMsg, Proto.FriendSource.CHATTING)
end

local function OnPlayerInfoExitCallBack(eChannel)
    local tbArgs = {}
    tbArgs.eChannel = eChannel
    UIManager:OpenWnd(UIDef.UI_LOBBY_CHAT, tbArgs)
end

local function ShowPlayerInfo(self, nPlayerId)
    -- local nPlayerId = self.tbBasicInfo.nPlayerId
    local Owner = self.Owner
    Owner:CloseSelf()
    local eCurrentChannel = Owner.eCurrentChannel
    eCurrentChannel = eCurrentChannel == nil and LobbyChatSystem.CHAT_WORLD or eCurrentChannel
    UIManager:OpenWnd(UIDef.UI_PLAYER_INFO, {nPlayerId = nPlayerId, callOnExit = function() OnPlayerInfoExitCallBack(eCurrentChannel) end})
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

local function OnRecievePlayerHeadBasicInfo(self, tbData)
    local nPlayerId = self.tbBasicInfo.nPlayerId
    if tbData.nPlayerId ~= nPlayerId then
        return
    end
    local tbFriend = self.FriendComponent:GetFriend(nPlayerId)
    local bIsFriend = tbFriend and true or false
    local nTeamSize = tbData.nTeamSize
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
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_REFRESH_PLAYER_BASEINFO, self, OnRecievePlayerHeadBasicInfo)
    self.tbBasicInfoEvent = nil
end


local function OnClickPlayHead(self)
    local pHeadRef = self.pPlayHeadScript.pWidgetRef
    local eMsgType = tonumber(self.tbContentData[1])
    local nPlayerId = self.tbBasicInfo.nPlayerId
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

    local pBtnTeaming = pCommonListScript:GetButton(BTN_TEAMING)
    pBtnTeaming:SetVisible(false)

    if eMsgType == EMsgType_Teaming then
        log("Hide Report Btn!")
        -- local pBtnScript = pCommonListScript:GetButton(BTN_REPORT)
        -- pBtnScript:SetVisible(false)
    end
    -- self.bIsFriend = tbFriend and true or false
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
        if not self.tbBasicInfoEvent then
            self.tbBasicInfoEvent = self.EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_PLAYER_BASEINFO, self, OnRecievePlayerHeadBasicInfo)
        end
        LobbyChatSystem:GetPlayerBaseInfoFromServer(nPlayerId)
    end

end

function UPLobbyMsgItemLeft:OnTeamingBtnClicked()
    self.super.OnTeamingBtnClicked(self)
end

function UPLobbyMsgItemLeft:BindHeadBtn()
    self.pPlayHeadScript:BindHeadBtnOnClicked(function () OnClickPlayHead(self) end)
end

function UPLobbyMsgItemLeft:SetData(tbData)
    self.super.SetData(self, tbData)
end

function UPLobbyMsgItemLeft:OnLoad()
    self.super.OnLoad(self)
    self.FriendComponent = FriendSystem:GetComponent()
end

function UPLobbyMsgItemLeft:OnBindEvent(EventHelper)
    self.super.OnBindEvent(self, EventHelper)
end

return UPLobbyMsgItemLeft