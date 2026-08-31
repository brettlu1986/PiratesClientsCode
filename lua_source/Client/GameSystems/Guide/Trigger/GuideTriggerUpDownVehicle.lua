-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                       = require("luaclass")
local GuideTrigger                   = require("GuideTrigger")
local GuideTriggerUpDownVehicle       = luaclass("GuideTriggerUpDownVehicle", GuideTrigger)

local CommonEventDef            = require("CommonEventDef")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")

local HumanVehicleStateDef = require("HumanVehicleStateDef")
-----------------------------------------------------
GuideTriggerUpDownVehicle.szParam = nil
-----------------------------------------------------

function GuideTriggerUpDownVehicle:OnVehicleStateChange(Player, nState, nVehicleId)
    self:DebugLog("OnUpDownVehicle")
    local szParam = self.szParam
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if Player.ObjectType == PlayerSelf.ObjectType then
        if nState == HumanVehicleStateDef.AttachToVehicle and szParam == "up" then
            self:Trigger()
        elseif nState == HumanVehicleStateDef.None and szParam == "down" then
            self:Trigger()
        end
    end
end

--override
function GuideTriggerUpDownVehicle:Begin()
    GuideTriggerUpDownVehicle.super.Begin(self)
    local tbTemplate = self.tbTemplate
    if not tbTemplate.tbParam then
        return
    end
    self.szParam = tbTemplate.tbParam[1]
end

function GuideTriggerUpDownVehicle:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, self, self.OnVehicleStateChange)
end

return GuideTriggerUpDownVehicle
