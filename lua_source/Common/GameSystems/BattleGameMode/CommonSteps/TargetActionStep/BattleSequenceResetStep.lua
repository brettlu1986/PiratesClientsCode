local luaclass = require("luaclass")
local BattleTargetActionStep = require("BattleTargetActionStep")
local BattleSequenceResetStep = luaclass("BattleSequenceResetStep", BattleTargetActionStep)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")
local D2CHelper = require("D2CHelper")
local EventManager = require("EventManager")

BattleSequenceResetStep.tbSteps = nil
BattleSequenceResetStep.FinishedAction = nil
BattleSequenceResetStep.SequenceFinishedAction = nil
BattleSequenceResetStep.nCurrentIndex = 1
BattleSequenceResetStep.tbStepData = nil
BattleSequenceResetStep.nResetGroupIndex1 = nil
BattleSequenceResetStep.nResetGroupIndex2 = nil
BattleSequenceResetStep.nResetGroupIndex3 = nil
BattleSequenceResetStep.nResetGroupIndex4 = nil
BattleSequenceResetStep.nResetGroupIndex5 = nil
BattleSequenceResetStep.tbGroupIndex = nil

function BattleSequenceResetStep:Init()
    BattleSequenceResetStep.super.Init(self)
    self.szName = "BattleSequenceResetStep"
end

function BattleSequenceResetStep:Uninit()
    if(self.tbSteps) then
        for i, v in ipairs(self.tbSteps) do
            v:Uninit()
        end
    end
    BattleSequenceResetStep.super.Uninit(self)
end

function BattleSequenceResetStep:OnStepReset()
    if(self:IsCompleted()) then
        return
    end
    local tbSteps = self.tbSteps
    local tbResetStep = tbSteps[self.nCurrentIndex]
    if tbResetStep == nil then 
        return 
    end

    tbResetStep:ForceStop()
    self:KillAll()
    -- tbResetStep:Uninit将fnCompleteCallback设置为nil,避免回调完成当前阶段
    tbResetStep:Uninit()
    tbResetStep = nil
    BattleOperationHelper:PrintLog(self, "SubResetStep"..self.nCurrentIndex.." will reset.")

    tbSteps[self.nCurrentIndex] = self:ParseResetStep(self.tbStepData)
    tbSteps[self.nCurrentIndex]:Start()
    self:RebornAllPlayers()
end

-- 需要重置每个阶段坐标
function BattleSequenceResetStep:RebornAllPlayers()
    local nPlayerCount = 1
    local tbAll = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    local tbStepStarts = self:GetPlayerStartByGroupIndex(self.tbGroupIndex[self.nCurrentIndex])
    
    for GameObject, _ in pairs(tbAll) do
        local tbStepStart = tbStepStarts[nPlayerCount]
        if tbStepStart == nil then 
            logerror("BattleSequenceResetStep failed, can not find reborn point")
        end 
        local tbTransform = tbStepStart.Transform
        if(tbTransform) then
            GameObject:Reborn(tbTransform.X, tbTransform.Y, tbTransform.Z, tbTransform.Yaw)
            D2CHelper:PlayerSetCameraYaw(GameObject, tbTransform.Yaw)
        end
        nPlayerCount = nPlayerCount + 1
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, GameObject)
    end  
end 

function BattleSequenceResetStep:GetPlayerStartByGroupIndex(nPlayerStartGroupIndex)
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbPlayerStarts = tbGameMode.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    local tbStepPoints = {}
    if tbPlayerStarts then
        for i, v in ipairs(tbPlayerStarts) do
            if v.GroupIndex == nPlayerStartGroupIndex then
                table.insert(tbStepPoints, v)
            end
        end
    end
    return tbStepPoints
end 

function BattleSequenceResetStep:KillAll()
    local tbPlayers = {}
    local tbDestroys = {}
    local tbAll = GameObjectSystem:GetAllGameObjects()
    local PlayerSelfType = GameObjectTypeDef.PlayerSelf
    for nId, GameObject in pairs(tbAll) do
        if PlayerSelfType == GameObject.ObjectType then
            table.insert(tbPlayers, GameObject)
        else
            table.insert(tbDestroys, GameObject)
        end
    end

    local Type, nInstanceId
    for _, GameObject in ipairs(tbDestroys) do
        Type = GameObject.ObjectType
        nInstanceId = GameObject.nServerInstanceId
        if(Type == GameObjectTypeDef.Npc) then
            GameObjectSystem:DestroyNpcInGameModeByInstanceId(nInstanceId)
        elseif(Type == GameObjectTypeDef.Trigger) then
            GameObjectSystem:DestroyTriggerInGameModeByInstanceId(nInstanceId)
        elseif(Type == GameObjectTypeDef.Dummy) then
            GameObjectSystem:DestroyDummyInGameModeByInstanceId(nInstanceId)
        end
    end

    for _, GameObject in ipairs(tbPlayers) do
        GameObject:KillSelf()
    end
