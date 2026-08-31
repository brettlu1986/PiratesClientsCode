local GameplayUtilityHelper = {}

--[[
    注意：通过此Helper调用BP_GameUtility的函数时，需要用.而不是:，类比到C++的静态函数，不需要传Self
]]

-- luacheck: push ignore 231
local GAMEPLAY_UTILITY_CLASS = "Blueprint'/Game/Game/Misc/BP_GameUtility.BP_GameUtility_C'"
local pGameplayUtility = nil
local pHolder = nil

setmetatable(GameplayUtilityHelper, {
    __index = function(t, key)
        if pGameplayUtility == nil then
            pGameplayUtility = GAMEPLAY_UTILITY_CLASS:load()
            pHolder = luaholder(pGameplayUtility)
        end
        return pGameplayUtility[key]
    end,
    __newindex = nil
})
-- luacheck: pop

return GameplayUtilityHelper
