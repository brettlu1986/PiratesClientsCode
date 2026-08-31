local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleDestroyTimerAction = luaclass("BattleDestroyTimerAction", BattleActionBase)

local BattleTimerHelper = require("BattleTimerHelper")
local BattleOperationHelper = require("BattleOperationHelper")

BattleDestroyTimerAction.szTimerName = nil

function BattleDestroyTimerAction:Parse(tbJsonData)
    local szTimerName = tbJsonData.TimerName
    self.szTimerName = szTimerName

    if(szTimerName == nil or string.len(szTimerName) == 0) then
        BattleOperationHelper:PrintError(self, "Invalid TimerName")
        return false
    end
    
    return true
end

function BattleDestroyTimerAction:Execute()
    BattleOperationHelper:PrintLog(self, "TimerName: "..self.szTimerName)

    BattleTimerHelper:DestroyTimer(self.szTimerName)   
    return true 
end

return BattleDestroyTimerAction