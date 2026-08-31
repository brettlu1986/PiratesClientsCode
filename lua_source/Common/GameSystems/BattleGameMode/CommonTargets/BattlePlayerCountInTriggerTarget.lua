-- 指定trigger中存在指定玩家数量

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattlePlayerCountInTriggerTarget = luaclass("BattlePlayerCountInTriggerTarget", BattleTargetBaseClass)

local BattleTriggerHelper = require("BattleTriggerHelper")
local BattlePlayerCountInTriggerCondition = require("BattlePlayerCountInTriggerCondition")


BattlePlayerCountInTriggerTarget.nCount = nil
BattlePlayerCountInTriggerTarget.nTriggerId = nil
BattlePlayerCountInTriggerTarget.szOperator = nil
BattlePlayerCountInTriggerTarget.nCampType = nil
BattlePlayerCountInTriggerTarget.fnCallback = nil

function BattlePlayerCountInTriggerTarget:Init()
    BattlePlayerCountInTriggerTarget.super.Init(self)
    self.szName = "BattlePlayerCountInTriggerTarget"    
end

function BattlePlayerCountInTriggerTarget:Parse(tbJsonData)    
    self.nTriggerId = tbJsonData.TriggerId
    self.szOperator = tbJsonData.Operator
    self.nCount = tbJsonData.Count
    self.nCampType = tbJsonData.CampType
    return self.nTriggerId ~= nil
end

local function OnEnterTrigger(self)    
    if(BattlePlayerCountInTriggerCondition.StaticCheck(self.nTriggerId, 
        self.szOperator, self.nCount, self.nCampType)) then        
        self:Complete()
    end
end

function BattlePlayerCountInTriggerTarget:RegisterEvent()
    self.fnCallback = function(nTriggerId, GameObject, bEnter)
        if(bEnter) then
            OnEnterTrigger(self)
        end
    end
    BattleTriggerHelper:AddCallback(self.nTriggerId, self.fnCallback)
end

function BattlePlayerCountInTriggerTarget:UnregisterEvent()
    if(self.fnCallback) then
        BattleTriggerHelper:RemoveCallback(self.nTriggerId, self.fnCallback)
        self.fnCallback = nil
    end
end

function BattlePlayerCountInTriggerTarget:Start()
    BattlePlayerCountInTriggerTarget.super.Start(self)

    OnEnterTrigger(self)
end


return BattlePlayerCountInTriggerTarget
