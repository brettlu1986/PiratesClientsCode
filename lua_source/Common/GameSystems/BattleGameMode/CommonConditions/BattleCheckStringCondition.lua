local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleCheckStringCondition = luaclass("BattleCheckStringCondition", BattleConditionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")

BattleCheckStringCondition.szOperator = nil
BattleCheckStringCondition.szKey1 = nil
BattleCheckStringCondition.szKey2 = nil
BattleCheckStringCondition.Value2 = nil

function BattleCheckStringCondition:Parse(tbJsonData)
    self.szOperator = tbJsonData.Operator
    self.szKey1 = tbJsonData.Key1
    self.szKey2 = tbJsonData.Key2
    self.Value2 = tbJsonData.Value2
    return true
end

function BattleCheckStringCondition.StaticCheck(szOperator, szKey1, szKey2, Value2)
    local Value1 = BattleBlackboard:GetString(szKey1)
    if(szKey2 ~= nil and string.len(szKey2) > 0) then
        Value2 = BattleBlackboard:GetString(szKey2)
    end
    if(Value1 == nil or Value2 == nil) then
        return nil
    end    
    return BattleOperationHelper:CallOperator(szOperator, Value1, Value2)
end

function BattleCheckStringCondition:Execute()
    local Ret = self.StaticCheck(self.szOperator, 
        self.szKey1, self.szKey2, self.Value2)
    if(Ret == nil) then
        BattleOperationHelper:PrintError(self, "Do failed, Operator: "..self.szOperator..
            ", Key1: "..self.szKey1)
        return false
    end
    return Ret
end

return BattleCheckStringCondition