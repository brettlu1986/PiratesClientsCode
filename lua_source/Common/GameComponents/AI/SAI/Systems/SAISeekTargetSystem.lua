
local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAISeekTargetSystem = luaclass("SAISeekTargetSystem", SAISystemBase)
local Timer = require("Timer")
local SAISystemDef = require("SAISystemDef")

SAISeekTargetSystem.tbGoalSystem = nil
SAISeekTargetSystem.nSeekTargetObject = nil
SAISeekTargetSystem.nTickIntarval = 2
SAISeekTargetSystem.nTimer = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAISeekTargetSystem:", ...)
end
-- luacheck: pop




function SAISeekTargetSystem:OnStart()
    local tbOwner = self.tbOwner
    local AIComponent  = tbOwner.SAIComponent
    self.tbGoalSystem  = AIComponent:GetSystem(SAISystemDef.Goal)
    self:SeekTarget(self.nSeekTargetObject)
end

function SAISeekTargetSystem:SeekTarget(tbGameObject)
    if tbGameObject and not tbGameObject:IsDead() then
        self.nSeekTargetObject = tbGameObject
        self:StartTimer()
        LOG("seek target:",self.tbOwner.szName, tbGameObject.szName)
    end
end

function SAISeekTargetSystem:StopSeek()
    LOG("clear seek", self.tbOwner.szName)
    self.tbGoalSystem:ClearGoalLocation()
    self:StoptTimer()
    self.nSeekTargetObject = nil
end

function SAISeekTargetSystem:Tick()
    local tbGameObject = self.nSeekTargetObject
    local tbGoalSystem = self.tbGoalSystem
    if tbGameObject and not tbGameObject:IsDead() then
        local tbLocation = tbGameObject:GetLocation()
        tbGoalSystem:SetGoalLocation(tbLocation.X, tbLocation.Y, tbLocation.Z)
    else
       self:StopSeek()
    end
end

function SAISeekTargetSystem:StartTimer()
    self:StoptTimer()
    self.nTimer = Timer.NewTimerMethod(self, self.Tick, self.nTickIntarval, true)
end

function SAISeekTargetSystem:StoptTimer()
    if self.nTimer then
        self.nTimer:Clear()
        self.nTimer = nil
    end
end


function SAISeekTargetSystem:OnStop()
    self:StoptTimer()
    self.tbGoalSystem = nil
end

function SAISeekTargetSystem:OnUninit()

end


return SAISeekTargetSystem
