
local luaclass = require("luaclass")
local GameCoreRealPlayer = luaclass("GameCoreRealPlayer")

local SelfEventHelper               = require("SelfEventHelper")
local CommonEventDef                = require("CommonEventDef")
local GlobalVariableSystem          = dynamic_require("GlobalVariableSystem")
local GameCoreProxyClient           = require("GameCoreProxyClient")
local Proto                         = require("GameCoreClientProtoNames")
local SelfTimerHelperClass          = require("SelfTimerHelper")
local Timer                         = require("Timer")
local GameCoreSyncSystem            = require("GameCoreSyncSystem")
local SyncDataRegisterRealPlayer    = require("SyncDataRegisterRealPlayer")
local GameCoreAgentLuaPoolManager   = require("GameCoreAgentLuaPoolManager")

local tbSightConfig = {
    Human = {
        PlayerRange = 10000,
        ItemRange = 4000,
        FOV = 120,
    },
    Ship = {
        PlayerRange = 100000,
        ItemRange = 60000,
        FOV = 160,
    },
}

local tbTablePoolNames = {
    "ShipRegionKey",
    "ShipKeyPosition",
    "ShipWeaponRange",
    "Sound",
    "VisibleItem",
    "PackageItem",
    "VisibleTorpedo",
    "VisiblePlayer",
    "VisibleVehicle",
    "WeaponParams",
}

GameCoreRealPlayer.tbAgent = nil
GameCoreRealPlayer.pAIController = nil
GameCoreRealPlayer.SelfEventHelper = nil
GameCoreRealPlayer.SelfTimerHelper = nil
GameCoreRealPlayer.tbGameCoreSyncSystem = nil
GameCoreRealPlayer.nTickTimer = nil
GameCoreRealPlayer.nFrame = 0
GameCoreRealPlayer.bStartSync = false
GameCoreRealPlayer.pAIControllerEndPlayDelegate = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCoreRealPlayer:", ...)
end
-- luacheck: pop

local function OnGameObjectActorCreated(self, tbGameObject)
    if tbGameObject == self.tbAgent then
        local pAIController = self.pAIController
        if pAIController then
            local tbSight = tbSightConfig.Human
            if tbGameObject:IsShip() then
                tbSight = tbSightConfig.Ship
                -- enable control rotation replicate
                tbGameObject.pUEActor.ShipMovementComponent:IncreaseViewers()
            end
            pAIController:SetSightParams(tbSight.PlayerRange, tbSight.ItemRange, tbSight.FOV)
        end
        self:StartSync()
    end
end

local function OnGameObjectActorDestroyed(self, tbGameObject)
    if tbGameObject == self.tbAgent then
        self:StopSync()
    end
end

local function OnDead(self, tbGameObject, _, nLastDamageType)
    -- if GlobalVariableSystem:IsServerLogic() and tbGameObject == self.tbAgent then
    --     self:EndTick()
    -- end
end

local function OnAIControllerDestroyed(self)
    if GlobalVariableSystem:IsServerLogic() then
        self.pAIController = nil
        self:Destroy()
        LOG("OnAIControllerDestroyed")
    end
end

local function BindAIController(self, pAIController)
    if pAIController then
        self.pAIController = pAIController
        self.pAIControllerEndPlayDelegate = self.SelfEventHelper:RegisterCppDelegate(pAIController.OnEndPlay, self, OnAIControllerDestroyed)
        local tbOwner = self.tbAgent
        local tbSight = tbSightConfig.Human
        if tbOwner:IsShip() then
            tbSight = tbSightConfig.Ship
        end
        pAIController:SetSightParams(tbSight.PlayerRange, tbSight.ItemRange, tbSight.FOV)
    end
end


local function OnPlayerLogout(self, tbGameObject)
    if tbGameObject == self.tbAgent then
        self:StopSync()
        if self.pAIControllerEndPlayDelegate then
            self.SelfEventHelper:UnregisterCppDelegate(self.pAIControllerEndPlayDelegate)
        end
        self.pAIControllerEndPlayDelegate = nil
        self.pAIController = nil
        if not tbGameObject:IsDead() then
            self:StartSync()
        end
    end
