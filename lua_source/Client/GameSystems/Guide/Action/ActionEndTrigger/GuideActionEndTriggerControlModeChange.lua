-----------------------------------------------------
--File Name    : GuideActionEndTriggerControlModeChange.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerControlModeChange    = luaclass("GuideActionEndTriggerControlModeChange", GuideActionEndTriggerBase)

local ClientEventDef = require("ClientEventDef")
local ControlModeDef = require("ControlModeDef")
-----------------------------------------------------

local function ControlModeChange(self, nControlMode)
    self:DebugLog("ControlModeChange ")
    local szChangeType = self.tbParam[1]
    if not szChangeType then
        self:Triggered()
        return
    end
    if szChangeType == "ship" and nControlMode == ControlModeDef.SHIP then
        self:DebugLog("ControlModeChange ship Trigger")
        self:Triggered()
    end
    if szChangeType == "human" and nControlMode == ControlModeDef.HUMAN then
        self:DebugLog("ControlModeChange human Trigger")
        self:Triggered()
    end
end

function GuideActionEndTriggerControlModeChange:BindEvent(tbParam)
    GuideActionEndTriggerControlModeChange.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, ControlModeChange)
end

return GuideActionEndTriggerControlModeChange
