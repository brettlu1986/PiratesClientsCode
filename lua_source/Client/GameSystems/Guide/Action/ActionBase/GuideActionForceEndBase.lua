-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionBase               = require("GuideActionBase")
local GuideActionForceEndBase       = luaclass("GuideActionForceEndBase", GuideActionBase)

local LuaClassHelper    = require("LuaClassHelper")
-----------------------------------------------------

--member veriable

local PREFIX = "GuideActionEndTrigger"

GuideActionForceEndBase.EndTrigger = nil
-----------------------------------------------------

function GuideActionForceEndBase:Init(Owner, nIndex, tbTemplate, tbGuideTemplate, OnActionEndFunc)
    GuideActionForceEndBase.super.Init(self, Owner, nIndex, tbTemplate, tbGuideTemplate, OnActionEndFunc)
    self:DebugLog("Init")
    assert(tbTemplate.tbParam, "EndTrigger is nil!")
    local szEndTriggerName = tbTemplate.tbParam[1]
    self:DebugLog("Action Trigger Name = " .. szEndTriggerName)
    if szEndTriggerName then
        local szEndTriggerClassName = PREFIX .. szEndTriggerName
        local EndTriggerClass = require(szEndTriggerClassName)
        local EndTrigger = EndTriggerClass()
        self.EndTrigger = EndTrigger
        EndTrigger:Init(self, szEndTriggerClassName, tbTemplate, tbGuideTemplate.nGroup, tbGuideTemplate.nStep, self.OnTriggered)
        return true
    end
    return false
end

function GuideActionForceEndBase:End()
    self:DebugLog("End")
    if self.bEnded then
        self:DebugLog("already done!")
        return
    end
    if self.EndTrigger then
        self.EndTrigger:End()
        self.EndTrigger = nil
    end
    GuideActionForceEndBase.super.End(self)
end

function GuideActionForceEndBase:Uninit()
    self:DebugLog("Uninit")
    if self.EndTrigger then
        self.EndTrigger:Uninit()
        self.EndTrigger = nil
    end
    GuideActionForceEndBase.super.Uninit(self)
end

function GuideActionForceEndBase:Begin()
    GuideActionForceEndBase.super.Begin(self)
    self:DebugLog("Begin")
    assert(self.EndTrigger, "EndTrigger is nil!")
    local tbParam = self.tbTemplate.tbParam
    local tbTempParam = LuaClassHelper.DeepCopyTable(tbParam)
    table.remove(tbTempParam, 1)

    self.EndTrigger:Begin(tbTempParam)
end

function GuideActionForceEndBase:Interrupt()
    self:DebugLog("Interrupt")
    GuideActionForceEndBase.super.Interrupt(self)
    if self.EndTrigger then
        self.EndTrigger:Interrupt()
    end
end

function GuideActionForceEndBase:OnTriggered()
    self:DebugLog("OnTriggered")
    self.EndTrigger:End()
    self.EndTrigger = nil
end

return GuideActionForceEndBase
