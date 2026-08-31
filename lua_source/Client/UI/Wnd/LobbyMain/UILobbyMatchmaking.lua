-----------------------------------------------------
--File Name    : UILobbyMatchmaking.lua
--Author       : Ranjie
--Create Time  : 2020-8-12
--Description  : 大厅匹配界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyMatchmaking = luaclass("UILobbyMatchmaking", WndBase)

local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local MatchmakingSystem = require("MatchmakingSystem")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TeamSystem = require("TeamSystem")
local SelfCheckBoxGroupHelper = require("SelfCheckBoxGroupHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local Proto = require("ClientProtoNames")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")

local TRAINING_DUNGEON_ID = 110001
local TRAINING_MODE_ID = 4
local DUNGEON_ID_LIST = {100011, 110001}

UILobbyMatchmaking.tbAllMode = nil
UILobbyMatchmaking.tbDungeonData = nil
UILobbyMatchmaking.nDungeonId = nil
UILobbyMatchmaking.nMatchmakingMode = nil
UILobbyMatchmaking.bAutoMatchmaking = nil

local function GetMatchmakingModeIndex(self, nMatchmakingMode)
    for k, v in pairs(self.tbAllMode) do
        if v.nId == nMatchmakingMode then
            return k
        end
    end
    return 1
end

local function SetAutoMatchmakingImage(self, bAutoMatchmaking)
    local pIconResource = nil
    if bAutoMatchmaking then
        pIconResource = UIResourceDef.LOBBY_AUTO_MATCHMAKING_CHECKED:load()
    else
        pIconResource = UIResourceDef.LOBBY_AUTO_MATCHMAKING_UNCHECKED:load()
    end
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgAutoMatchmaking, pIconResource)
end

local function UpdateDisplay(self, nDungeonId, nMatchmakingMode)
    local tbCurrentModeTemplate = MatchmakingTeamModeDataTable:GetTemplate(nMatchmakingMode)
    local pWidgetRef = self.pWidgetRef
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    log("UpdateDisplayByMatchmakingMode,", nDungeonId, nMatchmakingMode)
    if nDungeonId == TRAINING_DUNGEON_ID then
        pWidgetRef.hbxMode:SetVisibility(ESlateVisibility_HitTestInvisible)
        pWidgetRef.btnDisableMatchmakingMode:SetVisibility(ESlateVisibility_Visible)
        pWidgetRef.chkAutoMatchmaking:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.btnDisableAutoMatchmaking:SetVisibility(ESlateVisibility_Collapsed)
        for k, v in pairs(self.tbAllMode) do
            if v.nId == TRAINING_MODE_ID then
                self.CheckBoxGroupHelper:SetIsEnabledByIndex(k, true)
                self.CheckBoxGroupHelper:SelectByIndex(k, false)
            else
                self.CheckBoxGroupHelper:SetIsEnabledByIndex(k, false)
            end
        end
        if TeamSystem:IsInTeam(nSelfPlayerId) and not TeamSystem:IsTeamLeader(nSelfPlayerId) then
            pWidgetRef.btnDiableDungeon:SetVisibility(ESlateVisibility_Visible)
        else
            pWidgetRef.btnDiableDungeon:SetVisibility(ESlateVisibility_Collapsed)
        end
    else
        self.CheckBoxGroupHelper:SelectByIndex(GetMatchmakingModeIndex(self, nMatchmakingMode), false)
        local TeamMemberCount = TeamSystem:GetTeamMemberCount()
        pWidgetRef.txtPlayerCount:SetText(tostring(math.max(1, TeamMemberCount)).."/"..tbCurrentModeTemplate.nPlayersPerTeam)
        if TeamSystem:IsInTeam(nSelfPlayerId) and not TeamSystem:IsTeamLeader(nSelfPlayerId) then
            pWidgetRef.btnDiableDungeon:SetVisibility(ESlateVisibility_Visible)
            pWidgetRef.hbxMode:SetVisibility(ESlateVisibility_HitTestInvisible)
            pWidgetRef.btnDisableMatchmakingMode:SetVisibility(ESlateVisibility_Visible)
            pWidgetRef.chkAutoMatchmaking:SetVisibility(ESlateVisibility_HitTestInvisible)
            pWidgetRef.btnDisableAutoMatchmaking:SetVisibility(ESlateVisibility_Visible)
        else
            pWidgetRef.btnDiableDungeon:SetVisibility(ESlateVisibility_Collapsed)
            if MatchmakingSystem:IsMatchmaking() then
                pWidgetRef.btnDiableDungeon:SetVisibility(ESlateVisibility_Visible)
                self.pWidgetRef.hbxMode:SetVisibility(ESlateVisibility_HitTestInvisible)
                pWidgetRef.btnDisableMatchmakingMode:SetVisibility(ESlateVisibility_Visible)
                self.pWidgetRef.chkAutoMatchmaking:SetVisibility(ESlateVisibility_HitTestInvisible)
                pWidgetRef.btnDisableAutoMatchmaking:SetVisibility(ESlateVisibility_Visible)
            else
                pWidgetRef.hbxMode:SetVisibility(ESlateVisibility_Visible)
                pWidgetRef.btnDisableMatchmakingMode:SetVisibility(ESlateVisibility_Visible)
                if tbCurrentModeTemplate.nPlayersPerTeam == 1 then
                    pWidgetRef.chkAutoMatchmaking:SetVisibility(ESlateVisibility_Collapsed)
                    pWidgetRef.btnDisableAutoMatchmaking:SetVisibility(ESlateVisibility_Collapsed)
                else
                    pWidgetRef.chkAutoMatchmaking:SetVisibility(ESlateVisibility_Visible)
                    pWidgetRef.btnDisableAutoMatchmaking:SetVisibility(ESlateVisibility_Visible)
                end
                
                
            end
        end
        for k, v in pairs(self.tbAllMode) do
            if v.nPlayersPerTeam >= TeamMemberCount then
                self.CheckBoxGroupHelper:SetIsEnabledByIndex(k, true)
            else
                self.CheckBoxGroupHelper:SetIsEnabledByIndex(k, false)
            end
        end
    end
