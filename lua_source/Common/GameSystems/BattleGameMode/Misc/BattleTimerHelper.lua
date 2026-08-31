local BattleTimerHelper = {}

local Timer = require("Timer")

BattleTimerHelper.tbTimers = nil
BattleTimerHelper.tbListeners = nil

local function OnTimerEnd(self, szName, fnCallback)
    self.tbTimers[szName] = nil
    if(fnCallback) then
        fnCallback()
    end

    local Info = self.tbListeners[szName]
    if(Info) then
        self.tbListeners[szName] = nil
        if(type(Info) == 'function') then
            Info()
        else
            for i, v in ipairs(Info) do
                v()
            end
        end        
    end
end

function BattleTimerHelper:Init()
    self.tbTimers = {}
    self.tbListeners = {}
end

function BattleTimerHelper:Uninit()
    self:DestroyAllTimers()
    self.tbListeners = nil
    self.tbTimers = nil
end

function BattleTimerHelper:DestroyAllTimers()
    local tbTimers = self.tbTimers
    if(tbTimers) then
        for szName, TempTimer in pairs(tbTimers) do
            TempTimer:Clear()
        end
        self.tbTimers = {}
        self.tbListeners = {}
    end
end

function BattleTimerHelper:CreateTimer(szName, fnCallback, nTime)
    if(szName == nil or string.len(szName) == 0) then
        logerror("BattleTimerHelper:CreateTimer failed, invalid name")
        return false
    end
    if(self:HasTimer(szName)) then
        logerror("BattleTimerHelper:CreateTimer failed, duplicated name", szName)
        return false
    end

    local fnTimerEnd = function()
        OnTimerEnd(self, szName, fnCallback)
    end
    local TempTimer = Timer.NewTimer(fnTimerEnd, nTime, false)
    self.tbTimers[szName] = TempTimer
    return true
end

function BattleTimerHelper:DestroyTimer(szName)
    if(szName == nil or self.tbTimers == nil) then
        return
    end

    local tbTimer = self.tbTimers[szName]
    if(tbTimer) then
        tbTimer:Clear()
        self.tbTimers[szName] = nil
    end

    self.tbListeners[szName] = nil
end

function BattleTimerHelper:HasTimer(szName)
    return self.tbTimers[szName] ~= nil
end

function BattleTimerHelper:AddListener(szName, fnCallback)
    local tbListeners = self.tbListeners
    local Info = tbListeners[szName]
    if(Info == nil) then
        tbListeners[szName] = fnCallback
    else
        local tbTable = Info
        if(type(Info) == 'function') then
            tbTable = {}
            table.insert(tbTable, Info)
            tbListeners[szName] = tbTable
        end
        table.insert(tbTable, fnCallback)
    end
end

function BattleTimerHelper:RemoveListener(szName, fnCallback)
    local Info = self.tbListeners[szName]
    if(Info == nil) then
        return
    end

    if(type(Info) == 'function') then
        if(Info == fnCallback) then
            self.tbListeners[szName] = nil
        end
    else
        for i, v in ipairs(Info) do
            if(v == fnCallback) then
                table.remove(Info, i)
                break
            end -- if(v == fnCallback) then
        end -- for i, v in ipairs(Info) do
    end -- if(type(Info) == 'function') then
end

return BattleTimerHelper