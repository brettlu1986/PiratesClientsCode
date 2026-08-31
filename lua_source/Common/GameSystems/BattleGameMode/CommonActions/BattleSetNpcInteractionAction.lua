local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetNpcInteractionAction = luaclass("BattleSetNpcInteractionAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
-- local GameObjectSystem =  dynamic_require("GameObjectSystem")
local BattleNpcHelper = require("BattleNpcHelper")

BattleSetNpcInteractionAction.nInvalidCollectorCamp = nil

function BattleSetNpcInteractionAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nInvalidCollectorCamp = tbJsonData.InvalidCollectorCamp
    return true
end

function BattleSetNpcInteractionAction:Execute()
    BattleOperationHelper:PrintLog(self, 
    "nInvalidCollectorCamp: "..self.nInvalidCollectorCamp)

    -- local tbGameObjects = GameObjectSystem:GetAllGameObjects()
    
    -- for _, GameObject in pairs(tbGameObjects) do
    --     if (BattleNpcHelper:CheckIdentifier(self, GameObject) and (not GameObject:IsDead())) then
    --         local rTemp = GameObject.BattlePropertyRepComponent:GetNpcInteractionInvalidCamp()
    --         rTemp.nCampType = self.nInvalidCollectorCamp
    --         rTemp.Rep()
    --     end
    -- end

    return true
end

return BattleSetNpcInteractionAction