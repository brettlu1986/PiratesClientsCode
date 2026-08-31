local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePrintKeyValueAction = luaclass("BattlePrintKeyValueAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")

BattlePrintKeyValueAction.szKey = nil
BattlePrintKeyValueAction.szType = nil

function BattlePrintKeyValueAction:Parse(tbJsonData)
    self.szKey = tbJsonData.Key
    self.szType = tbJsonData.Type
    return string.len(self.szKey) > 0
end

function BattlePrintKeyValueAction:Execute()
    local Value
    local szKey = self.szKey
    local szType = self.szType

    if(szType == "Int") then
        Value = BattleBlackboard:GetNumber(szKey)
    elseif(szType == "String") then
        Value = BattleBlackboard:GetString(szKey)
    elseif(szType == "Bool") then
        Value = BattleBlackboard:GetBool(szKey)
    else
        BattleOperationHelper:PrintError(self, "Cannot find type: "..szType..", key: "..szKey)
        return false
    end
    BattleOperationHelper:PrintLog(self, "Key: "..szKey..", Value: "..tostring(Value)..", Type: "..szType)    
    return true
end

return BattlePrintKeyValueAction