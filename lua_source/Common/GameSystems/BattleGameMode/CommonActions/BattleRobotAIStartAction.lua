local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleRobotAIStartAction = luaclass("BattleRobotAIStartAction", BattleActionBase)
local BattleOperationHelper = require("BattleOperationHelper")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

function BattleRobotAIStartAction:Parse(tbJsonData)
    return true
end

function BattleRobotAIStartAction:Execute()
    BattleOperationHelper:PrintLog(self, "")

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_TEAM_BOT_START)
    
    return true
end

return BattleRobotAIStartAction