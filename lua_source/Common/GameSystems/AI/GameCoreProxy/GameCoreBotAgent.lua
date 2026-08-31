
local luaclass = require("luaclass")
local GameCoreBotAgent = luaclass("GameCoreBotAgent")

local BattlePrepareSystem           = require("BattlePrepareSystem")
local BattleGameModeSystem          = dynamic_require("BattleGameModeSystem")
local SelfEventHelper               = require("SelfEventHelper")
local CommonEventDef                = require("CommonEventDef")
local GlobalVariableSystem          = dynamic_require("GlobalVariableSystem")
local GameCoreProxyClient           = require("GameCoreProxyClient")
local Proto                         = require("GameCoreClientProtoNames")
local GameObjectSystem              = dynamic_require("GameObjectSystem")
local HumanMovementStateType        = require("HumanMovementStateType")
local SelfTimerHelperClass          = require("SelfTimerHelper")
local Timer                         = require("Timer")
local GameCoreWatchSystem           = dynamic_require("GameCoreWatchSystem")
local CarronadeEffectDef            = require("CarronadeEffectDef")
local GameCoreAgentLuaPoolManager   = require("GameCoreAgentLuaPoolManager")
local InitItemDataTable             = require("InitItemDataTable")
local InitItemIni                   = require("InitItemIni")
local GameCoreSyncSystem            = require("GameCoreSyncSystem")
local GameCoreActionActorType       = require("GameCoreActionActorType")
local SyncDataRegisterBot           = require("SyncDataRegisterBot")
local DamageTypeEx                  = require("DamageTypeEx")
local GameCoreVariable              = require("GameCoreVariable")
local AgentStatisticsSystem         = require("AgentStatisticsSystem")
--local AIDebug                       = require("AIDebug")

local RegionTypeOcean = EPiratesGridRegionType.Ocean
local RegionTypePort  = EPiratesGridRegionType.Port


local nMaxVisibleItem = 10

local tbSightConfig = {
    Human = {
        PlayerRange = 100000,
        ItemRange = 4000,
        FOV = 120,
    },
    Ship = {
        PlayerRange = 140000,
        ItemRange = 60000,
        FOV = 160,
    },
}

local nHumanListenRange = 10000
local nShipListenRange  = 100000

local DoorAction = {
    Open = 1,
    Close = 2,
}

local tbTransform = Transform()


GameCoreBotAgent.tbAgent = nil
GameCoreBotAgent.SelfEventHelper = nil
GameCoreBotAgent.nID = 0
GameCoreBotAgent.pAIController = nil
GameCoreBotAgent.pBlackboard = nil
GameCoreBotAgent.pBehaviorTree = nil
GameCoreBotAgent.bStartAI = false
GameCoreBotAgent.tbBornPosition = nil
GameCoreBotAgent.SelfTimerHelper = nil
GameCoreBotAgent.tbSwimTimer = nil
GameCoreBotAgent.nCarronadeEffectType = CarronadeEffectDef.BOOM
GameCoreBotAgent.bStucked = false
GameCoreBotAgent.pAIControllerEndPlayDelegate = nil
GameCoreBotAgent.pDelegateEnterDoor = nil
GameCoreBotAgent.pDelegateLeaveDoor = nil
GameCoreBotAgent.nDoorAction = 0
GameCoreBotAgent.nDoorInstanceId = 0
GameCoreBotAgent.bUseBTWhenShip = false
GameCoreBotAgent.nLastThrowAttackTime = 0 -- 上次扔投掷物的时间
GameCoreBotAgent.nStyle = 0 --机器人风格
GameCoreBotAgent.tbGameCoreSyncSystem = nil
GameCoreBotAgent.nTickTimer = nil
GameCoreBotAgent.nFrame = 0
GameCoreBotAgent.nDeadReason = 0
GameCoreBotAgent.nAILevel = 0
GameCoreBotAgent.tbIgnoredPacketIds = nil
GameCoreBotAgent.nDeadTemplateType = 0

local tbTablePoolNames = {
    "ShipRegionKey",
    "ShipKeyPosition",
    "ShipWeaponRange",
    "Sound",
    "VisibleItem",
    "PackageItem",
    "VisibleTorpedo",
    "Smoke",
    "VisiblePlayer",
    "VisibleVehicle",
    "WeaponParams",
}

