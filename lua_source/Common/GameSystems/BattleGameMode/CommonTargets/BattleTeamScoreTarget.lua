-- 达到最大分数则完成目标

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleTeamScoreTarget = luaclass("BattleTeamScoreTarget", BattleTargetBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

BattleTeamScoreTarget.nMaxScore = nil
BattleTeamScoreTarget.EventHandle = nil
BattleTeamScoreTarget.rTeamScores = nil

function BattleTeamScoreTarget:Init()
    BattleTeamScoreTarget.super.Init(self)
    self.szName = "BattleTeamScoreTarget"
end

function BattleTeamScoreTarget:SetParams(rTeamScores, nMaxScore)
    self.rTeamScores = rTeamScores
    self.nMaxScore = nMaxScore    
end

local function OnTeamScoreChanged(self)
    local tbTeamScores = self.rTeamScores.TeamScores
    local nTeamCount = #tbTeamScores    
    local bComplete = false
    for i=1, nTeamCount do
        if(tbTeamScores[i].nScore >= self.nMaxScore) then
            bComplete = true
            break
        end
    end
    if(bComplete) then
        self:Complete()
    end
end

function BattleTeamScoreTarget:RegisterEvent()
    BattleTeamScoreTarget.super.RegisterEvent(self)

    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_TEAM_SCORE_CHANGE, self, OnTeamScoreChanged)
end

function BattleTeamScoreTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_TEAM_SCORE_CHANGE, self, OnTeamScoreChanged)
    BattleTeamScoreTarget.super.UnregisterEvent(self)
end

return BattleTeamScoreTarget
