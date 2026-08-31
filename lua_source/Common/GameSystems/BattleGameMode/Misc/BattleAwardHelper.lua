local BattleResultAwardDataTable = require("BattleResultAwardDataTable")
local proto = require("DungeonLobbyProtoNames")
local BuffDataTable = require("BuffDataTable")

local AWARD_RATE_BASE = 10000 --掉落概率基于10000

local BattleAwardHelper = {}

local function GetRewardAdditionRate(tbCurrentBuffs, nItemId, nPlayerRank)
    if not tbCurrentBuffs then  
        return 1
    end
    local nRate = 1
    for _, v in pairs(tbCurrentBuffs) do   
        local tbData = BuffDataTable:GetTemplate(v)
        if nItemId == tbData.nRewardId then  
            if tbData.nRefRank > 0 then  
                if nPlayerRank < tbData.nRefRank then  
                    nRate = nRate * tbData.nRate
                end
            else   
                nRate = nRate * tbData.nRate
            end
        end
    end
    return math.floor( nRate ) 
end

--新的结算根据BATTLESCORE来发奖，不再依据个人排名
function BattleAwardHelper:GetBattleResultAward(tbPlayer, nBattleScore, nDungeonId, nPlayerRank, tbLobbyRewardsData)
    log("GetBattleResultAward Param:nDungeonId:",nDungeonId,",nBattleScore:",nBattleScore)
    local tbRet = BattleResultAwardDataTable:GetTemplate(nDungeonId,nBattleScore)
    local tbAwardLimited = tbPlayer.tbPrepareInfo.tbAwardLimited
    local tbItemIdToCountMap = {}
    for _,tbCurLimit in pairs(tbAwardLimited) do
        tbItemIdToCountMap[tbCurLimit.template_id] = tbCurLimit.count
    end

    if tbRet then
        local tbReturnAwards = {}
        --先随机普通奖励
        local tbNormalAwards = tbRet.tbNormalAwards
        local nNormalCount = #tbNormalAwards

        local nAdditionRate = 1
        for i = 1,nNormalCount do
            local nDropRate = tbNormalAwards[i].nDropRate
            local nRandomNum = math.random(1,AWARD_RATE_BASE) --基于10000
            if tbNormalAwards[i].nItemCount > 0 and nRandomNum <= nDropRate then
                local curAward = {}
                curAward.templateId = tbNormalAwards[i].nItemId
                nAdditionRate = GetRewardAdditionRate(tbPlayer.tbPrepareInfo.tbItemBuffs, curAward.templateId, nPlayerRank)
                curAward.count      = tbNormalAwards[i].nItemCount * nAdditionRate
                -- log("===lz  Regular reward:", curAward.templateId, tbNormalAwards[i].nItemCount, nAdditionRate)
                curAward.award_type = proto.AccountAwardType.REGULAR
                table.insert(tbReturnAwards,curAward)
            end
        end

        --将原力之尘的奖励放到 regular reward里
        if tbLobbyRewardsData.nItemId ~= nil then  
            table.insert(tbReturnAwards, {award_type = proto.AccountAwardType.REGULAR,
                templateId = tbLobbyRewardsData.nItemId, count = tbLobbyRewardsData.nItemCount
            })
        end

        --再随机特殊奖励
        local tbSpecialAwards = tbRet.tbSpecialAwards
        local nSpecialCount = #tbSpecialAwards
        for i = 1,nSpecialCount do
            local nDropRate = tbSpecialAwards[i].nDropRate
            local nRandomNum = math.random(1,AWARD_RATE_BASE) --基于10000
            if tbSpecialAwards[i].nItemCount > 0 and nRandomNum <= nDropRate then
                local curAward = {}
                curAward.templateId = tbSpecialAwards[i].nItemId
                nAdditionRate = GetRewardAdditionRate(tbPlayer.tbPrepareInfo.tbItemBuffs, curAward.templateId, nPlayerRank)
                curAward.count      = tbSpecialAwards[i].nItemCount * nAdditionRate
                -- log("===lz  Special reward:", curAward.templateId, tbSpecialAwards[i].nItemCount, nAdditionRate)
                curAward.award_type = proto.AccountAwardType.SPECIAL
                table.insert(tbReturnAwards,curAward)
            end
        end

        local nRetCount = #tbReturnAwards
        for i = 1,nRetCount do
            local tbCurAward = tbReturnAwards[i]
            if tbItemIdToCountMap[tbCurAward.templateId] ~= nil then
                tbCurAward.count = math.min(tbCurAward.count,tbItemIdToCountMap[tbCurAward.templateId])
            end
        end

        if nRetCount > 0 then
            return tbReturnAwards
        end
    end

    return nil
end

--把特殊奖励剔除然后转成proto.BattleResultAward数组并返回
function BattleAwardHelper:FillClientAwards(tbAwards)
    local tbRet = {}

    local nAwardCount = #tbAwards
    for i = 1,nAwardCount do
        if tbAwards[i].award_type == proto.AccountAwardType.REGULAR then
            local curAward = {}
            curAward.nItemId = tbAwards[i].templateId
            curAward.nItemCount = tbAwards[i].count
            table.insert(tbRet,curAward)
        end
    end

    return tbRet
end

return BattleAwardHelper