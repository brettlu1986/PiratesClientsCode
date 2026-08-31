local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAIParachuteSystem = luaclass("SAIParachuteSystem", SAISystemBase)
local SelfEventHelperClass      = require("SelfEventHelper")
local CommonEventDef            = require("CommonEventDef")
local Timer                     = require("Timer")
local ProtoDR                   = require("DungeonRepProtoNames")
local GameObjectSystem          = dynamic_require("GameObjectSystem")
local GameObjectTypeDef         = require("GameObjectTypeDef")
local AIHelper                  = require("AIHelper")
local AIVariableSystem          = require("AIVariableSystem")
local EventManager              = require("EventManager")
local SAIBlackboradKey          = require("SAIBlackboradKey")


local GamePhaseDef = {
    WAITING      = 1,    -- 集合岛
    PARACHUTING  = 2,    -- 跳伞
    SURVIVAL     = 3,    -- 吃鸡
}


SAIParachuteSystem.SelfEventHelper = nil
SAIParachuteSystem.pAIController = nil
SAIParachuteSystem.pBlackboard = nil
SAIParachuteSystem.nStartBattleDelayTime = 0
SAIParachuteSystem.tbTimer = nil


local function LOG(...)
    log("CJ->SAIParachuteSystem:", ...)
end

local function DelayStartBattle(self)
    self:StartBattle()
    --LOG("begin ai")
end

local function ShouldReplicate(nReplicatesLimitCount)
    if not nReplicatesLimitCount then
        return true
    end
    local nCount = 0
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if not Object:IsDead() and
        AIHelper.IsAIControlled(Object) then
            nCount = nCount + 1
        end
    end
    return nCount <= nReplicatesLimitCount
end


function SAIParachuteSystem:OnConfig(tbConfig)
    self.bEnabled = (tbConfig.Parachute ~= nil)
    if self.bEnabled then
        self.nStartBattleDelayTime = tbConfig.Parachute.nStartBattleDelayTime or 0
    end
    LOG("enabled:", self.bEnabled, self.nStartBattleDelayTime)
end

function SAIParachuteSystem:OnStart()

    local tbOwner = self.tbOwner
    self.pAIController = tbOwner.SAIComponent:GetAIController()
    self.pBlackboard = self.pAIController.Blackboard
    self.SelfEventHelper = SelfEventHelperClass()
    local SelfEventHelper = self.SelfEventHelper
    local nStage = self.pBlackboard:GetValueAsInt(SAIBlackboradKey.szStage)
    if not AIVariableSystem:IsBattleStarted() then
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_PARACHUTION_END         , self, self.OnParachuteEnd)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_FFA_PROCESS_STATE_CHANGED   , self, self.OnProcessStateChanged)
        if not ShouldReplicate(AIVariableSystem.nReplicatesLimitCount) then
            tbOwner.pUEActor:SetActorIsReplicates(false)
            LOG("SetActorIsReplicates false ", tbOwner.szName)
        else
            self.pBlackboard:SetValueAsInt(SAIBlackboradKey.szStage, GamePhaseDef.WAITING)
        end
    elseif nStage < GamePhaseDef.SURVIVAL then
        if  self:ShouldDelayBattle() then
            self:ClearTimer()
            self.tbTimer = Timer.NewTimerMethod(self, DelayStartBattle, self.nStartBattleDelayTime, false)
            LOG("delay start battle", self.nStartBattleDelayTime)
        else
            self:StartBattle()
        end
    end
end


function SAIParachuteSystem:OnStop()
    self:ClearTimer()
    if self.SelfEventHelper then
        self.SelfEventHelper:UnregisterAll()
        self.SelfEventHelper = nil
    end
    self.pAIController = nil
    self.pBlackboard = nil
end

function SAIParachuteSystem:OnUninit()

end

function SAIParachuteSystem:ShouldDelayBattle()
    return self.nStartBattleDelayTime > 0 and AIHelper:ShouldSkipParachute(self.tbOwner)
end

function SAIParachuteSystem:OnParachuteEnd(tbGameObject, ...)
    if self.tbOwner == tbGameObject then
        if self:ShouldDelayBattle() then
            self:ClearTimer()
            self.tbTimer = Timer.NewTimerMethod(self, DelayStartBattle, self.nStartBattleDelayTime, false)
            LOG("delay start battle", self.nStartBattleDelayTime)
        else
            self:StartBattle()
        end
    end
end


function SAIParachuteSystem:ClearTimer()
    if self.tbTimer then
        self.tbTimer:Clear()
        self.tbTimer = nil
    end
end

function SAIParachuteSystem:StartBattle()
    self:ClearTimer()
    local pBlackboard = self.pBlackboard
    pBlackboard:SetValueAsInt(SAIBlackboradKey.szStage, GamePhaseDef.SURVIVAL)
    EventManager:OnFireEvent(CommonEventDef.EV_AI_BATTLELOGIC_START, self.tbOwner)
end

function SAIParachuteSystem:OnProcessStateChanged(nState)
    if nState == ProtoDR.rFFAProcessState_EState.SELECTION then
        local pBlackboard = self.pBlackboard
        pBlackboard:SetValueAsInt(SAIBlackboradKey.szStage, GamePhaseDef.PARACHUTING)
    end
end

return SAIParachuteSystem