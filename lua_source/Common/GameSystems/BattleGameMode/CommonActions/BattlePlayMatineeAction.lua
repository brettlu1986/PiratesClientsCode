local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayMatineeAction = luaclass("BattlePlayMatineeAction", BattleActionBase)

local BattleInteractionHelper = require("BattleInteractionHelper")
local BattleOperationHelper = require("BattleOperationHelper")
local GameplayUtilityHelper = require("GameplayUtilityHelper")


BattlePlayMatineeAction.nMatineeId = nil
BattlePlayMatineeAction.bNotNotifyClients = nil

function BattlePlayMatineeAction:Parse(tbJsonData)
    self.nMatineeId = tbJsonData.MatineeId
    self.bNotNotifyClients = tbJsonData.NotNotifyClients or false

    return self.nMatineeId > 0
end

function BattlePlayMatineeAction:Execute()

    local szLog = string.format("BattlePlayMatineeAction MatineeId: %d, NotNotifyClients: %s", 
        self.nMatineeId, self.bNotNotifyClients and "true" or "false")    

    BattleOperationHelper:PrintLog(self, szLog)

    --服务器端执行
    GameplayUtilityHelper.DestoryThrowWeapon(GWorld,GWorld)

    if self.bNotNotifyClients then
        BattleInteractionHelper:LocalPlayMatinee(self.nMatineeId, nil,nil, false)
    else
        BattleInteractionHelper:PlayMatinee(self.nMatineeId, false, false)
    end
    
    return true
end

return BattlePlayMatineeAction