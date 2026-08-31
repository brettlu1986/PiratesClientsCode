-----------------------------------------------------
--File Name    : AbilityEvent_BeHit.lua
--Author       : Song Fuhao
--Create Time  : 2020-05-27
--Description  : 角色被击时触发
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBase = require("AbilityEventBase")
local AbilityEvent_BeHit = luaclass("AbilityEvent_BeHit", AbilityEventBase)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local function OnTakeDamage(self, tbTaker, tbCauser, nDamage, nDamageType, nHp, nItemTemplateId, tbDamageExtraData)
    if tbTaker ~= self.OwnerPawn then
        return
    end
    -- 判断Owner状态是人还是船
    -- 判断Causer状态是人还是船
    self:TriggerDo({tbTargetPawns={ tbCauser }})
end

function AbilityEvent_BeHit:OnActivate()
    EventManager:BindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
end

function AbilityEvent_BeHit:OnDeactivate()
    EventManager:UnBindEventMethod(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
end

return AbilityEvent_BeHit