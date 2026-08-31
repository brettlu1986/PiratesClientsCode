-- 倒计时Target

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleTimerTarget = luaclass("BattleTimerTarget", BattleTargetBaseClass)

local Timer = require("Timer")

BattleTimerTarget.nMaxTime = nil
BattleTimerTarget.Timer = nil

function BattleTimerTarget:Init()
    BattleTimerTarget.super.Init(self)
    self.szName = "BattleTimerTarget"
end

function BattleTimerTarget:SetTime(nTime)
    self.nMaxTime = nTime
end

function BattleTimerTarget:Start()    
    self.Timer = Timer.NewTimerMethod(self, self.Complete, self.nMaxTime, false)
    BattleTimerTarget.super.Start(self)
end

function BattleTimerTarget:UnregisterEvent()    
    if(self.Timer) then
        self.Timer:Clear()
        self.Timer = nil
    end
    BattleTimerTarget.super.UnregisterEvent(self)
end

function BattleTimerTarget:GetRemainTime()
    if(self.Timer) then
        return self.Timer:GetRemainingTime()
    end
    return -1
end

function BattleTimerTarget:GetElapsedTime()
    if(self.Timer) then
        return self.Timer:GetElapsedTime()
    end
    return -1
end

return BattleTimerTarget