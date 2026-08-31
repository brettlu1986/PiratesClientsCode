local luaclass = require("luaclass")
local SyncDataBase = luaclass("SyncDataBase")
local SelfEventHelperClass = require("SelfEventHelper")
local AgentStatisticsSystem = require("AgentStatisticsSystem")

SyncDataBase.tbOwner = nil
SyncDataBase.pAIController = nil
SyncDataBase.tbAgent = nil
SyncDataBase.tbSelfEventHelper = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SyncDataBase:", ...)
end

local function LOGERR(...)
    logerror("CJ->SyncDataBase:", ...)
end
-- luacheck: pop

function SyncDataBase:Init(Owner)
    self.tbAgent = Owner
    self.tbOwner = Owner:GetGameObject()
    self.pAIController = Owner.pAIController
    self.tbSelfEventHelper = SelfEventHelperClass()
    self.tbAgentStatistics = AgentStatisticsSystem:Get(self.tbOwner:GetServerInstanceId())
end

function SyncDataBase:BindEvent(SelfEventHelper)

end

function SyncDataBase:UnbindEvent(SelfEventHelper)

end

function SyncDataBase:OnSync(tbPack)

end

function SyncDataBase:Sync(tbPack)
    -- rts()
    -- local nBase = collectgarbage("count")
    self:OnSync(tbPack)
    -- local nFinal = collectgarbage("count")
    -- if nFinal > nBase then
    --     logdebug("lua memeory add:", self.szName, nFinal - nBase, "K")
    -- end
    -- rte("SyncDataBase:Sync " .. self.szName)
end


function SyncDataBase:OnStart()

end

function SyncDataBase:Start()
    self.pAIController = self.tbAgent.pAIController
    self:BindEvent(self.tbSelfEventHelper)
    self:OnStart()
end


function SyncDataBase:OnStop()

end

function SyncDataBase:Stop()
    self:UnbindEvent(self.tbSelfEventHelper)
    self:OnStop()
end


function SyncDataBase:UnInit()
    self.tbSelfEventHelper:UnregisterAll()
end

return SyncDataBase