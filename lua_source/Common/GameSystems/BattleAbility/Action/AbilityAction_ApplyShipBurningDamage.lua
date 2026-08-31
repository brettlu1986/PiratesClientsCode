-----------------------------------------------------
--File Name    : AbilityAction_ApplyShipBurningDamage.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-01
--Description  : 舰船点火伤害
--Param        : Value 数值，具体函数参考ValueType
--               ValueType 数值类型，百分比/固定值，默认百分比，参见BattleAbilityDefine.ValueType
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ApplyShipBurningDamage = luaclass("AbilityAction_ApplyShipBurningDamage", AbilityActionBase)

local PropName = require("PropName")
local PropUtil = require("PropUtil")
local SDCHelper = require("SDCHelper")
local DamageTypeEx = require("DamageTypeEx")
local BattleAbilityDefine = require("BattleAbilityDefine")

AbilityAction_ApplyShipBurningDamage.nDamage = 0

function AbilityAction_ApplyShipBurningDamage:OnCreate(Owner, tbInitParams)
    local nBaseDamage = tbInitParams.Value
    if tbInitParams.ValueType ~= BattleAbilityDefine.ValueType.FIXED then
        local nTakerMaxHp = self.OwnerPawn.ShipBattlePropertyComponent:GetMaxHp()
        local nBaseRatio = tbInitParams.Value
        nBaseDamage = nTakerMaxHp * nBaseRatio
        SDCHelper.LOG("[Burning] 船最大血量 : " .. nTakerMaxHp)
        SDCHelper.LOG("[Burning] 默认每秒扣血百分比 : " .. nBaseRatio)
    end

    local nCauserDamageRatio = self.tbInstigator and self.tbInstigator.ShipBattlePropertyComponent:GetProp(PropName.nBurningDamageRatioCaused) or 1
    local nTakerDamageRatio = self.OwnerPawn.ShipBattlePropertyComponent:GetProp(PropName.nBurningDamageRatioTaken)
    self.nDamage = nBaseDamage * nCauserDamageRatio * nTakerDamageRatio
    SDCHelper.LOG("[Burning] 默认基础每秒扣血值 : " .. nBaseDamage)
    SDCHelper.LOG("[Burning] 攻击方造成着火伤害比例 : " .. nCauserDamageRatio)
    SDCHelper.LOG("[Burning] 受击方受到着火伤害比例 : " .. nTakerDamageRatio)
    SDCHelper.LOG("[Burning] 最终每秒扣血值 : " .. self.nDamage)
end

function AbilityAction_ApplyShipBurningDamage:OnDo(tbParams)
    PropUtil.ApplyDamage(self.OwnerPawn, self.tbInstigator, DamageTypeEx.SHIP_FIRING, self.nDamage)
end


return AbilityAction_ApplyShipBurningDamage
