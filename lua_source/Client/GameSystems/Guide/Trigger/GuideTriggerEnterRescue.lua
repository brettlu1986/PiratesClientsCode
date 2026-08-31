-----------------------------------------------------
--File Name    : GuideTriggerEnterRescue.lua
--Description  : 进到救援的trigger当中
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerEnterRescue  = luaclass("GuideTriggerEnterRescue", GuideTrigger)
local ClientEventDef           = require("ClientEventDef")

-----------------------------------------------------
GuideTriggerEnterRescue.tbParam         = nil

-----------------------------------------------------
local function PlayerEnterRescue(self)
    self:Trigger()
end

function GuideTriggerEnterRescue:End()
    GuideTriggerEnterRescue.super.End(self)
end

--override
function GuideTriggerEnterRescue:Begin()
    GuideTriggerEnterRescue.super.Begin(self)
end

function GuideTriggerEnterRescue:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_ENTER_RESCUING_TRIGGER, self, PlayerEnterRescue)
end

return GuideTriggerEnterRescue
