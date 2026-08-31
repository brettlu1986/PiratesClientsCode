-----------------------------------------------------
--File Name    : HomelandPostEnterProcedure.lua
--Author       : WuJizhou
--Create Time  : 5/22/2019, 8:27:24 PM
--Description  : HomelandPostEnterProcedure
-----------------------------------------------------
local luaclass = require("luaclass")
local HomelandSubProcedureBase = require("HomelandSubProcedureBase")

local HomelandPostEnterProcedure = luaclass("HomelandPostEnterProcedure", HomelandSubProcedureBase)

local HomelandSystem = require("HomelandSystem")
local HomelandCGSystem = require("HomelandCGSystem")
local ClientEventDef = require("ClientEventDef")
local HomelandTreasureSystem = require("HomelandTreasureSystem")
local UIUtils = require("UIUtils")



local function PlayEnterMatinee(self)
    if HomelandSystem:IsFirstEntry() then
        local bRet = HomelandCGSystem:PlayEnterHomelandMatinee()
        if not bRet then
            self.EventHelper:FireEvent(ClientEventDef.EV_HOMELAND_ENTER_MATINEE_FINISHED)
        end
    else
        self.EventHelper:FireEvent(ClientEventDef.EV_HOMELAND_ENTER_MATINEE_FINISHED)
    end
end

local function PlayTransportTreasureMatinee(self)
    if HomelandTreasureSystem:HasTreasureInLobby() then
        HomelandCGSystem:PlayTransportTreasureMatinee()
    else
        UIUtils.ShowToastWithKey("HOMELAND_TREASURE_FAILED")
    end
end

function HomelandPostEnterProcedure:RegisterAllSteps()
    self:RegisterStep(PlayEnterMatinee, self, ClientEventDef.EV_HOMELAND_ENTER_MATINEE_FINISHED)
    self:RegisterStep(PlayTransportTreasureMatinee, self)
end


function HomelandPostEnterProcedure:GetProcedureFinishedEvent()
    return ClientEventDef.EV_HOMELAND_POST_ENTER_PROCEDURE_FINISHED
end

function HomelandPostEnterProcedure:GetProcedureTriggeredEvent()
    return ClientEventDef.EV_HOMELAND_READY
end

return HomelandPostEnterProcedure