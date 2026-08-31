-- 探险者副本

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local SocietyPrivateerStep = luaclass("SocietyPrivateerStep", BattleStepBaseClass)
local GameObjectTypeDef = require("GameObjectTypeDef")
local Timer = require("Timer")
local CommonEventDef = require("CommonEventDef")
local BattleTeamSystem = require("BattleTeamSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local SpawnerSystem = require("SpawnerSystem")
local GroupDeadTargetClass = require("BattleNpcGroupDeadTarget")
local CampDef = require("CampDefine")
local StringUtil = require("StringUtil")
local BattleResultDef = require("BattleResultDef")
local SpawnerDef = require("SpawnerDef")

local szShotActorClass = '/Game/Game/Ships/Shot/ShotActors/BP_ShotActorBase.BP_ShotActorBase_C'

local PLAYER_WIN = BattleResultDef.WIN
local PLAYER_LOSE = BattleResultDef.LOSE

SocietyPrivateerStep.NpcGroupDeadTarget  = nil
SocietyPrivateerStep.rStepRemainTime = nil
SocietyPrivateerStep.tbAreaInfos = nil 
SocietyPrivateerStep.tbJsonData = nil
SocietyPrivateerStep.Spawners = nil

SocietyPrivateerStep.DebuffBallTriggerId = nil
SocietyPrivateerStep.DebuffId = nil
SocietyPrivateerStep.EscapeTriggerId = 0
SocietyPrivateerStep.EffectId = nil
SocietyPrivateerStep.ResId = nil
SocietyPrivateerStep.tbGameState = nil
SocietyPrivateerStep.TimerTrigger = nil
SocietyPrivateerStep.DebuffBallCD = 0
SocietyPrivateerStep.HeadHintDialogId = 0
SocietyPrivateerStep.EffectInfo = nil
SocietyPrivateerStep.TargetNpcId = 0
SocietyPrivateerStep.TargetGroupId = 0
SocietyPrivateerStep.MerchantShip = nil
SocietyPrivateerStep.TimerDialog = nil


function SocietyPrivateerStep:Init()
    SocietyPrivateerStep.super.Init(self)

    self.szName = "SocietyPrivateerStep"
    self.tbAreaInfos = {}
    self.Spawners = {}
    self.DebuffBallTriggerId = {}
    self.DebuffId = {}
    self.EffectId = {}
    self.ResId = {}
    self.TimerTrigger = {}
    self.TimerDialog = {}
    self.EffectInfo = {}
    self.MerchantShip = {}
    self.NpcGroupDeadTarget = self:CreateTarget(GroupDeadTargetClass)

end

function SocietyPrivateerStep:ParseConditionParam(szConditionParam)
    if not szConditionParam or string.len( szConditionParam ) <= 0 then 
        return nil 
    end 
    local tbTemp = StringUtil.Split(szConditionParam, ",")
    local tbRet = {}
    for i,v in ipairs(tbTemp) do
        table.insert(tbRet, tonumber(v))
    end
    return tbRet
end

function SocietyPrivateerStep:SetParams(tbGameState, tbTemplateData, tbJsonData)
    self.tbGameState = tbGameState
    self.rBattlePlayerResultStep = tbGameState.rBattlePlayerResultStep
    local rStep = self.rBattlePlayerResultStep
    rStep.nStepTime = tbTemplateData.nShowResultTime
    rStep.Results = {}    
    self.tbJsonData = tbJsonData
    self.DebuffBallTriggerId = self:ParseConditionParam(tbTemplateData.szDebuffBallTriggerId)
    self.EscapeTriggerId = tbTemplateData.nEscapeTriggerId
    self.DebuffId = self:ParseConditionParam(tbTemplateData.szDebuffId)
    self.EffectId = self:ParseConditionParam(tbTemplateData.szEffectId)
    self.ResId = self:ParseConditionParam(tbTemplateData.szResId)
    self.DebuffBallCD = tbTemplateData.nDebuffBallCD
    self.HeadHintDialogId = tbTemplateData.nHeadHintDialogId
    self.TargetNpcId = tbTemplateData.nTargetNpcId
    self.TargetGroupId = tbTemplateData.nTargetGroupId
end

function SocietyPrivateerStep:GetNextResIndexByBallId(nDebuffId)
    local tbDebuffAreaInfo = self.tbAreaInfos[nDebuffId]
    local nResId = tbDebuffAreaInfo.tbJson.ResId
    log("SocietyPrivateerStep:GetNextResIndexByBallId nResId",nResId)
    local nIndex = 0
    for k,v in ipairs(self.ResId) do
        if v == nResId then
            nIndex = k;
        end
    end
    log("SocietyPrivateerStep:GetNextResIndexByBallId nIndex",nIndex)
    return (nIndex % #self.ResId) + 1;
end

function SocietyPrivateerStep:CheckComplete(BattleTarget)
    return true
end

function SocietyPrivateerStep:Start()

    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_ENTER, self, self.OnActorEnterArea)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_TRIGGER_LEAVE, self, self.OnActorLeaveArea)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
  
    self:InitAreaInfo()
    -- 创建NPC
    -- self.Spawners = SpawnerSystem:GetAllSpawners()
    -- SpawnerSystem:SpawnAll()
    -- -- 只有商船所在的groupid计入 1艘商船
    -- self.NpcGroupDeadTarget:AddGroupInfo(self.TargetGroupId, CampDef.Type.CAMP_2, 1)
    
    SpawnerSystem:SpawnByGroupIndex(0, SpawnerDef.SpawnerType.ALL_NPC)
    self.MerchantShip = SpawnerSystem:SpawnByTemplateId(self.TargetNpcId)
    -- logerror("SocietyPrivateerStep:CreateNpc------------ ",self.MerchantShip.nTemplateId)
    -- 只有商船所在的groupid计入 1艘商船
    self.NpcGroupDeadTarget:AddGroupInfo(self.TargetGroupId, CampDef.Type.CAMP_2, 1)
  
    SocietyPrivateerStep.super.Start(self)

