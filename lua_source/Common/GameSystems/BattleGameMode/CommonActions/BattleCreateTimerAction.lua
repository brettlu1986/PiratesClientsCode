local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleCreateTimerAction = luaclass("BattleCreateTimerAction", BattleActionBase)

local BattleTimerHelper = require("BattleTimerHelper")
local BattleOperationHelper = require("BattleOperationHelper")

BattleCreateTimerAction.szTimerName = nil
BattleCreateTimerAction.fTime = 0

function BattleCreateTimerAction:Parse(tbJsonData)
    local szTimerName = tbJsonData.TimerName
    self.szTimerName = szTimerName
    self.fTime = tbJsonData.Time

    if(szTimerName == nil or string.len(szTimerName) == 0) then
        BattleOperationHelper:PrintError(self, "Invalid TimerName")
        return false
    end
    if(self.fTime <= 0) then
        BattleOperationHelper:PrintError(self, "Invalid Time value")
        return false
    end
    
    return true
end

function BattleCreateTimerAction:Execute()
    BattleOperationHelper:PrintLog(self, "TimerName: "..self.szTimerName..", Time: "..self.fTime)

    return BattleTimerHelper:CreateTimer(self.szTimerName, nil, self.fTime)    
end

function BattleCreateTimerAction:Uninit()
    BattleTimerHelper:DestroyTimer(self.szTimerName)
    BattleCreateTimerAction.super.Uninit(self)
end

function BattleCreateTimerAction:ForceStop()
    BattleTimerHelper:DestroyTimer(self.szTimerName)
    BattleCreateTimerAction.super.ForceStop(self)
end

return BattleCreateTimerAction