local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local BattleLoopStep = luaclass("BattleLoopStep", BattleTargetActionStep)

local BattleOperationHelper = require("BattleOperationHelper")

BattleLoopStep.tbSteps = nil
BattleLoopStep.LoopFinishedAction = nil
BattleLoopStep.bAllStepFinished = false
BattleLoopStep.bParrallel = false
BattleLoopStep.nLoopCount = 0
BattleLoopStep.nCurrentIndex = 0

function BattleLoopStep:Init()
    BattleLoopStep.super.Init(self)
    self.szName = "BattleLoopStep"
end

function BattleLoopStep:Uninit()
    if(self.tbSteps) then
        for i, v in ipairs(self.tbSteps) do
            v:Uninit()
        end
    end
    BattleLoopStep.super.Uninit(self)
end

function BattleLoopStep:ForceStop()
    BattleLoopStep.super.ForceStop(self)

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

    if(self.bParrallel) then
        local nCount = 0
        for i, tbStep in ipairs(self.tbSteps) do
            if(tbStep:IsCompleted()) then
                nCount = nCount + 1
            end
        end
        if(nCount < #self.tbSteps) then
            return
        end
    else
        local nCurrentIndex = self.nCurrentIndex
        nCurrentIndex = nCurrentIndex + 1
        self.nCurrentIndex = nCurrentIndex
        if(nCurrentIndex <= #self.tbSteps) then
            self.tbSteps[nCurrentIndex]:Start()
            return
        end
    end

    self.bAllStepFinished = true
    self:Complete()
end

function BattleLoopStep:Parse(tbJsonData)
    if(not BattleLoopStep.super.Parse(self, tbJsonData)) then
        return false
    end

    local tbSteps = {}
    self.tbSteps = tbSteps
    local StepData = tbJsonData.Step
    self.nLoopCount = tbJsonData.LoopCount
    self.bParrallel = tbJsonData.Parrallel
    for i=1, self.nLoopCount do
        local SingleStep = BattleOperationHelper:Create(self, StepData)
        if(SingleStep == nil) then
            BattleOperationHelper:PrintError(self, "Step"..i.." parse failed.")
            return false
        end
        table.insert(tbSteps, SingleStep)
        SingleStep:SetCompleteCallback(function(Step) OnSubStepEnd(self, Step) end)
    end

    local FinishedActionData = tbJsonData.LoopFinishedAction
    if(FinishedActionData and #self.tbSteps > 0) then
        self.LoopFinishedAction = BattleOperationHelper:Create(self, FinishedActionData)
        self:AddAction(self.LoopFinishedAction)
    end

    return true
end

function BattleLoopStep:Start()
    BattleLoopStep.super.Start(self)

    self.nCurrentIndex = 1
    self.nFinishedCount = 0
    self.bAllStepFinished = false
    local tbSteps = self.tbSteps
    if(not self:IsCompleted() and #tbSteps > 0) then
        if(self.bParrallel) then
            for i, Step in ipairs(tbSteps) do
                Step:Reset()
            end
            for i, Step in ipairs(tbSteps) do
                Step:Start()
                if(self:IsCompleted()) then
                    break
                end
            end
        else
            tbSteps[1]:Start()
        end
    end
end

function BattleLoopStep:OnCompleted()
    BattleLoopStep.super.OnCompleted(self)
    if(self.bAllStepFinished) then
        self:DoAction("LoopFinishedAction")
    end

    -- 把子节点都强停掉
    self:ForceStop()
end

return BattleLoopStep