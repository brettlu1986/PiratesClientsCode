local luaclass = require("luaclass")
local AITemmateSystem = luaclass("AITemmateSystem")
local SelfEventHelperClass      = require("SelfEventHelper")
local CommonEventDef            = require("CommonEventDef")
local BattleTeamSystem          = require("BattleTeamSystem")
local GameCoreProxyClient       = require("GameCoreProxyClient")
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")
local BotGroupDataTable         = require("BotGroupDataTable")


AITemmateSystem.tbBots = nil
AITemmateSystem.SelfEventHelper = nil

local nMinAITemplateId = 3

local function LOG(...)
    log("CJ->AITemmateSystem:", ...)
end

local function OnParachuteEnd(self, tbGameObject, ...)
    if not GlobalVariableSystem:EnableSyncRealPlayerDataToAI() then
        return
    end
    local BotAISystem = dynamic_require("BotAISystem")
    if not BotAISystem:IsBot(tbGameObject) and not tbGameObject:IsDead() then
        local tbPlayers = BattleTeamSystem:GetTeamMembersByPlayer(tbGameObject)
        for i,v in ipairs(tbPlayers) do
            if BotAISystem:IsBot(v) then
                GameCoreProxyClient:SyncRealPlayer(tbGameObject)
                return
            end
        end
    end
end

function AITemmateSystem:Init()
    if GlobalVariableSystem:IsServerLogic() then
        local SelfEventHelper = SelfEventHelperClass()
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_PARACHUTION_END   , self, OnParachuteEnd)
        self.SelfEventHelper = SelfEventHelper
        self.tbBots = {}
    end
    return true
end

function AITemmateSystem:Uninit()
    if self.SelfEventHelper then
        self.SelfEventHelper:UnregisterAll()
        self.SelfEventHelper = nil
    end
    self.tbBots = nil
end

function AITemmateSystem:SpawnTeammate(nCount, nTeamId, nGrounpID)
    LOG("spawn ai teammate start", nCount, nTeamId, nGrounpID)
    local BotAISystem = dynamic_require("BotAISystem")
    local tbBotTemplates = { }
    local tbBotKinds = BotGroupDataTable:GetBotDatas(nGrounpID, nCount)
    for _,v in ipairs(tbBotKinds) do
        for i=1,v.nCount do
            table.insert(tbBotTemplates, v.nBotTemplateId)
        end
    end
    for i=1,nCount do
        local nBotTemplate = math.max(nMinAITemplateId, tbBotTemplates[i])
        LOG("spawn ai teammate", nTeamId, nBotTemplate)
        local tbBot = BotAISystem:CreateBot(nil, nBotTemplate, nTeamId)
        tbBot.pUEActor:SetActorIsReplicates(true)
        table.insert(self.tbBots, tbBot)
    end
    LOG("spawn ai teammate over", nCount, nTeamId, nGrounpID)
end

function AITemmateSystem:IsTeammate(tbGameObject)
    for i,v in ipairs(self.tbBots) do
        if v == tbGameObject then
            return true
        end
    end
    return false
end

return AITemmateSystem()