local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()

local szControllerClass = "Blueprint'/Game/Game/AI/AISegma/GameCoreProxy/BP_AgentController.BP_AgentController_C'"
local szBlackboardClass = "BlackboardData'/Game/Game/AI/AISegma/GameCoreProxy/BB_Agent.BB_Agent'"
local szBehaviorTreeClass = "BehaviorTree'/Game/Game/AI/AISegma/GameCoreProxy/BT_Agent.BT_Agent'"


-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCoreBotAgent:", ...)
end
-- luacheck: pop

local function OnAIControllerDestroyed(self)
    if GlobalVariableSystem:IsServerLogic() then
        self.pAIController = nil
        self.pBlackboard = nil
        self:Destroy()
        LOG("OnAIControllerDestroyed")
    end
end


local function CreateBotPrepareInfo(nPlayerId, szPlayerName, nGroupIndex)
    -- 初始物品
    local nHumanId = 100000
    local tbPrepareInfo = BattlePrepareSystem:CreatePlayerInfo(
        nPlayerId,
        szPlayerName,
        nHumanId,
        nGroupIndex)
    tbPrepareInfo:SetInitItems(InitItemDataTable:GetItems(InitItemIni.tbDeepLearning.nInitItemGroupId))
    tbPrepareInfo:SetDefaultShipPreparation()
    tbPrepareInfo:SetIsBot()
    return tbPrepareInfo
end


local function UpdateDoorState(self)
    self.nDoorAction = 0
    if self.nDoorInstanceId > 0 then
        local tbGameDoor = GameObjectSystem:FindByInstanceId(self.nDoorInstanceId)
        if tbGameDoor and tbGameDoor.pUEActor and not tbGameDoor:IsDead() then
            local pUEActor = tbGameDoor.pUEActor
            local nCurState = enumtoint(pUEActor:GetCurState())
            if nCurState == 0 then
                self.nDoorAction = DoorAction.Open
            else
                self.nDoorAction = DoorAction.Close
            end
            return
        end
    end
end


local function OnGameObjectActorCreated(self, tbGameObject)
    if tbGameObject == self.tbAgent then
        if self:ShouldStartAI() then
            self:StartAI()
        else
            tbGameObject.SAIComponent:StartAI()
        end
    end
end

local function OnGameObjectActorDestroyed(self, tbGameObject)
    if tbGameObject == self.tbAgent then
        self:StopAI()
    end
end

-- local function NotifyBotDead(self, nLastDamageType)
--     local tbPacket = {}
--     tbPacket.id = self.tbAgent.nServerInstanceId
--     tbPacket.damage_type = nLastDamageType
--     GameCoreProxyClient:Send(Proto.c2s_notifyBotDead, tbPacket)
--     log("[NotifyBotDead]", t2s(tbPacket))
-- end

local function OnDead(self, tbGameObject, _, nLastDamageType)
    if GlobalVariableSystem:IsServerLogic() and tbGameObject == self.tbAgent and self.pAIController then
        LOG("ai agent dead ", self.nID)
        --NotifyBotDead(self, nLastDamageType)
         -- for debug purpose
        if GlobalVariableSystem.bShowDLAgentName then
            self:ShowName(false)
        end

        if self.nDeadReason <= 0 then
            local tbAgentStatistics = AgentStatisticsSystem:Get(tbGameObject.nServerInstanceId)
            if tbAgentStatistics and tbAgentStatistics:IsDamagedInSeconds(5) then
                self.nDeadReason = tbAgentStatistics.nLastWeaponDamagedType
            else
                self.nDeadReason = nLastDamageType
            end
        end

        self.nDeadTemplateType = tbGameObject:GetTemplateType()
        if nLastDamageType == DamageTypeEx.FALLING then
            local nX, nY, nZ = tbGameObject:GetLocationXYZ()
            LOG("falling dead at:", nX, nY, nZ, tbGameObject.szName)
        end
    end
end

local function OnChangedToSwim(self, tbGameObject, bEnable)
    if GlobalVariableSystem:IsServerLogic() and tbGameObject == self.tbAgent and self.pAIController then
        if bEnable and not self.tbSwimTimer and tbGameObject:IsHuman() then
            self.tbSwimTimer = self.SelfTimerHelper:NewTimerMethod(self, self.CheckSwim, 1, true)
        else
            self:StopSwim()
        end
    end
