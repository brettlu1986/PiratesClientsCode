-----------------------------------------------------
--File Name    : AbilityEvent_HumanWeaponAttack.lua
--Author       : ZuoKun
--Create Time  : 4/27/2020
--Description  : AbilityEvent_HumanWeaponAttack
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_HumanWeaponAttack = luaclass("AbilityEvent_HumanCurrentWeaponChanged", AbilityEventBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")



local function OnHumanWeaponAttack(self, tbTaker, tbCauserOwner, nDamageType)
    local tbParams = {}
    tbParams.tbTaker = tbTaker
    tbParams.tbCauserOwner = tbCauserOwner
    tbParams.nDamageType = nDamageType
    self:TriggerDo(tbParams)
end




function AbilityEvent_HumanWeaponAttack:OnActivate()
    EventManager:BindEventMethod(CommonEventDef.EV_HUMAN_WEAPON_DAMAGE, self, OnHumanWeaponAttack)
end

function AbilityEvent_HumanWeaponAttack:OnDeactivate()
    EventManager:UnBindEventMethod(CommonEventDef.EV_HUMAN_WEAPON_DAMAGE, self, OnHumanWeaponAttack)
end

return AbilityEvent_HumanWeaponAttack