-- trigger中Npc数量

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleNpcCountInTriggerTarget = luaclass("BattleNpcCountInTriggerTarget", BattleTargetBaseClass)

local BattleNpcHelper = require("BattleNpcHelper")
local BattleTriggerHelper = require("BattleTriggerHelper")
local BattleNpcCountInTriggerCondition = require("BattleNpcCountInTriggerCondition")

BattleNpcCountInTriggerTarget.nCount = nil
BattleNpcCountInTriggerTarget.nTriggerId = nil
BattleNpcCountInTriggerTarget.szOperator = nil
BattleNpcCountInTriggerTarget.fnCallback = nil

function BattleNpcCountInTriggerTarget:Init()
    BattleNpcCountInTriggerTarget.super.Init(self)
    self.szName = "BattleNpcCountInTriggerTarget"    
end

function BattleNpcCountInTriggerTarget:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nTriggerId = tbJsonData.TriggerId
    self.szOperator = tbJsonData.Operator
    self.nCount = tbJsonData.Count
    return self.nTriggerId ~= nil
end

local function OnEnterTrigger(self)
    if(BattleNpcCountInTriggerCondition.StaticCheck(self.nTriggerId, 
        self.szOperator, self.nCount, self)) then
        self:Complete()
    end
end

function BattleNpcCountInTriggerTarget:RegisterEvent()
    self.fnCallback = function(nTriggerId, GameObject, bEnter)
        if(bEnter) then
            OnEnterTrigger(self)
        end
    end
    BattleTriggerHelper:AddCallback(self.nTriggerId, self.fnCallback)
end

function BattleNpcCountInTriggerTarget:UnregisterEvent()
    if(self.fnCallback) then
        BattleTriggerHelper:RemoveCallback(self.nTriggerId, self.fnCallback)
        self.fnCallback = nil
    end
end

function BattleNpcCountInTriggerTarget:Start()
    BattleNpcCountInTriggerTarget.super.Start(self)

    OnEnterTrigger(self)
end


return BattleNpcCountInTriggerTarget
