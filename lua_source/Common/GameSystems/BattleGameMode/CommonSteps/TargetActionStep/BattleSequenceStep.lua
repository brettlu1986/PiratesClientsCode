local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local BattleSequenceStep = luaclass("BattleSequenceStep", BattleTargetActionStep)

local BattleOperationHelper = require("BattleOperationHelper")

BattleSequenceStep.tbSteps = nil
BattleSequenceStep.FinishedAction = nil
BattleSequenceStep.SequenceFinishedAction = nil
BattleSequenceStep.nCurrentIndex = 1

function BattleSequenceStep:Init()
    BattleSequenceStep.super.Init(self)
    self.szName = "BattleSequenceStep"
end

function BattleSequenceStep:Uninit()
    if(self.tbSteps) then
        for i, v in ipairs(self.tbSteps) do
            v:Uninit()
        end
    end
    BattleSequenceStep.super.Uninit(self)
end

function BattleSequenceStep:ForceStop()
    BattleSequenceStep.super.ForceStop(self)

    if(self.tbSteps) then
        for i, v in ipairs(self.tbSteps) do
            v:ForceStop()
        end
    end 
end

local function OnSubStepEnd(self, Step)
    if(not self.bStarted) then
        return
    end
    if(self:IsCompleted()) then
        return
    end
    
    local tbSteps = self.tbSteps
    local nCurrentIndex = self.nCurrentIndex
    assert(Step == tbSteps[nCurrentIndex])
    BattleOperationHelper:PrintLog(self, "SubStep"..nCurrentIndex.." finished.")

    nCurrentIndex = nCurrentIndex + 1
    self.nCurrentIndex = nCurrentIndex
    if(nCurrentIndex <= #tbSteps) then
        tbSteps[nCurrentIndex]:Start()
    else
        self:Complete()    
    end 
end

function BattleSequenceStep:Parse(tbJsonData)
    if(not BattleSequenceStep.super.Parse(self, tbJsonData)) then
        return false
    end

    local tbSteps = {}
    self.tbSteps = tbSteps
    local tbStepData = tbJsonData.Steps
    local SingleStep
    for i, StepData in ipairs(tbStepData) do
        SingleStep = BattleOperationHelper:Create(self, StepData)
        if(SingleStep == nil) then
            BattleOperationHelper:PrintError(self, "Step"..i.." parse failed.")
            return false
        end
        SingleStep.szName = "SubStep"..i.."_InSequence"
        SingleStep:SetCompleteCallback(function(Step) OnSubStepEnd(self, Step) end)
        table.insert(tbSteps, SingleStep)
    end

    local FinishedActionData = tbJsonData.SequenceFinishedAction
    if(FinishedActionData and #self.tbSteps > 0) then
        self.SequenceFinishedAction = BattleOperationHelper:Create(self, FinishedActionData)
        self:AddAction(self.SequenceFinishedAction)
    end

    return true
end

function BattleSequenceStep:Start()
    BattleSequenceStep.super.Start(self)

    self.nCurrentIndex = 1
    if(not self:IsCompleted() and #self.tbSteps > 0) then
        self.tbSteps[1]:Start()
    end
end

function BattleSequenceStep:OnCompleted()
    BattleSequenceStep.super.OnCompleted(self)
    if(self.nCurrentIndex > #self.tbSteps) then
        self:DoAction("SequenceFinishedAction")
    end

    -- 把子节点都强停掉
    self:ForceStop()    
end

return BattleSequenceStep