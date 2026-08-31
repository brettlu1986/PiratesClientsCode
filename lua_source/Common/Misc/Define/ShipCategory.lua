local ShipCategory = {
    BattleShip = 1,     -- 战列舰
    Frigate = 2,        -- 护卫舰
    Gunship = 3,        -- 炮艇
    MAX_COUNT = 3
}

-- luacheck: push ignore
local BPEnumPath = "UserDefinedEnum'/Game/Game/Ships/Misc/Enum_ShipType.Enum_ShipType'"
local BPEnum = BPEnumPath:load()
local pHolder = luaholder(BPEnum)
-- luacheck: pop

local BPEnumMap = {
    [ShipCategory.BattleShip]   = BPEnum.BattleShip,
    [ShipCategory.Frigate]      = BPEnum.Frigate,
    [ShipCategory.Gunship]      = BPEnum.Gunship,
}

function ShipCategory.GetBPEnum(nIndex)
    return BPEnumMap[nIndex]
end

return ShipCategory
