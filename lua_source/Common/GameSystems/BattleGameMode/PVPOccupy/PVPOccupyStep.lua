-- PVP 2v2占圈玩法，只适用于两队或者一队人

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local PVPOccupyStep = luaclass("PVPOccupyStep", BattleStepBaseClass)

local BattleTimerTargetClass = require("BattleTimerTarget")
local BattleTeamDeadTargetClass = require("BattleTeamDeadTarget")
local BattleTeamScoreTargetClass = require("BattleTeamScoreTarget")

local Timer = require("Timer")
local Proto = require("DungeonRepProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleTeamSystem = require("BattleTeamSystem")
local CommonEventDef = require("CommonEventDef")
local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
local PVPOccupyAreaStateMachineClass = require("PVPOccupyAreaStateMachine")
local EventManager = require("EventManager")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleResultDef = require("BattleResultDef")
local SpawnerSystem = require("SpawnerSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

-- local AREA_STATE_NONE = Proto.PVPOccupyAreaInfo_OccupyState.NONE
local AREA_STATE_OCCUPIED = Proto.PVPOccupyAreaInfo_OccupyState.OCCUPIED
-- local AREA_STATE_OCCUPING = Proto.PVPOccupyAreaInfo_OccupyState.OCCUPING
-- local AREA_STATE_STALEMATE = Proto.PVPOccupyAreaInfo_OccupyState.STALEMATE

local AREA1_INDEX = Proto.PVPOccupyAreaInfo_AreaIndex.AREA1
local AREA2_INDEX = Proto.PVPOccupyAreaInfo_AreaIndex.AREA2
local AREA3_INDEX = Proto.PVPOccupyAreaInfo_AreaIndex.AREA3

local PLAYER_WIN = BattleResultDef.WIN
local PLAYER_LOSE = BattleResultDef.LOSE
local PLAYER_TIE = BattleResultDef.TIE


PVPOccupyStep.nArea1TriggerId = -1
PVPOccupyStep.nArea1OccupyTime = 0  -- 环1占领时间
PVPOccupyStep.nArea1PunishOccupyTimeCannon = 0 -- 环1占领中，占领圈内的船被炮击中扣除的占领时间
PVPOccupyStep.nArea1PunishOccupyTimeTorpedo = 0 -- 环1占领中，占领圈内的船被鱼雷击中扣除的占领时间
PVPOccupyStep.nArea1OccupyScore = 0 -- 环1占领积分
PVPOccupyStep.nArea1Score = 0  -- 环1积分速度
PVPOccupyStep.nArea2TriggerId = -1
PVPOccupyStep.tbAreaInfoCenter = nil
PVPOccupyStep.nArea2OccupyTime = 0  -- 环2占领时间
PVPOccupyStep.nArea2PunishOccupyTimeCannon = 0 -- 环2占领中，占领圈内的船被炮击中扣除的占领时间
PVPOccupyStep.nArea2PunishOccupyTimeTorpedo = 0 -- 环2占领中，占领圈内的船被鱼雷击中扣除的占领时间
PVPOccupyStep.nArea2OccupyScore = 0 -- 环2占领积分
PVPOccupyStep.nArea2Score = 0  -- 环2积分速度
PVPOccupyStep.nArea3TriggerId = -1
PVPOccupyStep.nArea3OccupyTime = 0  -- 环3占领时间
PVPOccupyStep.nArea3PunishOccupyTimeCannon = 0 -- 环3占领中，占领圈内的船被炮击中扣除的占领时间
PVPOccupyStep.nArea3PunishOccupyTimeTorpedo = 0 -- 环3占领中，占领圈内的船被鱼雷击中扣除的占领时间
PVPOccupyStep.nArea3OccupyScore = 0 -- 环3占领积分
PVPOccupyStep.nArea3Score = 0  -- 环3积分速度
PVPOccupyStep.nAreaOutScore = 0    -- 圈外积分速度
PVPOccupyStep.nUpdateInterval = 2.0     -- 计算间隔，根策划商量好了，误差不敏感
PVPOccupyStep.nSynRemainTime = 0             -- 同步remaintime用的计时器  
PVPOccupyStep.nSynRemainTimeInterval = 20.0  -- 同步remaintime间隔
PVPOccupyStep.nMaxScore = 0 -- 最大分数
PVPOccupyStep.nDeadScore = 0
PVPOccupyStep.nKillScore = 0

PVPOccupyStep.szOccupyNpcTag = nil

PVPOccupyStep.TimerTarget = nil
PVPOccupyStep.TeamDeadTarget = nil
PVPOccupyStep.TeamScoreTarget = nil
PVPOccupyStep.Timer = nil
PVPOccupyStep.tbAreaInfos = nil -- key : nTriggerId, value: Info
PVPOccupyStep.tbJsonData = nil

PVPOccupyStep.tbPVPOccupyAreaInfoMiddle = nil
PVPOccupyStep.tbPVPOccupyAreaInfoCenter = nil

PVPOccupyStep.rTeamScores = nil
PVPOccupyStep.rStepRemainTime = nil
PVPOccupyStep.rPVPOccupyChangedAreaState = nil
PVPOccupyStep.rPVPOccupyStepInfo = nil

-- 延迟发送占圈信息，降低发包频率，节省网络数据流量，主要原因
-- 是被击通常会连续发生多次（很多炮弹依次打中），扣除占领中的时长信息需要同步，避免短时间内被击多次导致数据通信暴增
-- 状态改变立马发，不延迟
PVPOccupyStep.nAreaInfoDelayRepTime = 0.2 -- 延迟
PVPOccupyStep.nAreaInfoDelayRepTimer = nil


function PVPOccupyStep:Init()
    PVPOccupyStep.super.Init(self)

    self.szName = "PVPOccupyStep"
    self.TimerTarget = self:CreateTarget(BattleTimerTargetClass)
    self.TeamDeadTarget = self:CreateTarget(BattleTeamDeadTargetClass)
    self.TeamScoreTarget = self:CreateTarget(BattleTeamScoreTargetClass)
    self.tbAreaInfos = {}
    self.tbScore = {}
end

function PVPOccupyStep:SetParams(tbGameState, tbTemplateData, tbJsonData)
    self.rTeamScores = tbGameState.rTeamScores
    self.rTeamScores.TeamScores = {}
    self.rStepRemainTime = tbGameState.rStepRemainTime
    self.rPVPOccupyStepInfo = tbGameState.rPVPOccupyStepInfo
    self.rPVPOccupyStepInfo.nStepTime = tbTemplateData.nMatchTime
    self.rPVPOccupyChangedAreaState = tbGameState.rPVPOccupyChangedAreaState
    self.rPVPOccupyChangedAreaState.Areas = {}
    self.rBattlePlayerResultStep = tbGameState.rBattlePlayerResultStep
    local rStep = self.rBattlePlayerResultStep
    rStep.nStepTime = tbTemplateData.nShowResultTime
    rStep.Results = {}    
    
    self.TimerTarget:SetTime(tbTemplateData.nMatchTime)
    self.TeamScoreTarget:SetParams(self.rTeamScores, tbTemplateData.nMaxScore)

    self.nArea1TriggerId = tbTemplateData.nArea1TriggerId
    self.nArea1OccupyTime = tbTemplateData.nArea1OccupyTime
    self.nArea1PunishOccupyTimeCannon = tbTemplateData.nArea1PunishOccupyTimeCannon
    self.nArea1PunishOccupyTimeTorpedo = tbTemplateData.nArea1PunishOccupyTimeTorpedo
    self.nArea1OccupyScore = tbTemplateData.nArea1OccupyScore
    self.nArea1Score = tbTemplateData.nArea1Score

    self.nArea2TriggerId = tbTemplateData.nArea2TriggerId
    self.nArea2OccupyTime = tbTemplateData.nArea2OccupyTime
    self.nArea2PunishOccupyTimeCannon = tbTemplateData.nArea2PunishOccupyTimeCannon
    self.nArea2PunishOccupyTimeTorpedo = tbTemplateData.nArea2PunishOccupyTimeTorpedo
    self.nArea2OccupyScore = tbTemplateData.nArea2OccupyScore
    self.nArea2Score = tbTemplateData.nArea2Score

    self.nArea3TriggerId = tbTemplateData.nArea3TriggerId
    self.nArea3OccupyTime = tbTemplateData.nArea3OccupyTime
    self.nArea3PunishOccupyTimeCannon = tbTemplateData.nArea3PunishOccupyTimeCannon
    self.nArea3PunishOccupyTimeTorpedo = tbTemplateData.nArea3PunishOccupyTimeTorpedo
    self.nArea3OccupyScore = tbTemplateData.nArea3OccupyScore
    self.nArea3Score = tbTemplateData.nArea3Score

    self.szOccupyNpcTag= tbTemplateData.szOccupyNpcTag

    self.nAreaOutScore = tbTemplateData.nAreaOutScore
    self.nMaxScore = tbTemplateData.nMaxScore
    self.nDeadScore = tbTemplateData.nDeadScore
    self.nKillScore = tbTemplateData.nKillScore
    self.tbJsonData = tbJsonData

    self:InitAreaInfo()
end

-- 同步Step信息
function PVPOccupyStep:RepStepInfo(bRepNow)
    if(bRepNow) then
        self.rPVPOccupyStepInfo.RepNow()
    else
        self.rPVPOccupyStepInfo.Rep()
    end
    PVPOccupyStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function PVPOccupyStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()

    local nNewRemainTime = self.TimerTarget:GetRemainTime()
    local nDeltaTime = self.rStepRemainTime.nTime - nNewRemainTime
    if(nDeltaTime < 0) then        
        nDeltaTime = 0
    end

    -- 这里分数不用重新计算，下次心跳会重新算，时间要刷一次
    self:UpdateRemainTime(nDeltaTime, false)
    
    -- 把State都rep下去
    local tbAreaInfos = self.tbAreaInfos
    for nAreaId, tbAreaInfo in pairs(tbAreaInfos) do
        self:AreaInfoMarkDirty(tbAreaInfo.tbSM.rInfo)
    end
    self:UpdateAreaInfo(true, false)
    return true
end

function PVPOccupyStep:CheckComplete(BattleTarget)
    -- 任何一个目标完成这个step都算完成
    return true
end

-- TODO:这里有隐患，如果上来就只有一个玩家进入，并且走到了这里，然后又来了第二个玩家，从属于另一个新队伍
-- 那么这里的新队伍信息并没有再次加入到rTeamScores中
function PVPOccupyStep:Start()
    self.nSynRemainTime = 0
    self.rStepRemainTime.nTime = self.TimerTarget.nMaxTime    
    self.Timer = Timer.NewTimerMethod(self, self.Update, self.nUpdateInterval, true)
    
    self:InitTeamScoreInfo()
    
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_ENTER, self, self.OnActorEnterArea)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_LEAVE, self, self.OnActorLeaveArea)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.OnGameObjectPostActorCreate)

    -- 强制rep一把
    self:ForceUpdate(true)

    PVPOccupyStep.super.Start(self)

    -- 接统计
    EventManager:OnFireEvent(CommonEventDef.EV_ENTER_PVPOCCUPY_STEP)

    -- 如果只进来一队，直接赢
    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    if(#tbTeams <= 1) then
        self:Complete()
    end

    for _, tbTeam in pairs(tbTeams) do
        for _, tbObject in pairs(tbTeam.tbGameObjects) do
            self:BindHitEvent(tbObject)
        end
    end
end

function PVPOccupyStep:Complete()
    -- 强制rep一把
    self:ForceUpdate(true)

    if(self.Timer) then
        self.Timer:Clear()
        self.Timer = nil
    end

    if(self.nAreaInfoDelayRepTimer) then
        self.nAreaInfoDelayRepTimer:Clear()
        self.nAreaInfoDelayRepTimer = nil
    end

    for nAreaId, tbAreaInfo in pairs(self.tbAreaInfos) do
        if(tbAreaInfo.tbSM) then
            tbAreaInfo.tbSM:Uninit()
        end
    end

    self:CalculateResult()
    
    PVPOccupyStep.super.Complete(self)
end

function PVPOccupyStep:CalculateResult()
    local tbResults  = self.rBattlePlayerResultStep.Results
    local tbTeamScores = self.rTeamScores.TeamScores
    local TeamDeadTarget = self.TeamDeadTarget
    local nTeamCount = #tbTeamScores
    assert(nTeamCount >= 1)    
    local tbWinTeam, tbLoseTeam
    
    local nDeadTeamId = nil
    if(nTeamCount <= 1) then
        -- 只有一个队近来，直接赢
        tbWinTeam = tbTeamScores[1]
        tbLoseTeam = nil
    else
        -- 以下代码假设只有两队或者一队，三队以及以上这里不支持
        nDeadTeamId = TeamDeadTarget.nDeadTeamId    
        if(nDeadTeamId >= 0) then
            -- 判断死亡队伍
            if(nDeadTeamId == tbTeamScores[1].nTeamId) then
                tbWinTeam = tbTeamScores[2]
                tbLoseTeam = tbTeamScores[1]
            else
                tbWinTeam = tbTeamScores[1]
                tbLoseTeam = tbTeamScores[2]
            end
        else
            -- 判断分数信息
            tbWinTeam = tbTeamScores[1]
            tbLoseTeam = tbTeamScores[2]
            if(tbWinTeam.nScore < tbLoseTeam.nScore) then
                tbWinTeam = tbLoseTeam
                tbLoseTeam = tbTeamScores[1]
            end
        end
    end

    local nWinTeamId = -1
    local nWinScore = 0
    local nLoseTeamId = -1
    local nLoseScore = 0
    if(tbWinTeam) then
        nWinTeamId = tbWinTeam.nTeamId
        nWinScore = tbWinTeam.nScore
    end
    if(tbLoseTeam) then
        nLoseTeamId = tbLoseTeam.nTeamId
        nLoseScore = tbLoseTeam.nScore
    end
    log("PVPOccupyStep:CalculateResult", nWinTeamId, nWinScore, nLoseTeamId, nLoseScore, nDeadTeamId, TeamDeadTarget.bAllDead)

    local bTie = TeamDeadTarget.bAllDead or (nDeadTeamId ~= nil and nLoseScore == nWinScore and nDeadTeamId < 0)

    local nResultType, tbPlayerResult, bWin
    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    for nTeamId, tbTeam in pairs(tbTeams) do
        for _, tbObject in pairs(tbTeam.tbGameObjects) do
            local nPlayerId = tbObject.nPlayerId
            bWin = nTeamId == nWinTeamId
            if(bTie) then
                nResultType = PLAYER_TIE
            elseif(bWin) then
                nResultType = PLAYER_WIN
            else
                nResultType = PLAYER_LOSE
            end
            tbPlayerResult = {}
            tbPlayerResult.nPlayerId = nPlayerId
            tbPlayerResult.nResult = nResultType
            table.insert(tbResults, tbPlayerResult)
        end
    end
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    tbGameMode:OnGameOver(tbResults)
end

function PVPOccupyStep:InitAreaInfo()
    local tbAreaInfos = {}
    self.tbAreaInfos = tbAreaInfos

    local tbTriggers = self.tbJsonData.tbContainer.Triggers
    local tbGameTrigger, tbJson, tbAreaInfo, nTriggerId
    local nCount = #tbTriggers
    for i=1, nCount do
        tbAreaInfo = {}
        tbJson = tbTriggers[i]
        local tbData = {tbJsonData = tbJson}
        tbGameTrigger = GameObjectSystem:CreateTriggerInGameMode(tbData)
        nTriggerId = tbGameTrigger.nTriggerId
        tbAreaInfo.nTriggerId = nTriggerId

        local tbSM = PVPOccupyAreaStateMachineClass()
        local tbRepData = {}
        tbRepData.nAreaIndex = self:GetAreaIndex(nTriggerId)
        tbSM:Init()
        tbSM:SetParams(tbRepData, self:GetOccupyMaxTime(nTriggerId), function(_tbSM, tbFromState, tbToState)
            self:OnAreaStateChanged(tbRepData, tbFromState, tbToState)
        end)
        tbSM:Start()
        tbAreaInfo.tbSM = tbSM
        tbAreaInfos[nTriggerId] = tbAreaInfo
    end

    if self.szOccupyNpcTag and string.len(self.szOccupyNpcTag) > 0 then 
        SpawnerSystem:SpawnByTag(self.szOccupyNpcTag)
    end
end

function PVPOccupyStep:InitTeamScoreInfo()
    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    local tbTeamScores = self.rTeamScores.TeamScores
    local tbSingleTeamScore

    for nTeamId, tbTeam in pairs(tbTeams) do
        tbSingleTeamScore = {}
        tbSingleTeamScore.nTeamId = nTeamId
        tbSingleTeamScore.nScore = 0        -- 这个为了同步
        tbSingleTeamScore.nScoreFloat = 0.0   -- 这个是为了计算准确
        table.insert(tbTeamScores, tbSingleTeamScore)
    end
end

function PVPOccupyStep:Update()
    local nNewRemainTime = self.TimerTarget:GetRemainTime()
    local nDeltaTime = self.rStepRemainTime.nTime - nNewRemainTime
    if(nDeltaTime < 0) then
        logerror("PVPOccupyStep:Update failed, the delta time is less then zero.", nDeltaTime)
        return
    end
    
    self:UpdateScore(nDeltaTime, true)
    self:UpdateRemainTime(nDeltaTime, false)
end

function PVPOccupyStep:ForceUpdate(bForceRep)
    log("PVPOccupyStep:ForceUpdate")
    self:UpdateScore(0, bForceRep)
    self:UpdateRemainTime(0, bForceRep)
end

local FindTeamScore = function(tbTeamScores, nTeamId)
    local tbTeamScore
    local nTeamCount = #tbTeamScores
    for i=1, nTeamCount do
        tbTeamScore = tbTeamScores[i]
        if(tbTeamScore.nTeamId == nTeamId) then
            return tbTeamScore                
        end
    end
    return nil
end

-- 更新分数
function PVPOccupyStep:UpdateScore(nDeltaTime, bForceRep)
    local tbTeamScores = self.rTeamScores.TeamScores
    local nTeamCount = #tbTeamScores
    
    -- 先算圈里的
    local tbSM, tbTeamScore
    for nAreaId, tbAreaInfo in pairs(self.tbAreaInfos) do
        tbSM = tbAreaInfo.tbSM
        if(tbSM.rInfo.nState == AREA_STATE_OCCUPIED) then
            tbTeamScore = FindTeamScore(tbTeamScores, tbSM.rInfo.nOwnerTeamId)
            assert(tbTeamScore)
            tbTeamScore.nScoreFloat = tbTeamScore.nScoreFloat + 
                self:GetScoreVelocity(tbAreaInfo.nTriggerId) * nDeltaTime
        end
    end

    -- 再算圈外的
    local nScoreFloat = 0
    for i=1, nTeamCount do
        tbTeamScore = tbTeamScores[i]
        nScoreFloat = tbTeamScore.nScoreFloat
        nScoreFloat = nScoreFloat + self:GetScoreVelocity(-1) * nDeltaTime
        if(nScoreFloat > self.nMaxScore) then
            nScoreFloat = self.nMaxScore
        end
        tbTeamScore.nScoreFloat = nScoreFloat
        tbTeamScore.nScore = math.ceil(tbTeamScore.nScoreFloat)            
    end

    if(bForceRep) then
        -- 标记为replicate，下针会发送到客户端
        self.rTeamScores.Rep()
    end
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_TEAM_SCORE_CHANGE, self.rTeamScores)
end

