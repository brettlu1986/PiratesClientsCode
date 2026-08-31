local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleGetPlayerCountAction = luaclass("BattleGetPlayerCountAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleBlackboard = require("BattleBlackboard")
local GameObjectTypeDef = require("GameObjectTypeDef")

BattleGetPlayerCountAction.szResultKey = nil

function BattleGetPlayerCountAction:Parse(tbJsonData)
    self.szResultKey = tbJsonData.ResultKey
    return string.len(self.szResultKey) > 0
end

function BattleGetPlayerCountAction:Execute()
    local nCount = 0
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        nCount = nCount + 1
    end

    local szKey = self.szResultKey
    BattleOperationHelper:PrintLog(self, "ResultKey: "..szKey..", Count: "..nCount)
    return BattleBlackboard:SetNumber(szKey, nCount)
end

return BattleGetPlayerCountAction