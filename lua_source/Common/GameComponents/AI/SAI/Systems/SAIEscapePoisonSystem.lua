
local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAIEscapePoisonSystem = luaclass("SAIEscapePoisonSystem", SAISystemBase)
local SelfEventHelperClass = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local SAIPoisonCircleSystem = require("SAIPoisonCircleSystem")
local SAISystemDef = require("SAISystemDef")
local SAIPoisonEscapeStrategy = require("SAIPoisonEscapeStrategy")
local AIVariableSystem = require("AIVariableSystem")

SAIEscapePoisonSystem.pAIController = nil
SAIEscapePoisonSystem.SelfEventHelper = nil
SAIEscapePoisonSystem.tbGoalSystem = nil
SAIEscapePoisonSystem.tbEscapingLocation = nil
SAIEscapePoisonSystem.pBlackboard = nil

local nDistanceToPosionCicleOffset = 0.85

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIEscapePoisonSystem:", ...)
end
-- luacheck: pop


local function GetDistanceBetween(nSourceX, nSourceY, nTargetX, nTargetY)
    return math.sqrt((nTargetX - nSourceX) ^ 2 + (nTargetY - nSourceY) ^ 2)
end

local function CheckEscapeLocation(self)
    if not AIVariableSystem:IsBattleStarted() then
        return
    end
    local nX, nY, nRadius = SAIPoisonCircleSystem:GetPoisonStatus()
    local tbPosotion = self.tbOwner:GetLocation()
    if GetDistanceBetween(tbPosotion.X, tbPosotion.Y, nX, nY) >= (nRadius * nDistanceToPosionCicleOffset) then
        local bFoundEscapeLocation = (self.tbEscapingLocation ~= nil)
        if bFoundEscapeLocation then
            bFoundEscapeLocation = GetDistanceBetween(self.tbEscapingLocation.X, self.tbEscapingLocation.Y, nX, nY) < nRadius
        end
        if not bFoundEscapeLocation then
            local nNextX, nNextY, nNextRadius = SAIPoisonCircleSystem:GetNextStatus()
            local tbPosition = SAIPoisonEscapeStrategy.Select(self.tbOwner, nNextX, nNextY, nNextRadius)
            self.tbEscapingLocation = tbPosition
            LOG("select escape poison location:", tbPosition.X, tbPosition.Y, tbPosition.Z)
        end
    end
    if self.tbEscapingLocation then
        self.tbGoalSystem:SetGoalLocation(self.tbEscapingLocation.X, self.tbEscapingLocation.Y, self.tbEscapingLocation.Z)
    end
end


local function OnPoisonCircleShrinking(self, nTime)
    CheckEscapeLocation(self)
    SAIPoisonCircleSystem:SetBBPoisonCircleData(self.pBlackboard)
end

function SAIEscapePoisonSystem:OnConfig(tbConfig)
    if not tbConfig.bEscapingPoison then
        self.bEnabled = false
    end
    LOG("escape:", self.bEnabled)
end

function SAIEscapePoisonSystem:IsEscaping()
    return self.tbEscapingLocation ~= nil
end

function SAIEscapePoisonSystem:OnStart()

    local tbOwner = self.tbOwner
    local AIComponent  = tbOwner.SAIComponent
    self.pAIController = AIComponent:GetAIController()
    self.pBlackboard   = self.pAIController.Blackboard
    self.tbGoalSystem  = AIComponent:GetSystem(SAISystemDef.Goal)
    local SelfEventHelper = SelfEventHelperClass()
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_AI_POISON_CIRCLE_SHRINKING,  self, OnPoisonCircleShrinking)
    self.SelfEventHelper = SelfEventHelper

    SAIPoisonCircleSystem:SetBBPoisonCircleData(self.pBlackboard)
    CheckEscapeLocation(self)
end


function SAIEscapePoisonSystem:OnStop()
    self.SelfEventHelper:UnregisterAll()
    self.pAIController = nil
    self.pBlackboard = nil
    self.tbGoalSystem = nil
    self.SelfEventHelper = nil
end

function SAIEscapePoisonSystem:OnUninit()
    self.tbEscapingLocation = nil
end



return SAIEscapePoisonSystem
