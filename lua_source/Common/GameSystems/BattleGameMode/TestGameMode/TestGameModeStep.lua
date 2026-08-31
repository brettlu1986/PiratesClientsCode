local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local TestGameModeStep = luaclass("TestGameModeStep", BattleStepBaseClass)

function TestGameModeStep:Init()
    TestGameModeStep.super.Init(self)

    self.szName = "BattleTimerStep"
end

-- 子类必须重载，将当前状态的快照写入replicate属性中，这里可根据情况调用rep，这函数会在新玩家登入时调用
function TestGameModeStep:SnapshotToReplicatedProperty()
    return true
end

return TestGameModeStep