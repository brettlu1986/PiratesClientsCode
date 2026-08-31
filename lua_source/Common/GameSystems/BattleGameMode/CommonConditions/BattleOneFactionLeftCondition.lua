local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleOneFactionLeftCondition = luaclass("BattleOneFactionLeftCondition", BattleConditionBase)

local BattleTeamSystem = require("BattleTeamSystem")

BattleOneFactionLeftCondition.bDead = nil

function BattleOneFactionLeftCondition:Parse(tbJsonData)
    self.bDead = tbJsonData.Dead
    return true
end

function BattleOneFactionLeftCondition:Execute()
    return self:CheckOneFactionLeft()
end

function BattleOneFactionLeftCondition:CheckOneFactionLeft()    
    local nFaction = nil

    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    for _, tbTeam in pairs(tbTeams) do
        for _, tbObject in pairs(tbTeam.tbGameObjects) do
            if not tbObject.IsDead() or (self.bDead and tbObject.IsDead()) then
                if nFaction == nil then 
                    nFaction =  tbObject.tbPrepareInfo.nFaction                      
                end
                if nFaction ~= nil and nFaction ~= tbObject.tbPrepareInfo.nFaction then
                    return false
                end
            end
        end
    end
    if nFaction ~= nil then 
        return true
    end 

    return false
end


return BattleOneFactionLeftCondition