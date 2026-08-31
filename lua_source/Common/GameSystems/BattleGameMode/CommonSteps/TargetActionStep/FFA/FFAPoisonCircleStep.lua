-- ffa毒圈阶段step

local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local FFAPoisonCircleStep = luaclass("FFAPoisonCircleStep", BattleTargetActionStep)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local Timer = require("Timer")
-- local BaseUtil = require("BaseUtil")
-- local BattleTriggerHelper = require("BattleTriggerHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
-- local BattleTransformPointHelper = require("BattleTransformPointHelper")
local PoisonCircleDataTable = require("PoisonCircleDataTable")
local BattleBlackboard = require("BattleBlackboard")
local AbilityAction_ApplyPoisonCircleDamage = require("AbilityAction_ApplyPoisonCircleDamage")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local PoisonCircleSettingDataTable = require("PoisonCircleSettingDataTable")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local LuaVector = require("LuaVector")
local DelayTimer = require("DelayTimer")

FFAPoisonCircleStep.tbPoisonCircleData = nil            -- 生成满足条件的毒圈数据
FFAPoisonCircleStep.PoisonCircleWaitTimer = nil         -- 毒圈等待计时器
FFAPoisonCircleStep.nTriggerInstanceId = nil
FFAPoisonCircleStep.nTriggerAreaId = nil
FFAPoisonCircleStep.nCurrentIndex = nil                 -- 当前毒圈Index
FFAPoisonCircleStep.PoisonCircleDamageTimer = nil       -- buff伤害timer
FFAPoisonCircleStep.tbChangingDisplay = nil             -- 为解决在毒圈内人船切换，会先进入毒圈 再离开毒圈的问题
FFAPoisonCircleStep.CheckBuffTimer = nil
FFAPoisonCircleStep.TempVector1 = nil
FFAPoisonCircleStep.TempVector2 = nil
FFAPoisonCircleStep.tbAbnormalObj = nil
FFAPoisonCircleStep.tbDelayHandle = nil

local TRIGGER_ID = 1
local POISON_CIRCLE_DAMAGE_UPDATE_INTERVAL = 1          -- 毒圈伤害刷新间隔
local CHECK_POISON_CIRCLE_DELAY = 120

-- local POISONCIRCLE_NONE = 0
local POISONCIRCLE_WAIT = 1
local POISONCIRCLE_SHRINK = 2
local POISONCIRCLE_FINISH = 3

local POISONCIRCLE_BUFF_TIMER = 5

local POISON_CIRCLE_CENTER = AbilityAction_ApplyPoisonCircleDamage.POISON_CIRCLE_CENTER
local POISON_CIRCLE_RADIUS = AbilityAction_ApplyPoisonCircleDamage.POISON_CIRCLE_RADIUS


local function SetPoisonCircleBlackboard(self)
    if self.nTriggerInstanceId then
        local tbGameTrigger = GameObjectSystem:FindByInstanceId(self.nTriggerInstanceId)
        local nRadius = tbGameTrigger.pUEActor.CollisionRadius
        local pLocation = tbGameTrigger:GetLocation()
        local tbCenter = {}
        tbCenter.X = pLocation.X
        tbCenter.Y = pLocation.Y
        tbCenter.Z = pLocation.Z

        BattleBlackboard:SetNumber(POISON_CIRCLE_RADIUS, nRadius)
        BattleBlackboard:SetTable(POISON_CIRCLE_CENTER, tbCenter)
    end
end

local function GetPoisonCircleByIndex(self)
    if self.nCurrentIndex and self.nCurrentIndex > 0 then
        local tbCurrentPoisonCircle = self.tbPoisonCircleData[self.nCurrentIndex]
        if tbCurrentPoisonCircle then
            return tbCurrentPoisonCircle
        end
        logwarning("GetPoisonCircleByIndex faild, nCurrentIndex: ", self.nCurrentIndex)
    end

    return nil
end

local function GetCurrentBuffId(self)
    local tbPoisonCircle = GetPoisonCircleByIndex(self)
    if tbPoisonCircle then
        return tbPoisonCircle.BuffId
    end
    return nil
end

local function OnEnterTrigger(self, GameObject, nAreaId)
    if nAreaId ~= self.nTriggerAreaId then
        return
    end
    if GameObject.ObjectType == GameObjectTypeDef.PlayerSelf or GameObject.ObjectType == GameObjectTypeDef.Horse then
        log("OnLeavePoisonCircle ", GameObject.nServerInstanceId)
        if GameObject.BuffComponentServer then
            local nBuffId = GetCurrentBuffId(self)
            if nBuffId then
                if GameObject.BuffComponentServer:IsExistBuffById(nBuffId) then
                    SetPoisonCircleBlackboard(self)
                    GameObject.BuffComponentServer:RemoveBuffById(nBuffId)
                    EventManager:OnFireEvent(CommonEventDef.EV_FFA_LEAVE_POISONCIRCLE, GameObject)
                else
                    log("OnLeavePoisonCircle and no buf ", GameObject.nServerInstanceId, self.nCurrentIndex)
                end
            else
                logwarning("OnLeavePoisonCircle but no buf ", GameObject.nServerInstanceId, self.nCurrentIndex)
            end
        end
    end
end

local function OnLeaveTrigger(self, GameObject, nAreaId, bNotCareChangingDisplay)
    if nAreaId ~= self.nTriggerAreaId then
        return
    end
    local nInstanceId = GameObject.nServerInstanceId
    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    if tbSetting and tbSetting:GameOver() then
        log("OnEnterPoisonCircle but game over ", nInstanceId)
        return
    end

    if self.tbChangingDisplay[GameObject.nServerInstanceId] and bNotCareChangingDisplay == nil then
        log("EnterPoisonCircle and is changing display, do't care ", nInstanceId)
        return
    end
    if GameObject.ObjectType == GameObjectTypeDef.PlayerSelf or GameObject.ObjectType == GameObjectTypeDef.Horse then
        log("OnEnterPoisonCircle ", nInstanceId)
        if GameObject.BuffComponentServer then
            local nBuffId = GetCurrentBuffId(self)
            if nBuffId then
                SetPoisonCircleBlackboard(self)
                GameObject.BuffComponentServer:AddBuffById(nBuffId)
                EventManager:OnFireEvent(CommonEventDef.EV_FFA_ENTER_POISONCIRCLE, GameObject)
            else
                logwarning("OnEnterPoisonCircle but no buf ", nInstanceId, self.nCurrentIndex)
            end
        end
    end
end

local function CheckObjectLeavePoisonCircle(self, tbObject, bNoLeave)
    local bResult = false
    if self.nTriggerInstanceId then
        -- 因为如果是ship，需要判断box是否在area内，不能用点距离判断
        local pTriggerManager = CommonShell.GetCommon(GWorld):GetAreaTriggerManager()
        if (not pTriggerManager:IsActorInArea(tbObject.pUEActor, self.nTriggerAreaId)) then
            log("CheckObjectLeavePoisonCircle leave ", tbObject.nServerInstanceId)
            if not bNoLeave then 
                OnLeaveTrigger(self, tbObject, self.nTriggerAreaId, true)
            end
            bResult = true
        end
        -- local tbGameTrigger = GameObjectSystem:FindByInstanceId(self.nTriggerInstanceId)
        -- local nRadius = tbGameTrigger.pUEActor.CollisionRadius
        -- local nX, nY = tbGameTrigger:GetLocationXYZ()
        -- self.TempVector1.X = nX
        -- self.TempVector1.Y = nY
        -- local fnDist = ExtendBlueprintFunctions.GetVectorToVectorDistanceSquared
        -- nX, nY = tbObject:GetLocationXYZ()
        -- self.TempVector2.X = nX
        -- self.TempVector2.Y = nY

        -- if fnDist(self.TempVector1, self.TempVector2) > nRadius * nRadius then
        --     log("CheckObjectLeavePoisonCircle leave", tbObject.nServerInstanceId, self.TempVector1.X, self.TempVector1.Y, self.TempVector2.X, self.TempVector2.Y, nRadius)
        --     if not bNoLeave then 
        --         OnLeaveTrigger(self, tbObject, self.nTriggerAreaId, true)
        --     end
        --     bResult = true
        -- end
    else
        log("CheckObjectLeavePoisonCircle nTriggerInstanceId is nil ", tbObject.nServerInstanceId)
    end

    return bResult
end

local function OnCreateObject(self, tbGameObj)
    local pTriggerManager = CommonShell.GetCommon(GWorld):GetAreaTriggerManager()
    local pUEActor = tbGameObj.pUEActor
    if tbGameObj.ObjectType == GameObjectTypeDef.PlayerSelf or tbGameObj.ObjectType == GameObjectTypeDef.Horse then
        local bAdded = false
        if tbGameObj:IsShip() then
            local pBox = pUEActor.ShipBox
            bAdded = pTriggerManager:AddActorBox(pUEActor, pBox)
        else
            bAdded = pTriggerManager:AddActor(pUEActor)
        end
        if not bAdded then
            error(string.format("PoisonCircle add actor failed: %d", tbGameObj.nServerInstanceId))
        end
        log("FFAPoisonCircleStep OnCreateObject ", tbGameObj.nServerInstanceId)

        -- 超参数 加机器人会在跳伞后加，UPiratesAreaTriggerManager::AddActor(AActor* Actor) 默认是bIn = false.
        -- 这时加到毒圈外的机器人就触发不了OnActorLeaveArea，因此无法中毒，所以需要加上这个函数
        -- 另外因为人船变换，会删除actor重新创建，然后会触发LeaveTrigger和EnterTrigger事件，从而有一瞬间的debuf图标。
        -- 因此在人船变换时，不处理LeaveTrigger，在ActorCreate时，调用这个函数处理
        CheckObjectLeavePoisonCircle(self, tbGameObj)
    end
end

local function OnObjectDestroy(self, tbGameObj)
    log("FFAPoisonCircleStep OnObjectDestroy ", tbGameObj.nServerInstanceId)
    local pTriggerManager = CommonShell.GetCommon(GWorld):GetAreaTriggerManager()
    pTriggerManager:RemoveActor(tbGameObj.pUEActor)
end

local function OnStartChangeDisplay(self, tbGameObj)
    local nInstanceId = tbGameObj.nServerInstanceId
    if not self.nTriggerInstanceId then
        log("FFAPoisonCircleStep OnStartChangeDisplay no poisoncirce ", nInstanceId)
        return
    end
    if tbGameObj.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        log("FFAPoisonCircleStep OnStartChangeDisplay no player self ", nInstanceId)
        return
    end
    log("FFAPoisonCircleStep start change display ", nInstanceId)
    self.tbChangingDisplay[nInstanceId] = true
end

local function OnEndChangeDisplay(self, tbGameObj)
    local nInstanceId = tbGameObj.nServerInstanceId
    if not self.nTriggerInstanceId then
        log("FFAPoisonCircleStep OnEndChangeDisplay no poisoncirce ", nInstanceId)
        return
    end
    if tbGameObj.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        log("FFAPoisonCircleStep OnEndChangeDisplay no player self ", nInstanceId)
        return
    end
    log("FFAPoisonCircleStep end change display ", nInstanceId)
    self.tbChangingDisplay[nInstanceId] = nil
end

function FFAPoisonCircleStep:Init()
    FFAPoisonCircleStep.super.Init(self)

    self.szName = "FFAPoisonCircleStep"

    self.tbPoisonCircleData = {}
    self.tbChangingDisplay = {}

    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnCreateObject)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnObjectDestroy)
    EventManager:BindEventMethod(CommonEventDef.EV_START_CHANGEDISPLAY, self, OnStartChangeDisplay)
    EventManager:BindEventMethod(CommonEventDef.EV_END_CHANGEDISPLAY, self, OnEndChangeDisplay)
