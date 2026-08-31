-- 协会皇家护卫队的战斗玩法

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local SocietyGuardBattleStep = luaclass("SocietyGuardBattleStep", BattleStepBaseClass)

local BattleNpcGroupDeadTargetClass = require("BattleNpcGroupDeadTarget")
local BattleRuntimePawnDeadTargetClass = require("BattleRuntimePawnDeadTarget")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleTeamSystem = require("BattleTeamSystem")
local TimerHelperClass = require("SelfTimerHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SpawnerSystem = require("SpawnerSystem")
local SpawnerDef = require("SpawnerDef")
local CampDef = require("CampDefine")
local TransformUtil = require("SocietyGuardTransformUtil")
local BattleResultDef = require("BattleResultDef")
local GroupTriggerUtil = require("GroupTriggerUtil")
local BattleGameModeDef = require("BattleGameModeDef")
local BattleObjectiveHelper = require("BattleObjectiveHelper")

local PLAYER_WIN = BattleResultDef.WIN
local PLAYER_LOSE = BattleResultDef.LOSE

local RATIO_MAX = 100

-- 所有的阶段信息都在这里
-- key : nStageIndex        第几stage
-- value : stage info table
-- {
--      tbTargetList = {}       target list      该stage有几个target
-- }
SocietyGuardBattleStep.tbStagesMap            = nil
SocietyGuardBattleStep.nCurrentStage          = 0

SocietyGuardBattleStep.AllNpcGroupDeadTarget  = nil
SocietyGuardBattleStep.GuardNpcDeadTarget     = nil

SocietyGuardBattleStep.TimerHelper            = nil
SocietyGuardBattleStep.StageTimer             = nil       -- 每个stage的时间，该时间结束，则当前stage结束
SocietyGuardBattleStep.tbJsonData             = nil
SocietyGuardBattleStep.tbTemplateData         = nil       -- SocietyGuardDataTable
SocietyGuardBattleStep.SocietyGuardGameState  = nil       -- game state
SocietyGuardBattleStep.rBattlePlayerResultStep= nil

SocietyGuardBattleStep.CountdownTipsTimer     = nil       -- 倒计时提示的timer,当前stage结束时候应该把该Timer清掉
-- 下阶段倒计时list，每阶段开始重新赋值，每阶段结束清空
-- {
--     nTipsNumber
--     nNextDeltaTime
-- }
SocietyGuardBattleStep.tbStageCountdownList = nil

-- key : GroupIndex
-- value : [group json data info]
--[[
{
    tbNpcJsonDataList = 
    [{
        Transform:
        {
            X: 5920,
            Y: 79300,
            Z: 530,
            Yaw: 0
        },
        TemplateId: 7,
        GroupIndex: 0,
        CampType: 1
    }],
    tbRandomNpcJsonDataList =
    [{
        "Transform":
			{
				"X": 1352,
				"Y": 68651,
				"Z": 0,
				"Yaw": 0
			},
			"SpawnerId": 1,
			"GroupIndex": 1,
			"SubGroupIndex": 0,
			"CampType": 1,
			"PathId": 1,
			"TemplateIds": [ 4110, 4111 ]
    }],
    tbTriggerJsonDataList = 
    [{
        "Name": "BP_AreaTrigger_03",
        "Guid": "33A10B24-49A16A10-E0951D8D-F4F8F06A",
        "Transform":
        {
            "X": -43520,
            "Y": 99710,
            "Z": 0,
            "Yaw": 0
        },
        "Shape":
        {
            "Type": 0,
            "Radius": 1
        },
        "ResId": -1,    -- modify by logic
        "BuffId":8,     -- modify by logic
        "TriggerId": 3,
        "GroupIndex": 0,
        "SubGroupIndex": 0
    }]
}
]]

SocietyGuardBattleStep.tbGroupJsonDataMap  = nil

local FIRST_INDEX = 1

local function CreateGroupJsonData(self, nGroupIndex)
    if self.tbGroupJsonDataMap[nGroupIndex] == nil then
        self.tbGroupJsonDataMap[nGroupIndex] = {}
        self.tbGroupJsonDataMap[nGroupIndex].tbNpcJsonDataList = {}
        self.tbGroupJsonDataMap[nGroupIndex].tbRandomNpcJsonDataList = {}
        self.tbGroupJsonDataMap[nGroupIndex].tbTriggerJsonDataList = {}
    end
    return self.tbGroupJsonDataMap[nGroupIndex]
end

-- 将NPC的出生位置移到随机目的地
local function MoveGroupNpcToRandomTransform(self)
    local tbGroupJsonDataMap = self.tbGroupJsonDataMap
    local tbGroupJsonData = nil
    local tbTargetTransform = nil
    local tbTempNpcJsonDataList = {}
    local function fnSort(tbNpcJsonDataA, tbNpcJsonDataB)
        return tbNpcJsonDataA.SpawnerId > tbNpcJsonDataA.SpawnerId
    end 

    local nIndex = next(tbGroupJsonDataMap)
    while (nIndex ~= nil) do
        tbGroupJsonData = tbGroupJsonDataMap[nIndex]
        tbTargetTransform = TransformUtil:GetNextRandomTransform()
        if tbTargetTransform == nil then
            error('MoveGroupNpcToRandomTransform() tbTargetTransform is nil !')
            return
        end
        tbTempNpcJsonDataList = {}
        for k, tbNpcJsonData in pairs(tbGroupJsonData.tbNpcJsonDataList) do
            if tbNpcJsonData.CampType == CampDef.Type.CAMP_2 then
                table.insert(tbTempNpcJsonDataList, tbNpcJsonData)
            end
        end

        table.sort(tbTempNpcJsonDataList, fnSort)

        -- 如果是最后一波，则随机一个战列舰
        local nGroupNpcCount = #tbTempNpcJsonDataList
        if nIndex == self.tbTemplateData.nStageCount then
            
            local nRandomRatio = math.random(1, RATIO_MAX)
            if nRandomRatio <= self.tbTemplateData.nLastStageRandomRatio then
                local nRendomIndex = math.random(1, nGroupNpcCount)
                local tbRandomNpcJsonData = tbTempNpcJsonDataList[nRendomIndex]
                tbRandomNpcJsonData.TemplateId = self.tbTemplateData.nLastStageRandomShipId
            end
        end

        TransformUtil:ModifyGroupNpcsTransform(tbTempNpcJsonDataList, tbTargetTransform, math.ceil(nGroupNpcCount/2))
        nIndex = next(tbGroupJsonDataMap, nIndex)
    end
end

local function ModifyTriggerRandomInfo(self)
    local tbGroupJsonDataMap = self.tbGroupJsonDataMap
    local tbGroupJsonData = nil
    local tbTriggerJsonDataList = {}
    local nIndex = next(tbGroupJsonDataMap)
    while (nIndex ~= nil) do
        tbGroupJsonData = tbGroupJsonDataMap[nIndex]
        local nGroupTriggerId = self.tbTemplateData.tbGroupTriggerIdList[nIndex]
        local tbTriggerBuffInfo = GroupTriggerUtil:GetRandomBuffIdByGroupID(nGroupTriggerId)
        if tbTriggerBuffInfo == nil then
            error('ModifyTriggerRandomInfo() tbTriggerBuffInfo is nil !')
            return
        end

        tbTriggerJsonDataList = tbGroupJsonData.tbTriggerJsonDataList
        for k, tbTriggerJsonData in pairs(tbTriggerJsonDataList) do
            tbTriggerJsonData.ResId  = tbTriggerBuffInfo.nTriggerResId
            tbTriggerJsonData.BuffId = tbTriggerBuffInfo.nBuffId
        end

        nIndex = next(tbGroupJsonDataMap, nIndex)
    end
end

-- 解析npc json data
local function ParseGroupJsonData(self, tbNpcJsonTableFile, tbRandomNpcJsonTableFile, tbTriggerJsonTableFile)
    if tbNpcJsonTableFile == nil then
        error('SocietyGuardBattleStep ParseGroupJsonData() tbNpcJsonTableFile is nil')
        return
    end

    local tbGroupInfo = nil
    for _, tbNpcJsonData in pairs(tbNpcJsonTableFile) do
        tbGroupInfo = CreateGroupJsonData(self, tbNpcJsonData.GroupIndex)
        table.insert(tbGroupInfo.tbNpcJsonDataList, tbNpcJsonData)
    end

    MoveGroupNpcToRandomTransform(self)

    for _, tbRandomNpcJsonData in pairs(tbRandomNpcJsonTableFile) do
        tbGroupInfo = CreateGroupJsonData(self, tbRandomNpcJsonData.GroupIndex)
        table.insert(tbGroupInfo.tbRandomNpcJsonDataList, tbRandomNpcJsonData)
    end

    for _, tbTriggerJsonData in pairs(tbTriggerJsonTableFile) do
        tbGroupInfo = CreateGroupJsonData(self, tbTriggerJsonData.GroupIndex)
        table.insert(tbGroupInfo.tbTriggerJsonDataList, tbTriggerJsonData)
    end

    ModifyTriggerRandomInfo(self)
end

local function AddGroupTargetData(self)
    local nNpcCampCount = 0
    local TargetNpcCampType = CampDef.Type.CAMP_2
    local tbGroupNpcList = nil
    for nGroupIndex, tbGroupInfo in pairs(self.tbGroupJsonDataMap) do
        tbGroupNpcList = tbGroupInfo.tbNpcJsonDataList
        nNpcCampCount = 0
        for _, tbJsonData in pairs(tbGroupNpcList) do
            if tbJsonData.CampType == TargetNpcCampType then
                nNpcCampCount = nNpcCampCount + 1
            end
        end
        self.AllNpcGroupDeadTarget:AddGroupInfo(nGroupIndex, TargetNpcCampType, nNpcCampCount)
    end
end

function SocietyGuardBattleStep:Init()
    SocietyGuardBattleStep.super.Init(self)
    self.szName = "SocietyGuardBattleStep"
    self.TimerHelper = TimerHelperClass()
    self.tbGroupJsonDataMap = {}
    self.tbStageCountdownList = {}
    self.AllNpcGroupDeadTarget = self:CreateTarget(BattleNpcGroupDeadTargetClass)
    self.GuardNpcDeadTarget = self:CreateTarget(BattleRuntimePawnDeadTargetClass)
end

function SocietyGuardBattleStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)
    self.SocietyGuardGameState = tbGameState
    self.tbTemplateData = tbTemplateData
    self.rBattlePlayerResultStep = tbGameState.rBattlePlayerResultStep
    local rStep = self.rBattlePlayerResultStep
    rStep.nStepTime = tbTemplateData.nShowResultTime
    rStep.Results = {}
    TransformUtil:Parse(tbJsonTableFile.tbContainer.Transforms)
    ParseGroupJsonData(self, tbJsonTableFile.tbContainer.DungeonNPCSpawners, tbJsonTableFile.tbContainer.DungeonRandomTemplateNPCSpawners, tbJsonTableFile.tbContainer.Triggers)
    AddGroupTargetData(self)