end

function GameCoreBotAgent:SetUseBTWhenShip(bEnable)
    self.bUseBTWhenShip = bEnable
end

function GameCoreBotAgent:ShouldStartAI()
    return (not self.bUseBTWhenShip) or self.tbAgent:IsHuman()
end

function GameCoreBotAgent:StopSwim()
    if self.tbSwimTimer then
        self.tbSwimTimer:Clear()
        self.tbSwimTimer = nil
        local tbAgent = self.tbAgent
        if tbAgent:IsHuman() then
            local HumanMovementStateComponent = tbAgent.HumanMovementStateComponent
            HumanMovementStateComponent:SetMovementState(HumanMovementStateType.UpRight_State)
        end
    end
end

function GameCoreBotAgent:CheckSwim()
    local bStopCheck = false
    local tbAgent = self.tbAgent
    if tbAgent:IsHuman() then
        local pLocation = tbAgent:GetLocation()
        local CharacterMovement = tbAgent.pUEActor.CharacterMovement
        local bShouldSwim = CharacterMovement.SwimLocationZ >= pLocation.Z
        local HumanMovementStateComponent = tbAgent.HumanMovementStateComponent
        if HumanMovementStateComponent:GetCurrentState() ~= HumanMovementStateType.Swimming then
            if bShouldSwim then
                self.tbAgent.HumanMovementStateComponent:SetMovementState(HumanMovementStateType.Swimming)
            end
        else
            if not bShouldSwim then
                bStopCheck = true
            end
        end
    else
        bStopCheck = true
    end
    if bStopCheck and self.tbSwimTimer then
        self:StopSwim()
    end
end

local function OnPawnDying(self, tbGameObject, bIsDying)
    if tbGameObject == self.tbAgent then
        if bIsDying then
            local tbAgentStatistics = AgentStatisticsSystem:Get(tbGameObject.nServerInstanceId)
            if tbAgentStatistics then
                if tbAgentStatistics:IsDamagedInSeconds(5) then
                    self.nDeadReason = tbAgentStatistics.nLastWeaponDamagedType
                else
                    self.nDeadReason = tbAgentStatistics.nLastDamagedType
                end
            end
        end
    end
end

function GameCoreBotAgent:Init()
    local EventHelper = SelfEventHelper()
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnGameObjectActorCreated)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD,      self, OnDead)
    EventHelper:RegisterEvent(CommonEventDef.EV_NOTIFY_BOT_CHANGED_TO_SWIM, self, OnChangedToSwim)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnGameObjectActorDestroyed)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED, self, OnPawnDying)


    self.SelfEventHelper = EventHelper
    self.SelfTimerHelper = SelfTimerHelperClass()
end

function GameCoreBotAgent:CreateAI()
    local pCClass = szControllerClass:load()
    local pController = EngineExtActorShell.SpawnActorForScript(GWorld, pCClass, tbTransform, nil)
    local pBBClass = szBlackboardClass:load()
    self.pBlackboard   = pController:UseBlackboard(pBBClass)
    self.pAIController = pController
    self.nFrame = 0
    self.tbIgnoredPacketIds = {}
    self.tbGameCoreSyncSystem = GameCoreSyncSystem()
    self.tbGameCoreSyncSystem:Init(self, SyncDataRegisterBot)
    pController.GoodsDetectComponent.MaxVisibelItemNum = nMaxVisibleItem
    GameCoreAgentLuaPoolManager:Register(self.tbAgent:GetServerInstanceId(), tbTablePoolNames)
    self.pAIControllerEndPlayDelegate = self.SelfEventHelper:RegisterCppDelegate(pController.OnEndPlay, self, OnAIControllerDestroyed)
end

function GameCoreBotAgent:GetBotType()
    local AIHelper = require("AIHelper")
    local bHasRealPlayerTeammate = AIHelper:HasRealPlayerTeammate(self.tbAgent)
    local nPersonality = bHasRealPlayerTeammate and 4 or self.nStyle
    local tbStyleId = {
        [0] = 2,
        [1] = 3,
        [2] = 4,
        [3] = 5,
        [4] = 6,
    }
    return tbStyleId[nPersonality] * 100 + self.nAILevel
