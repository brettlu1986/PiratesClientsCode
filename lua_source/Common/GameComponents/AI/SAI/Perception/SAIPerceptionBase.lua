local luaclass = require("luaclass")
local SAIPerceptionBase = luaclass("SAIPerceptionBase")
local SelfEventHelperClass = require("SelfEventHelper")
local SAIMisc = require("SAIMisc")

SAIPerceptionBase.tbOwner = nil
SAIPerceptionBase.tbSelfEventHelper = nil
SAIPerceptionBase.pAIController = nil
SAIPerceptionBase.tbConfig = nil
SAIPerceptionBase.bStarted = false

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIPerceptionBase:", ...)
end

local function LOGERR(...)
    logerror("CJ->SAIPerceptionBase:", ...)
end
-- luacheck: pop

function SAIPerceptionBase:Init(Owner)
    self.tbOwner = Owner
    self.tbSelfEventHelper = SelfEventHelperClass()
end

function SAIPerceptionBase:BindEvent(SelfEventHelper)

end

function SAIPerceptionBase:UnbindEvent(SelfEventHelper)

end

function SAIPerceptionBase:SetConfig(tbConfig)
    self.tbConfig = tbConfig
end

function SAIPerceptionBase:GetSelfEventHelper()
    return self.tbSelfEventHelper
end

function SAIPerceptionBase:GetGameObject()
    return self.tbOwner
end


function SAIPerceptionBase:OnStarted()

end

function SAIPerceptionBase:OnStop()

end

function SAIPerceptionBase:Start(pAIController)
    if self.bStarted then
        return
    end
    self.bStarted = true
    self.pAIController = pAIController
    self:BindEvent(self.tbSelfEventHelper)
    self:OnStarted()
end

function SAIPerceptionBase:Stop()
    self:OnStop()
    self:UnbindEvent(self.tbSelfEventHelper)
    self.pAIController = nil
    self.bStarted = false
end

function SAIPerceptionBase:Uninit()
    self.tbSelfEventHelper:UnregisterAll()
end

function SAIPerceptionBase:FireEvent(szEventName, ...)
    SAIMisc:FireEvent(self.tbOwner, "OnPerceptionEvent_" .. szEventName, ...)
end

return SAIPerceptionBase