--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ScoreIni = {}
ScoreIni.szFileName = "common/ffa/statistics/score.ini"

function ScoreIni:OnParse(Parser)
    local tbKillScore = {}
    tbKillScore.nKillOneBaseScore = Parser:Get("kill_score", "kill_one_base_score", 0, Parser.TypeNumber)
    tbKillScore.nMinGradeAffectScore = Parser:Get("kill_score", "min_grade_affect_score", 0, Parser.TypeNumber)
    tbKillScore.nMaxGradeAffectScore = Parser:Get("kill_score", "max_grade_affect_score", 0, Parser.TypeNumber)
    tbKillScore.nHigherOneGradeScore = Parser:Get("kill_score", "higher_one_grade_score", 0, Parser.TypeNumber)
    tbKillScore.nLowerOneGradeScore = Parser:Get("kill_score", "lower_one_grade_score", 0, Parser.TypeNumber)
    self.tbKillScore = tbKillScore

    local tbTotalScore = {}
    -- tbTotalScore.nSurvivalValue = Parser:Get("total_score", "survival_value", 0, Parser.TypeNumber)
    -- tbTotalScore.nKillValue = Parser:Get("total_score", "kill_value", 0, Parser.TypeNumber)
    tbTotalScore.nTotalGradeValue = Parser:Get("total_score", "total_grade_value", 0, Parser.TypeNumber)
    tbTotalScore.nSurvivalGradeValue = Parser:Get("total_score", "survival_grade_value", 0, Parser.TypeNumber)
    tbTotalScore.nKillGradeValue = Parser:Get("total_score", "kill_grade_value", 0, Parser.TypeNumber)
    tbTotalScore.nDimensionalSurvivalValue = Parser:Get("total_score", "dimensional_survival_value", 0, Parser.TypeNumber)
    self.tbTotalScore = tbTotalScore

    local tbInitScore = {}
    tbInitScore.nRank     = Parser:Get("init_score", "rank", 0, Parser.TypeNumber)
    tbInitScore.nSurvival = Parser:Get("init_score", "survival", 0, Parser.TypeNumber)
    tbInitScore.nDistance = Parser:Get("init_score", "distance", 0, Parser.TypeNumber)
    tbInitScore.nKill     = Parser:Get("init_score", "kill", 0, Parser.TypeNumber)
    tbInitScore.nHumanDamage = Parser:Get("init_score", "human_damage", 0, Parser.TypeNumber)
    tbInitScore.nShipDamage  = Parser:Get("init_score", "ship_damage", 0, Parser.TypeNumber)
    tbInitScore.nKillBoss = Parser:Get("init_score", "kill_boss", 0, Parser.TypeNumber)
    tbInitScore.nAssist   = Parser:Get("init_score", "assist", 0, Parser.TypeNumber)
    tbInitScore.nAppliedDamage = Parser:Get("init_score", "applied_damage", 0, Parser.TypeNumber)
    tbInitScore.nItem     = Parser:Get("init_score", "item", 0, Parser.TypeNumber)
    tbInitScore.nRescue   = Parser:Get("init_score", "rescue", 0, Parser.TypeNumber)
    tbInitScore.nHumanCure= Parser:Get("init_score", "human_cure", 0, Parser.TypeNumber)
    tbInitScore.nShipCure = Parser:Get("init_score", "ship_cure", 0, Parser.TypeNumber)    
    self.tbInitScore = tbInitScore

    local tbMaxScore = {}
    tbMaxScore.nRank     = Parser:Get("max_score", "rank", 0, Parser.TypeNumber)
    tbMaxScore.nSurvival = Parser:Get("max_score", "survival", 0, Parser.TypeNumber)
    tbMaxScore.nDistance = Parser:Get("max_score", "distance", 0, Parser.TypeNumber)
    tbMaxScore.nKill     = Parser:Get("max_score", "kill", 0, Parser.TypeNumber)
    tbMaxScore.nHumanDamage = Parser:Get("max_score", "human_damage", 0, Parser.TypeNumber)
    tbMaxScore.nShipDamage  = Parser:Get("max_score", "ship_damage", 0, Parser.TypeNumber)
    tbMaxScore.nAssist      = Parser:Get("max_score", "assist", 0, Parser.TypeNumber)
    tbMaxScore.nAppliedDamage= Parser:Get("max_score", "applied_damage", 0, Parser.TypeNumber)
    tbMaxScore.nKillBoss    = Parser:Get("max_score", "kill_boss", 0, Parser.TypeNumber)
    tbMaxScore.nItem        = Parser:Get("max_score", "item", 0, Parser.TypeNumber)
    tbMaxScore.nRescue      = Parser:Get("max_score", "rescue", 0, Parser.TypeNumber)
    tbMaxScore.nHumanCure   = Parser:Get("max_score", "human_cure", 0, Parser.TypeNumber)
    tbMaxScore.nShipCure    = Parser:Get("max_score", "ship_cure", 0, Parser.TypeNumber)
    self.tbMaxScore = tbMaxScore

    local tbAssistScore = {}
    tbAssistScore.nTime   = Parser:Get("assist_kill", "time", 0, Parser.TypeNumber)
    if tbAssistScore.nTime <= 0 then
        error("assist kill time is 0")
    end
    self.tbAssistScore = tbAssistScore

    local tbDimensionalScore = {}
    tbDimensionalScore.nMin     = Parser:Get("dimensional_score", "dimensional_min", 0, Parser.TypeNumber)
    self.tbDimensionalScore = tbDimensionalScore
end

return ScoreIni
