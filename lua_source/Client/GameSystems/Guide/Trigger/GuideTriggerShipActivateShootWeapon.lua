-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerShipActivateShootWeapon   = luaclass("GuideTriggerShipActivateShootWeapon", GuideTrigger)

local ShipWeaponTemplateDef         = require("ShipWeaponTemplateDef")
local CommonEventDef                = require("CommonEventDef")
local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
-----------------------------------------------------

function GuideTriggerShipActivateShootWeapon:OnShipActiveWeaponItemChanged(tbCharacter, NewActiveWeaponItem)
    self:DebugLog("OnShipWeaponActivate ")
    if GamePlayerSelfHelper:Get() ~= tbCharacter then
        return
    end
    local nTemplateType = NewActiveWeaponItem and NewActiveWeaponItem:GetTemplateType()
    if nTemplateType ~= ShipWeaponTemplateDef.EMBOLON and nTemplateType ~= ShipWeaponTemplateDef.FLAMER then 
        self:Trigger()
    end
end

--override
function GuideTriggerShipActivateShootWeapon:Begin()
    GuideTriggerShipActivateShootWeapon.super.Begin(self)
end

function GuideTriggerShipActivateShootWeapon:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_ACTIVE_WEAPON_ITEM_CHANGED, self, self.OnShipActiveWeaponItemChanged)
end

return GuideTriggerShipActivateShootWeapon
