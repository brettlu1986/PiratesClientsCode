local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayMatineeAction_C = luaclass("BattlePlayMatineeAction_C", BattleActionBase)

local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleOperationHelper = require("BattleOperationHelper")

BattlePlayMatineeAction_C.nMatineeID = nil

function BattlePlayMatineeAction_C:Parse(tbJsonData)
    self.nMatineeID = tbJsonData.MatineeId
    return self.nMatineeID > 0
end

function BattlePlayMatineeAction_C:Execute()
    
    local szLog = string.format("BattlePlayMatineeAction_C MatineeID: %d ", 
        self.nMatineeID)
    BattleOperationHelper:PrintLog(self, szLog)
    
    BattleInteractionHelper:LocalPlayMatinee(self.nMatineeID, nil, nil, false)
    return true
end

return BattlePlayMatineeAction_C