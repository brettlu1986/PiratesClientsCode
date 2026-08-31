local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_Lobby = luaclass("Procedure_Lobby", ProcedureBase)

local Timer = require("Timer")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local SelfEventHelper = require("SelfEventHelper")

local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local DelayTimer = require("DelayTimer")
local UEActorHelper = require("UEActorHelper")
-- local GMSystem = dynamic_require("GMSystem")
local GameObjectSystem = require("GameObjectSystem_C")
local GameWorldSystem = require("GameWorldSystem")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local SoundManager = require("SoundManager")
local LoadingSystem = require("LoadingSystem")
local UIStateDef = require("UIStateDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SceneDataTable = require("SceneDataTable")
local DisplayAwardItemIni = require("DisplayAwardItemIni")
local ResourceManager = require("ResourceManager")
local SCENE_LEVEL = '/Game/Resources/FFA/Maps/Select/Map_FFA_Lobby'
local HUMAN_AWARD_DISPLAY_SUBLEVEL = DisplayAwardItemIni.tbHumanDisplay.szLevelRes


Procedure_Lobby.EventHelper = nil

Procedure_Lobby.pStreamingLevel = nil
Procedure_Lobby.CameraActor = nil
Procedure_Lobby.RenderParams = nil

Procedure_Lobby.pHumanActor = nil
Procedure_Lobby.nAvatarId = 0
Procedure_Lobby.szName = nil
Procedure_Lobby.nPlayerId = nil
Procedure_Lobby.bLoadingMinSecond = false
Procedure_Lobby.ShowUITimer = nil
Procedure_Lobby.bShowLoading = nil

local LOGIN_MAP_ID = 70001
local EMPTY_STEP_COUNT = 10
local XFOVBak = nil

local function ClearTimer(self)
    if self.ShowUITimer then
        DelayTimer:ClearTimer(self.ShowUITimer)
        self.ShowUITimer = nil
    end
end

local function OpenUIStep(self)
    local function OpenUIFunc()
        local tbParam = {
            [UIDef.UI_LOBBY] = {
                nAvatarId = self.nAvatarId,
                szName=self.szName,
                pHumanActor=self.pHumanActor,
                nPlayerId = self.nPlayerId
            }
        }
        UIManager:PushState(UIStateDef.StateName.UI_LOBBY_STATE, tbParam)
    end
    if self.bShowLoading then
        if not self.ShowUITimer then
            self.ShowUITimer = DelayTimer:DelayRun(function()
                    self.ShowUITimer = nil
                    OpenUIFunc()
                    LoadingSystem:StepNext()
            end, 1.0)
        end
    else
        OpenUIFunc()
    end
end

local function FireLobbyReadyEventStep(self)
    EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_READY)
    if self.bShowLoading then
        LoadingSystem:StepNext()
    end
end

local function HideUI(self)
    self.pStreamingLevel = nil
end

-- local function HumanShow(self)
--     local tbHumanData = HumanDataTable:GetResData(self.nAvatarId)
--     if not tbHumanData then
--         return
--     end
--     local szPawnClassName = tbHumanData.szPawnClassName
--     local location = self.HumanPosActor:K2_GetActorLocation()
--     local rotation = self.HumanPosActor:K2_GetActorRotation()
--     local _, pHuman = UEActorHelper:CreateActor(szPawnClassName,location,rotation,Vector{X=1,Y=1,Z=1})

--     pHuman:K2_SetActorLocation(location)
--     pHuman:K2_SetActorRotation(rotation)
--     pHuman.bUseControllerRotationYaw = false
--     self.pHumanActor = pHuman

--     local tbAvatar = AvatarDataTable:GetTemplate(self.nAvatarId)
--     if tbAvatar.szShowAnimation then
--         SelfAnimationHelper:PlayActorAnimation(pHuman,self.nAvatarId,tbAvatar.szShowAnimation)
--     end

--     MatineeSystem:Clear()
--     local pController = GameplayStatics.GetPlayerController(GWorld, 0)
--     pController:SetViewTargetWithBlend(self.CameraActor, 0, EViewTargetBlendFunction.VTBlend_Linear, 0, false)
--     LoadingSystem:StepNext()
-- end

