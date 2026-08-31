-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerForceEndGroup    = luaclass("GuideActionEndTriggerForceEndGroup", GuideActionEndTriggerBase)

local GuideSystem = require("GuideSystem")
-----------------------------------------------------
local function ForceEndGroup(self, nModuleId, nGroupId)
    self:DebugLog("ForceEndGroup nModuleId = " .. nModuleId .. " nGroupId = " .. nGroupId)
    GuideSystem:ForceEndGroup(nModuleId, nGroupId)
    self:Triggered()
end

function GuideActionEndTriggerForceEndGroup:BindEvent(tbParam)
    GuideActionEndTriggerForceEndGroup.super.BindEvent(self, tbParam)
    local nModuleId = tonumber(tbParam[1])
    local nGroupId = tonumber(tbParam[2])
    ForceEndGroup(self, nModuleId, nGroupId)
end

return GuideActionEndTriggerForceEndGroup
