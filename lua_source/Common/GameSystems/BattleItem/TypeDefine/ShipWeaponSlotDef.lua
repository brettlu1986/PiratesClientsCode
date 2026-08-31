-----------------------------------------------------
--File Name    : ShipWeaponSlotDef.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-13
--Description  : 船武器槽位定义
-----------------------------------------------------

local ShipWeaponSlotDef = {
    UNKNOWN     = 0,    -- 未知
    HEAD        = 1,    -- 船头武器
    SIDE        = 2,    -- 船舷武器
    DECK        = 3,    -- 甲板武器
    THROW       = 4,    -- 投掷武器

    MIN         = 1,    -- 枚举最小值
    MAX         = 4,    -- 枚举最大值

    COMMON_START= 1,    -- 常规武器枚举起始值
    COMMON_END  = 3,    -- 常规武器枚举结束值
}

local BPEnumName = {
    [ShipWeaponSlotDef.UNKNOWN] = "Default",
    [ShipWeaponSlotDef.HEAD]    = "Head",
    [ShipWeaponSlotDef.SIDE]    = "Side",
    [ShipWeaponSlotDef.DECK]    = "Deck",
    [ShipWeaponSlotDef.THROW]   = "Throw"
}

-- luacheck: push ignore
local ShipWeaponSlotPath = "UserDefinedEnum'/Game/Game/ShipEx/Misc/Enum_ShipWeaponSlot.Enum_ShipWeaponSlot'"
local EnumShipWeaponSlot = ShipWeaponSlotPath:load()
local pHolder = luaholder(EnumShipWeaponSlot)
-- luacheck: pop

--- 是否为有效槽位
function ShipWeaponSlotDef.IsValid(nIndex)
    return nIndex and (nIndex >= ShipWeaponSlotDef.MIN) and (nIndex <= ShipWeaponSlotDef.MAX)
end

--- 获取槽位的蓝图枚举名字
function ShipWeaponSlotDef.GetBPEnumName(nIndex)
    return BPEnumName[nIndex]
end

--- 获取槽位的蓝图枚举对象
function ShipWeaponSlotDef.GetBPEnum(nIndex)
    local szBPEnumName = ShipWeaponSlotDef.GetBPEnumName(nIndex)
    return EnumShipWeaponSlot[szBPEnumName]
end

return ShipWeaponSlotDef