end

function GameCoreBotAgent:ShowName(bShow)
    local PropName = require("PropName")
    local tbGameObject = self.tbAgent
    if tbGameObject:IsShip() then
        local ShipBattlePropertyComponent = tbGameObject.ShipBattlePropertyComponent
        ShipBattlePropertyComponent :SetPropOriginValue(PropName.nShipBotType,  bShow and self:GetBotType() or 0)
    else
        local HumanBattlePropertyComponent = tbGameObject.HumanBattlePropertyComponent
        HumanBattlePropertyComponent:SetPropOriginValue(PropName.nHumanBotType, bShow and self:GetBotType() or 0)
    end
end

local function OnEnterDoor(self, nInstanceId)
    self.nDoorInstanceId = nInstanceId
    LOG("enter door ", nInstanceId)
end

local function OnLeaveDoor(self, nInstanceId)
    self.nDoorInstanceId = 0
    LOG("leave door ", nInstanceId)
end

function GameCoreBotAgent:EnableDoorDetect(bEnable)
    local pDoorDetectComp = self.pAIController.DoorDetectComponent
    if pDoorDetectComp then
        LOG("set door detect:", bEnable)
        pDoorDetectComp:SetEnable(bEnable)
        if self.pDelegateEnterDoor then
            self.SelfEventHelper:UnregisterCppDelegate(self.pDelegateEnterDoor)
            self.pDelegateEnterDoor =  nil
        end
        if self.pDelegateLeaveDoor then
            self.SelfEventHelper:UnregisterCppDelegate(self.pDelegateLeaveDoor)
            self.pDelegateLeaveDoor =  nil
        end
        if bEnable then
            self.pDelegateEnterDoor = self.SelfEventHelper:RegisterCppDelegate(pDoorDetectComp.EnterDoor, self, OnEnterDoor)
            self.pDelegateLeaveDoor = self.SelfEventHelper:RegisterCppDelegate(pDoorDetectComp.LeaveDoor, self, OnLeaveDoor)
        end
    end
end

function GameCoreBotAgent:EnableVehicleDetect(bEnable, SightDistance, Fov)
    local pVehicleDetectComp = self.pAIController.VehicleDetectComponent
    if pVehicleDetectComp then
        LOG("set vehicle detect:", bEnable, SightDistance, Fov)
        pVehicleDetectComp:SetEnable(bEnable)
        if bEnable then
            pVehicleDetectComp.SightDistance = SightDistance
            pVehicleDetectComp.SightFOV = Fov
        end
    end
end

function GameCoreBotAgent:EnableOceanGridDetect(bEnable, SightDistance, Fov)
    local pOceanGridDetectComponent = self.pAIController.OceanGridDetectComponent
    if pOceanGridDetectComponent then
        LOG("set ocean grid detect:", bEnable, SightDistance, Fov)
        pOceanGridDetectComponent:SetEnable(bEnable)
        if bEnable then
            pOceanGridDetectComponent.SightDistance = SightDistance
            pOceanGridDetectComponent.SightFOV = Fov
        end
    end
end

function GameCoreBotAgent:StartAI()
    local pAIController = self.pAIController
    local tbOwner = self.tbAgent
    local pUEActor = tbOwner.pUEActor
    if pAIController and pUEActor then
        if tbOwner:IsHuman() then
            local pHumanMovementComponent = pUEActor:GetHumanMovementComponent()
            pHumanMovementComponent.bUseControllerDesiredRotation = true
            pHumanMovementComponent.RotationRate.Yaw = 720
            -- diable new jump for agent
            pHumanMovementComponent.bUseNewJump = false
        else
            pAIController.bSetControlRotationFromPawnOrientation = false
        end
        pUEActor.bUseControllerRotationYaw = false
        pUEActor.bUseControllerRotationPitch = false
        pUEActor.bUseControllerRotationRoll = false
        local pBehaviorTree = szBehaviorTreeClass:load()
        if pAIController:RunBehaviorTree(pBehaviorTree) then
            pAIController:Possess(pUEActor)
        else
            logerror("run behavior tree return false")
        end
        pAIController.GoodsDetectComponent.bIsShip = tbOwner:IsShip()
        local tbSight = tbSightConfig.Human
        local nListenRange = nHumanListenRange
        if tbOwner:IsShip() then
            tbSight = tbSightConfig.Ship
            nListenRange = nShipListenRange
        end
        pAIController:SetSightParams(tbSight.PlayerRange, tbSight.ItemRange, tbSight.FOV)
        pAIController:ConfigHeard(nListenRange)
        pAIController.SmokeDetectComponent.QueryRadius = tbSight.PlayerRange
        self.bStartAI = true
        self:EnableDoorDetect(tbOwner:IsHuman())
        self:EnableVehicleDetect(tbOwner:IsHuman(), tbSight.PlayerRange, tbSight.FOV)
        self:EnableOceanGridDetect(tbOwner:IsShip(), tbSight.PlayerRange, tbSight.FOV)
        self.tbGameCoreSyncSystem:Start()
        self:StartTick()

        -- for debug purpose
        if GlobalVariableSystem.bShowDLAgentName then
            self:ShowName(true)
        end
        --
        LOG("start ai")
    end