-- 更新游戏剩余时间
function PVPOccupyStep:UpdateRemainTime(nDeltaTime, bForceRep)    
    local nCurrentTime = self.nSynRemainTime
    local nMaxTime = self.nSynRemainTimeInterval
    local bNeedRep = bForceRep or false

    nCurrentTime = nCurrentTime + nDeltaTime
    while(nCurrentTime >= nMaxTime) do
        nCurrentTime = nCurrentTime - nMaxTime
        bNeedRep = true
    end

    local rStepRemainTime = self.rStepRemainTime
    rStepRemainTime.nTime = rStepRemainTime.nTime - nDeltaTime
    self.nSynRemainTime = nCurrentTime
    if(bNeedRep) then
        rStepRemainTime.Rep()
    end
end

function PVPOccupyStep:AreaInfoMarkDirty(rInfo)
    local rState = self.rPVPOccupyChangedAreaState
    local rAreas = rState.Areas
    for i, rAreaInfo in ipairs(rAreas) do
        if rAreaInfo.nAreaIndex == rInfo.nAreaIndex then
            log("Delay rep area info reduce multicast times +1")
            table.remove(rAreas, i)
            break
        end
    end
    table.insert(rAreas, rInfo)
end

function PVPOccupyStep:UpdateAreaInfo(bNeedRefresh, bRepNow)
    local rState = self.rPVPOccupyChangedAreaState
    local rAreas = rState.Areas
    if #rAreas > 0 then
        if bNeedRefresh then
            for _, rInfo in ipairs(rAreas) do
                local nAreaIndex = rInfo.nAreaIndex
                local nTriggerId = self:GetTriggerId(nAreaIndex)
                local tbAreaInfo = self.tbAreaInfos[nTriggerId]
                assert(tbAreaInfo ~= nil)
                tbAreaInfo.tbSM:RefreshRepInfo()
            end
        end
        if bRepNow then
            rState.RepNow()
        else
            rState.Rep()
        end
        rState.Areas = {}
        if self.nAreaInfoDelayRepTimer then
            self.nAreaInfoDelayRepTimer:Clear()
            self.nAreaInfoDelayRepTimer = nil
        end
    end
