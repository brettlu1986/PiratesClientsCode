-- 押运战斗

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local SideQuest01GameStep = luaclass("SideQuest01GameStep", BattleStepBaseClass)

local SpawnerSystem = require("SpawnerSystem")
local CampDef = require("CampDefine")
local GroupDeadTargetClass = require("BattleNpcGroupDeadTarget")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SinglePlayerDeadTargetClass = require("BattleSinglePlayerDeadTarget")
local BattleResultDef = require("BattleResultDef")
local SpawnerDef = require("SpawnerDef")

SideQuest01GameStep.NpcGroupDeadTarget  = nil
SideQuest01GameStep.SinglePlayerDeadTarget = nil

SideQuest01GameStep.rBattlePlayerResultStepForShow = nil

SideQuest01GameStep.tbGameState = nil

SideQuest01GameStep.nNpcCount = nil

-- 解析 npc json data
local function ParseNpcsJsonData(self, tbNpcJsonTableFile)
    if tbNpcJsonTableFile == nil then
        logerror('SideQuest01GameStep ParseNpcsJsonData() tbNpcJsonTableFile is nil')
        return
    end

    self.nNpcCount = 0
    for _,tbNpcJson in ipairs(tbNpcJsonTableFile) do
        assert(tbNpcJson.GroupIndex == 0, "SideQuest01 npc GroupIndex not set to 0")

        -- 可能会有己方npc，所以这里注掉了
        --assert(tbNpcJson.CampType == CampDef.Type.CAMP_2, "SideQuest01 npc CampType not set to CampDef.Type.CAMP_2")
        if(tbNpcJson.CampType == CampDef.Type.CAMP_2) then
            self.nNpcCount = self.nNpcCount + 1
        end
    end
end

local function SpawnNpcs(self)
    SpawnerSystem:SpawnByGroupIndex(0, SpawnerDef.SpawnerType.ALL_NPC)
end

function SideQuest01GameStep:Init()
    SideQuest01GameStep.super.Init(self)
    self.NpcGroupDeadTarget = self:CreateTarget(GroupDeadTargetClass)
    self.SinglePlayerDeadTarget = self:CreateTarget(SinglePlayerDeadTargetClass)
end

function SideQuest01GameStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)
    self.tbGameState = tbGameState
    self.rFightResult = tbGameState.rSideQuest01FightResult
    self.rBattlePlayerResultStepForShow = tbGameState.rBattlePlayerResultStep

    self.tbTemplateData = tbTemplateData
    ParseNpcsJsonData(self, tbJsonTableFile.tbContainer.DungeonNPCSpawners)
end

-- 同步Step信息
function SideQuest01GameStep:RepStepInfo(bRepNow)
    SideQuest01GameStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function SideQuest01GameStep:SnapshotToReplicatedProperty()

    return true
end

-- 当Target结束时候会调用这个函数
-- return true  该step完成
-- return false 该step没完成
function SideQuest01GameStep:CheckComplete(BattleTarget)

    -- FOR DISPLAY IN LAST STEP - SHOW RESULT
    local rResult = self.rBattlePlayerResultStepForShow
    rResult.Results = {}
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nPlayerId = PlayerSelf.nPlayerId
    local tbResult = {}
    tbResult.nPlayerId = nPlayerId
    table.insert(rResult.Results, tbResult)

    if BattleTarget == self.NpcGroupDeadTarget then
        tbResult.nResult = BattleResultDef.WIN
        self.tbGameState.bWin = true
    elseif BattleTarget == self.SinglePlayerDeadTarget then
        tbResult.nResult = BattleResultDef.LOSE
        self.tbGameState.bWin = false
    end

    return true
end

function SideQuest01GameStep:Start()
    SpawnNpcs(self)
    self.NpcGroupDeadTarget:AddGroupInfo(0, CampDef.Type.CAMP_2, self.nNpcCount)

    SideQuest01GameStep.super.Start(self)
end

function SideQuest01GameStep:Complete()
    SideQuest01GameStep.super.Complete(self)
end

-- 将结果写入到GameState数据面板里
function SideQuest01GameStep:CalculateResult()
    
end

return SideQuest01GameStep
