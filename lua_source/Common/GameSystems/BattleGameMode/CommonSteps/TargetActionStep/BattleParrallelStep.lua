local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local BattleParrallelStep = luaclass("BattleParrallelStep", BattleTargetActionStep)
local BattleOperationHelper = require("BattleOperationHelper")

BattleParrallelStep.tbSteps = nil
BattleParrallelStep.ParrallelFinishedAction = nil
BattleParrallelStep.nFinishedCount = 0
BattleParrallelStep.bAllStepFinished = false

function BattleParrallelStep:Init()
    BattleParrallelStep.super.Init(self)
    self.szName = "BattleParrallelStep"
end

function BattleParrallelStep:Uninit()
    if(self.tbSteps) then
        for i, v in ipairs(self.tbSteps) do
            v:Uninit()
        end
    end
    BattleParrallelStep.super.Uninit(self)
end

function BattleParrallelStep:ForceStop()
    BattleParrallelStep.super.ForceStop(self)

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

    local nCount = 0
    for i, tbStep in ipairs(self.tbSteps) do
        if(tbStep:IsCompleted()) then
            nCount = nCount + 1
        end
    end

    if (self.nFinishedCount > 0 and nCount >= self.nFinishedCount) or nCount >= #self.tbSteps then
        self.bAllStepFinished = true
        self:Complete()
    end
end

function BattleParrallelStep:Parse(tbJsonData)
    if(not BattleParrallelStep.super.Parse(self, tbJsonData)) then
        return false
    end

    self.nFinishedCount = tbJsonData.FinishedCount
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
        table.insert(tbSteps, SingleStep)
        SingleStep:SetCompleteCallback(function(Step) OnSubStepEnd(self, Step) end)
    end

    local FinishedActionData = tbJsonData.ParrallelFinishedAction
    if(FinishedActionData and #self.tbSteps > 0) then
        self.ParrallelFinishedAction = BattleOperationHelper:Create(self, FinishedActionData)
        self:AddAction(self.ParrallelFinishedAction)
    end

    return true
end

function BattleParrallelStep:Start()
    BattleParrallelStep.super.Start(self)

    self.bAllStepFinished = false
    local tbSteps = self.tbSteps
    if(not self:IsCompleted() and #tbSteps > 0) then
        for i, Step in ipairs(tbSteps) do
            Step:Reset()
        end
        for i, Step in ipairs(tbSteps) do
            Step:Start()
            if(self:IsCompleted()) then
                break
            end
        end
    end
end

function BattleParrallelStep:OnCompleted()
    BattleParrallelStep.super.OnCompleted(self)
    if(self.bAllStepFinished) then
        self:DoAction("ParrallelFinishedAction")
    end

    -- 把子节点都强停掉
    self:ForceStop()
end

return BattleParrallelStep