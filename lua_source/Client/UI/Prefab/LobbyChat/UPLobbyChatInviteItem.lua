-----------------------------------------------------
--File Name    : UPLobbyChatInviteItem.lua
--Author       : Edward J
--Create Time  : 2020-05-26
--Description  : UPLobbyChatInviteItem
-----------------------------------------------------
local luaclass                      = require("luaclass")
local ListItemBase                  = require("ListItemBase")
local UPLobbyChatInviteItem         = luaclass("UPLobbyChatInviteItem", ListItemBase)

local AvatarDataTable       = require("AvatarDataTable")
local UIResourceDef         = require("UIResourceDef")
local HumanDataTable        = require("HumanDataTable")
local GenderTypeDefine      = require("GenderTypeDefine")
local UISetUtils            = require("UISetUtils")
local LobbyChatSystem       = require("LobbyChatSystem")
local L10N                  = require("L10N")
local ClientEventDef        = require("ClientEventDef")
local TeamSystem            = require("TeamSystem")
local UIUtils               = require("UIUtils")
local RankDataTable         = require("RankDataTable")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local SeasonHelper          = require("SeasonHelper")
-- local PlayerInfoSystem      = require("PlayerInfoSystem")
local UIManager             = require("UIManager")
local UIDef                 = require("UIDef")
local FriendSystem          = require("FriendSystem")
local Proto                 = require("ClientProtoNames")
-----------------------------------------------------
local TEAM_FOUR_TAG = "4"
local BTN_INFO              = 1
local BTN_FRIEND            = 2
local BTN_TEAMING           = 3
local BTN_BLOCK             = 4
local BTN_REPORT            = 5

UPLobbyChatInviteItem.pPlayHeadScript      = nil
UPLobbyChatInviteItem.tbData               = nil
UPLobbyChatInviteItem.tbBasicInfo          = nil
UPLobbyChatInviteItem.tbContentData        = nil
UPLobbyChatInviteItem.tbSummaryEventHandler= false
UPLobbyChatInviteItem.FriendComponent      = nil
UPLobbyChatInviteItem.tbBasicInfoEvent     = nil

-----------------------------------------------------
local RANK_SUB_MAX = 5

local function OnPlayerInfoExitCallBack(eChannel)
    local tbArgs = {}
    tbArgs.eChannel = eChannel
    UIManager:OpenWnd(UIDef.UI_LOBBY_CHAT, tbArgs)
end

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

local function OnRecievePlayerHeadBasicInfo(self, tbBasicInfo)
    local nPlayerId = self.tbBasicInfo.nPlayerId
    if tbBasicInfo.nPlayerId ~= nPlayerId then
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
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_REFRESH_PLAYER_BASEINFO, self, OnRecievePlayerHeadBasicInfo)
    self.tbBasicInfoEvent = nil
end

local function TransformationSubRank(nSubRank)
    if nSubRank == 0 then
        return nSubRank
    else
        return RANK_SUB_MAX - nSubRank + 1
    end
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

local function RefreshRnakInfo(self, nPlayerRank)
    local pWidgetRef = self.pWidgetRef
    local tbRankData = RankDataTable:GetTemplate(nPlayerRank)
    if not tbRankData then
        return
    end
    local nRankImgIndex = math.modf(nPlayerRank / 10)
    nRankImgIndex = TransformationSubRank(nRankImgIndex)
    -- local l10nSubRank = UISetUtils.GetL10NTextByKey("SEASON_RANK_"..nRankImgIndex)
    local szRankName = L10N:ToString(tbRankData.l10nName)..tbRankData.szRankLevelName
    pWidgetRef.ktxtRank:SetText(szRankName)
    local szRankImg, szRankNumImg = SeasonHelper.GetIcon(nPlayerRank)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRank, szRankImg:load())
    if szRankNumImg ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgRankNumber, szRankNumImg:load())
    else
        pWidgetRef.imgRankNumber:SetVisibility(ESlateVisibility_Collapsed)
    end
end

local function RefreshPlayerBasicInfo(self, tbBasicInfo)
    local tbData = self.tbData
    if not tbData then
        return
    end
    log("[UPLobbyChatInviteItem] RefreshPlayerBasicInfo")
    self.tbBasicInfo = tbBasicInfo
    local nPlayerId = tbBasicInfo.nPlayerId
    local nTargetPlayerId = tbData.nSenderId
    if nPlayerId ~= nTargetPlayerId then
        return
    end
    log("[UPLobbyChatInviteItem] RefreshPlayerBasicInfo Set Data")
    local nAvatarId = tbBasicInfo.nAvatarId
    local nLevel = tbBasicInfo.nLevel
    local nPlayerRank = tbBasicInfo.nRank
    local szName = tbBasicInfo.szName
    RefreshRnakInfo(self, nPlayerRank)
    self:RefreshPlayerHeadInfo(nPlayerId, nAvatarId, nLevel)
    self:RefreshPlayerBaseInfo(szName, nAvatarId, nPlayerRank)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_REFRESH_PLAYER_BASEINFO, self, RefreshPlayerBasicInfo)
    self.tbSummaryEventHandler = nil
