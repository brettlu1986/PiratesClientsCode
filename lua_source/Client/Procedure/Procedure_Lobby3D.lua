local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_Lobby3D = luaclass("Procedure_Lobby3D", ProcedureBase)

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
-- local GMSystem = dynamic_require("GMSystem")
local GameObjectSystem = require("GameObjectSystem_C")
local GameWorldSystem = require("GameWorldSystem")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local SoundManager = require("SoundManager")
local LoadingSystem = require("LoadingSystem")
local UIStateDef = require("UIStateDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SceneDataTable = require("SceneDataTable")
local LobbySystem = require("LobbySystem")

Procedure_Lobby3D.EventHelper = nil
Procedure_Lobby3D.bLoadingMinSecond = false
Procedure_Lobby3D.ShowUITimer = nil
Procedure_Lobby3D.bShowLoading = nil
Procedure_Lobby3D.WaitEvent = nil
Procedure_Lobby3D.tbRecieveEvent = nil
Procedure_Lobby3D.nLoadResourceAsyncHandler = nil
Procedure_Lobby3D.tbDelayLoadSubLevelTimer = nil
Procedure_Lobby3D.bShadowCacheEnableBak = nil

local LOGIN_MAP_ID = 70001
local EMPTY_STEP_COUNT = 10

local function ClearTimer(self)
    if self.ShowUITimer then
        DelayTimer:ClearTimer(self.ShowUITimer)
        self.ShowUITimer = nil
    end
    if self.tbDelayLoadSubLevelTimer then
        DelayTimer:ClearTimer(self.tbDelayLoadSubLevelTimer)
        self.tbDelayLoadSubLevelTimer = nil
    end
end

local function OpenUIStep(self)
    log("Procedure_Lobby3D OpenUIStep")
    UIManager:PushState(UIStateDef.StateName.UI_LOBBY3D_STATE)
    if self.bShowLoading then
        LoadingSystem:StepNext()
    end
    
end

local function FireLobbyReadyEventStep(self)
    log("Procedure_Lobby3D FireLobbyReadyEventStep")
    EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_READY)
    if self.bShowLoading then
        LoadingSystem:StepNext()
    end
end


local function LoadAllSubLevelAsyncStep(self)
    log("Procedure_Lobby3D LoadAllSubLevelStep")
    
    LobbySystem:LoadAllSubLevelAsync()
    LoadingSystem:StepNext()
    
end

local function BindMethod(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_SELECT_ROLE_BACK, self, self.OnReturnBack)
end

local function UnbindMethod(self)
    self.EventHelper:UnregisterAll()
end

local function ProcessPendingPacketOnStep(self)
    log("Procedure_Lobby3D ProcessPendingPacketOnStep set pending false")
    NetworkManager:SetPending(false)
    if self.bShowLoading then
        LoadingSystem:StepNext()
    end
end

local function CreateLobbyStep(self, bReceivedEvent)
    log("Procedure_Lobby3D CreateLobbyStep",bReceivedEvent)
    if bReceivedEvent then
        LoadingSystem:StepNext()
    else
        local nCurrentSceneId = GlobalVariableSystem.LOGIN_MAP_ID
        if GlobalVariableSystem.bEnterLobby3D then
            nCurrentSceneId = 70003
        end
        local tbCreateData =
        {
            bLoadNewMap = true,
            nSceneId = nCurrentSceneId,
            bLoadAsync = false,
        }
        GameWorldSystem:CreateWorld(tbCreateData)
    end
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

local function RestorePlayerSelfStep(self)
    log("Procedure_Lobby3D RestorePlayerSelfStep")
    local nPlayerNewServerId = GlobalVariableSystem.nSelfLobbyPlayerId
    GameObjectSystem:RestorePlayerSelfObject(false, nPlayerNewServerId, nil, true)
    GamePlayerSelfHelper:Get().pUEActor.CharacterMovement:SetComponentTickEnabled(false)
    if self.bShowLoading then
        LoadingSystem:StepNext()
    end
end


local function RegisterLoadStep(self, StepMethod, Event)
    local tbEventParam = {}
    if Event then
        self.EventHelper:RegisterEventFunc(Event, function(...)
            self.tbRecieveEvent[Event] = true
            tbEventParam = {...}
            if self.WaitEvent == Event then
                StepMethod(self, true, ...)
            end
        end)
    end

    LoadingSystem:AddStepMethod(self, function()
        self.WaitEvent = Event
        StepMethod(self, Event == nil or self.tbRecieveEvent[Event] == true, table.unpack(tbEventParam))
    end)
