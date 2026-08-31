-----------------------------------------------------
--File Name    : GuideTriggerOnEquipShip.lua
--Description  : 当装配某艘舰船时的trigger
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideTrigger              = require("GuideTrigger")
local GuideTriggerOnEquipShip   = luaclass("GuideTriggerOnEquipShip", GuideTrigger)

local ClientEventDef            = require("ClientEventDef")
-----------------------------------------------------

-----------------------------------------------------

local function OnReceiveEuipShipResult(self, nSlotId, nTemplateId)
    if not nTemplateId then
        return
    end
    local tbParam = self.tbTemplate.tbParam
    local szTemplateId = tostring(nTemplateId)
    if not tbParam then
        return
    end
    for i,v in ipairs(tbParam) do
        if szTemplateId == v then
            self:Trigger()    
            return
        end
    end
    self:Break()
end

--override
function GuideTriggerOnEquipShip:Begin()
    GuideTriggerOnEquipShip.super.Begin(self)
end

function GuideTriggerOnEquipShip:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_EQUIP_SHIP_RESULT, self, OnReceiveEuipShipResult)
end

return GuideTriggerOnEquipShip