end

function GameCoreBotAgent:GetGameObject()
    return self.tbAgent
end

function GameCoreBotAgent:IsValid()
    return self.bStartAI
end

function GameCoreBotAgent:CanDoAction(nActorType)
    local tbGameObject = self.tbAgent
    if self.bStartAI and tbGameObject and not tbGameObject:IsDead() then
        if tbGameObject:IsHuman() then
            if tbGameObject.HumanMovementStateComponent:IsInVehicle() then
                return nActorType & GameCoreActionActorType.Horse > 0
            else
                return nActorType & GameCoreActionActorType.Human > 0
            end
        else
            return nActorType & GameCoreActionActorType.Ship > 0
        end
    end
    return false
end

function GameCoreBotAgent:StopAI()
    LOG("stop ai")
    Timer.StopOwnerAllTimer(self, true)
    -- for debug purpose
    if GlobalVariableSystem.bShowDLAgentName then
        self:ShowName(false)
    end
    --
    self:EndTick()
    if self.tbGameCoreSyncSystem then
        self.tbGameCoreSyncSystem:Stop()
    end
    local pAIController = self.pAIController
    if pAIController and isvalidhandle(pAIController) then
        self:EnableDoorDetect(false)
        self:EnableVehicleDetect(false)
        self:EnableOceanGridDetect(false)
        pAIController:UnPossess()
    end
    self.bStartAI = false
end

function GameCoreBotAgent:Update(nDelta, nFrame)
    if not self.pAIController then
        return
    end
    if self.bStartAI then
        self:TickIgnoredPackets()
        self:GatherInfos(nFrame)
    end
    if self.tbAgent:IsDead() then
        self:Destroy()
    end
end


function GameCoreBotAgent:GatherInfos(nFrame)

    -- local nBase = collectgarbage("count")
    -- rts()

    UpdateDoorState(self)

    local tbAgent = self.tbAgent
    local tbPacket = self.tbNewPacket or {}
    local tbFatState = tbPacket.bot_fat_state or {}

    self.tbGameCoreSyncSystem:Sync(tbFatState)

    tbFatState.poisoncircle = tbFatState.poisoncircle or { }
    GameCoreProxyClient:GetPoisonCircleInfo(tbFatState.poisoncircle)

    tbFatState.stucked = self.bStucked
    tbFatState.auto_increment_key = nFrame
    tbFatState.door_action = self.nDoorAction
    tbFatState.sync_time_ms = 0--math.floor(getseconds() * 1000)

    tbPacket.bot_fat_state = tbFatState
    tbPacket.game_id = GameCoreProxyClient:GetCCSGameId()

    GameCoreProxyClient:Send(Proto.c2s_syncBot, tbPacket)

    self.tbNewPacket = tbPacket
    GameCoreAgentLuaPoolManager:Reset(tbAgent:GetServerInstanceId())

    -- rte("GameCoreBotAgent:Gather Infos")
    -- local nFinal = collectgarbage("count")
    -- logdebug("lua memeory add:", nFinal - nBase, "K")

    if GameCoreWatchSystem.bEnabled then
        if GameCoreWatchSystem:HasWacther(tbAgent) then
            local tbWatcherPacket = { }
            tbWatcherPacket.state = tbFatState
            GameCoreWatchSystem:RepSourceStatus(tbAgent, tbWatcherPacket)
        end
    end

