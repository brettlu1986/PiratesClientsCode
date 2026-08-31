local Defs = {
    KILL   = 1,
    DAMAGE = 2,
    RESCUE = 3,
    DAMAGE_COUNT = 4,  -- 造成伤害次数，除去持续性伤害
}

function Defs.Max()
    local nMax = 0
    for k,v in pairs(Defs) do
        nMax = nMax + 1
    end
    return nMax
end

return Defs