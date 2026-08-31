local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleNpcFollowPlayerLoginAction = luaclass("BattleNpcFollowPlayerLoginAction", BattleActionBase)

local BattleNpcHelper = require("BattleNpcHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleBlackboard = require("BattleBlackboard")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleOperationDef = require("BattleOperationDef")

function BattleNpcFollowPlayerLoginAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    return true
end

function BattleNpcFollowPlayerLoginAction:Execute()
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    local TargetPlayer = BattleBlackboard:GetTable(BattleOperationDef.CurrentObject)
    if(TargetPlayer == nil or TargetPlayer.ObjectType ~= GameObjectTypeDef.PlayerSelf) then
        -- 找到第一个player
        for nId, Object in pairs(tbObjects) do
            if(Object.ObjectType == GameObjectTypeDef.PlayerSelf) then
                TargetPlayer = Object
                break
            end
        end
    end

    if(TargetPlayer == nil) then
        BattleOperationHelper:PrintError(self, "Can not find player")
    end

    BattleOperationHelper:PrintLog(self, BattleNpcHelper:GetIdentifierInfo(self))
    for nId, Object in pairs(tbObjects) do
        if(BattleNpcHelper:CheckIdentifier(self, Object) and Object.BattleAIComponent) then
            Object.BattleAIComponent:SetCaptain(TargetPlayer)
        end
    end
    
    return true
end

return BattleNpcFollowPlayerLoginAction

