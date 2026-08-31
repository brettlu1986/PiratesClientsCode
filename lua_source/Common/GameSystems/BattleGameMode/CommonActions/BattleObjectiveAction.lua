local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleObjectiveAction = luaclass("BattleObjectiveAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleObjectiveHelper = require("BattleObjectiveHelper")
local BattleBlackboard = require("BattleBlackboard")

BattleObjectiveAction.nId = nil
BattleObjectiveAction.szParamKey0 = nil
BattleObjectiveAction.szParamKey1 = nil
BattleObjectiveAction.szParamKey2 = nil

function BattleObjectiveAction:Parse(tbJsonData)
    self.nId = tbJsonData.Id
    self.szParamKey0 = tbJsonData.ParamKey0
    self.szParamKey1 = tbJsonData.ParamKey1
    self.szParamKey2 = tbJsonData.ParamKey2
    return self.nId > 0
end

local function GetStringValue(szKey)
    if(szKey == nil or string.len(szKey) == 0) then
        return nil
    end
    local Value = BattleBlackboard:GetRaw(szKey)
    if(Value) then
        Value = tostring(Value)
    end
    return Value
end

function BattleObjectiveAction:Execute()
    local szParam0 = GetStringValue(self.szParamKey0)
    local szParam1 = GetStringValue(self.szParamKey1)
    local szParam2 = GetStringValue(self.szParamKey2)

    local szLog = string.format("Objective id: %d, param0: %s, param1: %s, param2: %s", 
        self.nId, 
        szParam0 ~= nil and szParam0 or "nil",
        szParam1 ~= nil and szParam1 or "nil",
        szParam2 ~= nil and szParam2 or "nil")     

    BattleOperationHelper:PrintLog(self, szLog)
    BattleObjectiveHelper:SendObjectiveInfo(self.nId, true, 
        szParam0, szParam1, szParam2)
    return true
end

return BattleObjectiveAction