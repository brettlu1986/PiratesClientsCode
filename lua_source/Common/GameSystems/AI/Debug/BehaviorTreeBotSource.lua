
local luaclass = require("luaclass")
local BehaviorTreeBotSource = luaclass("BehaviorTreeBotSource")
local BotAISystem  = dynamic_require("BotAISystem")
local AIHelper              = require("AIHelper")
local SAILogicDef           = require("SAILogicDef")
local SAIDeliveryBotSystem          = require("SAIDeliveryBotSystem")
local SAISystemDef          = require("SAISystemDef")

local BotStateDef = require("MinimapBotStateDef")

function BehaviorTreeBotSource:OnStart()

end

function BehaviorTreeBotSource:GetSize()
    return #BotAISystem.tbBots
end

function BehaviorTreeBotSource:QueryInfo(i)
    local nBotIndex = i
    local tbBot = BotAISystem.tbBots[i]
    if not tbBot then
        return
    end
    local tbBotInfo = {}
    local tbLocation = tbBot:GetLocation()
    tbBotInfo.instanceId = tbBot.nServerInstanceId
    tbBotInfo.x = tbLocation.X
    tbBotInfo.y = tbLocation.Y
    tbBotInfo.bot_index = nBotIndex
    tbBotInfo.human = tbBot:IsHuman()
    local nState = BotStateDef.RUNNING
    if tbBot:IsDead() then
        nState = BotStateDef.DEAD
    elseif AIHelper:IsRunningAILogic(tbBot, SAILogicDef.Bot) then
        local pAIController = AIHelper.GetActivedAIController(tbBot)
        local pBlackboard = pAIController.Blackboard
        local bDying = tbBot.SAIEntityComponent:GetIsDying()
        local bSending = SAIDeliveryBotSystem:IsInSending(tbBot)
        local pAttackTarget = pBlackboard:GetValueAsObject("AttackTarget")
        local bBuildItem = pBlackboard:GetValueAsBool("IsBuildingItem")
        local pGoalLocation = pBlackboard:GetValueAsVector("GoalLocation")
        local bIsEscaping = tbBot.SAIComponent:GetSystem(SAISystemDef.Escape):IsEscaping()
        if bDying then
            nState = BotStateDef.DYING
        elseif pAttackTarget then
            nState = BotStateDef.FIGHTING
        elseif bBuildItem then
            nState = BotStateDef.BUILDING
        elseif bSending then
            nState = BotStateDef.DHL
            tbBotInfo.mov_x = pGoalLocation.X
            tbBotInfo.mov_y = pGoalLocation.Y
        elseif bIsEscaping then
            nState = BotStateDef.ESCAPING
            tbBotInfo.mov_x = pGoalLocation.X
            tbBotInfo.mov_y = pGoalLocation.Y
        end
    end
    tbBotInfo.state = nState
    return tbBotInfo
end

return BehaviorTreeBotSource