end

-- 外圆半径 减去 内圆半径的长度为半径,并以内圆圆心为圆心,形成的圆的范围内任取一点为外圆圆心
local function RandomPointInSecurityCircleRange(tbInnerTransform, nInnerRadius, nOuterRadius)
    local nRandomPointRadius = nOuterRadius - nInnerRadius
    if nRandomPointRadius <= 0 then
        logerror("RandomPoisonCirclePoint Faild, expected nInnerRadius less than nOuterRadius", nInnerRadius, nOuterRadius)
        return nil
    end

    local nRandomR = math.random(0, nRandomPointRadius)
    local nRandomAngle = math.random(0, 360)
    local nDiffX = math.ceil(nRandomR * math.cos(math.rad(nRandomAngle)))
    local nDiffY = math.ceil(nRandomR * math.sin(math.rad(nRandomAngle)))

    local tbNewTransform = {}
    tbNewTransform.X = tbInnerTransform.X + nDiffX
    tbNewTransform.Y = tbInnerTransform.Y + nDiffY
    tbNewTransform.Z = tbInnerTransform.Z

    return tbNewTransform
end

local function GenrateOutPointWhichContainInnterCircleInRect(self, nHalfWidth, nOutCircleRadius, nInnerRadius , tbInnterPoint)
    local nValidWidth = nHalfWidth - nOutCircleRadius

    local nTryTime = 100
    for i = nTryTime, 1, -1 do
        local tbOutPoint = RandomPointInSecurityCircleRange(tbInnterPoint, nInnerRadius, nOutCircleRadius)
        if math.abs(tbOutPoint.X ) <= nValidWidth and
           math.abs(tbOutPoint.Y ) <= nValidWidth then
            return tbOutPoint
        end
    end

    --直接给出一个可行解
    local vec1 = LuaVector(0 - tbInnterPoint.X, 0 - tbInnterPoint.Y, 0)
    vec1 = vec1:Normalized()
    local point = LuaVector(tbInnterPoint.X, tbInnterPoint.Y, 0)
    local ret = point + vec1 * (nOutCircleRadius - nInnerRadius)
    return {X = ret.x, Y = ret.y, 0}