end

-- 因为几个圈有重叠，所以这里伪造了进了一个圈从另一个圈出来
local function TryLeaveArea(self, tbArea, nUniqueId, nTeamId)
    if(tbArea.tbUniqueIds 
        and tbArea.tbUniqueIds[nUniqueId]
        and tbArea.tbSM.tbIds[nUniqueId]) then
        
        log("PVPOccupyStep:LeaveArea", tbArea.nTriggerId, nTeamId, nUniqueId)
        tbArea.tbSM:OnLeave(nUniqueId, nTeamId)
        return true
    end
    return false
end

local function TryEnterArea(self, tbArea, nUniqueId, nTeamId)
    if(tbArea.tbUniqueIds 
        and tbArea.tbUniqueIds[nUniqueId]
        and tbArea.tbSM.tbIds[nUniqueId] == nil) then
        
        log("PVPOccupyStep:EnterArea", tbArea.nTriggerId, nTeamId, nUniqueId)
        tbArea.tbSM:OnEnter(nUniqueId, nTeamId)
        return true
    end
    return false
end

local function TryLeaveOtherArea(self, tbGameObject)
    local nUniqueId = tbGameObject.nUniqueId
    local tbAreaInfos = self.tbAreaInfos
    local nTeamId = tbGameObject.BattleTeamComponent.nTeamId

    -- 根据优先级退出，最外圈的先退
    if((tbAreaInfos[self.nArea3TriggerId] and TryLeaveArea(self, tbAreaInfos[self.nArea3TriggerId], nUniqueId, nTeamId))
        or (tbAreaInfos[self.nArea2TriggerId] and TryLeaveArea(self, tbAreaInfos[self.nArea2TriggerId], nUniqueId, nTeamId))
        or (tbAreaInfos[self.nArea1TriggerId] and TryLeaveArea(self, tbAreaInfos[self.nArea1TriggerId], nUniqueId, nTeamId))) then
        return
    end
