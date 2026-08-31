local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleNpcHpCondition = luaclass("BattleNpcHpCondition", BattleConditionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

BattleNpcHpCondition.szTag = nil
BattleNpcHpCondition.szOperator = nil
BattleNpcHpCondition.nPercentage = nil

function BattleNpcHpCondition:Parse(tbJsonData)
    self.szTag = tbJsonData.Tag
    self.nPercentage = tbJsonData.Percentage
    self.szOperator = tbJsonData.Operator
    return true
end

function BattleNpcHpCondition:Execute()
    local szTag = self.szTag
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Npc)
    for Object, _ in pairs(tbObjects) do
        if(Object.szTag == szTag) then
            local nValue = Object.BattleShipPropertyComponent:GetHpPercent()
            return BattleOperationHelper:CallOperator(self.szOperator, nValue, self.nPercentage)
        end
    end

    BattleOperationHelper:PrintError(self, "Cannot find npc, tag: "..szTag)
    return false
end

return BattleNpcHpCondition