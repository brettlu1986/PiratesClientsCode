local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleGetNpcCountAction = luaclass("BattleGetNpcCountAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleNpcHelper = require("BattleNpcHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleBlackboard = require("BattleBlackboard")

BattleGetNpcCountAction.szResultKey = nil

function BattleGetNpcCountAction:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    self.szResultKey = tbJsonData.ResultKey
    return string.len(self.szResultKey) > 0
end

function BattleGetNpcCountAction:Execute()
    local nCount = 0
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for nId, Object in pairs(tbObjects) do
        if(BattleNpcHelper:CheckIdentifier(self, Object)) then
            nCount = nCount + 1
        end
    end

    local szKey = self.szResultKey
    BattleOperationHelper:PrintLog(self, "ResultKey: "..szKey..", Count: "..nCount)
    return BattleBlackboard:SetNumber(szKey, nCount)
end

return BattleGetNpcCountAction