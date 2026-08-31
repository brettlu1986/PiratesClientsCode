-- 占圈分数达到目标完成

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleOccupyScoreChangeTarget = luaclass("BattleOccupyScoreChangeTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleBlackboard = require("BattleBlackboard")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleOperationHelper = require("BattleOperationHelper")

BattleOccupyScoreChangeTarget.szOperator = nil
BattleOccupyScoreChangeTarget.nScore = 0
BattleOccupyScoreChangeTarget.szSaveCampTypeKey = nil

function BattleOccupyScoreChangeTarget:Init()
    BattleOccupyScoreChangeTarget.super.Init(self)
    self.szName = "BattleOccupyScoreChangeTarget"    
end

function BattleOccupyScoreChangeTarget:Parse(tbJsonData)
    self.szOperator = tbJsonData.Operator
    self.nMaxScore = tbJsonData.MaxScore
    self.szSaveCampTypeKey = tbJsonData.SaveCampTypeKey
    return true
end

function BattleOccupyScoreChangeTarget:OnTeamScoreChanged(rTeamScores)
    local tbTeamScores = rTeamScores.TeamScores
    local nTeamCount = #tbTeamScores    
    local bComplete = false
    local nCampType = 0
    for i=1, nTeamCount do
        if BattleOperationHelper:CallOperator(self.szOperator, tbTeamScores[i].nScore, self.nMaxScore) then
            nCampType = BattleTeamSystem:GetCampTypeByTeamId(tbTeamScores[i].nTeamId)
            if self.szSaveCampTypeKey then
                BattleBlackboard:SetNumber(self.szSaveCampTypeKey, nCampType)            
            end
            bComplete = true
            break
        end
    end
    if(bComplete) then
        self:Complete()
    end
end


function BattleOccupyScoreChangeTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_TEAM_SCORE_CHANGE, self, self.OnTeamScoreChanged)
end

function BattleOccupyScoreChangeTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_TEAM_SCORE_CHANGE, self, self.OnTeamScoreChanged)
end

function BattleOccupyScoreChangeTarget:Start()
    BattleOccupyScoreChangeTarget.super.Start(self)    
end


return BattleOccupyScoreChangeTarget
