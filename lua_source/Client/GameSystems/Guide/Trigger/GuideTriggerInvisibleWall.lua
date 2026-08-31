-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideTrigger              = require("GuideTrigger")
local GuideTriggerInvisibleWall = luaclass("GuideTriggerInvisibleWall", GuideTrigger)
local ClientEventDef            = require("ClientEventDef")

local INVISIBLEWALL_COLLISIONTYPE = 16
-----------------------------------------------------

local function OnShipMountainWarning(self, bHit, pCollisionType)
    if bHit and enumtoint(pCollisionType) == INVISIBLEWALL_COLLISIONTYPE then 
        self:Trigger()
    end
end

--override
function GuideTriggerInvisibleWall:Begin()
    GuideTriggerInvisibleWall.super.Begin(self)
end

function GuideTriggerInvisibleWall:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_MOUNTAIN_WARNING, self, OnShipMountainWarning)
end

return GuideTriggerInvisibleWall
