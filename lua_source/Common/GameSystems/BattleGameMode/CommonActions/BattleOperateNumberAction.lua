local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleOperateNumberAction = luaclass("BattleOperateNumberAction", BattleActionBase)

local BattleBlackboard = require("BattleBlackboard")
local BattleOperationHelper = require("BattleOperationHelper")

BattleOperateNumberAction.szOperator = nil
BattleOperateNumberAction.szKey1 = nil
BattleOperateNumberAction.nValue1 = nil
BattleOperateNumberAction.szKey2 = nil
BattleOperateNumberAction.nValue2 = nil
BattleOperateNumberAction.szResult = nil

function BattleOperateNumberAction:Parse(tbJsonData)
    self.szOperator = tbJsonData.Operator
    self.szKey1 = tbJsonData.Key1
    self.nValue1 = tbJsonData.Value1
    self.szKey2 = tbJsonData.Key2
    self.nValue2 = tbJsonData.Value2
    self.szResult = tbJsonData.ResultKey
    return string.len(self.szResult) > 0
end

function BattleOperateNumberAction:Execute()
    local nValue1 = self.nValue1
    if(string.len(self.szKey1) > 0) then
        nValue1 = BattleBlackboard:GetNumber(self.szKey1)
    end
    local nValue2 = self.nValue2
    if(string.len(self.szKey2) > 0) then
        nValue2 = BattleBlackboard:GetNumber(self.szKey2)
    end
    local nRet = BattleOperationHelper:CallOperator(self.szOperator, nValue1, nValue2)
    if(nRet == nil) then
        BattleOperationHelper:PrintError(self, "Call operator failed, operator: ", self.szOperator)
        return false
    end
    BattleBlackboard:SetNumber(self.szResult, nRet)

    BattleOperationHelper:PrintLog(self, string.format("Operator: %s, Key1: %s, Value1: %d, Key2: %s, Value2: %d, ResultKey: %s, ResultValue: %d",
        self.szOperator, self.szKey1, nValue1, self.szKey2, nValue2, self.szResult, nRet))
    
    return true
end

return BattleOperateNumberAction