end

-- 清除计时器
function SocietyPrivateerStep:ClearTimer()
    for _, nTriggerId in pairs(self.DebuffBallTriggerId) do
        if( self.TimerTrigger[nTriggerId] ) then
            self.TimerTrigger[nTriggerId]:Clear()
            self.TimerTrigger[nTriggerId] = nil
        end
    end
    if self.TimerDialog then
        self.TimerDialog:Clear()
        self.TimerDialog = nil
    end
end

function SocietyPrivateerStep:Complete()
    self:ClearTimer()
    -- 结算
    log("SocietyPrivateerStep:Complete")
    self:CalculateResult()

    SocietyPrivateerStep.super.Complete(self)
end

-- 结算
function SocietyPrivateerStep:CalculateResult()
    local nResultType = PLAYER_LOSE
    local tbResults  = self.rBattlePlayerResultStep.Results
    if self.NpcGroupDeadTarget.bCompleted then
        nResultType = PLAYER_WIN
    end
    self.tbGameState.bWin = nResultType

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

function SocietyPrivateerStep:OnPawnDead(tbDeadObject)
    if tbDeadObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        self:Complete()
    end
end

function SocietyPrivateerStep:OnPlayerLogout(tbGamePlayer)
end

-- 需要清除timer 否则副本中途退出有问题
function SocietyPrivateerStep:Uninit()
    self:ClearTimer()
    SocietyPrivateerStep.super.Uninit(self)
end

-- 同步Step信息
function SocietyPrivateerStep:RepStepInfo(bRepNow)
    SocietyPrivateerStep.super.RepStepInfo(self, bRepNow)
end

function SocietyPrivateerStep:SnapshotToReplicatedProperty()
    return true
end

local function GetTableIndex(value, tbl)
    for k,v in ipairs(tbl) do
        if v == value then
            return k;
        end
    end
    return 0;
end

local function GetTableValueByIndex(index, tbl)
    if index > 0 then 
        if tbl[index] ~= nil then 
            return tbl[index]
        end
    end
    return 0;
end

-- 判定是子弹进入trigger
local function OnActorHit(self, pHitActor, nTriggerId)
    local tbGameObject
    tbGameObject = GameObjectSystem:FindByUEActor(pHitActor)
    if(tbGameObject == nil) then
        local pShotClass = szShotActorClass:load()
        if(KismetMathLibrary.ClassIsChildOf(GameplayStatics.GetObjectClass(pHitActor), pShotClass)) then
            local pOwnerActor = pHitActor:GetInstigator()
            tbGameObject = GameObjectSystem:FindByUEActor(pOwnerActor)
        end    
    end

    if(tbGameObject and tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf) then
        self:ChangeDeBuff(nTriggerId)
    end
end

local function IsInTable(value, tbl)
    for k,v in ipairs(tbl) do
        if v == value then
            return true;
        end
    end
    return false;
end

