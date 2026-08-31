-----------------------------------------------------
--File Name    : GuideTriggerDungeonStep.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerDungeonStep = luaclass("GuideTriggerDungeonStep",GuideTrigger)

local ClientEventDef = require("ClientEventDef")


--override
function GuideTriggerDungeonStep:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_DUNGEON_NEXT, self, self.OnDungeonStep)
end

function GuideTriggerDungeonStep:OnDungeonStep(nStepIndex)
    self:DebugLog("OnDungeonStep,nstepIndex="..tostring(nStepIndex))
    if(nStepIndex == self.tbTemplate.nDungeonStepIndex)then
        self:Trigger()
    else
        self:Break()
    end
end

return GuideTriggerDungeonStep
