-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerNoneWeapon       = luaclass("GuideActionEndTriggerNoneWeapon", GuideActionEndTriggerBase)

local CommonEventDef        = require("CommonEventDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

local function CheckHoldWeapon(self, nNewWeaponId, nLastWeaponId, nPlayerInstanceId)
    self:DebugLog("GuideActionForceEndGroup:CheckHoldRangeWeapon  ")
    if nPlayerInstanceId ~= GamePlayerSelfHelper:GetServerInstanceId() then
        return 
    end
    self:Triggered()
end

function GuideActionEndTriggerNoneWeapon:BindEvent(tbParam)
    GuideActionEndTriggerNoneWeapon.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, CheckHoldWeapon)
end

return GuideActionEndTriggerNoneWeapon