end

function BattleSequenceResetStep:ForceStop()
    BattleSequenceResetStep.super.ForceStop(self)

    if(self.tbSteps) then
        for i, v in ipairs(self.tbSteps) do
            v:ForceStop()
        end
    end 
end

local function OnSubStepEnd(self, Step)
    if(not self.bStarted) then
        return
    end
    if(self:IsCompleted()) then
        return
    end
    
    local tbSteps = self.tbSteps
    local nCurrentIndex = self.nCurrentIndex
    assert(Step == tbSteps[nCurrentIndex])
    BattleOperationHelper:PrintLog(self, "SubResetStep"..nCurrentIndex.." finished.")

    nCurrentIndex = nCurrentIndex + 1
    self.nCurrentIndex = nCurrentIndex
    if(nCurrentIndex <= #tbSteps) then
        tbSteps[nCurrentIndex]:Start()
    else
        self:Complete()    
    end 
end

function BattleSequenceResetStep:ParseResetStep(tbStepData)
    local SingleStep 
    local StepData = tbStepData[self.nCurrentIndex]
    if StepData == nil then 
        return nil
    end 

    SingleStep = BattleOperationHelper:Create(self, StepData)
    if(SingleStep == nil) then
        BattleOperationHelper:PrintError(self, "ResetStep"..self.nCurrentIndex.." parse failed.")
        return false
    end
    SingleStep.szName = "SubResetStep"..self.nCurrentIndex.."_InSequence"
    SingleStep:SetCompleteCallback(function(Step) OnSubStepEnd(self, Step) end)
    return SingleStep
end

function BattleSequenceResetStep:Parse(tbJsonData)
    if(not BattleSequenceResetStep.super.Parse(self, tbJsonData)) then
        return false
    end
    self.tbGroupIndex = {}
    self.nResetGroupIndex1 = tbJsonData.ResetGroupIndex1
    table.insert(self.tbGroupIndex, tbJsonData.ResetGroupIndex1)
    table.insert(self.tbGroupIndex, tbJsonData.ResetGroupIndex2)
    table.insert(self.tbGroupIndex, tbJsonData.ResetGroupIndex3)
    table.insert(self.tbGroupIndex, tbJsonData.ResetGroupIndex4)
    table.insert(self.tbGroupIndex, tbJsonData.ResetGroupIndex5)

    local tbSteps = {}
    self.tbSteps = tbSteps
    local tbStepData = tbJsonData.Steps
    self.tbStepData = tbStepData
    local SingleStep
    for i, StepData in ipairs(tbStepData) do
        SingleStep = BattleOperationHelper:Create(self, StepData)
        if(SingleStep == nil) then
            BattleOperationHelper:PrintError(self, "ResetStep"..i.." parse failed.")
            return false
        end
        SingleStep.szName = "SubResetStep"..i.."_InSequence"
        SingleStep:SetCompleteCallback(function(Step) OnSubStepEnd(self, Step) end)
        table.insert(tbSteps, SingleStep)
    end

    local FinishedActionData = tbJsonData.SequenceFinishedAction
    if(FinishedActionData and #self.tbSteps > 0) then
        self.SequenceFinishedAction = BattleOperationHelper:Create(self, FinishedActionData)
        self:AddAction(self.SequenceFinishedAction)
    end

    return true
end

function BattleSequenceResetStep:Start()
    BattleSequenceResetStep.super.Start(self)
    
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_STEP_RESET, self, self.OnStepReset)

    self.nCurrentIndex = 1
    if(not self:IsCompleted() and #self.tbSteps > 0) then
        self.tbSteps[1]:Start()
    end
end

function BattleSequenceResetStep:OnCompleted()
    BattleSequenceResetStep.super.OnCompleted(self)
    if(self.nCurrentIndex > #self.tbSteps) then
        self:DoAction("SequenceFinishedAction")
    end

    -- 把子节点都强停掉
    self:ForceStop()    
end

return BattleSequenceResetStep