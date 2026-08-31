-----------------------------------------------------
--File Name    : GuideActionEndTriggerShipWeaponEmpty.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerShipWeaponEmpty      = luaclass("GuideActionEndTriggerShipWeaponEmpty", GuideActionEndTriggerBase)

local ClientEventDef            = require("ClientEventDef")
-----------------------------------------------------

local function CheckShipWeaponEmpty(self, nCount)
    local nTargetCount = tonumber(self.tbParam[1])
    if nCount == nTargetCount then
        self:DebugLog("ship weapon is empty ")
        self:Triggered()
    end
end

function GuideActionEndTriggerShipWeaponEmpty:BindEvent(tbParam)
    GuideActionEndTriggerShipWeaponEmpty.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_WEAPON_BULLET_COUNT, self, CheckShipWeaponEmpty)
end

return GuideActionEndTriggerShipWeaponEmpty
