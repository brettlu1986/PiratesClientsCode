local luaclass = require("luaclass")
local BotSpawner = luaclass("BotSpawner")
local BotAISystem = dynamic_require("BotAISystem")
local AITemmateSystem = require("AITemmateSystem")

function BotSpawner.Spawn(nRequiredCount, nGrounpID, nTime)
    BotAISystem:ClearSpawnTimer()
    local nCurrentCount = BotAISystem:GetBotCount()
    if nRequiredCount > nCurrentCount then
        BotAISystem:Spawn(nRequiredCount - nCurrentCount, nGrounpID, nTime, nil)
    end
end

function BotSpawner.SpawnImmediately(nRequiredCount, nGrounpID, nTeamId)
    BotAISystem:ClearSpawnTimer()
    local nCurrentCount = BotAISystem:GetBotCount()
    if nRequiredCount > nCurrentCount then
        BotAISystem:Spawn(nRequiredCount - nCurrentCount, nGrounpID, 0, nTeamId)
    end

end

function BotSpawner.SpawnTeammate(nCount, nTeamId, nGrounpID)
    AITemmateSystem:SpawnTeammate(nCount, nTeamId, nGrounpID)
end


return BotSpawner