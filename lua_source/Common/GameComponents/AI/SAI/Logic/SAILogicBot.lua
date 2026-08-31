local luaclass = require("luaclass")
local SAILogicBase = require("SAILogicBase")
local SAILogicBot = luaclass("SAILogicBot", SAILogicBase)
local BotWeaponDataTable = require("BotWeaponDataTable")
local BotTemplateDataTable = require("BotTemplateDataTable")
local BotLevelDataTable = require("BotLevelDataTable")
local SAISystemDef = require("SAISystemDef")
local Timer                 = require("Timer")
local BattleItemSystemServer= require("BattleItemSystemServer")
local BotSupplyDataTable    = require("BotSupplyDataTable")
local BotSupplyItemRandomDataTable = require("BotSupplyItemRandomDataTable")
local BotIni                =  require("BotIni")
local SAIDeliveryBotSystem = require("SAIDeliveryBotSystem")
local CommonEventDef = require("CommonEventDef")

local function LOG(...)
    log("CJ->SAILogicBot:", ...)
end

SAILogicBot.nTemplateId = 0
SAILogicBot.tbAddShipItemsTimer = nil
SAILogicBot.nAttackIntention = 1.0

local function GetAILevel(self)
    local tbBotTemplate = BotTemplateDataTable:GetTemplate(self.nTemplateId)
    assert(tbBotTemplate, "bot template id is not valid" )
    return tbBotTemplate.nBotLevel
end

local function GetBotAILevelConfig(self)
    return BotLevelDataTable:GetTemplate(GetAILevel(self))
end

function SAILogicBot:OnCreatedAI()
    self.nAttackIntention = BotIni.nInitAttackIntention
end

function SAILogicBot:Enable(tbConfig, nTemplateId)
    self.nTemplateId = nTemplateId
    local tbAILevelConfig = GetBotAILevelConfig(self)
    if tbAILevelConfig and tbAILevelConfig.bSender then
        SAIDeliveryBotSystem:RegisterBot(self.Owner)
    end
    SAILogicBot.super.Enable(self, tbConfig, nTemplateId)
end

local function OnAIBattleLogicStart(self, tbGameObejct)
    if tbGameObejct == self.Owner then
        LOG("OnAIBattleLogicStart", tbGameObejct.szName)
        local AIComponent = self.Owner.SAIComponent

        local tbPerceptionSystem = AIComponent:GetSystem(SAISystemDef.Perception)
        tbPerceptionSystem:Stop()
        tbPerceptionSystem:Start()

        local tbTreatSystem = AIComponent:GetSystem(SAISystemDef.Threat)
        tbTreatSystem.bEnabled = true
        tbTreatSystem:Start()
    end
end

function SAILogicBot:OnBindEvent(SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_AI_BATTLELOGIC_START, self, OnAIBattleLogicStart)
end

function SAILogicBot:OnUnbindEvent(SelfEventHelper)
    SelfEventHelper:UnregisterEvent(CommonEventDef.EV_AI_BATTLELOGIC_START)
end

function SAILogicBot:Possessed()
    local tbAILevelConfig = GetBotAILevelConfig(self)
    local nHitProb  = 0
    local szAimPart = ""
    if self.Owner:IsShip() then
        nHitProb  = tbAILevelConfig.nShipHitProbability
        szAimPart = tbAILevelConfig.nAimShipPart
    else
        nHitProb  = tbAILevelConfig.nHumanHitProbability
        szAimPart = tbAILevelConfig.szAimHumanPart
    end
    local tbWeaponSystem = self.Owner.SAIComponent:GetSystem(SAISystemDef.Weapon)
    tbWeaponSystem:SetWeaponHitProb(nHitProb)
    tbWeaponSystem:SetAimPart(szAimPart)
end

function SAILogicBot:CanUseWeapon(nTemplateId)
    return self:GetWeaponConfig(nTemplateId) ~= nil
end

function SAILogicBot:GetWeaponConfig(nTemplateId)
    return BotWeaponDataTable:GetWeaponConfig(GetAILevel(self), self.Owner:IsShip(), nTemplateId)
end

function SAILogicBot:ClearAddShipItemsTimer()
    if self.tbAddShipItemsTimer then
        self.tbAddShipItemsTimer:Clear()
        self.tbAddShipItemsTimer = nil
    end
end

function SAILogicBot:AddShipBattleItems(nPoisonCircleIndex)
    local tbSupplyConfig = BotSupplyDataTable:GetTemplate(GetAILevel(self), nPoisonCircleIndex)
    if tbSupplyConfig then
        self:ClearAddShipItemsTimer()
        local nDelayTime = math.random( tbSupplyConfig.nDelayTimeMin, tbSupplyConfig.nDelayTimeMax )
        local tbAddItems = BotSupplyItemRandomDataTable:GetRandomItems(tbSupplyConfig.nSupplyItemRandomId)
        if tbAddItems and #tbAddItems > 0 then
            nDelayTime = math.max(nDelayTime, 0.1)
            self.tbAddShipItemsTimer = Timer.NewTimer(function()
                self:ClearAddShipItemsTimer()
                BattleItemSystemServer:AddItems(self.Owner.nServerInstanceId, tbAddItems)
                LOG("add ship battle items")
            end, nDelayTime, false)
        else
            logerror("invalid ship items id found ", tbSupplyConfig.nSupplyItemRandomId)
        end
    else
        LOG("can not found ai supply config ", GetAILevel(self), nPoisonCircleIndex)
    end
end

function SAILogicBot:ChangeBotAttackIntention(nPoisonCircleIndex)
    local nAttackIntention = BotIni.tbAttackIntention[nPoisonCircleIndex]
    if nAttackIntention and nAttackIntention > 0 then
        self.nAttackIntention = nAttackIntention
        LOG("change attack intention ", nPoisonCircleIndex, nAttackIntention)
    end
end

function SAILogicBot:GetDamageParam()
    if self.Owner:IsShip() then
        return GetBotAILevelConfig(self).nShipDamageParam
    else
        return GetBotAILevelConfig(self).nHumanDamageParam
    end
end

function SAILogicBot:GetLevel()
    return GetAILevel(self)
end

function SAILogicBot:OnUninit()
    self:ClearAddShipItemsTimer()
    SAILogicBot.super.OnUninit(self)
end


return SAILogicBot