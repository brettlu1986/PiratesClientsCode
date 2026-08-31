local luaclass = require("luaclass")
local GameCoreALFromConfig = luaclass("GameCoreALFromConfig")
local AIHelper = require("AIHelper")


function GameCoreALFromConfig:GetLevel(tbGameObject)
    local AILogic = AIHelper:GetAILogic(tbGameObject)
    if AILogic then
        return AILogic:GetLevel()
    end
    return 0
end

function GameCoreALFromConfig:Init()

end

return GameCoreALFromConfig