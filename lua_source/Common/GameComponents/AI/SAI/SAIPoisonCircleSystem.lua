local luaclass = require("luaclass")
local SAIPoisonCircleSystem = luaclass("SAIPoisonCircleSystem")
local SelfEventHelperClass  = require("SelfEventHelper")
local CommonEventDef        = require("CommonEventDef")
local BotAISystem           = dynamic_require("BotAISystem")
local AIHelper              = require("AIHelper")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local SAILogicDef = require("SAILogicDef")
local Timer = require("Timer")
local SAIBlackboradKey = require("SAIBlackboradKey")

local POISONCIRCLE_WAIT = 1
local POISONCIRCLE_SHRINK = 2

SAIPoisonCircleSystem.SelfEventHelper = nil
SAIPoisonCircleSystem.nStageId = 0
SAIPoisonCircleSystem.nNextX = 0
SAIPoisonCircleSystem.nNextY = 0
SAIPoisonCircleSystem.nNextRadius = 0
SAIPoisonCircleSystem.nX = 0
SAIPoisonCircleSystem.nY = 0
SAIPoisonCircleSystem.nRadius = 0
SAIPoisonCircleSystem.nTime = 0
SAIPoisonCircleSystem.nCurrentRadius = 0
SAIPoisonCircleSystem.nCurrentX = 0
SAIPoisonCircleSystem.nCurrentY = 0
SAIPoisonCircleSystem.nTotolTime = 0
SAIPoisonCircleSystem.nPoisonTimer = nil

local function LOG(...)
    log("CJ->SAIPoisonCircleSystem:", ...)
end

local function ClearPoisonTimer(self)
    if self.nPoisonTimer then
        self.nPoisonTimer:Clear()
        self.nPoisonTimer = nil
    end
end

local function OnTick(self)
    if self.nTime > 0 then
        self.nTime = self.nTime - 1
    end
    if self.nTime <= 0 then
        ClearPoisonTimer(self)
    end
    if self.nStageId == POISONCIRCLE_SHRINK then
        local nPercent = self.nTime / self.nTotolTime
        self.nCurrentRadius = nPercent * (self.nRadius - self.nNextRadius) + self.nNextRadius
        self.nCurrentX = nPercent * (self.nX - self.nNextX) + self.nNextX
        self.nCurrentY = nPercent * (self.nY - self.nNextY) + self.nNextY
        self.SelfEventHelper:FireEvent(CommonEventDef.EV_AI_POISON_CIRCLE_SHRINKING, self.nTime)
        --LOG("shrink ", self.nCurrentX, self.nCurrentY, self.nCurrentRadius)
    end
end


local function OnPoisonCircleInfo(self, rFFAPoisonCircleInfo)
    self.nX = rFFAPoisonCircleInfo.nCurrentX
    self.nY = rFFAPoisonCircleInfo.nCurrentY
    self.nRadius = rFFAPoisonCircleInfo.nCurrentRadius
    self.nStageId = rFFAPoisonCircleInfo.nStageId
    self.nCurrentRadius = self.nRadius
    self.nCurrentX = self.nX
    self.nCurrentY = self.nY
    local X = rFFAPoisonCircleInfo.nNextX
    local Y = rFFAPoisonCircleInfo.nNextY
    local Radius = rFFAPoisonCircleInfo.nNextRadius
    if X and Y and Radius then
        self.nNextX = X
        self.nNextY = Y
        self.nNextRadius = Radius
        if rFFAPoisonCircleInfo.nStageId == POISONCIRCLE_WAIT then
            ClearPoisonTimer(self)
            local WaitTime = math.floor(rFFAPoisonCircleInfo.nWaitEndTimeStamp - GlobalVariableSystem:GetLocalTime())
            self.nTime = WaitTime
            self.nTotolTime = WaitTime
            self.nPoisonTimer = Timer.NewTimerMethod(self, OnTick, 1, true)
            LOG("poison circle start wait ", WaitTime, self.nNextX, self.nNextY, self.nNextRadius, self.X, self.Y, self.nRadius)
        elseif rFFAPoisonCircleInfo.nStageId == POISONCIRCLE_SHRINK then
            ClearPoisonTimer(self)
            local ShrinkTime = math.floor(rFFAPoisonCircleInfo.nShrinkEndTimeStamp - GlobalVariableSystem:GetLocalTime())
            self.nTime = ShrinkTime
            self.nTotolTime = ShrinkTime
            self.nPoisonTimer = Timer.NewTimerMethod(self, OnTick, 1, true)
            LOG("poison circle start shrink ", ShrinkTime, self.nNextX, self.nNextY, self.nNextRadius, self.X, self.Y, self.nRadius)
        end
    end
end

local function OnPoisonCircleShrinkStart(self, nPoisonCircleIndex)
    for i, tbBot in ipairs(BotAISystem:GetAllBots()) do
        if AIHelper:IsRunningAILogic(tbBot, SAILogicDef.Bot) then
            local AILogic = AIHelper:GetAILogic(tbBot)
            if AILogic and AILogic.AddShipBattleItems and GlobalVariableSystem.bEnableBotSupply then
                AILogic:AddShipBattleItems(nPoisonCircleIndex)
            end
            if AILogic and AILogic.ChangeBotAttackIntention then
                AILogic:ChangeBotAttackIntention(nPoisonCircleIndex)
            end
        end
    end
end

function SAIPoisonCircleSystem:SetBBPoisonCircleData(pBlackborad)
    pBlackborad:SetValueAsFloat(SAIBlackboradKey.szPoisonX, self.nCurrentX)
    pBlackborad:SetValueAsFloat(SAIBlackboradKey.szPoisonY, self.nCurrentY)
    pBlackborad:SetValueAsFloat(SAIBlackboradKey.szPoisonRadius, self.nCurrentRadius)
end


function SAIPoisonCircleSystem:GetPoisonStatus()
    return self.nCurrentX, self.nCurrentY, self.nCurrentRadius
end

function SAIPoisonCircleSystem:GetNextStatus()
    return self.nNextX, self.nNextY, self.nNextRadius
end

function SAIPoisonCircleSystem:Init()
    if GlobalVariableSystem:IsServerLogic() then
        local SelfEventHelper = SelfEventHelperClass()
        self.SelfEventHelper = SelfEventHelper
        self.nRadius = 10000000
        self.nX = 0
        self.nY = 0
        self.nCurrentRadius = self.nRadius
        self.nCurrentX = self.nX
        self.nCurrentY = self.nY
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_POISONCIRCLE_INFO_CHANGED,  self, OnPoisonCircleInfo)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_POISONCIRCLE_SHRINK_START,  self, OnPoisonCircleShrinkStart)
    end
    return true
end


function SAIPoisonCircleSystem:Uninit()
    if GlobalVariableSystem:IsServerLogic() then
        ClearPoisonTimer(self)
        if self.SelfEventHelper then
            self.SelfEventHelper:UnregisterAll()
        end
    end
end


return SAIPoisonCircleSystem()