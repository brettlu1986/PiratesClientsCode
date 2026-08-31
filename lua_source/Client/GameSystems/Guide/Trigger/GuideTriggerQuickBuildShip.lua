-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerQuickBuildShip  = luaclass("GuideTriggerQuickBuildShip", GuideTrigger)

local ClientEventDef    = require("ClientEventDef")
-----------------------------------------------------
GuideTriggerQuickBuildShip.nShipBuildItemId = 0
-----------------------------------------------------

function GuideTriggerQuickBuildShip:OnReciveEvent(tbTemplateIds)
    self:DebugLog("OnReciveEvent," .. " self.nShipBuildItemId = " .. self.nShipBuildItemId)
    for i, nItemId in ipairs(tbTemplateIds) do
        if self.nShipBuildItemId == nItemId then
            self:Trigger()
            break
        end
    end
end

--override
function GuideTriggerQuickBuildShip:Begin()
    GuideTriggerQuickBuildShip.super.Begin(self)
    local tbTemplate = self.tbTemplate
    local tbParam = tbTemplate.tbParam
    if not tbParam then
        self:LogError("tbParam is nil!")
        return
    end
    self.nShipBuildItemId = tonumber(tbParam[1])
end

function GuideTriggerQuickBuildShip:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_QUICK_BUILD, self, self.OnReciveEvent)
end

return GuideTriggerQuickBuildShip
