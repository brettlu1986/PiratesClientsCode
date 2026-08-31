local Proto = {}

function Proto.GenerateIds()
    local GetHash = function(szValue)
        local nValue = 0
        local nLength = #szValue
        for i = 1, nLength do
            nValue = 31 * nValue + string.byte(szValue, i)
        end
        return nValue
    end

    local tbSortedString = {}
    for _, v in pairs(Proto) do
        if(type(v) == "string") then
            table.insert(tbSortedString, {v, GetHash(v)})
        end
    end
    table.sort(tbSortedString, function(v1, v2) return v1[2] < v2[2] end)

    local tbIds = {}
    local nProtoId = 10001
    for _, v in ipairs(tbSortedString) do
        tbIds[nProtoId] = v[1]
        nProtoId = nProtoId + 1
    end
    return tbIds
end

---------------------------------------------
-- export from src\d2c_rep.proto begin

-- For communication between client and dungeon through RPC.
-- r打头的作为同步用的属性





--//////////////////////////////////////////////////////////////////////////////////
-- 一些基础信息
Proto.rGameStateBaseInfo = "rGameStateBaseInfo"

-- 因为分数需要持续同步，所以这里吧分数从队伍信息中抽出来了
Proto.SingleTeamScore = "SingleTeamScore"

-- 所有队伍的分数信息
Proto.rTeamScores = "rTeamScores"

-- 战斗指引信息
Proto.rCurrentObjective = "rCurrentObjective"

-- 玩家战斗通用统计信息
Proto.PlayerCommonStatisticsData = "PlayerCommonStatisticsData"

-- 当前的战斗数据统计
Proto.rCurrentStatisticsDatas = "rCurrentStatisticsDatas"

-- 剩余时间，客户端会进行模拟，同步间隔与上面的分数不一样，原则上时间的同步要远低于分数的同步
Proto.rStepRemainTime = "rStepRemainTime"

-- 当前是哪个step
Proto.rCurrentStepInfo = "rCurrentStepInfo"
Proto.rCurrentStepInfo_State = {
        STARTED     = 0,    -- 开始
        IN_PROGRESS = 1,    -- 进行中
        COMPLETED   = 2,    -- 完成
}

-- 这里比较尴尬，加这个纯粹是为了解决客户端创建船太卡
-- 客户端所需的资源
Proto.rNeededResources = "rNeededResources"

-- 机器人信息
Proto.rBotInfo = "rBotInfo"

--//////////////////////////////////////////////////////////////////////////////////
-- 下面是Common Step用的replicated信息

-- BattleTimerStep
Proto.rBattleTimerStepInfo = "rBattleTimerStepInfo"

-- 胜利失败结果
Proto.PlayerWinLoseResult = "PlayerWinLoseResult"
Proto.PlayerWinLoseResult_ResultType = {
        WIN     = 0,
        LOSE    = 1,
        DRAW    = 2,
}
Proto.PlayerWinLoseResult_BalanceType = {
        Escape = 0, --逃跑结算
        Escort = 1, --护送结算
        Kill   = 2, --击杀结算
}

-- BattlePlayerResultStep
Proto.rBattlePlayerResultStep = "rBattlePlayerResultStep"

--//////////////////////////////////////////////////////////////////////////////////
-- 专用Step

-- PVPOccupyStep 开始信息
Proto.rPVPOccupyStepInfo = "rPVPOccupyStepInfo"

-- 占圈信息
Proto.PVPOccupyAreaInfo = "PVPOccupyAreaInfo"
Proto.PVPOccupyAreaInfo_OccupyState = {
        NONE = 0,           -- 未占领
        OCCUPIED    = 1,    -- 已占领
        OCCUPING    = 2,    -- 占领中
        STALEMATE   = 3,    -- 僵持
}
Proto.PVPOccupyAreaInfo_AreaIndex = {
        AREA_INVALID = 0,
        AREA1 = 1, -- 外环
        AREA2 = 2, -- 中环
        AREA3 = 3, -- 中心
}

-- 圈的占领情况，哪个圈变了就同步哪个圈，所以有可能只同步某一个圈，当某一个玩家进来则同步所有圈的状态
Proto.rPVPOccupyChangedAreaState = "rPVPOccupyChangedAreaState"

-- --------- society guard ----------->
-- 协会-皇家护卫 倒计时提示信息
Proto.rSocietyGuardCountdownTipInfo = "rSocietyGuardCountdownTipInfo"
-- <

--///////////////////////////////////////////////////////////////////////////////////////
-- Escort 押运
Proto.rEscortFightResult = "rEscortFightResult"
Proto.rEscortFightResult_FightResult = {
        WIN = 0,
        LOSE = 1,
}

--///////////////////////////////////////////////////////////////////////////////////////
-- JsonGameMode
Proto.rJsonSetting = "rJsonSetting"

Proto.rJsonMainStepInfo = "rJsonMainStepInfo"

--设置或者显示追踪目标
Proto.rTargetTrackInfoAndIsShow = "rTargetTrackInfoAndIsShow"

-- 设置特殊Toast
Proto.rBattleSpecialToast = "rBattleSpecialToast"

--修改npc是否可以交互
Proto.rBattleNpcInteraction = "rBattleNpcInteraction"

--设置复活界面信息及显示
Proto.rReviveInfoAndShow = "rReviveInfoAndShow"
Proto.rReviveInfoAndShow_EReviveType = {
        BACKCITY_NOWREVIVE = 0,--有回城和立即复活
        RESET = 1, --重置
        WAIT_NOW = 2,  --PVE死亡复活逻辑,立即复活和等待全队死亡复活
}

--///////////////////////////////////////////////////////////////////////////////////////
-- BattleProperty

-- 夺旗战场旗子状态
Proto.rBattleFlagState = "rBattleFlagState"

-- 船身上的着火点和进水点数据
Proto.rSustainedDamageSpots = "rSustainedDamageSpots"

-- 船是否死亡
Proto.rShipIsDead = "rShipIsDead"

--//////////////////////////////////////////////////////////

-- 毒圈同步信息
Proto.rFFAPoisonCircleInfo = "rFFAPoisonCircleInfo"
Proto.rFFAPoisonCircleInfo_EStageState = {
        NONE = 0,
        WAIT = 1,
        SHRINK = 2,
        FINISH = 3,
}

-- 吃鸡副本流程状态更改
Proto.rFFAProcessState = "rFFAProcessState"
Proto.rFFAProcessState_EState = {
        COUNTDOWN           = 0,
        SELECTION           = 1,
        SELECTION_LOCK      = 2,
        MATINEE             = 3,
        PARACHUTING         = 4,
        END                 = 5,
}

Proto.FFATransportInfo = "FFATransportInfo"

Proto.rFFANewTransportInfos = "rFFANewTransportInfos"

--训练营Begin
Proto.rTrainingCampPlayerInfos = "rTrainingCampPlayerInfos"
--训练营End
-- export from src\d2c_rep.proto end
---------------------------------------------

return Proto