local luaclass = require("luaclass")
local BattleStepBase = luaclass("BattleStepBase")

local SelfEventHelperClass = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local Proto = require("DungeonRepProtoNames")
local BattleOperationHelper = require("BattleOperationHelper")

local ProtoStartState = Proto.rCurrentStepInfo_State.STARTED
local ProtoInProgressState = Proto.rCurrentStepInfo_State.IN_PROGRESS
local ProtoCompleteState = Proto.rCurrentStepInfo_State.COMPLETED

BattleStepBase.tbTargets = nil
BattleStepBase.SelfEventHelper = nil
BattleStepBase.nStepId = -1
BattleStepBase.bCompleted = false
BattleStepBase.bStarted = false
BattleStepBase.fnCompleteCheckFunc = nil
BattleStepBase.fnCompleteCallback = nil
BattleStepBase.rCurrentStepInfo = nil
BattleStepBase.szName = nil


function BattleStepBase:Init()
    self.tbTargets = {}
    self.SelfEventHelper = SelfEventHelperClass()
    self.fnCompleteCheckFunc = function(Class, BattleTarget)
        return self:CheckComplete(BattleTarget)
    end
end

function BattleStepBase:Uninit()
    self:UnregisterEvent()
    local tbTargets = self.tbTargets
    if tbTargets then
        local nCount = #tbTargets
        for i=1, nCount do
            tbTargets[i]:Uninit()
        end
        self.tbTargets = nil
        self.fnCompleteCheckFunc = nil
        self.fnCompleteCallback = nil
    end
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function BattleStepBase:SnapshotToReplicatedProperty()
    error("BattleStepBase:SnapshotToReplicatedProperty failed, the derived class must override this function " .. self.szName .. ", ".. self.nStepId)
    return false
end

function BattleStepBase:SetReplicatedStepInfo(rCurrentStepInfo)
    self.rCurrentStepInfo = rCurrentStepInfo
end

function BattleStepBase:OnStarted()
end

function BattleStepBase:Start()
    BattleOperationHelper:PrintLog(self, "Start, StepId: "..self.nStepId)

    self:RegisterEvent()
    self.bStarted = true
    self.bCompleted = false

     -- Start强制replicate
    self:SetStepReplicatedState(ProtoStartState, true)
     -- rep后在设成inprogress，这样后进来的玩家同步后会收到IN_PROGRESS
    self:SetStepReplicatedState(ProtoInProgressState, false)

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_STEP_START, self)
    -- 先同步step消息
    self:OnStarted()

    -- Start完被强停了
    if(not self.bStarted) then
        return
    end

    -- 有可能Target一起来就结束了，所以这里放到了最后
    local tbTargets = self.tbTargets
    local i = 1
    while(i <= #tbTargets) do
        tbTargets[i]:Start()
        i = i + 1
    end
end

function BattleStepBase:OnCompleted()
end

function BattleStepBase:Complete()
    BattleOperationHelper:PrintLog(self, "Complete, StepId: "..self.nStepId)
    self.bCompleted = true
    self:UnregisterEvent()
    self:OnCompleted()

    -- Complete完被强停了
    if(not self.bStarted) then
        return
    end

    self:SetStepReplicatedState(ProtoCompleteState, true)
    if(self.fnCompleteCallback) then
        self.fnCompleteCallback(self)
    end
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_STEP_COMPLETE, self)
end

function BattleStepBase:AddTarget(Target)
    table.insert(self.tbTargets, Target)
    Target:SetCompleteCallback(function(TempTarget) self:OnTargetComplete(TempTarget) end)
end

function BattleStepBase:CreateTarget(TargetClass)
    local Target = TargetClass()
    Target:Init()
    self:AddTarget(Target)
    return Target
end

function BattleStepBase:DestroyTarget(Target)
    local tbTargets = self.tbTargets
    if tbTargets then
        local nCount = #tbTargets
        for i=1, nCount do
            if(tbTargets[i] == Target) then
                Target:SetCompleteCallback(nil)
                table.remove(tbTargets, i)
                break
            end
        end
    end
end

function BattleStepBase:OnTargetComplete(BattleTarget)
    if(self.fnCompleteCheckFunc(self, BattleTarget)) then
        self:Complete()
    end
end

function BattleStepBase:OnForceStop()

end

function BattleStepBase:ForceStop()
    local tbTargets = self.tbTargets
    if tbTargets then
        local nCount = #tbTargets
        for i=1, nCount do
            tbTargets[i]:ForceStop()
        end
    end
    -- 这里怕直接Complete会有问题，所以不调用Complete
    if(not self.bCompleted and self.bStarted) then
        BattleOperationHelper:PrintLog(self, "ForceStop, StepId: "..self.nStepId)
        self:UnregisterEvent()
        self:OnForceStop()
        self.bStarted = false
    end
end

function BattleStepBase:IsStarted()
    return self.bStarted
end

function BattleStepBase:IsCompleted()
    return self.bCompleted
end

function BattleStepBase:Reset()
    self.bStarted = false
    self.bCompleted = false
end

function BattleStepBase:CheckComplete(BattleTarget)
    local tbTargets = self.tbTargets
    if tbTargets then
        local nCount = #tbTargets
        for i=1, nCount do
            if(not tbTargets[i].bCompleted) then
                return false
            end
        end
    end
    return true
end

function BattleStepBase:SetCompleteCheckFunc(fnCallback)
    self.fnCompleteCheckFunc = fnCallback
end

function BattleStepBase:SetCompleteCallback(fnCallback)
    self.fnCompleteCallback = fnCallback
end

function BattleStepBase:RegisterEvent()
    --self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_TARGET_COMPLETE, self, self.OnTargetComplete)
end

function BattleStepBase:UnregisterEvent()
    self.SelfEventHelper:UnregisterAll()
    local tbTargets = self.tbTargets
    if tbTargets then
        local nCount = #tbTargets
        for i=1, nCount do
            tbTargets[i]:UnregisterEvent()
        end
    end
end

function BattleStepBase:SetStepReplicatedState(nState, bRepNow)
    local rCurrentStepInfo = self.rCurrentStepInfo
    if(rCurrentStepInfo == nil) then
        return
    end

    rCurrentStepInfo.nStepId = self.nStepId
    rCurrentStepInfo.nState = nState
    self:RepStepInfo(bRepNow)
end

-- 同步Step信息
function BattleStepBase:RepStepInfo(bRepNow)
    local rCurrentStepInfo = self.rCurrentStepInfo
    if(rCurrentStepInfo) then
        if(bRepNow) then
            rCurrentStepInfo.RepNow()
        else
            rCurrentStepInfo.Rep()
        end
    end
end

function BattleStepBase:OnPlayerLogin(tbGamePlayer)
end

function BattleStepBase:OnPlayerReLogin(tbGamePlayer)
end

function BattleStepBase:OnPlayerLogout(tbGamePlayer)
end

function BattleStepBase:GetDebugInfo()
    local tbRet = {}
    tbRet.nStepId = self.nStepId
    return tbRet
end

return BattleStepBase
