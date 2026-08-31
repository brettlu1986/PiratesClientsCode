-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerMidOnAttackFinished  = luaclass("GuideTriggerMidOnAttackFinished", GuideTrigger)

local ClientEventDef    = require("ClientEventDef")
-----------------------------------------------------

local function MidOnAttackFinished(self, bFocus)
    if not bFocus then
        self:Trigger()
    end
end

--override
function GuideTriggerMidOnAttackFinished:Begin()
    GuideTriggerMidOnAttackFinished.super.Begin(self)
end

function GuideTriggerMidOnAttackFinished:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ACCUMULAT, self, MidOnAttackFinished)
end

return GuideTriggerMidOnAttackFinished
