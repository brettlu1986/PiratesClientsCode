
local luaclass = require("luaclass")
local GameCoreAgentSource  = luaclass("GameCoreAgentSource")
local GameCoreProxyClient  = require("GameCoreProxyClient")
local BattleTeamSystem     = require("BattleTeamSystem")
local DamageTypeEx         = require("DamageTypeEx")
local BotStateDef = require("MinimapBotStateDef")

function GameCoreAgentSource:OnStart()

end

function GameCoreAgentSource:GetSize()
    return #GameCoreProxyClient.tbAgents
end

function GameCoreAgentSource:QueryInfo(i)
    local nBotIndex = i
    local tbAgent = GameCoreProxyClient.tbAgents[i]
    if not tbAgent then
        return
    end
    local tbBot = tbAgent:GetGameObject()
    local tbBotInfo = {}
    local tbLocation = tbBot:GetLocation()
    tbBotInfo.instanceId = tbBot.nServerInstanceId
    tbBotInfo.x = tbLocation.X
    tbBotInfo.y = tbLocation.Y
    tbBotInfo.bot_index = nBotIndex
    tbBotInfo.human = tbBot:IsHuman()
    tbBotInfo.teamid = BattleTeamSystem:FindTeamId(tbBot)
    local nState = BotStateDef.RUNNING
    if tbBot:IsDying() then
        nState = BotStateDef.DYING
    elseif tbBot:IsDead() then
        if tbAgent.nDeadReason == DamageTypeEx.FALLING then
            nState = BotStateDef.FALLDEAD
        elseif tbAgent.nDeadReason == DamageTypeEx.POISON_CIRCLE then
            nState = BotStateDef.POISONDEAD
        elseif tbAgent.nDeadReason == DamageTypeEx.DROWN then
            nState = BotStateDef.DROWNDEAD
        else
            nState = BotStateDef.DEAD
        end
    end
    tbBotInfo.state = nState
    return tbBotInfo
end

return GameCoreAgentSource