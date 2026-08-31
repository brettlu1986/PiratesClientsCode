local AIUtilityHelper = {}

--[[
    注意：通过此Helper调用BP_AIUtility的函数时，需要用.而不是:，类比到C++的静态函数，不需要传Self
]]

-- luacheck: push ignore 231
local AI_UTILITY_CLASS = "Blueprint'/Game/Game/AI/AISegma/Misc/AI_HelperLib.AI_HelperLib_C'"
local pAIUtility = nil
local pHolder = nil

setmetatable(AIUtilityHelper, {
    __index = function(t, key)
        if pAIUtility == nil then
            pAIUtility = AI_UTILITY_CLASS:load()
            pHolder = luaholder(pAIUtility)
        end
        return pAIUtility[key]
    end,
    __newindex = nil
})
-- luacheck: pop

return AIUtilityHelper
