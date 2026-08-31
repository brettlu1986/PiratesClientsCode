local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleGroupAction = luaclass("BattleGroupAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")

BattleGroupAction.tbActions = nil
BattleGroupAction.bForceStop = false

function BattleGroupAction:Parse(tbJsonData)
    self.tbActions = {}
    local tbGroup = tbJsonData.Group
    for i, Data in ipairs(tbGroup) do
        local Action = BattleOperationHelper:Create(self, Data)
        if(Action == nil) then
            BattleOperationHelper:PrintError(self, "Create Action failed, index: "..i)
            return false
        end
        table.insert(self.tbActions, Action)        
    end
    return true
end

function BattleGroupAction:Execute()
    BattleOperationHelper:PrintLog(self, "")

    self.bForceStop = false
    local tbActions = self.tbActions
    local nCount = #tbActions
    for i=1, nCount do
        if(not tbActions[i]:Execute()) then
            return false
        end
        if(self.bForceStop) then
            return true
        end
    end
    return true
end

function BattleGroupAction:Uninit()
    local tbActions = self.tbActions
    local nCount = #tbActions
    for i=1, nCount do
        tbActions[i]:Uninit()
    end
    BattleGroupAction.super.Uninit(self)
end

function BattleGroupAction:ForceStop()
    self.bForceStop = true
    local tbActions = self.tbActions
    local nCount = #tbActions
    for i=1, nCount do
        tbActions[i]:ForceStop()
    end
    BattleGroupAction.super.ForceStop(self)
end

return BattleGroupAction