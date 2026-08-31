-----------------------------------------------------
--File Name    : HomelandPreLeaveProcedure.lua
--Author       : WuJizhou
--Create Time  : 5/22/2019, 8:27:24 PM
--Description  : HomelandPreLeaveProcedure
-----------------------------------------------------
local luaclass = require("luaclass")
local HomelandSubProcedureBase = require("HomelandSubProcedureBase")

local HomelandPreLeaveProcedure = luaclass("HomelandPreLeaveProcedure", HomelandSubProcedureBase)

local HomelandSystem = require("HomelandSystem")
local HomelandCGSystem = require("HomelandCGSystem")
local ClientEventDef = require("ClientEventDef")


local function PlayLeaveMatinee(self)
    if HomelandSystem:IsFirstEntry() then
        local bRet = HomelandCGSystem:PlayLeaveHomelandMatinee()
        if not bRet then
            self.EventHelper:FireEvent(ClientEventDef.EV_HOMELAND_LEAVE_MATINEE_FINISHED)
        end
    else
        self.EventHelper:FireEvent(ClientEventDef.EV_HOMELAND_LEAVE_MATINEE_FINISHED)
    end
end

function HomelandPreLeaveProcedure:RegisterAllSteps()
    self:RegisterStep(PlayLeaveMatinee, self, ClientEventDef.EV_HOMELAND_LEAVE_MATINEE_FINISHED)
end


function HomelandPreLeaveProcedure:GetProcedureFinishedEvent()
    return ClientEventDef.EV_HOMELAND_PRE_LEAVE_PROCEDURE_FINISHED
end

function HomelandPreLeaveProcedure:GetProcedureTriggeredEvent()
    return ClientEventDef.EV_HOMELAND_PRE_LEAVE_PROCEDURE_BEGIN
end

return HomelandPreLeaveProcedure