local SAIWeaponStrategyDef = require("SAIWeaponStrategyDef")

local SAIWeaponStrategyFactory = { }

local tbWeaponStrategyList = {
    [SAIWeaponStrategyDef.NoChange]        = "SAIWeaponStrategyNoChange",
    [SAIWeaponStrategyDef.DistanceBased]   = "SAIWeaponStrategyDistanceBased",

}

function SAIWeaponStrategyFactory:CreateWeaponStrategy(nWeaponStrategy)
    if tbWeaponStrategyList[nWeaponStrategy] then
        return require(tbWeaponStrategyList[nWeaponStrategy])()
    end
end


return SAIWeaponStrategyFactory