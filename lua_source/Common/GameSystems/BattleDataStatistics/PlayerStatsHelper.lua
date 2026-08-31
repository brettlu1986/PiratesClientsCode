local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")
local PropertyDef = require("BattleDataStatisticsPropertyFieldDef")
local RankScoreDataTable = require("RankScoreDataTable")
local SurvivalScoreDataTable = require("SurvivalScoreDataTable")
local MoveDistanceScoreDataTable = require("MoveDistanceScoreDataTable")
local ScoreIni = require("ScoreIni")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipPartTypeDef = require("ShipPartTypeDef")
-- local ShipDataTable = require("ShipDataTable")
-- local ShipCategory = require("ShipCategory")
local ConsumableItemDef = require("ConsumableItemDef")
local BattleAwardDataTable = require("BattleAwardDataTable")
local KillScoreDataTable = require("KillScoreDataTable")
local HumanDamageScoreDataTable = require("HumanDamageScoreDataTable")
local ShipDamageScoreDataTable = require("ShipDamageScoreDataTable")
local GradeScoreDataTable = require("GradeScoreDataTable")
local GradeValueRatioDataTable = require("GradeValueRatioDataTable")
local DamageTypeEx = require("DamageTypeEx")
local HumanBodyDef = require("HumanBodyDef")
local HumanMovementStateType = require("HumanMovementStateType")
local AssistScoreDataTable = require("AssistScoreDataTable")
local AppliedDamageScoreDataTable = require("AppliedDamageScoreDataTable")
local ScoreRateDataTable = require("ScoreRateDataTable")
local RescueScoreDataTable = require("RescueScoreDataTable")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local TemplateTypeDef = require("TemplateTypeDef")
local BattlePrepareSystem = require("BattlePrepareSystem")
local ItemScoreDataTable = require("ItemScoreDataTable")
local HumanCureScoreDataTable = require("HumanCureScoreDataTable")
local ShipCureScoreDataTable = require("ShipCureScoreDataTable")
local BattleTeamSystem = require("BattleTeamSystem")
local DamageCauserType = require("DamageCauserType")
local MathUtil = require("MathUtil")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

local BUILD_SHIP_PART_GRADE = 3

local PlayerStatsHelper = {}

-- 所有分,除了评分是保留小数点后一位，其他都是向上取整

-- 生存分参数 = 排名分-排名分起始值+生存时间分-生存时间分起始值+移动距离分-移动距离分起始值）
local function GetSurvivalScoreParam(tbStats, nPlayerRank)
    local tbInitScore = ScoreIni.tbInitScore
    local nScore = 0
    -- 排名积分
    local nRankScore = RankScoreDataTable:GetScore(nPlayerRank)
    if nRankScore == nil then
        logerror("GetRankScore no score ", nPlayerRank)
        nRankScore = 0
    end
    nRankScore = nRankScore - tbInitScore.nRank
    log("[stats]---rank ", nPlayerRank, nRankScore)
    nScore = nScore + nRankScore

    -- 生存时间积分
    local nTime = tbStats:GetProperty(PropertyDef.SURVIVALTIME)
    local nSurvivalScore = SurvivalScoreDataTable:GetScore(nTime)
    if nSurvivalScore == nil then
        logerror("GetSurvivalScore no score ", nTime)
        nSurvivalScore = 0
    end
    nSurvivalScore = nSurvivalScore - tbInitScore.nSurvival
    log("[stats]---survival ", nTime, nSurvivalScore)
    nScore = nScore + nSurvivalScore

    -- 移动距离积分
    local nShipDistance = tbStats:GetProperty(PropertyDef.SHIPMOVEDISTANCE)
    local nHumanDistance = tbStats:GetProperty(PropertyDef.HUMANMOVEDISTANCE)
    local nDistance = nShipDistance + nHumanDistance
    nDistance = math.ceil(nDistance/100)
    local nDistanceScore = MoveDistanceScoreDataTable:GetScore(nDistance)
    if nDistanceScore == nil then
        logerror("GetnDistanceScore no score ", nTime)
        nDistanceScore = 0
    end
    log("[stats]---distance ", nDistanceScore)
    nDistanceScore = nDistanceScore - tbInitScore.nDistance
    log("[stats]---distance ", nDistance, nShipDistance, nHumanDistance, nDistanceScore)
    nScore = nScore + nDistanceScore

    return nScore
end

-- 击杀分参数 =（击杀分-击杀分起始值+对人伤害分-对人伤害分起始值+对船伤害分-对船伤害分起始值
-- +助攻分-助攻分起始值+承受伤害分-承受伤害分起始值）
local function GetKillScoreParam(tbStats)
    local nGrade = tbStats:GetProperty(PropertyDef.GRADE)
    local tbKillScore = ScoreIni.tbKillScore
    local tbInitScore = ScoreIni.tbInitScore

    local nKillTotalScore = 0
    local tbOtherPlayerStats
    local tbOtherDamage = tbStats:GetOtherPlayerStats()
    for k, v in pairs(tbOtherDamage) do
        if v.bKill then
            local nKillScore = tbKillScore.nKillOneBaseScore

            tbOtherPlayerStats = BattleDataStatisticsSystem:GetCharacterStats(k)
            if tbOtherPlayerStats ~= nil then
                local nOtherGrade = tbOtherPlayerStats:GetProperty(PropertyDef.GRADE)
                if nOtherGrade > 0 then
                    local nValue = nOtherGrade - nGrade
                    if nValue > 0 then
                        nKillScore = nKillScore + nValue * tbKillScore.nHigherOneGradeScore
                    else
                        nKillScore = nKillScore + nValue * tbKillScore.nLowerOneGradeScore
                    end
                    nKillScore = math.max(nKillScore, tbKillScore.nMinGradeAffectScore)
                    nKillScore = math.min(nKillScore, tbKillScore.nMaxGradeAffectScore)
                end
            end
            nKillTotalScore = nKillTotalScore + nKillScore
        end
    end

    log("[stats]--- kill ", nKillTotalScore)
    nKillTotalScore = KillScoreDataTable:GetScore(nKillTotalScore) - tbInitScore.nKill
    local nHumanTotalDamage = tbStats:GetProperty(PropertyDef.APPLYDAMAGETOHUMAN)
    log("[stats]--- human damage ", nHumanTotalDamage)
    nHumanTotalDamage = HumanDamageScoreDataTable:GetScore(nHumanTotalDamage) - tbInitScore.nHumanDamage
    local nShipTotalDamage  = tbStats:GetProperty(PropertyDef.APPLYDAMAGETOSHIP)
    nShipTotalDamage = ShipDamageScoreDataTable:GetScore(nShipTotalDamage) - tbInitScore.nShipDamage
    log("[stats]--- ship damage ", nShipTotalDamage)
    local nAssistCount = tbStats:GetProperty(PropertyDef.ASSISTCOUNT)
    local nAssistScore = AssistScoreDataTable:GetScore(nAssistCount) - tbInitScore.nAssist
    log("[stats]--- assist ", nAssistCount, nAssistScore)
    local nShipAppliedDamage = tbStats:GetProperty(PropertyDef.SHIPAPPLIEDDAMAGE) 
    local nHumanAppliedDamage =  tbStats:GetProperty(PropertyDef.HUMANAPPLIEDDAMAGE)
    local nAppliedDamageScore =  AppliedDamageScoreDataTable:GetScore(nShipAppliedDamage + nHumanAppliedDamage) - tbInitScore.nAppliedDamage
    log("[stats]--- applied damage ", nShipAppliedDamage, nHumanAppliedDamage, nAppliedDamageScore)

    local nScore = nKillTotalScore + nHumanTotalDamage + nShipTotalDamage + nAssistScore + nAppliedDamageScore

    log("[stats]--- kill ", nScore, nKillTotalScore, nHumanTotalDamage, nShipTotalDamage, nAssistScore, nAppliedDamageScore)
    return nScore, nKillTotalScore, nHumanTotalDamage, nShipTotalDamage, nAssistScore, nAppliedDamageScore
end

-- 击杀boss分参数 = 击杀boss分-击杀boss分起始值
local function GetKillBossScoreParam(tbStats)
    local tbInitScore = ScoreIni.tbInitScore
    return 0 - tbInitScore.nKillBoss
end

