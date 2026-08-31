local GameCoreHelper = {}
local GameCoreProxyClient = require("GameCoreProxyClient")
local GameCoreAgentDistribution = require("GameCoreAgentDistribution")
local SAIDeliveryBotSystem = require("SAIDeliveryBotSystem")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCoreHelper:", ...)
end
-- luacheck: pop


function GameCoreHelper:ChangeBotToDLAgent(tbGameObject, nLevel)
    if tbGameObject:IsDead() then
        return
    end
    local bShouldChange = GameCoreAgentDistribution:ShouldChangeToAgent(tbGameObject)
    if bShouldChange then
        SAIDeliveryBotSystem:UnregisterBot(tbGameObject)
        GameCoreProxyClient:Possess(tbGameObject, nLevel)
        LOG("changed bot to agent:", tbGameObject.szName)
    end
end

function GameCoreHelper.ShowAgentName(bShow)
    for _,v in ipairs(GameCoreProxyClient.tbAgents) do
        v:ShowName(bShow)
    end
end


return GameCoreHelper