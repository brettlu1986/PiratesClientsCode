-----------------------------------------------------
--File Name    : GuideActionEndTriggerOnMovementChange.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerUnholdHumanWeapon    = luaclass("GuideActionEndTriggerUnholdHumanWeapon", GuideActionEndTriggerBase)

local CommonEventDef        = require("CommonEventDef")
local HumanWeaponStateDef   = require("HumanWeaponStateDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

local function OnWeaponStateChanged(self, nCurrentState, Owner)
    if Owner:GetServerInstanceId() ~= GamePlayerSelfHelper:GetServerInstanceId() then
        return 
    end

    if nCurrentState == HumanWeaponStateDef.UNHOLDING or nCurrentState == HumanWeaponStateDef.UNHOLDED then  
        self:Triggered()
    end
end

function GuideActionEndTriggerUnholdHumanWeapon:BindEvent(tbParam)
    GuideActionEndTriggerUnholdHumanWeapon.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, self, OnWeaponStateChanged)
end

return GuideActionEndTriggerUnholdHumanWeapon
