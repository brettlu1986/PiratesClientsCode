-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTriggerHoldRangeWeapon   = require("GuideTriggerHoldRangeWeapon")
local GuideTriggerWeaponStateChange = luaclass("GuideTriggerWeaponStateChange", GuideTriggerHoldRangeWeapon)
-----------------------------------------------------

function GuideTriggerWeaponStateChange:CheckHoldRangeWeapon()
    self:DebugLog("CheckHoldRangeWeapon")
    self:Trigger()
end

--override
function GuideTriggerWeaponStateChange:Begin()
    GuideTriggerWeaponStateChange.super.Begin(self)
end

return GuideTriggerWeaponStateChange
