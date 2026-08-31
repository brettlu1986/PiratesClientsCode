
local GameCoreAgentLevelRegister = { }

local function Register(szName, szFile)
    GameCoreAgentLevelRegister[szName] = szFile
end


--Register("test",    "GameCoreALSimple")
Register("from_config",  "GameCoreALFromConfig")


function GameCoreAgentLevelRegister:GetStrategyFile(szName)
    return self[szName]
end

return GameCoreAgentLevelRegister