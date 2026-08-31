-- 押运战斗

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local EscortGameStep = luaclass("EscortGameStep", BattleStepBaseClass)

local BaseUtil = require("BaseUtil")
local Proto = require("DungeonRepProtoNames")
local SpawnerSystem = require("SpawnerSystem")
local CampDef = require("CampDefine")
local GroupDeadTargetClass = require("BattleNpcGroupDeadTarget")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SinglePlayerDeadTargetClass = require("BattleSinglePlayerDeadTarget")
local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleObjectiveHelper = require("BattleObjectiveHelper")

local StringUtil = require("StringUtil")
local BattleResultDef = require("BattleResultDef")

local nBossCount = 1
local nOrdinaryMobCount = 3

EscortGameStep.tbBossIds = nil
EscortGameStep.tbOrdinaryMobIds = nil

EscortGameStep.tbNpcJsonData = nil

EscortGameStep.NpcGroupDeadTarget  = nil
EscortGameStep.SinglePlayerDeadTarget = nil

EscortGameStep.rFightResult = nil
EscortGameStep.rBattlePlayerResultStepForShow = nil

EscortGameStep.nDialogId = nil

local function IsInArray(tbArray, nElement)
    for _,v in ipairs(tbArray) do
        if v == nElement then
            return true
        end
    end
    return false
end

