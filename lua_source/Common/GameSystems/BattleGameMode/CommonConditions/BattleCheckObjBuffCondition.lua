local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleCheckObjBuffCondition = luaclass("BattleCheckObjBuffCondition", BattleConditionBase)

local BattleBlackboard = require("BattleBlackboard")

BattleCheckObjBuffCondition.szGetObjKey = nil
BattleCheckObjBuffCondition.nBuffId = nil

function BattleCheckObjBuffCondition:Parse(tbJsonData)
    self.szGetObjKey = tbJsonData.GetObjKey
    self.nBuffId = tbJsonData.BuffId
    return true
end

function BattleCheckObjBuffCondition:Execute()
    return self:CheckBuff()
end

function BattleCheckObjBuffCondition:CheckBuff()
    if self.nBuffId and self.szGetObjKey and string.len(self.szGetObjKey) > 0 then
        local tbObject = BattleBlackboard:GetTable(self.szGetObjKey)
        if tbObject then
            if tbObject.BuffComponentServer and tbObject.BuffComponentServer:IsExistBuffById(self.nBuffId) then 
                return true
            end
        end
    end 
    return false
end

return BattleCheckObjBuffCondition