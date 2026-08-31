-- Param = { TargetMap, TargetMapName }

local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_WildWorld = luaclass("Procedure_WildWorld", ProcedureBase)

local ClientEventDef = require("ClientEventDef")
local SelfEventHelperClass = require("SelfEventHelper")
local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local NetworkManager = dynamic_require("NetworkManager")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local GameWorldSystem = require("GameWorldSystem")
local LoadingSystem = require("LoadingSystem")
local SoundManager = require("SoundManager")
local EventManager = require("EventManager")
local DelayTimer = require("DelayTimer")
local Timer = require("Timer")
local SceneDataTable = require("SceneDataTable")
local SceneResDataTable = require("SceneResDataTable")
local GameWorldDefine = require("GameWorldDefine")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectSystem = require("GameObjectSystem_C")
-- local HandlerManagerHelper = require("HandlerManagerHelper")

local BGMHelper = require("BGMHelper")
local UIStateDef = require("UIStateDef")

local UninitCheckSystem = require("UninitCheckSystem")

Procedure_WildWorld.EventHelper = nil
Procedure_WildWorld.bSmoothTravel = false


local function CheckPlayerSelf(self)
    local bIsOcean = GameWorldSystem:GetWorld():IsOcean()
    local tbParam = self.Param
    GameObjectSystem:RestorePlayerSelfObject(bIsOcean, tbParam.nPlayerNewServerId,
        tbParam.tbTransform, true)
    GamePlayerSelfHelper:Get():OnEnterWild()
end

local function ProcessPendingPacket(self)
    log("ProcessPendingPacket")
    -- 因为pending的packet里可能还包含切场景，所以必须要让整个loading过程完成，所以必须在loading结束后再pending false
    -- if not self.SetPendingTimer then
    --     self.SetPendingTimer = DelayTimer:RunNextTick(function()
    --     log("Procedure_WildWorld ProcessPendingPacket set pending false")
    --         self.SetPendingTimer = nil
    --     NetworkManager:SetPending(false)
    -- end)
    -- end
    -- LoadingSystem:StepNext()

    -- 临时：强制延后关loading，为了关loading后效果不会太卡
    NetworkManager:SetPending(false)
    if not self.SetPendingTimer then
        self.SetPendingTimer = DelayTimer:DelayRun(function()
            self.SetPendingTimer = nil
            LoadingSystem:StepNext()
        end, 0.5)
    end
end

local function CreateWorldStep(self)
    log("Procedure_WildWorld:CreateWorldStep")

    local nSceneId = self.Param.nSceneId
    local tbSceneData = SceneDataTable:GetTemplate(nSceneId)
    local bIsOcean = tbSceneData and tbSceneData.nType == GameWorldDefine.Type.OCEAN or false
    ClientShell.GetClient(GWorld):SetGameStatus(bIsOcean and EPiratesGameStatus.WILD_OCEAN or EPiratesGameStatus.WILD_LAND)

    local tbSceneCreateData = {}
    tbSceneCreateData.bLoadNewMap = true
    tbSceneCreateData.nSceneId = nSceneId
    GameWorldSystem:CreateWorld(tbSceneCreateData)
end

local function OpenUIStep(self)
    local GameWorld = GameWorldSystem:GetWorld()
    if (GameWorld:IsOcean()) then
        local Param = {
            [UIDef.UI_MAIN] ={nMapID = GameWorld.nSceneId}
        }
        UIManager:PushState(UIStateDef.StateName.UI_HUB_STATE, Param, true)
        -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.ShipWildMode)
    else

        -- TODO: 打开主城UI，这里测试用ship的
        local Param = {
            [UIDef.UI_MAIN] ={ nMapID = GameWorld.nSceneId }
        }
        UIManager:PushState(UIStateDef.StateName.UI_TOWN_STATE, Param, true)
        log("Procedure_WildWorld:OnPostLoadMap open town ui")
        -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.Player)
    end

    -- play back ground music
    BGMHelper:PlayWildWorldBGM(GameWorld.nSceneId)


    -- Need optimize. Loading shouldn't be coupled with procedure.
    if not self.bSmoothTravel then
        LoadingSystem:StepNext()
    end

    -- Enter WildWorld Successfully.
end

local function OnPostLoadMap(self)
    CheckPlayerSelf(self)
    -- Need optimize. Loading shouldn't be coupled with procedure.
    if self.bSmoothTravel then
        OpenUIStep(self)
    else
        LoadingSystem:StepNext()
    end
end

