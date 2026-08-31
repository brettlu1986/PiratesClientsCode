local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleInteractionDialogAction = luaclass("BattleInteractionDialogAction", BattleActionBase)

local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleOperationHelper = require("BattleOperationHelper")


BattleInteractionDialogAction.nDialogId = nil
BattleInteractionDialogAction.bDialogBoard = nil

function BattleInteractionDialogAction:Parse(tbJsonData)
    self.nDialogId = tbJsonData.DialogId
    self.bDialogBoard = tbJsonData.DialogBoard
    return self.nDialogId > 0
end

function BattleInteractionDialogAction:Execute()
    BattleOperationHelper:PrintLog(self, 
    "DialogId: "..self.nDialogId..
    ", DialogBoard: "..(self.bDialogBoard and "true" or "false"))
        
    BattleInteractionHelper:ShowDialog(self.nDialogId, self.bDialogBoard)
    
    return true
end

return BattleInteractionDialogAction