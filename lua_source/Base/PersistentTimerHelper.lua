local luaclass          = require("luaclass")
local PersistentTimer   = require("PersistentTimer")
local PersistentTimerHelper = luaclass("PersistentTimerHelper")

PersistentTimerHelper.tbTimers = {} 

function PersistentTimerHelper:NewTimer(fnCallback, nTime, bLooping)
    local tbPersistentTimer = PersistentTimer()
    local OneTimer = tbPersistentTimer:SetTimer(fnCallback, nTime, bLooping)
    self.tbTimers[OneTimer] = tbPersistentTimer
    return OneTimer
end

function PersistentTimerHelper:ClearTimer(OneTimer)
    if OneTimer ~= nil then
        local tbPersistentTimer = self.tbTimers[OneTimer]
        if tbPersistentTimer ~= nil then
            tbPersistentTimer:ClearTimer()
        end
        self.tbTimers[OneTimer] = nil
    end
end

function PersistentTimerHelper:ClearAllTimer()
    for k, v in pairs(self.tbTimers) do
        v:ClearTimer()
    end
    self.tbTimers = {}
end

return PersistentTimerHelper