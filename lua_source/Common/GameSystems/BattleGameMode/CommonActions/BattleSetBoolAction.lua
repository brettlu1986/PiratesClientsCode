local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetBoolAction = luaclass("BattleSetBoolAction", BattleActionBase)

local BattleBlackboard = require("BattleBlackboard")
local BattleOperationHelper = require("BattleOperationHelper")

BattleSetBoolAction.szKey = nil
BattleSetBoolAction.Value = nil

function BattleSetBoolAction:Parse(tbJsonData)
    self.szKey = tbJsonData.Key
    self.Value = tbJsonData.Value
    return string.len(self.szKey) > 0
end

function BattleSetBoolAction:Execute()
    BattleOperationHelper:PrintLog(self, 
        "Key: "..self.szKey..
        ", Value: "..(self.Value and "true" or "false"))

    BattleBlackboard:SetBool(self.szKey, self.Value)
    return true
end

return BattleSetBoolAction