end

local function NotifyCountdownTips(self)
    local tbStageCountdownTipsList = self.tbStageCountdownList
    self.TimerHelper:ClearTimer(self.CountdownTipsTimer)

    -- nTipsNumber
    -- nNextDeltaTime
    local tbCurrentCountdownInfo = tbStageCountdownTipsList[FIRST_INDEX]
    
    -- do something
    local SocietyGuardGameState = self.SocietyGuardGameState
    SocietyGuardGameState.rSocietyGuardCountdownTipInfo.nNextStageSecond = tbCurrentCountdownInfo.nTipsNumber
    SocietyGuardGameState.rSocietyGuardCountdownTipInfo.RepNow()
    
    if tbCurrentCountdownInfo == nil or tbCurrentCountdownInfo.nNextDeltaTime == 0 then
        return
    end
    
    self.CountdownTipsTimer = self.TimerHelper:NewTimerMethod(self, NotifyCountdownTips, tbCurrentCountdownInfo.nNextDeltaTime, false)
    table.remove(tbStageCountdownTipsList, FIRST_INDEX)
end

-- 处理新stage的倒计时提示
local function ProcessNewStageCountdownTips(self)
    local nCurrentStageTime = self.tbTemplateData.tbStageTimeList[self.nCurrentStage]
    local tbStageCountdownTipsList = self.tbTemplateData.tbStageCountdownTipsList
    self.tbStageCountdownList = {}

    local nCountdownTipsCount = #tbStageCountdownTipsList
    if nCountdownTipsCount == 0 then
        return
    end

    local nBeginIndex = -1
    for k, nCountdownTime in pairs(tbStageCountdownTipsList) do
        if nCurrentStageTime > nCountdownTime then
            nBeginIndex = k
            break
        end
    end

    if nBeginIndex == -1 then
        error('SocietyGuardBattleStep:ProcessNewStageCountdownTips() not count down')
        return
    end

    local nNextIndex = 0
    local nNextDeltaTime = 0
    for i = nBeginIndex, nCountdownTipsCount do
        nNextIndex = i + 1
        if i == nCountdownTipsCount then
            nNextDeltaTime = 0
        else
            nNextDeltaTime = tbStageCountdownTipsList[i] - tbStageCountdownTipsList[nNextIndex]
        end
        
        -- nTipsNumber
        -- nNextDeltaTime
        local tbDeltaTimeInfo = {}
        tbDeltaTimeInfo.nNextDeltaTime = nNextDeltaTime
        tbDeltaTimeInfo.nTipsNumber = tbStageCountdownTipsList[i]
        table.insert(self.tbStageCountdownList, tbDeltaTimeInfo)
    end

    local nBeginCountdownTime = nCurrentStageTime - tbStageCountdownTipsList[nBeginIndex]
    self.CountdownTipsTimer = self.TimerHelper:NewTimerMethod(self, NotifyCountdownTips, nBeginCountdownTime, false)
