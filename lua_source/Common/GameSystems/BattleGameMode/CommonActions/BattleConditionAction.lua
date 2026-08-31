local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleConditionAction = luaclass("BattleConditionAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")

BattleConditionAction.Condition = nil
BattleConditionAction.TrueAction = nil
BattleConditionAction.FalseAction = nil

function BattleConditionAction:Parse(tbJsonData)
    local Data = tbJsonData.Condition
    if(Data == nil) then
        BattleOperationHelper:PrintError(self, "ConditionAction:Parse failed, condition is nil")
        return false
    end
    self.Condition = BattleOperationHelper:Create(self, Data)
    if(self.Condition == nil) then
        BattleOperationHelper:PrintError(self, 
            "ConditionAction:Parse failed, the condition cannot be created: "..Data.OperationName)
        return false
    end

    if(tbJsonData.TrueAction) then
        self.TrueAction = BattleOperationHelper:Create(self, tbJsonData.TrueAction)
    end
    if(tbJsonData.FalseAction) then
        self.FalseAction = BattleOperationHelper:Create(self, tbJsonData.FalseAction)
    end    
    return self.TrueAction ~= nil or self.FalseAction ~= nil
end

function BattleConditionAction:Execute()    
    if(self.Condition ~= nil) then
        local bRet = self.Condition:Execute()
        BattleOperationHelper:PrintLog(self, "Execute Condition: "..(bRet and "true" or "false"))
        if(bRet) then
            if(self.TrueAction) then
                return self.TrueAction:Execute()
            end
        else
            if(self.FalseAction) then
                return self.FalseAction:Execute()
            end
        end
        return true
    end
    return false
end

function BattleConditionAction:Uninit()
    if(self.TrueAction) then
        self.TrueAction:Uninit()
    end
    if(self.FalseAction) then
        self.FalseAction:Uninit()
    end
    BattleConditionAction.super.Uninit(self)
end

function BattleConditionAction:ForceStop()
    if(self.TrueAction) then
        self.TrueAction:ForceStop()
    end
    if(self.FalseAction) then
        self.FalseAction:ForceStop()
    end
    BattleConditionAction.super.ForceStop(self)
end

return BattleConditionAction