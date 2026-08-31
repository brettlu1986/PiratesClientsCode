local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetForcedTargetToAttackAction = luaclass("BattleSetForcedTargetToAttackAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleNpcHelper = require("BattleNpcHelper")

BattleSetForcedTargetToAttackAction.szTag = nil
BattleSetForcedTargetToAttackAction.szTargetTag = nil

function BattleSetForcedTargetToAttackAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.szTargetTag = tbJsonData.TargetTag
    return true
end

local function GetNpcObject(self)
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if BattleNpcHelper:CheckIdentifier(self, Object) then
            return Object
        end
    end
    return nil
end

local function GetTagObject(szTag)
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if Object.szTag == szTag then
            return Object
        end
    end
    return nil
end

function BattleSetForcedTargetToAttackAction:Execute()
    BattleOperationHelper:PrintLog(self, "TargetTag: "..self.szTargetTag)

    local tbObject = GetNpcObject(self)
    if tbObject and tbObject.BattleAIComponent then
        local tbTargetObject = GetTagObject(self.szTargetTag)
        if tbTargetObject then
            tbObject.BattleAIComponent:SetForcedTargetToAttack(tbTargetObject)
        end
    end

    return true
end

return BattleSetForcedTargetToAttackAction