end

function GameCoreBotAgent:Possessed(nID, tbGameObject)
    assert(not self.tbAgent)

    self.tbAgent = tbGameObject
    self.nID = nID
    if tbGameObject:IsHuman() then
        self.bStucked = EngineExtActorShell.IsPawnLocationBlocked(GWorld, tbGameObject.pUEActor)
        if self.bStucked then
            local tbLocation = tbGameObject:GetLocation()
            log("agent stucked possessed before ", tbGameObject.szName, tbLocation.X, tbLocation.Y, tbLocation.Z)
            EngineExtActorShell.MovePawnToSafeLocation(GWorld, tbGameObject.pUEActor)
            tbLocation = tbGameObject:GetLocation()
            log("agent stucked possessed after ",  tbGameObject.szName, tbLocation.X, tbLocation.Y, tbLocation.Z)
        end
    end

    self:CreateAI()

    local AIComponent = tbGameObject.SAIComponent
    AIComponent:SetAutoStartAI(false)
    if self:ShouldStartAI() then
        AIComponent:StopAI()
    self:StartAI()
    end

    return true
end

function GameCoreBotAgent:Create(nID, nX, nY, nZ, nTeamId, bAutoTeleport)
    assert(not self.tbAgent)
    local nRadius = 0
    if bAutoTeleport then
        nRadius = 100
    end
    local nRegionType = GridTypeManager:GetRegionType(nX, nY)
    local bShip = false
    if nRegionType == RegionTypeOcean or nRegionType == RegionTypePort then
        bShip = true
    end
    if bShip then
        self.tbBornPosition = { X = nX, Y =  nY, Z =  nZ }
    else
        local pLocation = ExtendBlueprintFunctions.GetAISafePosition(GWorld, Vector{X = nX, Y = nY, Z = nZ}, nRadius, 20000, -10000)
        self.tbBornPosition = { X = pLocation.X, Y =  pLocation.Y, Z =  pLocation.Z }
    end

    local nAgentId = -nID
    local szAgentName = ("Agent_" .. nID)
    local nGroupIndex = nTeamId
    local tbBotPrepareInfo = CreateBotPrepareInfo(nAgentId, szAgentName, nGroupIndex)
    local tbBot = BattleGameModeSystem:CreatePlayerSelf(tbBotPrepareInfo, nil, nil, 0)
    if not tbBot then
        logerror("GameCoreBotAgent-> create agent fail, id ", nID)
        return false
    end
    self.tbAgent = tbBot
    self.nID = nID
    if not BattleGameModeSystem:SpawnPlayerPawn(tbBot, false) then
        logerror("GameCoreBotAgent-> spawn agent fail, id ", nID)
        return false
    end
    --BattlePrepareSystem:AddBotPrepareInfo(tbBotPrepareInfo)
    --tbBot.bIsBot = true
    BattleGameModeSystem:OnPlayerLogin(tbBot)
    tbBot:SetLocation(self.tbBornPosition.X, self.tbBornPosition.Y, self.tbBornPosition.Z)
    if bShip then
        self.SelfTimerHelper:RunNextTick(function()
            local nShipId = tbBot:GetShipTemplateId()
            BattleGameModeSystem:GetGameMode():ChangeToShip(tbBot, nShipId, Vector{X = nX, Y = nY, Z = nZ})
            self:CreateAI()
            self:StartAI()
        end)
    else
        self.bStucked = EngineExtActorShell.IsPawnLocationBlocked(GWorld, tbBot.pUEActor)
        LOG("born stucked ", szAgentName, self.bStucked, bAutoTeleport, nRadius)
        self:CreateAI()
        self:StartAI()
    end

    return true
end

function GameCoreBotAgent:Destroy()
    self:ClearIgnoredPackets()
    self.SelfEventHelper:FireEvent(CommonEventDef.EV_GAMECORE_AGENT_DESTROY, self)
    Timer.StopOwnerAllTimer(self, true)
    self:StopAI()
    self:DestroyAI()
    self.SelfEventHelper:UnregisterAll()
    self.SelfTimerHelper:ClearAllTimer()
    self.tbSwimTimer = nil
    LOG("destroyed")