end

local function OnModeSelectChanged(self, nIndex)
    self.nMatchmakingMode = self.tbAllMode[nIndex].nId
    UpdateDisplay(self, self.nDungeonId, self.nMatchmakingMode)
end

local function OnDungeonSelectChanged(self, nIndex)
    self.nDungeonId = self.tbDungeonData[nIndex].nDungeonId
    UpdateDisplay(self, self.nDungeonId, self.nMatchmakingMode)
end

local function OnMatchConditionChanged(self, nMatchmakingMode, bAutoMatch, nDungeonId)
    self.nMatchmakingMode = MatchmakingSystem:GetMatchmakingMode()
    self.nDungeonId = MatchmakingSystem:GetSelectDungeon()
    self.bAutoMatchmaking = MatchmakingSystem:IsAutoMatchmaking()
    self.CheckBoxGroupHelper:SelectByIndex(GetMatchmakingModeIndex(self, self.nMatchmakingMode), true)
    for k, v in pairs(self.tbDungeonData) do
        if v.nDungeonId == self.nDungeonId then
            self.ListHelper:SetSelectedIndex(k)
            break
        end
    end
    self.pWidgetRef.chkAutoMatchmaking:SetIsChecked(self.bAutoMatchmaking)
    SetAutoMatchmakingImage(self, self.bAutoMatchmaking)
    UpdateDisplay(self, self.nDungeonId, self.nMatchmakingMode)
end

local function OnTeamChanged(self, tbPacket)
    if tbPacket.change_type == Proto.ChangeType.ADD_MEMBER and tbPacket.player_id == GamePlayerSelfHelper:Get():GetPlayerId() then
        self:CloseSelf()
    end
    --self.CheckBoxGroupHelper:SelectByIndex(GetMatchmakingModeIndex(self, nMatchmakingModeFixed), true)
end

local function OnLeaderChanged(self)
    UpdateDisplay(self, self.nDungeonId, self.nMatchmakingMode)
end

local function OnCancelMatchMaking(self, bSuccess)
    if bSuccess then
        UpdateDisplay(self, self.nDungeonId, self.nMatchmakingMode)
    end
end

local function OnConfirmClicked(self)
    if not MatchmakingSystem:IsMatchmaking() then
        if not TeamSystem:IsInTeam() or TeamSystem:IsTeamLeader(GamePlayerSelfHelper:Get():GetPlayerId()) then
            local nSelectDungeonId = self.nDungeonId
            local nMatchmakingMode, bAutoMatchMaking = nil
            if nSelectDungeonId == TRAINING_DUNGEON_ID then
                nMatchmakingMode = TRAINING_MODE_ID
                bAutoMatchMaking = false
            else
                nMatchmakingMode = self.nMatchmakingMode
                bAutoMatchMaking = self.bAutoMatchmaking
                MatchmakingSystem:SetMatchmakingMode(nMatchmakingMode)
                MatchmakingSystem:SetAutoMatchmaking(bAutoMatchMaking)
            end
            MatchmakingSystem:SetSelectDungeon(nSelectDungeonId)
            if TeamSystem:IsTeamLeader(GamePlayerSelfHelper:Get():GetPlayerId()) then
                TeamSystem:ChangeMatchCondition(nMatchmakingMode, bAutoMatchMaking, nSelectDungeonId)
            end
        end
        self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_MATCHMAKING_MODE_CHANGED)
    end
    self:CloseSelf()