end

local function TryEnterOtherArea(self, tbGameObject)
    local nUniqueId = tbGameObject.nUniqueId
    local tbAreaInfos = self.tbAreaInfos
    local nTeamId = tbGameObject.BattleTeamComponent.nTeamId

    -- 根据优先级进入，最内圈的先进
    if((tbAreaInfos[self.nArea1TriggerId] and TryEnterArea(self, tbAreaInfos[self.nArea1TriggerId], nUniqueId, nTeamId))
        or (tbAreaInfos[self.nArea2TriggerId] and TryEnterArea(self, tbAreaInfos[self.nArea2TriggerId], nUniqueId, nTeamId))
        or (tbAreaInfos[self.nArea3TriggerId] and TryEnterArea(self, tbAreaInfos[self.nArea3TriggerId], nUniqueId, nTeamId))) then
        return
    end 
end

function PVPOccupyStep:OnActorEnterArea(tbGameTrigger, tbGameObject)
    if(BattleTeamSystem:FindTeamId(tbGameObject) < 0) then
        return
    end

    local nTriggerId = tbGameTrigger.nTriggerId
    local tbAreaInfo = self.tbAreaInfos[nTriggerId]
    local nUniqueId = tbGameObject.nUniqueId
    if(tbGameObject.BattleTeamComponent == nil) then
        error("PVPOccupyStep:OnActorEnterArea failed, BattleTeamComponent is invalid " .. nUniqueId)
        return
    end

    -- 因为OnActorEnterArea只会在进入trigger时触发，同时又因为几个圈叠在一块，所以这里要伪造leave事件
    TryLeaveOtherArea(self, tbGameObject)

    -- 记录下真实在圈里的东西
    local tbSavedUniqueIds = tbAreaInfo.tbUniqueIds
    if(tbSavedUniqueIds == nil) then
        tbSavedUniqueIds = {}
        tbAreaInfo.tbUniqueIds = tbSavedUniqueIds
    end
    tbSavedUniqueIds[nUniqueId] = true

    TryEnterArea(self, tbAreaInfo, nUniqueId, tbGameObject.BattleTeamComponent.nTeamId)