local function UnloadSublevelRes(self)
    if self.nLoadResourceAsyncHandler and self.nLoadResourceAsyncHandler ~= -1 then
        ResourceManager:CancelLoadAsync(self.nLoadResourceAsyncHandler)
        self.nLoadResourceAsyncHandler = nil
    end
end

local function PreLoadSublevelStep(self)
    --提前加载人时装奖励展示的sublevel
    if self.nLoadResourceAsyncHandler and self.nLoadResourceAsyncHandler ~= -1 then
        return
    end
    self.nLoadResourceAsyncHandler = ResourceManager:LoadAsync(HUMAN_AWARD_DISPLAY_SUBLEVEL, function()
        EventManager:OnFireEvent(ClientEventDef.EV_SUBLEVEL_LOADED_IN_LOBBY, HUMAN_AWARD_DISPLAY_SUBLEVEL)
    end)
    if self.bShowLoading then
        LoadingSystem:StepNext()
    end
end

local function LoadMontage(self)
    if not isvalidhandle(self.CameraActor) then
        self.CameraActor = ExtendBlueprintFunctions.GetWorldActorByName(GWorld, "Camera2")
    end
    if not isvalidhandle(self.RenderParams) then
        self.RenderParams = ExtendBlueprintFunctions.GetWorldActorByName(GWorld, "RPOW")
    end
    local pController = GameplayStatics.GetPlayerController(GWorld, 0)
    pController:SetViewTargetWithBlend(self.CameraActor, 0, EViewTargetBlendFunction.VTBlend_Linear, 0, false)
    local pCameraComponent = self.CameraActor.CameraComponent
	-- Convert XFOV To YFOV at the begining to make sure the vertical content is consistent in different devices
	if not XFOVBak then
		XFOVBak = pCameraComponent.FieldOfView
    end
    -- Only convert when aspect ratio < 16:9
	local yFOV = RenderExtendBlueprintFunctions.ConvertXFOVToYFOV(pCameraComponent, XFOVBak, pCameraComponent.AspectRatio)
    if yFOV > pCameraComponent.FieldOfView then
		pCameraComponent.FieldOfView = yFOV
	end
    log("Lobby Camera:FieldOfView, OrthoWidth, OrthoNearClipPlane, OrthoFarClipPlane, AspectRatio=",
    pCameraComponent.FieldOfView, pCameraComponent.OrthoWidth, pCameraComponent.OrthoNearClipPlane,
    pCameraComponent.OrthoFarClipPlane, pCameraComponent.AspectRatio)

    self.RenderParams:Apply()
end

local function BindMethod(self)
    -- self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_ENTER_GAME, self, self.OnMatch)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_SELECT_ROLE_BACK, self, self.OnReturnBack)
    self.pStreamingLevelLoadedDelegate = self.EventHelper:RegisterCppDelegate(ClientShell.GetClient(GWorld).OnSubLevelLoadEnd,self, self.PostLoadMap)
end

local function UnbindMethod(self)
    self.EventHelper:UnregisterAll()
end

local function ProcessPendingPacketOnStep(self)
    log("Procedure_Lobby ProcessPendingPacketOnStep set pending false")
    NetworkManager:SetPending(false)
    if self.bShowLoading then
        LoadingSystem:StepNext()
    end
end

local function CreateSubLevelStep(self)
    --local pClientShell = ClientShell.GetClient(GWorld)
    --pClientShell:ToggleSceneRendering(true)
    LowEntryExtendedStandardLibrary.SetWorldRenderingEnabled(true)
    SCENE_LEVEL:load()
    ClientShell.GetClient(GWorld):LoadStreamLevel(GWorld, SCENE_LEVEL)
    GameplayStatics.FlushLevelStreaming(GWorld)
end

local function CreateLobbyStep(self)
    local OnLoginSceneReady = nil
    OnLoginSceneReady = function()
        EventManager:UnBindEvent(ClientEventDef.EV_POST_LOAD_MAP, OnLoginSceneReady)
        LoadingSystem:StepNext()
    end
    EventManager:BindEvent(ClientEventDef.EV_POST_LOAD_MAP, OnLoginSceneReady)

    self:OpenLoginMap()
