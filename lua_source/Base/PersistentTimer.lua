local luaclass          = require("luaclass")
local PersistentTimer   = luaclass("PersistentTimer")
local Signature         = U4LDelegateProxy.Fire

PersistentTimer.TimerDelegate   = nil
PersistentTimer.TimerHandle     = nil

function PersistentTimer:SetTimer(fnCallback, nTime, bLooping)
    nTime = nTime or 0.01
    bLooping = bLooping or false
    if self.TimerHandle then
        error("TimerHandle already exists")
    end

    local szInfo
    local Timer = ClientShell.GetClient(GWorld):GetPersistentTimer()
    if(GEnableNewLua) then
        szInfo = getdebuginfo_f(fnCallback)
    end
    self.fnCallback = fnCallback
    self.TimerDelegate  = createDelegate(Signature, fnCallback, szInfo)
    self.TimerHandle    = Timer:SetTimer(self.TimerDelegate, "Fire", nTime, bLooping)
    return self.TimerHandle
end

function PersistentTimer:ClearTimer()
    if self.TimerHandle then
        local Timer = ClientShell.GetClient(GWorld):GetPersistentTimer()
        Timer:ClearTimerHandle(self.TimerHandle)
        self.TimerHandle = nil
    end
    self.TimerDelegate = nil
end

return PersistentTimer