local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleCheckNpcInteractionCondition = luaclass("BattleCheckNpcInteractionCondition", BattleConditionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

function BattleCheckNpcInteractionCondition:Parse(tbJsonData)

    return true
end

function BattleCheckNpcInteractionCondition:Execute()
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

return BattleCheckNpcInteractionCondition