-- 物资分参数 = 物资分-物资分起始值
local function GetItemScoreParam(tbStats)
    local nPlayerId = tbStats:GetProperty(PropertyDef.PLAYERID)
    local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
    if tbPlayer == nil then
        log("[stats]--- item: not find player")
        return 0
    end

    local tbInitScore = ScoreIni.tbInitScore 

    local nItemScore = 0
    local tbItemDatas = tbStats:GetItems()
    if tbItemDatas ~= nil then
        for i, v in ipairs(tbItemDatas) do
            local tbItemTemplate = BattleItemDataTable:GetTemplate(v.nTemplateId)
            if tbItemTemplate and tbItemTemplate.nBattleScore then
                nItemScore = nItemScore + v.nCount * tbItemTemplate.nBattleScore
                log("[stats]--- item template ", v.nTemplateId, v.nCount) 
            end
        end
    else
        log("[stats]--- no item ", nPlayerId)
    end

    local nScore = ItemScoreDataTable:GetScore(nItemScore)
    log("[stats]--- item ", nItemScore, nScore) 
    return nScore - tbInitScore.nItem
end

-- 评分总计分 = 排名分-排名分起始值+生存时间分-生存时间分起始值+移动距离分-移动距离分起始值）*生存积分占比+
-- （击杀分-击杀分起始值+对人伤害分-对人伤害分起始值+对船伤害分-对船伤害分起始值+助攻分-助攻分起始值+承受伤害分-承受伤害分起始值）*战斗积分占比
-- +(击杀小boss分-击杀小boss分起始值+物资分-物资分起始值) * 其他积分占比
-- local function GetEvaluateTotalScoreParam(nDungeonId, nSurvivalScoreParam, nKillScoreParam, nKillBossScoreParam, nItemScoreParam)
--     local tbScoreData = ScoreRateDataTable:GetTemplate(nDungeonId)
--     local nTotalScore = nSurvivalScoreParam * tbScoreData.nSurvivalRate / 100 + nKillScoreParam * tbScoreData.nBattleRate / 100 
--         + (nKillBossScoreParam + nItemScoreParam) * tbScoreData.nOtherRate / 100
--     local nResult = math.ceil(nTotalScore)
--     log("[stats]--- evaluate total ", nResult, nSurvivalScoreParam, nKillScoreParam, nKillBossScoreParam, nItemScoreParam)
--     return nResult
-- end

-- (MIN(SQRT(击杀分^2+助攻分^2),(击杀分满评分值+助攻分满评分值)/2)+
-- MIN(SQRT(MAX(对船伤害分，承受伤害分)^2+对人伤害分^2),(对船伤害分满评分值+对人伤害分满评分值)/2)-
-- 击杀分起始值-助攻分起始值-对人伤害分起始值-对船伤害分起始值-承受伤害分起始值)
local function GetEvaluateAndIntegralKillScoreParam(nKillScoreParam, nDamageHumanScoreParam, nDamageShipScoreParam, nAssistScoreParam, nAppliedDamageScoreParam)
    local tbInitScore = ScoreIni.tbInitScore
    local tbMaxScore = ScoreIni.tbMaxScore
    local nKillValue = nKillScoreParam + tbInitScore.nKill
    local nDamageHumanValue = nDamageHumanScoreParam + tbInitScore.nHumanDamage
    local nDamageShipValue = nDamageShipScoreParam + tbInitScore.nShipDamage
    local nAssistValue = nAssistScoreParam + tbInitScore.nAssist
    local nAppliedDamageValue = nAppliedDamageScoreParam + tbInitScore.nAppliedDamage

    local se = MathUtil.Square
    local st = math.sqrt
    
    local nResult = (math.min(st(se(nKillValue) + se(nAssistValue)), (tbMaxScore.nKill + tbMaxScore.nAssist) / 2) + 
        math.min(st(se(math.max(nDamageShipValue, nAppliedDamageValue)) + se(nDamageHumanValue)), (tbMaxScore.nShipDamage + tbMaxScore.nHumanDamage) / 2) -
        - tbInitScore.nKill - tbInitScore.nAssist - tbInitScore.nHumanDamage - tbInitScore.nShipDamage - tbInitScore.nAppliedDamage)

    log("[stats]--- total param ", nResult, nKillScoreParam, nDamageHumanScoreParam, nDamageShipScoreParam, nAssistScoreParam, nAppliedDamageScoreParam)
    return nResult         
end

-- 评分总计分 =（排名分-排名分起始值+生存时间分-生存时间分起始值+移动距离分-移动距离分起始值）*生存积分占比+
-- (MIN(SQRT(击杀分^2+助攻分^2),(击杀分起始值+助攻分起始值)/2)+MIN(SQRT(MAX(对船伤害分，承受伤害分)^2+对人伤害分^2),(对船伤害分起始值+对人伤害分起始值)/2) -
-- 击杀分起始值-助攻分起始值-对人伤害分起始值-对船伤害分起始值-承受伤害分起始值)*战斗积分占比 +
-- （击杀小boss分-击杀小boss分起始值+物资分-物资分起始值）*其他积分占比
local function GetEvaluateTotalScoreParam(nDungeonId, nSurvivalScoreParam, nKillScoreParam, nKillBossScoreParam, nItemScoreParam)
    local tbScoreData = ScoreRateDataTable:GetTemplate(nDungeonId)

    local nSurvivalScore = nSurvivalScoreParam * tbScoreData.nSurvivalRate / 100
    local nKillScore = nKillScoreParam * tbScoreData.nBattleRate / 100
    local nOtherScore = (nKillBossScoreParam + nItemScoreParam) * tbScoreData.nOtherRate / 100

    local nResult = nSurvivalScore + nKillScore + nOtherScore
    nResult = math.ceil(nResult)
    log("[stats]--- evaluate total ", nResult, nSurvivalScore, nKillScore, nKillBossScoreParam, nItemScoreParam)
    
    return nResult
end
        
-- 段位差系数 表
local function GetGradeValueRadioData(tbStats)
    local nGrade = tbStats:GetProperty(PropertyDef.GRADE)
    local nTotalGrade = BattleDataStatisticsSystem:GetCombatProperty(PropertyDef.TOTALGRADE)
    local nPlayerCount = BattleDataStatisticsSystem:GetCombatProperty(PropertyDef.PLAYERCOUNT)
    local nAvgGrade = nTotalGrade / nPlayerCount
    local nGradeValue = math.ceil(nGrade - nAvgGrade)

    local tbGradeValueRatio = GradeValueRatioDataTable:GetTemplate(nGradeValue)
    if tbGradeValueRatio ~= nil then
        log("[stats]--- grade value ", nAvgGrade, nGrade)
        return tbGradeValueRatio, nGradeValue
    else
        logerror("[stats]--- grade value failed ", nGrade, nAvgGrade)
        return nil, nGradeValue
    end
end

-- 生存积分总计分 = 生存分参数 *生存段位差系数
local function GetSurvivalTotalScoreParam(tbGradeValueData, nSurvivalScoreParam)
    return tbGradeValueData and nSurvivalScoreParam * tbGradeValueData.nSurvivalValue or 0
end

-- 战斗积分总计分 = (MIN(SQRT(击杀分^2+助攻分^2),(击杀分满评分值+助攻分满评分值)/2)+
-- MIN(SQRT(MAX(对船伤害分，承受伤害分)^2+对人伤害分^2), (对船伤害分满评分值+对人伤害分满评分值)/2)-
-- 击杀分起始值-助攻分起始值-对人伤害分起始值-对船伤害分起始值-承受伤害分起始值) *
-- 战斗段位差系数
local function GetKillTotalScoreParam(tbGradeValueData, nKillScoreParam, nDamageHumanScoreParam, nDamageShipScoreParam, nAssistScoreParam, nAppliedDamageScoreParam)
    local tbInitScore = ScoreIni.tbInitScore
    local tbMaxScore = ScoreIni.tbMaxScore

    local nKillValue = nKillScoreParam + tbInitScore.nKill
    local nDamageHumanValue = nDamageHumanScoreParam + tbInitScore.nHumanDamage
    local nDamageShipValue = nDamageShipScoreParam + tbInitScore.nShipDamage
    local nAssistValue = nAssistScoreParam + tbInitScore.nAssist
    local nAppliedDamageValue = nAppliedDamageScoreParam + tbInitScore.nAppliedDamage

    local se = MathUtil.Square
    local st = math.sqrt
    
    local nKillParam = math.min(st(se(nKillValue) + se(nAssistValue)), (tbMaxScore.nKill + tbMaxScore.nAssist) / 2) +
        math.min(st(se(math.max(nDamageShipValue, nAppliedDamageValue)) + se(nDamageHumanValue)), (tbMaxScore.nHumanDamage + tbMaxScore.nShipDamage) / 2) -
        tbInitScore.nKill - tbInitScore.nAssist - tbInitScore.nHumanDamage - tbInitScore.nShipDamage - tbInitScore.nAppliedDamage

    log("[stats]--- kill total score ", nKillParam, nKillValue, nDamageHumanValue, nDamageShipValue, nAssistValue, nAppliedDamageValue)
    return tbGradeValueData and nKillParam * tbGradeValueData.nKillValue or 0
