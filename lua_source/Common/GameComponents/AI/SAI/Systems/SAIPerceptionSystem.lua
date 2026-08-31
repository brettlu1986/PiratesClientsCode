
local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAIPerceptionSystem = luaclass("SAIPerceptionSystem", SAISystemBase)
local SAIPerceptionFactory  = require("SAIPerceptionFactory")
local SAIPerceptionDef      = require("SAIPerceptionDef")

SAIPerceptionSystem.tbPerceptions = nil
SAIPerceptionSystem.bRunning = false
SAIPerceptionSystem.pAIController = nil
SAIPerceptionSystem.tbConfig = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIPerceptionSystem:", ...)
end
-- luacheck: pop


local tbPerceptionConfigKey = {
    [SAIPerceptionDef.Sight] = "Sight",
    [SAIPerceptionDef.Hearing] = "Hearing",
    [SAIPerceptionDef.Damage] = "Damage",
    [SAIPerceptionDef.Alert] = "Alert",
    [SAIPerceptionDef.Enmity] = "Enmity",
}

function SAIPerceptionSystem:EnablePerception(nPerception)
    local tbPerception = SAIPerceptionFactory:CreatePerception(nPerception)
    tbPerception:Init(self.tbOwner)
    self.tbPerceptions[nPerception] = tbPerception
    local tbConfig = self.tbConfig
    local szKey = tbPerceptionConfigKey[nPerception]
    if tbConfig[szKey] then
        tbPerception:SetConfig(tbConfig[szKey])
    end
    LOG("enable perception:", nPerception)
    if self.bRunning then
        tbPerception:Start(self.pAIController)
    end
end

function SAIPerceptionSystem:DisablePerception(nPerception)
    LOG("disable perception:", nPerception)
    local tbPerception = self.tbPerceptions[nPerception]
    if tbPerception then
        tbPerception:Stop()
        tbPerception:Uninit(self.tbOwner)
    end
    self.tbPerceptions[nPerception] = nil
end

function SAIPerceptionSystem:OnConfig(tbConfig)
    self.tbConfig = tbConfig
    for i=1,SAIPerceptionDef.Num do
        local szKey = tbPerceptionConfigKey[i]
        if tbConfig[szKey] then
            self:EnablePerception(i)
        else
            self:DisablePerception(i)
        end
    end
end


function SAIPerceptionSystem:OnInit()
    self.tbPerceptions  = {}
    self.bRunning = false
end

function SAIPerceptionSystem:OnStart()
    self.pAIController = self.tbOwner.SAIComponent:GetAIController()
    self.bRunning = true
    for k,v in pairs(self.tbPerceptions) do
        if v then
            v:Start(self.pAIController)
        end
    end
end


function SAIPerceptionSystem:OnStop()
    for k,v in pairs(self.tbPerceptions) do
        if v then
            v:Stop()
        end
    end
    self.bRunning = false
    self.pAIController = nil
end

function SAIPerceptionSystem:OnUninit()
    for k,v in pairs(self.tbPerceptions) do
        if v then
            v:Uninit()
        end
    end
    self.tbPerceptions = nil
end

function SAIPerceptionSystem:GetEntity()
    return self.tbOwner.SAIEntityComponent
end

function SAIPerceptionSystem:GetSeenActors()
    local tbPerception = self.tbPerceptions[SAIPerceptionDef.Sight]
    if tbPerception then
        return tbPerception:GetSeenActors()
    end
end

function SAIPerceptionSystem:GetDamagedActors()
    local tbPerception = self.tbPerceptions[SAIPerceptionDef.Damage]
    if tbPerception then
        return tbPerception:GetDamageList()
    end
end

function SAIPerceptionSystem:GetHeardSound()
    local tbPerception = self.tbPerceptions[SAIPerceptionDef.Hearing]
    if tbPerception then
        return tbPerception:GetSoundEvent()
    end
end


function SAIPerceptionSystem:GetPerception(nPerception)
    return self.tbPerceptions[nPerception]
end

return SAIPerceptionSystem
