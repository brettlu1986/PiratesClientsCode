-----------------------------------------------------
--File Name    : UILobbyTeamInvite.lua
--Description  : 大厅组队邀请申请界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyTeamInvite = luaclass("UILobbyTeamInvite", WndBase)

local L10N = require("L10N")
local HumanDataTable = require("HumanDataTable")
local UIResourceDef = require("UIResourceDef")
local GenderTypeDefine = require("GenderTypeDefine")
local UISetUtils = require("UISetUtils")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local Proto = require("ClientProtoNames")
local TeamRefuseReasonDataTable = require("TeamRefuseReasonDataTable")
local TeamSystem = require("TeamSystem")
local TeamIni = require("TeamIni")
local ClientEventDef = require("ClientEventDef")

--local REFUSE_WAIT_TIME = 20
local AUTO_REFUSE_REASON_ID = 0
local InviteFrom = Proto.InviteFrom

UILobbyTeamInvite.nSelectIndex = nil
UILobbyTeamInvite.tbInviteApplyMessageList = nil
UILobbyTeamInvite.tbInfo = nil


local function SetInfo(self, tbInfo, nReceiveTime)
    self.tbInfo = tbInfo
    local tbPlayerSummary = tbInfo.player_summary
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtName:SetText(tbPlayerSummary.name)
    self.pbPlayerHead:SetPlayerHead(tbPlayerSummary.avatar_id, tbPlayerSummary.level)
    local tbHumanTemplate = HumanDataTable:GetTemplate(tbPlayerSummary.id)
    if tbHumanTemplate then
        local nGenderType = tbHumanTemplate.nGender
        local szGenderIcon = UIResourceDef.GENDER_FEMALE
        if nGenderType == GenderTypeDefine.MALE then
            szGenderIcon = UIResourceDef.GENDER_MALE
        end
        UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGenderIcon:load(), true)
    end
    local tbAllReason = TeamRefuseReasonDataTable:GetAllShowReason()
    for k, v in ipairs(tbAllReason) do
        pWidgetRef.cmbRefuseReason:AddOption(L10N:ToString(v.l10nReasonText))
    end
    pWidgetRef.cmbRefuseReason:SetSelectedOption(L10N:ToString(tbAllReason[1].l10nReasonText))
    if tbInfo.type == Proto.InviteApplyType.INVITE_JOIN_TEAM then
        pWidgetRef.txtIgnore:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IGNORE_INVITE"))
        pWidgetRef.txtTitle:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_INVITE_TITLE"))
    elseif tbInfo.type == Proto.InviteApplyType.APPLY_JOIN_TEAM then
        pWidgetRef.txtIgnore:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IGNORE_APPLY"))
        pWidgetRef.txtTitle:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_APPLY_TITLE"))
    end
    local Invite_From = tbInfo.from
    if Invite_From == InviteFrom.FRIEND then
        pWidgetRef.txtInviteFrom:SetText(UISetUtils.GetL10NTextByKey("INVITE_FROM_FRIEND"))
    elseif Invite_From == InviteFrom.CHAT then
        pWidgetRef.txtInviteFrom:SetText(UISetUtils.GetL10NTextByKey("INVITE_FROM_CHAT"))
    end
    local l10Refuse = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_REFUSE")
    pWidgetRef.txtRefuse:SetTimerStart(l10Refuse, false, nReceiveTime + TeamIni.nValidTimeForApplyJoinTeam)
    self.nSelectIndex = 1
end

local function GetNextMessage(self)
    if #self.tbInviteApplyMessageList > 0 then
        local tbMessage = table.remove(self.tbInviteApplyMessageList, 1)
        if GlobalVariableSystem:GetLocalTime() - tbMessage.nReceiveTime < TeamIni.nValidTimeForApplyJoinTeam then
            SetInfo(self, tbMessage.tbPacket, tbMessage.nReceiveTime)
        else
            GetNextMessage(self)
        end
    else
        self:CloseSelf()
    end
end

