-- 占圈step

local luaclass = require("luaclass")

local BattleTargetActionStep = require("BattleTargetActionStep")
local BattleOccupyStep = luaclass("BattleOccupyStep", BattleTargetActionStep)

local Timer = require("Timer")
local Proto = require("DungeonRepProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleTeamSystem = require("BattleTeamSystem")
local CommonEventDef = require("CommonEventDef")
local PVPOccupyAreaStateMachineClass = require("PVPOccupyAreaStateMachine")
local EventManager = require("EventManager")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local SpawnerSystem = require("SpawnerSystem")

local AREA_STATE_OCCUPIED = Proto.PVPOccupyAreaInfo_OccupyState.OCCUPIED
local AREA1_INDEX = Proto.PVPOccupyAreaInfo_AreaIndex.AREA1

BattleOccupyStep.nAreaTriggerId = -1
BattleOccupyStep.nAreaOccupyTime = 0  -- 环1占领时间
BattleOccupyStep.nAreaPunishOccupyTimeCannon = 0 -- 环1占领中，占领圈内的船被炮击中扣除的占领时间
BattleOccupyStep.nAreaPunishOccupyTimeTorpedo = 0 -- 环1占领中，占领圈内的船被鱼雷击中扣除的占领时间
BattleOccupyStep.nAreaOccupyScore = 0 -- 环1占领积分
BattleOccupyStep.nAreaScore = 0  -- 环1积分速度

BattleOccupyStep.nAreaOutScore = 0    -- 圈外积分速度
BattleOccupyStep.nUpdateInterval = 2.0     -- 计算间隔，根策划商量好了，误差不敏感
BattleOccupyStep.nMaxScore = 0 -- 最大分数
BattleOccupyStep.nDeadScore = 0
BattleOccupyStep.nKillScore = 0

BattleOccupyStep.Timer = nil
BattleOccupyStep.tbAreaInfos = nil -- key : nTriggerId, value: Info
BattleOccupyStep.tbTeamCampType = nil

BattleOccupyStep.rTeamScores = nil
BattleOccupyStep.rPVPOccupyChangedAreaState = nil

-- 延迟发送占圈信息，降低发包频率，节省网络数据流量，主要原因
-- 是被击通常会连续发生多次（很多炮弹依次打中），扣除占领中的时长信息需要同步，避免短时间内被击多次导致数据通信暴增
-- 状态改变立马发，不延迟
BattleOccupyStep.nAreaInfoDelayRepTime = 0.2 -- 延迟
BattleOccupyStep.nAreaInfoDelayRepTimer = nil

function BattleOccupyStep:ForceStop()
    BattleOccupyStep.super.ForceStop(self)
end

function BattleOccupyStep:OnCompleted()
    BattleOccupyStep.super.OnCompleted(self)
    -- 把子节点都强停掉
    self:ForceStop()
end

function BattleOccupyStep:Init()
    BattleOccupyStep.super.Init(self)

    self.szName = "BattleOccupyStep"
    self.tbAreaInfos = {}
    self.tbScore = {}
    self.tbTeamCampType = {}
end


function BattleOccupyStep:Parse(tbJsonData)
    if(not BattleOccupyStep.super.Parse(self, tbJsonData)) then
        return false
    end

    local tbGameState = BattleGameModeSystem:GetGameState()
    self.rTeamScores = tbGameState.rTeamScores
    self.rTeamScores.TeamScores = {}
    self.rPVPOccupyChangedAreaState = tbGameState.rPVPOccupyChangedAreaState
    self.rPVPOccupyChangedAreaState.Areas = {}

    self.nAreaTriggerId = tbJsonData.TriggerId
    self.nAreaOccupyTime = tbJsonData.OccupyTime
    self.nAreaPunishOccupyTimeCannon = tbJsonData.PunishOccupyTimeCannon
    self.nAreaPunishOccupyTimeTorpedo = tbJsonData.PunishOccupyTimeTorpedo
    self.nAreaOccupyScore = tbJsonData.OccupyScore
    self.nAreaScore = tbJsonData.ScoreSpeed

    self.nAreaOutScore = tbJsonData.OutScore
    self.nMaxScore = tbJsonData.MaxScore
    self.nDeadScore = tbJsonData.DeadScore
    self.nKillScore = tbJsonData.KillScore
        
    return true
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function BattleOccupyStep:SnapshotToReplicatedProperty()
    -- 把State都rep下去
    local tbAreaInfos = self.tbAreaInfos
    for nAreaId, tbAreaInfo in pairs(tbAreaInfos) do
        self:AreaInfoMarkDirty(tbAreaInfo.tbSM.rInfo)
    end
    self:UpdateAreaInfo(true, false)
    return true
end

function BattleOccupyStep:Start()
    -- 先监听trigger后创建trigger 保证一创建有玩家在trigger中收到事件
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_ENTER, self, self.OnActorEnterArea)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_LEAVE, self, self.OnActorLeaveArea)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.OnGameObjectPostActorCreate)

    self:InitAreaInfo(self.nAreaTriggerId)
    self:InitTeamScoreInfo()
    self:InitTeamCampType()

    self.Timer = Timer.NewTimerMethod(self, self.Update, self.nUpdateInterval, true)
    
    -- 强制rep一把
    self:ForceUpdate(true)

    BattleOccupyStep.super.Start(self)

    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    for _, tbTeam in pairs(tbTeams) do
        for _, tbObject in pairs(tbTeam.tbGameObjects) do
            self:BindHitEvent(tbObject)
        end
    end