end

local function EmptyStep(self)
    LoadingSystem:StepNext()
end

local function MinSecondStep(self)
    if self.bLoadingMinSecond then
        if not self.ShowUITimer then
            self.ShowUITimer = DelayTimer:DelayRun(function()
                    self.ShowUITimer = nil
                    LoadingSystem:StepNext()
            end, 0.1)
        end
    else
        LoadingSystem:StepNext()
    end
end

local function PrepareLoading(self)
    -- log("Procedure_Lobby set pending false")
    --NetworkManager:SetPending(false)

    LoadingSystem:ClearSteps()
    for i = 1 , EMPTY_STEP_COUNT do
        LoadingSystem:AddStepMethod(self, EmptyStep)
    end
    LoadingSystem:AddStepMethod(self, MinSecondStep)
    LoadingSystem:AddStepMethod(self, PreLoadSublevelStep)
    LoadingSystem:AddStepMethod(self, CreateLobbyStep)
    LoadingSystem:AddStepMethod(self, CreateSubLevelStep)
    LoadingSystem:AddStepMethod(self, ProcessPendingPacketOnStep)
    LoadingSystem:AddStepMethod(self, OpenUIStep)
    LoadingSystem:AddStepMethod(self, FireLobbyReadyEventStep)
    local tbParam = {nSceneId = LOGIN_MAP_ID}
    LoadingSystem:Start(tbParam)

end


function Procedure_Lobby:OpenLoginMap()
    local tbCreateData =
    {
        bLoadNewMap = true,
        nSceneId = LOGIN_MAP_ID,
        bLoadAsync = false,
    }
    GameWorldSystem:CreateWorld(tbCreateData)
end

function Procedure_Lobby:Init()
    Procedure_Lobby.super.Init(self)
    self.EventHelper = SelfEventHelper()
end

function Procedure_Lobby:Uninit()
    UnbindMethod(self)
    ClearTimer(self)
    Procedure_Lobby.super.Uninit(self)
end

function Procedure_Lobby:Begin()
    log("Procedure_Lobby set pending true")
    self.tbCurrentHumanPos = {}
    self.tbHumanActor = {}
    self.bShowLoading = true
    NetworkManager:SetPending(true)

    local tbPackage = self.Param
    if tbPackage then
        self.bShowLoading = tbPackage.bShowLoading
        self.szName = tbPackage.tbPlayerData.name
        self.nPlayerId = tbPackage.tbPlayerData.id
        if(GlobalVariableSystem.bEnableNewLobbyServer) then
            self.nAvatarId = tbPackage.tbPlayerData.avatar_id
        else
            local avatar = tbPackage.data.avatar
            self.nAvatarId = avatar.avatar_id
        end
        if self.bShowLoading then
            self.bLoadingMinSecond = true
        else
            self.bLoadingMinSecond = false
        end
    else
        self.bLoadingMinSecond = false
    end

    self.pHumanActor = nil

    GlobalVariableSystem:SetInDungeon(false)
    GlobalVariableSystem:SetStandalone(false)

    UIManager:CloseWnd(UIDef.UI_LOGIN)
    Procedure_Lobby.super.Begin(self)
    BindMethod(self)

    ManagerRoot:InitGroup(ManagerGroupDef.nLobbyGroupID, true)

    CommonShell.GetCommon(GWorld):GetInputManager():CloseGestureSelfTouchListen()
    ClientShell.GetClient(GWorld):SetGameStatus(EPiratesGameStatus.LOBBY)

    EventManager:OnFireEvent(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY)
    if self.bShowLoading then
        PrepareLoading(self)
    else
        PreLoadSublevelStep(self)
        CreateSubLevelStep(self)
        self:PostLoadMap()
        ProcessPendingPacketOnStep(self)
        OpenUIStep(self)
        FireLobbyReadyEventStep(self)
    end
end

