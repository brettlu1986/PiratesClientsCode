local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_CreateRole = luaclass("Procedure_CreateRole", ProcedureBase)

local EventManager      = require("EventManager")
-- local ProcedureTool 	= require("ProcedureTool")
local ClientEventDef 	= require("ClientEventDef")
local NetworkManager 	= dynamic_require("NetworkManager")
local UIManager 		= require("UIManager")
local UIUtils 			= require("UIUtils")
local UIDef 			= require("UIDef")
local SelfEventHelper 	= require("SelfEventHelper")
local ManagerRoot 		= require("ManagerRoot")
local ManagerGroupDef 	= require("ManagerGroupDef")
local GenderTypeDef 	= require("GenderTypeDefine")
local MatineeSystem 	= dynamic_require("MatineeSystem")
local RaceTypeDefine 	= require("RaceTypeDefine")
local SoundManager 		= require("SoundManager")
local SceneDataTable 	= require("SceneDataTable")
local SelfTimerHelperClass  = require("SelfTimerHelper")
local GlobalVariableSystem  = require("GlobalVariableSystem_C")
local GameWorldSystem       = require("GameWorldSystem")

local DEFAULT_SEX  = GenderTypeDef.FEMALE
local DEFAULT_RACE = RaceTypeDefine.Europe

Procedure_CreateRole.EventHelper = nil
Procedure_CreateRole.TimerHelper = SelfTimerHelperClass()
Procedure_CreateRole.bFirstShow = true
Procedure_CreateRole.SelectPlayerSound = nil
Procedure_CreateRole.pStreamingLevel = nil
Procedure_CreateRole.nCurrentSelectSex = DEFAULT_SEX
Procedure_CreateRole.nCurrentSelectRace = DEFAULT_RACE
Procedure_CreateRole.tbCurrentCreateRoleData = nil
Procedure_CreateRole.nHumanID = 0
-- Procedure_CreateRole.CameraActor = nil
Procedure_CreateRole.bShadowCacheEnableBak = nil

local MATINEE_SCENE_LEVEL_NEW = "/Game/Resources/FFA/Maps/Outside/Map_RoleCreation/Map_RoleCreation"

local RENDER_PARAMS_TAG = "RPOW"

-- local CandidateAvatarConfig = GlobalVariableSystem.CandidateAvatarConfig
-- local tbCandidateRoleType = {}
-- tbCandidateRoleType[CandidateAvatarConfig.All] = {GenderTypeDef.MALE, GenderTypeDef.FEMALE}
-- tbCandidateRoleType[CandidateAvatarConfig.MaleOnly] = {GenderTypeDef.MALE}
-- tbCandidateRoleType[CandidateAvatarConfig.FemaleOnly] = {GenderTypeDef.FEMALE}

local function PlayBGM()
	local nBGMId = SceneDataTable:GetTemplate(GlobalVariableSystem.CREATE_ROLE_MAP_ID).nBGMId
	local CurrentBackgroundMusic = SoundManager.CurrentBackgroundMusic
	if not CurrentBackgroundMusic or CurrentBackgroundMusic.nID ~= nBGMId then
		SoundManager:PlayBackgroundMusic(nBGMId)
	end
end

local function StopBGM()
	SoundManager:StopBackgroundMusic()
end


-- local function GetCandidateRolesType()
--     local szConfigValue = GlobalVariableSystem:GetAvatarSexConfig()
-- 	local tbCadidates = tbCandidateRoleType[szConfigValue]
--     return tbCadidates
-- end

-- local function InitCandidateRole(self)
-- 	local tbCadidates = GetCandidateRolesType()
-- 	if tbCadidates and #tbCadidates == 1 then
-- 		self.nCurrentSelectSex = tbCadidates[1]
-- 	else
-- 		self.nCurrentSelectSex = DEFAULT_SEX
-- 	end
-- 	self.nCurrentSelectRace = DEFAULT_RACE
-- 	self:SetSexAndRace(self.nCurrentSelectSex, self.nCurrentSelectRace)
-- end

function Procedure_CreateRole:Init()
	Procedure_CreateRole.super.Init(self)
	self.EventHelper = SelfEventHelper()
end

function Procedure_CreateRole:Uninit()
	self:UnbindHubMethod()
	Procedure_CreateRole.super.Uninit(self)
end


local function OnPostLoadDefaultMap(self)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_POST_LOAD_MAP)
    self:OpenCreateRoleMap()
end