end

function BattleOccupyStep:Complete()
    -- 强制rep一把
    self:ForceUpdate(true)

    -- 清除 Trigger
    local tbOccupyAreaInfo = self.tbAreaInfos[self.nAreaTriggerId]
    GameObjectSystem:DestroyTriggerInGameMode(tbOccupyAreaInfo.nTriggerUniqueId)  

    
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

    BattleOccupyStep.super.Complete(self)
end

function BattleOccupyStep:InitAreaInfo(nTriggerId)
    local tbAreaInfos = self.tbAreaInfos
    local tbAreaInfo = {}
    tbAreaInfo.nTriggerId = nTriggerId
    
    local tbOccupySM = PVPOccupyAreaStateMachineClass()
    local tbRepData = {}
    tbRepData.nAreaIndex = self:GetAreaIndex(nTriggerId)
    tbOccupySM:Init()
    tbOccupySM:SetParams(tbRepData, self:GetOccupyMaxTime(nTriggerId), function(tbSM, tbFromState, tbToState)
        self:OnAreaStateChanged(tbRepData, tbFromState, tbToState)
    end)
    tbOccupySM:Start()
    tbAreaInfo.tbSM = tbOccupySM
    tbAreaInfos[nTriggerId] = tbAreaInfo

    
    -- 先启动状态机再创建trigger,保证创建Trigger时，玩家在其中的状态机正常逻辑处理
    local tbRet = SpawnerSystem:SpawnByTriggerId(nTriggerId)
    -- 存trigger UEActorUniqueId
    tbAreaInfo.nTriggerUniqueId = tbRet[1]:GetUEActorUniqueId()


end

function BattleOccupyStep:InitTeamScoreInfo()
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

function BattleOccupyStep:InitTeamCampType()
    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    local nCampType

    for nTeamId, tbTeam in pairs(tbTeams) do
        nCampType = BattleTeamSystem:GetCampTypeByTeamId(nTeamId)
        self.tbTeamCampType[nTeamId] = nCampType
    end
end

function BattleOccupyStep:Update()
    self:UpdateScore(self.nUpdateInterval, true)
end

function BattleOccupyStep:ForceUpdate(bForceRep)
    self:UpdateScore(0, bForceRep)
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
function BattleOccupyStep:UpdateScore(nDeltaTime, bForceRep)
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

function BattleOccupyStep:AreaInfoMarkDirty(rInfo)
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

function BattleOccupyStep:UpdateAreaInfo(bNeedRefresh, bRepNow)
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
        
        log("BattleOccupyStep:LeaveArea", tbArea.nTriggerId, nTeamId, nUniqueId)
        tbArea.tbSM:OnLeave(nUniqueId, nTeamId)
        return true
    end
    return false
end

local function TryEnterArea(self, tbArea, nUniqueId, nTeamId)
    if(tbArea.tbUniqueIds 
        and tbArea.tbUniqueIds[nUniqueId]
        and tbArea.tbSM.tbIds[nUniqueId] == nil) then
        
        log("BattleOccupyStep:EnterArea", tbArea.nTriggerId, nTeamId, nUniqueId)
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
    if tbAreaInfos[self.nAreaTriggerId] and TryLeaveArea(self, tbAreaInfos[self.nAreaTriggerId], nUniqueId, nTeamId) then
        return
    end
end

local function TryEnterOtherArea(self, tbGameObject)
    local nUniqueId = tbGameObject.nUniqueId
    local tbAreaInfos = self.tbAreaInfos
    local nTeamId = tbGameObject.BattleTeamComponent.nTeamId

    -- 根据优先级进入，最内圈的先进
    if tbAreaInfos[self.nAreaTriggerId] and TryEnterArea(self, tbAreaInfos[self.nAreaTriggerId], nUniqueId, nTeamId) then
        return
    end 
end

function BattleOccupyStep:OnActorEnterArea(tbGameTrigger, tbGameObject)
    -- 玩家死亡后创建Trigger,则不算玩家进入圈内,此处需注意
    if tbGameObject and tbGameObject:IsDead() then
        return
    end
    local nTriggerId = tbGameTrigger.nTriggerId
    if self.nAreaTriggerId ~= nTriggerId then
        return
    end
    if(BattleTeamSystem:FindTeamId(tbGameObject) < 0) then
        return
    end

    local tbAreaInfo = self.tbAreaInfos[nTriggerId]
    local nUniqueId = tbGameObject.nUniqueId
    if(tbGameObject.BattleTeamComponent == nil) then
        error("BattleOccupyStep:OnActorEnterArea failed, BattleTeamComponent is invalid " .. nUniqueId)
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

