local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleDungeonEndAction = luaclass("BattleDungeonEndAction", BattleActionBase)
local BattleOperationHelper = require("BattleOperationHelper")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

BattleDungeonEndAction.nResult = nil

function BattleDungeonEndAction:Parse(tbJsonData)
    self.nResult = tbJsonData.Result
    return true
end

function BattleDungeonEndAction:Execute()
    BattleOperationHelper:PrintLog(self, "")

    -- 发消息自己处理
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_DUNGEON_END, self.nResult)
    
    return true
end

return BattleDungeonEndAction