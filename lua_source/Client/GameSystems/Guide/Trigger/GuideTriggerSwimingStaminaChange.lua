-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerSwimingStaminaChange  = luaclass("GuideTriggerSwimingStaminaChange", GuideTrigger)

local ClientEventDef            = require("ClientEventDef")
-----------------------------------------------------
GuideTriggerSwimingStaminaChange.nWarningValue = 1
-----------------------------------------------------
function GuideTriggerSwimingStaminaChange:OnSwimingStaminaChange(nStamina, nPercent)
    self:DebugLog("OnSwimingStaminaChange, nStamina = " .. nStamina .. " nPercent = " .. nPercent)
    if nPercent <= self.nWarningValue then
        self:Trigger()
    end
end

function GuideTriggerSwimingStaminaChange:Begin()
    GuideTriggerSwimingStaminaChange.super.Begin(self)
    local tbTemplate = self.tbTemplate
    local tbParam = tbTemplate.tbParam
    if tbParam then
        self.nWarningValue = tonumber(tbParam[1])
    end
end

function GuideTriggerSwimingStaminaChange:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_HUMAN_SWIMMING_STAMINA_CHANGE, self, self.OnSwimingStaminaChange)
end

return GuideTriggerSwimingStaminaChange
