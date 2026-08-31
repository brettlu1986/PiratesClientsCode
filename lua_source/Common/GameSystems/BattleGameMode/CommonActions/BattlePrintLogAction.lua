local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePrintLogAction = luaclass("BattlePrintLogAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")

BattlePrintLogAction.szLog = nil

function BattlePrintLogAction:Parse(tbJsonData)
    self.szLog = tbJsonData.Log
    return true
end

function BattlePrintLogAction:Execute()
    BattleOperationHelper:PrintLog(self, self.szLog)    
    return true
end

return BattlePrintLogAction