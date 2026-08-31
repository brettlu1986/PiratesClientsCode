local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleNpcCountCondition = luaclass("BattleNpcCountCondition", BattleConditionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleNpcHelper = require("BattleNpcHelper")

BattleNpcCountCondition.nCount = nil
BattleNpcCountCondition.szOperator = nil

function BattleNpcCountCondition:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nCount = tbJsonData.Count
    self.szOperator = tbJsonData.Operator
    return true
end

function BattleNpcCountCondition:Execute()
    local nCurrentCount = 0
    local tbGameObjects = GameObjectSystem:GetAllGameObjects()
    for _, GameObject in pairs(tbGameObjects) do
        if (BattleNpcHelper:CheckIdentifier(self, GameObject) and (not GameObject:IsDead())) then
            nCurrentCount = nCurrentCount + 1
        end
    end

    return BattleOperationHelper:CallOperator(self.szOperator, nCurrentCount, self.nCount)
end

return BattleNpcCountCondition