end

-- 根据最终点生成毒圈数据
local function InitPoisonCircleData_FinalPoint(self)
    local tbSetting = PoisonCircleSettingDataTable:GetContainer(BattleGameModeSystem:GetCurrentDungeonId())
    local nLandPercent = tbSetting.nLandPercent
    local nMaxRangeWidth = tbSetting.nMaxRangeWidth
    local fMapHalfWidth = nMaxRangeWidth / 2
    local tbFinalPoint

    local szKey = "INTER_FFAFinalPoint"
    if BattleBlackboard:IsDefined(szKey) then
        --gm命令指定了最终点
        tbFinalPoint = BattleBlackboard:GetTable(szKey)
        log("gm set finalpoint: ", tbFinalPoint.X, tbFinalPoint.Y)
    else
        local bLandIdEqual = tbSetting.bLandIdEqual
        local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
        tbFinalPoint = GridTypeManager:GetRandomPosition(nLandPercent, bLandIdEqual)
        log("GridTypeManager GetRandomPosition: ", tbFinalPoint.X, tbFinalPoint.Y)
    end

    local tbPoisonCircleTable = PoisonCircleDataTable:GetContainer(BattleGameModeSystem:GetCurrentDungeonId())
    local nCount = #tbPoisonCircleTable

    local nInnterRadius = 1
    local tbInnterPoint = tbFinalPoint

    for nIndex = nCount, 1, -1 do
        local tbConf = tbPoisonCircleTable[nIndex]
        if not tbConf then
            logerror("InitPoisonCircleData_CompleteRandom Faild, FindPoisonCircleConfig error nIndex: ", nIndex)
            return
        end

        local nOutCircleRadius  = tbConf.nRadius

        local tbPoint = {}
        if nIndex == 1 then --第一个圈是整个地图的外切圆，所以肯定是0，0点
            tbPoint.X = 0
            tbPoint.Y = 0
            tbPoint.Z = 0
        else
            tbPoint = GenrateOutPointWhichContainInnterCircleInRect(self, fMapHalfWidth, nOutCircleRadius, nInnterRadius, tbInnterPoint)
            nInnterRadius = nOutCircleRadius
            tbInnterPoint = tbPoint
        end

        local tbPoisonCircle = {}
        tbPoisonCircle.ShrinkTime = tbConf.nShrinkTime
        tbPoisonCircle.Radius = tbConf.nRadius
        tbPoisonCircle.WaitTime = tbConf.nWaitTime
        tbPoisonCircle.RadiusRange = tbConf.nRadiusRange
        tbPoisonCircle.BuffId = tbConf.nBuffId
        tbPoisonCircle.Id = tbConf.nId
        tbPoisonCircle.Transform = tbPoint

        if nIndex == nCount then
            tbPoisonCircle.NextTransform = nil
            tbPoisonCircle.NextRadius    = nil
        else
            tbPoisonCircle.NextTransform = self.tbPoisonCircleData[nIndex + 1].Transform
            tbPoisonCircle.NextRadius    = self.tbPoisonCircleData[nIndex + 1].Radius
        end

        self.tbPoisonCircleData[nIndex] =  tbPoisonCircle
    end
