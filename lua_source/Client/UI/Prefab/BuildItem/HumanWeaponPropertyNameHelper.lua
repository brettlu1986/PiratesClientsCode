-----------------------------------------------------
--File Name    : HumanWeaponPropertyNameHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-09-19
--Description  : 人武器属性描述的helper
-----------------------------------------------------

local HumanWeaponPropertyNameHelper = {}

local UISetUtils = require("UISetUtils")
local HumanWeaponDef = require("HumanWeaponDef")

local RecoilLevel = HumanWeaponDef.RecoilLevel
local MeleeAttackSpeedLevel = HumanWeaponDef.MeleeAttackSpeedLevel

local tbRecoilLevelNames = {
    [RecoilLevel.Very_Strong]   = UISetUtils.GetL10NTextByKey("HUMAN_WEAPON_RECOIL_LEVEL_VERY_STRONG"),
    [RecoilLevel.Strong]        = UISetUtils.GetL10NTextByKey("HUMAN_WEAPON_RECOIL_LEVEL_STRONG"),
    [RecoilLevel.Normal]        = UISetUtils.GetL10NTextByKey("HUMAN_WEAPON_RECOIL_LEVEL_NORMAL"),
    [RecoilLevel.Weak]          = UISetUtils.GetL10NTextByKey("HUMAN_WEAPON_RECOIL_LEVEL_WEAK"),
    [RecoilLevel.Very_Weak]     = UISetUtils.GetL10NTextByKey("HUMAN_WEAPON_RECOIL_LEVEL_VERY_WEAK"),
}

local tbMeleeAttackSpeedLevelNames = {
    [MeleeAttackSpeedLevel.Very_Fast]   = UISetUtils.GetL10NTextByKey("MELEE_ATTACK_SPEED_LEVEL_VERY_FAST"),
    [MeleeAttackSpeedLevel.Fast]        = UISetUtils.GetL10NTextByKey("MELEE_ATTACK_SPEED_LEVEL_FAST"),
    [MeleeAttackSpeedLevel.Normal]      = UISetUtils.GetL10NTextByKey("MELEE_ATTACK_SPEED_LEVEL_NORMAL"),
    [MeleeAttackSpeedLevel.Slow]        = UISetUtils.GetL10NTextByKey("MELEE_ATTACK_SPEED_LEVEL_SLOW"),
    [MeleeAttackSpeedLevel.Very_Slow]   = UISetUtils.GetL10NTextByKey("MELEE_ATTACK_SPEED_LEVEL_VERY_SLOW"),
}

function HumanWeaponPropertyNameHelper.GetRecoilLevelName(nRecoilLevel)
    return tbRecoilLevelNames[nRecoilLevel]
end

function HumanWeaponPropertyNameHelper.GetMeleeAttackSpeedLevelName(nMeleeAttackSpeedLevel)
    return tbMeleeAttackSpeedLevelNames[nMeleeAttackSpeedLevel]
end

return HumanWeaponPropertyNameHelper