local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local BattleConditionStep = luaclass("BattleConditionStep", BattleTargetActionStep)

local BattleOperationHelper = require("BattleOperationHelper")

BattleConditionStep.Condition = nil
BattleConditionStep.TrueStep = nil
BattleConditionStep.FalseStep = nil

function BattleConditionStep:Init()
    BattleConditionStep.super.Init(self)
    self.szName = "BattleConditionStep"
end

local function OnSubStepEnd(self, Step)
    self:Complete()
end

function BattleConditionStep:Parse(tbJsonData)
    if(not BattleConditionStep.super.Parse(self, tbJsonData)) then
        return false
    end

    local Data = tbJsonData.Condition
    if(Data == nil) then
        BattleOperationHelper:PrintError(self, "BattleConditionStep:Parse failed, condition is nil")
        return false
    end
    self.Condition = BattleOperationHelper:Create(self, Data)
    if(self.Condition == nil) then
        BattleOperationHelper:PrintError(self, 
            "BattleConditionStep:Parse failed, the condition cannot be created: "..Data.OperationName)
        return false
    end

    if(tbJsonData.TrueStep) then
        self.TrueStep = BattleOperationHelper:Create(self, tbJsonData.TrueStep)
    end
    if(tbJsonData.FalseStep) then
        self.FalseStep = BattleOperationHelper:Create(self, tbJsonData.FalseStep)
    end    
    return self.TrueStep ~= nil or self.FalseStep ~= nil
end

function BattleConditionStep:Start()
    BattleConditionStep.super.Start(self)
    
    if(self.Condition) then
        local bRet = self.Condition:Execute()
        BattleOperationHelper:PrintLog(self, "Execute Condition: "..(bRet and "true" or "false"))
        local StepToExecute
        if(bRet) then
            StepToExecute = self.TrueStep
        else
            StepToExecute = self.FalseStep
        end
        if(StepToExecute) then
            StepToExecute:SetCompleteCallback(function(Step) OnSubStepEnd(self, Step) end)
            StepToExecute:Start()
        end
    end
end

function BattleConditionStep:Uninit()
    if(self.TrueStep) then
        self.TrueStep:Uninit()
    end
    if(self.FalseStep) then
        self.FalseStep:Uninit()
    end
    BattleConditionStep.super.Uninit(self)
end

function BattleConditionStep:ForceStop()
    if(self.TrueStep) then
        self.TrueStep:ForceStop()
    end
    if(self.FalseStep) then
        self.FalseStep:ForceStop()
    end
    BattleConditionStep.super.ForceStop(self)
end

return BattleConditionStep