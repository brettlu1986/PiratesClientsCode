-- PVE02 第一场战斗

local luaclass = require("luaclass")
local PVE02BattleGameStepBaseClass = require("PVE02BattleGameStepBase")
local PVE02Battle2GameStep = luaclass("PVE02Battle2GameStep", PVE02BattleGameStepBaseClass)

local BattleRuntimePawnDeadTargetClass = require("BattleRuntimePawnDeadTarget")

local CommonEventDef = require("CommonEventDef")
local Timer = require("Timer")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SpawnerSystem = require("SpawnerSystem")
local CampDef = require("CampDefine")
local D2CHelper = require("D2CHelper")
local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleObjectiveHelper = require("BattleObjectiveHelper")
local BattleTargetTrackHelper = require("BattleTargetTrackHelper")

PVE02Battle2GameStep.tbOrdinaryMobJsonDatas = nil -- tbOrdinaryMobJsonDatas[nSubGroupIndex] = tbRandomNpcJsonData 普通怪刷新点数据
PVE02Battle2GameStep.tbEliteMobJsonDatas = nil -- tbEliteMobJsonDatas[nSubGroupIndex] = {tbNpcJsonData1, tbNpcJsonData2} 精英怪数据

-- 小怪刷新间隔
PVE02Battle2GameStep.nMobRefreshInterval = nil -- in second
-- 场景中最多存在的小怪数
PVE02Battle2GameStep.nOrdinaryMobCountLimit = nil
-- 每次每组刷新小怪数
PVE02Battle2GameStep.nOrdinaryMobRefreshCount = nil

-- 怪物组数
PVE02Battle2GameStep.nSubGroupCount = nil

-- 精英怪总数
PVE02Battle2GameStep.nEliteNpcCount = nil
-- 运行时数据
-- tbRuntimeSubGroupData[nSubGroup].tbEliteMobs = {tbEliteMob1, tbEliteMob2}
-- tbRuntimeSubGroupData[nSubGroup].Timer = Timer
PVE02Battle2GameStep.tbRuntimeSubGroupData = nil

-- 剩余的存活的小怪
PVE02Battle2GameStep.tbOrdinaryNpcs = nil

-- Trigger相关
PVE02Battle2GameStep.tbTriggers = nil -- tbTriggers[nTriggerId] = tbJsonTrigger
PVE02Battle2GameStep.tbTriggerActivated = nil -- tbTriggerActivated[nTriggerId] = true or nil

-- 阻挡相关
PVE02Battle2GameStep.tbDummiesJson = nil -- 第二关和第三关之间阻挡的导出数据
PVE02Battle2GameStep.tbDummies = nil -- 第二关和第三关间阻挡对象数组

PVE02Battle2GameStep.EliteMobsDieTarget = nil
PVE02Battle2GameStep.OrdinaryMobsDieTarget = nil

PVE02Battle2GameStep.nDialog = nil

-- 在没有进入战斗状态时为每个玩家添加的（加速）状态，在进入战斗状态后，此状态移除
PVE02Battle2GameStep.nBattle2NonCombatStatusId = nil

PVE02Battle2GameStep.nSummonDialogId = nil

-- Fill tb2 elements to tb1
local function Fill(tb1, tb2)
    for i=1,#tb2 do
        tb1[tb2[i]] = true
    end
    return tb1
end

