-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerExitLoading       = luaclass("GuideTriggerExitLoading", GuideTrigger)

local ClientEventDef        = require("ClientEventDef")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
-----------------------------------------------------

function GuideTriggerExitLoading:OnExitLoading()
    self:DebugLog("OnExitLoading ")
    
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if bIsInDungeon then
        self:Trigger()
    else
        self:Break()
    end
end

function GuideTriggerExitLoading:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, self.OnExitLoading)
end

return GuideTriggerExitLoading