end

local function OnPlayerReLogin(self, tbGameObject)
    if tbGameObject == self.tbAgent then
        self:StopSync()
        BindAIController(self, tbGameObject:GetUEController())
        if not tbGameObject:IsDead() then
            self:StartSync()
        end
    end
end


function GameCoreRealPlayer:Create(tbGameObject)
    local EventHelper = SelfEventHelper()
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnGameObjectActorCreated)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD,      self, OnDead)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnGameObjectActorDestroyed)
    EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, OnPlayerLogout)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerReLogin)

    self.SelfEventHelper = EventHelper

    self.SelfTimerHelper = SelfTimerHelperClass()
    self.tbAgent = tbGameObject
    self.nFrame = 0
    BindAIController(self, tbGameObject:GetUEController())
    GameCoreAgentLuaPoolManager:Register(tbGameObject:GetServerInstanceId(), tbTablePoolNames)
    self.tbGameCoreSyncSystem = GameCoreSyncSystem()
    self.tbGameCoreSyncSystem:Init(self, SyncDataRegisterRealPlayer)
    self:StartSync()
    if tbGameObject:IsShip() then
        -- enable control rotation replicate
        tbGameObject.pUEActor.ShipMovementComponent:IncreaseViewers()
    end
end


function GameCoreRealPlayer:StartSync()
    self.bStartSync = true
    self.tbGameCoreSyncSystem:Start()
    self:StartTick()
end

function GameCoreRealPlayer:StopSync()
    if self.bStartSync then
        self:EndTick()
        self.tbGameCoreSyncSystem:Stop()
        self.bStartSync = false
    end
end


function GameCoreRealPlayer:GetGameObject()
    return self.tbAgent
end

function GameCoreRealPlayer:Update(nDelta, nFrame)
    self:GatherInfos(nFrame)
    if self.tbAgent:IsDead() then
        self:Destroy()
    end
end


function GameCoreRealPlayer:GatherInfos(nFrame)

    -- local nBase = collectgarbage("count")
    -- rts()

    local tbPacket = self.tbNewPacket or {}
    local tbFatState = tbPacket.bot_fat_state or {}

    self.tbGameCoreSyncSystem:Sync(tbFatState)

    tbFatState.auto_increment_key = nFrame
    tbPacket.bot_fat_state = tbFatState
    tbPacket.game_id = GameCoreProxyClient:GetCCSGameId()

    GameCoreProxyClient:Send(Proto.c2s_syncBot, tbPacket)

    self.tbNewPacket = tbPacket
    GameCoreAgentLuaPoolManager:Reset(self.tbAgent:GetServerInstanceId())

    -- rte("GameCoreRealPlayer:Gather Infos")
    -- local nFinal = collectgarbage("count")
    -- logdebug("lua memeory add:", nFinal - nBase, "K")
end

function GameCoreRealPlayer:Destroy()
    self.SelfEventHelper:UnregisterCppDelegate(self.pAIControllerEndPlayDelegate)
    self:StopSync()
    GameCoreAgentLuaPoolManager:Unregister(self.tbAgent:GetServerInstanceId())
    self.tbGameCoreSyncSystem:Uninit()
    Timer.StopOwnerAllTimer(self, true)
    self.SelfEventHelper:UnregisterAll()
    self.SelfTimerHelper:ClearAllTimer()
    LOG("destroyed")
end

function GameCoreRealPlayer:StartTick()
    if not self.nTickTimer then
        local nInterval = GameCoreProxyClient.nTickInterval
        self.nTickTimer = Timer.NewTimerMethod(self, self.Tick, nInterval, true)
        LOG("start game core agent tick ", nInterval)
    end
end

function GameCoreRealPlayer:EndTick()
    if self.nTickTimer then
        self.nTickTimer:Clear()
        self.nTickTimer = nil
    end
end

function GameCoreRealPlayer:Tick(nDelta)
    if GameCoreProxyClient.szCCSGameId then
        self.nFrame = self.nFrame + 1
        self:Update(nDelta, self.nFrame)
    end
end

return GameCoreRealPlayer