end

local function OnTriggerHit(self, GameTriggerInstance, pHitActor, nGroupIndex, nBuffId)
    -- test begin
    -- GameTriggerInstance:PlayDestroyedEffect()
    -- GameObjectSystem:DestroyTriggerInGameMode(GameTriggerInstance:GetUEActorUniqueId())
    -- test end

    local tbGameObject = nil
    local bIsBullet = false
    tbGameObject = GameObjectSystem:FindByUEActor(pHitActor)
    if(tbGameObject == nil) then
        local pShotClass = BattleGameModeDef.SHOT_ACTOR_CLASS:load()
        if(KismetMathLibrary.ClassIsChildOf(GameplayStatics.GetObjectClass(pHitActor), pShotClass)) then
            local pOwnerActor = pHitActor:GetInstigator()
            tbGameObject = GameObjectSystem:FindByUEActor(pOwnerActor)
            bIsBullet = true
        end 
    end

    if(tbGameObject and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf) then
        -- GameTriggerInstance:PlayDestroyedEffect()
        GameObjectSystem:DestroyTriggerInGameMode(GameTriggerInstance:GetUEActorUniqueId())
        if bIsBullet == true then
            pHitActor:KillShot(false, Enum_HitEffectType.Default)
        end
        local BuffComponentServer = tbGameObject.BuffComponentServer
        if BuffComponentServer == nil then
            logerror('SocietyGuardBattleStep OnTriggerHit() BuffComponentServer is nil')
            return
        end
        BuffComponentServer:AddBuffById(nBuffId)
    end
