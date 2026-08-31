-- 走私副本

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local SmuggleStep = luaclass("SmuggleStep", BattleStepBaseClass)
-- local EventManager = require("EventManager")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")
local Proto = require("DungeonRepProtoNames")
local BattleTeamSystem = require("BattleTeamSystem")
local SpawnerSystem = require("SpawnerSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleObjectiveHelper = require("BattleObjectiveHelper")
local SpawnerDef = require("SpawnerDef")


local PLAYER_WIN = Proto.PlayerWinLoseResult_ResultType.WIN
local PLAYER_LOSE = Proto.PlayerWinLoseResult_ResultType.LOSE

SmuggleStep.tbJsonData = nil
SmuggleStep.tbGameState = nil
SmuggleStep.nNpcGroupIndex = 0
SmuggleStep.nFinishTriggerID = 0
SmuggleStep.bFinished = false
SmuggleStep.nMatineeId = 0
SmuggleStep.nDialogId = 0
SmuggleStep.nBuffId = 0
-- SmuggleStep.nResult = nil

function SmuggleStep:Init()
    SmuggleStep.super.Init(self)

    self.szName = "SmuggleStep"
end

function SmuggleStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)
    self.tbGameState = tbGameState
    self.rBattlePlayerResultStep = tbGameState.rBattlePlayerResultStep
    local rStep = self.rBattlePlayerResultStep
    rStep.nStepTime = tbTemplateData.nShowResultTime
    rStep.Results = {}    
    self.tbJsonData = tbJsonTableFile
    self.nNpcGroupIndex = tbTemplateData.nNpcGroupIndex
    self.nFinishTriggerID = tbTemplateData.nFinishTriggerID
    self.nMatineeId = tbTemplateData.nMatineeId
    self.nDialogId = tbTemplateData.nDialogId
    self.nBuffId = tbTemplateData.nBuffId
end

function SmuggleStep:CheckComplete(BattleTarget)
    return true
end

function SmuggleStep:OnMatineeEnd()
    local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbGameObject, _ in pairs(tbGameObjects) do
        if tbGameObject.BuffComponentServer and not tbGameObject:IsDead() then
            tbGameObject.BuffComponentServer:AddBuffById(self.nBuffId)
        end
    end

    BattleInteractionHelper:ShowDialog(self.nDialogId)    
    BattleObjectiveHelper:ObjectiveStepForward()
    return true
end

function SmuggleStep:Start()
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_ENTER, self, self.OnActorEnterArea)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    -- 创建终点区域
    self:InitAreaInfo()

    -- 创建NPC
    log("SmuggleStep:CreateNpc")
    SpawnerSystem:SpawnByGroupIndex(self.nNpcGroupIndex, SpawnerDef.SpawnerType.ALL_NPC)
    
    -- 播放Matinee
    -- log("SmuggleStep:PlayMatinee", self.nMatineeId)
    BattleInteractionHelper:LocalPlayMatinee(self.nMatineeId, self, self.OnMatineeEnd, false)
    
    SmuggleStep.super.Start(self)
end

function SmuggleStep:InitAreaInfo()
    local tbTriggers = self.tbJsonData.tbContainer.Triggers
    if tbTriggers == nil then
       return 
    end
    local tbJson
    local nCount = #tbTriggers
    for i=1, nCount do
        tbJson = tbTriggers[i]
        local tbData = {tbJsonData = tbJson}
        GameObjectSystem:CreateTriggerInGameMode(tbData)
    end
end

-- function SmuggleStep:CheckPlayerLose()
--     -- if self.nResult ~= PLAYER_WIN then 
--     local tbPlayerAward = {}
--     tbPlayerAward.nResultType = self.nResult
--     tbPlayerAward.tbAwardList = {}
--     EventManager:OnFireEvent(CommonEventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD, tbPlayerAward)
--     -- end 
-- end

function SmuggleStep:Complete()
    --结算
    log("SmuggleStep:Complete")
    self:CalculateResult()
    -- self:CheckPlayerLose()

    SmuggleStep.super.Complete(self)
end

function SmuggleStep:OnActorEnterArea(tbGameTrigger, tbGameObject)
    log("SmuggleStep:OnPawnEnterArea")
    local nTriggerId = tbGameTrigger.nTriggerId
 
    -- 如果是玩家触发trigger则顺利逃出副本,玩家胜利
    if tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf and nTriggerId == self.nFinishTriggerID then
        self.bFinished = true
        self:Complete()
    end
end

function SmuggleStep:CalculateResult()
    local nResultType = PLAYER_LOSE
    local tbResults  = self.rBattlePlayerResultStep.Results
    if self.bFinished then
        nResultType = PLAYER_WIN
    end
    self.tbGameState.bWin = nResultType
    -- self.nResult = nResultType

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

function SmuggleStep:OnPawnDead(tbDeadObject)
    if tbDeadObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        self:Complete()
    end
end

function SmuggleStep:OnPlayerLogout(tbGamePlayer)
end

-- 同步Step信息
function SmuggleStep:RepStepInfo(bRepNow)
    SmuggleStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function SmuggleStep:SnapshotToReplicatedProperty()
    return true
end

return SmuggleStep
