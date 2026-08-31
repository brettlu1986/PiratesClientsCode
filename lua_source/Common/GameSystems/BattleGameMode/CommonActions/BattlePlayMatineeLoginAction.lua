local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayMatineeLoginAction = luaclass("BattlePlayMatineeLoginAction", BattleActionBase)

local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleOperationDef = dynamic_require("BattleOperationDef")


BattlePlayMatineeLoginAction.nMatineeId = nil


function BattlePlayMatineeLoginAction:Parse(tbJsonData)
    self.nMatineeId = tbJsonData.MatineeId
    return self.nMatineeId > 0
end

function BattlePlayMatineeLoginAction:Execute()

    local szLog = string.format("BattlePlayMatineeLoginAction MatineeId: %d,", 
        self.nMatineeId)    

    BattleOperationHelper:PrintLog(self, szLog)

    local tbPlayer = BattleBlackboard:GetTable(BattleOperationDef.CurrentObject)
    if(tbPlayer == nil) then
        BattleOperationHelper:PrintLog(self, "Can not find player from blackboard")
        return false
    end

    BattleInteractionHelper:PlayerPlayMatinee(tbPlayer, self.nMatineeId)
    return true
end

return BattlePlayMatineeLoginAction