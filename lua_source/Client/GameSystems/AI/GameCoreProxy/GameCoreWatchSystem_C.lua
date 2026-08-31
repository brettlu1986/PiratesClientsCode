local luaclass           = require("luaclass")
local GameCoreWatchSystem   = require("GameCoreWatchSystem")
local GameCoreWatchSystem_C = luaclass("GameCoreWatchSystem_C", GameCoreWatchSystem)
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local UIManager = require("UIManager")
local UIStateDef = require("UIStateDef")
local CommonEventDef = require("CommonEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIUtils = require("UIUtils")

GameCoreWatchSystem_C.tbWatchStatus = nil
GameCoreWatchSystem_C.tbCurrentWatchBot = nil
GameCoreWatchSystem_C.tbTeamInfo = nil
GameCoreWatchSystem_C.tbFFAInfo = nil
GameCoreWatchSystem_C.nCurrentWatchId = -1
GameCoreWatchSystem_C.nCurrentWatchVehicleId = -1
GameCoreWatchSystem_C.bWaitForCreate = false
GameCoreWatchSystem_C.bWaitForVehicleCreate = false -- 避免切到骑马的bot身上时，马还没rep导致bot位置错误

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCoreWatchSystem_C:", ...)
end
-- luacheck: pop

local function IsBotWatchMode()
    local ActiveUIState = UIManager:GetActiveState()
    return ActiveUIState and  ActiveUIState.szName == UIStateDef.StateName.UI_BOT_WATCH_STATE
end

local function IsBeingWatchedBot(self, tbGameObject)
    return self.tbCurrentWatchBot and self.tbCurrentWatchBot.nServerInstanceId == tbGameObject.nServerInstanceId
end

local function OnWatchBot( self, tbBotObject )
    self.tbCurrentWatchBot = tbBotObject
    self.SelfEventHelper:FireEvent(ClientEventDef.EV_SET_WATCH_BOT_SOUND_TARGET, true, self.tbCurrentWatchBot)

    if not IsBotWatchMode() then
        UIManager:PushState(UIStateDef.StateName.UI_BOT_WATCH_STATE, { tbCurrentWatchBot = self.tbCurrentWatchBot })
    else
        self.SelfEventHelper:FireEvent(ClientEventDef.EV_REFRESH_WATCH_BOT, self.tbCurrentWatchBot)
    end
end

local function FinishWatchBot( self )
    UIManager:PopState(UIStateDef.StateName.UI_BOT_WATCH_STATE)
    local pActor = GamePlayerSelfHelper:GetUEActor()
    self.SelfEventHelper:FireEvent(ClientEventDef.EV_SET_WATCH_BOT_SOUND_TARGET, false)
    ExtendBlueprintFunctions.LoadLevelsImmediatelyByLocation(GWorld, pActor:K2_GetActorLocation())
end

local function OnActorCreate(self, tbGameObject)
    local bCanWatch = false
    local nCreateInsId = tbGameObject:GetServerInstanceId()
    if self.bWaitForCreate then   
        if nCreateInsId == self.nCurrentWatchId then
            self.bWaitForCreate = false
            bCanWatch = true
            LOG("OnActorCreate, bot is created", nCreateInsId, self.bWaitForCreate, self.bWaitForVehicleCreate, bCanWatch)
        end
    end

    if self.bWaitForVehicleCreate then
        if nCreateInsId == self.nCurrentWatchVehicleId then
            self.bWaitForVehicleCreate = false
            bCanWatch = true
            LOG("OnActorCreate, vehicle is created", nCreateInsId, self.bWaitForCreate, self.bWaitForVehicleCreate, bCanWatch)

            if self.bWaitForCreate then
                local tbBotObject = GameObjectSystem:FindByInstanceId(self.nCurrentWatchId)
                if tbBotObject and tbBotObject.pUEActor then
                    LOG("OnActorCreate, on vehicle created bot already exists")
                    self.bWaitForCreate = false
                end
            end

        end
    end
    
    if (not self.bWaitForCreate) and (not self.bWaitForVehicleCreate) and bCanWatch then
        if nCreateInsId ~= self.nCurrentWatchId then
            tbGameObject = GameObjectSystem:FindByInstanceId(self.nCurrentWatchId)
        end
        self:ChangeToWatchBot(tbGameObject)
    end

    if not IsBotWatchMode() then
        return
    end

    if IsBeingWatchedBot(self, tbGameObject) then
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "toggleBotAim 0", nil)
        self.SelfEventHelper:FireEvent(ClientEventDef.EV_WATCH_BOT, tbGameObject)
        if tbGameObject:IsHuman() then
            self.SelfEventHelper:FireEvent(ClientEventDef.EV_SET_CAMERA_FORBOT, true, tbGameObject)
        else
            self.SelfEventHelper:FireEvent(ClientEventDef.EV_SET_CAMERA_FORBOT, false, tbGameObject)
        end
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "toggleBotAim 1", nil)
    end
   
