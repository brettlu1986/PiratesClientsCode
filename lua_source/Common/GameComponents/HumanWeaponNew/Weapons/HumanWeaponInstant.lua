local luaclass = require("luaclass")
local HumanWeaponGunBase = dynamic_require("HumanWeaponGunBase")
local HumanWeaponInstant = luaclass("HumanWeaponInstant", HumanWeaponGunBase)

local HumanWeaponMisc = require("HumanWeaponMisc")

local SELF_TYPE = HumanWeaponMisc.Type.INSTANT

function HumanWeaponInstant:GetType()
    return SELF_TYPE
end

function HumanWeaponInstant:CheckAttackIllegal(StartPos, EndPos, Taker, nHitBodyType)
    local szReason = self:CheckAttackIllegalOnFire(StartPos)
    if szReason then
        return szReason
    end
    return HumanWeaponInstant.super.CheckAttackIllegal(self, StartPos, EndPos, Taker, nHitBodyType)
end

return HumanWeaponInstant