end

function PVPOccupyStep:OnActorLeaveArea(tbGameTrigger, tbGameObject)    
    if(BattleTeamSystem:FindTeamId(tbGameObject) < 0) then
        return
    end  
    
    local nTriggerId = tbGameTrigger.nTriggerId
    local tbAreaInfo = self.tbAreaInfos[nTriggerId]
    local nUniqueId = tbGameObject.nUniqueId
    if(tbGameObject.BattleTeamComponent == nil) then
        error("PVPOccupyStep:OnActorEnterArea failed, BattleTeamComponent is invalid " .. nUniqueId)
        return
    end

    -- 清理下
    TryLeaveArea(self, tbAreaInfo, nUniqueId, tbGameObject.BattleTeamComponent.nTeamId)
    if(tbAreaInfo.tbUniqueIds) then
        tbAreaInfo.tbUniqueIds[nUniqueId] = nil
    end

    -- 尝试重新加入到别的圈里
    TryEnterOtherArea(self, tbGameObject)
end

function PVPOccupyStep:OnPawnDead(tbDeadObject)
    local tbKillObject = nil--tbDeadObject.BattleStatusComponent:GetLastDamageCauser()
    if(BattleTeamSystem:FindTeamId(tbDeadObject) < 0) then
        return
    end
    log("PVPOccupyStep:OnPawnDead")

    -- 离开所有区域
    local nTeamId = tbDeadObject.BattleTeamComponent.nTeamId
    local nUniqueId = tbDeadObject.nUniqueId
    for nTriggerId, tbAreaInfo in pairs(self.tbAreaInfos) do
        TryLeaveArea(self, tbAreaInfo, nUniqueId, nTeamId)
        if(tbAreaInfo.tbUniqueIds) then
            tbAreaInfo.tbUniqueIds[nUniqueId] = nil
        end        
    end
    
    -- 死亡积分
    local tbTeamScores = self.rTeamScores.TeamScores
    local tbTeamScore = FindTeamScore(tbTeamScores, nTeamId)
    if(tbTeamScore == nil) then
        logerror("PVPOccupyStep:OnPawnDead error, can not find dead teamid", nTeamId, nUniqueId)
        return
    end
    local nScore = tbTeamScore.nScoreFloat
    nScore = nScore - self.nDeadScore
    if(nScore < 0) then
        nScore = 0
    end
    tbTeamScore.nScoreFloat = nScore
    log("Dead decrease score", nTeamId, nUniqueId, tbTeamScore.nScoreFloat)

    -- 击杀得分
    if(tbKillObject ~= nil and tbDeadObject ~= tbKillObject and BattleTeamSystem:FindTeamId(tbKillObject) >= 0) then
        nUniqueId = tbKillObject.nUniqueId
        nTeamId = tbKillObject.BattleTeamComponent.nTeamId
        tbTeamScore = FindTeamScore(tbTeamScores, nTeamId)
        if(tbTeamScore == nil) then
            logerror("PVPOccupyStep:OnPawnDead error, can not find kill teamid", nTeamId, nUniqueId)
            return
        end        
        nScore = tbTeamScore.nScoreFloat + self.nKillScore
        if(nScore > self.nMaxScore) then
            nScore = self.nMaxScore
        end
        tbTeamScore.nScoreFloat = nScore
        log("Kill increase score", nTeamId, nUniqueId, tbTeamScore.nScoreFloat)
    end
    self:UpdateScore(0, true)

    -- 设置死亡状态
    if tbDeadObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, BattleReviveModeTypeDef.Reset, tbDeadObject)
    end
