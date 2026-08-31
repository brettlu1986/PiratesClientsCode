local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleDestroyNpcAction = luaclass("BattleDestroyNpcAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleNpcHelper = require("BattleNpcHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

BattleDestroyNpcAction.bAll = nil

function BattleDestroyNpcAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.bAll = tbJsonData.All
    return true
end

function BattleDestroyNpcAction:Execute()
    BattleOperationHelper:PrintLog(self)

    local tbIds = {}
    local bAll = self.bAll
    local nNpcType = GameObjectTypeDef.Npc
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if(Object.ObjectType == nNpcType) then
            if(bAll or BattleNpcHelper:CheckIdentifier(self, Object)) then
                table.insert(tbIds, nId)
            end
        end
    end

    for _, nId in ipairs(tbIds) do
        GameObjectSystem:DestroyNpcInGameModeByInstanceId(nId)
    end
    return true
end

return BattleDestroyNpcAction