local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleTeleportPlayerAction = luaclass("BattleTeleportPlayerAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleTransformPointHelper = require("BattleTransformPointHelper")
local BattlePlayerHelper = require("BattlePlayerHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleSelectPlayerStartHelper = require("BattleSelectPlayerStartHelper")

BattleTeleportPlayerAction.nTransformId = nil
BattleTeleportPlayerAction.szPlayerObjKey = nil
BattleTeleportPlayerAction.nPlayerStartGroupIndex = nil


function BattleTeleportPlayerAction:Parse(tbJsonData)
    self.nTransformId = tbJsonData.TransformId
    self.szPlayerObjKey = tbJsonData.PlayerObjKey
    self.nPlayerStartGroupIndex = tbJsonData.PlayerStartGroupIndex
    return true
end

function BattleTeleportPlayerAction:Execute()
    BattleOperationHelper:PrintLog(self,
    "TransformId: "..self.nTransformId..
    ", PlayerObjKey: "..self.szPlayerObjKey..
    ", PlayerStartGroupIndex: "..self.nPlayerStartGroupIndex)

    -- 全部传送到组
    if self.nPlayerStartGroupIndex and self.nPlayerStartGroupIndex > 0 then
        local tbGameObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
        local NewPoint
        for Object, _ in pairs(tbGameObjects) do
            NewPoint = BattleSelectPlayerStartHelper:PlayerSelectPoint(Object, true, 0, self.nPlayerStartGroupIndex, 0)
            if NewPoint == nil then
                BattleOperationHelper:PrintError(self, "PlayerSelectPoint failed, can not find point")
                return false
            end
            BattlePlayerHelper:Teleport(Object, NewPoint.Transform)
        end

    else
        -- 单人传送到点
        if self.nTransformId and self.szPlayerObjKey and string.len(self.szPlayerObjKey) > 0 then
            local tbPlayer = BattleBlackboard:GetTable(self.szPlayerObjKey)
            if tbPlayer then
                local tbTransform = BattleTransformPointHelper:Find(self.nTransformId)
                if(tbTransform == nil) then
                    BattleOperationHelper:PrintError(self, "Cannot find TransformId: "..self.nTransformId)
                    return false
                end
                BattlePlayerHelper:Teleport(tbPlayer, tbTransform)
            end
        end
    end

    return true
end

return BattleTeleportPlayerAction