end

function FFAPoisonCircleStep:Parse(tbJsonData)
    if(not FFAPoisonCircleStep.super.Parse(self, tbJsonData)) then
        return false
    end

    return true
end

local function ClearPoisonCircleWaitTimer(self)
    if self.PoisonCircleWaitTimer then
        self.PoisonCircleWaitTimer:Clear()
        self.PoisonCircleWaitTimer = nil
    end
end

local PoisonCircleNext

-- 是否最后一个圈
local function CheckFinalPoisonCircle(self)
    if self.nCurrentIndex >= #self.tbPoisonCircleData then
        return true
    end
    return false
end

-- 同步客户端毒圈数据
local function RepPoisonCircle(self, nStageId)
    local tbPoisonCircle = GetPoisonCircleByIndex(self)
    if tbPoisonCircle then
        local rFFAPoisonCircleInfo = {}
        local nWaitTime = tbPoisonCircle.WaitTime
        local nShrinkTime = tbPoisonCircle.ShrinkTime
        local nNewStageId = nStageId and nStageId or 0
        if self.PoisonCircleWaitTimer then
            nNewStageId = POISONCIRCLE_WAIT
            nWaitTime = tbPoisonCircle.WaitTime - self.PoisonCircleWaitTimer:GetElapsedTime()
        end
        rFFAPoisonCircleInfo.nCurrentWaitTime = nWaitTime
        rFFAPoisonCircleInfo.nWaitEndTimeStamp = GlobalVariableSystem:GetLocalTime() + nWaitTime

        if self.PoisonCircleShrinkTimer then
            nNewStageId = POISONCIRCLE_SHRINK
            nShrinkTime = tbPoisonCircle.ShrinkTime - self.PoisonCircleShrinkTimer:GetElapsedTime()
        end
        rFFAPoisonCircleInfo.nCurrentShrinkTime = nShrinkTime
        rFFAPoisonCircleInfo.nShrinkEndTimeStamp = GlobalVariableSystem:GetLocalTime() + nShrinkTime
        rFFAPoisonCircleInfo.nCurrentRadius = tbPoisonCircle.Radius
        rFFAPoisonCircleInfo.nCurrentX = tbPoisonCircle.Transform.X
        rFFAPoisonCircleInfo.nCurrentY = tbPoisonCircle.Transform.Y
        rFFAPoisonCircleInfo.nStageId = nNewStageId

        rFFAPoisonCircleInfo.nNextRadius = tbPoisonCircle.NextRadius
        if tbPoisonCircle.NextTransform then
            rFFAPoisonCircleInfo.nNextX = tbPoisonCircle.NextTransform.X
            rFFAPoisonCircleInfo.nNextY = tbPoisonCircle.NextTransform.Y
        else
            rFFAPoisonCircleInfo.nNextX = tbPoisonCircle.Transform.X
            rFFAPoisonCircleInfo.nNextY = tbPoisonCircle.Transform.Y
        end
        rFFAPoisonCircleInfo.nInstanceId = self.nTriggerInstanceId

        local tbGameState = BattleGameModeSystem:GetGameState()
        tbGameState.rFFAPoisonCircleInfo:Set(rFFAPoisonCircleInfo)

        EventManager:OnFireEvent(CommonEventDef.EV_FFA_POISONCIRCLE_INFO_CHANGED, rFFAPoisonCircleInfo)
    end