local function LoadDefaultMap(self)
	local nCurrentSceneId = GlobalVariableSystem.LOGIN_MAP_ID
	if GlobalVariableSystem.bEnterLobby3D then
		nCurrentSceneId = 70003
	end
    local tbCreateData =
    {
        bLoadNewMap = true,
        --szMapName = LOGIN_MAP_NAME,
        nSceneId = nCurrentSceneId,
        bLoadAsync = false,
    }
    self.EventHelper:RegisterEvent(ClientEventDef.EV_POST_LOAD_MAP, self, OnPostLoadDefaultMap)
    GameWorldSystem:CreateWorld(tbCreateData)
end

function Procedure_CreateRole:Begin()
	Procedure_CreateRole.super.Begin(self)
	self:BindHubMethod()
	GlobalVariableSystem:SetInDungeon(false)
	-- InitCandidateRole(self)
	self.bShadowCacheEnableBak = RenderExtendBlueprintFunctions.GetShadowCacheEnabled()
    RenderExtendBlueprintFunctions.SetShadowCacheEnabled(false)
    self.bFirstShow = true
    local tbParam = self.Param
	if(tbParam ~= nil and tbParam.bNeedLoadMap) then
        LoadDefaultMap(self)
    else
        self:OpenCreateRoleMap()
    end

	ManagerRoot:InitGroup(ManagerGroupDef.nLoginGroupID, true)
end

function Procedure_CreateRole:End()
	
	RenderExtendBlueprintFunctions.SetShadowCacheEnabled(self.bShadowCacheEnableBak)
    local envControl = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, "EnvControl03")
    if envControl then
        envControl:RevertEnvironment()
    end
	StopBGM()
	self:UnbindHubMethod()
	self:HideUI()
	-- self:DestroyAvatar()
	UIManager:PopAllState()
	UIUtils.HideLoadingDialog()

    if isvalidhandle(self.RenderParams) then
        self.RenderParams:Restore()
    end
    self.RenderParams = nil
	self.pStreamingLevel:SetShouldBeVisible(false)
	self.pStreamingLevel = nil

	ManagerRoot:UninitGroup(ManagerGroupDef.nLoginGroupID)
	Procedure_CreateRole.super.End(self)
end

function Procedure_CreateRole:LoadConfigActor()
	-- self.CameraActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, "Cha_Overall")
	self.HumanPosActor = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, "Human1")
end

function Procedure_CreateRole:ShowUI()
	UIManager:CloseWnd(UIDef.UI_LOGIN)
	local tbParams = {}
	tbParams.pLocation = self.HumanPosActor:K2_GetActorLocation()
    tbParams.pRotation = self.HumanPosActor:K2_GetActorRotation()
    tbParams.pStreamingLevel = self.pStreamingLevel
	UIManager:OpenWnd(UIDef.UI_CREATE_ROLE, tbParams)
	PlayBGM()
	EventManager:OnFireEvent(ClientEventDef.EV_SHOW_CREATE_ROLE)
end

function Procedure_CreateRole:HideUI()
	UIManager:CloseWnd(UIDef.UI_CREATE_ROLE)
end

function Procedure_CreateRole:BindHubMethod()
	self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_CREATE_ROLE_BACK, self, self.OnReturnBack)
	
end

function Procedure_CreateRole:OpenCreateRoleMap()
	self.pStreamingLevel = ClientShell.GetClient(GWorld):GetStreamingLevel(GWorld, MATINEE_SCENE_LEVEL_NEW)
	if not self.pStreamingLevel then
		return
	end
	self.pStreamingLevel:SetShouldBeVisible(true)
	if not self.pStreamingLevel.LoadedLevel then
		self.pStreamingLevel:SetShouldBeLoaded(true)
	end
	GameplayStatics.FlushLevelStreaming(GWorld)
	self:PostLoadSubLevel()
end

function Procedure_CreateRole:PostLoadSubLevel()
	MatineeSystem:Clear()
	self:LoadConfigActor()
	-- local pController = GameplayStatics.GetPlayerController(GWorld, 0)
    -- pController:SetViewTargetWithBlend(self.CameraActor, 0, EViewTargetBlendFunction.VTBlend_Linear, 0, false)

    local envControl = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, "EnvControl03")
    if envControl then
        envControl:SetEnvironment()
    end
	self.RenderParams = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, RENDER_PARAMS_TAG)
	if isvalidhandle(self.RenderParams) then
		self.RenderParams:Apply()
	end
    self:ShowUI()
end



function Procedure_CreateRole:UnbindHubMethod()
	self.EventHelper:UnregisterAll()
end



function Procedure_CreateRole:OnReturnBack()
	-- if self.Param and self.Param.bFromSelecteRole then
	-- 	ProcedureTool:EnterSelectRole(self.Param)
	-- else
		local HubServerProxy = NetworkManager:GetHubServerProxy()
		HubServerProxy:Disconnect()
	-- end
end

return Procedure_CreateRole
