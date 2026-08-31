local luaclass = require("luaclass")
local SAIService = luaclass("SAIService")
local Timer = require("Timer")


SAIService.nTickIntarval = 1
SAIService.nTimer = nil
SAIService.fnService = nil
SAIService.tbClass = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIService:", ...)
end
-- luacheck: pop


function SAIService:Init(nInterval, fnServcie, tbClass)
    self.nTickIntarval = nInterval
    self.fnServcie = fnServcie
    self.tbClass = tbClass
end

function SAIService:Start()
    if self.nTickIntarval > 0 and self.fnServcie then
        self:StartTimer()
    end
end

function SAIService:Stop()
    self:StoptTimer()
end

function SAIService:Tick()
    self.fnServcie(self.tbClass)
end

function SAIService:StartTimer()
    self:StoptTimer()
    self.nTimer = Timer.NewTimerMethod(self, self.Tick, self.nTickIntarval, true)
end

function SAIService:StoptTimer()
    if self.nTimer then
        self.nTimer:Clear()
        self.nTimer = nil
    end
end


return SAIService