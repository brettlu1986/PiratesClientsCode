-- ffa 空投阶段step

local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local FFAAirdropStep = luaclass("FFAAirdropStep", BattleTargetActionStep)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local Timer = require("Timer")
-- local BaseUtil = require("BaseUtil")
local AirdropDataTable = require("AirdropDataTable")
local StringUtil = require("StringUtil")
local BattleItemSystemServer  = require("BattleItemSystemServer")
local BattleItemDropSystem = require("BattleItemDropSystem")
local FFAItemIni = require("FFAItemIni")
local CommonEventDef = require("CommonEventDef")
local SceneItemActorDef = require("SceneItemActorDef")
local TriggerIni = require("TriggerIni")

local szAirDropTransporter = "AirDropTransporter"
-- config params
FFAAirdropStep.AirDropWaitTimer = nil       -- 空投等待时间
FFAAirdropStep.nAirDropDuration = nil       -- 空投持续时间
FFAAirdropStep.tbAirdropArea = nil          -- 空投航线区间
FFAAirdropStep.tbConfig = nil               -- 空投配置
FFAAirdropStep.tbAirDropInterval = nil      -- 空投间隔时间配置
FFAAirdropStep.nCurrentIndex = nil          -- 空投当前Index
FFAAirdropStep.tbTransporterList = nil

function FFAAirdropStep:Init()
    FFAAirdropStep.super.Init(self)

    self.szName = "FFAAirdropStep"

    self.tbAirDropInterval = {}
    self.nAirDropDuration = 0
    self.tbTransporterList = {}
end

-- 读取配置表初始化每次空投间隔时间范围
local function InitConfig(self)
    local tbIntervalTime = StringUtil.Split(self.tbConfig.szAirdropInterval, "|")
    local nCount = self.tbConfig.nCount
    local tbTime = nil
    for i = 1, nCount do
        if tbIntervalTime[i] then
            tbTime = {}
            local tbInterval = StringUtil.Split(tbIntervalTime[i], ",")
            tbTime.MinTime = tbInterval[1]
            tbTime.MaxTime = tbInterval[2]
        end
        self.tbAirDropInterval[i] = tbTime
    end
end

function FFAAirdropStep:Parse(tbJsonData)
    if(not FFAAirdropStep.super.Parse(self, tbJsonData)) then
        return false
    end

    self.tbConfig = AirdropDataTable:GetTemplate(BattleGameModeSystem:GetCurrentDungeonId())
    assert(self.tbConfig ~= nil)
    local nRadius = self.tbConfig.nAirdropArea
    self.tbAirdropArea = {
        X0 = -nRadius,
        X1 = nRadius,
        Y0 = -nRadius,
        Y1 = nRadius,
    }

    InitConfig(self)

    return true
end

local function ClearAirDropWaitTimer(self)
    if self.AirDropWaitTimer then
        self.AirDropWaitTimer:Clear()
        self.AirDropWaitTimer = nil
    end
end

-- 随机两点顺序
local function RadomTwoPoint(tbPointA, tbPointB)
    local nRandomNum = math.random(0, 1)
    if nRandomNum == 0 then
        return tbPointA, tbPointB
    else
        return tbPointB, tbPointA
    end
end

-- 检查是否在地图范围内
local function CheckPointInMapSize(tbTransform)
    if tbTransform == nil then
        return false
    end
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbMapSize = tbGameMode.tbJsonTableFile.tbContainer.MapSize[1]
    local nX = math.ceil(tbMapSize.GamePlayWidth / 2)
    local nY = math.ceil(tbMapSize.GamePlayHeight / 2)
    local nMinX = -nX
    local nMaxX = nX
    local nMinY = -nY
    local nMaxY = nY
    if tbTransform.X < nMinX or tbTransform.X > nMaxX
        or tbTransform.Y < nMinY or tbTransform.Y > nMaxY then
        return false
    end
    return true
end