local function WaitDungeonFailed(self)
    log("Procedure_WildWorld:WaitDungeonFailed")
    NetworkManager:SetPending(false)
end

local function PrepareLoading(self)
    LoadingSystem:ClearSteps()
    if(self.Param.bWaitDungeonFail) then
        LoadingSystem:AddStepMethod(self, WaitDungeonFailed)
    end
    LoadingSystem:AddStepMethod(self, CreateWorldStep)
    LoadingSystem:AddStepMethod(self, OpenUIStep)
    LoadingSystem:AddStepMethod(self, ProcessPendingPacket)
    local tbParam = {nSceneId = self.Param.nSceneId}
    LoadingSystem:Start(tbParam)
end

local function IsSameWorld(self, nSceneId)
    local CurWorld = GameWorldSystem:GetWorld()
    if CurWorld then
        return CurWorld.nSceneId == nSceneId
    end

    log("game world system is clear")

    local tbSceneData = SceneDataTable:GetTemplate(nSceneId)
    if(tbSceneData == nil) then
        logerror("is same world: not find scene ", nSceneId)
        return false
    end
    local nResId    = tbSceneData.nResID
    local tbResInfo = SceneResDataTable:GetTemplate(nResId)
    if (tbResInfo == nil) then
        logerror("is same world: not find scene res ", nResId)
        return false
    end

    local szCurrentMapName = EngineExtShell.Get(GWorld):GetCurrentMapName()

    log("is same world", szCurrentMapName, tbResInfo.szMapName)

    return tbResInfo.szMapName == szCurrentMapName
end

function Procedure_WildWorld:Begin()
    Procedure_WildWorld.super.Begin(self)
    GlobalVariableSystem:SetInDungeon(false)
    GlobalVariableSystem:SetStandalone(true)
    log("Procedure_WildWorld begin set pending true")
    NetworkManager:SetPending(true)

    ManagerRoot:InitGroup(ManagerGroupDef.nHubGroupID, true)
    self:BindEvents()

    CommonShell.GetCommon(GWorld):GetInputManager():CloseGestureSelfTouchListen()
    if not self.Param.bWaitDungeonFail then
        local nSceneId = self.Param.nSceneId
        assert(nSceneId ~= nil)

        EventManager:OnFireEvent(ClientEventDef.EV_ENTER_PROCEDURE_WILD, self.Param.nSceneId)
        -- Need optimize. Loading shouldn't be coupled with procedure.
        local pClientShell = ClientShell.GetClient(GWorld)
        self.bSmoothTravel = pClientShell:IsInSmoothTravel() or IsSameWorld(self, self.Param.nSceneId)
        if self.bSmoothTravel then
            CreateWorldStep(self)
            ProcessPendingPacket(self)
        else
            PrepareLoading(self)
        end
    else
        PrepareLoading(self)
    end
end

function Procedure_WildWorld:End()
    EventManager:OnFireEvent(ClientEventDef.EV_LEAVE_PROCEDURE_WILD)

    CommonShell.GetCommon(GWorld):GetInputManager():OpenGestureSelfTouchListen()

    UIManager:PopAllState()
    self:UnbindEvents()

    --local pClientShell = ClientShell.GetClient(GWorld)
    --GameObjectSystem:DestroyAllWithParams(not pClientShell:IsInSmoothTravel())   -- 非smoothtravel的时候需要删掉playerself actor
    GameObjectSystem:DestroyAll()
    GameWorldSystem:DestroyWorld()

    SoundManager:StopBackgroundMusic()
    self.bSmoothTravel = false
    ManagerRoot:UninitGroup(ManagerGroupDef.nHubGroupID)

    self.SetPendingTimer = nil
    -- 检查并清理timer
    Timer.CheckAndClearAllTimer()

    UninitCheckSystem:ExecCheck()

    ClientShell.GetClient(GWorld):SetGameStatus(EPiratesGameStatus.NONE)
    Procedure_WildWorld.super.End(self)
end

function Procedure_WildWorld:Uninit()
    self:UnbindEvents()
    Procedure_WildWorld.super.Uninit(self)
end

function Procedure_WildWorld:BindEvents()
    local EventHelper = SelfEventHelperClass()
    self.EventHelper = EventHelper
    EventHelper:RegisterEventFunc(ClientEventDef.EV_POST_LOAD_MAP, function()
        OnPostLoadMap(self)
    end)
end

function Procedure_WildWorld:UnbindEvents()
    if(self.EventHelper) then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
end

return Procedure_WildWorld
