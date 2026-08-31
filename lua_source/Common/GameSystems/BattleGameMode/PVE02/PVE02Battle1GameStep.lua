-- PVE02 第一场战斗

local luaclass = require("luaclass")
local PVE02BattleGameStepBaseClass = require("PVE02BattleGameStepBase")
local PVE02Battle1GameStep = luaclass("PVE02Battle1GameStep", PVE02BattleGameStepBaseClass)

local BattleGroupDeadTargetClass = require("BattleNpcGroupDeadTarget")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local SpawnerSystem = require("SpawnerSystem")
local CampDef = require("CampDefine")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleObjectiveHelper = require("BattleObjectiveHelper")

-- 怪生成规则：不在 RandomSpawner 中的独立 Spawner 全部视为需要单独 Spawn 的怪，对应文档中的两个大炮台
-- 其余配置在 RandomSpawner 中的 Spawner 按照 RandomSpawner 规则生成

PVE02Battle1GameStep.tbSpawnerIds = nil -- 不存在于 RandomSpawner 中的 SpawnerId 集合
PVE02Battle1GameStep.tbRandomSpawnerIds = nil -- RandomSpawner Id 集合

PVE02Battle1GameStep.tbDummiesJson = nil -- 第一关和第二关之间阻挡的导出数据
PVE02Battle1GameStep.tbDummies = nil -- 第一关和第二关间阻挡对象数组

PVE02Battle1GameStep.AllNpcDeadTarget = nil
PVE02Battle1GameStep.tbEnemies = nil -- 第一关活着的Npc，目前用于restart过程中销毁残存的Npc

PVE02Battle1GameStep.nDialog = nil

-- Utility functions
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
local function ParseTemplateData(self, tbTemplateData)
    if tbTemplateData == nil then
        logerror('PVE02Battle1GameStep ParseTemplateData() tbTemplateData is nil')
        return
    end

    self.nDialog = tbTemplateData.nDialog1
end

