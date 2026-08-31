-----------------------------------------------------
--File Name    : UPLobbyMsgItemBase.lua
--Author       : Edward J
--Create Time  : 2018-04-16
--Description  : UPLobbyMsgItemBase
-----------------------------------------------------
local luaclass                  = require("luaclass")
local PrefabBase                = require("PrefabBase")
local UPLobbyMsgItemBase        = luaclass("UPLobbyMsgItemBase", PrefabBase)

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
local GlobalVariableSystem  = require("GlobalVariableSystem_C")
local SeasonHelper          = require("SeasonHelper")
-----------------------------------------------------
local CHAT_FRIEND       = LobbyChatSystem.CHAT_FRIEND
local EMsgType_Text     = LobbyChatSystem.EMsgType_Text
local EMsgType_Voice    = LobbyChatSystem.EMsgType_Voice
local EMsgType_Teaming  = LobbyChatSystem.EMsgType_Teaming
local Visible           = ESlateVisibility.Visible
local Collapsed         = ESlateVisibility.Collapsed

UPLobbyMsgItemBase.pPlayHeadScript      = nil
UPLobbyMsgItemBase.tbShowWidget         = nil
UPLobbyMsgItemBase.tbData               = nil
UPLobbyMsgItemBase.tbBasicInfo          = nil
UPLobbyMsgItemBase.tbContentData        = nil
UPLobbyMsgItemBase.CurrentDate          = nil
UPLobbyMsgItemBase.tbSummaryEventHandler= false
-----------------------------------------------------

local function AddShowWidgetParams(self, Key, ...)
    local tbHBox = self.tbShowWidget
    if not tbHBox then
        return
    end
    local tbWidgets = { ... }
    if not tbHBox[Key] then
        tbHBox[Key] = {}
    end
    tbHBox[Key] = tbWidgets
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

local function RefreshPlayerBasicInfo(self, tbBasicInfo)
    self.tbBasicInfo = tbBasicInfo
    local nPlayerId = tbBasicInfo.nPlayerId
    local nTargetPlayerId = self.tbData.nSenderId
    if nPlayerId ~= nTargetPlayerId then
        return
    end
    local nAvatarId = tbBasicInfo.nAvatarId
    local nLevel = tbBasicInfo.nLevel
    local nPlayerRank = tbBasicInfo.nRank
    local szName = tbBasicInfo.szName
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
            self.tbSummaryEventHandler = self.EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_PLAYER_BASEINFO, self, RefreshPlayerBasicInfo)
        end
    end
end

local function SetWidgetsVisible(tbWidgets, bVisible)
    assert(type(tbWidgets) == "table", "[UI] UPLobbyMsgItemBase SetWidgetsVisible tbWidgets is not a table!")
    for i, widget in ipairs(tbWidgets) do
        widget:SetVisibility(bVisible)
    end
end

local function HideAllMsgTypeWidget(self)
    local tbShowWidget = self.tbShowWidget
    assert(tbShowWidget, "[UI] UPLobbyMsgItemBase HideAllMsgTypeWidget tbShowWidget is nil!")
    for k, tbmsgType in pairs(tbShowWidget) do
        SetWidgetsVisible(tbmsgType, Collapsed)
    end
end

local function RefreshItemStyle(self, eMsgType)
    local tbShowWidget = self.tbShowWidget
    local tbWidgets = tbShowWidget[eMsgType]
    HideAllMsgTypeWidget(self)
    SetWidgetsVisible(tbWidgets, Visible)
end

local function SetTextMsg(self, pMsgRef, nFlags)
    local szMsg = self.tbContentData[2]
    pMsgRef:SetText(szMsg)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgHorn:SetVisibility(Collapsed)
    pWidgetRef.imgHornBig:SetVisibility(Collapsed)
    if nFlags == LobbyChatSystem.SMALL_HORN then
        pWidgetRef.imgHorn:SetVisibility(Visible)
    elseif nFlags == LobbyChatSystem.BIG_HORN then
        pWidgetRef.imgHornBig:SetVisibility(Visible)
    else
        pWidgetRef.imgHorn:SetVisibility(Collapsed)
    end
end

local function SetVoiceMsg(self, pMsgRef)
    local pWidgetRef = self.pWidgetRef
    local szMsg = self.tbContentData[2]
    pMsgRef:SetText(szMsg)
    pWidgetRef.txtVoiceTime:SetText("5s")
end