end

function PVPOccupyStep:OnAreaStateChanged(tbRepData, tbFromState, tbToState)
    -- RepNow
    if tbFromState.nState ~= Proto.PVPOccupyAreaInfo_OccupyState.OCCUPIED
        and tbToState.nState == Proto.PVPOccupyAreaInfo_OccupyState.OCCUPIED then
        local nTeamId = tbRepData.nOwnerTeamId
        assert(nTeamId ~= -1)
        local tbTeamScores = self.rTeamScores.TeamScores
        local tbTeamScore = FindTeamScore(tbTeamScores, nTeamId)
        if(tbTeamScore == nil) then
            logerror("PVPOccupyStep:OnAreaStateChanged error, can not find state changed teamid", nTeamId)
            return
        end
        local nTriggerId = self:GetTriggerId(tbRepData.nAreaIndex)
        local nScore = tbTeamScore.nScoreFloat + self:GetOccupyScore(nTriggerId)
        if(nScore > self.nMaxScore) then
            nScore = self.nMaxScore
        end
        tbTeamScore.nScoreFloat = nScore
        self:UpdateScore(0, true)
    end

    self:AreaInfoMarkDirty(tbRepData)
    self:UpdateAreaInfo(false, true)
end

local function StartDelayRepAreaInfoTimer(self)
    if self.nAreaInfoDelayRepTimer == nil then
        assert(self.nAreaInfoDelayRepTime > 0)
        local fnDelayRepTimerCallback = function()
            self:UpdateAreaInfo(true, true)
            self.nAreaInfoDelayRepTimer = nil
        end
        self.nAreaInfoDelayRepTimer = Timer.NewTimer(fnDelayRepTimerCallback, self.nAreaInfoDelayRepTime, false)
    end
