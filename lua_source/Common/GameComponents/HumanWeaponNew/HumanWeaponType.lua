local HumanWeaponType = {}

--[[
    注意：通过此Helper调用ShipUtility的函数时，需要用.而不是:，类比到C++的静态函数，不需要传Self
]]

-- luacheck: push ignore 231
local ENUM_WEAPON_TYPE_CLASS = "/Game/Game/CharacterEx/Weapon/Enum_HumanWeaponType.Enum_HumanWeaponType"
local pWeaponType = nil
local pHolder = nil

setmetatable(HumanWeaponType, {
    __index = function(t, key)
        if pWeaponType == nil then
            pWeaponType = ENUM_WEAPON_TYPE_CLASS:load()
            pHolder = luaholder(pWeaponType)
        end
        return pWeaponType[key]
    end,
    __newindex = nil
})
-- luacheck: pop

return HumanWeaponType
