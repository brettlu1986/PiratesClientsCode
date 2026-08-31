local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleDestroyTriggerAction = luaclass("BattleDestroyTriggerAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")

BattleDestroyTriggerAction.bAll = nil
BattleDestroyTriggerAction.nTriggerId = nil

function BattleDestroyTriggerAction:Parse(tbJsonData)
    self.nTriggerId = tbJsonData.TriggerId
    self.bAll = tbJsonData.All
    return true
end

function BattleDestroyTriggerAction:Execute()
    BattleOperationHelper:PrintLog(self)

    local tbIds = {}
    local bAll = self.bAll
    local nTriggerId = self.nTriggerId
    local nObjectType = GameObjectTypeDef.Trigger
    local tbObjects = GameObjectSystem:GetAllByObjectType(nObjectType)
    for Object, _ in pairs(tbObjects) do
        local nId = Object:GetServerInstanceId()
        if(bAll) then
            table.insert(tbIds, nId)
        elseif(Object.nTriggerId == nTriggerId) then
            table.insert(tbIds, nId)
            break
        end
    end

    for _, nId in ipairs(tbIds) do
        GameObjectSystem:DestroyTriggerInGameModeByInstanceId(nId)
    end
    return true
end

return BattleDestroyTriggerAction