-- Append tb2's elements to tb1
local function Append(tb1, tb2)
    for i=1,#tb2 do
        tb1[#tb1 + 1] = tb2[i]
    end
    return tb1
end

-- 解析 template data
local function ParseTemplateData(self)
    local tbTemplateData = self.tbTemplateData
    self.nMobRefreshInterval = tbTemplateData.nBattle2MobRefreshInterval
    self.nOrdinaryMobCountLimit = tbTemplateData.nBattle2MobCountLimit
    self.nOrdinaryMobRefreshCount = tbTemplateData.nBattle2MobRefreshCount
    self.nDialog = tbTemplateData.nDialog2
    self.nBattle2NonCombatStatusId = tbTemplateData.nBattle2NonCombatStatusId
    self.nSummonDialogId = tbTemplateData.nSummonDialogId
end

local function ParseTriggerJsonTable(self, tbJsonTriggers)
    if tbJsonTriggers == nil then
        logerror('PVE02Battle2GameStep ParseNpcsJsonData() tbNpcJsonTableFile is nil')
        return
    end

    self.tbTriggers = {}
    self.tbTriggerActivated = {}
    local tbTriggerSubGroupIds = {} -- validated use
    local nTriggerCount = #tbJsonTriggers
    assert(nTriggerCount == self.nSubGroupCount)
    for _,tbTrigger in ipairs(tbJsonTriggers) do
        if tbTrigger.GroupIndex == 2 then
            assert(tbTrigger.SubGroupIndex >= 1)
            assert(tbTrigger.SubGroupIndex <= nTriggerCount)
            assert(tbTriggerSubGroupIds[tbTrigger.SubGroupIndex] == nil, "Trigger subgroup dup. ", tbTrigger.SubGroupIndex)
            tbTriggerSubGroupIds[tbTrigger.SubGroupIndex] = true

            assert(self.tbTriggers[tbTrigger.TriggerId] == nil)
            self.tbTriggers[tbTrigger.TriggerId] = tbTrigger
        end
    end
end

-- 解析npc json data
local function ParseNpcsJsonData(self, tbNpcJsonTableFile, tbRandomNpcJsonTableFile, tbJsonTriggers)
    if tbNpcJsonTableFile == nil then
        logerror('PVE02Battle2GameStep ParseNpcsJsonData() tbNpcJsonTableFile is nil')
        return
    end

    if tbRandomNpcJsonTableFile == nil then
        logerror('PVE02Battle2GameStep ParseNpcsJsonData() tbRandomNpcJsonTableFile is nil')
        return
    end

    self.tbOrdinaryMobJsonDatas = {}
    self.tbEliteMobJsonDatas = {}

    local tbOrdinaryMobIds = {} -- used to check if a NpcJsonData is ordinary or elite
    local nRandomNpcSubGroupCount = 0
    for _, tbRandomNpcJsonData in ipairs(tbRandomNpcJsonTableFile) do
        if tbRandomNpcJsonData.GroupIndex == 2 then
            assert(self.tbOrdinaryMobJsonDatas[tbRandomNpcJsonData.SubGroupIndex] == nil, "PVE02Battle2GameStep ParseNpcsJsonData failed. RandomNpcJsonData SubGroupIndex dup. ", tbRandomNpcJsonData.SubGroupIndex)
            self.tbOrdinaryMobJsonDatas[tbRandomNpcJsonData.SubGroupIndex] = tbRandomNpcJsonData
            Fill(tbOrdinaryMobIds, tbRandomNpcJsonData.SpawnerIds)
            nRandomNpcSubGroupCount = nRandomNpcSubGroupCount + 1
        end
    end

    -- Validate begin
    local nValidCount = 0
    for k, v in pairs(self.tbOrdinaryMobJsonDatas) do
        nValidCount = nValidCount + 1
        assert(k <= nRandomNpcSubGroupCount and k >= 1, "PVE02Battle2GameStep ParseNpcsJsonData failed. RandomNpcJson configurated error. SubGroup discontinuous. Reason 1")
    end
    assert(nValidCount == nRandomNpcSubGroupCount, "PVE02Battle2GameStep ParseNpcsJsonData failed. RandomNpcJson configurated error. SubGroup discontinuous. Reason 2")
    -- Validate end

    self.nSubGroupCount = nRandomNpcSubGroupCount

    local nEliteNpcSubGroupCount = 0
    self.nEliteNpcCount = 0
    for _, tbNpcJsonData in pairs(tbNpcJsonTableFile) do
        if tbNpcJsonData.GroupIndex == 2 then
            if tbOrdinaryMobIds[tbNpcJsonData.SpawnerId] == nil then
                if self.tbEliteMobJsonDatas[tbNpcJsonData.SubGroupIndex] == nil then
                    self.tbEliteMobJsonDatas[tbNpcJsonData.SubGroupIndex] = {}
                    nEliteNpcSubGroupCount = nEliteNpcSubGroupCount + 1
                end
                table.insert(self.tbEliteMobJsonDatas[tbNpcJsonData.SubGroupIndex], tbNpcJsonData)

                self.nEliteNpcCount = self.nEliteNpcCount + 1
            end

            assert(tbNpcJsonData.CampType == CampDef.Type.CAMP_1, "PVE02 step2 - Ememy camp not CAMP_1")
        end
    end

    -- Validate begin
    nValidCount = 0
    for k, v in pairs(self.tbEliteMobJsonDatas) do
        nValidCount = nValidCount + 1
        assert(k <= nEliteNpcSubGroupCount and k >= 1, "PVE02Battle2GameStep ParseNpcsJsonData failed. EliteNpcJson configurated error. SubGroup discontinuous. Reason 1")
    end
    assert(nValidCount == nEliteNpcSubGroupCount, "PVE02Battle2GameStep ParseNpcsJsonData failed. EliteNpcJson configurated error. SubGroup discontinuous. Reason 2")
    assert(nEliteNpcSubGroupCount == self.nSubGroupCount, "PVE02Battle2GameStep ParseNpcsJsonData failed. EliteNpcSubGroupCount not equals to RandomNpcSubGroupCount", nEliteNpcSubGroupCount, self.nSubGroupCount)
    -- Validate end

    ParseTriggerJsonTable(self, tbJsonTriggers)

    log("PVE02Battle2GameStep has", self.nSubGroupCount, "sub groups.")
end

local function SpawnTriggers(self)
    log("PVE02Battle2GameStep Spawn triggers.")
    for _, tbTrigger in pairs(self.tbTriggers) do
        local tbData = {tbJsonData = tbTrigger}
        GameObjectSystem:CreateTriggerInGameMode(tbData)
    end
end

-- 激活第nSubGroupIndex组怪，由Trigger触发
local function ActivateSubGroup(self, nSubGroupIndex)
    log("PVE02Battle2GameStep Sub Group", nSubGroupIndex, "started.")
    local tbEliteMobs = self.tbEliteMobJsonDatas[nSubGroupIndex]
    assert(tbEliteMobs ~= nil, "PVE02Battle2GameStep activateSubGroup", nSubGroupIndex, "failed. No group elite mobs data found.")

    assert(self.tbRuntimeSubGroupData[nSubGroupIndex] == nil, "PVE02Battle2GameStep ActivateSubGroup failed. Activate multiple times. SubGroupIndex: ", nSubGroupIndex)
    self.tbRuntimeSubGroupData[nSubGroupIndex] = {}
    self.tbRuntimeSubGroupData[nSubGroupIndex].tbEliteMobs = {}
    for _,v in ipairs(tbEliteMobs) do
        local tbEliteMob = SpawnerSystem:SpawnById(v.SpawnerId)
        assert(tbEliteMob)
        table.insert(self.tbRuntimeSubGroupData[nSubGroupIndex].tbEliteMobs, tbEliteMob)
        self.EliteMobsDieTarget:AddTargetPawn(tbEliteMob)
    end

    local nEliteMobCount = #self.tbRuntimeSubGroupData[nSubGroupIndex].tbEliteMobs
    log("Refresh", nEliteMobCount, "elite mobs in sub group", nSubGroupIndex)
    if nEliteMobCount > 0 then
        local fnCallback = function()
            self:CreateOrdinaryMobs(nSubGroupIndex)
        end
        local OrdinaryMobsTimer = Timer.NewTimer(fnCallback, self.nMobRefreshInterval, true)
        self.tbRuntimeSubGroupData[nSubGroupIndex].Timer = OrdinaryMobsTimer
        -- self:CreateOrdinaryMobs(nSubGroupIndex) -- for first time call immediately
        
        self:RemoveNonCombatStatus()
    end
end

function PVE02Battle2GameStep:CreateOrdinaryMobs(nSubGroupIndex)
    local nCountLimit = self.nOrdinaryMobCountLimit - #self.tbOrdinaryNpcs
    local nRefreshCount = math.min(nCountLimit, self.nOrdinaryMobRefreshCount)
    log("PVE02Battle2GameStep:CreateOrdinaryMobs subgroup:", nSubGroupIndex)
    local tbRandomJsonData = self.tbOrdinaryMobJsonDatas[nSubGroupIndex]
    assert(tbRandomJsonData ~= nil, "PVE02Battle2GameStep:CreateOrdinaryMobs failed. Random json data not found. SubGroup:", nSubGroupIndex)
    local tbRandomSpawner = SpawnerSystem:FindById(tbRandomJsonData.SpawnerId)
    assert(tbRandomSpawner ~= nil)

    tbRandomSpawner.nRandomMinCount = nRefreshCount
    tbRandomSpawner.nRandomMaxCount = nRefreshCount
    local tbCreatedOrdinaryMobs = SpawnerSystem:Spawn(tbRandomSpawner)
    log("PVE02Battle2GameStep:CreateOrdinaryMobs create", #tbCreatedOrdinaryMobs, "ordinary mobs. SubGroup", nSubGroupIndex)
    Append(self.tbOrdinaryNpcs, tbCreatedOrdinaryMobs)
    for _,v in ipairs(tbCreatedOrdinaryMobs) do
        assert(v ~= nil, "PVE02Battle2GameStep:CreateOrdinaryMobs SpawnerSystem spawn random spawner failed. Return nil element. SubGroup:", nSubGroupIndex, "Input refresh count:", nRefreshCount, "Output refresh count:", #tbCreatedOrdinaryMobs)
        self.OrdinaryMobsDieTarget:AddTargetPawn(v)
    end

    if #tbCreatedOrdinaryMobs > 0 then
        -- 大怪头顶气泡
        for _, tbEliteMob in ipairs(self.tbRuntimeSubGroupData[nSubGroupIndex].tbEliteMobs) do
            BattleInteractionHelper:ShowHeadDialog(tbEliteMob, self.nSummonDialogId)
        end
    end
end

-- 停止第nSubGroupIndex组怪，由 Pawn Dead Event 触发
local function DeactivateSubGroup(self, nSubGroupIndex)
    log("PVE02Battle2GameStep SubGroup", nSubGroupIndex, "deactivated.")
    assert(self.tbRuntimeSubGroupData[nSubGroupIndex] ~= nil, "PVE02Battle2GameStep DeactivateSubGroup failed. SubGroup", nSubGroupIndex, "hasn't been activated.")
    if self.tbRuntimeSubGroupData[nSubGroupIndex].Timer ~= nil then
        self.tbRuntimeSubGroupData[nSubGroupIndex].Timer:Clear()
    end
    self.tbRuntimeSubGroupData[nSubGroupIndex] = nil
end

function PVE02Battle2GameStep:OnPawnDead(tbDeadObject)
    for nSubGroupIndex,v in pairs(self.tbRuntimeSubGroupData) do
        for i,tbEliteMob in ipairs(v.tbEliteMobs) do
            if tbDeadObject == tbEliteMob then
                table.remove(v.tbEliteMobs, i)
                log("PVE02Battle2GameStep:OnPawnDead remove one elite from subgroup", nSubGroupIndex)
                if #v.tbEliteMobs == 0 then
                    DeactivateSubGroup(self, nSubGroupIndex)
                    self:CheckAndAddNonCombatStatus()
                end
                return
            end
        end
    end
    for i,v in ipairs(self.tbOrdinaryNpcs) do
        if v == tbDeadObject then
            log("PVE02Battle2GameStep:OnPawnDead one ordinary mob died.")
            table.remove(self.tbOrdinaryNpcs, i)
            self:CheckAndAddNonCombatStatus()
            return
        end
    end
end

function PVE02Battle2GameStep:OnActorEnterArea(tbGameTrigger, tbGameObject)
    log("PVE02Battle2GameStep:OnActorEnterArea")
    local nTriggerId = tbGameTrigger.nTriggerId
    local nGroupIndex = tbGameTrigger.nGroupIndex
    if nGroupIndex ~= 2 or self.tbTriggerActivated[nTriggerId] == true then
        return
    end

    if tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        -- Player touches triggers
        self.tbTriggerActivated[nTriggerId] = true
        ActivateSubGroup(self, self.tbTriggers[nTriggerId].SubGroupIndex)
    end
end

function PVE02Battle2GameStep:Init()
    PVE02Battle2GameStep.super.Init(self)
    self.EliteMobsDieTarget = self:CreateTarget(BattleRuntimePawnDeadTargetClass)
    self.OrdinaryMobsDieTarget = self:CreateTarget(BattleRuntimePawnDeadTargetClass)
end

function PVE02Battle2GameStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)
    PVE02Battle2GameStep.super.SetParams(self, tbGameState, tbTemplateData, tbJsonTableFile)
    self.tbTemplateData = tbTemplateData
    ParseTemplateData(self)
    ParseNpcsJsonData(self, tbJsonTableFile.tbContainer.DungeonNPCSpawners, tbJsonTableFile.tbContainer.DungeonRandomNPCSpawners, tbJsonTableFile.tbContainer.Triggers)
    self.tbDummiesJson = self:ParseDummiesJsonData(tbJsonTableFile.tbContainer.DungeonDummySpawners, 2)

    self.tbOrdinaryNpcs = {}
    self.tbRuntimeSubGroupData = {}

    self.EliteMobsDieTarget:SetParams(self.nEliteNpcCount)
    self.EliteMobsDieTarget:SetCanComplete(true)

    SpawnTriggers(self)
end

-- 同步Step信息
function PVE02Battle2GameStep:RepStepInfo(bRepNow)
    PVE02Battle2GameStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function PVE02Battle2GameStep:SnapshotToReplicatedProperty()
    return true
end

-- 当Target结束时候会调用这个函数
-- return true  该step完成
-- return false 该step没完成
function PVE02Battle2GameStep:CheckComplete(BattleTarget)
    if BattleTarget == self.EliteMobsDieTarget then
        self.OrdinaryMobsDieTarget:SetCanComplete(true)

        -- EliteMobsDieTarget should always happen prior to OrdinaryMobsDieTarget
        -- Return false and wait for OrdinaryMobsDieTarget done
        return false
    end
    return true
end

function PVE02Battle2GameStep:Start()
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_ENTER, self, self.OnActorEnterArea)

    self.tbDummies = self:SpawnDummies(self.tbDummiesJson)

    self:ShowDialog(self.nDialog)
    BattleObjectiveHelper:ObjectiveStepForward()
    
    PVE02Battle2GameStep.super.Start(self)

    self:AddNonCombatStatus()

    BattleTargetTrackHelper:SetTargetTrackVisible(nil, true)
end

function PVE02Battle2GameStep:Complete()
    self:DestoryDummies(self.tbDummies)
    D2CHelper:MulticastStopMove()

    self:RemoveNonCombatStatus()
    BattleTargetTrackHelper:SetTargetTrackVisible(nil, false)
    PVE02Battle2GameStep.super.Complete(self)
end

-- 将结果写入到GameState数据面板里
function PVE02Battle2GameStep:CalculateResult()
    
end

function PVE02Battle2GameStep:Restart()
    log("PVE02Battle2GameStep restart")
    if not self:IsStarted() then
        log("PVE02Battle2GameStep skip restart. Step hasn't been started.")
        return 
    end

------------------Reset-----------------------------------
    assert(self.EliteMobsDieTarget ~= nil)
    assert(self.OrdinaryMobsDieTarget ~= nil)

    -- reset target
    self.EliteMobsDieTarget:UnregisterEvent()
    self.OrdinaryMobsDieTarget:UnregisterEvent()

    self.EliteMobsDieTarget:Reset()
    self.OrdinaryMobsDieTarget:Reset()
    self.EliteMobsDieTarget:SetParams(self.nEliteNpcCount)
    self.EliteMobsDieTarget:SetCanComplete(true)

    -- kill elite mobs
    for i=1, self.nSubGroupCount do
        local tbSubGroupData = self.tbRuntimeSubGroupData[i]
        if tbSubGroupData ~= nil then
            local tbEliteMobs = tbSubGroupData.tbEliteMobs
            if tbEliteMobs ~= nil then
                for _, v in ipairs(tbEliteMobs) do
                    GameObjectSystem:DestroyByUniqueId(v:GetUEActorUniqueId())
                end
            end
            DeactivateSubGroup(self, i)
        end
    end

    -- kill ordinary mobs
    local tbOrdinaryNpcs = self.tbOrdinaryNpcs
    if tbOrdinaryNpcs ~= nil then
        for _, tbOrdinaryNpc in ipairs(tbOrdinaryNpcs) do 
            GameObjectSystem:DestroyByUniqueId(tbOrdinaryNpc:GetUEActorUniqueId())
        end
    end
    self.tbOrdinaryNpcs = {}

    -- reset trigger
    self.tbTriggerActivated = {}

    -- destroy dummies
    self:DestoryDummies(self.tbDummies)

------------------Start-----------------------------------
    self.tbDummies = self:SpawnDummies(self.tbDummiesJson)

    self.EliteMobsDieTarget:RegisterEvent()
    self.OrdinaryMobsDieTarget:RegisterEvent()

    self:AddNonCombatStatus()
end

function PVE02Battle2GameStep:CheckAndAddNonCombatStatus()
    if not self:IsCompleted() then
        if #self.tbOrdinaryNpcs > 0 then
            -- ordinary npc alive
            return
        end
        for i=1, self.nSubGroupCount do
            local tbSubGroupData = self.tbRuntimeSubGroupData[i]
            if tbSubGroupData ~= nil then
                -- sub group active
                return
            end
        end
    end
    self:AddNonCombatStatus()
end

function PVE02Battle2GameStep:AddNonCombatStatus()
    local nBattle2NonCombatStatusId = self.nBattle2NonCombatStatusId
    local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbGameObject, _ in pairs(tbGameObjects) do
        if not tbGameObject:IsDead() then
            tbGameObject.BuffComponentServer:AddBuffById(nBattle2NonCombatStatusId)
        end
    end
end

function PVE02Battle2GameStep:RemoveNonCombatStatus()
    local nBattle2NonCombatStatusId = self.nBattle2NonCombatStatusId
    local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbGameObject, _ in pairs(tbGameObjects) do
        if not tbGameObject:IsDead() then
            tbGameObject.BuffComponentServer:RemoveBuffById(nBattle2NonCombatStatusId)
        end
    end
end

function PVE02Battle2GameStep:Uninit()
    PVE02Battle2GameStep.super.Uninit(self)
    local nSubGroupCount = self.nSubGroupCount
    if self.nSubGroupCount then
        for i=1, nSubGroupCount do
            if self.tbRuntimeSubGroupData and self.tbRuntimeSubGroupData[i] then
                DeactivateSubGroup(self, i)
            end
        end
    end
end

return PVE02Battle2GameStep
