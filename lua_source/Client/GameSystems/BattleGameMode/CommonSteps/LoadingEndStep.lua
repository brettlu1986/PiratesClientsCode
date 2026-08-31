-- 只有单机副本才会走这里的逻辑,等待客户端loading结束再开始

local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local LoadingEndStep = luaclass("LoadingEndStep", BattleStepBaseClass)
local ClientEventDef = require("ClientEventDef")

function LoadingEndStep:Start()
    LoadingEndStep.super.Start(self)
    self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, self.OnLoadingEnd)
end

function LoadingEndStep:OnLoadingEnd()
    self:Complete()
end

function LoadingEndStep:SnapshotToReplicatedProperty()
    return true
end

return LoadingEndStep
