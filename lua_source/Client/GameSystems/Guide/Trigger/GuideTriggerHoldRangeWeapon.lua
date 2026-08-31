-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerHoldRangeWeapon   = luaclass("GuideTriggerHoldRangeWeapon", GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local CommonEventDef                = require("CommonEventDef")
local HumanWeaponMisc               = require("HumanWeaponMisc")
-----------------------------------------------------

function GuideTriggerHoldRangeWeapon:CheckHoldRangeWeapon()
    self:DebugLog("CheckHoldRangeWeapon  ")
    local WeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if not WeaponComponent then
        self:DebugLog("CheckHoldRangeWeapon WeaponComponent is nil!!!")
        return
    end
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    self:DebugLog("CheckHoldRangeWeapon tbCurrentWeapon = " .. tostring(tbCurrentWeapon) .. " State = " .. tostring(WeaponComponent:GetCurrentState()))
    if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponMisc.Type.GUN) then
        self:DebugLog("CheckHoldRangeWeapon  Trigger")
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerHoldRangeWeapon:Begin()
    GuideTriggerHoldRangeWeapon.super.Begin(self)
end

function GuideTriggerHoldRangeWeapon:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, self.CheckHoldRangeWeapon) 
end

return GuideTriggerHoldRangeWeapon