end

local function StartNewStage(self)
    self.nCurrentStage = self.nCurrentStage + 1
    local nGroupIndex = self.nCurrentStage
    local tbGroupInfo = self.tbGroupJsonDataMap[nGroupIndex]
    local tbNpcJsonDataList = nil
    local tbRandomNpcJsonDataList = nil
    local tbTriggerJsonDataList = nil

    if tbGroupInfo ~= nil then
        local GameTrigger = nil
        local BattleTriggerComponent = nil
        local GameNpcInstance = nil
        -- create npc
        tbNpcJsonDataList = tbGroupInfo.tbNpcJsonDataList
        for _, tbNpcJsonData in pairs(tbNpcJsonDataList) do
            tbNpcJsonData.AutoSpawn = true
            SpawnerSystem:CreateSpawner(SpawnerDef.SpawnerType.NPC, tbNpcJsonData, true)
        end

        -- create random npc
        tbRandomNpcJsonDataList = tbGroupInfo.tbRandomNpcJsonDataList
        for _, tbRandomNpcJsonData in pairs(tbRandomNpcJsonDataList) do
            tbRandomNpcJsonData.AutoSpawn = true
            _, GameNpcInstance = SpawnerSystem:CreateSpawner(SpawnerDef.SpawnerType.RANDOM_TEMPLATE_NPC, tbRandomNpcJsonData, true)
            self.GuardNpcDeadTarget:AddTargetPawn(GameNpcInstance)
            self.GuardNpcDeadTarget:SetCanComplete(true)
        end

        -- create trigger
        tbTriggerJsonDataList = tbGroupInfo.tbTriggerJsonDataList
        for _, tbTriggerJsonData in pairs(tbTriggerJsonDataList) do
            local tbData = {tbJsonData = tbTriggerJsonData}
            GameTrigger = GameObjectSystem:CreateTriggerInGameMode(tbData)
            BattleTriggerComponent =  GameTrigger.BattleTriggerComponent
            local fnFunc = function(tbTriggerObject, pHitActor, nTriggerId)
            --    local tbGameObject = GameObjectSystem:FindByUEActor(pHitActor)
            --    if(tbGameObject) then
                    OnTriggerHit(self, tbTriggerObject, pHitActor, nGroupIndex, tbTriggerJsonData.BuffId)
            --    end
            end
            BattleTriggerComponent:SetActorEnterCallback(fnFunc)
            BattleTriggerComponent:EnableTriggerShot(true)
        end
    else
        logerror('SocietyGuardBattleStep StartNewStage() not exist group data, group index : ', nGroupIndex)
    end

    -- clear timer
    self.TimerHelper:ClearTimer(self.StageTimer)
    self.TimerHelper:ClearTimer(self.CountdownTipsTimer)

    BattleObjectiveHelper:SetObjectiveStepIndex(self.nCurrentStage, true)

    if self.nCurrentStage >= self.tbTemplateData.nStageCount then
        return
    end

    -- > 创建 stage timer
    local nStageTime = self.tbTemplateData.tbStageTimeList[self.nCurrentStage]
    self.TimerHelper:ClearTimer(self.StageTimer)
    self.StageTimer = self.TimerHelper:NewTimerMethod(self, StartNewStage, nStageTime, false)

    -- > 创建 stage timer count down tips 倒计时提示
    ProcessNewStageCountdownTips(self)
