local luaclass = require("luaclass")
local BattleStepBaseClass = require("BattleStepBase")
local BattleTargetActionStep = luaclass("BattleTargetActionStep", BattleStepBaseClass)

local BattleOperationHelper = require("BattleOperationHelper")
local Proto = require("DungeonRepProtoNames")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

BattleTargetActionStep.StartAction = nil
BattleTargetActionStep.Target = nil
BattleTargetActionStep.TargetCompletedAction = nil
BattleTargetActionStep.tbActions = nil

function BattleTargetActionStep:DefineRProperty(szProtoName)
    local tbGameState = BattleGameModeSystem:GetGameState()

    local r = tbGameState[szProtoName]
    if(r == nil) then
        self[szProtoName] = tbGameState:DefineProtoProperty(Proto[szProtoName])
    else
        self[szProtoName] = r
    end
    assert(self[szProtoName])
end

function BattleTargetActionStep:Init()
    BattleTargetActionStep.super.Init(self)
    self.tbActions = {}
    self.szName = "BattleTargetActionStep"
end

function BattleTargetActionStep:Uninit()
    for i, v in ipairs(self.tbActions) do
        v:Uninit()
    end
    self.tbActions = nil
    BattleTargetActionStep.super.Uninit(self)
end

function BattleTargetActionStep:AddAction(tbAction)
    if(tbAction) then
        table.insert(self.tbActions, tbAction)
    end
end

function BattleTargetActionStep:DoAction(szAction)
    local Action = self[szAction]
    if(Action) then
        local bRet = Action:Execute()
        if(not bRet) then
            BattleOperationHelper:PrintError(self, "Do ["..szAction..
                "], failed, action name: "..Action.szOperationName)
            return
        end
    end
end

function BattleTargetActionStep:Parse(tbJsonData)
    if(tbJsonData.StartAction) then
        self.StartAction = BattleOperationHelper:Create(self, tbJsonData.StartAction)
        self:AddAction(self.StartAction)
    end
    if(tbJsonData.Target) then
        local Target = BattleOperationHelper:Create(self, tbJsonData.Target)
        if(Target) then
            self:AddTarget(Target)
        end
        self.Target = Target
    end
    if(tbJsonData.TargetCompletedAction) then
        self.TargetCompletedAction = BattleOperationHelper:Create(self, tbJsonData.TargetCompletedAction)
        self:AddAction(self.TargetCompletedAction)
    end
    return true
end

function BattleTargetActionStep:OnStarted()
    self:DoAction("StartAction")
    BattleTargetActionStep.super.OnStarted(self)
end

function BattleTargetActionStep:OnCompleted()
    if(self.Target and self.Target:IsCompleted()) then
        -- 如果有Target则执行CompleteAction
        self:DoAction("TargetCompletedAction")
    end
    BattleTargetActionStep.super.OnCompleted(self)
end

return BattleTargetActionStep