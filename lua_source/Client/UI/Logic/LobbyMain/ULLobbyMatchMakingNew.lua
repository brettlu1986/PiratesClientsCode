-----------------------------------------------------
--File Name    : ULLobbyMatchMaking.lua
--Author       : Ranjie
--Create Time  : 2020-4-20
--Description  : 大厅匹配logic
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyMatchMaking = luaclass("ULLobbyMatchMaking", UILogicBase)

local UISetUtils = require("UISetUtils")
local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local MatchmakingSystem = require("MatchmakingSystem")
local ClientEventDef = require("ClientEventDef")
local Proto = require("ClientProtoNames")
local UIUtils = require("UIUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TeamSystem = require("TeamSystem")
local L10N = require("L10N")
local DungeonDataTable = require("DungeonDataTable")
local UIManager = require("UIManager")
local UIDef = require("UIDef")



local MATCHMAKING_NOT_IN_OPEN_TIME_TITLE = UISetUtils.GetL10NTextByKey("MATCHMAKING_OPEN_TIME_TITLE")
local MATCHMAKING_NOT_IN_OPEN_TIME_DETAIL = UISetUtils.GetL10NTextByKey("MATCHMAKING_OPEN_TIME_DETAIL")
local MATCHMAKING_NOT_IN_OPEN_TIME_NO_MODE = UISetUtils.GetL10NTextByKey("MATCHMAKING_OPEN_TIME_NO_MODE")
local MATCHMAKING_NOT_IN_OPEN_TIME_OPEN_MODE = UISetUtils.GetL10NTextByKey("MATCHMAKING_OPEN_TIME_OPEN_MODE")
local MATCHMAKING_NOT_IN_OPEN_TIME_MODE = UISetUtils.GetL10NTextByKey("MATCHMAKING_OPEN_TIME_MODE")
local MATCHMAKING_NOT_IN_OPEN_TIME_TIME = UISetUtils.GetL10NTextByKey("MATCHMAKING_OPEN_TIME_TIME")
local TRAINING_MODE_ID = 4

ULLobbyMatchMaking.tbAllMode = nil
ULLobbyMatchMaking.nMaxModeCount = nil
ULLobbyMatchMaking.bCancelMatchMaking = false
ULLobbyMatchMaking.tbDungeonData = nil
ULLobbyMatchMaking.tbAnimTimer = nil

local function SetDungeonCondition(self)
    local pWidgetRef = self.pWidgetRef
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    pWidgetRef.btnStartGame:SetIsEnabled(true)
    local nSelectDungeonId = MatchmakingSystem:GetSelectDungeon()
    
    local tbDungeonTemplate = DungeonDataTable:GetTemplate(nSelectDungeonId)
    if tbDungeonTemplate then
        pWidgetRef.txtDungeonName:SetText(tbDungeonTemplate.l10nName)
        if tbDungeonTemplate.szUIThumbnail and tbDungeonTemplate.szUIThumbnail ~= "" then
            local pResouceObject = tbDungeonTemplate.szUIThumbnail:load()
            if pResouceObject then
                UISetUtils.SetButtonBrushRes(pWidgetRef.btnChangeMode, pResouceObject)
            end
        end
    else
        logerror("ULLobbyMatchMaking:SetDungeonCondition,tbDungeonTemplate is nil",MatchmakingSystem:GetSelectDungeon())
    end
    local nSelectMatchmakingMode = nil
    if MatchmakingSystem:IsTrainingMode() then
        nSelectMatchmakingMode = TRAINING_MODE_ID
    else
        nSelectMatchmakingMode = MatchmakingSystem:GetMatchmakingMode()
    end
    log("SetDungeonCondition:nSelectMatchmakingMode=",nSelectMatchmakingMode, nSelectDungeonId)
    pWidgetRef.txtMatchmakingMode:SetText(nSelectMatchmakingMode)
    if MatchmakingSystem:IsMatchmaking() then
        pWidgetRef.txtStartGame:SetText(UISetUtils.GetL10NTextByKey("UI_LOBBY_MATCHMAKING"))
        self.Owner:StopAnimation("animStart01")
        if not self.tbAnimTimer then
            self.tbAnimTimer = self.TimerHelper:NewTimer(function()
                self.tbAnimTimer = nil
                self.Owner:PlayAnimation("animPglow", 0, 0, EUMGSequencePlayMode.Forward, 1)
            end, 0.8, false)
        end
    else
        self.Owner:StopAnimation("animPglow")
        self.Owner:PlayAnimation("animStart01", 0, 0, EUMGSequencePlayMode.Forward, 1)
        if TeamSystem:IsTeamLeader(nSelfPlayerId) or not TeamSystem:IsInTeam() then
            pWidgetRef.txtStartGame:SetText(UISetUtils.GetL10NTextByKey("UI_LOBBY_START_GAME"))
        else
            local tbMemberData = TeamSystem:GetTeamMemberData(nSelfPlayerId)
            --logdebug("SetDungeonCondition",nDungeonId, nTeamMode,tbMemberData.bIsReady)
            if tbMemberData.bIsReady then
                pWidgetRef.txtStartGame:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_READY_CANCEL"))
            else
                pWidgetRef.txtStartGame:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_READY"))
            end
        end
    end
end

local function MatchPreCheck(self)
    local tbMemberIds = TeamSystem:GetTeamMemberIds()
    for k, v in ipairs(tbMemberIds) do
        if not TeamSystem:IsTeamLeader(v) then
            local tbMemberData = TeamSystem:GetTeamMemberData(v)
            local tbSummary = tbMemberData.tbSummary
            if tbSummary and tbSummary.status == Proto.PlayerStatus.OFFLINE  then
                UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TEAM_TEAM_MEMBER_OFFLINE"))
                return false
            elseif not tbMemberData.bIsReady then
                UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TEAM_TEAM_MEMBER_NOT_READY"))
                return false
            end
        end
    end
    return true
end

local function OnSwitchStartGameClicked(self)
    local pWidgetRef = self.pWidgetRef
    --logdebug("OnSwitchStartGameClicked",MatchmakingSystem:IsMatchmaking())
    if MatchmakingSystem:IsMatchmaking() then
        if MatchmakingSystem:CancelMatchMaking() then
            --pWidgetRef.txtStartGame:SetText(UISetUtils.GetL10NTextByKey("UI_LOBBY_MATCHMAKING"))
            pWidgetRef.btnStartGame:SetIsEnabled(false)
        else
            logwarning("Cancel matchmaking failed.")
        end
        return
    end

    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    if TeamSystem:IsTeamLeader(nSelfPlayerId) or not TeamSystem:IsInTeam() then
        if not MatchPreCheck(self) then
            return
        end
        log("OnSwitchStartGameClicked.....")
        self.Owner:PlayAnimation("animStart", 0, 1, EUMGSequencePlayMode.Forward, 1)
        MatchmakingSystem:SetMatchmakingRoom("")
        if MatchmakingSystem:StartMatchmaking() then
            pWidgetRef.btnStartGame:SetIsEnabled(false)
        end
    else
        local tbMemberData = TeamSystem:GetTeamMemberData(nSelfPlayerId)
        --logdebug("tbMemberData.bIsReady=",tbMemberData.bIsReady)
        local bIsReady = tbMemberData.bIsReady
        TeamSystem:ReadyToMatch(not bIsReady)
    end
end

local function OnDisableEnterClicked(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_DISABLE_ENTER_GAME"))
end


local function OnForceEndMatching(self)
    if MatchmakingSystem:IsMatchmaking() then
        MatchmakingSystem:CancelMatchMaking()
    end
end

local function OnMatchmakingResult(self, bSuccess, nReason)
    if bSuccess then
        self.pWidgetRef.txtStartGame:SetText(UISetUtils.GetL10NTextByKey("UI_LOBBY_MATCHMAKING"))
        self.bCancelMatchMaking = true
        self.pWidgetRef.btnStartGame:SetIsEnabled(true)
    else
        self.bCancelMatchMaking = false
        self.pWidgetRef.btnStartGame:SetIsEnabled(true)
        if nReason == Proto.s2c_StartMatchmaking_Reason.NOT_IN_OPEN_TIME then
            local nSelectMatchmakingMode = nil
            if MatchmakingSystem:IsTrainingMode() then
                nSelectMatchmakingMode = TRAINING_MODE_ID
            else
                nSelectMatchmakingMode = MatchmakingSystem:GetMatchmakingMode()
            end
            MatchmakingSystem:RequestOpenTime(MatchmakingSystem:GetSelectDungeon(), nSelectMatchmakingMode)
        end
    end
    SetDungeonCondition(self)
end

local function OnCancelMatchMaking(self, bSuccess)
    if bSuccess then
        self.bCancelMatchMaking = false
    elseif MatchmakingSystem:IsMatchmaking() == true then
        log("OnCancelMatchmaking failed.")
        self.bCancelMatchMaking = false
        self.pWidgetRef.txtStartGame:SetText(UISetUtils.GetL10NTextByKey("UI_LOBBY_MATCHMAKING"))
        self.pWidgetRef.btnStartGame:SetIsEnabled(true)
    end
    SetDungeonCondition(self)
end

local function OnClickedHyperLink(self, tbMeta)
    for k, v in pairs(tbMeta) do
        if v.Key == "href" then
            KismetSystemLibrary.LaunchURL(v.Value)
            return
        end
    end
end

local function OnMatchmakingOpenTime(self, tbOpentTimes, tbOpenModes)
    local szOpenTime = ""
    local nCount = #tbOpentTimes
    local szSeparator = ","
    for k, v in ipairs(tbOpentTimes )do
        if k == nCount then
            szSeparator = ""
        end
        local szEndTime = v.end_time
        if v.end_time == "23:59:59" then
            szEndTime = "24:00"
        end
        szOpenTime = szOpenTime .. L10N:ToString(L10N:Format(MATCHMAKING_NOT_IN_OPEN_TIME_TIME, v.start_time .. "-" .. szEndTime)) .. szSeparator
    end
    --开放模式
    local function SortFunc(tbDataA, tbDataB)
        if tbDataA.team_mode > tbDataB.team_mode then
            return true
        else
            return false
        end
    end
    local szOpenMode = ""
    szSeparator = "，"
    nCount = #tbOpenModes
    if nCount > 0 then
        table.sort(tbOpenModes, SortFunc)
        for k, v in ipairs(tbOpenModes) do
            if k == nCount then
                szSeparator = ""
            end
            local tbTeamModeTemplate = MatchmakingTeamModeDataTable:GetTemplate(v.team_mode)
            if tbTeamModeTemplate then
                szOpenMode = szOpenMode .. L10N:ToString(L10N:Format(MATCHMAKING_NOT_IN_OPEN_TIME_MODE, tbTeamModeTemplate.l10nDesc)) .. szSeparator
            end
        end
        szOpenMode = L10N:Format(MATCHMAKING_NOT_IN_OPEN_TIME_OPEN_MODE, szOpenMode)
    else
        szOpenMode = MATCHMAKING_NOT_IN_OPEN_TIME_NO_MODE
    end
    local l10nDetail = L10N:Format(MATCHMAKING_NOT_IN_OPEN_TIME_DETAIL, szOpenTime, szOpenMode)

    local pbDialogFrame = UIUtils.ShowConfirmDialog(MATCHMAKING_NOT_IN_OPEN_TIME_TITLE, l10nDetail, function()
        if nCount > 0 then
            SetDungeonCondition(self)
        end
    end)

    pbDialogFrame:SetMessageJustification(ETextJustify.Left)
    local txtMessage = pbDialogFrame.pWidgetRef.txtMessage

    if txtMessage and not self.ClickedHyperLinkHandle then
        self.ClickedHyperLinkHandle = self.EventHelper:RegisterCppDelegate(txtMessage.OnClickedHyperLink, self, OnClickedHyperLink)
    end
    pbDialogFrame:SetDialogClosedCallback(function()
        if self.ClickedHyperLinkHandle then
            self.EventHelper:UnregisterCppDelegate(self.ClickedHyperLinkHandle)
            self.ClickedHyperLinkHandle = nil
        end
    end)
end

local function OnTeamChanged(self, tbPacket)
    --logdebug("OnTeamChanged,tbPacket.change_type=",tbPacket.change_type,tbPacket.player_id)
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    if tbPacket.change_type == Proto.ChangeType.ADD_MEMBER and TeamSystem:IsTeamLeader(nSelfPlayerId) then
        local nMatchmakingModeFixed = MatchmakingSystem:GetMatchmakingMode()
        local nTeamMemberCount = TeamSystem:GetTeamMemberCount()
        local tbCurrentModeTemplate = MatchmakingTeamModeDataTable:GetTemplate(nMatchmakingModeFixed)
        if tbCurrentModeTemplate.nPlayersPerTeam < nTeamMemberCount then
            local tbAllMode = MatchmakingTeamModeDataTable:GetAllMode()
            for k, v in ipairs(tbAllMode) do
                if v.nPlayersPerTeam >= TeamSystem:GetTeamMemberCount() then
                    nMatchmakingModeFixed = v.nId
                    break
                end
            end
        end
        MatchmakingSystem:SetMatchmakingMode(nMatchmakingModeFixed)
        TeamSystem:ChangeMatchCondition(nMatchmakingModeFixed, MatchmakingSystem:IsAutoMatchmaking(), MatchmakingSystem:GetSelectDungeon())
    end
    SetDungeonCondition(self)
end

local function OnLeaderChanged(self, nNewLeader, nOlderLeader)
    SetDungeonCondition(self)
end

local function OnTeamMemberReadyChanged(self)
    --logdebug("OnTeamMemberReadyChanged")
    SetDungeonCondition(self)
end

local function OnMatchConditionChanged(self, nTeamMode, bAutoMatch, nDungeonId)
    log("OnMatchConditionChangedOnMatchConditionChanged",nTeamMode, bAutoMatch, nDungeonId)
    SetDungeonCondition(self)
end

local function OnMatchmakingModeChanged(self)
    SetDungeonCondition(self)
end

local function OnChangeModeClicked(self)
    UIManager:OpenWnd(UIDef.UI_LOBBY_MATCHMAKING)
end


function ULLobbyMatchMaking:OnShow()
    SetDungeonCondition(self)
end

function ULLobbyMatchMaking:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnStartGame.OnClicked, self, OnSwitchStartGameClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnStartGame.OnDisableClicked, self, OnDisableEnterClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnChangeMode.OnClicked, self, OnChangeModeClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_MATCHMAKING_RESULT, self, OnMatchmakingResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_CANCEL_MATCHMAKING, self, OnCancelMatchMaking)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_SYNC, self, SetDungeonCondition)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED, self, OnTeamChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_LEADER_CHANGED, self, OnLeaderChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MEMBER_READY_MATCH, self, OnTeamMemberReadyChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MATCH_CONDITION_CHANGED, self, OnMatchConditionChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_MATCHMAKING_FORCE_CANCLE, self, OnForceEndMatching)
    EventHelper:RegisterEvent(ClientEventDef.EV_MATCHMAKING_OPEN_TIME, self, OnMatchmakingOpenTime)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_MATCHMAKING_MODE_CHANGED, self, OnMatchmakingModeChanged)
    
end

function ULLobbyMatchMaking:OnUnbindEvent()
    self.ClickedHyperLinkHandle = nil
end

function ULLobbyMatchMaking:OnExit()
    self.tbAnimTimer = nil
end

return ULLobbyMatchMaking