-- 在内圈中随机出投掷点
local function RandomThrowPoint(self)
    local bCoreAreaOpen = false
    local nCoreAreaRadius = 0

    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    if tbSetting then
        if tbSetting.IsCoreAreaOpen then
            bCoreAreaOpen = tbSetting:IsCoreAreaOpen()
        end

        if tbSetting.GetCoreAreaRadius then
            nCoreAreaRadius = tbSetting:GetCoreAreaRadius()
        end
    end

    local tbGameState = BattleGameModeSystem:GetGameState()
    local rFFAPoisonCircleInfo = tbGameState.rFFAPoisonCircleInfo:Get()

    local nNextX = rFFAPoisonCircleInfo.nNextX ~= nil and rFFAPoisonCircleInfo.nNextX or rFFAPoisonCircleInfo.nCurrentX
    local nNextY = rFFAPoisonCircleInfo.nNextY ~= nil and rFFAPoisonCircleInfo.nNextY or rFFAPoisonCircleInfo.nCurrentY
    local nNextRadius = rFFAPoisonCircleInfo.nNextRadius ~= nil and rFFAPoisonCircleInfo.nNextRadius or rFFAPoisonCircleInfo.nCurrentRadius
    if nNextX and nNextY and nNextRadius then
        local nStartLenth = 0

        --排除掉中心区域
        local bExceptCoreArea = (not bCoreAreaOpen and nNextRadius > nCoreAreaRadius)
        if  bExceptCoreArea then
            nStartLenth = nCoreAreaRadius
        end

        local nRandomR = math.random(nStartLenth, nNextRadius)
        local nRandomAngle = math.random(0, 360)
        local nDiffX = math.ceil(nRandomR * math.cos(math.rad(nRandomAngle)))
        local nDiffY = math.ceil(nRandomR * math.sin(math.rad(nRandomAngle)))

        local tbNewTransform = {}
        tbNewTransform.X = nNextX + nDiffX
        tbNewTransform.Y = nNextY + nDiffY

        local nLenth = KismetMathLibrary.VSize(Vector{X = tbNewTransform.X,Y = tbNewTransform.Y,Z = 0})
        if nLenth < nCoreAreaRadius and bExceptCoreArea then
            tbNewTransform.X = tbNewTransform.X + nNextX
            tbNewTransform.Y = tbNewTransform.Y + nNextY
        end

        return tbNewTransform, nNextX, nNextY
    end
    logerror("RandomThrowPoint get tbNewTransform are invalid.")
    return nil, nNextX, nNextY
end

-- 确定掉落点
local function SelectThrowPoint(self)
    local bUsePointInCircle = true
    local tbThrowPoint = nil
    local nPointInCircleX, nPointInCircleY
    -- 最多随机三次，如果还是没有在地图范围内的点，则用毒圈中心点
    for i = 1, 3 do
        tbThrowPoint, nPointInCircleX, nPointInCircleY = RandomThrowPoint(self)
        if CheckPointInMapSize(tbThrowPoint) then
            bUsePointInCircle = false
            break
        end
    end
    if bUsePointInCircle then
        tbThrowPoint.X = nPointInCircleX
        tbThrowPoint.Y = nPointInCircleY
    end
    return tbThrowPoint
end

-- 在BP_FFAAirdropTransport_Exporter边上随机出航线一点
local function RandomRoutePoint(self)
    local tbPoint = {}
    local tbAirdropArea = self.tbAirdropArea
    local nRandomXY = math.random(0, 1)
    local nRandomSide = math.random(0, 1)

    if nRandomXY == 0 then
        local nRandomX = math.random(tbAirdropArea.X0 + 1, tbAirdropArea.X1 - 1)
        tbPoint.X = nRandomX
        if nRandomSide == 0 then
            tbPoint.Y = tbAirdropArea.Y0
        else
            tbPoint.Y = tbAirdropArea.Y1
        end
    else
        local nRandomY = math.random(tbAirdropArea.Y0 + 1, tbAirdropArea.Y1 - 1)
        tbPoint.Y = nRandomY
        if nRandomSide == 0 then
            tbPoint.X = tbAirdropArea.X0
        else
            tbPoint.X = tbAirdropArea.X1
        end
    end
    return tbPoint
end