end

-- 毒圈开始收缩
local function PoisonCircleShrink(self)
    ClearPoisonCircleWaitTimer(self)
    local tbPoisonCircle = GetPoisonCircleByIndex(self)
    if tbPoisonCircle then

        RepPoisonCircle(self, POISONCIRCLE_SHRINK)

        if self.nTriggerInstanceId and not CheckFinalPoisonCircle(self) then
            local tbGameTrigger = GameObjectSystem:FindByInstanceId(self.nTriggerInstanceId)
            local pUEActor = tbGameTrigger.pUEActor
            if pUEActor then
                local nShrinkTime = tbPoisonCircle.ShrinkTime
                local DestOrigin = Vector2D{X=tbPoisonCircle.NextTransform.X, Y=tbPoisonCircle.NextTransform.Y}
                pUEActor:StartShrink(DestOrigin, tbPoisonCircle.NextRadius, nShrinkTime)
            end
        end

        EventManager:OnFireEvent(CommonEventDef.EV_FFA_POISONCIRCLE_SHRINK_START, self.nCurrentIndex)
    end
end

-- 开始执行缩圈等待流程
local function PoisonCircleWait(self)
    local tbCurrentPoisonCircle = GetPoisonCircleByIndex(self)
    if tbCurrentPoisonCircle then
        -- 最后一个是点，跳出流程
        if CheckFinalPoisonCircle(self) then
            RepPoisonCircle(self, POISONCIRCLE_FINISH)
            return
        end
        RepPoisonCircle(self, POISONCIRCLE_WAIT)

        ClearPoisonCircleWaitTimer(self)
        self.PoisonCircleWaitTimer = Timer.NewTimerMethod(self, PoisonCircleShrink, tbCurrentPoisonCircle.WaitTime, false)
    end
