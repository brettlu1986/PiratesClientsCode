-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerSprintWithWeapon  = luaclass("GuideTriggerSprintWithWeapon", GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local HumanWeaponStateDef           = require("HumanWeaponStateDef")
local ClientEventDef                = require("ClientEventDef")
-----------------------------------------------------

function GuideTriggerSprintWithWeapon:CheckPlayerHoldWeapon()
    self:DebugLog(":CheckPlayerHoldWeapon")
    local WeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if not WeaponComponent then
        return
    end
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    if tbCurrentWeapon and tbCurrentWeapon.nSlot < 3 and WeaponComponent:GetCurrentState() == HumanWeaponStateDef.HOLDED then
        self:Trigger()
    end
end

--override
function GuideTriggerSprintWithWeapon:Begin()
    GuideTriggerSprintWithWeapon.super.Begin(self)
end

function GuideTriggerSprintWithWeapon:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_SPRINT, self, self.CheckPlayerHoldWeapon) 
end

return GuideTriggerSprintWithWeapon