-- 确定空投飞鸟航线,方向
local function SelectAirliner(self)
    local tbRandomPoint = RandomRoutePoint(self)
    local tbThrowPoint = SelectThrowPoint(self)
    local nFlyHeight = self.tbConfig.nFlyHeight
    tbRandomPoint.Z = nFlyHeight
    tbThrowPoint.Z = nFlyHeight

    local pRandomLocation = Vector{X=tbRandomPoint.X, Y=tbRandomPoint.Y, Z=tbRandomPoint.Z}
    local pThrowLocation = Vector{X=tbThrowPoint.X, Y=tbThrowPoint.Y, Z=tbThrowPoint.Z}

    local tbAirdropArea = self.tbAirdropArea
    local pAreaVectorMin = Vector{X=tbAirdropArea.X0, Y=tbAirdropArea.Y0, Z=0}
    local pAreaVectorMax = Vector{X=tbAirdropArea.X1, Y=tbAirdropArea.Y1, Z=0}

    -- 取延长线上一点
    local pForwardVector = KismetMathLibrary.Subtract_VectorVector(pThrowLocation, pRandomLocation)
    local fnDist = ExtendBlueprintFunctions.GetVectorToVectorDistance
    local nMaxOffset = fnDist(pAreaVectorMin, pAreaVectorMax)
    local pNormalForwardVector = KismetMathLibrary.Normal(pForwardVector, GDefaultTolerance)
    local pLocationDelta = KismetMathLibrary.Multiply_VectorFloat(pNormalForwardVector, nMaxOffset)
    local pOffsetLocation = KismetMathLibrary.Add_VectorVector(pThrowLocation, pLocationDelta)

    -- 取航线与volume相交的2点
    local pAreaMin = Vector2D{X=tbAirdropArea.X0, Y=tbAirdropArea.Y0}
    local pAreaMax = Vector2D{X=tbAirdropArea.X1, Y=tbAirdropArea.Y1}
    local nRet, pP1, pP2 = ExtendBlueprintFunctions.SegmentIntersectWithBox2D(
        pRandomLocation, pOffsetLocation, Box2D{Min=pAreaMin, Max=pAreaMax})
    log("ThrowPoint", tbThrowPoint.X, tbThrowPoint.Y)
    log("RandomPoint", tbRandomPoint.X, tbRandomPoint.Y)
    log("pOffsetLocation", pOffsetLocation.X, pOffsetLocation.Y)
    log("SegmentIntersectWithBox2D ", nRet, pP1.X, pP1.Y, pP2.X, pP2.Y)
    assert(nRet == 2)

    pP1.Z = nFlyHeight
    pP2.Z = nFlyHeight

    local tbStartPoint = nil
    local tbEndPoint = nil
    if self.tbConfig.nRouteDirection == 1 then
        -- 离空头点最近方向为航线起点
        if(fnDist(pThrowLocation, pP1) > fnDist(pThrowLocation, pP2)) then
            tbStartPoint = pP2
            tbEndPoint = pP1
        else
            tbStartPoint = pP1
            tbEndPoint = pP2
        end
    else
        tbStartPoint, tbEndPoint = RadomTwoPoint(pP1, pP2)
        -- 随机方向为起点
    end
    return tbStartPoint, tbEndPoint, tbThrowPoint
end

local AirDropWait

local function GetThrowTime(tbStartPoint, tbThrowPoint, nVelocity)
    local fnDist = ExtendBlueprintFunctions.GetVectorToVectorDistance
    local pStartPoint = Vector{X=tbStartPoint.X, Y=tbStartPoint.Y, Z=0}
    local pThrowPoint = Vector{X=tbThrowPoint.X, Y=tbThrowPoint.Y, Z=0}
    local nDistance = fnDist(pStartPoint, pThrowPoint)
    if nVelocity ~= 0 then
        return nDistance / nVelocity
    end
    return nil
end

local function OnTransporterDestroyed(self, tbGameObject)
    for _k, tbTransporter in pairs(self.tbTransporterList) do
        if tbTransporter.nInstanceId ~= nil and tbTransporter.nInstanceId == tbGameObject:GetServerInstanceId() then
            self.SelfEventHelper:UnregisterCppDelegate(tbTransporter.tbReachDelegate)
            tbTransporter.nInstanceId = nil
            tbTransporter.tbReachDelegate = nil
        end
    end
end

local function OnReachDestination(self, nInstanceId)
    for _k, tbTransporter in pairs(self.tbTransporterList) do
        if tbTransporter.nInstanceId == nInstanceId then
            GameObjectSystem:DestroyDummyInGameModeByInstanceId(nInstanceId)
        end
    end
end

