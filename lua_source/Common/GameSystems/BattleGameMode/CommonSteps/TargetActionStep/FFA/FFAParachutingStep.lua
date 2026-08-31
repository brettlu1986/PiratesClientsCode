-- ffa毒圈阶段step

local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local FFAParachutingStep = luaclass("FFAParachutingStep", BattleTargetActionStep)

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
-- local ParachutingNewIni = require("ParachutingNewIni")
local BattleTransporterHelper = require("BattleTransporterHelper")
-- local TransporterDataTable = require("TransporterDataTable")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
-- local BotAISystem = dynamic_require("BotAISystem")
-- local szTransporterTag = "Transporter"
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
-- local ProtoDR = require("DungeonRepProtoNames")
local SelectionPointHelper = require("SelectionPointHelper")
local AIHelper = require("AIHelper")
local BattleItemSystemServer = require("BattleItemSystemServer")
local InitItemDataTable = require("InitItemDataTable")
local InitItemIni = require("InitItemIni")

FFAParachutingStep.tbTransporters = nil
FFAParachutingStep.tbDelegates = nil

-- 等待阶段结束发消息给服务器
local function WaitingStepEnd()
    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    tbSetting:OnFFAWaitStageEnd()
    --清理楚等待时间倒计时,使用GM跳过等待阶段后会有问题，固此处清理一下
    tbSetting:ClearStepRemainTimer()
end

-- local function CreateTransport(self)
--     local tbTransport = ParachutingNewIni.tbTransport
--     local tbLaunch = ParachutingNewIni.tbLaunch
--     local tbParachuteOpen = ParachutingNewIni.tbParachuteOpen
--     local tbRelevantDistance = ParachutingNewIni.tbRelevantDistance

--     local tbGameMode = BattleGameModeSystem:GetGameMode()
--     local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
--     local nMapSize = math.max(math.ceil(tbMapSize.GamePlayWidth / 2), math.ceil(tbMapSize.GamePlayHeight / 2))

--     self.tbTransporters = {}

--     local tbTransports = BattleTransporterHelper:GetAll()
--     for _, v in pairs(tbTransports) do
--         local nTransporterId = v.TransporterId
--         local tbStartNode = v.StartNode
--         local tbPathNodes = {}
--         local tbTransporterData = TransporterDataTable:GetTemplate(nTransporterId)
--         if tbTransporterData ~= nil then
--             local tbTransporter = GameObjectSystem:CreateDummyInGameMode(tbTransporterData.nDummyId,
--             tbStartNode, nil, szTransporterTag..nTransporterId)
--             if(tbTransporter == nil or tbTransporter.pUEActor == nil) then
--                 error("Spawn new transporter failed, id: ", nTransporterId)
--             else
--                 for _, Node in ipairs(v.PathNodes) do
--                     tbTransporter.pUEActor:AddPathNode(Node.X, Node.Y)
--                     table.insert(tbPathNodes, {nX = Node.X, nY = Node.Y})
--                 end

--                 tbTransporter.pUEActor:SetTransporterInfo(tbTransport.nTransportTime,
--                     nMapSize / tbTransport.nTriggerTime,
--                     tbLaunch.nLaunchHeight,
--                     tbLaunch.nOpenParachuteHeight,
--                     tbLaunch.nLaunchTime,
--                     tbLaunch.nPreTopHeight,
--                     tbLaunch.nPreOpenParachuteHeight,
--                     tbParachuteOpen.nNormalFallSpeed,
--                     tbParachuteOpen.nMaxFallSpeed,
--                     tbParachuteOpen.nTranslationSpeed,
--                     tbParachuteOpen.nAcceleration,
--                     tbParachuteOpen.nRotationRate,
--                     tbParachuteOpen.nRemoveParachuteHeight,
--                     tbParachuteOpen.nPlayDropAniHeight,
--                     tbRelevantDistance.nInAirDistance,
--                     tbRelevantDistance.nNormalDistance)

--                 self.tbTransporters[nTransporterId] = tbTransporter:GetUEActorUniqueId()
--             end
--         else
--             error("Spawn new transporter failed, invalid transporterid: ", nTransporterId)
--         end
--     end
-- end

-- local function ForceChangeToHuman()
--     local tbObjects = GameObjectSystem:GetAllGameObjects()
--     for nId, Object in pairs(tbObjects) do
--         if Object.ObjectType == GameObjectTypeDef.PlayerSelf and Object:IsShip() then
--             local nHumanId = Object.tbPrepareInfo.nHumanId
--             local tbTransform = {}
--             tbTransform.X = Object.Location.X
--             tbTransform.Y = Object.Location.Y
--             tbTransform.Z = Object.Location.Z
--             BattleGameModeSystem:GetGameMode():ChangeToHuman(Object, nHumanId, tbTransform)
--         end
--     end
-- end

local function StartTransport(self)
    log("start move")
    local tbTransporter
    SelectionPointHelper:StartMove()
    for _, v in ipairs(self.tbTransporters) do
        tbTransporter = GameObjectSystem:FindByUniqueId(v.nUniqueId)
        if tbTransporter then
            tbTransporter.pUEActor:StartMove()
        else
            logerror("start move not find transporter ", v.nTransporterId)
        end
    end
