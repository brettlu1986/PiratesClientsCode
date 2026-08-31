-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerChangeControlMode  = luaclass("GuideTriggerChangeControlMode", GuideTrigger)

local ControlModeDef                = require("ControlModeDef")
local ClientEventDef                = require("ClientEventDef")
-----------------------------------------------------

function GuideTriggerChangeControlMode:ControlModeChange(nControlMode)
    self:DebugLog("ControlModeChange ")
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    if tbParam[1] == "ship" and nControlMode == ControlModeDef.SHIP then
        self:DebugLog("ControlModeChange ship Trigger")
        self:Trigger()
    else
        self:Break()
    end
    if tbParam[1] == "human" and nControlMode == ControlModeDef.HUMAN then
        self:DebugLog("ControlModeChange human Trigger")
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerChangeControlMode:Begin()
    GuideTriggerChangeControlMode.super.Begin(self)
end

function GuideTriggerChangeControlMode:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, self.ControlModeChange) 
end

return GuideTriggerChangeControlMode