end

-- 物资分总计分 = 物资分参数 * 物资段位差系数
local function GetItemTotalScoreParam(tbGradeValueData, nItemScoreParam)
    return tbGradeValueData and nItemScoreParam * tbGradeValueData.nItemValue or 0
end

-- 总积分总计分 =生存积分总计分*生存积分占比+战斗积分总计分*战斗积分占比+击杀boss分参数*其他积分占比+物资分总计分*其他积分占比*物资段位差系数
local function GetIntegralTotalScoreParam(nDungeonId, nSurvivalTotalScoreParam, nKillTotalScoreParam, nKillBossScoreParam, nItemTotalScoreParam)
    local tbScoreData = ScoreRateDataTable:GetTemplate(nDungeonId)
    local nTotalScore = nSurvivalTotalScoreParam * tbScoreData.nSurvivalRate / 100
            + nKillTotalScoreParam * tbScoreData.nBattleRate / 100 
            + nKillBossScoreParam * tbScoreData.nOtherRate / 100 
            + nItemTotalScoreParam * tbScoreData.nOtherRate / 100
    local nResult = math.ceil(nTotalScore)

    log("[stats]--- integral total ", nResult, nSurvivalTotalScoreParam, nKillTotalScoreParam, nKillBossScoreParam, nItemTotalScoreParam)
    return nResult
end

-- 评分 =  MIN{ROUND（归百化比例系数A*评分总计分，1），100}
local function GetBattleScore(nDungeonId, nEvaluateTotalScoreParam)
    local tbScoreData = ScoreRateDataTable:GetTemplate(nDungeonId)
    local tbMaxScore = ScoreIni.tbMaxScore
    -- 归百化比例系数A = 100/
        -- {（排名分满评分值+生存时间分满评分值+移动距离分满评分值）*生存积分占比+
        -- ((击杀分满评分值+助攻分满评分值)/2+(对人伤害分满评分值+对船伤害分满评分值+承受伤害分满评分值)/3)*战斗积分占比 
        -- +(击杀小BOSS分满评分值+物资分满评分值)*其他积分占比}

    local nValueA = (tbMaxScore.nRank + tbMaxScore.nSurvival + tbMaxScore.nDistance) * tbScoreData.nSurvivalRate / 100
        + ((tbMaxScore.nKill + tbMaxScore.nAssist) / 2 + (tbMaxScore.nHumanDamage + tbMaxScore.nShipDamage + tbMaxScore.nAppliedDamage) / 3) * tbScoreData.nBattleRate / 100
        + (tbMaxScore.nKillBoss + tbMaxScore.nItem) * tbScoreData.nOtherRate / 100
    nValueA = 100 / nValueA

    local nResult = string.format("%.1f", nValueA * nEvaluateTotalScoreParam)
    nResult = tonumber(nResult)
    nResult = math.min(nResult, 100)

    log("[stats]--- battlescore ", nResult)
    return nResult
end

-- 段位分参数 = 段位附加分-段位附加分矫正参数
local function GetGradeScoreParam(tbStats)
    local nGrade = tbStats:GetProperty(PropertyDef.GRADE)
    local nGradeScoreParam = GradeScoreDataTable:GetScore(nGrade)
    return nGradeScoreParam
end

