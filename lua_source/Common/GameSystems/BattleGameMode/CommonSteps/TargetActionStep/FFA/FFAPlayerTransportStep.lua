-- ffa飞机阶段step

local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local FFAPlayerTransportStep = luaclass("FFAPlayerTransportStep", BattleTargetActionStep)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleOperationHelper = require("BattleOperationHelper")
local SelfEventHelper = require("SelfEventHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local Proto = require("DungeonRepProtoNames")
local ProtoDC = require("DungeonCommonProtoNames")
local CommonEventDef = require("CommonEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local GameObjectTypeDef = require("GameObjectTypeDef")
-- local ParachutingIni = require("ParachutingIni")
local EventManager = require("EventManager")
-- config params
FFAPlayerTransportStep.nTransporterResId = nil -- 因为飞机除了bp什么特性都没有，所以这里走dummy
FFAPlayerTransportStep.tbPointGroup = nil     -- 需要随机的所有点
FFAPlayerTransportStep.tbJumpArea = nil       -- 跳伞区域，Box2d
FFAPlayerTransportStep.nVelocity = nil        -- 飞机速度，这个如果换成时间也可以
FFAPlayerTransportStep.nFlyHeight = nil       -- 飞行高度
FFAPlayerTransportStep.nMinJumpHeight = nil
FFAPlayerTransportStep.nMaxJumpHeight = nil
FFAPlayerTransportStep.nSeaLevelHeight= nil   -- 翻跟头的高度
FFAPlayerTransportStep.strSeaLevelMeshName = nil
-- variables
FFAPlayerTransportStep.nTransporterInstanceId = nil
FFAPlayerTransportStep.EventHelper = nil
FFAPlayerTransportStep.tbSetting = nil

-- replicated properties
FFAPlayerTransportStep.rFFATransportState = nil
FFAPlayerTransportStep.rFFATransportPlayerCount = nil
FFAPlayerTransportStep.nPlayerCount = 0        -- 未跳伞人数
FFAPlayerTransportStep.tbJumpedList = nil      -- 已经跳伞玩家


function FFAPlayerTransportStep:Init()
    FFAPlayerTransportStep.super.Init(self)

    self.szName = "FFAPlayerTransportStep"
    self.SelfEventHelper = SelfEventHelper()

    self.tbJumpedList = {}
    -- 有这个step才定义TransportInfo    
    self:DefineRProperty(Proto.rFFATransportState)
    self:DefineRProperty(Proto.rFFATransportPlayerCount)
end

function FFAPlayerTransportStep:Uninit()
    FFAPlayerTransportStep.super.Uninit(self)
    self.tbJumpedList = nil
end

function FFAPlayerTransportStep:Parse(_tbJsonData)
    if(not FFAPlayerTransportStep.super.Parse(self, _tbJsonData)) then
        return false
    end

    local tbJsonGameMode = BattleGameModeSystem:GetGameMode()
    local tbJsonDatas = tbJsonGameMode.tbJsonTableFile.tbContainer.FFAPlayerTransport
    if(tbJsonDatas == nil or #tbJsonDatas == 0) then
        BattleOperationHelper:PrintError(self, "Transport data has not exported.")
        return false
    end
    
    local tbJsonData = tbJsonDatas[1]
    self.nTransporterId = tbJsonData.TransporterId
    self.tbPointGroup = tbJsonData.PointGroup
    self.tbJumpArea = tbJsonData.JumpArea
    self.nVelocity = tbJsonData.Velocity
    self.nFlyHeight = tbJsonData.FlyHeight
    self.nMinJumpHeight = tbJsonData.MinJumpHeight
    self.nMaxJumpHeight = tbJsonData.MaxJumpHeight
    self.nSeaLevelHeight= tbJsonData.SeaLevelHeight
    self.strSeaLevelMeshName = tbJsonData.SeaLevelMeshName

    self.rFFATransportState.State = Proto.rFFATransportState_EState.NOTSPAWNED
    return true
end

local function OnEnterJumpArea(self)
    local rFFATransportState = self.rFFATransportState
    rFFATransportState.State = Proto.rFFATransportState_EState.JUMPING
    rFFATransportState.Rep()
    EventManager:OnFireEvent(CommonEventDef.EV_ENTER_JUMP_AREA)
end

local function OnLeaveJumpArea(self)
    local rFFATransportState = self.rFFATransportState
    rFFATransportState.State = Proto.rFFATransportState_EState.FINISHED
    rFFATransportState.Rep()

    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    local tbTransporter = GameObjectSystem:FindByInstanceId(tbSetting.nTransporterInstanceId)
    assert(tbTransporter)
    tbTransporter:GetModelActor():DischargeAllPlayers()
end

local function OnReachDestination(self)
    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    GameObjectSystem:DestroyDummyInGameModeByInstanceId(tbSetting.nTransporterInstanceId)
    self:Complete()
end

local function OnPlayerRequestJump(self, nUniqueId, bRequest)
    if(not bRequest) then
        return
    end

    local tbPlayer = GameObjectSystem:FindByUniqueId(nUniqueId)
    assert(tbPlayer)

    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    local tbTransporter = GameObjectSystem:FindByInstanceId(tbSetting.nTransporterInstanceId)
    if(not tbTransporter) then
        return
    end

    if(tbTransporter.pUEActor:DischargePlayer(tbPlayer.pUEActor, tbPlayer.pUEController)) then
        NetworkManager:GetRPCNetworkProxy():SendToClient(
            tbPlayer:GetUEControllerUniqueId(),
            ProtoDC.d2c_JumpFromTransporter, {})
        
        local rFFATransportPlayerCount = self.rFFATransportPlayerCount
        self.nPlayerCount = self.nPlayerCount - 1
        rFFATransportPlayerCount.nCount = self.nPlayerCount
        rFFATransportPlayerCount.Rep()
        local nServerInstanceId = tbPlayer:GetServerInstanceId()
        self.tbJumpedList[nServerInstanceId] = 1
    end
end

local function OnPawnPreDestroy(self, tbGameObject)
    -- 飞机销毁
    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    local nTargetId = tbSetting.nTransporterInstanceId
    if(nTargetId ~= nil and nTargetId == tbGameObject:GetServerInstanceId()) then
        self.SelfEventHelper:UnregisterAll()
        tbSetting.nTransporterInstanceId = nil
    end
    -- 玩家退出、死亡
    if tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        local nServerInstanceId = tbGameObject:GetServerInstanceId()
        if not tbGameObject:IsDead() and self.tbJumpedList[nServerInstanceId] == nil then
            local rFFATransportPlayerCount = self.rFFATransportPlayerCount
            self.nPlayerCount = self.nPlayerCount - 1
            rFFATransportPlayerCount.nCount = self.nPlayerCount
            rFFATransportPlayerCount.Rep()
        end
    end
end

local function ForceChangeToHuman()
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if Object:IsShip() then
            local nHumanId = Object.tbPrepareInfo.nHumanId
            local tbTransform = {}
            tbTransform.X = Object.Location.X
            tbTransform.Y = Object.Location.Y
            tbTransform.Z = Object.Location.Z
            BattleGameModeSystem:GetGameMode():ChangeToHuman(Object, nHumanId, tbTransform)
        end
    end
end

-- 等待阶段结束发消息给服务器
local function WaitingStepEnd()
    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    tbSetting:OnFFAWaitStageEnd()
    --清理楚等待时间倒计时,使用GM跳过等待阶段后会有问题，固此处清理一下
    tbSetting:ClearStepRemainTimer()
end

function FFAPlayerTransportStep:Start()
    FFAPlayerTransportStep.super.Start(self)
    
    -- 等待阶段结束发消息给服务器
    WaitingStepEnd()
    -- Force Change To Human
    ForceChangeToHuman()

    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbSetting = tbGameMode.Setting
    local tbEnd = tbSetting.tbTransportEnd
    -- bind jump area events
    local nTransporterInstanceId = tbSetting.nTransporterInstanceId
    local tbTransporter = GameObjectSystem:FindByInstanceId(nTransporterInstanceId)
    local pUEActor = tbTransporter:GetModelActor()
    if(pUEActor.OnEnterJumpAreaEvent == nil or pUEActor.OnLeaveJumpAreaEvent == nil) then
        BattleOperationHelper:PrintError(self, "Transporter bp is invalid.")
        return
    end

    local EH = self.SelfEventHelper
    EH:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnPawnPreDestroy)
    EH:RegisterEvent(CommonEventDef.EV_FFA_JUMP_FROM_TRANSPORTER, self, OnPlayerRequestJump)
    EH:RegisterCppDelegate(pUEActor.OnEnterJumpAreaEvent, self, OnEnterJumpArea)
    EH:RegisterCppDelegate(pUEActor.OnLeaveJumpAreaEvent, self, OnLeaveJumpArea)
    EH:RegisterCppDelegate(pUEActor.OnReachDestinationEvent, self, OnReachDestination)

    -- set desination and start move
    local tbJumpArea = self.tbJumpArea
    local pAreaMin = Vector2D{X=tbJumpArea.X0, Y=tbJumpArea.Y0}
    local pAreaMax = Vector2D{X=tbJumpArea.X1, Y=tbJumpArea.Y1}
    local pEndLocation = Vector{X=tbEnd.X, Y=tbEnd.Y, Z=tbEnd.Z}

    pUEActor:CarryAllPlayers()

    -- local tbNoOpen = ParachutingIni.tbParachuteNoOpen
    -- local tbOpen = ParachutingIni.tbParachuteOpen
    -- local tbRealWorld = ParachutingIni.tbRealWorld
    -- local tbRelevantDistance = ParachutingIni.tbRelevantDistance
    -- local tbRollStep = ParachutingIni.tbRollStep
    -- pUEActor:SetParachutingData(
    --     self.nSeaLevelHeight,
    --     tbNoOpen.nNormalFallSpeed,
    --     tbNoOpen.nMinFallSpeed,
    --     tbNoOpen.nMaxFallSpeed,
    --     tbNoOpen.nTranslationSpeed,
    --     tbNoOpen.nAcceleration,
    --     tbNoOpen.nSpeedChangeAcceleration,
    --     tbNoOpen.nLeaveOffset,
    --     tbOpen.nNormalFallSpeed,
    --     tbOpen.nMaxFallSpeed,
    --     tbOpen.nTranslationSpeed,
    --     tbOpen.nAcceleration,
    --     tbOpen.nSpeedChangeAcceleration,
    --     tbRealWorld.nFallSpeed,
    --     tbRealWorld.nAcceleration,
    --     self.strSeaLevelMeshName,
    --     tbRelevantDistance.nUnderSeaDistance,
    --     tbRelevantDistance.nOnSeaDistance,
    --     tbRelevantDistance.nUnderToOnDistance,
    --     tbRollStep.nNormalFallSpeed,
    --     tbRollStep.nAcceleration,
    --     tbRollStep.nSeaLevelOffset,
    --     tbRollStep.nRollTimer
    -- )

    pUEActor:StartMove(self.nVelocity, pEndLocation, pAreaMin, pAreaMax)

    local rFFATransportState = self.rFFATransportState
    rFFATransportState.State = Proto.rFFATransportState_EState.MOVING
    rFFATransportState.Rep()

    self.nPlayerCount =  pUEActor:GetCarrayPlayerCount()
    local rFFATransportPlayerCount = self.rFFATransportPlayerCount
    rFFATransportPlayerCount.nCount = self.nPlayerCount
    rFFATransportPlayerCount.Rep()

    EventManager:OnFireEvent(CommonEventDef.EV_ENTER_TRANSPORT_STEP)
end

function FFAPlayerTransportStep:UnregisterEvent()
    self.SelfEventHelper:UnregisterAll()

    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    if tbSetting.nTransporterInstanceId then
        GameObjectSystem:DestroyDummyInGameModeByInstanceId(tbSetting.nTransporterInstanceId)
        tbSetting.nTransporterInstanceId = nil
    end

    FFAPlayerTransportStep.super.UnregisterEvent(self)
end

function FFAPlayerTransportStep:RepStepInfo(bRepNow)
    self.rFFATransportState.Rep(bRepNow)
    self.rFFATransportPlayerCount.Rep(bRepNow)

    FFAPlayerTransportStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function FFAPlayerTransportStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()
    return true
end

return FFAPlayerTransportStep