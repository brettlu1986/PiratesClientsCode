-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerEnterBattleReady  = luaclass("GuideTriggerEnterBattleReady", GuideTrigger)

local ClientEventDef        = require("ClientEventDef")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
-----------------------------------------------------

function GuideTriggerEnterBattleReady:OnPlayerSelfReady()
    self:DebugLog("OnPlayerSelfReady ")
    
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if bIsInDungeon then
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerEnterBattleReady:Begin()
    GuideTriggerEnterBattleReady.super.Begin(self)
end

function GuideTriggerEnterBattleReady:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, self.OnPlayerSelfReady)
end

return GuideTriggerEnterBattleReady
