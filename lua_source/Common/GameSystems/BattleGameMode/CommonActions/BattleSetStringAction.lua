local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetStringAction = luaclass("BattleSetStringAction", BattleActionBase)

local BattleBlackboard = require("BattleBlackboard")
local BattleOperationHelper = require("BattleOperationHelper")

BattleSetStringAction.szKey = nil
BattleSetStringAction.Value = nil

function BattleSetStringAction:Parse(tbJsonData)
    self.szKey = tbJsonData.Key
    self.Value = tbJsonData.Value
    return string.len(self.szKey) > 0
end

function BattleSetStringAction:Execute()
    BattleOperationHelper:PrintLog(self, "Key: "..self.szKey..", Value: "..self.Value)

    BattleBlackboard:SetString(self.szKey, self.Value)
    return true
end

return BattleSetStringAction