local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleTeleportNpcAction = luaclass("BattleTeleportNpcAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleNpcHelper = require("BattleNpcHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleTransformPointHelper = require("BattleTransformPointHelper")

BattleTeleportNpcAction.nTransformId = nil

function BattleTeleportNpcAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.nTransformId = tbJsonData.TransformId
    return true
end

function BattleTeleportNpcAction:Execute()
    BattleOperationHelper:PrintLog(self, self.nTransformId)

    local tbTransform = BattleTransformPointHelper:Find(self.nTransformId)
    if(tbTransform == nil) then
        BattleOperationHelper:PrintError(self, "Cannot find TransformId: "..self.nTransformId)
        return false
    end

    local tbGameObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbGameObjects) do
        if BattleNpcHelper:CheckIdentifier(self, Object) then
            BattleNpcHelper:Teleport(Object, tbTransform)
        end
    end

    return true
end

return BattleTeleportNpcAction