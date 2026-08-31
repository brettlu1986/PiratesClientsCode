local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleDefineBBKeyAction = luaclass("BattleDefineBBKeyAction", BattleActionBase)

local BattleBlackboard = require("BattleBlackboard")
local BattleOperationHelper = require("BattleOperationHelper")

BattleDefineBBKeyAction.szType = nil
BattleDefineBBKeyAction.szKey = nil
BattleDefineBBKeyAction.InitValue = nil
BattleDefineBBKeyAction.bUndefine = nil

function BattleDefineBBKeyAction:Parse(tbJsonData)
    self.szType = tbJsonData.Type
    self.szKey = tbJsonData.Key
    self.InitValue = tbJsonData.InitValue
    self.bUndefine = tbJsonData.Undefine
    return string.len(self.szKey) > 0
end

function BattleDefineBBKeyAction:Execute()
    local szType = self.szType
    local szKey = self.szKey
    local bDefine = self.bUndefine == nil

    if(bDefine) then
        local InitValue = self.InitValue
        local szLog =  "Define Type: "..szType..", szKey: "..szKey..", InitValue: "..tostring(InitValue)       
        BattleOperationHelper:PrintLog(self, szLog)
        if(szType == "Int") then
            BattleBlackboard:DefineNumber(szKey, InitValue)
        elseif(szType == "String") then
            BattleBlackboard:DefineString(szKey, InitValue)
        elseif(szType == "Bool") then
            BattleBlackboard:DefineBool(szKey, InitValue)
        elseif(szType == "Table") then
            BattleBlackboard:DefineTable(szKey, InitValue)
        else
            BattleOperationHelper:PrintError(self, szLog)
            return false
        end
    else
        BattleOperationHelper:PrintLog(self, "Undefine Key: "..szKey)
        BattleBlackboard:Undefine(szKey)
    end
    
    return true
end

return BattleDefineBBKeyAction