-- 解析 npc json data
local function ParseNpcsJsonData(self, tbNpcJsonTableFile, tbRandomNpcJsonTableFile)
    if tbNpcJsonTableFile == nil or tbRandomNpcJsonTableFile == nil then
        logerror('PVE02Battle1GameStep ParseNpcsJsonData() failed. tbNpcJsonTableFile', tbNpcJsonTableFile, "; tbRandomNpcJsonTableFile", tbRandomNpcJsonTableFile)
        return
    end

    -- validate camp data begin
    for _, tbSpawner in ipairs(tbNpcJsonTableFile) do
        if tbSpawner.GroupIndex == 1 and tbSpawner.CampType ~= CampDef.Type.CAMP_1 then
            logerror('PVE02Battle1GameStep ParseNpcsJsonData() failed. CampDef error. Should be CAMP_1')
            return
        end
    end
    -- validate camp data end

    self.tbSpawnerIds = {}
    self.tbRandomSpawnerIds = {}

    local tbSpawnerInRandomIds = {} -- 配置在 Random Spawner 中的 Spawner Id 集合
    for _, tbRandomSpawner in ipairs(tbRandomNpcJsonTableFile) do
        if tbRandomSpawner.GroupIndex == 1 then
            table.insert(self.tbRandomSpawnerIds, tbRandomSpawner.SpawnerId)
            Fill(tbSpawnerInRandomIds, tbRandomSpawner.SpawnerIds)
        end
    end

    for _, tbSpawner in ipairs(tbNpcJsonTableFile) do
        if tbSpawner.GroupIndex == 1 and tbSpawnerInRandomIds[tbSpawner.SpawnerId] == nil then
            table.insert(self.tbSpawnerIds, tbSpawner.SpawnerId)
        end
    end
    log("PVE02Battle1GameStep", #self.tbRandomSpawnerIds, " random groups.", #self.tbSpawnerIds, "spawners.")
end

-- 生成怪物
local function SpawnEnemies(self)
    self.tbEnemies = {}
    for _, nId in ipairs(self.tbSpawnerIds) do
        local tbObj = SpawnerSystem:SpawnById(nId, false)
        if tbObj ~= nil then    
            table.insert(self.tbEnemies, tbObj)
        end
    end

    for _, nId in ipairs(self.tbRandomSpawnerIds) do
        local tbObjs = SpawnerSystem:SpawnById(nId, false)
        if tbObjs ~= nil then    
            Append(self.tbEnemies, tbObjs)
        end
    end

    self.AllNpcDeadTarget:AddGroupInfo(1, CampDef.Type.CAMP_1, #self.tbEnemies)
end

function PVE02Battle1GameStep:OnPawnDead(tbDeadActor)
    local tbEnemies = self.tbEnemies
    if tbEnemies ~= nil then
        for i, v in ipairs(tbEnemies) do
            if v == tbDeadActor then
                table.remove(tbEnemies, i)
                return
            end 
        end
    end
end

function PVE02Battle1GameStep:Init()
    PVE02Battle1GameStep.super.Init(self)

    self.AllNpcDeadTarget = self:CreateTarget(BattleGroupDeadTargetClass)
end

function PVE02Battle1GameStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)
    PVE02Battle1GameStep.super.SetParams(self, tbGameState, tbTemplateData, tbJsonTableFile)
    self.tbTemplateData = tbTemplateData
    ParseTemplateData(self, tbTemplateData)
    ParseNpcsJsonData(self, tbJsonTableFile.tbContainer.DungeonNPCSpawners, tbJsonTableFile.tbContainer.DungeonRandomNPCSpawners)
    self.tbDummiesJson = self:ParseDummiesJsonData(tbJsonTableFile.tbContainer.DungeonDummySpawners, 1)
end

-- 同步Step信息
function PVE02Battle1GameStep:RepStepInfo(bRepNow)
    PVE02Battle1GameStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function PVE02Battle1GameStep:SnapshotToReplicatedProperty()

    return true
end

-- 当Target结束时候会调用这个函数
-- return true  该step完成
-- return false 该step没完成
function PVE02Battle1GameStep:CheckComplete(BattleTarget)
    return true
end

function PVE02Battle1GameStep:Start()
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)

    SpawnEnemies(self)
    self.tbDummies = self:SpawnDummies(self.tbDummiesJson)

    self:ShowDialog(self.nDialog)
    BattleObjectiveHelper:ObjectiveStepForward()

    PVE02Battle1GameStep.super.Start(self)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_TEAM_BOT_START)
end

function PVE02Battle1GameStep:Complete()
    self:DestoryDummies(self.tbDummies)
    PVE02Battle1GameStep.super.Complete(self)
end

-- 将结果写入到GameState数据面板里
function PVE02Battle1GameStep:CalculateResult()
    
end

function PVE02Battle1GameStep:Restart()
    log("PVE02Battle1GameStep restart")
    if not self:IsStarted() then
        log("PVE02Battle1GameStep skip restart. Step hasn't been started.")
        return 
    end

------------------Reset-----------------------------------
    assert(self.AllNpcDeadTarget ~= nil)
    self.AllNpcDeadTarget:UnregisterEvent()
    self.AllNpcDeadTarget.nCurrentDeadCount = 0
    
    self:DestoryDummies(self.tbDummies)

    -- kill all enemies in current step
    for _, v in ipairs(self.tbEnemies) do
        GameObjectSystem:DestroyByUniqueId(v:GetUEActorUniqueId())
    end
    self.tbEnemies = {}

------------------Start-----------------------------------
    -- spawn enemies
    SpawnEnemies(self)

    self.tbDummies = self:SpawnDummies(self.tbDummiesJson)
    
    self.AllNpcDeadTarget:RegisterEvent()
end

function PVE02Battle1GameStep:Uninit()
    PVE02Battle1GameStep.super.Uninit(self)
end

function PVE02Battle1GameStep:OnPlayerLogin(tbGamePlayer)
    PVE02Battle1GameStep.super.OnPlayerLogin(self, tbGamePlayer)
    BattleInteractionHelper:PlayerShowDialog(tbGamePlayer, self.nDialog)
end

return PVE02Battle1GameStep