end

-- 下一个毒圈
PoisonCircleNext = function(self)
    if self.nCurrentIndex < #self.tbPoisonCircleData then
        self.nCurrentIndex = self.nCurrentIndex + 1
        PoisonCircleWait(self)
    end
end

-- 创建Trigger
local function PoisonCircleTriggerCreate(self)
    local tbPoisonCircle = GetPoisonCircleByIndex(self)
    if tbPoisonCircle then
        local tbTriggerJson = {}
        local tbShape = {}
        tbShape.Type = 0
        tbShape.Radius = tbPoisonCircle.Radius
        tbTriggerJson.Transform = tbPoisonCircle.Transform
        tbTriggerJson.Shape = tbShape
        tbTriggerJson.ResId = 22
        tbTriggerJson.TriggerId = TRIGGER_ID
        tbTriggerJson.Visibility = 0
        tbTriggerJson.GroupIndex = 0
        tbTriggerJson.SubGroupIndex = 0
        local tbData = {tbJsonData = tbTriggerJson}
        local tbGameTrigger = GameObjectSystem:CreateTriggerInGameMode(tbData)
        self.nTriggerAreaId = tbGameTrigger.pUEActor.AreaId
        self.nTriggerInstanceId = tbGameTrigger:GetServerInstanceId()
        self.SelfEventHelper:RegisterCppDelegate(tbGameTrigger.pUEActor.ShrinkCircleOverDispatcher, self, self.OnPoisonCircleShrinkFinish)
    end
end

local function ClearPoisonCircleDamageTimer(self)
    if self.PoisonCircleDamageTimer then
        self.PoisonCircleDamageTimer:Clear()
        self.PoisonCircleDamageTimer = nil
    end
end

local function UpdatePoisonCircleDamage(self)
    SetPoisonCircleBlackboard(self)
end

local function PoisonCircleDamageStart(self)
    if self.nTriggerInstanceId == nil then
        return
    end
    ClearPoisonCircleDamageTimer(self)
    self.PoisonCircleDamageTimer = Timer.NewTimerMethod(self, UpdatePoisonCircleDamage, POISON_CIRCLE_DAMAGE_UPDATE_INTERVAL, true)
end

-- local function CheckLeavePoisonCircle(self)
--     local tbGameObjects = GameObjectSystem:GetAllGameObjects()
--     for _, tbGameObject in pairs(tbGameObjects) do
--         if tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
--             CheckObjectLeavePoisonCircle(self, tbGameObject)
--         end
--     end
-- end

local function PoisonCircleStart(self)
    self.nCurrentIndex = 1
    PoisonCircleTriggerCreate(self)
    -- CheckLeavePoisonCircle(self)
    PoisonCircleDamageStart(self)
    PoisonCircleWait(self)
end

local function OnModifyPoisonCirclePos(self, nX, nY)
    for k,v in pairs(self.tbPoisonCircleData) do
        v.Transform.X = nX
        v.Transform.Y = nY
    end
end

local function PrintPoisonCircleInfo(self)
    if self.nTriggerInstanceId ~= nil then
        local tbGameTrigger = GameObjectSystem:FindByInstanceId(self.nTriggerInstanceId)
        if tbGameTrigger ~= nil and tbGameTrigger.pUEActor ~= nil then
            tbGameTrigger.pUEActor:PrintPoisonCircleInfo()
        end
    end
end

function FFAPoisonCircleStep:RegisterEvent()
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_AREA_ENTER, self, OnEnterTrigger)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_AREA_LEAVE, self, OnLeaveTrigger)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_MODIFY_POISONCIRCLE_POS, self, OnModifyPoisonCirclePos)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_PRINT_POISONCIRCLE_INFO, self, PrintPoisonCircleInfo)
end

local function ChangePoisonCircleBuff(self, nOldBuffId)
    SetPoisonCircleBlackboard(self)
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if not Object:IsDead() and Object.BuffComponentServer then
            if Object.BuffComponentServer:IsExistBuffById(nOldBuffId) then
                local nNewBuffId = GetCurrentBuffId(self)
                Object.BuffComponentServer:RemoveBuffById(nOldBuffId)
                Object.BuffComponentServer:AddBuffById(nNewBuffId)
            end
        end
    end
