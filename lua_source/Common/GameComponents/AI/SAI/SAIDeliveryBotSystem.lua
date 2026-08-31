local luaclass = require("luaclass")
local SAIDeliveryBotSystem = luaclass("SAIDeliveryBotSystem")
local SelfEventHelperClass  = require("SelfEventHelper")
local CommonEventDef        = require("CommonEventDef")
local GameObjectSystem      = dynamic_require("GameObjectSystem")
local Timer                 = require("Timer")
local GameObjectTypeDef     = require("GameObjectTypeDef")
local AIHelper              = require("AIHelper")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local SAISystemDef          = require("SAISystemDef")
local SAIThreatStrategyDef  = require("SAIThreatStrategyDef")


SAIDeliveryBotSystem.tbBots = nil
SAIDeliveryBotSystem.tbDelivingBots = nil
SAIDeliveryBotSystem.nBotSenderDelayTime = 0
SAIDeliveryBotSystem.bEnable = false

local function LOG(...)
    log("CJ->SAIDeliveryBotSystem:", ...)
end


local function IsSending(self, tbGameObject)
    local nServerInstanceId = tbGameObject.nServerInstanceId
    for k,v in pairs(self.tbDelivingBots) do
        if k == nServerInstanceId and v then
            return true
        end
    end
    return false
end

local function BotStopSend(tbGameObject)
    if tbGameObject and tbGameObject:IsAlive() then
        LOG("stop send", tbGameObject.szName)
        local AILogic = AIHelper:GetAILogic(tbGameObject)
        if AILogic and AILogic:IsEnabled() then
            local tbSeekTargetSystem = AIHelper:GetAISystem(tbGameObject, SAISystemDef.SeekTarget)
            if tbSeekTargetSystem then
                tbSeekTargetSystem:StopSeek()
                tbGameObject.SAIEntityComponent:SetInvisibleFromAI(false)
            end
            local tbTreatSystem = AIHelper:GetAISystem(tbGameObject, SAISystemDef.Threat)
            if tbTreatSystem then
                tbTreatSystem:Active(SAIThreatStrategyDef.AnyEnemy)
            end
        end
    end
end


local function BotStartSend(tbGameObject, tbTargetObject)
    if tbGameObject and tbGameObject:IsAlive() then
        LOG("start bot send:", tbGameObject.szName, "->", tbTargetObject.szName)
        local AILogic = AIHelper:GetAILogic(tbGameObject)
        if AILogic and AILogic:IsEnabled() then
            local tbSeekTargetSystem = AIHelper:GetAISystem(tbGameObject, SAISystemDef.SeekTarget)
            if tbSeekTargetSystem then
                tbSeekTargetSystem:SeekTarget(tbTargetObject)
                tbGameObject.SAIEntityComponent:SetInvisibleFromAI(true)
            end
            local tbTreatSystem = AIHelper:GetAISystem(tbGameObject, SAISystemDef.Threat)
            if tbTreatSystem then
                tbTreatSystem:Active(SAIThreatStrategyDef.RealPlayer)
            end
        end
    end
end


local function SendABot(self, tbGameObject)
    local pUEActor = tbGameObject.pUEActor
    if not pUEActor then
        return
    end
    local nMinDistance = -1
    local tbFoundBot = nil
    for i,v in ipairs(self.tbBots) do
        if v:IsAlive() and not IsSending(self, v) then
            local nTempDistance = pUEActor:GetDistanceTo(v.pUEActor)
            if nTempDistance < nMinDistance or nMinDistance < 0 then
                nMinDistance = nTempDistance
                tbFoundBot = v
            end
        end
    end
    if tbFoundBot then
        BotStartSend(tbFoundBot, tbGameObject)
        self.tbDelivingBots[tbFoundBot.nServerInstanceId] = tbGameObject
        LOG("start send:", tbFoundBot.szName, "->", tbGameObject.szName)
    else
        LOG("not bot can send")
    end
end

function SAIDeliveryBotSystem:OnPlayerLoginOut(tbGameObject)
    if self.bEnable then
        for k,v in pairs(self.tbDelivingBots) do
            if v and v == tbGameObject then
                self.tbDelivingBots[k] = nil
                local tbBot = GameObjectSystem:FindByInstanceId(k)
                BotStopSend(tbBot)
                return
            end
        end
    end
end