-- 总积分 = ROUND{MIN[SQRT（总积分总计分）*归百化比例系数B，100]+段位分参数,0}+额外胜利条件积分
local function GetGradeScore(nDungeonId, nIntegralTotalScoreParam, nGradeScoreParam, nExtraScore)
    local tbMaxScore = ScoreIni.tbMaxScore
    local tbTotalScore = ScoreIni.tbTotalScore
    local tbScoreData = ScoreRateDataTable:GetTemplate(nDungeonId)
    nGradeScoreParam = nGradeScoreParam - tbTotalScore.nTotalGradeValue

    -- 归百化比例系数B = 100/{SQRT[
        -- （排名分满评分值+生存时间分满评分值+移动距离分满评分值）*生存积分占比+
        -- ((击杀分满评分值+助攻分满评分值)/2+(对人伤害分满评分值+对船伤害分满评分值+承受伤害分满评分值)/3)*战斗积分占比
        -- +(击杀BOSS分满评分值+物资分满评分值)*其他积分占比
    local nValueB = (tbMaxScore.nRank + tbMaxScore.nSurvival + tbMaxScore.nDistance) * tbScoreData.nSurvivalRate / 100
        + ((tbMaxScore.nKill + tbMaxScore.nAssist) / 2 + (tbMaxScore.nHumanDamage + tbMaxScore.nShipDamage + tbMaxScore.nAppliedDamage) / 3) * tbScoreData.nBattleRate / 100
        + (tbMaxScore.nKillBoss + tbMaxScore.nItem) * tbScoreData.nOtherRate / 100
    nValueB = 100 / math.sqrt(nValueB)

    nIntegralTotalScoreParam = math.max(nIntegralTotalScoreParam, 0)
    local nResult = math.min(math.sqrt(nIntegralTotalScoreParam) * nValueB, 100) + nGradeScoreParam + nExtraScore
    nResult = math.ceil(nResult)

    log("[stats]--- gradescore ", nResult, nIntegralTotalScoreParam, nGradeScoreParam)
    return nResult
end

-- 生存积分 = ROUND{MIN[SQRT（生存积分总计分）*归百化比例系数C，100]+段位分参数,0}
local function GetSurvivalScore(nSurvivalTotalScoreParam, nGradeScoreParam)
    local tbMaxScore = ScoreIni.tbMaxScore
    local tbTotalScore = ScoreIni.tbTotalScore
    nGradeScoreParam = nGradeScoreParam - tbTotalScore.nSurvivalGradeValue

    -- 归百化比例系数C = 100/{SQRT（排名分满评分值+生存时间分满评分值+移动距离分满评分值）}
    local nValueC = tbMaxScore.nRank + tbMaxScore.nSurvival + tbMaxScore.nDistance
    nValueC = 100 / math.sqrt(nValueC)

    nSurvivalTotalScoreParam = math.max(nSurvivalTotalScoreParam, 0)
    local nResult = math.min(math.sqrt(nSurvivalTotalScoreParam) * nValueC, 100) + nGradeScoreParam
    nResult = math.ceil(nResult)

    log("[stats]--- survivalscore ", nResult, nSurvivalTotalScoreParam, nGradeScoreParam)
    return nResult
end

-- 战斗积分 = ROUND{MIN[SQRT（战斗积分总计分）*归百化比例系数D，100]+段位分参数-30,0}
local function GetKillScore(nKillTotalScoreParam, nGradeScoreParam)
    local tbMaxScore = ScoreIni.tbMaxScore
    local tbTotalScore = ScoreIni.tbTotalScore
    nGradeScoreParam = nGradeScoreParam - tbTotalScore.nKillGradeValue

	-- 归百化比例系数D = 100/{SQRT((击杀分满评分值+助攻分满评分值)/2+(对人伤害分满评分值+对船伤害分满评分值+承受伤害分满评分值)/3)}
    local nValueD = (tbMaxScore.nKill + tbMaxScore.nAssist) / 2 + (tbMaxScore.nHumanDamage + tbMaxScore.nShipDamage + tbMaxScore.nAppliedDamage) / 3
    nValueD = 100 / math.sqrt(nValueD)

    nKillTotalScoreParam = math.max(nKillTotalScoreParam, 0)
    local nResult = math.min(math.sqrt(nKillTotalScoreParam) * nValueD, 100) + nGradeScoreParam
    nResult = math.ceil(nResult)

    log("[stats]--- killscore ", nResult, nKillTotalScoreParam, nGradeScoreParam)
    return nResult
end

-- 五维图生存=MAX{ROUND{MIN[SQRT（排名分-排名分起始值+生存时间分-生存时间分起始值+移动距离分-移动距离分起始值）*100/{SQRT（排名分满评分值+生存时间分满评分值+移动距离分满评分值）} * 五维图生存修正系数，100],1},10}
local function GetDimensionalSurvival(tbStats, nSurvivalScoreParam)
    local nSurvivalParam = math.max(nSurvivalScoreParam, 0)
    local tbMaxScore = ScoreIni.tbMaxScore
    local nMaxScoreParam = tbMaxScore.nRank + tbMaxScore.nSurvival + tbMaxScore.nDistance
    local nResult = math.min((math.sqrt(nSurvivalParam) * 100 / math.sqrt(nMaxScoreParam)) * ScoreIni.tbTotalScore.nDimensionalSurvivalValue, 100)
    nResult = tonumber(string.format("%0.1f", nResult))
    nResult = math.max(nResult, ScoreIni.tbDimensionalScore.nMin)
    log("[stats]--- dimensional survival ", nResult, nSurvivalParam, nMaxScoreParam)
    return nResult
end

-- 五维图伤害=MAX{ROUND{MIN[SQRT（对人伤害分-对人伤害分起始值+对船伤害分-对船伤害分起始值）*100/{SQRT（对人伤害分满评分值+对船伤害分满评分值）}，100],1},10}
local function GetDimensionalDamage(tbStats, nDamageHumanScoreParam, nDamageShipScoreParam)
    local nDamageScoreParam = math.max((nDamageHumanScoreParam + nDamageShipScoreParam), 0)
    local tbMaxScore = ScoreIni.tbMaxScore
    local nMaxScoreParam = tbMaxScore.nHumanDamage + tbMaxScore.nShipDamage
    
    local nResult = math.min(math.sqrt(nDamageScoreParam) * 100 / math.sqrt(nMaxScoreParam), 100)
    
    nResult = tonumber(string.format("%0.1f", nResult))
    nResult = math.max(nResult, ScoreIni.tbDimensionalScore.nMin)

    log("[stats]--- dimensional damage ", nResult, nDamageScoreParam, nMaxScoreParam)
    return nResult    
end

-- 五维图击败=MAX{ROUND{MIN[SQRT（击杀分-击杀分起始值）*100/{SQRT（击杀分满评分值）}，100],1},10}
local function GetDimensionalKill(tbStats, nKillScore)
    local nKillScoreParam = math.max(nKillScore, 0)
    local tbMaxScore = ScoreIni.tbMaxScore
    local nResult = math.min(math.sqrt(nKillScoreParam) * 100 / math.sqrt(tbMaxScore.nKill), 100)

    nResult = tonumber(string.format("%0.1f", nResult))
    nResult = math.max(nResult, ScoreIni.tbDimensionalScore.nMin)
    
    log("[stats]--- dimensional kill ", nResult, nKillScoreParam)
    return nResult            
end

-- 多人局
-- 五维图支援=MAX{ROUND{MIN[SQRT（助攻分-助攻分起始值+救援分-救援分起始值+承受伤害分-承受伤害分起始值）*100/{SQRT（助攻分满评分值+救援分满评分值+承受伤害分满评分值）}，100],1}，10}
-- 单人局
-- 五维图支援= ROUND(MAX(MIN(SQRT(承受伤害分-承受伤害分起始值)*100/SQRT(承受伤害分满评分值),100),10),1)
-- ROUND(MAX(MIN(MAX(SQRT(人治疗分-人治疗分起始值)*100/SQRT(人治疗分满评分值),SQRT(船治疗分-船治疗分起始值)*100/SQRT(船治疗分满评分值)),100),10),1)
local function GetDimensionalAssist(tbStats, nAssistScoreParam, nAppliedDamageScoreParam)
    local nTeamModeId = BattleGameModeSystem:GetGameInitData().nTeamModeId or 1
    local tbMaxScore = ScoreIni.tbMaxScore
    local nResult = 0
    if nTeamModeId > 1 then
        local nRescueCount = tbStats:GetProperty(PropertyDef.RESCUINGCOUNT) 
        local nRescueScoreParam = RescueScoreDataTable:GetScore(nRescueCount) - ScoreIni.tbInitScore.nRescue
        local nAssistScore = math.max(nAssistScoreParam + nRescueScoreParam + nAppliedDamageScoreParam, 0)
        nResult = math.min(math.sqrt(nAssistScore) * 100 / math.sqrt(tbMaxScore.nAssist + tbMaxScore.nRescue + tbMaxScore.nAppliedDamage), 100)
        nResult = tonumber(string.format("%0.1f", nResult))
        nResult = math.max(nResult, ScoreIni.tbDimensionalScore.nMin)
        log("[stats]--- dimensional assist ", nResult, nRescueCount, nRescueScoreParam, nAssistScore, nAssistScoreParam, nAppliedDamageScoreParam)
    else
        local tbInitScore = ScoreIni.tbInitScore
        local nHumanCureScore = HumanCureScoreDataTable:GetScore(tbStats:GetProperty(PropertyDef.APPLYCURETOHUMAN))
        local nShipCureScore  = ShipCureScoreDataTable:GetScore(tbStats:GetProperty(PropertyDef.APPLYCURETOSHIP))
        
        nResult = math.max(math.min(math.max(math.sqrt(nHumanCureScore - tbInitScore.nHumanCure)*100/math.sqrt(tbMaxScore.nHumanCure),
            math.sqrt(nShipCureScore - tbInitScore.nShipCure)*100/math.sqrt(tbMaxScore.nShipCure)), 100), ScoreIni.tbDimensionalScore.nMin)          
        nResult = tonumber(string.format("%0.1f", nResult))
        log("[stats]--- dimensional single assist ", nResult, tbStats:GetProperty(PropertyDef.APPLYCURETOHUMAN), nHumanCureScore, tbStats:GetProperty(PropertyDef.APPLYCURETOSHIP), nShipCureScore)
    end
    return nResult                
end

-- 物资= MAX{ROUND{MIN[SQRT（物资分-物资分起始值）*100/{SQRT（物资分满评分值）}，100],1},10}
local function GetDimensionalItem(tbStats, nItemScoreParam)
    nItemScoreParam = math.max(nItemScoreParam, 0)
    local nResult = math.min(math.sqrt(nItemScoreParam) * 100 / math.sqrt(ScoreIni.tbMaxScore.nItem), 100)
    nResult = tonumber(string.format("%0.1f", nResult))
    nResult = math.max(nResult, ScoreIni.tbDimensionalScore.nMin)
    
    log("[stats]--- dimensional item ", nResult, nItemScoreParam)
    return nResult                    
end

local function GetWeaponKillCount(tbStats, tbData)
    local tbKillDatas = tbStats:GetKillStats()
    local tbRegionDatas = tbStats:GetRegionStats()
    local tbMovementDatas = tbStats:GetMovementStats()
    local fnGetCount = function(nDamageType, nTemplateType)
        if nTemplateType == nil then
            nTemplateType = 0 
        end
        local nCount = 0
        local tbKillData = tbKillDatas[nDamageType]
        

        if tbKillData ~= nil then
            if nTemplateType == 0 then
                for k, v in pairs(tbKillData) do
                    nCount = nCount + v
                end
            else
                for k, v in pairs(tbKillData) do
                    if k == nTemplateType then
                        nCount = nCount + v
                    end
                end
            end
        end
        log("[stats]--- weapon kill count : ", nDamageType, nTemplateType, nCount)
        return nCount
    end

    tbData.grenade_kill = fnGetCount(DamageTypeEx.HUMAN_GRENADE)
    tbData.melee_kill = fnGetCount(DamageTypeEx.HUMAN_MELEE)
    tbData.head_hit_kill = tbRegionDatas[HumanBodyDef.HUMAN_HEAD]
    tbData.firebomb_kill = fnGetCount(DamageTypeEx.HUMAN_FIREBOMB)
    tbData.bow_kill = fnGetCount(DamageTypeEx.HUMAN_BOW)
    tbData.carronade_kill = fnGetCount(DamageTypeEx.SHIP_CARRONADE, TemplateTypeDef.SHIP)
    tbData.embolon_kill = fnGetCount(DamageTypeEx.SHIP_EMBOLON, TemplateTypeDef.SHIP)
    tbData.torpedo_kill = fnGetCount(DamageTypeEx.SHIP_TORPEDO, TemplateTypeDef.SHIP)
    tbData.bumping_kill = fnGetCount(DamageTypeEx.SHIP_BUMPING, TemplateTypeDef.HUMAN)
    tbData.kill_on_vehicle = tbMovementDatas[HumanMovementStateType.Vehicle]
end

local function GetAttackCount(tbStats)
    local nMeleeAttackCount = tbStats:GetProperty(PropertyDef.MELEEATTACKCOUNT)

    local nConsumeBulletCount = 0
    local tbItemData
    local tbConsumeItems = tbStats:GetConsumeItem()
    for k, v in pairs(tbConsumeItems) do
        tbItemData = BattleItemDataTable:GetTemplate(k)
        if tbItemData and
            (tbItemData.nCategory == BattleItemCategoryDef.SHIP_BULLET
            or tbItemData.nCategory == BattleItemCategoryDef.HUMAN_BULLET
            or tbItemData.nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM) then
            nConsumeBulletCount = nConsumeBulletCount + v
        end
    end

    return nMeleeAttackCount + nConsumeBulletCount
end

-- 使用药品或维修包次数/使用酒类或饮料次数
local function GetConsumeItemCount(tbStats)
    local nDrugCount, nWineCount = 0, 0
    local tbConsumeItems = tbStats:GetConsumeItem()
    local tbItemData

    local ConsumableSubType = ConsumableItemDef.ConsumableSubType
    for k, v in pairs(tbConsumeItems) do
        tbItemData = BattleItemDataTable:GetTemplate(k)
        if tbItemData then
            if tbItemData.nCategory == BattleItemCategoryDef.HUMAN_CONSUMABLE and tbItemData.nSubCategory == ConsumableSubType.MEDICINE then
                nDrugCount = nDrugCount + v
            elseif tbItemData.nCategory == BattleItemCategoryDef.HUMAN_CONSUMABLE and tbItemData.nSubCategory == ConsumableSubType.FOOD_AND_DRINK then
                nWineCount = nWineCount + v
            end
        end
    end
    log("[stats]--- consume count ", nDrugCount, nWineCount)
    -- 因为使用消耗类物品EV_CONSUMABLE_ITEM_CONSUME_SUCCESS，EV_DECREASE_PLAYER_BATTLE_ITEM事件都会触发，
    -- 使用子弹炮弹只会触发EV_DECREASE_PLAYER_BATTLE_ITEM 
    -- 所以统计时两个事件都得监听，导致消耗类物品统计两次，又不想在统计的地方添加物品类型判断，所以 /2
    return math.floor(nDrugCount / 2), math.floor(nWineCount / 2)
end

-- 建造舰船零件、武器、三级舰船、三级船帆、三级护甲、三级船长室个数
local function GetBuildShipPartCount(tbStats, tbData)
    local tbBuildItems = tbStats:GetBuildItem()
    local tbItemData
    local nPartCount, nWeaponCount, nShipCount, nSailCount, nArmorCount, nCaptainRoomCount = 0, 0, 0, 0, 0, 0
    for k, v in pairs(tbBuildItems) do
        tbItemData = BattleItemDataTable:GetTemplate(k)
        if tbItemData then
            if tbItemData.nCategory == BattleItemCategoryDef.SHIP_PART then
                nPartCount = nPartCount + v
                if tbItemData.nGrade == BUILD_SHIP_PART_GRADE then
                    if tbItemData.nSubCategory == ShipPartTypeDef.ARMOR then
                        nArmorCount = nArmorCount + v
                    elseif tbItemData.nSubCategory == ShipPartTypeDef.CAPTAIN_ROOM then
                        nCaptainRoomCount = nCaptainRoomCount + v
                    end
                end
            elseif tbItemData.nCategory == BattleItemCategoryDef.SHIP_WEAPON then
                nWeaponCount = nWeaponCount + v
            elseif tbItemData.nCategory == BattleItemCategoryDef.SHIP then
                if tbItemData.nGrade == BUILD_SHIP_PART_GRADE then
                    nShipCount = nShipCount + v
                end
            end
        end
    end

    tbData.built_part = nPartCount
    tbData.built_weapon = nWeaponCount
    tbData.built_ship = nShipCount
    tbData.built_sail = nSailCount
    tbData.built_armor = nArmorCount
    tbData.built_captain_room = nCaptainRoomCount
end

-- local function IsRequireShipToOverGame(tbStats, nGrade, nCategory)
--     local nShipId = tbStats:GetProperty(PropertyDef.GAMEOVERUSESHIP)
--     local tbShipData = ShipDataTable:GetTemplate(nShipId)
--     if tbShipData then
--         if tbShipData.nGrade == nGrade and tbShipData.nCategory == nCategory then
--             return 1
--         else
--             return 0
--         end
--     else
--         return 0
--     end
-- end

local function IsFirstPickUpAirDrop(tbStats)
    local nTeamId = tbStats:GetProperty(PropertyDef.TEAMID)
    local nRecordTeamId = BattleDataStatisticsSystem:GetCombatProperty(PropertyDef.FIRSTAIRDROP)
    return nTeamId == nRecordTeamId
end

local function GetStatsScore(tbStats, nPlayerRank, nExtraScore, nDungeonId)
    local tbRet = {}
    tbRet.nGradeScore = tbStats:GetProperty(PropertyDef.GRADESCORE)
    tbRet.nBattleScore = tbStats:GetProperty(PropertyDef.BATTLESCORE)
    tbRet.nSurvivalScore = tbStats:GetProperty(PropertyDef.SURVIVALSCORE)
    tbRet.nKillScore = tbStats:GetProperty(PropertyDef.KILLSCORE)
    tbRet.nDimensionalSurvival = tbStats:GetProperty(PropertyDef.DIMENSIIONALSURVIVAL)
    tbRet.nDimensionalDamage = tbStats:GetProperty(PropertyDef.DIMENSIIONALDAMAGE)
    tbRet.nDimensionalKill = tbStats:GetProperty(PropertyDef.DIMENSIIONALKILL)
    tbRet.nDimensionalAssist = tbStats:GetProperty(PropertyDef.DIMENSIIONALASSIST)
    tbRet.nDimensionalItem = tbStats:GetProperty(PropertyDef.DIMENSIIONALITEM)
    local bSeted = false
    for k, v in pairs(tbRet) do
        if v ~= 0 then
            bSeted = true
            break
        end
    end
    if not bSeted then
        local nSurvivalScoreParam = GetSurvivalScoreParam(tbStats, nPlayerRank)
        local _, nKillScore, nDamageHumanScoreParam, nDamageShipScoreParam, nAssistScoreParam, nAppliedDamageScoreParam
             = GetKillScoreParam(tbStats)
        local nKillBossScoreParam = GetKillBossScoreParam(tbStats)
        local nItemScoreParam = GetItemScoreParam(tbStats)
        local nEvaluateAndIntegralKillScoreParam = GetEvaluateAndIntegralKillScoreParam(nKillScore, nDamageHumanScoreParam, nDamageShipScoreParam, nAssistScoreParam, nAppliedDamageScoreParam)
        -- local nEvaluateTotalScoreParam = GetEvaluateTotalScoreParam(nDungeonId, nSurvivalScoreParam, nKillScoreParam, nKillBossScoreParam, nItemScoreParam)
        local nEvaluateTotalScoreParam = GetEvaluateTotalScoreParam(nDungeonId, nSurvivalScoreParam, 
            nEvaluateAndIntegralKillScoreParam, nKillBossScoreParam, nItemScoreParam)
        
        local tbGradeValueData = GetGradeValueRadioData(tbStats)
        local nSurvivalTotalScoreParam = GetSurvivalTotalScoreParam(tbGradeValueData, nSurvivalScoreParam)
        local nKillTotalScoreParam = GetKillTotalScoreParam(tbGradeValueData, nKillScore, nDamageHumanScoreParam, nDamageShipScoreParam, nAssistScoreParam, nAppliedDamageScoreParam)
        local nItemTotalScoreParam = GetItemTotalScoreParam(tbGradeValueData, nItemScoreParam)
        local nIntegralTotalScoreParam = GetIntegralTotalScoreParam(nDungeonId, nSurvivalTotalScoreParam, nEvaluateAndIntegralKillScoreParam, nKillBossScoreParam, nItemTotalScoreParam)
        local nGradeScoreParam = GetGradeScoreParam(tbStats)
        tbRet.nGradeScore = GetGradeScore(nDungeonId, nIntegralTotalScoreParam, nGradeScoreParam, nExtraScore)
        tbRet.nBattleScore = GetBattleScore(nDungeonId, nEvaluateTotalScoreParam)
        tbRet.nSurvivalScore = GetSurvivalScore(nSurvivalTotalScoreParam, nGradeScoreParam)
        tbRet.nKillScore = GetKillScore(nKillTotalScoreParam, nGradeScoreParam)
        tbRet.nDimensionalSurvival = GetDimensionalSurvival(tbStats, nSurvivalScoreParam)
        tbRet.nDimensionalDamage = GetDimensionalDamage(tbStats, nDamageHumanScoreParam, nDamageShipScoreParam)
        tbRet.nDimensionalKill = GetDimensionalKill(tbStats, nKillScore)
        tbRet.nDimensionalAssist = GetDimensionalAssist(tbStats, nAssistScoreParam, nAppliedDamageScoreParam)
        tbRet.nDimensionalItem = GetDimensionalItem(tbStats, nItemScoreParam)

        tbStats:SetProperty(PropertyDef.GRADESCORE, tbRet.nGradeScore)
        tbStats:SetProperty(PropertyDef.BATTLESCORE, tbRet.nBattleScore)
        tbStats:SetProperty(PropertyDef.SURVIVALSCORE, tbRet.nSurvivalScore)
        tbStats:SetProperty(PropertyDef.KILLSCORE, tbRet.nKillScore)
        tbStats:SetProperty(PropertyDef.DIMENSIIONALSURVIVAL, tbRet.nDimensionalSurvival)
        tbStats:SetProperty(PropertyDef.DIMENSIIONALDAMAGE, tbRet.nDimensionalDamage)
        tbStats:SetProperty(PropertyDef.DIMENSIIONALKILL, tbRet.nDimensionalKill)
        tbStats:SetProperty(PropertyDef.DIMENSIIONALASSIST, tbRet.nDimensionalAssist)
        tbStats:SetProperty(PropertyDef.DIMENSIIONALITEM, tbRet.nDimensionalItem)
    end

    return tbRet
end

local function GetAward(tbStats, nPlayerRank)
    local tbAwardData = BattleAwardDataTable:GetTemplate(nPlayerRank)
    if tbAwardData == nil then
        logerror("PlayerStatsHelper get award failed, invalid rank", nPlayerRank)
        return 0, 0
    end

    local nExp = tbAwardData.nExp
    local nCurrency = tbAwardData.nCurrency
    local nKillCount = tbStats:GetProperty(PropertyDef.KILL)
    local nKillCurrency = math.min(nKillCount * tbAwardData.nExtraKillCurrency, tbAwardData.nExtraKillCurrencyMax)

    return nExp, nCurrency + nKillCurrency
end

-- [[不属于统计系统，移到BattleAwardHelper中

--新的结算根据BATTLESCORE来发奖，不再依据个人排名
-- local function GetBattleResultAward(tbPlayer,nBattleScore,nDungeonId)
--     log("GetBattleResultAward Param:nDungeonId:",nDungeonId,",nBattleScore:",nBattleScore)
--     local tbRet = BattleResultAwardDataTable:GetTemplate(nDungeonId,nBattleScore)
--     local tbAwardLimited = tbPlayer.tbPrepareInfo.tbAwardLimited
--     local tbItemIdToCountMap = {}
--     for _,tbCurLimit in pairs(tbAwardLimited) do
--         tbItemIdToCountMap[tbCurLimit.template_id] = tbCurLimit.count
--     end

--     if tbRet then
--         local tbReturnAwards = {}
--         --先随机普通奖励
--         local tbNormalAwards = tbRet.tbNormalAwards
--         local nNormalCount = #tbNormalAwards

--         for i = 1,nNormalCount do
--             local nDropRate = tbNormalAwards[i].nDropRate
--             local nRandomNum = math.random(1,AWARD_RATE_BASE) --基于10000
--             if tbNormalAwards[i].nItemCount > 0 and nRandomNum <= nDropRate then
--                 local curAward = {}
--                 curAward.templateId = tbNormalAwards[i].nItemId
--                 curAward.count      = tbNormalAwards[i].nItemCount
--                 curAward.award_type = proto.AccountAwardType.REGULAR
--                 table.insert(tbReturnAwards,curAward)
--             end
--         end
--         --再随机特殊奖励
--         local tbSpecialAwards = tbRet.tbSpecialAwards
--         local nSpecialCount = #tbSpecialAwards
--         for i = 1,nSpecialCount do
--             local nDropRate = tbSpecialAwards[i].nDropRate
--             local nRandomNum = math.random(1,AWARD_RATE_BASE) --基于10000
--             if tbSpecialAwards[i].nItemCount > 0 and nRandomNum <= nDropRate then
--                 local curAward = {}
--                 curAward.templateId = tbSpecialAwards[i].nItemId
--                 curAward.count      = tbSpecialAwards[i].nItemCount
--                 curAward.award_type = proto.AccountAwardType.SPECIAL
--                 table.insert(tbReturnAwards,curAward)
--             end
--         end

--         local nRetCount = #tbReturnAwards
--         for i = 1,nRetCount do
--             local tbCurAward = tbReturnAwards[i]
--             if tbItemIdToCountMap[tbCurAward.templateId] ~= nil then
--                 tbCurAward.count = math.min(tbCurAward.count,tbItemIdToCountMap[tbCurAward.templateId])
--             end
--         end

--         if nRetCount > 0 then
--             return tbReturnAwards
--         end
--     end

--     return nil
-- end

--把特殊奖励剔除然后转成proto.BattleResultAward数组并返回
-- local function FillClientAwards(tbAwards)
--     local tbRet = {}

--     local nAwardCount = #tbAwards
--     for i = 1,nAwardCount do
--         if tbAwards[i].award_type == proto.AccountAwardType.REGULAR then
--             local curAward = {}
--             curAward.nItemId = tbAwards[i].templateId
--             curAward.nItemCount = tbAwards[i].count
--             table.insert(tbRet,curAward)
--         end
--     end

--     return tbRet
-- end
-- ]]

function PlayerStatsHelper:GetTeamMVP(tbTeamdata)
    local tbMVP = {}
    for nIndex, tbData in ipairs(tbTeamdata) do
        local nPlayerId = tbData.nPlayerId
        local tbStats = BattleDataStatisticsSystem:GetCharacterStats(nPlayerId)
        if tbStats then
            local nBattleScore = tbStats:GetProperty(PropertyDef.BATTLESCORE)
            local nKill = tbStats:GetProperty(PropertyDef.KILL)
            local nShipDamage = tbStats:GetProperty(PropertyDef.APPLYDAMAGETOSHIP)
            local nHumanDamage = tbStats:GetProperty(PropertyDef.APPLYDAMAGETOHUMAN)
            table.insert(tbMVP, {nInstanceId = tbData.nInstanceId, 
                nPlayerId = nPlayerId,
                nIndex = nIndex, 
                nBattleScore = nBattleScore,
                nKill = nKill,
                nShipDamage = nShipDamage,
                nHumanDamage = nHumanDamage})
            log("[stats] ---mvp ", nPlayerId, nBattleScore, nKill, nShipDamage, nHumanDamage)
        else
            logwarning("PlayerStatsHelper:GetTeamMVP invalid playerid ", nPlayerId)
        end
    end
    if #tbMVP > 0 then
        local fnSort = function(a, b)
            if a.nBattleScore > b.nBattleScore then
                return true
            elseif a.nBattleScore < b.nBattleScore then
                return false
            elseif a.nKill > b.nKill then
                return true
            elseif a.nKill < b.nKill then
                return false
            elseif a.nShipDamage > b.nShipDamage then
                return true
            elseif a.nShipDamage < b.nShipDamage then
                return false
            elseif a.nHumanDamage > b.nHumanDamage then
                return true
            elseif a.nHumanDamage < b.nHumanDamage then
                return false
            end
            return a.nIndex < b.nIndex
        end
        table.sort(tbMVP, fnSort)
        return tbMVP[1].nInstanceId, tbMVP[1].nPlayerId
    else
        error("PlayerStatsHelper:GetTeamMVP Error")
        return 0, 0
    end
end

function PlayerStatsHelper:GetBotStatisticsData(nPlayerId, nPlayerRank, nExtraScore, nDungeonId, tbData)
    local tbStats = BattleDataStatisticsSystem:GetCharacterStats(nPlayerId)
    if tbStats ~= nil then
        local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
        if tbPlayer then
            BattleDataStatisticsSystem:StatisticsCharacterResult(tbPlayer, nPlayerRank)
        end
        self:GetClientStatisticsData(nPlayerId, nPlayerRank, nExtraScore, nDungeonId, tbData)
    end
end

function PlayerStatsHelper:GetClientStatisticsData(nPlayerId, nPlayerRank, nExtraScore, nDungeonId, tbData)
    local tbStats = BattleDataStatisticsSystem:GetCharacterStats(nPlayerId)
    if tbStats ~= nil then
        log("[stats] ---client ", nPlayerId)
        tbData.nApplyDamageToShip = tbStats:GetProperty(PropertyDef.APPLYDAMAGETOSHIP)
        tbData.nApplyDamageToHuman = tbStats:GetProperty(PropertyDef.APPLYDAMAGETOHUMAN)
        tbData.nApplyCureToShip = tbStats:GetProperty(PropertyDef.APPLYCURETOSHIP)
        tbData.nApplyCureToHuman = tbStats:GetProperty(PropertyDef.APPLYCURETOHUMAN)
        log("[stats] ---client cure ", tbStats:GetProperty(PropertyDef.APPLYCURETOSHIP), tbStats:GetProperty(PropertyDef.APPLYCURETOHUMAN))
        local nDistance = tbStats:GetProperty(PropertyDef.SHIPMOVEDISTANCE) + tbStats:GetProperty(PropertyDef.HUMANMOVEDISTANCE)
        tbData.nMoveDistance = math.ceil(nDistance/100)
        tbData.nShipLaunchCount = tbStats:GetProperty(PropertyDef.SHIPLAUNCHCOUNT)
        tbData.nShipHitCount = tbStats:GetProperty(PropertyDef.SHIPHITCOUNT)
        tbData.nHumanLaunchCount = tbStats:GetProperty(PropertyDef.HUMANLAUNCHCOUNT)
        tbData.nHumanHitCount = tbStats:GetProperty(PropertyDef.HUMANHITCOUNT)
        tbData.nHitShipCoreCount = tbStats:GetProperty(PropertyDef.HITSHIPCORECOUNT)
        tbData.nHitHumanCoreCount = tbStats:GetProperty(PropertyDef.HITHUMANCORECOUNT)
        tbData.nSaveTeamateCount = tbStats:GetProperty(PropertyDef.RESCUINGCOUNT)
        tbData.nSurvivalTime = tbStats:GetProperty(PropertyDef.SURVIVALTIME)
        tbData.nKillCount = tbStats:GetProperty(PropertyDef.KILL)
        tbData.nAssistCount = tbStats:GetProperty(PropertyDef.ASSISTCOUNT)
        tbData.nShipAppliedDamage = tbStats:GetProperty(PropertyDef.SHIPAPPLIEDDAMAGE)
        tbData.nHumanAppliedDamage = tbStats:GetProperty(PropertyDef.HUMANAPPLIEDDAMAGE)
        if nPlayerRank == nil then
            nPlayerRank = tbStats:GetProperty(PropertyDef.PLAYERRANK)
            if nPlayerRank <= 0 then
                nPlayerRank = nil
            else
                log("[stats] ---client rank ", nPlayerRank)
            end
        end
        if nPlayerRank then
            tbData.nExtraScore = nExtraScore
            tbData.nExp, tbData.nCurrency = GetAward(tbStats, nPlayerRank)--TODO 所有奖励挪到Awards中，待删除

            local tbScoreData = GetStatsScore(tbStats, nPlayerRank, nExtraScore, nDungeonId)
            for k, v in pairs(tbScoreData) do
                tbData[k] = v 
            end

            -- if tbAwards then
            --     tbData.Awards = FillClientAwards(tbAwards)
            -- end
        else
            log("[stats] ---client battle score 0 ")
            tbData.nBattleScore = 0
        end
    end
end

function PlayerStatsHelper:CreateLobbyPlayerStatisticsData(tbPlayer, nPlayerId, nPlayerRank, nExtraScore, nDungeonId)
    if not nPlayerRank then
        return
    end
    local tbStats = BattleDataStatisticsSystem:GetPlayerStats(nPlayerId)
    if tbStats ~= nil  then
        if tbStats:GetProperty(PropertyDef.GAMETIME) <= 0 then
            log("[stats] ---lobby ", nPlayerId)
            BattleDataStatisticsSystem:StatisticsCharacterResult(tbPlayer, nPlayerRank)
            local tbData = {}
            tbData.rank = nPlayerRank
            tbData.kill = tbStats:GetProperty(PropertyDef.KILL)
            tbData.death = tbStats:GetProperty(PropertyDef.DEATH) > 0 and true or false
            tbData.duration = tbStats:GetProperty(PropertyDef.SURVIVALTIME)
            tbData.human_distance = tbStats:GetProperty(PropertyDef.HUMANMOVEDISTANCE)
            local nDistance = tbStats:GetProperty(PropertyDef.SHIPMOVEDISTANCE) + tbData.human_distance
            tbData.distance = math.ceil(nDistance/100)
            tbData.heals = tbStats:GetProperty(PropertyDef.APPLYCURETOSHIP) + tbStats:GetProperty(PropertyDef.APPLYCURETOHUMAN)
            tbData.rescues = tbStats:GetProperty(PropertyDef.RESCUINGCOUNT)
            tbData.damage = tbStats:GetProperty(PropertyDef.APPLYDAMAGETOSHIP) + tbStats:GetProperty(PropertyDef.APPLYDAMAGETOHUMAN)
            tbData.hit = tbStats:GetProperty(PropertyDef.SHIPHITCOUNT) + tbStats:GetProperty(PropertyDef.HUMANHITCOUNT)
            tbData.critical = tbStats:GetProperty(PropertyDef.HITSHIPCORECOUNT) + tbStats:GetProperty(PropertyDef.HITHUMANCORECOUNT)
            tbData.attack = GetAttackCount(tbStats)
            tbData.ship_damage = tbStats:GetProperty(PropertyDef.APPLYDAMAGETOSHIP)
            tbData.human_damage = tbStats:GetProperty(PropertyDef.APPLYDAMAGETOHUMAN)
            tbData.ship_cure = tbStats:GetProperty(PropertyDef.APPLYCURETOSHIP)
            tbData.human_cure = tbStats:GetProperty(PropertyDef.APPLYCURETOHUMAN)
            tbData.ship_launch = tbStats:GetProperty(PropertyDef.SHIPLAUNCHCOUNT)
            tbData.ship_hit = tbStats:GetProperty(PropertyDef.SHIPHITCOUNT)
            tbData.human_launch = tbStats:GetProperty(PropertyDef.HUMANLAUNCHCOUNT)
            tbData.human_hit = tbStats:GetProperty(PropertyDef.HUMANHITCOUNT)
            tbData.ship_hit_core = tbStats:GetProperty(PropertyDef.HITSHIPCORECOUNT)
            tbData.human_hit_core = tbStats:GetProperty(PropertyDef.HITHUMANCORECOUNT)
            tbData.kill_npc = tbStats:GetProperty(PropertyDef.HITHUMANCORECOUNT)
            tbData.ship_kill_human = tbStats:GetProperty(PropertyDef.SHIPKILLHUMAN)
            GetWeaponKillCount(tbStats, tbData)
            tbData.ship_suffer = tbStats:GetProperty(PropertyDef.SHIPAPPLIEDDAMAGE)
            tbData.human_suffer = tbStats:GetProperty(PropertyDef.HUMANAPPLIEDDAMAGE)

            tbData.used_drug, tbData.used_wine = GetConsumeItemCount(tbStats)
            GetBuildShipPartCount(tbStats, tbData)
            tbData.ship_killed_ship = tbStats:GetProperty(PropertyDef.SHIPKILLSHIP)
            tbData.human_killed_human = tbStats:GetProperty(PropertyDef.HUMANKILLHUMAN)
            -- tbData.used_battleship = IsRequireShipToOverGame(tbStats, BUILD_SHIP_PART_GRADE, ShipCategory.BattleShip) -- 是否使用三级战列舰完成比赛
            -- tbData.used_frigate = IsRequireShipToOverGame(tbStats, BUILD_SHIP_PART_GRADE, ShipCategory.Frigate) -- 是否使用三级护卫舰完成比赛
            -- tbData.used_gunship = IsRequireShipToOverGame(tbStats, BUILD_SHIP_PART_GRADE, ShipCategory.Gunship) -- 是否使用三级炮艇完成比赛
            tbData.in_poison_circle = tbStats:GetProperty(PropertyDef.POISONCIRCLETIME)
            tbData.first_airdrop = IsFirstPickUpAirDrop(tbStats)
            tbData.boss_point = nExtraScore

            local tbScoreData = GetStatsScore(tbStats, nPlayerRank, nExtraScore, nDungeonId)
            tbData.rank_point = tbScoreData.nGradeScore
            tbData.battle_point = tbScoreData.nBattleScore
            tbData.survival_point = tbScoreData.nSurvivalScore
            tbData.kill_point = tbScoreData.nKillScore
            tbData.assist = tbStats:GetProperty(PropertyDef.ASSISTCOUNT)
            tbData.dimensional_survival = tbScoreData.nDimensionalSurvival
            tbData.dimensional_damage = tbScoreData.nDimensionalDamage
            tbData.dimensional_kill = tbScoreData.nDimensionalKill
            tbData.dimensional_assist = tbScoreData.nDimensionalAssist
            tbData.dimensional_item = tbScoreData.nDimensionalItem

            -- tbData.awards = GetBattleResultAward(tbPlayer,tbData.battle_point,nDungeonId)
            return tbData
        -- else
        --     log("already stats ")
        end
    end
end

function PlayerStatsHelper:CreateLobbyTeamStatisticsData(tbPlayerIdList, nTeamId, nTeamRank, nMVPPlayerId, nPlayerCount, nTeamCount)
    if nTeamRank == nil then
        return
    end
    local nStartTime = BattleDataStatisticsSystem:GetCombatProperty(PropertyDef.DUNGEONBEGINTIME) or 0

    local tbStats = BattleDataStatisticsSystem:GetTeamStats(nTeamId)
    if tbStats then
        if tbStats:GetProperty(PropertyDef.TEAMRANK) <= 0 then
            BattleDataStatisticsSystem:StatisticsTeamResult(nTeamId, nTeamRank)

            local tbData = {}
            tbData.rank = nTeamRank
            tbData.mvp_id = nMVPPlayerId
            tbData.player_count = nPlayerCount
            tbData.battle_time = nStartTime
            tbData.team_count = nTeamCount
            -- 因为lobby结构导致它获取member统计信息困难，所以这么在组队数据中又发一遍队员统计信息
            local tbTeamMembers = {}
            for _, nPlayerId in ipairs(tbPlayerIdList) do
                local tbPlayerStats = BattleDataStatisticsSystem:GetCharacterStats(nPlayerId)
                if tbPlayerStats ~= nil then
                    local tbTeamMember = {}
                    tbTeamMember.player_id = nPlayerId
                    tbTeamMember.rank = tbPlayerStats:GetProperty(PropertyDef.PLAYERRANK)
                    tbTeamMember.kill = tbPlayerStats:GetProperty(PropertyDef.KILL)
                    tbTeamMember.battle_point = tbPlayerStats:GetProperty(PropertyDef.BATTLESCORE)
                    table.insert(tbTeamMembers, tbTeamMember)
                end
            end
            tbData.members = tbTeamMembers

            return tbData
        end
    end
end

local function GetDeathPlaybackKillerData(tbDamageArray)
    local tbHitDown
    local tbLastHit = tbDamageArray[#tbDamageArray]
    for i, v in ipairs(tbDamageArray) do   
        if v.bHitDown then
            tbHitDown = v
        end
    end
    
    if tbHitDown == nil then
        log("[stats] ---death playback: hitdown is nil")
        return tbLastHit
    end
    if tbHitDown == tbLastHit then
        log("[stats] ---death playback: hitdown == lasthit")
        return tbHitDown
    end

    -- 最后一击者和击倒者都是人
    if (tbHitDown.nCauserType == DamageCauserType.PLAYER or tbHitDown.nCauserType == DamageCauserType.BOT) 
        and (tbLastHit.nCauserType == DamageCauserType.PLAYER or tbLastHit.nCauserType == DamageCauserType.BOT) then
        
        -- B和C是队友，并且B和C都是人（玩家、BOT）那么击杀者是C
        if BattleTeamSystem:FindTeamIdByInstanceId(tbHitDown.nCauserInstanceId) 
            == BattleTeamSystem:FindTeamIdByInstanceId(tbLastHit.nCauserInstanceId) then
            log("[stats] ---death playback: hitdown and lasthit is team member")
            return tbLastHit
        else
            -- B和C不是队友，并且B和C都是人，那么击杀者是B
            log("[stats] ---death playback: hitdown and lasthit is player, but not team member")
            return tbHitDown
        end
    elseif (tbHitDown.nCauserType == DamageCauserType.PLAYER or tbHitDown.nCauserType == DamageCauserType.BOT) then 
        -- 若B和C其中有一个是人，另外一个非人（毒圈、npc），那么击杀者就是人
        log("[stats] ---death playback: hitdown is player and lasthit is not player")
        return tbHitDown
    elseif (tbLastHit.nCauserType == DamageCauserType.PLAYER or tbLastHit.nCauserType == DamageCauserType.BOT) then
        log("[stats] ---death playback: hitdown is not player and lasthit is player")
        return tbLastHit
    else
        -- 若B和C都是非人单位，则击杀者是B
        log("[stats] ---death playback: hitdown is not player and lasthit is not player")
        return tbLastHit
    end
end

function PlayerStatsHelper:CreateDeathPlaybackStaticsData(tbPlayer, nCount)
    if tbPlayer == nil then
        logerror("PlayerStatsHelper:CreateDeathPlaybackStaticsData player is nil")
        return
    end

    local nPlayerId = tbPlayer.nPlayerId
    local tbStats = BattleDataStatisticsSystem:GetPlayerStats(nPlayerId)
    if tbStats == nil then
        logerror("PlayerStatsHelper:CreateDeathPlaybackStaticsData stats is nil ", nPlayerId)
        return
    end

    local tbDamageArray = tbStats:GetDamagedStats()
    local tbKillerData = GetDeathPlaybackKillerData(tbDamageArray)
    if tbKillerData == nil then
        logerror("PlayerStatsHelper:CreateDeathPlaybackStaticsData damage is blank ", nPlayerId)
        return
    end 

    log("[stats] ---death playback ", nPlayerId, tbKillerData.nCauserId)
    -- 整理数据，同一伤害来源的合并
    local fnGetWeaponDamage = function(tbDeathPlaybackWeapons, nWeaponTemplateId)
        for i, v in ipairs(tbDeathPlaybackWeapons) do
            if v.nWeaponTemplateId == nWeaponTemplateId then
                return v
            end
        end
    end
    local tbPlayback = {}
    for i = 1, #tbDamageArray do
        local tbRecord = tbDamageArray[i]
        local tbDamageData = tbPlayback[tbRecord.nCauserId]
        if tbDamageData == nil then
            tbDamageData = {}
            tbPlayback[tbRecord.nCauserId] = tbDamageData
            tbDamageData.nCauserType = tbRecord.nCauserType
            tbDamageData.nTemplateType = tbRecord.nTemplateType
            tbDamageData.nTemplateId = tbRecord.nTemplateId
            tbDamageData.nCauserId = tbRecord.nCauserId
            local tbPrepare = BattlePrepareSystem:GetPlayerPrepareInfo(tbRecord.nCauserId) 
            tbDamageData.szName = tbPrepare and tbPrepare.szPlayerName or "" 
            tbDamageData.DeathPlaybackWeapons = {}
            tbDamageData.nDamage = 0
        end
        tbDamageData.nDamage = tbRecord.nDamage + tbDamageData.nDamage
        local tbWeaponData = fnGetWeaponDamage(tbDamageData.DeathPlaybackWeapons, tbRecord.nWeaponTemplateId)
        if tbWeaponData == nil then
            tbWeaponData = {}
            table.insert(tbDamageData.DeathPlaybackWeapons, tbWeaponData)
            tbWeaponData.nWeaponTemplateId = tbRecord.nWeaponTemplateId
            tbWeaponData.nDamage = 0
            tbWeaponData.nAttackCount = 0
            tbWeaponData.nDamageType = tbRecord.nDamageType
        end
        tbWeaponData.nDamage = tbRecord.nDamage + tbWeaponData.nDamage
        tbWeaponData.nAttackCount = tbWeaponData.nAttackCount + 1
    end

    -- 伤害排序
    local tbTemp = {}
    for k, v in pairs(tbPlayback) do
        v.nDamage = math.floor(v.nDamage + 0.5)
        for nIndex, Value in ipairs(v.DeathPlaybackWeapons) do
            Value.nDamage = math.floor(Value.nDamage + 0.5)
        end
        if v.nCauserId ~= tbKillerData.nCauserId then
            table.insert(tbTemp, v)
        end
    end
    local fnSortDamageArray = function(a, b)
        if a.nDamage > b.nDamage then
            return true
        elseif b.nDamage > a.nDamage then
            return false
        elseif a.nCauserType ~= b.nCauserType then
            return a.nCauserType < b.nCauserType
        else
            return a.nCauserId > b.nCauserId
        end
    end
    table.sort(tbTemp, fnSortDamageArray)
    -- 
    local tbRet = {}
    local tbData = tbPlayback[tbKillerData.nCauserId]
    table.insert(tbRet, tbData)

    if #tbRet < nCount then
        for i, v in ipairs(tbTemp) do
            table.insert(tbRet, v)
            if #tbRet >= nCount then
                break
            end
        end
    end

    -- 
    local nTotalDamage = 0
    for i, v in ipairs(tbRet) do
        for key, value in pairs(v.DeathPlaybackWeapons) do
            nTotalDamage = nTotalDamage + value.nDamage
        end
    end
    for i, v in ipairs(tbRet) do
        for key, value in pairs(v.DeathPlaybackWeapons) do
            value.nDamageRate = value.nDamage / nTotalDamage
        end
    end

    return tbRet
end

function PlayerStatsHelper:GetKillCountByPlayerId(nPlayerId)
    local tbStats = BattleDataStatisticsSystem:GetCharacterStats(nPlayerId)
    if tbStats ~= nil then
        local nKillCount = tbStats:GetProperty(PropertyDef.KILL)
        return nKillCount and nKillCount or 0
    end

    -- tbStats = BattleDataStatisticsSystem:GetBotStats(nPlayerId)
    -- if tbStats ~= nil then
    --     local nKillCount = tbStats:GetProperty(PropertyDef.KILL)
    --     return nKillCount and nKillCount or 0
    -- end

    return 0
end

return PlayerStatsHelper