local function RandomElements(nCount, tbArray, tbExcludeIndexes)
    local tbRet = {}
    local tbScope = {}
    for i,v in ipairs(tbArray) do
        if not IsInArray(tbExcludeIndexes, i) then
            local tbElement = {}
            tbElement.nValue = v
            tbElement.nIndex = i
            tbScope[#tbScope + 1] = tbElement
        end
    end
    log(nCount)
    BaseUtil:PrintTable(tbArray)
    BaseUtil:PrintTable(tbExcludeIndexes)

    for i=1, nCount do
        BaseUtil:PrintTable(tbScope)
        assert(#tbScope > 0)
        local nRandomIndex = math.random(1, #tbScope)
        local tbRandomElement = tbScope[nRandomIndex]
        tbRet[#tbRet + 1] = tbRandomElement.nValue
        tbExcludeIndexes[#tbExcludeIndexes + 1] = tbRandomElement.nIndex
        table.remove(tbScope,nRandomIndex)
    end
    return tbRet
end

-- 解析 template data
local function ParseTemplateData(self, tbTemplateData)
    if tbTemplateData == nil then
        logerror('EscortGameStep ParseTemplateData() tbTemplateData is nil')
        return
    end

    self.tbBossIds = {}
    local tbSzBossIds = StringUtil.Split(tbTemplateData.szBossIds, ",")
    for _,szId in ipairs(tbSzBossIds) do
        self.tbBossIds[#self.tbBossIds + 1] = tonumber(szId)
    end

    self.tbOrdinaryMobIds = {}
    local tbSzOrdinaryMobIds = StringUtil.Split(tbTemplateData.szOrdinaryMobIds, ",")
    for _,szId in ipairs(tbSzOrdinaryMobIds) do
        self.tbOrdinaryMobIds[#self.tbOrdinaryMobIds + 1] = tonumber(szId)
    end

    self.nDialogId = tbTemplateData.nDialogId

    log("Escort boss will generated in", #self.tbBossIds, "types.")
    log("Escort ordinary mobs will generated in", #self.tbOrdinaryMobIds, "types.")
end

-- 解析 npc json data
local function ParseNpcsJsonData(self, tbNpcJsonTableFile)
    if tbNpcJsonTableFile == nil then
        logerror('EscortGameStep ParseNpcsJsonData() tbNpcJsonTableFile is nil')
        return
    end

    self.tbNpcJsonData = tbNpcJsonTableFile
    for _,tbNpcJson in ipairs(tbNpcJsonTableFile) do
        assert(tbNpcJson.CampType == CampDef.Type.CAMP_1, "Escort npc CampType not set to CAMP_1")
        assert(tbNpcJson.GroupIndex == 1, "Escort npc GroupIndex not set to 1")
    end
    assert(#self.tbNpcJsonData >= nBossCount + nOrdinaryMobCount, "Escort npc json count less than boss count + ordinary mob count")
end

local function SpawnNpcs(self)
    local tbSpawners = SpawnerSystem:GetAllSpawners()
    assert(nBossCount + nOrdinaryMobCount <= #tbSpawners)

    

    local nSpawnerIndex = 1

    -- spawn boss
    local tbExcludeIndexes = {}
    local tbBossIds = RandomElements(nBossCount, self.tbBossIds, tbExcludeIndexes)
    log("Escort random boss id:", BaseUtil:ConvertTableToJsonString(tbBossIds))
    for i,nBossTemplateId in ipairs(tbBossIds) do
        local tbSpawner = tbSpawners[nSpawnerIndex]
        tbSpawner.nTemplateId = nBossTemplateId
        SpawnerSystem:Spawn(tbSpawner)
        nSpawnerIndex = nSpawnerIndex + 1
    end

    -- spawn ordinary mobs
    local tbOrdinaryMobIds = RandomElements(nOrdinaryMobCount, self.tbOrdinaryMobIds, tbExcludeIndexes)
    log("Escort random ordinary mob ids:", BaseUtil:ConvertTableToJsonString(tbOrdinaryMobIds))
    for i,nOrdinaryMobId in ipairs(tbOrdinaryMobIds) do
        local tbSpawner = tbSpawners[nSpawnerIndex]
        tbSpawner.nTemplateId = nOrdinaryMobId
        SpawnerSystem:Spawn(tbSpawner)
        nSpawnerIndex = nSpawnerIndex + 1
    end
end

function EscortGameStep:Init()
    EscortGameStep.super.Init(self)
    self.NpcGroupDeadTarget = self:CreateTarget(GroupDeadTargetClass)
    self.SinglePlayerDeadTarget = self:CreateTarget(SinglePlayerDeadTargetClass)
end

function EscortGameStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)
    self.rFightResult = tbGameState.rEscortFightResult
    self.rBattlePlayerResultStepForShow = tbGameState.rBattlePlayerResultStep

    self.tbTemplateData = tbTemplateData
    ParseTemplateData(self, tbTemplateData)
    ParseNpcsJsonData(self, tbJsonTableFile.tbContainer.DungeonNPCSpawners)
end

-- 同步Step信息
function EscortGameStep:RepStepInfo(bRepNow)
    EscortGameStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function EscortGameStep:SnapshotToReplicatedProperty()

    return true
end

-- 当Target结束时候会调用这个函数
-- return true  该step完成
-- return false 该step没完成
function EscortGameStep:CheckComplete(BattleTarget)

    -- FOR DISPLAY IN LAST STEP - SHOW RESULT
    local rResult = self.rBattlePlayerResultStepForShow
    rResult.Results = {}
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nPlayerId = PlayerSelf.nPlayerId
    local tbResult = {}
    tbResult.nPlayerId = nPlayerId
    table.insert(rResult.Results, tbResult)

    if BattleTarget == self.NpcGroupDeadTarget then
        self.rFightResult.nFightResult = BattleResultDef.WIN
        tbResult.nResult = Proto.PlayerWinLoseResult_ResultType.WIN
    elseif BattleTarget == self.SinglePlayerDeadTarget then
        self.rFightResult.nFightResult = BattleResultDef.LOSE
        tbResult.nResult = Proto.PlayerWinLoseResult_ResultType.LOSE
    end

    return true
end

function EscortGameStep:Start()
    SpawnNpcs(self)
    self.NpcGroupDeadTarget:AddGroupInfo(1, CampDef.Type.CAMP_1, nBossCount + nOrdinaryMobCount)

    BattleInteractionHelper:ShowDialog(self.nDialogId)
    BattleObjectiveHelper:ObjectiveStepForward()

    EscortGameStep.super.Start(self)
end

function EscortGameStep:Complete()
    EscortGameStep.super.Complete(self)
end

-- 将结果写入到GameState数据面板里
function EscortGameStep:CalculateResult()
    
end

return EscortGameStep