end

local function PrepareLoading(self)
    -- log("Procedure_Lobby3D set pending false")
    --NetworkManager:SetPending(false)

    LoadingSystem:ClearSteps()
    for i = 1 , EMPTY_STEP_COUNT do
        RegisterLoadStep(self, EmptyStep)
    end
    RegisterLoadStep(self, MinSecondStep)
    RegisterLoadStep(self, CreateLobbyStep, ClientEventDef.EV_POST_LOAD_MAP)
    RegisterLoadStep(self, LoadAllSubLevelAsyncStep)
    RegisterLoadStep(self, RestorePlayerSelfStep)
    RegisterLoadStep(self, ProcessPendingPacketOnStep)
    RegisterLoadStep(self, OpenUIStep)
    RegisterLoadStep(self, FireLobbyReadyEventStep)
    local tbParam = {nSceneId = LOGIN_MAP_ID}
    LoadingSystem:Start(tbParam)

end

function Procedure_Lobby3D:Init()
    Procedure_Lobby3D.super.Init(self)
    self.EventHelper = SelfEventHelper()
end

function Procedure_Lobby3D:Uninit()
    UnbindMethod(self)
    ClearTimer(self)
    Procedure_Lobby3D.super.Uninit(self)
end

function Procedure_Lobby3D:Begin()
    log("Procedure_Lobby3D set pending true")
    self.bShowLoading = true
    self.tbRecieveEvent = {}
    NetworkManager:SetPending(true)
    self.bShadowCacheEnableBak = RenderExtendBlueprintFunctions.GetShadowCacheEnabled()
    RenderExtendBlueprintFunctions.SetShadowCacheEnabled(false)
    local tbPackage = self.Param
    if tbPackage then
        self.bShowLoading = tbPackage.bShowLoading
    end
    GlobalVariableSystem:SetInDungeon(false)
    GlobalVariableSystem:SetStandalone(false)
    --ClientShell.GetClient(GWorld):UnloadStreamLevel(GWorld, CREATE_ROLE_SUBLEVEL)

    UIManager:CloseWnd(UIDef.UI_LOGIN)
    Procedure_Lobby3D.super.Begin(self)
    BindMethod(self)

    ManagerRoot:InitGroup(ManagerGroupDef.nLobbyGroupID, true)

    CommonShell.GetCommon(GWorld):GetInputManager():CloseGestureSelfTouchListen()
    ClientShell.GetClient(GWorld):SetGameStatus(EPiratesGameStatus.LOBBY)
    local nBGMId = SceneDataTable:GetTemplate(LOGIN_MAP_ID).nBGMId
    local CurrentBackgroundMusic = SoundManager.CurrentBackgroundMusic
    if not CurrentBackgroundMusic or CurrentBackgroundMusic.nID ~= nBGMId then
        SoundManager:PlayBackgroundMusic(nBGMId)
    end

    EventManager:OnFireEvent(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY)
    if self.bShowLoading then
        PrepareLoading(self)
    else
        RestorePlayerSelfStep(self)
        ProcessPendingPacketOnStep(self)
        OpenUIStep(self)
        FireLobbyReadyEventStep(self)
        self.tbDelayLoadSubLevelTimer = DelayTimer:DelayRun(function()
            self.tbDelayLoadSubLevelTimer = nil
            LoadAllSubLevelAsyncStep(self)
        end, 0.5)
    end
end

function Procedure_Lobby3D:End()
    RenderExtendBlueprintFunctions.SetShadowCacheEnabled(self.bShadowCacheEnableBak)
    -- 关闭移动端虚拟键盘
    ExtendBlueprintFunctions.HideVirtualKeyboard()
    -- 防止没进行ProcessPendingPacketOnStep 就切procedure了
    log("Procedure_Lobby3D End set pending false")
    NetworkManager:SetPending(false)

    EventManager:OnFireEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY)
    UnbindMethod(self)
    ClearTimer(self)
    UIManager:PopAllState()
    -- 检查并清理timer
    Timer.CheckAndClearAllTimer()
    GameObjectSystem:DestroyAll()
    GameWorldSystem:DestroyWorld()
    SoundManager:StopBackgroundMusic()
    ManagerRoot:UninitGroup(ManagerGroupDef.nLobbyGroupID)
    ClientShell.GetClient(GWorld):SetGameStatus(EPiratesGameStatus.NONE)

    Procedure_Lobby3D.super.End(self)
end


function Procedure_Lobby3D:OnReturnBack()
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    HubServerProxy:Disconnect()
end

return Procedure_Lobby3D
