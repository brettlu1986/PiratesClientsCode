--等待玩家进入step，过了时间并且有玩家就会结束

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local BattleMatineeStep = luaclass("BattleMatineeStep", BattleStepBaseClass)

local CommonEventDef = require("CommonEventDef")
local BattleInteractionHelper = require("BattleInteractionHelper")

BattleMatineeStep.nMatineeId = nil
BattleMatineeStep.bPause = nil

function BattleMatineeStep:Init()
    BattleMatineeStep.super.Init(self)

    self.szName = "BattleMatineeStep"
end

function BattleMatineeStep:Uninit()
    BattleMatineeStep.super.Uninit(self)
end

function BattleMatineeStep:SetParams(nMatineeId, bPause)
    self.nMatineeId = nMatineeId
    self.bPause = bPause
end

function BattleMatineeStep:OnBattleMatineeEnd()
    self:Complete()
end

function BattleMatineeStep:Start()
    BattleMatineeStep.super.Start(self)
    
    local nMatineeId = self.nMatineeId
    assert(nMatineeId ~= nil)
 
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_MATINEE_END, self, self.OnBattleMatineeEnd)
    BattleInteractionHelper:PlayMatinee(nMatineeId, false, self.bPause)
end

function BattleMatineeStep:Complete()
    BattleMatineeStep.super.Complete(self)
end

function BattleMatineeStep:CheckComplete(BattleTarget)
    return true
end

function BattleMatineeStep:RepStepInfo(bRepNow)
    BattleMatineeStep.super.RepStepInfo(self, bRepNow)
end

function BattleMatineeStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()
    return true
end

return BattleMatineeStep