local function SetTeamingMsg(self)
    local pWidgetRef = self.pWidgetRef
    local tbContentData = self.tbContentData
    local nToatalCount = tbContentData[3]
    local nCurrentCount = tbContentData[4]
    local szCurrentInfo = string.format( "%s/%s", nCurrentCount, nToatalCount)
    local l10NTextMsg = L10N:Format(UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAMINGTEMPLATE"), szCurrentInfo)
    pWidgetRef.txtTeaming:SetText(l10NTextMsg)
end

local function RefreshMsg(self, eMsgType, pMsgRef, nFlags)
    log(EMsgType_Text)
    if eMsgType == EMsgType_Text then
        SetTextMsg(self, pMsgRef, nFlags)
    elseif eMsgType == EMsgType_Voice then
        SetVoiceMsg(self, pMsgRef)
    elseif eMsgType == EMsgType_Teaming then
        SetTeamingMsg(self)
    end
end

local function CheckTimeLien(self, bNeedTimeLine, nTime)
    local pWidgetRef = self.pWidgetRef
    if bNeedTimeLine == nil or not bNeedTimeLine then
        pWidgetRef.hboxTimeLine:SetVisibility(Collapsed)
        return
    end
    pWidgetRef.hboxTimeLine:SetVisibility(Visible)
    local tbDate =  os.date("*t", nTime)
    local nYear = tbDate.year
    local nMonth = tbDate.month
    local nDay = tbDate.day
    local nHour = tbDate.hour
    local nMin = tbDate.min
    local CurrentDate = self.CurrentDate
    local nCurrentYear = CurrentDate.year
    local nCurrentMonth = CurrentDate.month
    local nCurrentDay = CurrentDate.day
    local szTime = ""
    if nYear ~= nCurrentYear then
        szTime = string.format("%d-%02d-%02d %02d:%02d", nYear, nMonth, nDay, nHour, nMin)
    elseif  nMonth ~= nCurrentMonth or nDay ~= nCurrentDay then
        szTime = string.format("%02d-%02d %02d:%02d", nMonth, nDay, nHour, nMin)
    else
        szTime = string.format("%02d:%02d", nHour, nMin)
    end
    pWidgetRef.txtTime:SetText(szTime)
end

local function GetMsgTxt(self, eChannel)
    local pWidgetRef = self.pWidgetRef
    local bTypeFirend = eChannel == CHAT_FRIEND
    pWidgetRef.txtMsg:SetVisibility(bTypeFirend and Collapsed or Visible)
    pWidgetRef.txtFriendMsg:SetVisibility(bTypeFirend and Visible or Collapsed)
    return bTypeFirend and pWidgetRef.txtFriendMsg or pWidgetRef.txtMsg
end

function UPLobbyMsgItemBase:OnTeamingBtnClicked()
    local tbData = self.tbData
    local nSenderId = tbData.nSenderId
    local nTime = tbData.nTime
    local tbContentData = self.tbContentData
    local nPlayerId = tonumber(tbContentData[5])
    local nTeamId = tbContentData[6]
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
            TeamSystem:ReplyRecruitTeammate(nPlayerId)
        end
    else
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAM_INVITE_INVALILD"))
    end
end

function UPLobbyMsgItemBase:BindHeadBtn()

end

function UPLobbyMsgItemBase:RefreshPlayerHeadInfo(nPlayerId, nAvatarId, nLevel)
    local pPlayHead = self.pPlayHeadScript
    pPlayHead:SetPlayerId(nPlayerId)
    pPlayHead:SetPlayerHead(nAvatarId, nLevel)
    self:BindHeadBtn()
end

function UPLobbyMsgItemBase:RefreshPlayerBaseInfo(szName, nAvatarId, nPlayerRank)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtPlayerName:SetText(szName)
    local szGender = GetGenderRes(nAvatarId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgGender, szGender:load(), true)
    local szRankImg, szRankNumImg = SeasonHelper.GetIcon(nPlayerRank)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRank, szRankImg:load())
    if szRankNumImg ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgRankNumber, szRankNumImg:load())
    else
        pWidgetRef.imgRankNumber:SetVisibility(ESlateVisibility_Collapsed)
    end
end

function UPLobbyMsgItemBase:SetData(tbData)
    self.tbData = tbData
    local nFlags = tbData.nFlags
    local nPlayerId = tbData.nSenderId
    local szContent = tbData.szContent
    local eChannel = tbData.eChannel
    local nTime = tbData.nTime
    local bNeedTimeLine = tbData.NeedTimeLine
    self.tbContentData = LobbyChatSystem:UnpackContent(szContent)
    local eMsgType = tonumber(self.tbContentData[1])
    RefreshItemStyle(self, eMsgType)
    local pMsgRef = GetMsgTxt(self, eChannel)
    RefreshMsg(self, eMsgType, pMsgRef, nFlags)
    RequestBasicInfo(self, nPlayerId)
    CheckTimeLien(self, bNeedTimeLine, nTime)
end

function UPLobbyMsgItemBase:OnLoad()
    self.tbShowWidget = {}
    local pWidgetRef = self.pWidgetRef
    self.CurrentDate = os.date("*t", GlobalVariableSystem:GetServerTimeUtc())
    self.pPlayHeadScript = self.PrefabHelper:BindPrefab(pWidgetRef.pbPlayHead)
    pWidgetRef.txtRank:SetText("")
    AddShowWidgetParams(self, EMsgType_Text, pWidgetRef.vboxMsg, pWidgetRef.txtMsg)
    AddShowWidgetParams(self, EMsgType_Voice, pWidgetRef.vboxMsg, pWidgetRef.ovlVoice, pWidgetRef.txtMsg)
    AddShowWidgetParams(self, EMsgType_Teaming, pWidgetRef.ovlTeaming)
end

function UPLobbyMsgItemBase:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTeaming.OnClicked, self, self.OnTeamingBtnClicked)
end

return UPLobbyMsgItemBase