-----------------------------------------------------
--File Name    : GuideActionStopShipRudderMove.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional         = require("GuideActionFunctional")
local GuideActionStopShipRudderMove = luaclass("GuideActionStopShipRudderMove",GuideActionFunctional)

--import
local ClientEventDef        = require("ClientEventDef")
--local 

local function StopShipRudderMove(self)
    local tbTemplate = self.tbTemplate
    local tbParam = tbTemplate.tbParam
    self.EventHelper:FireEvent(ClientEventDef.EV_STOP_SHIP_RUDDER_MOVE, tonumber(tbParam[2]))
end

function GuideActionStopShipRudderMove:DoAction(tbTemplate)
    GuideActionStopShipRudderMove.super.DoAction(self, tbTemplate)
    local tbParam = tbTemplate.tbParam
    if tbParam and tbParam[1] == "begin" then
        StopShipRudderMove(self)
    end
end

function GuideActionStopShipRudderMove:PreEnd()
    GuideActionStopShipRudderMove.super.PreEnd(self)
    local tbParam = self.tbTemplate.tbParam
    if not tbParam or tbParam[1] == "end" then
        StopShipRudderMove(self)
    end
end

return GuideActionStopShipRudderMove
