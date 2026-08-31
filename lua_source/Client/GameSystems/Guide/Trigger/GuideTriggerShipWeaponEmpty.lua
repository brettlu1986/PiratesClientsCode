-----------------------------------------------------
--File Name    : GuideTriggerShipWeaponEmpty.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerShipWeaponEmpty   = luaclass("GuideTriggerShipWeaponEmpty", GuideTrigger)

local ClientEventDef            = require("ClientEventDef")
-----------------------------------------------------

local function CheckBulletCount(self, nCount)
    local nTargetCount = tonumber(self.tbParam[1])
    if nCount == nTargetCount then
        self:Trigger()
    end
end

--override
function GuideTriggerShipWeaponEmpty:Begin()
    GuideTriggerShipWeaponEmpty.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam 
    if tbParam and tbParam[1] then
        self.tbParam = tbParam
        return
    end
end

function GuideTriggerShipWeaponEmpty:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_WEAPON_BULLET_COUNT, self, CheckBulletCount)
end

return GuideTriggerShipWeaponEmpty
