local luaclass = require("luaclass")
local AgentStatisticsSystem   = luaclass("AgentStatisticsSystem")
local SelfEventHelper   = require("SelfEventHelper")
local CommonEventDef    = require("CommonEventDef")

AgentStatisticsSystem.tbAgentStatistics = nil
AgentStatisticsSystem.SelfEventHelper = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->AgentStatisticsSystem:", ...)
end
-- luacheck: pop


local function OnPlayerLoginIn(self, tbGameObject)
    if not self.tbAgentStatistics[tbGameObject.nServerInstanceId] then
        self:Register(tbGameObject)
    end
end

function AgentStatisticsSystem:Init()
    self.tbAgentStatistics = { }
    self.SelfEventHelper = SelfEventHelper()
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLoginIn)
end

function AgentStatisticsSystem:Register(tbGameObject)
    local tbNewAgentStatistics = require("AgentStatistics")()
    tbNewAgentStatistics:Init(tbGameObject)
    self.tbAgentStatistics[tbGameObject.nServerInstanceId] = tbNewAgentStatistics
--    LOG("AgentStatisticsSystem register ", tbGameObject.nServerInstanceId)
end

function AgentStatisticsSystem:Get(nServerInstanceId)
    return self.tbAgentStatistics[nServerInstanceId]
end

function AgentStatisticsSystem:Clear()
    for _,v in pairs(self.tbAgentStatistics) do
        v:Clear()
    end
end

function AgentStatisticsSystem:Uninit()
    for _,v in pairs(self.tbAgentStatistics) do
        v:Uinit()
    end
    self.SelfEventHelper:UnregisterAll()
    self.tbAgentStatistics = { }
end

return AgentStatisticsSystem()