local function OnRefuseClicked(self)
    local tbAllReason = TeamRefuseReasonDataTable:GetAllShowReason()
    local tbReasonTemplate = tbAllReason[self.nSelectIndex]
    --logdebug("self.nSelectIndex,tbReasonTemplate=",self.nSelectIndex,tbReasonTemplate)
    if tbReasonTemplate then
        local tbInfo = self.tbInfo
        tbInfo.bHandled = true
        TeamSystem:ReplyJoinTeam(tbInfo.type, tbInfo.player_summary.id, tbInfo.team_id, false, tbReasonTemplate.nId)
    end
    GetNextMessage(self)
end

local function OnCountDownFinished(self)
    local tbInfo = self.tbInfo
    tbInfo.bHandled = true
    TeamSystem:ReplyJoinTeam(tbInfo.type, tbInfo.player_summary.id, tbInfo.team_id, false, AUTO_REFUSE_REASON_ID)
    GetNextMessage(self)
end

local function OnAcceptClicked(self)
    local tbInfo = self.tbInfo
    tbInfo.bHandled = true
    TeamSystem:ReplyJoinTeam(tbInfo.type, tbInfo.player_summary.id, tbInfo.team_id, true, nil)
    GetNextMessage(self)
end

local function OnIgnoreCheckChanged(self, bChecked)
    local tbInfo = self.tbInfo
    if tbInfo.type == Proto.InviteApplyType.INVITE_JOIN_TEAM then
        TeamSystem:AddToInviteIgnore(tbInfo.player_summary.id, bChecked)
    elseif tbInfo.type == Proto.InviteApplyType.APPLY_JOIN_TEAM then
        TeamSystem:AddToApplyIgore(tbInfo.player_summary.id, bChecked)
    end
end

local function OnReasonSelectionChanged(self, szSelectOption)
    self.nSelectIndex = self.pWidgetRef.cmbRefuseReason:FindOptionIndex(szSelectOption) + 1
    --logdebug("OnReasonSelectionChanged,self.nSelectIndex=",self.nSelectIndex)
end

local function CheckInviteMessageExist(self, nPlayerId)
    if self.tbInfo.player_summary.id == nPlayerId then
        return true
    end
    for k, v in ipairs(self.tbInviteApplyMessageList) do
        if nPlayerId == v.tbPacket.player_summary.id then
            return true
        end
    end
    return false
end

local function OnTeamInviteApply(self, tbPacket)
    local tbMessage = {}
    tbMessage.tbPacket = tbPacket
    tbMessage.nReceiveTime = GlobalVariableSystem:GetLocalTime()
    if CheckInviteMessageExist(self, tbPacket.player_summary.id) then
        return
    end
    table.insert(self.tbInviteApplyMessageList, tbMessage)
end

function UILobbyTeamInvite:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.pbPlayerHead = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerHead)
end

function UILobbyTeamInvite:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRefuse.OnClicked, self, OnRefuseClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAccept.OnClicked, self, OnAcceptClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.chkSelect.OnCheckStateChanged, self, OnIgnoreCheckChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtRefuse.OnCountDownFinished, self, OnCountDownFinished)
    EventHelper:RegisterCppDelegate(pWidgetRef.cmbRefuseReason.OnSelectionChanged, self, OnReasonSelectionChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_INVITE_APPLY, self, OnTeamInviteApply)
end

function UILobbyTeamInvite:OnShow()
    self.tbInviteApplyMessageList = {}
    SetInfo(self, self.tbOpenArgs, GlobalVariableSystem:GetLocalTime())
    self:PlayAnimation("animTeamlnvite", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UILobbyTeamInvite:OnExit()
    local tbInfo = self.tbInfo
    if tbInfo and not tbInfo.bHandled then
        TeamSystem:ReplyJoinTeam(tbInfo.type, tbInfo.player_summary.id, tbInfo.team_id, false, AUTO_REFUSE_REASON_ID)
        tbInfo.bHandled = false
    end
end

return UILobbyTeamInvite