function SocietyPrivateerStep:InitAreaInfo()
    local tbAreaInfos = {}
    self.tbAreaInfos = tbAreaInfos

    local tbTriggers = self.tbJsonData.tbContainer.Triggers
    if tbTriggers == nil then
       return 
    end
    local tbJson, tbAreaInfo, nTriggerId
    local nCount = #tbTriggers
    for i=1, nCount do
        tbAreaInfo = {}
        tbJson = tbTriggers[i]
        nTriggerId = tbJson.TriggerId
        tbAreaInfo.nTriggerId = tbJson.TriggerId
        tbAreaInfo.tbJson = tbJson
        tbAreaInfo.Shape = tbJson.Shape
        tbAreaInfo.ResId = tbJson.ResId
        -- ball的cd标识
        tbAreaInfo.CanTrigger = true
        local tbData = {tbJsonData = tbJson}
        local tbTrigger = GameObjectSystem:CreateTriggerInGameMode(tbData)
        tbAreaInfo.BallUniqueId = tbTrigger:GetUEActorUniqueId()

        if IsInTable(tbJson.TriggerId, self.DebuffBallTriggerId) then
            self:SetBallTrigger(tbTrigger)
        end
        tbAreaInfos[nTriggerId] = tbAreaInfo
    end
end

function SocietyPrivateerStep:InitPlayerInfo()
end

-- 激活debuff区域
function SocietyPrivateerStep:SetBallTrigger(tbTrigger)
    tbTrigger.BattleTriggerComponent:EnableTriggerShot(true)
    local fnFunc = function(tbTriggerObject, pHitActor, nTriggerId)
        OnActorHit(self, pHitActor, nTriggerId)
    end
    tbTrigger.BattleTriggerComponent:SetActorEnterCallback(fnFunc)
end
-- function SocietyPrivateerStep:TimerDebuffBall()
--     local tbDebuffBallAreaInfo = self.tbAreaInfos[nTriggerId]
--     tbDebuffBallAreaInfo.CanTrigger = true
-- end
-- 改变debuff区域
function SocietyPrivateerStep:ChangeDeBuff(nTriggerId)
    log("SocietyPrivateerStep:ChangeDeBuff", nTriggerId)
    if IsInTable(nTriggerId, self.DebuffBallTriggerId) then
        -- 清除ball_trigger
        local tbDebuffBallAreaInfo = self.tbAreaInfos[nTriggerId]
        -- 判断ball是否在cd中
        log("SocietyPrivateerStep:CanTrigger:",self.tbAreaInfos[1].CanTrigger,  self.tbAreaInfos[4].CanTrigger,  self.tbAreaInfos[6].CanTrigger)
        if tbDebuffBallAreaInfo.CanTrigger ~= true then
            log("SocietyPrivateerStep:CanTrigger is false")
            return 
        end
        local TimerDebuffBall = function()
            tbDebuffBallAreaInfo.CanTrigger = true
        end
        -- 设置CD
        tbDebuffBallAreaInfo.CanTrigger = false
        self.TimerTrigger[nTriggerId] = Timer.NewTimer(TimerDebuffBall, self.DebuffBallCD, false)

        if tbDebuffBallAreaInfo.BallUniqueId ~= nil then 
            GameObjectSystem:DestroyTriggerInGameMode(tbDebuffBallAreaInfo.BallUniqueId)
        end 
        log("SocietyPrivateerStep:after CanTrigger:",self.tbAreaInfos[1].CanTrigger,  self.tbAreaInfos[4].CanTrigger,  self.tbAreaInfos[6].CanTrigger)
        -- 新建ball_triger
        local nResIndex = self:GetNextResIndexByBallId(nTriggerId)
        tbDebuffBallAreaInfo.tbJson.ResId = self.ResId[nResIndex]
        local tbData = {tbJsonData = tbDebuffBallAreaInfo.tbJson}
        local tbBallTrigger = GameObjectSystem:CreateTriggerInGameMode(tbData)
        tbDebuffBallAreaInfo.BallUniqueId = tbBallTrigger:GetUEActorUniqueId()
        self:SetBallTrigger(tbBallTrigger)
        
        -- 销毁新建debuff_trigger
        local nIndex = GetTableIndex(nTriggerId, self.DebuffBallTriggerId)
        local nDebuffId = GetTableValueByIndex(nIndex, self.DebuffId)
        -- 清除之前debuff效果
        if self.EffectInfo[nDebuffId] then 
            for key, info in ipairs(self.EffectInfo[nDebuffId]) do
                -- logerror("SocietyPrivateerStep:ChangeDeBuff RemoveStatusBuffById",info.nEffectId, info.tbGameObject, info.tbGameObject.BuffComponentServer)
                if info.tbGameObject.BuffComponentServer then 
                    info.tbGameObject.BuffComponentServer:RemoveBuffById(info.nEffectId)
                end
            end
            self.EffectInfo[nDebuffId] = {}
        end

        local tbDebuffAreaInfo = self.tbAreaInfos[nDebuffId]
        if tbDebuffAreaInfo.BallUniqueId ~= nil then 
            GameObjectSystem:DestroyTriggerInGameMode(tbDebuffAreaInfo.BallUniqueId)
        end 
        local nNextDebuffId = self.DebuffId[nResIndex]
        tbDebuffAreaInfo.tbJson.Shape = self.tbAreaInfos[nNextDebuffId].Shape
        tbDebuffAreaInfo.tbJson.ResId = self.tbAreaInfos[nNextDebuffId].ResId
        local tbBufferTriggerInfo = {tbJsonData = tbDebuffAreaInfo.tbJson}
        local tbBuffTrigger = GameObjectSystem:CreateTriggerInGameMode(tbBufferTriggerInfo)
        tbDebuffAreaInfo.BallUniqueId = tbBuffTrigger:GetUEActorUniqueId()

    end
