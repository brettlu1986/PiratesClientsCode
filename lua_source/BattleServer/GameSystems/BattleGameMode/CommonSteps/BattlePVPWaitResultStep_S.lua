-- 输赢结果结算

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local BattlePVPWaitResultStep_S = luaclass("BattlePVPWaitResultStep_S", BattleStepBaseClass)
local BattleTimerTargetClass = require("BattleTimerTarget")

BattlePVPWaitResultStep_S.TimerTarget = nil

function BattlePVPWaitResultStep_S:Init()
    BattlePVPWaitResultStep_S.super.Init(self)

    self.szName = "BattlePVPWaitResultStep_S"
    self.TimerTarget = self:CreateTarget(BattleTimerTargetClass)
end

function BattlePVPWaitResultStep_S:SetParams(nTime)
    self.TimerTarget:SetTime(nTime)
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function BattlePVPWaitResultStep_S:SnapshotToReplicatedProperty()
    -- self:RepStepInfo()
    return true
end

return BattlePVPWaitResultStep_S
