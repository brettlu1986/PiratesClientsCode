-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                       = require("luaclass")
local GuideTrigger                   = require("GuideTrigger")
local GuideTriggerPlayerInShip       = luaclass("GuideTriggerPlayerInShip", GuideTrigger)

local ClientEventDef            = require("ClientEventDef")
local ProtoDR                   = require("DungeonRepProtoNames")
-----------------------------------------------------

function GuideTriggerPlayerInShip:OnFFAProcessStateChanged(nState)
    self:DebugLog("OnFFAProcessStateChanged")
    if nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        self:Trigger()
    else
        self:Break()
    end
    --self:DebugLog("GuideTriggerPlayerInShip:OnFFAProcessStateChanged, bResult = " .. tostring(bResult))
end

--override
function GuideTriggerPlayerInShip:Begin()
    GuideTriggerPlayerInShip.super.Begin(self)
end

function GuideTriggerPlayerInShip:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, self.OnFFAProcessStateChanged)
end

return GuideTriggerPlayerInShip
