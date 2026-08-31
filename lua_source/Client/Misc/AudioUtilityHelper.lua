local AudioUtilityHelper = {}

--[[
    注意：通过此Helper调用Audio_Utility的函数时，需要用.而不是:，类比到C++的静态函数，不需要传Self
]]

-- luacheck: push ignore 231
local AUDIO_UTILITY_CLASS = "Blueprint'/Game/Game/CharacterEx/Sound/Audio_Utility.Audio_Utility_C'"
local pAudioUtility = nil
local pHolder = nil

setmetatable(AudioUtilityHelper, {
    __index = function(t, key)
        if pAudioUtility == nil then
            pAudioUtility = AUDIO_UTILITY_CLASS:load()
            pHolder = luaholder(pAudioUtility)
        end
        return pAudioUtility[key]
    end,
    __newindex = nil
})
-- luacheck: pop

return AudioUtilityHelper
