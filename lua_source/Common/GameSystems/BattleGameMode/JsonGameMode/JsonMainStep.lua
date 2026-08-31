local luaclass = require("luaclass")
local BattleStepBase = require("BattleStepBase")
local JsonMainStep = luaclass("JsonMainStep", BattleStepBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleTimerTarget = require("BattleTimerTarget")
local Timer = require("Timer")

JsonMainStep.LaunchAction = nil
JsonMainStep.RunStep = nil
JsonMainStep.ExitAction = nil
JsonMainStep.TimerTarget = nil
JsonMainStep.Timer = nil
JsonMainStep.rStepRemainTime = nil
JsonMainStep.nUpdateInterval = 20     -- 同步间隔
JsonMainStep.nCanNotLeaveTime = nil
JsonMainStep.rJsonMainStepInfo = nil

function JsonMainStep:Init()
    JsonMainStep.super.Init(self)
    self.szName = "JsonMainStep"
end

function JsonMainStep:Parse(tbJsonData, tbGameState)
    local tbSetting = tbJsonData.Setting
    if(tbSetting.MatchTime ~= nil) then 
        self.TimerTarget = self:CreateTarget(BattleTimerTarget)
        self.TimerTarget:SetTime(tbSetting.MatchTime)
        self.rStepRemainTime = tbGameState.rStepRemainTime
    end
    if(tbSetting.CanNotLeaveTime ~= nil) then 
        self.rJsonMainStepInfo = tbGameState.rJsonMainStepInfo
        self.rJsonMainStepInfo.bCanNotLeaveDungeon = true
        self.nCanNotLeaveTime = tbSetting.CanNotLeaveTime
    end
    
    local tbLaunchData = tbJsonData.LaunchAction
    if(tbLaunchData) then
        self.LaunchAction = BattleOperationHelper:Create(self, tbLaunchData)
    end

    local tbRunStepData = tbJsonData.RunStep
    if(tbRunStepData) then
        self.RunStep = BattleOperationHelper:Create(self, tbRunStepData)
    end

    local tbExitData = tbJsonData.ExitAction
    if(tbExitData) then
        self.ExitAction = BattleOperationHelper:Create(self, tbExitData)
    end

    return true
end

local function OnRunStepEnd(self)
    self:Complete()
end

function JsonMainStep:Update()
    local nNewRemainTime = self.TimerTarget:GetRemainTime()
    local nDeltaTime = self.rStepRemainTime.nTime - nNewRemainTime
    if(nDeltaTime < 0) then
        logerror("JsonMainStep:Update failed, the delta time is less then zero.", nDeltaTime)
        return
    end
    self.rStepRemainTime.nTime = self.rStepRemainTime.nTime - nDeltaTime
    self.rStepRemainTime.Rep()
    -- 设置可离开副本
    if self.nCanNotLeaveTime ~= nil then 
        local nElapsedTime = self.TimerTarget:GetElapsedTime()
        if nElapsedTime > self.nCanNotLeaveTime then
            self.rJsonMainStepInfo.bCanNotLeaveDungeon = false
            self.rJsonMainStepInfo.Rep()
        end
    end
end

function JsonMainStep:OnStarted()
    JsonMainStep.super.OnStarted(self)

    if(self.TimerTarget) then 
        self.rStepRemainTime.nTime = self.TimerTarget.nMaxTime  
        self.rStepRemainTime.Rep()
        self.Timer = Timer.NewTimerMethod(self, self.Update, self.nUpdateInterval, true)
    end
    
    if(self.LaunchAction) then
        if(false == self.LaunchAction:Execute()) then
            BattleOperationHelper:PrintError("LaunchAction execute failed.")
            return
        end
    end

    local RunStep = self.RunStep
    if(RunStep) then
        RunStep:SetCompleteCallback(function(Step) OnRunStepEnd(self) end)
        RunStep:Start()
    end
end

function JsonMainStep:Complete()
    if(self.ExitAction) then
        if(false == self.ExitAction:Execute()) then
            BattleOperationHelper:PrintError("ExitAction execute failed.")
            return
        end
    end

    if(self.Timer) then
        self.Timer:Clear()
        self.Timer = nil
    end

    self.RunStep:ForceStop()
    JsonMainStep.super.Complete(self)
end

function JsonMainStep:ForceStop()    
    self.RunStep:ForceStop()

    JsonMainStep.super.ForceStop(self)
end

function JsonMainStep:Uninit()    
    if(self.Timer) then
        self.Timer:Clear()
        self.Timer = nil
    end
    self.RunStep:Uninit()
    JsonMainStep.super.Uninit(self)
end

-- 同步Step信息
function JsonMainStep:RepStepInfo(bRepNow)    
    JsonMainStep.super.RepStepInfo(self, bRepNow)

    if self.nCanNotLeaveTime ~= nil then 
        if(bRepNow) then
            self.rJsonMainStepInfo.RepNow()
        else
            self.rJsonMainStepInfo.Rep()
        end
    end

    if self.rStepRemainTime ~= nil then 
        if(bRepNow) then
            self.rStepRemainTime.RepNow()
        else
            self.rStepRemainTime.Rep()
        end

    end
end

function JsonMainStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()
    return true
end

return JsonMainStep