end

function GameCoreBotAgent:DestroyAI()
    GameCoreAgentLuaPoolManager:Unregister(self.tbAgent:GetServerInstanceId())
    if not self.pAIController or not isvalidhandle(self.pAIController) then
        return
    end
    self.tbGameCoreSyncSystem:Uninit()
    self.SelfEventHelper:UnregisterCppDelegate(self.pAIControllerEndPlayDelegate)
    self.pAIController:UnPossess()
    EngineExtActorShell.DestroyActor(GWorld, self.pAIController)
    self.pAIController = nil
    self.pBlackboard = nil
    self.pBehaviorTree = nil
    self.bStartAI = false
    self.tbGameCoreSyncSystem = nil
    LOG("agent destroy ai")
end


function GameCoreBotAgent:SetAIStyle(nStyle)
    self.nStyle = nStyle
    LOG("set ai style:", nStyle)
    -- for debug purpose
    if GlobalVariableSystem.bShowDLAgentName then
        self:ShowName(true)
    end
end

function GameCoreBotAgent:SetAILevel(nLevel)
    self.nAILevel = nLevel
    LOG("set ai level:", nLevel)
    -- for debug purpose
    if GlobalVariableSystem.bShowDLAgentName then
        self:ShowName(true)
    end
end

function GameCoreBotAgent:StartTick()
    if not self.nTickTimer then
        local nInterval = GameCoreProxyClient.nTickInterval
        self.nTickTimer = Timer.NewTimerMethod(self, self.Tick, nInterval, true)
        LOG("start game core agent tick ", nInterval)
    end
end

function GameCoreBotAgent:EndTick()
    if self.nTickTimer then
        self.nTickTimer:Clear()
        self.nTickTimer = nil
    end
end

function GameCoreBotAgent:Tick(nDelta)
    if GameCoreProxyClient.szCCSGameId then
        self.nFrame = self.nFrame + 1
        self:Update(nDelta, self.nFrame)
    end
end

function GameCoreBotAgent:AddAirDrops(tbBoxItem)
    if self.pAIController then
        local pGoodsDetectComponent = self.pAIController.GoodsDetectComponent
        local nInstanceId = tbBoxItem:GetInstanceId()
        local nTemplateId = tbBoxItem:GetTemplateId()
        local pLocation   = tbBoxItem:GetSceneActor():GetLocation()
        pGoodsDetectComponent:AddGlobalItem(nInstanceId, pLocation, nTemplateId)
    end
end



function GameCoreBotAgent:GetChargedAttackTime()
    if self.tbAgent:IsHuman() then
        local WeaponComponent = self.tbAgent.HumanWeaponComponent
        local tbWeaponInst = WeaponComponent:GetCurrentWeapon()
        if tbWeaponInst and tbWeaponInst.GetRemainingPreAttackTime then
            return tbWeaponInst:GetRemainingPreAttackTime()
        end
    end
    return 0
end

function GameCoreBotAgent:AddIngorePacket(szPacketId, nIngoreTime)
    local nCurrentCounter = self.tbIgnoredPacketIds[szPacketId]
    local nNewCounter = nIngoreTime // GameCoreVariable.nDefaultTickInterval + 1
    if not nCurrentCounter or nNewCounter > nCurrentCounter then
        self.tbIgnoredPacketIds[szPacketId] = nNewCounter
        LOG("add ingore packet:", self.tbAgent.szName, szPacketId, nNewCounter)
    end
end

function GameCoreBotAgent:RemoveIngorePacket(szPacketId)
    self.tbIgnoredPacketIds[szPacketId] = nil
end

function GameCoreBotAgent:IsPacketIgnored(szPacketId)
    local nCounter = self.tbIgnoredPacketIds[szPacketId]
    return nCounter and nCounter > 0
end

function GameCoreBotAgent:ClearIgnoredPackets()
    for k,v in pairs(self.tbIgnoredPacketIds) do
        self.tbIgnoredPacketIds[k] = nil
    end
end

function GameCoreBotAgent:TickIgnoredPackets()
    for k,v in pairs(self.tbIgnoredPacketIds) do
        if v and v > 0 then
            self.tbIgnoredPacketIds[k] = v - 1
        end
    end
end

return GameCoreBotAgent