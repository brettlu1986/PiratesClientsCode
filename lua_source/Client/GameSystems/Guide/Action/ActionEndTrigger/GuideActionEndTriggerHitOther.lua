-----------------------------------------------------
--File Name    : GuideActionEndTriggerHitOther.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerHitOther             = luaclass("GuideActionEndTriggerHitOther", GuideActionEndTriggerBase)

-- local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local CommonEventDef        = require("CommonEventDef")
-----------------------------------------------------

local function OnTakeDamage(self, tbTaker, tbCauser, nDamage, nDamageType, nHp, nWeaponTempId, tbExtraData)
    -- local PlayerSelf = GamePlayerSelfHelper:Get()
    -- if not PlayerSelf then
    --     return
    -- end
    -- local bHitBySelf = tbCauser and tbCauser.nServerInstanceId == PlayerSelf:GetServerInstanceId()
    -- self:DebugLog("bHitBySelf = " .. tostring(bHitBySelf))
    -- if bHitBySelf then
    --     self:Triggered()
    -- end
    self:Triggered()
end

function GuideActionEndTriggerHitOther:BindEvent(tbParam)
    GuideActionEndTriggerHitOther.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
end

return GuideActionEndTriggerHitOther
