-----------------------------------------------------
--File Name    : GuideActionEndTriggerShipWeaponSlotChange.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerShipWeaponSlotChange    = luaclass("GuideActionEndTriggerShipWeaponSlotChange", GuideActionEndTriggerBase)

local CommonEventDef            = require("CommonEventDef")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
-----------------------------------------------------
local function OnShipActiveWeaponItemChanged(self, tbCharacter, NewActiveWeaponItem, OldActiveWeaponItem)
    if GamePlayerSelfHelper:Get() == tbCharacter then
        self:Triggered()
    end
end

function GuideActionEndTriggerShipWeaponSlotChange:BindEvent(tbParam)
    GuideActionEndTriggerShipWeaponSlotChange.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_ACTIVE_WEAPON_ITEM_CHANGED, self, OnShipActiveWeaponItemChanged)
end

return GuideActionEndTriggerShipWeaponSlotChange
