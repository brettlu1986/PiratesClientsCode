-----------------------------------------------------
--File Name    : ShipWeaponDeviationLevelDef.lua
--Author       : Song Fuhao
--Create Time  : 2019-08-29
--Description  : 舰船武器攻击类型
-----------------------------------------------------

local ShipWeaponDeviationLevelDef =
{
    LARGE      = 1, -- 较大
    LARGER     = 2, -- 大
    MEDIUM     = 3, -- 中
    SMALLER    = 4, -- 小
    SMALL      = 5, -- 较小
}

local tbDeviationLevelNames = nil

function ShipWeaponDeviationLevelDef:GetLevelName(nDeviationLevel)
    if tbDeviationLevelNames == nil then
        local UISetUtils = require("UISetUtils")
        tbDeviationLevelNames = {
            [ShipWeaponDeviationLevelDef.LARGE]   = UISetUtils.GetL10NTextByKey("SHIP_WEAPON_DEVIATION_LEVEL_LARGE"),
            [ShipWeaponDeviationLevelDef.LARGER]  = UISetUtils.GetL10NTextByKey("SHIP_WEAPON_DEVIATION_LEVEL_LARGER"),
            [ShipWeaponDeviationLevelDef.MEDIUM]  = UISetUtils.GetL10NTextByKey("SHIP_WEAPON_DEVIATION_LEVEL_MEDIUM"),
            [ShipWeaponDeviationLevelDef.SMALLER] = UISetUtils.GetL10NTextByKey("SHIP_WEAPON_DEVIATION_LEVEL_SMALLER"),
            [ShipWeaponDeviationLevelDef.SMALL]   = UISetUtils.GetL10NTextByKey("SHIP_WEAPON_DEVIATION_LEVEL_SMALL"),
        }
    end
    return tbDeviationLevelNames[nDeviationLevel]
end

return ShipWeaponDeviationLevelDef