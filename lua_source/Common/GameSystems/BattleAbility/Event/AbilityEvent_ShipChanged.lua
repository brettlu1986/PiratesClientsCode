-----------------------------------------------------
--File Name    : AbilityEvent_ShipChanged.lua
--Author       : Song Fuhao
--Create Time  : 2020-05-19
--Description  : 换船时触发
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_ShipChanged = luaclass("AbilityEvent_ShipChanged", AbilityEventBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local function OnPlayerShipChanged(self, tbPlayer, _nShipId)
    if tbPlayer == self.OwnerPawn then
        self:TriggerDo()
    end
end

function AbilityEvent_ShipChanged:OnActivate()
    EventManager:BindEventMethod(CommonEventDef.EV_ON_PLAYER_SHIP_CHANGED_SERVER, self, OnPlayerShipChanged)
end

function AbilityEvent_ShipChanged:OnDeactivate()
    EventManager:UnBindEventMethod(CommonEventDef.EV_ON_PLAYER_SHIP_CHANGED_SERVER, self, OnPlayerShipChanged)
end

return AbilityEvent_ShipChanged