function BattleOccupyStep:OnActorLeaveArea(tbGameTrigger, tbGameObject)    
    local nTriggerId = tbGameTrigger.nTriggerId
    if self.nAreaTriggerId ~= nTriggerId then
        return
    end
    if(BattleTeamSystem:FindTeamId(tbGameObject) < 0) then
        return
    end

    local tbAreaInfo = self.tbAreaInfos[nTriggerId]
    local nUniqueId = tbGameObject.nUniqueId
    if(tbGameObject.BattleTeamComponent == nil) then
        error("BattleOccupyStep:OnActorEnterArea failed, BattleTeamComponent is invalid " .. nUniqueId)
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

function BattleOccupyStep:OnPawnDead(tbDeadObject)
    local tbKillObject = nil--tbDeadObject.BattleStatusComponent:GetLastDamageCauser()
    if(BattleTeamSystem:FindTeamId(tbDeadObject) < 0) then
        return
    end
    log("BattleOccupyStep:OnPawnDead")

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
        logerror("BattleOccupyStep:OnPawnDead error, can not find dead teamid", nTeamId, nUniqueId)
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
            logerror("BattleOccupyStep:OnPawnDead error, can not find kill teamid", nTeamId, nUniqueId)
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

    -- -- 设置死亡状态
    -- if tbDeadObject.ObjectType == GameObjectTypeDef.PlayerSelf then
    --     EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, BattleReviveModeTypeDef.Reset, tbDeadObject)
    -- end
end

function BattleOccupyStep:OnAreaStateChanged(tbRepData, tbFromState, tbToState)
    local nTeamId = tbRepData.nOwnerTeamId
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_OCCUPY_TYPE_CHANGE, tbToState.nState, self.tbTeamCampType[nTeamId] )
    
    -- RepNow
    if tbFromState.nState ~= Proto.PVPOccupyAreaInfo_OccupyState.OCCUPIED
        and tbToState.nState == Proto.PVPOccupyAreaInfo_OccupyState.OCCUPIED then
        assert(nTeamId ~= -1)   

        local tbTeamScores = self.rTeamScores.TeamScores
        local tbTeamScore = FindTeamScore(tbTeamScores, nTeamId)
        if(tbTeamScore == nil) then
            logerror("BattleOccupyStep:OnAreaStateChanged error, can not find state changed teamid", nTeamId)
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

function BattleOccupyStep:BindHitEvent(tbGameObject)
    if tbGameObject.DelegateComponent then
        self.SelfEventHelper:RegisterLuaDelegate(tbGameObject.DelegateComponent.OnHitByCannon, function(...) PunishOccupyTime(tbGameObject, self.GetPunishOccupyTimeCannon, ...) end, self)
        self.SelfEventHelper:RegisterLuaDelegate(tbGameObject.DelegateComponent.OnHitByTorpedo, function(...) PunishOccupyTime(tbGameObject, self.GetPunishOccupyTimeTorpedo, ...) end, self)
    end
end

function BattleOccupyStep:OnGameObjectPostActorCreate(tbGameObject)
    self:BindHitEvent(tbGameObject)
end

-- 转换每秒计分速度
function BattleOccupyStep:GetScoreVelocity(nTriggerId)
    if(nTriggerId == self.nAreaTriggerId) then
        return self.nAreaScore
    end
    return self.nAreaOutScore    
end

-- 获取占领时间
function BattleOccupyStep:GetOccupyMaxTime(nTriggerId)    
    if(nTriggerId == self.nAreaTriggerId) then
        return self.nAreaOccupyTime
    end
    assert(false)
    return 0
end

function BattleOccupyStep:GetAreaIndex(nTriggerId)
    if(nTriggerId == self.nAreaTriggerId) then
        return AREA1_INDEX
    end
    assert(false)
    return 0
end

function BattleOccupyStep:GetTriggerId(nAreaIndex)
    if(nAreaIndex == AREA1_INDEX) then
        return self.nAreaTriggerId
    end
    assert(false)
    return 0
end

function BattleOccupyStep:GetOccupyScore(nTriggerId)
    if(nTriggerId == self.nAreaTriggerId) then
        return self.nAreaOccupyScore
    end
    assert(false)
    return 0
end

function BattleOccupyStep:GetPunishOccupyTimeCannon(nTriggerId)
    if(nTriggerId == self.nAreaTriggerId) then
        return self.nAreaPunishOccupyTimeCannon
    end
    assert(false)
    return 0
end

function BattleOccupyStep:GetPunishOccupyTimeTorpedo(nTriggerId)
    if(nTriggerId == self.nAreaTriggerId) then
        return self.nAreaPunishOccupyTimeTorpedo
    end
    assert(false)
    return 0
end

function BattleOccupyStep:Uninit()
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

    BattleOccupyStep.super.Uninit(self)
end

return BattleOccupyStep