end

local function OnPunishOccupyingTime(self, tbGameObject, tbSM, nPunishTime)
    local nUniqueId = tbGameObject.nUniqueId
    local nTeamId = BattleTeamSystem:FindTeamId(tbGameObject)
    if tbSM:OnPunishOccupyingTime(nUniqueId, nTeamId, nPunishTime) then
        log("OnPunishOccupyingTime. Remaining time:", tbSM.rInfo.nOccupyingRemainTime)
        self:AreaInfoMarkDirty(tbSM.rInfo)
        StartDelayRepAreaInfoTimer(self)
    end
end

local function GetTargetSM(self, nUniqueId)
    for _, tbArea in pairs(self.tbAreaInfos) do
        if tbArea.tbSM.tbIds[nUniqueId] ~= nil then
            return tbArea.tbSM
        end
    end
    return nil
end

local function PunishOccupyTime(tbGameObject, fnGetPunishTime, self, nDamage, nResult, pAttackShip, bTeammate)
    if not bTeammate then
        local tbSM = GetTargetSM(self, tbGameObject.nUniqueId)
        if tbSM then
            local nTriggerId = self:GetTriggerId(tbSM.rInfo.nAreaIndex)
            local nPunishTime = fnGetPunishTime(self, nTriggerId)
            OnPunishOccupyingTime(self, tbGameObject, tbSM, nPunishTime)
        end
    end
