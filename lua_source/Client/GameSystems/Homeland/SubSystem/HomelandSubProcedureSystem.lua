-----------------------------------------------------
--File Name    : HomelandSubProcedureSystem.lua
--Author       : WuJizhou
--Create Time  : 5/20/2019, 1:20:29 PM
--Description  : HomelandSubProcedureSystem
-----------------------------------------------------
local HomelandSubProcedureSystem = {}

local SelfEventHelper = require("SelfEventHelper")

local EventHelper = nil

local tbAllProcedures = {}

local function DoRegisterProcedure(szProcedureName)
    local ProcedureClass = require(szProcedureName)
    local Procedure = ProcedureClass()
    Procedure:Init()
    local nTriggerProcedureEvent = Procedure:GetProcedureTriggeredEvent()
    tbAllProcedures[nTriggerProcedureEvent] = Procedure
    EventHelper:RegisterEvent(nTriggerProcedureEvent, Procedure, Procedure.Begin)
end

local function RegisterProcedure(self)
    DoRegisterProcedure("HomelandPostEnterProcedure")
    DoRegisterProcedure("HomelandPreLeaveProcedure")
end

local function UnregisterProcedure(self)
    for k, v in pairs(tbAllProcedures) do
        v:Uninit()
    end
    tbAllProcedures = {}
end


function HomelandSubProcedureSystem:Init()
    EventHelper = SelfEventHelper()
    RegisterProcedure(self)
end

function HomelandSubProcedureSystem:Uninit()
    UnregisterProcedure(self)
    EventHelper:UnregisterAll()
    EventHelper = nil
end

function HomelandSubProcedureSystem:OnEnterHomeland()
end

function HomelandSubProcedureSystem:OnLeaveHomeland()
end

-----------------------------------------给外部模块的调用接口---------------------------------------------

return HomelandSubProcedureSystem