end

local function OnCloseClicked(self)
    self:CloseSelf()
end

local function OnDisableButtonClicked(self)
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    local nDungeonId = self.nDungeonId
    if TeamSystem:IsTeamLeader(nSelfPlayerId) then
        if MatchmakingSystem:IsMatchmaking() then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TEAM_MATCH_MAKING"))
        elseif nDungeonId == TRAINING_DUNGEON_ID then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_MATCHMAKING_CAN_NOT_MODIFY"))
        else
            logerror("UILobbyMatchmaking:OnDisableMatchmakingModeClicked:state error")
        end
    else
        if TeamSystem:IsInTeam() then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_MEMBER_CAN_NOT_MODIFY"))
        elseif nDungeonId == TRAINING_DUNGEON_ID then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_MATCHMAKING_CAN_NOT_MODIFY"))
        else
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TEAM_MATCH_MAKING"))
        end
    end
end

local function OnAutoMatchmakingCheckStateChanged(self, bIsChecked)
    self.bAutoMatchmaking = bIsChecked
    SetAutoMatchmakingImage(self, bIsChecked)
end

function UILobbyMatchmaking:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.vlistMode)

    self.tbAllMode = MatchmakingTeamModeDataTable:GetAllMode()
    self.CheckBoxGroupHelper = SelfCheckBoxGroupHelper()
    self.CheckBoxGroupHelper:Init(self, self.pWidgetRef.hbxMode)
    
    for k, v in ipairs(self.tbAllMode) do
        self.CheckBoxGroupHelper:SetCheckBoxText(k, v.l10nDesc)
    end
    self.tbDungeonData = {}
    for k, v in ipairs(DUNGEON_ID_LIST) do
        local tbData = {}
        tbData.nDungeonId = v
        tbData.nIndex = k
        table.insert(self.tbDungeonData, tbData)
    end
    --插入一个空的数据用于显示
    table.insert(self.tbDungeonData, {bNotOpen = true})
    self.CheckBoxGroupHelper.OnSelectedChangedDelegate:Bind(OnModeSelectChanged, self)
    self.ListHelper.OnSelectedChangedDelegate:Bind(OnDungeonSelectChanged, self)
end

function UILobbyMatchmaking:OnEnter()
    self.nDungeonId = MatchmakingSystem:GetSelectDungeon()
    self.nMatchmakingMode = MatchmakingSystem:GetMatchmakingMode()
    self.bAutoMatchmaking = MatchmakingSystem:IsAutoMatchmaking()
    self.ListHelper:SetData(self.tbDungeonData)
    for k, v in pairs(self.tbDungeonData) do
        if v.nDungeonId == self.nDungeonId then
            self.ListHelper:SetSelectedIndex(k)
            break
        end
    end
    self.CheckBoxGroupHelper:SelectByIndex(GetMatchmakingModeIndex(self, self.nMatchmakingMode), true)
    self.pWidgetRef.chkAutoMatchmaking:SetIsChecked(self.bAutoMatchmaking)
    SetAutoMatchmakingImage(self, self.bAutoMatchmaking)
end

function UILobbyMatchmaking:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnConfirm.OnClicked, self, OnConfirmClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnCloseClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCloseBg.OnClicked, self, OnCloseClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDisableMatchmakingMode.OnClicked, self, OnDisableButtonClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDisableAutoMatchmaking.OnClicked, self, OnDisableButtonClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.chkAutoMatchmaking.OnCheckStateChanged, self, OnAutoMatchmakingCheckStateChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDiableDungeon.OnClicked, self, OnDisableButtonClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MATCH_CONDITION_CHANGED, self, OnMatchConditionChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED, self, OnTeamChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_CANCEL_MATCHMAKING, self, OnCancelMatchMaking)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_LEADER_CHANGED, self, OnLeaderChanged)
end

function UILobbyMatchmaking:OnShow()
    self:PlayAnimation("animMatchMakin", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UILobbyMatchmaking:OnDestroy()
    self.CheckBoxGroupHelper:Uninit()
    self.ListHelper:Uninit()
end

return UILobbyMatchmaking