end

function SocietyPrivateerStep:GetEffectIdByDebuffId(nDebuffId)
    local nIndex = GetTableIndex(nDebuffId, self.DebuffId)
    local nBallId = GetTableValueByIndex(nIndex, self.DebuffBallTriggerId)
    local nResId = self.tbAreaInfos[nBallId].tbJson.ResId
    local nEffectIndex = GetTableIndex(nResId, self.ResId)
    return self.EffectId[nEffectIndex]
end

-- debuff生效
function SocietyPrivateerStep:EffectDeBuff(nDebuffId, tbGameObject)
    log("SocietyPrivateerStep:EffectDeBuff", nDebuffId)
    -- tbGameObject生效debuff
    if tbGameObject and tbGameObject.BuffComponentServer then
        local nEffectId = self:GetEffectIdByDebuffId(nDebuffId)
        log("SocietyPrivateerStep:EffectDeBuff2", nDebuffId, nEffectId)
        tbGameObject.BuffComponentServer:AddBuffById(nEffectId)
        -- 存储生效buff和obj
        local info = {}
        info.nEffectId = nEffectId
        info.tbGameObject = tbGameObject
        self.EffectInfo[nDebuffId] = self.EffectInfo[nDebuffId] or {}
        table.insert(self.EffectInfo[nDebuffId], info)
    end
end

-- debuff清除
function SocietyPrivateerStep:CleanDeBuff(nDebuffId, tbGameObject)
    log("SocietyPrivateerStep:CleanDeBuff", nDebuffId)
    -- tbGameObject生效debuff
    if tbGameObject and tbGameObject.BuffComponentServer then
        local nEffectId = self:GetEffectIdByDebuffId(nDebuffId)
        log("SocietyPrivateerStep:CleanDeBuff", nDebuffId, nEffectId)
        tbGameObject.BuffComponentServer:RemoveBuffById(nEffectId)
    end
end

-- Npc逃跑 结算失败
function SocietyPrivateerStep:NPCEscaped()
    log("SocietyPrivateerStep:NPCEscaped")
    self:Complete()
end

function SocietyPrivateerStep:OnActorEnterArea(tbGameTrigger, tbGameObject)
    log("SocietyPrivateerStep:OnPawnEnterArea")
    local nTriggerId = tbGameTrigger.nTriggerId
    local tbAreaInfo = self.tbAreaInfos[nTriggerId]
 
    -- 如果是玩家撞击  tigger为ball则ChangeDeBuff
    if tbGameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
        if IsInTable(tbAreaInfo.nTriggerId, self.DebuffBallTriggerId) then
            self:ChangeDeBuff(tbAreaInfo.nTriggerId)
            return
        end 
        -- -- 测试
        -- if tbAreaInfo.nTriggerId == self.EscapeTriggerId then
        --     self:NPCEscaped()
        --     return
        -- end     
        -- if IsInTable(tbAreaInfo.nTriggerId, self.DebuffId) then
        --     self:EffectDeBuff(nTriggerId, tbGameObject)
        --     return
        -- end
        
    end

    -- 如果是NPC则判断tigger是否为escape_trigger,
    if tbGameObject.ObjectType == GameObjectTypeDef.Npc then
        if IsInTable(tbAreaInfo.nTriggerId, self.DebuffId) then
            self:EffectDeBuff(nTriggerId, tbGameObject)
            return
        end
        if tbAreaInfo.nTriggerId == self.EscapeTriggerId and self.TargetNpcId == tbGameObject.nTemplateId then
            self:NPCEscaped()
            return
        end
    end
end

function SocietyPrivateerStep:OnActorLeaveArea(tbGameTrigger, tbGameObject)
    log("SocietyPrivateerStep:OnPawnLeaveArea")    
    local nTriggerId = tbGameTrigger.nTriggerId
    local tbAreaInfo = self.tbAreaInfos[nTriggerId]
 
    -- 如果是NPC则判断tigger是否为escape_trigger,
    if tbGameObject.ObjectType == GameObjectTypeDef.Npc then
        if IsInTable(tbAreaInfo.nTriggerId, self.DebuffId) then
            self:CleanDeBuff(nTriggerId, tbGameObject)
            return
        end
    end
end


return SocietyPrivateerStep
