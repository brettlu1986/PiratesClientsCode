-----------------------------------------------------
--File Name    : GuideTriggerRecieveShipAward.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerRecieveShipAward  = luaclass("GuideTriggerRecieveShipAward", GuideTrigger)

local ClientEventDef            = require("ClientEventDef")
-----------------------------------------------------

-----------------------------------------------------

local function RecieveShipAward(self)
    self:Trigger()
end


--override
function GuideTriggerRecieveShipAward:Begin()
    GuideTriggerRecieveShipAward.super.Begin(self)
end

function GuideTriggerRecieveShipAward:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_NOOB_GUIDE_AWARD, self, RecieveShipAward)
end

return GuideTriggerRecieveShipAward
