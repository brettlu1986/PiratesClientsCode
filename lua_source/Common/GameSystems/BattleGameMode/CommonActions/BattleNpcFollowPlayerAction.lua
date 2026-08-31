local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleNpcFollowPlayerAction = luaclass("BattleNpcFollowPlayerAction", BattleActionBase)

local BattleNpcHelper = require("BattleNpcHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleBlackboard = require("BattleBlackboard")
local GameObjectTypeDef = require("GameObjectTypeDef")
-- local BattleOperationDef = require("BattleOperationDef")

BattleNpcFollowPlayerAction.szPlayerObjKey = nil

function BattleNpcFollowPlayerAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.szPlayerObjKey = tbJsonData.PlayerObjKey
    return true
end

function BattleNpcFollowPlayerAction:Execute()
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    local TargetPlayer = nil
    if self.szPlayerObjKey and string.len(self.szPlayerObjKey) > 0 then 
        TargetPlayer = BattleBlackboard:GetTable(self.szPlayerObjKey)
    end

    if(TargetPlayer == nil or TargetPlayer.ObjectType ~= GameObjectTypeDef.PlayerSelf) then
        -- 找到第一个player
        for nId, Object in pairs(tbObjects) do
            if(Object.ObjectType == GameObjectTypeDef.PlayerSelf) then
                TargetPlayer = Object
                break
            end
        end
    end

    if TargetPlayer then
        BattleOperationHelper:PrintLog(self, BattleNpcHelper:GetIdentifierInfo(self))
        for nId, Object in pairs(tbObjects) do
            if(BattleNpcHelper:CheckIdentifier(self, Object) and Object.BattleAIComponent) then
                Object.BattleAIComponent:SetCaptain(TargetPlayer)
            end
        end
    end

    return true
end

return BattleNpcFollowPlayerAction

