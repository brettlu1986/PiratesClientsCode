-----------------------------------------------------
--File Name    : AbilityAction_ApplyShipLeakingDamage.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-01
--Description  : 舰船漏水伤害
--Param        : Value 数值，具体函数参考ValueType
--               ValueType 数值类型，百分比/固定值，默认百分比，参见BattleAbilityDefine.ValueType
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ApplyShipLeakingDamage = luaclass("AbilityAction_ApplyShipLeakingDamage", AbilityActionBase)

local PropName = require("PropName")
local PropUtil = require("PropUtil")
local SDCHelper = require("SDCHelper")
local DamageTypeEx = require("DamageTypeEx")
local BattleAbilityDefine = require("BattleAbilityDefine")

AbilityAction_ApplyShipLeakingDamage.nDamage = 0

function AbilityAction_ApplyShipLeakingDamage:OnCreate(Owner, tbInitParams)
    local nBaseDamage = tbInitParams.Value
    if tbInitParams.ValueType ~= BattleAbilityDefine.ValueType.FIXED then
        local nTakerMaxHp = self.OwnerPawn.ShipBattlePropertyComponent:GetMaxHp()
        local nBaseRatio = tbInitParams.Value
        nBaseDamage = nTakerMaxHp * nBaseRatio
        SDCHelper.LOG("[Leaking] 船最大血量 : " .. nTakerMaxHp)
        SDCHelper.LOG("[Leaking] 默认每秒扣血百分比 : " .. nBaseRatio)
    end

    local nCauserDamageRatio = self.tbInstigator and self.tbInstigator.ShipBattlePropertyComponent:GetProp(PropName.nLeakingDamageRatioCaused) or 1
    local nTakerDamageRatio = self.OwnerPawn.ShipBattlePropertyComponent:GetProp(PropName.nLeakingDamageRatioTaken)
    self.nDamage = nBaseDamage * nCauserDamageRatio * nTakerDamageRatio
    SDCHelper.LOG("[Leaking] 默认基础每秒扣血值 : " .. nBaseDamage)
    SDCHelper.LOG("[Leaking] 攻击方造成漏水伤害比例 : " .. nCauserDamageRatio)
    SDCHelper.LOG("[Leaking] 受击方受到漏水伤害比例 : " .. nTakerDamageRatio)
    SDCHelper.LOG("[Leaking] 最终每秒扣血值 : " .. self.nDamage)
end

function AbilityAction_ApplyShipLeakingDamage:OnDo(tbParams)
    PropUtil.ApplyDamage(self.OwnerPawn, self.tbInstigator, DamageTypeEx.SHIP_LEAKING, self.nDamage)
end

return AbilityAction_ApplyShipLeakingDamage
