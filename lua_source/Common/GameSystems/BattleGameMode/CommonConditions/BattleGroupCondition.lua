local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleGroupCondition = luaclass("BattleGroupCondition", BattleConditionBase)

local BattleOperationHelper = require("BattleOperationHelper")

BattleGroupCondition.szOperator = nil
BattleGroupCondition.tbConditions = nil

function BattleGroupCondition:Parse(tbJsonData)
    self.szOperator = tbJsonData.Operator
    self.tbConditions = {}

    local tbGroup = tbJsonData.Group
    for i, Data in ipairs(tbGroup) do
        local Condition = BattleOperationHelper:Create(self, Data)
        if(Condition == nil) then
            BattleOperationHelper:PrintError(self, "Create Conditon failed, index: "..i)
            return false
        end
        table.insert(self.tbConditions, Condition)
    end

    return true
end

function BattleGroupCondition:Execute()
    local szOperator = self.szOperator
    local tbConditions = self.tbConditions
    local nCount = #tbConditions
    if(nCount == 0) then
        return false
    end

    local szLog
    local bRet = tbConditions[1]:Execute()
    szLog = bRet and "true" or "false"
    for i=2, nCount do
        bRet = BattleOperationHelper:CallOperator(szOperator, tbConditions[i]:Execute(), bRet)
        szLog = szLog..(bRet and ", true" or ", false")
    end

    BattleOperationHelper:PrintLog(self, szLog)

    return bRet
end

return BattleGroupCondition