

local DamageHurtDef = {
    HURT_NONE       = 0,
    HURT_CORE       = 1, --集中核心区
    HURT_LEAKING    = 1 << 1,  --造成漏水      
    HURT_FIRE       = 1 << 2,  --造成点火
}

function DamageHurtDef.IsLeaking(nFlag)
    return (1 << 1 & nFlag ) ~= 0
end

function DamageHurtDef.IsOnFire(nFlag)
    return ( 1 << 2 & nFlag ) ~= 0
end

function DamageHurtDef.IsHitCore(nFlag)
    return ( 1 & nFlag ) ~= 0
end

--ui按照这个顺序显示
function DamageHurtDef.GetHurtFlagResult(nFlag)
    return DamageHurtDef.IsHitCore(nFlag), DamageHurtDef.IsLeaking(nFlag), DamageHurtDef.IsOnFire(nFlag)
end

return DamageHurtDef
