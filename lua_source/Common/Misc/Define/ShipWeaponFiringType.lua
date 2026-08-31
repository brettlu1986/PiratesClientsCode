-----------------------------------------------------
--File Name    : ShipWeaponFiringType.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-29
--Description  : 舰船武器开火类型
-----------------------------------------------------
local ShipWeaponFiringType =  {
    FIRING_WITH_ONE = 1,    -- 按颗发射
    FIRING_WITH_ROW = 2,    -- 按排发射
    FIRING_WITH_ALL = 3     -- 全部发射
}

-- luacheck: push ignore
local ShipWeaponFiringTypePath = "UserDefinedEnum'/Game/Game/ShipEx/Misc/Enum_ShipWeaponFiringType.Enum_ShipWeaponFiringType'"
local EnumShipWeaponFiringType = ShipWeaponFiringTypePath:load()
local pHolder = luaholder(EnumShipWeaponFiringType)
-- luacheck: pop

local BPEnum = {
    [ShipWeaponFiringType.FIRING_WITH_ONE] = EnumShipWeaponFiringType.FiringWithOne,
    [ShipWeaponFiringType.FIRING_WITH_ROW] = EnumShipWeaponFiringType.FiringWithRow,
    [ShipWeaponFiringType.FIRING_WITH_ALL] = EnumShipWeaponFiringType.FiringWithAll
}

function ShipWeaponFiringType.GetBPEnum(nIndex)
    return BPEnum[nIndex]
end

return ShipWeaponFiringType