local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleHasTimerCondition = luaclass("BattleHasTimerCondition", BattleConditionBase)

local BattleTimerHelper = require("BattleTimerHelper")

BattleHasTimerCondition.szTimerName = nil

function BattleHasTimerCondition:Parse(tbJsonData)
    self.szTimerName = tbJsonData.TimerName
    return string.len(self.szTimerName) > 0
end

function BattleHasTimerCondition:Execute()
    return BattleTimerHelper:HasTimer(self.szTimerName)
end

return BattleHasTimerCondition