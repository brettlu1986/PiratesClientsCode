local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleGetPlayerIdAction = luaclass("BattleGetPlayerIdAction", BattleActionBase)

local BattleBlackboard = require("BattleBlackboard")
local BattleOperationHelper = require("BattleOperationHelper")

BattleGetPlayerIdAction.szPlayerObjKey = nil
BattleGetPlayerIdAction.szPlayerIdKey = nil

function BattleGetPlayerIdAction:Parse(tbJsonData)
    self.szPlayerObjKey = tbJsonData.PlayerObjKey
    self.szPlayerIdKey = tbJsonData.PlayerIdKey
    return true
end
-- 使用 ServerInstanceId
function BattleGetPlayerIdAction:Execute()
    BattleOperationHelper:PrintLog(self, "szPlayerObjKey: "..self.szPlayerObjKey..", szPlayerIdKey: "..self.szPlayerIdKey)

    if self.szPlayerObjKey and string.len(self.szPlayerObjKey) > 0 then 
        local tbPlayer = BattleBlackboard:GetTable(self.szPlayerObjKey)
        if tbPlayer then
            if self.szPlayerIdKey and string.len(self.szPlayerIdKey) > 0 then 
                BattleBlackboard:SetNumber(self.szPlayerIdKey, tbPlayer:GetServerInstanceId())
            end
        end
    end
    
    return true
end

return BattleGetPlayerIdAction