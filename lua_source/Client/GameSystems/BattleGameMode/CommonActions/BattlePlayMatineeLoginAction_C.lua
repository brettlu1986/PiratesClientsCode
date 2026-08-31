local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayMatineeLoginAction_C = luaclass("BattlePlayMatineeLoginAction_C", BattleActionBase)

local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleOperationHelper = require("BattleOperationHelper")

BattlePlayMatineeLoginAction_C.nMatineeID = nil

function BattlePlayMatineeLoginAction_C:Parse(tbJsonData)
    self.nMatineeID = tbJsonData.MatineeId
    return self.nMatineeID > 0
end

function BattlePlayMatineeLoginAction_C:Execute()
    
    local szLog = string.format("BattlePlayMatineeLoginAction_C MatineeID: %d ", 
        self.nMatineeID)
    BattleOperationHelper:PrintLog(self, szLog)
    
    BattleInteractionHelper:LocalPlayMatinee(self.nMatineeID, nil, nil, false)
    return true
end

return BattlePlayMatineeLoginAction_C