-----------------------------------------------------
--File Name    : HomelandSubProcedureBase.lua
--Author       : WuJizhou
--Create Time  : 5/22/2019, 8:27:24 PM
--Description  : HomelandSubProcedureBase
-----------------------------------------------------
local luaclass = require("luaclass")
local HomelandSubProcedureBase = luaclass("HomelandSubProcedureBase")
local SelfEventHelper = require("SelfEventHelper")

HomelandSubProcedureBase.EventHelper = nil
HomelandSubProcedureBase.tbSteps ={}
HomelandSubProcedureBase.tbCurrentStep = nil

local MoveOnStep

local function OnEventTrigger(self, ...)
    self.EventHelper:UnregisterEvent(self.tbCurrentStep.nStepFinishedEvent)
    if self.tbCurrentStep.fnEventFunc then
        if self.tbCurrentStep.tbClass then
            self.tbCurrentStep.fnEventFunc(self.tbCurrentStep.tbClass, ...)
        else
            self.tbCurrentStep.fnEventFunc(...)
        end
    end
    MoveOnStep(self)
end

MoveOnStep = function (self)
    self.tbCurrentStep = table.remove(self.tbSteps, 1)
    if self.tbCurrentStep then
        if self.tbCurrentStep.nStepFinishedEvent then
            -- register event
            self.EventHelper:RegisterEvent(self.tbCurrentStep.nStepFinishedEvent, self, OnEventTrigger)
            self.tbCurrentStep.fnStep(self.tbCurrentStep.tbStepParam)
        else
            self.tbCurrentStep.fnStep(self.tbCurrentStep.tbStepParam)
            MoveOnStep(self)
        end
    else
        local nProcedureFinishedEvent = self:GetProcedureFinishedEvent()
        assert(nProcedureFinishedEvent)
        self.EventHelper:FireEvent(nProcedureFinishedEvent)
    end
end

function HomelandSubProcedureBase:RegisterStep(fnStep, tbStepParam, nStepFinishedEvent, tbClass, fnEventFunc)
    local tbStep = {}
    tbStep.fnStep = fnStep
    tbStep.tbStepParam = tbStepParam
    tbStep.nStepFinishedEvent = nStepFinishedEvent
    tbStep.tbClass = tbClass
    tbStep.fnEventFunc = fnEventFunc
    table.insert(self.tbSteps, tbStep)
end


function HomelandSubProcedureBase:Begin()
    self.tbSteps = {}
    self:RegisterAllSteps()
    MoveOnStep(self)
end


function HomelandSubProcedureBase:RegisterAllSteps()
    -- override in subclass
end


function HomelandSubProcedureBase:GetProcedureFinishedEvent()
    -- override in subclass
end

function HomelandSubProcedureBase:GetProcedureTriggeredEvent()
        -- override in subclass
end

function HomelandSubProcedureBase:Init()
    self.EventHelper = SelfEventHelper()
    -- self:RegisterAllSteps()
end

function HomelandSubProcedureBase:Uninit()
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
end


return HomelandSubProcedureBase