
local GamePlayerTypeDef = {}

local L10N = require("L10N")


--人物相关枚举定义

--阵营
local L10N_FATIONTEXT = 
{
    L10N:MakeText("GamePlayerTypeDef", "Nothing"    , "无阵营"),
    L10N:MakeText("GamePlayerTypeDef", "England"    , "英国"),
    L10N:MakeText("GamePlayerTypeDef", "Spain"      , "西班牙"),
    L10N:MakeText("GamePlayerTypeDef", "Pirate"     , "海盗"),
}

function GamePlayerTypeDef:GetFactionText( nFaction )
    if #L10N_FATIONTEXT < nFaction then
        return nil
    end

    return L10N_FATIONTEXT[nFaction+1]
end


return GamePlayerTypeDef