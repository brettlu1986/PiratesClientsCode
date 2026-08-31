local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleInteractionDialogLoginAction = luaclass("BattleInteractionDialogLoginAction", BattleActionBase)

local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleOperationDef = dynamic_require("BattleOperationDef")


BattleInteractionDialogLoginAction.nDialogId = nil

function BattleInteractionDialogLoginAction:Parse(tbJsonData)
    self.nDialogId = tbJsonData.DialogId
    return self.nDialogId > 0
end

function BattleInteractionDialogLoginAction:Execute()
    BattleOperationHelper:PrintLog(self, 
        "DialogId: "..self.nDialogId)
    local tbPlayer = BattleBlackboard:GetTable(BattleOperationDef.CurrentObject)
    if tbPlayer ~= nil then
        BattleInteractionHelper:PlayerShowDialog(tbPlayer, self.nDialogId)
    else
        logerror("Can't find Player")
        return false
    end

    return true
end

return BattleInteractionDialogLoginAction