local BattleResultAwardDataTable = {}

local StringUtil = require("StringUtil")

BattleResultAwardDataTable.szFileName = "common/ffa/statistics/battle_result_award.tab"

function BattleResultAwardDataTable:OnEditorDefine(Parser)
    Parser:Define("nDungeonId", "dungeon_id", -1, Parser.TypeInt)
    Parser:Define("nScores", "scores", -1, Parser.TypeInt)
    Parser:Define("szNormalAwardItemId",         "normal_award_item_id", "",         Parser.TypeString)
    Parser:Define("szNormalAwardItemCount",      "normal_award_item_count", "",      Parser.TypeString)
    Parser:Define("szNormalAwardItemDropRate",   "normal_award_item_drop_rate", "",  Parser.TypeString)
    Parser:Define("szSpecialAwardItemId",        "special_award_item_id", "",        Parser.TypeString)
    Parser:Define("szSpecialAwardItemCount",     "special_award_item_count", "",     Parser.TypeString)
    Parser:Define("szSpecialAwardItemDropRate",  "special_award_item_drop_rate", "", Parser.TypeString)
end

function BattleResultAwardDataTable:OnEditorParseLine(Parser, tbContainer, tbNewTemplate)
    local nDungeonId = tbNewTemplate.nDungeonId
    local nScores = tbNewTemplate.nScores

    local szNormalAwardItemId = tbNewTemplate.szNormalAwardItemId
    local tbNormalAwardIds = StringUtil.Split(szNormalAwardItemId,",")
    local nNormalAwardCount = #tbNormalAwardIds

    local szNormalAwardItemCount = tbNewTemplate.szNormalAwardItemCount
    local tbNormalAwardCounts = StringUtil.Split(szNormalAwardItemCount,",")
 
    if nNormalAwardCount ~= #tbNormalAwardCounts then
        return false
    end

    local szNormalAwardItemDropRate = tbNewTemplate.szNormalAwardItemDropRate
    local tbNormalAwardRates = StringUtil.Split(szNormalAwardItemDropRate,",")

    if nNormalAwardCount ~= #tbNormalAwardRates then
        return false
    end

    local szSpecialAwardItemId = tbNewTemplate.szSpecialAwardItemId
    local tbSpecialAwardIds = StringUtil.Split(szSpecialAwardItemId,",")
    local nSpecialAwardCount = #tbSpecialAwardIds

    local szSpecialAwardItemCount = tbNewTemplate.szSpecialAwardItemCount
    local tbSpecialAwardCounts = StringUtil.Split(szSpecialAwardItemCount,",")
 
    if nSpecialAwardCount ~= #tbSpecialAwardCounts then
        return false
    end

    local szSpecialAwardItemDropRate = tbNewTemplate.szSpecialAwardItemDropRate
    local tbSpecialAwardRates = StringUtil.Split(szSpecialAwardItemDropRate,",")

    if nSpecialAwardCount ~= #tbSpecialAwardRates then
        return false
    end

    tbContainer[nDungeonId] = tbContainer[nDungeonId] or {}
    local tbScores = tbContainer[nDungeonId]
    local tbCurScore = {}
    table.insert(tbScores,tbCurScore)

    local tbNormalAwards = {}
    local tbSpecialAwards = {}
    tbCurScore.nScores = nScores
    tbCurScore.tbNormalAwards = tbNormalAwards
    tbCurScore.tbSpecialAwards= tbSpecialAwards

    --log("Scores:",nScores,",DungeonId:",nDungeonId)
    for i=1,nNormalAwardCount do 
        local curNormalAward = {}
        curNormalAward.nItemId = tonumber(tbNormalAwardIds[i])
        curNormalAward.nItemCount = tonumber(tbNormalAwardCounts[i])
        curNormalAward.nDropRate  = tonumber(tbNormalAwardRates[i])
        table.insert(tbNormalAwards,curNormalAward)
        --log("NormalAward ItemId:",curNormalAward.nItemId,",ItemCount:",curNormalAward.nItemCount,",ItemRate:",curNormalAward.nDropRate)
    end

    for i=1,nSpecialAwardCount do 
        local curSpecialAward = {}
        curSpecialAward.nItemId = tonumber(tbSpecialAwardIds[i])
        curSpecialAward.nItemCount = tonumber(tbSpecialAwardCounts[i])
        curSpecialAward.nDropRate  = tonumber(tbSpecialAwardRates[i])
        table.insert(tbSpecialAwards,curSpecialAward)
        --log("SpecialAward ItemId:",curSpecialAward.nItemId,",ItemCount:",curSpecialAward.nItemCount,",ItemRate:",curSpecialAward.nDropRate)
    end

    return true
end

-- [EXPORT BEGIN]
function BattleResultAwardDataTable:GetTemplate(nDungeonId, nCurScores)
    if self.tbContainer[nDungeonId] == nil then
        return nil
    end

    local tbScores = self.tbContainer[nDungeonId]
    local nCount = #tbScores

    local ret = nil
    for i = nCount,1,-1 do
        if nCurScores >= tbScores[i].nScores then
            ret = tbScores[i]
            break
        end
    end

    return ret
end

-- [EXPORT END]

return BattleResultAwardDataTable