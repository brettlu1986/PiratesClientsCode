local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleNpcCountInTriggerCondition = luaclass("BattleNpcCountInTriggerCondition", BattleConditionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleNpcHelper = require("BattleNpcHelper")
local BattleTriggerHelper = require("BattleTriggerHelper")

BattleNpcCountInTriggerCondition.nCount = nil
BattleNpcCountInTriggerCondition.szOperator = nil

function BattleNpcCountInTriggerCondition:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nTriggerId = tbJsonData.TriggerId
    self.szOperator = tbJsonData.Operator
    self.nCount = tbJsonData.Count
    return true
end

BattleNpcCountInTriggerCondition.StaticCheck = function(nTriggerId, szOperator, nCount, NpcIdentifier)
    local tbObjects = BattleTriggerHelper:GetObjects(nTriggerId)
    if(tbObjects == nil) then
        return false
    end
    
    local nCurrentCount = 0
    for i, Object in ipairs(tbObjects) do
        if(not Object:IsDead() and BattleNpcHelper:CheckIdentifier(NpcIdentifier, Object)) then
            nCurrentCount = nCurrentCount + 1
        end
    end
    return BattleOperationHelper:CallOperator(szOperator, nCurrentCount, nCount)  
end

function BattleNpcCountInTriggerCondition:Execute()
    return self.StaticCheck(self.nTriggerId, self.szOperator, self.nCount, self)
end

return BattleNpcCountInTriggerCondition