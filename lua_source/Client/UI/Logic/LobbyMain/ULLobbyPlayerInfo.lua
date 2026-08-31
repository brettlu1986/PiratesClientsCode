-----------------------------------------------------
--File Name    : ULLobbyPlayerInfo.lua
--Author       : WuJizhou
--Create Time  : 3/21/2019, 2:13:19 PM
--Description  : ULLobbyPlayerInfo
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULLobbyPlayerInfo = luaclass("ULLobbyPlayerInfo", UILogicBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local PlayerBasicInfoSystem = require("PlayerBasicInfoSystem")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local PlayerLevelDataTable = require("PlayerLevelDataTable")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local TeamSystem = require("TeamSystem")

ULLobbyPlayerInfo.tbDragIndex = nil
ULLobbyPlayerInfo.tbDragLastPos = nil

ULLobbyPlayerInfo.pbPlayHead = nil
ULLobbyPlayerInfo.bShowLevelChange = nil


local function GetLobbyPropertyComponent()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local LobbyPropertyComponent = PlayerSelf.LobbyPropertyComponent
    return LobbyPropertyComponent
end

local function RefreshExpAndLevel(pWidgetRef, LobbyPropertyComponent)
    local nPlayerLevel = LobbyPropertyComponent:GetPlayerLevel()
    pWidgetRef.ktxtPlayLevel:SetText(nPlayerLevel)
    local nCurLevelMaxExp = PlayerLevelDataTable:GetTemplate(nPlayerLevel).nExp
    local nExp = LobbyPropertyComponent:GetPlayerExp()
    local szExp = string.format("%d/%d", nExp, nCurLevelMaxExp)
    pWidgetRef.txtExp:SetText(szExp)
    pWidgetRef.pgbExp:SetPercent(nExp/nCurLevelMaxExp)
end

local function RefreshPlayerBasicInfo(self)
    local pWidgetRef = self.pWidgetRef
    local LobbyPropertyComponent = GetLobbyPropertyComponent()
    if LobbyPropertyComponent then
        local nAvatarId = LobbyPropertyComponent:GetAvatarId()
        self.pbPlayHead:SetPlayerHead(nAvatarId)
        pWidgetRef.txtPlayerName:SetText(LobbyPropertyComponent:GetPlayerName())
        RefreshExpAndLevel(pWidgetRef, LobbyPropertyComponent)
    else
        logerror("ULLobbyPlayerInfo", "LobbyPropertyComponent is nil")
    end
end

local function OnHeadBtnClicked(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nPlayerId = PlayerSelf:GetPlayerId()
    UIManager:OpenWnd(UIDef.UI_PLAYER_INFO, {nPlayerId = nPlayerId})
end


local function ShowLevelUp(self)
    log("ULLOBYYPLAYERBASICINFO ShowLevelUp")
    UIManager:OpenWnd(UIDef.UI_PLAYER_LEVEL_UP)
end

local function OnLevelUp(self)
    local pWidgetRef = self.pWidgetRef
    local LobbyPropertyComponent = GetLobbyPropertyComponent()
    RefreshExpAndLevel(pWidgetRef, LobbyPropertyComponent)
    ShowLevelUp(self)
end

local function OnExpSynced(self)
    local pWidgetRef = self.pWidgetRef
    local LobbyPropertyComponent = GetLobbyPropertyComponent()
    RefreshExpAndLevel(pWidgetRef, LobbyPropertyComponent)
end

local function CheckLevelUp(self)
    if PlayerBasicInfoSystem:LevelUpInfoExist() then
        ShowLevelUp(self)
    end
end

local function OnLobbyReady(self)
    if self.bShowLevelChange then
        CheckLevelUp(self)
        self.bShowLevelChange = false
    end
end

local function OnNameChanged(self)
    RefreshPlayerBasicInfo(self)
end

local function UpdateDragEnable(self)
    local tbTeamMemberIds = TeamSystem:GetTeamMemberIds()
    if #tbTeamMemberIds > 0 then
        self.Owner.tbLogic["ULLobbyDrag"]:SetEnable(false)
    else
        self.Owner.tbLogic["ULLobbyDrag"]:SetEnable(true)
    end
end

--playerself drag
local function OnInvitedDisableClicked(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 0.2)
end

----------life cycle----------
function ULLobbyPlayerInfo:OnLoad()
    self.pbPlayHead = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayHead)
    self.pbPlayHead:BindHeadBtnOnClicked(OnHeadBtnClicked)

end

function ULLobbyPlayerInfo:OnShow()
    RefreshPlayerBasicInfo(self)
    UpdateDragEnable(self)
    -- CheckLevelUp(self)
    self.bShowLevelChange = true
    self.tbDragIndex = {}
    self.tbDragLastPos = {}
end

function ULLobbyPlayerInfo:OnBindEvent( EventHelper )
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_LEVEL_UP_NEW, self, OnLevelUp)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_EXP_SYNC_NEW, self, OnExpSynced)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnLobbyReady)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_NAME_CHANGED, self, OnNameChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_SYNC, self, UpdateDragEnable)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CLEAR_MEMBERS, self, UpdateDragEnable)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnInvite.OnDisableClicked, self, OnInvitedDisableClicked)
end


return ULLobbyPlayerInfo