end

function FFAParachutingStep:Init()
    FFAParachutingStep.super.Init(self)

    self.szName = "FFAParachutingStep"
end

function FFAParachutingStep:Parse(tbJsonData)
    if(not FFAParachutingStep.super.Parse(self, tbJsonData)) then
        return false
    end

    return true
end

local function OnReachDestination(self, nUniqueId)
    local tbTransporter = GameObjectSystem:FindByUniqueId(nUniqueId)
    self.SelfEventHelper:UnregisterCppDelegate(self.tbDelegates[nUniqueId])
    self.tbDelegates[nUniqueId] = nil
    GameObjectSystem:DestroyDummyInGameModeByInstanceId(tbTransporter:GetServerInstanceId())
    log("FFAParachutingStep OnReachDestination ")
    for i, v in ipairs(self.tbTransporters) do
        if v.nUniqueId == nUniqueId then
            -- self.tbTransporters[k] = nil
            table.remove(self.tbTransporters, i)
            log("FFAParachutingStep OnReachDestination transportid = ", v.nTransporterId)
            break
        end
    end
end

-- local function OnEnterPlayerSelectPoint(self, nState, tbPlayer)
--     log("OnEnterPlayerSelectPoint", nState, tbPlayer.nPlayerId)
--     if nState > ProtoDR.rFFAProcessState_EState.SELECTION_LOCK then
--         log("OnEnterPlayerSelectPoint", nState)
--         SelectionPointHelper:RandomSpawnPlayer(tbPlayer, self.tbTransporters)
--     end
-- end

local function ResetHumanWeaponState(tbPlayer)
    if tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf and tbPlayer:IsHuman() then
        local HumanWeaponComponent = tbPlayer.HumanWeaponComponent
        HumanWeaponComponent:SetCurrentWeapon(0, true)
    end
end

local function ResetPlayerInitItemsToFormal(tbPlayer)
    local tbPrepareInfo = tbPlayer.tbPrepareInfo
    tbPrepareInfo:SetInitItems(InitItemDataTable:GetItems(InitItemIni.tbFormalScene.nInitItemGroupId))
    BattleItemSystemServer:ResetBattleItemsFromPrepareInfo(tbPlayer:GetServerInstanceId())
end

local function ResetInitItemsToFormal()
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        ResetHumanWeaponState(Object)     --todo @WuJizhou 临时解决方案，主要解决上船时，手上有手雷，多次点击攻击引起报错
        if not AIHelper.IsAICustomPreparationItem(Object) then
            ResetPlayerInitItemsToFormal(Object)
        end
    end
end

local function OnPlayerLogin(self, tbPlayer)
    log("Player Login when parachute has begun:",tbPlayer.szName)
    --跳伞阶段已经开始的情况下收到了Login
    ResetPlayerInitItemsToFormal(tbPlayer)
end

function FFAParachutingStep:RegisterEvent()
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)
end

function FFAParachutingStep:Start()
    FFAParachutingStep.super.Start(self)

    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    self.tbTransporters = tbSetting.tbTransporters
    -- newsetting 使用下面这行代码
    self.tbTransporters = BattleTransporterHelper:GetTransporters()

    -- 等待阶段结束发消息给服务器
    WaitingStepEnd()
    -- Force Change To Human
    -- ForceChangeToHuman()
    -- CreateTransport(self)
    StartTransport(self)
    ResetInitItemsToFormal()

    -- EventManager:BindEventMethod(CommonEventDef.EV_FFA_ENTERPLAYER_SELECTPOINT, self, OnEnterPlayerSelectPoint)
    EventManager:OnFireEvent(CommonEventDef.EV_ENTER_TRANSPORT_STEP)
    -- TransportPlayerToPoint(self)

    self.tbDelegates = {}
    local EH = self.SelfEventHelper
    for _, v in ipairs(self.tbTransporters) do
        local tbTransporter = GameObjectSystem:FindByUniqueId(v.nUniqueId)
        self.tbDelegates[v.nUniqueId] = EH:RegisterCppDelegate(tbTransporter.pUEActor.OnReachDestinationEvent, self, OnReachDestination)
    end
end

function FFAParachutingStep:Uninit()
    if self.tbDelegates ~= nil then
        for k, v in pairs(self.tbDelegates) do
            self.SelfEventHelper:UnregisterCppDelegate(self.tbDelegates[k])
        end
        self.tbDelegates = nil
    end
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_FFA_ENTERPLAYER_SELECTPOINT, self, OnEnterPlayerSelectPoint)

    FFAParachutingStep.super.Uninit(self)
end

function FFAParachutingStep:ForceStop()
    FFAParachutingStep.super.ForceStop(self)
end

function FFAParachutingStep:OnCompleted()
    FFAParachutingStep.super.OnCompleted(self)
end

function FFAParachutingStep:RepStepInfo(bRepNow)
    FFAParachutingStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function FFAParachutingStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()
    return true
end

return FFAParachutingStep