end

local function ClearPoisonCircleCheckBuffDelayTimer(self)
    if self.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
end

local function ClearPoisonCircleCheckBuffTimer(self)
    if self.CheckBuffTimer then
        self.CheckBuffTimer:Clear()
        self.CheckBuffTimer = nil
    end
end

local function CheckPoisonCircleBuff(self)
    local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    if tbSetting and tbSetting:GameOver() then
        log("CheckPoisonCircleBuff but game over ")
        ClearPoisonCircleCheckBuffTimer(self)
        return
    end

    local nBuffId = GetCurrentBuffId(self)
    if not nBuffId then
        return
    end

    local tbOldAbnormals = self.tbAbnormalObj 
    self.tbAbnormalObj = {}

    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if not Object:IsDead() and Object.BuffComponentServer then
            -- local x, y, z = Object:GetLocationXYZ()
            -- log("obj position ", nId, x, y, z)
            if not Object.BuffComponentServer:IsExistBuffById(nBuffId) then
                if CheckObjectLeavePoisonCircle(self, Object, true) then
                    -- PrintPoisonCircleInfo(self)
                    local nId = Object:GetServerInstanceId()
                    if tbOldAbnormals and tbOldAbnormals[nId] then
                        logerror(string.format("PoisonCircle error %d %d ", nId, self.nCurrentIndex))
                    end
                    self.tbAbnormalObj[nId] = true
                end
            end
        end
    end
end

function FFAPoisonCircleStep:OnPoisonCircleShrinkFinish()
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_POISONCIRCLE_SHRINK_FINISH, self.nCurrentIndex)
    -- 得到老buff
    local nOldBuffId = GetCurrentBuffId(self)

    PoisonCircleNext(self)
    -- 换成新buff
    ChangePoisonCircleBuff(self, nOldBuffId)
end

function FFAPoisonCircleStep:Start()
    FFAPoisonCircleStep.super.Start(self)

    BattleBlackboard:DefineTable(POISON_CIRCLE_CENTER, nil)
    BattleBlackboard:DefineNumber(POISON_CIRCLE_RADIUS, 0)

    InitPoisonCircleData_FinalPoint(self)
    
    EventManager:OnFireEvent(CommonEventDef.EV_POISONCIRCLE_DATA_INIT, self.tbPoisonCircleData)
    PoisonCircleStart(self)

    self.TempVector1 = Vector()
    self.TempVector2 = Vector()

    local fnCheckPoisonCircleTimer = function()
        ClearPoisonCircleCheckBuffDelayTimer(self)
        self.CheckBuffTimer = Timer.NewTimerMethod(self, CheckPoisonCircleBuff, POISONCIRCLE_BUFF_TIMER, true)
    end
    self.tbDelayHandle = DelayTimer:DelayRun(fnCheckPoisonCircleTimer, CHECK_POISON_CIRCLE_DELAY)
end

function FFAPoisonCircleStep:Uninit()
    self.tbChangingDisplay = nil
    self.TempVector2 = nil
    self.TempVector1 = nil
    self.tbAbnormalObj = nil

    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnCreateObject)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnObjectDestroy)
    EventManager:UnBindEventMethod(CommonEventDef.EV_START_CHANGEDISPLAY, self, OnStartChangeDisplay)
    EventManager:UnBindEventMethod(CommonEventDef.EV_END_CHANGEDISPLAY, self, OnEndChangeDisplay)

    ClearPoisonCircleCheckBuffDelayTimer(self)
    ClearPoisonCircleWaitTimer(self)
    ClearPoisonCircleDamageTimer(self)
    ClearPoisonCircleCheckBuffTimer(self)

    FFAPoisonCircleStep.super.Uninit(self)
end

function FFAPoisonCircleStep:ForceStop()
    FFAPoisonCircleStep.super.ForceStop(self)
    ClearPoisonCircleDamageTimer(self)
end

function FFAPoisonCircleStep:OnCompleted()
    FFAPoisonCircleStep.super.OnCompleted(self)
end

function FFAPoisonCircleStep:RepStepInfo(bRepNow)
    FFAPoisonCircleStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function FFAPoisonCircleStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()
    return true
end

return FFAPoisonCircleStep