local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleCreateTimerBbAction = luaclass("BattleCreateTimerBbAction", BattleActionBase)

local BattleTimerHelper = require("BattleTimerHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")

BattleCreateTimerBbAction.szTimerName = nil
BattleCreateTimerBbAction.nTime = 0
BattleCreateTimerBbAction.szSetTimeKey = nil

function BattleCreateTimerBbAction:Parse(tbJsonData)
    local szTimerName = tbJsonData.TimerName
    self.szTimerName = szTimerName
    self.szSetTimeKey = tbJsonData.SetTimeKey
    
    self.nTime = tbJsonData.Time

    if(szTimerName == nil or string.len(szTimerName) == 0) then
        BattleOperationHelper:PrintError(self, "Invalid TimerName")
        return false
    end

    if(self.nTime <= 0 and (self.szSetTimeKey == nil or self.szSetTimeKey <= 0)) then
        BattleOperationHelper:PrintError(self, "Invalid Time value")
        return false
    end
    
    return true
end

function BattleCreateTimerBbAction:Execute()
    BattleOperationHelper:PrintLog(self, "TimerName: "..self.szTimerName..", Time: "..self.nTime)
    if self.szSetTimeKey and string.len(self.szSetTimeKey) > 0 then
        self.nTime = BattleBlackboard:GetNumber(self.szSetTimeKey)
    end

    return BattleTimerHelper:CreateTimer(self.szTimerName, nil, self.nTime)    
end

function BattleCreateTimerBbAction:Uninit()
    BattleTimerHelper:DestroyTimer(self.szTimerName)
    BattleCreateTimerBbAction.super.Uninit(self)
end

function BattleCreateTimerBbAction:ForceStop()
    BattleTimerHelper:DestroyTimer(self.szTimerName)
    BattleCreateTimerBbAction.super.ForceStop(self)
end

return BattleCreateTimerBbAction