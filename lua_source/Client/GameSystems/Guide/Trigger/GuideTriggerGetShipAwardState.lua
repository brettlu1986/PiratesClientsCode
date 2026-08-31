-----------------------------------------------------
--File Name    : GuideTriggerGetShipAwardState.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerGetShipAwardState  = luaclass("GuideTriggerGetShipAwardState", GuideTrigger)

local ClientEventDef            = require("ClientEventDef")
local NoobAwardHelper           = require("NoobAwardHelper")
local Proto                     = require("ClientProtoNames")
-----------------------------------------------------

-----------------------------------------------------

local function AwardState(self, bGet)
    if bGet then
        self:Trigger()
    else
        self:ForceEndCurrentGroup()
    end
end

local function GetAwardState(self)
    NoobAwardHelper.GetNoobAwardState(Proto.NoobAwardType.NOOB_SHIP)
end

--override
function GuideTriggerGetShipAwardState:Begin()
    GuideTriggerGetShipAwardState.super.Begin(self)
    GetAwardState(self)
end

function GuideTriggerGetShipAwardState:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_NOOB_GUIDE_AWARD_STATE, self, AwardState)
end

return GuideTriggerGetShipAwardState