function SAIDeliveryBotSystem:OnParachutionEnd(tbGameObject, bIsShip, bIsTransport, pTransportLocation)
    if not AIHelper.IsAIControlled(tbGameObject) then
        if self.bEnable then
            SendABot(self, tbGameObject)
        elseif self.nBotSenderDelayTime > 0 then
            self:SetDelaySender(self.nBotSenderDelayTime)
            self.nBotSenderDelayTime = 0
        end
    end
end


function SAIDeliveryBotSystem:OnPawnDead(tbGameObject)
    if self.bEnable then
        local nServerInstanceId = tbGameObject.nServerInstanceId
        for k,v in pairs(self.tbDelivingBots) do
            if v then
                if k == nServerInstanceId then
                    self.tbDelivingBots[k] = nil
                    SendABot(self, v)
                    return
                elseif v == tbGameObject then
                    self.tbDelivingBots[k] = nil
                    local tbBot = GameObjectSystem:FindByInstanceId(k)
                    BotStopSend(tbBot)
                    return
                end
            end
        end
    end
end

function SAIDeliveryBotSystem:OnEndChangeDisplay(tbGameObject)
    if self.bEnable then
        local nServerInstanceId = tbGameObject.nServerInstanceId
        for k,v in pairs(self.tbDelivingBots) do
            if v == tbGameObject then
                local tbBot = GameObjectSystem:FindByInstanceId(k)
                BotStartSend(tbBot, tbGameObject)
                return
            elseif k == nServerInstanceId and v then
                BotStartSend(tbGameObject, v)
            end
        end
        if not AIHelper.IsAIControlled(tbGameObject) then
            SendABot(self, tbGameObject)
        end
    end
end

function SAIDeliveryBotSystem:ClearDelaySenderTimer()
    if self.tbDelaySenderTimer then
        self.tbDelaySenderTimer:Clear()
        self.tbDelaySenderTimer = nil
    end
end

function SAIDeliveryBotSystem:SetDelaySender(nTime)
    self:ClearDelaySenderTimer()
    if nTime > 0 then
        self.tbDelaySenderTimer = Timer.NewTimer(function()
            self.bEnable = true
            local nPlayerSelfDef = GameObjectTypeDef.PlayerSelf
            local tbGameObjects = GameObjectSystem:GetAllByObjectType(nPlayerSelfDef)
            for tbGameObject, _ in pairs(tbGameObjects) do
                if not AIHelper.IsAIControlled(tbGameObject) then
                    SendABot(self, tbGameObject)
                end
            end
            self.tbDelaySenderTimer = nil
        end, nTime, false)
    end
end

function SAIDeliveryBotSystem:RegisterBot(tbGameObject)
    for i,v in ipairs(self.tbBots) do
        if v == tbGameObject then
            return
        end
    end
    table.insert(self.tbBots, tbGameObject)
    self.bEnable = true
    LOG("register deliver bot:", tbGameObject.szName)
end

function SAIDeliveryBotSystem:UnregisterBot(tbGameObject)
    for i,v in ipairs(self.tbBots) do
        if v == tbGameObject then
            table.remove(self.tbBots, i)
            LOG("UnregisterBot ", tbGameObject.szName)
            break
        end
    end
    local nServerInstanceId = tbGameObject.nServerInstanceId
    for k,v in pairs(self.tbDelivingBots) do
        if k == nServerInstanceId then
            self.tbDelivingBots[k] = nil
            BotStopSend(tbGameObject)
            break
        end
    end
end

function SAIDeliveryBotSystem:IsInSending(tbGameObject)
    return IsSending(self, tbGameObject)
end

function SAIDeliveryBotSystem:Init()
    if GlobalVariableSystem:IsServerLogic() then
        local SelfEventHelper = SelfEventHelperClass()
        self.tbBots = {}
        self.tbDelivingBots = {}
        self.bEnable = false
        self.nBotSenderDelayTime = 0
        self.SelfEventHelper = SelfEventHelper
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_PARACHUTION_END,            self, self.OnParachutionEnd)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD,       self, self.OnPawnDead)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_END_CHANGEDISPLAY,              self, self.OnEndChangeDisplay)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT,           self, self.OnPlayerLoginOut)
    end
    return true
end

function SAIDeliveryBotSystem:Uninit()
    if GlobalVariableSystem:IsServerLogic() then
        self.SelfEventHelper:UnregisterAll()
        self:ClearDelaySenderTimer()
        self.tbDelivingBots = nil
        self.tbBots = nil
    end
end

return SAIDeliveryBotSystem()