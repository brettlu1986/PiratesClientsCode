local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetNumberAction = luaclass("BattleSetNumberAction", BattleActionBase)

local BattleBlackboard = require("BattleBlackboard")
local BattleOperationHelper = require("BattleOperationHelper")

BattleSetNumberAction.szKey = nil
BattleSetNumberAction.Value = nil

function BattleSetNumberAction:Parse(tbJsonData)
    self.szKey = tbJsonData.Key
    self.Value = tbJsonData.Value
    return string.len(self.szKey) > 0
end

function BattleSetNumberAction:Execute()
    BattleOperationHelper:PrintLog(self, "Key: "..self.szKey..", Value: "..self.Value)

    BattleBlackboard:SetNumber(self.szKey, self.Value)
    return true
end

return BattleSetNumberAction