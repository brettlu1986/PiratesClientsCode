-- 探险者副本

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local SocietyExplorerStep = luaclass("SocietyExplorerStep", BattleStepBaseClass)
-- local GameObjectTypeDef = require("GameObjectTypeDef")
-- local CommonEventDef = require("CommonEventDef")
local BattleTeamSystem = require("BattleTeamSystem")
-- local BattlePawnDeadTargetClass = require("BattlePawnDeadTarget")
local GroupDeadTargetClass = require("BattleNpcGroupDeadTarget")
local SpawnerSystem = require("SpawnerSystem")
local CampDef = require("CampDefine")
local BattleResultDef = require("BattleResultDef")

local PLAYER_WIN = BattleResultDef.WIN
local PLAYER_LOSE = BattleResultDef.LOSE

SocietyExplorerStep.NpcGroupDeadTarget  = nil
-- SocietyExplorerStep.PawnDeadTarget = nil
SocietyExplorerStep.tbJsonData = nil
SocietyExplorerStep.Spawners = nil
SocietyExplorerStep.tbGameState = nil
SocietyExplorerStep.HeadHintDialogId = nil

function SocietyExplorerStep:Init()
    SocietyExplorerStep.super.Init(self)

    self.szName = "SocietyExplorerStep"
    self.Spawners = {}
    -- self.HeadHintDialogId = {}
    self.NpcGroupDeadTarget = self:CreateTarget(GroupDeadTargetClass)
    -- self.PawnDeadTarget = self:CreateTarget(BattlePawnDeadTargetClass)
end

function SocietyExplorerStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)
    self.tbGameState = tbGameState
    self.rBattlePlayerResultStep = tbGameState.rBattlePlayerResultStep
    local rStep = self.rBattlePlayerResultStep
    rStep.nStepTime = tbTemplateData.nShowResultTime
    rStep.Results = {}    
    self.tbJsonData = tbJsonTableFile
    self.HeadHintDialogId = tbTemplateData.nHeadHintDialogId

end

function SocietyExplorerStep:CheckComplete(BattleTarget)
    return true
end

function SocietyExplorerStep:Start()
    -- self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    -- self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, self.OnPlayerLogout)
    -- 创建NPC
    log("SocietyExplorerStep:CreateNpc")
    self.Spawners = SpawnerSystem:GetAllSpawners()
    SpawnerSystem:SpawnAll()
    -- self.PawnDeadTarget:SetParams(GameObjectTypeDef.Npc, #self.Spawners, GameObjectTypeDef.PlayerSelf)
    self.NpcGroupDeadTarget:AddGroupInfo(0, CampDef.Type.CAMP_2, #self.Spawners)   

    SocietyExplorerStep.super.Start(self)
end

function SocietyExplorerStep:Complete()
    --结算
    log("SocietyExplorerStep:Complete")
    self:CalculateResult()

    SocietyExplorerStep.super.Complete(self)
end

function SocietyExplorerStep:CalculateResult()
    local nResultType = PLAYER_LOSE
    local tbResults  = self.rBattlePlayerResultStep.Results
    if self.NpcGroupDeadTarget.bCompleted then
        nResultType = PLAYER_WIN
    end

    local tbAllTeamsInfo = BattleTeamSystem:GetAllTeamInfo()
    for _, tbTeamInfo in pairs(tbAllTeamsInfo) do
        for _, nPlayerId in pairs(tbTeamInfo.tbPlayerIds) do
            local tbResult = {}
            tbResult.nPlayerId = nPlayerId
            tbResult.nResult = nResultType
            table.insert(tbResults, tbResult)
        end
    end
end

function SocietyExplorerStep:OnPawnDead(tbDeadObject)
end

function SocietyExplorerStep:OnPlayerLogout(tbGamePlayer)
end

-- 同步Step信息
function SocietyExplorerStep:RepStepInfo(bRepNow)
    SocietyExplorerStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function SocietyExplorerStep:SnapshotToReplicatedProperty()
    return true
end

return SocietyExplorerStep
