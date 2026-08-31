-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerPlayerHoldWeapon  = luaclass("GuideTriggerPlayerHoldWeapon", GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local HumanWeaponStateDef           = require("HumanWeaponStateDef")
local CommonEventDef                = require("CommonEventDef")
-----------------------------------------------------

function GuideTriggerPlayerHoldWeapon:CheckPlayerHoldWeapon()
    self:DebugLog("CheckPlayerHoldWeapon  ")
    local WeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if not WeaponComponent then
        return
    end
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    --tbCurrentWeapon.nSlot
    if tbCurrentWeapon and WeaponComponent:GetCurrentState() == HumanWeaponStateDef.HOLDED then
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerPlayerHoldWeapon:Begin()
    GuideTriggerPlayerHoldWeapon.super.Begin(self)
end

function GuideTriggerPlayerHoldWeapon:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, self.CheckPlayerHoldWeapon) 
end

return GuideTriggerPlayerHoldWeapon