-- 创建空投飞鸟
local function AirDropTransporterCreate(self)
    local tbStartPoint, tbEndPoint, tbThrowPoint = SelectAirliner(self)
    local tbConfig = self.tbConfig
    -- 创建鸟
    local tbAirDropTransporter = GameObjectSystem:CreateDummyInGameMode(tbConfig.nTransporterId,
    tbStartPoint, nil, szAirDropTransporter)
    if(tbAirDropTransporter == nil or tbAirDropTransporter.pUEActor == nil) then
        logerror("Spawn AirDropTransporter failed, id: ", tbConfig.nTransporterId)
        return
    end
    local nInstanceId = tbAirDropTransporter:GetServerInstanceId()
    local pUEActor = tbAirDropTransporter:GetModelActor()
    local tbReachDelegate = self.SelfEventHelper:RegisterCppDelegate(pUEActor.OnReachDestinationEvent, self, function() OnReachDestination(self, nInstanceId) end)

    local tbTransporter = {}
    tbTransporter.nInstanceId = nInstanceId
    tbTransporter.tbReachDelegate = tbReachDelegate
    table.insert(self.tbTransporterList, tbTransporter)

    -- 创建空投箱子
    local tbSceneItemData = {}
    local tbItemInfos = {}
    local tbItemData, nBoxTemplateId = BattleItemDropSystem:DropItems(tbConfig.nAirdropId)
    for _, tbItemSet in pairs(tbItemData) do
        for _, ItemInfo in pairs(tbItemSet) do
            table.insert(tbItemInfos, ItemInfo)
        end
    end
    tbSceneItemData.tbItemInfos = tbItemInfos
    tbSceneItemData.tbTransform = tbStartPoint
    local BoxActor = BattleItemSystemServer:AddItemPackageToScene(tbSceneItemData, SceneItemActorDef.AIR_DROP_BOX, nBoxTemplateId)

    local nThrowTime = GetThrowTime(tbStartPoint, tbThrowPoint, tbConfig.nFlyVelocity)
    if nThrowTime == nil then
        logerror("Calculate ThrowTime Error, nFlyVelocity: ", tbConfig.nFlyVelocity)
        return
    end

    local tbSceneItem = FFAItemIni.tbSceneItem
    pUEActor:SetDropItemInfo(TriggerIni.tbPickTrigger.nLandTriggerRadius,
        TriggerIni.tbPickTrigger.nOceanTriggerRadius,
        tbSceneItem.nAirDropNormalMeshScale,
        tbSceneItem.nAirDropLandMeshScale,
        tbSceneItem.nAirDropOceanMeshScale,
        tbConfig.nDropVelocity,
        tbConfig.nDropAcceleration)
    pUEActor:StartMove(tbConfig.nFlyVelocity, tbEndPoint, nThrowTime, BoxActor.pUEActor)

    -- 进入下一轮空投
    self.nCurrentIndex = self.nCurrentIndex + 1
    AirDropWait(self)
end

-- 随机等待空投时间
local function RandomAirDropWaitTime(self)
    local tbAirDropInterval = self.tbAirDropInterval
    local nCurrentIndex = self.nCurrentIndex
    local nWaitTime = nil
    if tbAirDropInterval[nCurrentIndex] then
        local tbTime = tbAirDropInterval[nCurrentIndex]
        if tbTime.MinTime and tbTime.MaxTime then
            if tonumber(tbTime.MinTime) < tonumber(tbTime.MaxTime) then
                nWaitTime = math.random(tbTime.MinTime, tbTime.MaxTime)
            end
        end
    end
    return nWaitTime
end

-- 等待空投timer
AirDropWait = function(self)
    ClearAirDropWaitTimer(self)
    if self.nCurrentIndex <= self.tbConfig.nCount then
        local nWaitTime = RandomAirDropWaitTime(self)
        if nWaitTime then
            self.nAirDropDuration = self.nAirDropDuration + nWaitTime
            if self.nAirDropDuration < self.tbConfig.nEndTime then
                self.AirDropWaitTimer = Timer.NewTimerMethod(self, AirDropTransporterCreate, nWaitTime, false)
            end
        end
    end
end

-- 开始空投逻辑
local function AirDropStart(self)
    self.nCurrentIndex = 1
    AirDropWait(self)

end

function FFAAirdropStep:RegisterEvent()
    FFAAirdropStep.super.RegisterEvent(self)

    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnTransporterDestroyed)
end

function FFAAirdropStep:UnregisterEvent()
    FFAAirdropStep.super.UnregisterEvent(self)
end

function FFAAirdropStep:Start()
    FFAAirdropStep.super.Start(self)
    AirDropStart(self)
end

function FFAAirdropStep:Uninit()
    FFAAirdropStep.super.Uninit(self)
    ClearAirDropWaitTimer(self)

    for _k, tbTransporter in pairs(self.tbTransporterList) do
        if tbTransporter.nInstanceId then
            GameObjectSystem:DestroyDummyInGameModeByInstanceId(tbTransporter.nInstanceId)
        end
        tbTransporter.nInstanceId = nil
        tbTransporter.tbReachDelegate = nil
    end
    self.tbTransporterList = nil
end

function FFAAirdropStep:ForceStop()
    FFAAirdropStep.super.ForceStop(self)
end

function FFAAirdropStep:OnCompleted()
    FFAAirdropStep.super.OnCompleted(self)
end

-- function FFAAirdropStep:RepStepInfo(bRepNow)
--     FFAAirdropStep.super.RepStepInfo(self, bRepNow)
-- end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function FFAAirdropStep:SnapshotToReplicatedProperty()
    -- self:RepStepInfo()
    return true
end

return FFAAirdropStep