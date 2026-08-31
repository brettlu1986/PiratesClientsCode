local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleGetObjNameAction = luaclass("BattleGetObjNameAction", BattleActionBase)

local BattleBlackboard = require("BattleBlackboard")
local BattleOperationHelper = require("BattleOperationHelper")

BattleGetObjNameAction.szObjKey = nil
BattleGetObjNameAction.szObjNameKey = nil

function BattleGetObjNameAction:Parse(tbJsonData)
    self.szObjKey = tbJsonData.ObjKey
    self.szObjNameKey = tbJsonData.ObjNameKey
    return true
end

function BattleGetObjNameAction:Execute()
    BattleOperationHelper:PrintLog(self, "ObjKey: "..self.szObjKey..", ObjNameKey: "..self.szObjNameKey)

    if self.szObjKey and string.len(self.szObjKey) > 0 then 
        local tbObject = BattleBlackboard:GetTable(self.szObjKey)
        if tbObject then
            if self.szObjNameKey and string.len(self.szObjNameKey) > 0 then 
                BattleBlackboard:SetString(self.szObjNameKey, tbObject.szName)
            end
        end
    end
    
    return true
end

return BattleGetObjNameAction