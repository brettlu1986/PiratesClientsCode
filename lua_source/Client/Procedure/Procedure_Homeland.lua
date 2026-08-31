local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_Homeland = luaclass("Procedure_Homeland", ProcedureBase)

local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local SelfEventHelper = require("SelfEventHelper")()
local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local DelayTimer = require("DelayTimer")
local GameObjectSystem = require("GameObjectSystem_C")
local GameWorldSystem = require("GameWorldSystem")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local SoundManager = require("SoundManager")
local LoadingSystem = require("LoadingSystem")
local UIStateDef = require("UIStateDef")
local HomelandSceneSystem = require("HomelandSceneSystem")
local NetworkManager = dynamic_require("NetworkManager")
local HomelandSystem = require("HomelandSystem")

local SCENE_MAP_ID = 200000

Procedure_Homeland.nLoadingMinSecond = 0.3
Procedure_Homeland.tbMinSecondTimerHandle = nil
Procedure_Homeland.tbRecieveEvent = {}

local function ClearTimer(self)
    if self.tbMinSecondTimerHandle then
        DelayTimer:ClearTimer(self.tbMinSecondTimerHandle)
        self.tbMinSecondTimerHandle = nil
    end
end

local function MinSecondStep(self)
    if self.nLoadingMinSecond then
        if not self.tbMinSecondTimerHandle then
            self.tbMinSecondTimerHandle = DelayTimer:DelayRun(function()
                    self.tbMinSecondTimerHandle = nil
                    LoadingSystem:StepNext()
            end, self.nLoadingMinSecond)
        end
    else
        LoadingSystem:StepNext()
    end
end

local function CreateWorldStep(self, bReceivedEvent)
    log("Procedure_Homeland:CreateWorldStep")
    if bReceivedEvent then
        LoadingSystem:StepNext()
    else
        local tbSceneCreateData = {}
        tbSceneCreateData.bLoadNewMap = true
        tbSceneCreateData.nSceneId = SCENE_MAP_ID
        --tbSceneCreateData.bLoadAsync = false
        GameWorldSystem:CreateWorld(tbSceneCreateData)
    end
end

local function FireHomelandReadyEventStep(self)
    SelfEventHelper:FireEvent(ClientEventDef.EV_HOMELAND_READY)
    LoadingSystem:StepNext()
end

local function CheckPlayerSelf(self)
    local tbTransform = HomelandSceneSystem:GetDefaultPlayerStart()
    local nPlayerNewServerId = GlobalVariableSystem.nSelfLobbyPlayerId
    GameObjectSystem:RestorePlayerSelfObject(false, nPlayerNewServerId, tbTransform, true)
end

local function IsSwitchStyle(self)
    return self.Param and self.Param.bSwitchStyle
end

local function LoadHomelandSceneDataStep(self)
    log("Procedure_Homeland:SetHomeStyleStep")
    CheckPlayerSelf(self)
    local nCurrentSceneId = HomelandSystem:GetCurrentSceneId()
    local bSwitch =IsSwitchStyle(self)
    HomelandSceneSystem:LoadSceneData(nCurrentSceneId, bSwitch)
    LoadingSystem:StepNext()
end

local function SetPendingFalseStep(self)
    log("Procedure_Homeland:SetPendingFalseStep")
    NetworkManager:SetPending(false)
    LoadingSystem:StepNext()
end

local function OpenUIStep(self)
    log("Procedure_Homeland:OpenUIStep")
    UIManager:PushState(UIStateDef.StateName.UI_HOMELAND_STATE)
    LoadingSystem:StepNext()
end

local function RegisterLoadStep(self, StepMethod, Event)
    local tbEventParam = {}
    if Event then
        SelfEventHelper:RegisterEventFunc(Event, function(...)
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
    log("Procedure_Homeland set pending false")
    NetworkManager:SetPending(false)

    LoadingSystem:ClearSteps()
    if not IsSwitchStyle(self) then
        RegisterLoadStep(self, MinSecondStep)
    end
    RegisterLoadStep(self, CreateWorldStep, ClientEventDef.EV_POST_LOAD_MAP)
    RegisterLoadStep(self, LoadHomelandSceneDataStep)
    RegisterLoadStep(self, SetPendingFalseStep)
    RegisterLoadStep(self, OpenUIStep)
    RegisterLoadStep(self, FireHomelandReadyEventStep)
    local tbParam = {szHomelandBg = self.Param.szHomelandBg}
    LoadingSystem:Start(tbParam)
end

function Procedure_Homeland:Init()
    Procedure_Homeland.super.Init(self)
end

function Procedure_Homeland:Uninit()
    Procedure_Homeland.super.Uninit(self)
    ClearTimer(self)
    SelfEventHelper:UnregisterAll()
end

function Procedure_Homeland:Begin()
    log("Procedure_Homeland set pending true")
    Procedure_Homeland.super.Begin(self)
    self.tbRecieveEvent = {}

    NetworkManager:SetPending(true)


    GlobalVariableSystem:SetInDungeon(false)
    GlobalVariableSystem:SetStandalone(false)

    ManagerRoot:InitGroup(ManagerGroupDef.nHomelandGroupID, true)

    CommonShell.GetCommon(GWorld):GetInputManager():CloseGestureSelfTouchListen()
    ClientShell.GetClient(GWorld):SetGameStatus(EPiratesGameStatus.LOBBY)
    PrepareLoading(self)
    SelfEventHelper:FireEvent(ClientEventDef.EV_ENTER_PROCEDURE_HOMELAND)
end

function Procedure_Homeland:End()
    ClearTimer(self)
    SelfEventHelper:UnregisterAll()
    UIManager:PopAllState()
    ManagerRoot:UninitGroup(ManagerGroupDef.nHomelandGroupID)
    GameObjectSystem:DestroyAll()
    GameWorldSystem:DestroyWorld()
    SoundManager:StopBackgroundMusic()
    ClientShell.GetClient(GWorld):SetGameStatus(EPiratesGameStatus.NONE)
    SelfEventHelper:FireEvent(ClientEventDef.EV_LEAVE_PROCEDURE_HOMELAND)
    Procedure_Homeland.super.End(self)
end




return Procedure_Homeland