end

-- 同步Step信息
function SocietyGuardBattleStep:RepStepInfo(bRepNow)
--     if(bRepNow) then
-- --        self.rSocietyGuardBattleStepInfo.RepNow()
--     else
-- --        self.rSocietyGuardBattleStepInfo.Rep()
--     end
    SocietyGuardBattleStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function SocietyGuardBattleStep:SnapshotToReplicatedProperty()

    return true
end

-- 当Target结束时候会调用这个函数
-- return true  该step完成
-- return false 该step没完成
function SocietyGuardBattleStep:CheckComplete(BattleTarget)
    local nResult = false

    if BattleTarget == self.GuardNpcDeadTarget then
        nResult = PLAYER_LOSE
        if self.tbTemplateData.bTest == true then
            return false
        end
    else
        nResult = PLAYER_WIN
    end

    local tbResults  = self.rBattlePlayerResultStep.Results
    local tbAllTeamsInfo = BattleTeamSystem:GetAllTeamInfo()
    for _, tbTeamInfo in pairs(tbAllTeamsInfo) do
        for _, nPlayerId in pairs(tbTeamInfo.tbPlayerIds) do
            local tbResult = {}
            tbResult.nPlayerId = nPlayerId
            tbResult.nResult = nResult
            table.insert(tbResults, tbResult)
        end
    end
    return true
end

function SocietyGuardBattleStep:Start()
    StartNewStage(self)
    SocietyGuardBattleStep.super.Start(self)
end

function SocietyGuardBattleStep:Complete()
    -- clear timer
    self.TimerHelper:ClearTimer(self.StageTimer)
    self.TimerHelper:ClearTimer(self.CountdownTipsTimer)
    -- 
    SocietyGuardBattleStep.super.Complete(self)
end

-- 将结果写入到GameState数据面板里
function SocietyGuardBattleStep:CalculateResult()
    
end

-- 需要清除timer 否则副本中途退出有问题
function SocietyGuardBattleStep:Uninit()
    self.TimerHelper:ClearTimer(self.StageTimer)
    self.TimerHelper:ClearTimer(self.CountdownTipsTimer)
    SocietyGuardBattleStep.super.Uninit(self)
end

return SocietyGuardBattleStep
