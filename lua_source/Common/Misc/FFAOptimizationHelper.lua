local EventManager      = require("EventManager")
local ResourceManager   = require("ResourceManager")
local CommonEventDef    = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local DelayTimer        = require("DelayTimer")
local GameObjectSystem  = dynamic_require("GameObjectSystem")
local BattleBlackboard  = require("BattleBlackboard")
local ParachutingNewIni = require("ParachutingNewIni")
local ProtoDR           = require("DungeonRepProtoNames")
local TransporterDataTable = require("TransporterDataTable")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

local FFAOptimizationHelper = {}

FFAOptimizationHelper.tbActiveMovementTimer = nil
FFAOptimizationHelper.tbHoldResources = nil

local RESOURCECACHE =
{
    "/Game/Game/ShipEx/BP_ShipEx.BP_ShipEx_C",
    "/Game/Game/CharacterEx/BP_NewPlayer.BP_NewPlayer_C",
    "/Game/Game/ShipEx/ShipChild/BP_Ship_MayFlower.BP_Ship_MayFlower_C"
}


local function HoldResources(self)
    local tbHoldResources = {}
    for i, v in ipairs(RESOURCECACHE) do
        local pObject = ResourceManager:LoadSync(v, true)
        table.insert(tbHoldResources, pObject)
    end
    self.tbHoldResources = tbHoldResources
end

local function UnholdResources(self)
    for i = #self.tbHoldResources, 1, -1 do
        ResourceManager:Unhold(self.tbHoldResources[i])
    end
    self.tbHoldResources = nil
end

local function SetObjectMovementActive(tbObjectTypes, bActive)
    log("SetObjectMovementActive", bActive)
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    local fnCheckObjectType = function(nType)
        for i, v in ipairs(tbObjectTypes) do
            if v == nType then
                return true
            end
        end
        return false
    end
    for nId, Object in pairs(tbObjects) do
        local pUEActor = Object.pUEActor
        if (pUEActor ~= nil) 
        and (fnCheckObjectType(Object.ObjectType)) 
        and (not Object:IsDead())
        and (Object.szTag ~= "AlwaysTick") then
            local pMovementComponent
            if Object:IsShip() then
                pMovementComponent = pUEActor.ShipMovementComponent
            else
                pMovementComponent = pUEActor.CharacterMovement
            end
            if pMovementComponent ~= nil then
                pMovementComponent:SetComponentTickEnabled(bActive)
                pMovementComponent:SetActive(bActive)
            end
        end
    end
end

local function ClearActiveMomentTimer(self)
    if self.tbActiveMovementTimer ~= nil then
        self.tbActiveMovementTimer:Clear()
        self.tbActiveMovementTimer = nil
    end
end

local function SetObjectMovementActiveTimer(self)
    local bNewLaunch = BattleBlackboard:GetBool("TransporterNewLaunch")
    local nMinTime = 10000
    if bNewLaunch then
        local tbAll = TransporterDataTable.tbContainer
        for k, v in pairs(tbAll) do
            if nMinTime > v.nLaunchTime then
                nMinTime = v.nLaunchTime
            end
        end
    else
        local tbGameMode = BattleGameModeSystem:GetGameMode()
        local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
        local nMapSize = math.max(math.ceil(tbMapSize.GamePlayWidth / 2), math.ceil(tbMapSize.GamePlayHeight / 2))
        local nSpeed = nMapSize / ParachutingNewIni.tbTransport.nTriggerTime
        nMinTime = ParachutingNewIni.tbReadyArea.nCoreAreaRadius / nSpeed
    end
    local nFlyTime = ParachutingNewIni.tbLaunch.nMaxLandHeight / ParachutingNewIni.tbParachuteNoOpen.nMaxFallSpeed
    nMinTime = nMinTime + ParachutingNewIni.tbLaunch.nLaunchTime + nFlyTime
    nMinTime = math.floor( nMinTime )

    log("SetObjectMovementActiveTimer ", nMinTime, bNewLaunch)
    self.tbActiveMovementTimer = DelayTimer:DelayRun(
        function()
            log("SetObjectMovementActiveTimer complete")
            ClearActiveMomentTimer(self)
            SetObjectMovementActive({GameObjectTypeDef.Npc}, true)
        end,
        nMinTime)
end

local function OnFFAProcessStateChanged(self, nState)
    if nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        SetObjectMovementActiveTimer(self)
    end
end

function FFAOptimizationHelper:Init()
    EventManager:BindEventMethod(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
end

function FFAOptimizationHelper:Uninit()
    ClearActiveMomentTimer(self)
    UnholdResources(self)
    EventManager:UnBindEventMethod(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
end

function FFAOptimizationHelper:Optimize()
    HoldResources(self)
    SetObjectMovementActive({GameObjectTypeDef.Npc}, false)
end

return FFAOptimizationHelper