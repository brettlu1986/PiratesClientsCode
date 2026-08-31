local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleCheckDoingQuestCondition = luaclass("BattleCheckDoingQuestCondition", BattleConditionBase)

local BattleBlackboard = require("BattleBlackboard")
local BattleQuestSystem = dynamic_require("BattleQuestSystem")

BattleCheckDoingQuestCondition.szGetObjKey = nil
BattleCheckDoingQuestCondition.nQuestId = nil

function BattleCheckDoingQuestCondition:Parse(tbJsonData)
    self.szGetObjKey = tbJsonData.GetObjKey
    self.nQuestId    = tbJsonData.QuestId
    return true
end

function BattleCheckDoingQuestCondition:Execute()
    return self:CheckDoingQuest()
end

function BattleCheckDoingQuestCondition:CheckDoingQuest()
    if self.nQuestId and self.szGetObjKey and string.len(self.szGetObjKey) > 0 then
        local tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
        if tbPlayer then
            return BattleQuestSystem:CheckDoingQuestByPlayer(tbPlayer,self.nQuestId)
        end
    end 
    return false
end

return BattleCheckDoingQuestCondition