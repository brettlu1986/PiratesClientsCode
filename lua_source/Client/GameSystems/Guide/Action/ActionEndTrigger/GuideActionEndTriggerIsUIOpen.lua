-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerIsUIOpen         = luaclass("GuideActionEndTriggerIsUIOpen", GuideActionEndTriggerBase)

local UIManager = require("UIManager")
-----------------------------------------------------

local function IsUIOpen(self, tbParam)
    self:DebugLog("IsUIOpen")
    local szUIName = tbParam[1]
    local szType = tbParam[2]
    local bVisible = UIManager:IsWndVisible(szUIName)
    if bVisible and szType == "true" then
        self:Triggered()
    elseif not bVisible and szType == "false" then
        self:Triggered()
    end
end

function GuideActionEndTriggerIsUIOpen:BindEvent(tbParam)
    GuideActionEndTriggerIsUIOpen.super.BindEvent(self, tbParam)
    IsUIOpen(self, tbParam)
end

return GuideActionEndTriggerIsUIOpen