function Procedure_Lobby:End()
    -- 关闭移动端虚拟键盘
    ExtendBlueprintFunctions.HideVirtualKeyboard()
    -- 防止没进行ProcessPendingPacketOnStep 就切procedure了
    log("Procedure_Lobby End set pending false")
    NetworkManager:SetPending(false)
    --重置RenderParam
    if isvalidhandle(self.RenderParams) then
        self.RenderParams:Restore()
    end
    self.RenderParams = nil

    local envControl = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, "EnvControl01")
    if envControl then
        envControl:RevertEnvironment()
    end

    EventManager:OnFireEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY)
    if self.pHumanActor and isvalidhandle(self.pHumanActor) then
        UEActorHelper:DestroyActor(self.pHumanActor)
    end
    self.pHumanActor = nil

    if self.pStreamingLevelLoadedDelegate then
        self.EventHelper:UnregisterCppDelegate(self.pStreamingLevelLoadedDelegate)
        self.pStreamingLevelLoadedDelegate = nil
    end
    UnloadSublevelRes(self)
    UnbindMethod(self)
    HideUI(self)
    ClearTimer(self)

    
    UIManager:PopAllState()
    -- 检查并清理timer
    Timer.CheckAndClearAllTimer()
    GameObjectSystem:DestroyAll()
    GameWorldSystem:DestroyWorld()
    SoundManager:StopBackgroundMusic()
    ManagerRoot:UninitGroup(ManagerGroupDef.nLobbyGroupID)
    ClientShell.GetClient(GWorld):SetGameStatus(EPiratesGameStatus.NONE)

    Procedure_Lobby.super.End(self)
end

function Procedure_Lobby:HoldObject(pObject)
    if pObject then
        local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pObject)
        self.tbHolderList[nUniqueID] = luaholder(pObject)
    end
end

function Procedure_Lobby:UnholdObject(pObject)
    if pObject then
        local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pObject)
        self.tbHolderList[nUniqueID] = nil
    end
end

function Procedure_Lobby:PostLoadMap()
    if not isvalidhandle(self.pStreamingLevel) then
        self.pStreamingLevel = ClientShell.GetClient(GWorld):GetStreamingLevel(GWorld, SCENE_LEVEL)
        if not self.pStreamingLevel then
            log("Procedure_Lobby:PostLoadMap self.pStreamingLevel is nil")
            return
        end
    end
    if self.pStreamingLevelLoadedDelegate then
        self.EventHelper:UnregisterCppDelegate(self.pStreamingLevelLoadedDelegate)
        self.pStreamingLevelLoadedDelegate = nil
    end
    local nPlayerNewServerId = GlobalVariableSystem.nSelfLobbyPlayerId
    GameObjectSystem:RestorePlayerSelfObject(false, nPlayerNewServerId, nil, true)
    LoadMontage(self)
    GamePlayerSelfHelper:Get().pUEActor.CharacterMovement:SetComponentTickEnabled(false)
    local nBGMId = SceneDataTable:GetTemplate(LOGIN_MAP_ID).nBGMId
    local CurrentBackgroundMusic = SoundManager.CurrentBackgroundMusic
    if not CurrentBackgroundMusic or CurrentBackgroundMusic.nID ~= nBGMId then
        SoundManager:PlayBackgroundMusic(nBGMId)
    end

    local envControl = ExtendBlueprintFunctions.GetLevelActorByTag(self.pStreamingLevel, "EnvControl01")
    if envControl then
        envControl:SetEnvironment()
    end
    if self.bShowLoading then
        LoadingSystem:StepNext()
    end
end

-- function Procedure_Lobby:OnMatch()
--     GMSystem:Exec("gm require('ffa').StartGame(me, 100009)")
--     if not self.ShowUITimer then
--         self.ShowUITimer = DelayTimer:DelayRun(function()
--                 self.ShowUITimer = nil
--                 EventManager:OnFireEvent(ClientEventDef.EV_UI_LOBBY_RESET)
--         end, 2.0)
--     end
-- end

function Procedure_Lobby:OnReturnBack()
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    HubServerProxy:Disconnect()
end

return Procedure_Lobby
