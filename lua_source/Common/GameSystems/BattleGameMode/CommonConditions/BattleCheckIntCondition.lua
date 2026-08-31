local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleCheckIntCondition = luaclass("BattleCheckIntCondition", BattleConditionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")

BattleCheckIntCondition.szOperator = nil
BattleCheckIntCondition.szKey1 = nil
BattleCheckIntCondition.szKey2 = nil
BattleCheckIntCondition.Value2 = nil

function BattleCheckIntCondition:Parse(tbJsonData)
    self.szOperator = tbJsonData.Operator
    self.szKey1 = tbJsonData.Key1
    self.szKey2 = tbJsonData.Key2
    self.Value2 = tbJsonData.Value2
    return string.len(self.szKey1) > 0
end

function BattleCheckIntCondition.StaticCheck(szOperator, szKey1, szKey2, Value2)
    local Value1 = BattleBlackboard:GetNumber(szKey1)
    if(szKey2 ~= nil and string.len(szKey2) > 0) then
        Value2 = BattleBlackboard:GetNumber(szKey2)
    end
    if(Value1 == nil or Value2 == nil) then
        return nil
    end    
    return BattleOperationHelper:CallOperator(szOperator, Value1, Value2)
end

function BattleCheckIntCondition:Execute()
    local Ret = self.StaticCheck(self.szOperator, 
        self.szKey1, self.szKey2, self.Value2)
    if(Ret == nil) then
        BattleOperationHelper:PrintError(self, "Do failed, Operator: "..self.szOperator..
            ", Key1: "..self.szKey1)
        return false
    end
    return Ret
end

return BattleCheckIntCondition