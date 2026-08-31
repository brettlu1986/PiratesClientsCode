-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerEnterNextSafeZone   = luaclass("GuideTriggerEnterNextSafeZone", GuideTrigger)

local ClientEventDef = require("ClientEventDef")
-----------------------------------------------------

function GuideTriggerEnterNextSafeZone:OnPoisonCircleUpdate(tbPacket)
    self:DebugLog("OnPoisonCircleUpdate")
    local nDestRadius = tbPacket.nNextRadius
    if nDestRadius then
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerEnterNextSafeZone:Begin()
    GuideTriggerEnterNextSafeZone.super.Begin(self)
end

function GuideTriggerEnterNextSafeZone:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_POISONCIRCLE_UPDATE, self, self.OnPoisonCircleUpdate)
end

return GuideTriggerEnterNextSafeZone
