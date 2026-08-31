local luaclass = require("luaclass")
local BattleConditionBase = require("BattleConditionBase")
local BattleTeamDeadCondition = luaclass("BattleTeamDeadCondition", BattleConditionBase)

local BattleTeamSystem = require("BattleTeamSystem")

BattleTeamDeadCondition.nDeadTeamId = -1
BattleTeamDeadCondition.bAllDead = false

function BattleTeamDeadCondition:Parse(tbJsonData)
    return true
end

function BattleTeamDeadCondition:Execute()
    return self:CheckDeadTeam()
end

function BattleTeamDeadCondition:CheckDeadTeam()
    local tbTeams = BattleTeamSystem:GetAllTeamInfo()
    local nMemberCount, tbGameCharacter, nDeadCount, tbGameObjects
    self.bAllDead = true

    for nTeamId, tbTeam in pairs(tbTeams) do
        tbGameObjects = tbTeam.tbGameObjects
        nMemberCount = #tbGameObjects
        nDeadCount = 0
        for i=1, nMemberCount do
            tbGameCharacter = tbGameObjects[i]
            if tbGameCharacter:IsDead() then
                nDeadCount = nDeadCount + 1
            end
        end

        if(nDeadCount >= nMemberCount) then
            self.nDeadTeamId = nTeamId
        else
            self.bAllDead = false
        end
    end
    
    if(self.nDeadTeamId >= 0 or self.bAllDead) then
        return true
    end
    return false
end

return BattleTeamDeadCondition