-- 纯倒计时

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local BattleTimerStep = luaclass("BattleTimerStep", BattleStepBaseClass)

local BattleTimerTargetClass = require("BattleTimerTarget")

BattleTimerStep.TimerTarget = nil
BattleTimerStep.rTimeStepInfo = nil
BattleTimerStep.rStepRemainTime = nil

function BattleTimerStep:Init()
    BattleTimerStep.super.Init(self)

    self.szName = "BattleTimerStep"
    self.TimerTarget = self:CreateTarget(BattleTimerTargetClass)
end

function BattleTimerStep:SetParams(rTimeStepInfo, rStepRemainTime, nTime)
    self.rTimeStepInfo = rTimeStepInfo
    rTimeStepInfo.nStepTime = nTime
    self.rStepRemainTime = rStepRemainTime
    self.TimerTarget:SetTime(nTime)
end

function BattleTimerStep:RepStepInfo(bRepNow)
    if(bRepNow) then
        self.rTimeStepInfo.RepNow()
    else
        self.rTimeStepInfo.Rep()
    end
    BattleTimerStep.super.RepStepInfo(self, bRepNow)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function BattleTimerStep:SnapshotToReplicatedProperty()
    self:RepStepInfo()

    local rStepRemainTime = self.rStepRemainTime
    if(rStepRemainTime) then
        rStepRemainTime.nTime = self.TimerTarget:GetRemainTime()
        rStepRemainTime.Rep()
    end
    return true
end

return BattleTimerStep