end

function PVPOccupyStep:BindHitEvent(tbGameObject)
    if tbGameObject.DelegateComponent then
        self.SelfEventHelper:RegisterLuaDelegate(tbGameObject.DelegateComponent.OnHitByCannon, function(...) PunishOccupyTime(tbGameObject, self.GetPunishOccupyTimeCannon, ...) end, self)
        self.SelfEventHelper:RegisterLuaDelegate(tbGameObject.DelegateComponent.OnHitByTorpedo, function(...) PunishOccupyTime(tbGameObject, self.GetPunishOccupyTimeTorpedo, ...) end, self)
    end
end

function PVPOccupyStep:OnGameObjectPostActorCreate(tbGameObject)
    self:BindHitEvent(tbGameObject)
end

-- 转换每秒计分速度
function PVPOccupyStep:GetScoreVelocity(nTriggerId)
    if(nTriggerId == self.nArea1TriggerId) then
        return self.nArea1Score
    elseif(nTriggerId == self.nArea2TriggerId) then
        return self.nArea2Score
    elseif(nTriggerId == self.nArea3TriggerId) then
        return self.nArea3Score
    end
    return self.nAreaOutScore    
end

-- 获取占领时间
function PVPOccupyStep:GetOccupyMaxTime(nTriggerId)    
    if(nTriggerId == self.nArea1TriggerId) then
        return self.nArea1OccupyTime
    elseif(nTriggerId == self.nArea2TriggerId) then
        return self.nArea2OccupyTime
    elseif(nTriggerId == self.nArea3TriggerId) then
        return self.nArea3OccupyTime
    end
    assert(false)
    return 0
end

function PVPOccupyStep:GetAreaIndex(nTriggerId)
    if(nTriggerId == self.nArea1TriggerId) then
        return AREA1_INDEX
    elseif(nTriggerId == self.nArea2TriggerId) then
        return AREA2_INDEX
    elseif(nTriggerId == self.nArea3TriggerId) then
        return AREA3_INDEX
    end
    assert(false)
    return 0
end

function PVPOccupyStep:GetTriggerId(nAreaIndex)
    if(nAreaIndex == AREA1_INDEX) then
        return self.nArea1TriggerId
    elseif(nAreaIndex == AREA2_INDEX) then
        return self.nArea2TriggerId
    elseif(nAreaIndex == AREA3_INDEX) then
        return self.nArea3TriggerId
    end
    assert(false)
    return 0
end

function PVPOccupyStep:GetOccupyScore(nTriggerId)
    if(nTriggerId == self.nArea1TriggerId) then
        return self.nArea1OccupyScore
    elseif(nTriggerId == self.nArea2TriggerId) then
        return self.nArea2OccupyScore
    elseif(nTriggerId == self.nArea3TriggerId) then
        return self.nArea3OccupyScore
    end
    assert(false)
    return 0
end

function PVPOccupyStep:GetPunishOccupyTimeCannon(nTriggerId)
    if(nTriggerId == self.nArea1TriggerId) then
        return self.nArea1PunishOccupyTimeCannon
    elseif(nTriggerId == self.nArea2TriggerId) then
        return self.nArea2PunishOccupyTimeCannon
    elseif(nTriggerId == self.nArea3TriggerId) then
        return self.nArea3PunishOccupyTimeCannon
    end
    assert(false)
    return 0
end

function PVPOccupyStep:GetPunishOccupyTimeTorpedo(nTriggerId)
    if(nTriggerId == self.nArea1TriggerId) then
        return self.nArea1PunishOccupyTimeTorpedo
    elseif(nTriggerId == self.nArea2TriggerId) then
        return self.nArea2PunishOccupyTimeTorpedo
    elseif(nTriggerId == self.nArea3TriggerId) then
        return self.nArea3PunishOccupyTimeTorpedo
    end
    assert(false)
    return 0
end

-- 需要清除timer 否则副本中途退出可能有影响
function PVPOccupyStep:Uninit()
    if(self.Timer) then
        self.Timer:Clear()
        self.Timer = nil
    end

    if (self.nAreaInfoDelayRepTimer) then
        self.nAreaInfoDelayRepTimer:Clear()
        self.nAreaInfoDelayRepTimer = nil
    end

    for nAreaId, tbAreaInfo in pairs(self.tbAreaInfos) do
        if(tbAreaInfo.tbSM) then
            tbAreaInfo.tbSM:Uninit()
        end
    end

    PVPOccupyStep.super.Uninit(self)
end

return PVPOccupyStep
