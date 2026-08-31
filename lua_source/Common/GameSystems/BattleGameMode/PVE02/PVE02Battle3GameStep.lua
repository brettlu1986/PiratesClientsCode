-- PVE02 第一场战斗

local luaclass = require("luaclass")
local PVE02BattleGameStepBaseClass = require("PVE02BattleGameStepBase")
local PVE02Battle3GameStep = luaclass("PVE02Battle3GameStep", PVE02BattleGameStepBaseClass)

local BattleRuntimePawnDeadTargetClass = require("BattleRuntimePawnDeadTarget")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SpawnerSystem = require("SpawnerSystem")
local CampDef = require("CampDefine")

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleObjectiveHelper = require("BattleObjectiveHelper")
local BattleResultDef = require("BattleResultDef")

local PLAYER_WIN = BattleResultDef.WIN
-- local PLAYER_LOSE = BattleResultDef.LOSE

PVE02Battle3GameStep.tbJsonDataBoss = nil -- SpawnerJsonData
PVE02Battle3GameStep.tbJsonDataRandomOrdinaryMobs = nil -- Random spawner json data array. {RandomSpawnerJsonData1, RandomSpawnerJsonData2...}

PVE02Battle3GameStep.tbBoss = nil -- 章鱼怪

PVE02Battle3GameStep.BossDieTarget = nil
PVE02Battle3GameStep.tbResults = nil

PVE02Battle3GameStep.nDialog = nil

-- Fill tb2 elements to tb1
local function Fill(tb1, tb2)
    for i=1,#tb2 do
        tb1[tb2[i]] = true
    end
    return tb1
end

-- 解析 template data
local function ParseTemplateData(self, tbTemplateData)
    if tbTemplateData == nil then
        logerror('PVE02Battle3GameStep ParseTemplateData() tbTemplateData is nil')
        return
    end
    self.nDialog = tbTemplateData.nDialog3
end

-- 解析 npc json data
local function ParseNpcsJsonData(self, tbNpcJsonTableFile, tbRandomNpcJsonTableFile)
    if tbNpcJsonTableFile == nil then
        logerror('PVE02Battle3GameStep ParseNpcsJsonData() tbNpcJsonTableFile is nil')
        return
    end

    self.tbJsonDataRandomOrdinaryMobs = {}
    local tbOrdinaryMobIds = {}
    for _,v in ipairs(tbRandomNpcJsonTableFile) do
        if v.GroupIndex == 3 then
            table.insert(self.tbJsonDataRandomOrdinaryMobs, v)
            Fill(tbOrdinaryMobIds, v.SpawnerIds)
        end
    end
    log("PVE02Battle3GameStep ParseNpcsJsonData", #self.tbJsonDataRandomOrdinaryMobs, "groups to random ordinary mobs.")

    for _,v in ipairs(tbNpcJsonTableFile) do
        if v.GroupIndex == 3 then
            if tbOrdinaryMobIds[v.SpawnerId] == nil then
                assert(self.tbJsonDataBoss == nil, "PVE02Battle3GameStep more than one boss in battle 3.")
                self.tbJsonDataBoss = v
                assert(v.CampType == CampDef.Type.CAMP_1, "PVE02 step3 - Boss camp not CAMP_1")
            else
                assert(v.CampType == CampDef.Type.CAMP_1, "PVE02 step3 - Ordinary camp not CAMP_1")
            end
        end
    end
end

-- 生成章鱼怪Boss
local function SpawnBoss(self)
    log("PVE02Battle3GameStep spawn boss")
    assert(self.tbJsonDataBoss ~= nil, "PVE02Battle3GameStep Spawn boss failed. No boss data.")

    local tbBoss = SpawnerSystem:SpawnById(self.tbJsonDataBoss.SpawnerId)
    assert(tbBoss)
    self.BossDieTarget:AddTargetPawn(tbBoss)
    self.BossDieTarget:SetCanComplete(true)
    self.tbBoss = tbBoss
end

function PVE02Battle3GameStep:SpawnPawn(nSpawnerId)
    if self.tbJsonDataBoss ~= nil and nSpawnerId == self.tbJsonDataBoss.SpawnerId then
        SpawnBoss(self)
    else
        -- validate
        local bValid = false
        for _,v in ipairs(self.tbJsonDataRandomOrdinaryMobs) do
            if v.SpawnerId == nSpawnerId then
                bValid = true
                break
            end
        end
        if not bValid then
            logerror("PVE02Battle3GameStep:SpawnPawn failed. Should not use spawner id", nSpawnerId)
            return
        end

        SpawnerSystem:SpawnById(nSpawnerId)
    end
end

function PVE02Battle3GameStep:Init()
    PVE02Battle3GameStep.super.Init(self)
    self.BossDieTarget = self:CreateTarget(BattleRuntimePawnDeadTargetClass)
end

function PVE02Battle3GameStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)
    PVE02Battle3GameStep.super.SetParams(self, tbGameState, tbTemplateData, tbJsonTableFile)
    self.tbTemplateData = tbTemplateData
    tbGameState.rBattlePlayerResultStep.Results = {}
    self.tbResults = tbGameState.rBattlePlayerResultStep.Results
    ParseTemplateData(self, tbTemplateData)
    ParseNpcsJsonData(self, tbJsonTableFile.tbContainer.DungeonNPCSpawners, tbJsonTableFile.tbContainer.DungeonRandomNPCSpawners)
end

-- 同步Step信息
function PVE02Battle3GameStep:RepStepInfo(bRepNow)
    PVE02Battle3GameStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function PVE02Battle3GameStep:SnapshotToReplicatedProperty()

    return true
end

-- 当Target结束时候会调用这个函数
-- return true  该step完成
-- return false 该step没完成
function PVE02Battle3GameStep:CheckComplete(BattleTarget)
    return true
end

function PVE02Battle3GameStep:Start()
    SpawnBoss(self)
    self:ShowDialog(self.nDialog)
    BattleObjectiveHelper:ObjectiveStepForward()

    -- Teleport players to PlayerStarts in this battle step.
    local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbGameObject, _ in pairs(tbGameObjects) do
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_RESET_PLAYER_POSITION, tbGameObject)
    end

    PVE02Battle3GameStep.super.Start(self)
end

function PVE02Battle3GameStep:Complete()
    self.tbBoss = nil

    local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    local tbResults  = self.tbResults
    for tbGameObject, _ in pairs(tbGameObjects) do
        local tbResult = {}
        tbResult.nPlayerId = tbGameObject.nPlayerId
        tbResult.nResult = PLAYER_WIN
        table.insert(tbResults, tbResult)
    end

    PVE02Battle3GameStep.super.Complete(self)
end

-- 将结果写入到GameState数据面板里
function PVE02Battle3GameStep:CalculateResult()
    
end

function PVE02Battle3GameStep:Restart()
    log("PVE02Battle3GameStep restart")
    if not self:IsStarted() then
        log("PVE02Battle3GameStep skip restart. Step hasn't been started.")
        return 
    end

------------------Reset-----------------------------------
    assert(self.BossDieTarget ~= nil)
    self.BossDieTarget:UnregisterEvent()
    self.BossDieTarget:Reset()

    if self.tbBoss ~= nil then
        GameObjectSystem:DestroyByUniqueId(self.tbBoss:GetUEActorUniqueId())
    end
------------------Start-----------------------------------
    -- spawn boss
    SpawnBoss(self)
    
    self.BossDieTarget:RegisterEvent()
end

return PVE02Battle3GameStep
