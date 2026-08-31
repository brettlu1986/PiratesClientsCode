local luaclass = require("luaclass")
local SAIPerceptionBase = require("SAIPerceptionBase")
local SAIPerceptionHearing = luaclass("SAIPerceptionHearing", SAIPerceptionBase)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local Timer = require("Timer")

SAIPerceptionHearing.tbSoundEvent = nil
SAIPerceptionHearing.nRememberTime = 10
SAIPerceptionHearing.nTimer = nil

local tbPriority = {
    Footstep = 1,
    Fire = 10,
}

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIPerceptionHearing:", ...)
end
-- luacheck: pop


local function OnHeard(self, nUniqueId, Location, Tag)
    if not Tag or not tbPriority[Tag] then
        logerror("invalid sound tag:" .. Tag)
        return
    end
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if tbGameObject then
        local bAdd = false
        if not self.tbSoundEvent then
            bAdd = true
        elseif tbPriority[Tag] >= tbPriority[self.tbSoundEvent.Tag] then
            bAdd = true
        end
        if bAdd then
            self.tbSoundEvent = {
                SoundMakerId = tbGameObject:GetServerInstanceId(),
                Location = {
                    X = Location.X, Y = Location.Y, Z = Location.Z
                },
                Tag = Tag,
            }
            --LOG("heard event ", Tag)
            self:StartTimer()
            self:FireEvent("OnHeardSound", tbGameObject:GetServerInstanceId())
        end
    end
end


function SAIPerceptionHearing:OnStarted()
    self.tbSoundEvent = nil
    local tbConfig = self.tbConfig
    local pAIController = self.pAIController
    local tbHearingConfig = self.tbOwner:IsShip() and tbConfig.Ship or tbConfig.Human
    pAIController:ConfigHeard(tbHearingConfig.ListenRange)
    if tbConfig.RememberTime then
        self.nRememberTime = tbConfig.RememberTime
    end
    LOG("config hearing:", tbHearingConfig.ListenRange, self.nRememberTime)
end

function SAIPerceptionHearing:OnStop()
    self:StoptTimer()
    self.tbSoundEvent = nil
end

function SAIPerceptionHearing:BindEvent(SelfEventHelper)
    SAIPerceptionHearing.super.BindEvent(self, SelfEventHelper)
    local pAIController = self.pAIController
    SelfEventHelper:RegisterCppDelegate(pAIController.NotifyHeard, self, OnHeard)
end

function SAIPerceptionHearing:StartTimer()
    self:StoptTimer()
    if self.nRememberTime > 0 then
        self.nTimer = Timer.NewTimerMethod(self, self.Forget, self.nRememberTime, false)
    end
end

function SAIPerceptionHearing:StoptTimer()
    if self.nTimer then
        self.nTimer:Clear()
        self.nTimer = nil
    end
end

function SAIPerceptionHearing:Forget()
    --LOG("forget heard ", self.tbSoundEvent.Tag)
    self.tbSoundEvent = nil
end

function SAIPerceptionHearing:GetSoundEvent()
    return self.tbSoundEvent
end

function SAIPerceptionHearing:UnbindEvent(SelfEventHelper)
    SAIPerceptionHearing.super.UnbindEvent(self, SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

return SAIPerceptionHearing