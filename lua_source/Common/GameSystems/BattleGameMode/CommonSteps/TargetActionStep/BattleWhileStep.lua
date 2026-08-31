local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local BattleWhileStep = luaclass("BattleWhileStep", BattleTargetActionStep)

local BattleOperationHelper = require("BattleOperationHelper")

BattleWhileStep.Step = nil

function BattleWhileStep:Init()
    BattleWhileStep.super.Init(self)
    self.szName = "BattleWhileStep"
end

function BattleWhileStep:Uninit()
    if(self.Step) then
        self.Step:Uninit()
    end
    BattleWhileStep.super.Uninit(self)
end

function BattleWhileStep:ForceStop()
    BattleWhileStep.super.ForceStop(self)

    if(self.Step) then
        self.Step:ForceStop()
    end
end

local function OnSubStepEnd(self, Step)
    if(not self.bStarted) then
        return
    end

    if(self:IsCompleted()) then
        return
    end
    
    if(Step) then
        Step:Start()
    end
end

function BattleWhileStep:Parse(tbJsonData)
    if(not BattleWhileStep.super.Parse(self, tbJsonData)) then
        return false
    end

    local StepData = tbJsonData.Step
    local SingleStep = BattleOperationHelper:Create(self, StepData)
    if(SingleStep == nil) then
        BattleOperationHelper:PrintError(self, "Step parse failed.")
        return false
    end    
    SingleStep:SetCompleteCallback(function(Step) OnSubStepEnd(self, Step) end)
    self.Step = SingleStep
    return true
end

function BattleWhileStep:Start()
    BattleWhileStep.super.Start(self)

    if(self.Step) then
        self.Step:Start()
    end
end

function BattleWhileStep:OnCompleted()
    BattleWhileStep.super.OnCompleted(self)

    -- 把子节点都强停掉
    self:ForceStop()
end

return BattleWhileStep