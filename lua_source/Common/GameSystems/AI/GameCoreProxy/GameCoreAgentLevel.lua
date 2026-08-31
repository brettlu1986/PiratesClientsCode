
local GameCoreAgentLevelRegister = require("GameCoreAgentLevelRegister")

local GameCoreAgentLevel = { }
GameCoreAgentLevel.tbStrategy = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCoreAgentLevel:", ...)
end
-- luacheck: pop

function GameCoreAgentLevel:InitStrategy(szStrategy)
    if szStrategy and szStrategy ~= "" then
        LOG("init strategy:", szStrategy)
        local szStrategyFile = GameCoreAgentLevelRegister:GetStrategyFile(szStrategy)
        if not szStrategyFile then
            szStrategyFile = szStrategy
        end
        local tbStrategy = require(szStrategyFile)()
        tbStrategy:Init()
        self.tbStrategy = tbStrategy
    end
end

function GameCoreAgentLevel:GetAgentLevel(tbGameObject)
    if self.tbStrategy then
        return self.tbStrategy:GetLevel(tbGameObject)
    end
    return 0
end

function GameCoreAgentLevel:Uninit()
    self.tbStrategy = nil
end

return GameCoreAgentLevel