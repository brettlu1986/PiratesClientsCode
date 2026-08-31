local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleWaitingStepTarget = luaclass("BattleWaitingStepTarget", BattleTargetBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

BattleWaitingStepTarget.tbSteps = nil
BattleWaitingStepTarget.nFinishedCount = 0

function BattleWaitingStepTarget:Init()
    BattleWaitingStepTarget.super.Init(self)
    self.szName = "BattleWaitingStepTarget"
    self.tbSteps = {}
end

function BattleWaitingStepTarget:SetFinishedCount(nCount)
    self.nFinishedCount = nCount
end

function BattleWaitingStepTarget:AddStep(Step)
    self.tbSteps[Step] = true
end

function BattleWaitingStepTarget:RemoveStep(Step)
    self.tbSteps[Step] = nil    
end

function BattleWaitingStepTarget:RemoveAll()
    self.tbSteps = {}
end

function BattleWaitingStepTarget:Start()
    local nCount = 0
    for Step, _ in pairs(self.tbSteps) do
        nCount = nCount + 1
    end
    if(self.nFinishedCount <= 0) then
        self.nFinishedCount = nCount
    elseif(self.nFinishedCount > nCount) then
        self.nFinishedCount = nCount
    end
    BattleWaitingStepTarget.super.Start(self)
end

function BattleWaitingStepTarget:Complete()
    self:RemoveAll()
    self.nFinishedCount = 0
    BattleWaitingStepTarget.super.Complete(self)
end

local function OnStepCompleted(self, Step)
    local tbSteps = self.tbSteps
    if(tbSteps[Step]) then
        local nCount = 0
        for tbStep, _ in pairs(tbSteps) do
            if(tbStep:IsCompleted()) then
                nCount = nCount + 1
            end
        end
        if(nCount >= self.nFinishedCount) then
            self:Complete()
        end
    end
end

function BattleWaitingStepTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_STEP_COMPLETE, self, OnStepCompleted)
end

function BattleWaitingStepTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_STEP_COMPLETE, self, OnStepCompleted)
end

return BattleWaitingStepTarget