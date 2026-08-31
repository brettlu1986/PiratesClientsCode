local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleNpcNotDestroyAction = luaclass("BattleNpcNotDestroyAction", BattleActionBase)

local BattleNpcHelper = require("BattleNpcHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

function BattleNpcNotDestroyAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    return true
end

function BattleNpcNotDestroyAction:Execute()    
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    local nUniqueId
    for nId, Object in pairs(tbObjects) do
        if Object.ObjectType == GameObjectTypeDef.Npc and BattleNpcHelper:CheckIdentifier(self, Object) then
            nUniqueId = Object:GetUEActorUniqueId()
            tbGameMode:AddNotDestroyDead(nUniqueId)
        end
    end
    
    return true
end

return BattleNpcNotDestroyAction

