local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleCheckCampTypeCondition = luaclass("BattleCheckCampTypeCondition", BattleConditionBase)

local BattleBlackboard = require("BattleBlackboard")

BattleCheckCampTypeCondition.nCampType = nil
BattleCheckCampTypeCondition.szGetObjKey = nil

function BattleCheckCampTypeCondition:Parse(tbJsonData)
    self.nCampType = tbJsonData.CampType
    self.szGetObjKey = tbJsonData.GetObjKey
    return true
end

function BattleCheckCampTypeCondition:Execute()
    if self.nCampType and self.szGetObjKey and string.len(self.szGetObjKey) > 0 then
        local tbObject = BattleBlackboard:GetTable(self.szGetObjKey)
        if tbObject then
            if tbObject.BattleCampComponent and self.nCampType == tbObject.BattleCampComponent:GetCampType() then 
                return true
            end
        end
    end 
    return false
end

return BattleCheckCampTypeCondition