end

local function RequestBasicInfo(self, nPlayerId)
    local tbBasicInfo = LobbyChatSystem:GetPlayerBaseInfo(nPlayerId)
    if tbBasicInfo then
        RefreshPlayerBasicInfo(self, tbBasicInfo)
    else
        if not self.tbSummaryEventHandler then
            log("[UPLobbyChatInviteItem] RequestBasicInfo RegisterEvent")
            self.tbSummaryEventHandler = self.EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_PLAYER_BASEINFO, self, RefreshPlayerBasicInfo)
        end
    end
end

function UPLobbyChatInviteItem:OnTeamingBtnClicked()
    local tbData = self.tbData
    if not tbData then
        return
    end
    local nSenderId = tbData.nSenderId
    local nTime = tbData.nTime
    local tbContentData = self.tbContentData
    local nPlayerId = tonumber(tbContentData[5])
    local nTeamId = tbContentData[6]
    local nSelfPlayerId =  GlobalVariableSystem.nSelfLobbyPlayerId
    if nTeamId == LobbyChatSystem.INVALID_TEAM_ID then
        nTeamId = nil
    end
    if LobbyChatSystem:IsLatest(nSenderId, nTime) then
        if TeamSystem:IsInTeam() then
            if TeamSystem:GetTeamMemberData(nPlayerId) then
                UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBYCHAT_ALREADY_IN_TEAM"), 0.2)
            else
                UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBYCHAT_IN_OTHER_TEAM"), 0.2)
            end
        else
            if nSelfPlayerId == nSenderId then
                UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBYCHAT_ALREADY_IN_TEAM"), 0.2)
            else
                TeamSystem:ReplyRecruitTeammate(nPlayerId)
            end
        end
    else
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAM_INVITE_INVALILD"))
    end
end

local function OnClickPlayHead(self)
    local tbData = self.tbData
    if not tbData then
        return
    end
    local pHeadRef = self.pPlayHeadScript.pWidgetRef
    local nPlayerId = tbData.nSenderId
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

local function SetPlayerName(self, szName)
    self.pWidgetRef.txtName:SetText(szName)
end

function UPLobbyChatInviteItem:BindHeadBtn()
    self.pPlayHeadScript:BindHeadBtnOnClicked(function () OnClickPlayHead(self) end)
end

function UPLobbyChatInviteItem:RefreshPlayerHeadInfo(nPlayerId, nAvatarId, nLevel)
    local tbData = self.tbData
    if not tbData then
        return
    end
    local pPlayHead = self.pPlayHeadScript
    pPlayHead:SetPlayerId(nPlayerId)
    pPlayHead:SetPlayerHead(nAvatarId, nLevel)
    self:BindHeadBtn()
end

function UPLobbyChatInviteItem:RefreshPlayerBaseInfo(szName, nAvatarId, nPlayerRank)
    local tbData = self.tbData
    if not tbData then
        return
    end
    local pWidgetRef = self.pWidgetRef
    SetPlayerName(self, szName)
    local szGender = GetGenderRes(nAvatarId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGender:load(), true)
end

local function SetTeamingMsg(self)
    local pWidgetRef = self.pWidgetRef
    local tbContentData = self.tbContentData
    local szToatalCount = tbContentData[3]
    local szCurrentCount = tbContentData[4]
    local szCurrentInfo = string.format( "%s/%s", szCurrentCount, szToatalCount)
    local szModeType = szToatalCount == TEAM_FOUR_TAG and UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAMINGMODE_FOUR") or UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAMINGMODE_TOW")
    local l10NTextMsg = L10N:Format(UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAMINGTEMPLATE_NEW"), L10N:ToString(szModeType), szCurrentInfo)
    pWidgetRef.txtStatus:SetText(l10NTextMsg)
end

function UPLobbyChatInviteItem:OnRefresh(tbData)
    if not tbData then
        return
    end
    self.tbData = tbData
    local nPlayerId = tbData.nSenderId
    local szContent = tbData.szContent
    self.tbContentData = LobbyChatSystem:UnpackContent(szContent)
    SetPlayerName(self, tbData.szName)
    SetTeamingMsg(self)
    RequestBasicInfo(self, nPlayerId)
end

function UPLobbyChatInviteItem:OnLoad()
    self.tbShowWidget = {}
    local pWidgetRef = self.pWidgetRef
    self.pPlayHeadScript = self.PrefabHelper:BindPrefab(pWidgetRef.pbPlayerHead)
    self.FriendComponent = FriendSystem:GetComponent()
end

function UPLobbyChatInviteItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClick.OnClicked, self, self.OnTeamingBtnClicked)
end

return UPLobbyChatInviteItem