end

local function OnActorDestroy(self, tbGameObject)
    if not IsBotWatchMode() then
        return
    end

    if IsBeingWatchedBot(self, tbGameObject) then
        local GCMgr = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        GCMgr:UnInitCameraForDead()
        self.SelfEventHelper:FireEvent(ClientEventDef.EV_WATCH_BOT_DESTROY)
    end
end

local function OnFFAInfoChanged(self, rInfo)
    self.tbFFAInfo = rInfo
end

function GameCoreWatchSystem_C:Init()
    GameCoreWatchSystem_C.super.Init(self)

    self.tbWatchStatus = {}
    local EventHelper = self.SelfEventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_WATCH_BOT, self, OnWatchBot)
    EventHelper:RegisterEvent(ClientEventDef.EV_WATCH_BOT_OVER, self, FinishWatchBot)

    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnActorCreate)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnActorDestroy)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_INFO_CHANGED, self, OnFFAInfoChanged)
end

function GameCoreWatchSystem_C:SyncBot(tbPacket)
    self.tbWatchStatus = tbPacket
    EventManager:OnFireEvent(ClientEventDef.EV_SYNC_BOT_INFO, self.tbWatchStatus)
end

function GameCoreWatchSystem_C:SyncBotTeamInfo(tbPacket)
    self.tbTeamInfo = tbPacket
    EventManager:OnFireEvent(ClientEventDef.EV_SYNC_BOT_TEAM, tbPacket)
end

function GameCoreWatchSystem_C:IsTeammate(tbGameObject)
    local nServerInstanceId = tbGameObject.nServerInstanceId
    if self.tbCurrentWatchBot and self.tbTeamInfo then
        for i,v in ipairs(self.tbTeamInfo.teammates) do
            if v.nInstanceId == nServerInstanceId then
                return true
            end
        end
    end
    return false
end

function GameCoreWatchSystem_C:ChangeToWatchBot(tbWatchObj)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "toggleBotAim 0", nil)
    self.tbCurrentWatchBot = tbWatchObj
    local bHuman = self.tbCurrentWatchBot:IsHuman()
    EventManager:OnFireEvent(ClientEventDef.EV_SET_CAMERA_FORBOT, bHuman, self.tbCurrentWatchBot)
    self.SelfEventHelper:FireEvent(ClientEventDef.EV_WATCH_BOT, self.tbCurrentWatchBot)
    ExtendBlueprintFunctions.LoadLevelsImmediatelyByLocation(GWorld, self.tbCurrentWatchBot.pUEActor:K2_GetActorLocation())
    if bHuman then
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "xsj.usepawnlocforwc 0", nil)
    else  
        KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "xsj.usepawnlocforwc 1", nil)
    end
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "dm toggleBot " .. self.nCurrentWatchId, nil)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "toggleBotAim 1", nil)
end

function GameCoreWatchSystem_C:TryChangeToWatchBot(nWillWatchId, nWillWatchVehicleId)
    if nWillWatchId > 0 then
        self.bWaitForCreate = false
        self.nCurrentWatchId = nWillWatchId
        local tbWillWatchObj = GameObjectSystem:FindByInstanceId(nWillWatchId)
        if not (tbWillWatchObj and tbWillWatchObj.pUEActor) then
            LOG("TryChangeToWatchBot wait for bot create", self.nCurrentWatchId)
            self.bWaitForCreate = true
        end

        self.bWaitForVehicleCreate = false
        if nWillWatchVehicleId > 0 then
            LOG("TryChangeToWatchBot nWillWatchVehicleId=", nWillWatchVehicleId)
            self.nCurrentWatchVehicleId = nWillWatchVehicleId
            local tbVehicle = GameObjectSystem:FindByInstanceId(nWillWatchVehicleId)
            if not (tbVehicle and tbVehicle.pUEActor) then
                LOG("TryChangeToWatchBot wait for vehicle create", nWillWatchVehicleId)
                self.bWaitForVehicleCreate = true
            end
        end

        if not (self.bWaitForCreate or self.bWaitForVehicleCreate) then
            self:ChangeToWatchBot(tbWillWatchObj)
        end
    else   
        UIUtils.ShowToast("can not toggle to current bot") -- is GM
    end
end

function GameCoreWatchSystem_C:Uninit()
    GameCoreWatchSystem_C.super.Uninit(self)

    self.tbWatchStatus = {}
end

return GameCoreWatchSystem_C()