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
    local nProtoId = 1
    for _, v in ipairs(tbSortedString) do
        tbIds[nProtoId] = v[1]
        nProtoId = nProtoId + 1
    end
    return tbIds
end

---------------------------------------------
-- export from src\dungeon_common.proto begin

-- For communication between client and dungeon through RPC.





Proto.ShipInfo = "ShipInfo"

Proto.L10N = "L10N"

Proto.c2d_RequestAddBuff = "c2d_RequestAddBuff"

Proto.c2d_RequestCastSkill = "c2d_RequestCastSkill"

Proto.d2c_CastSkillFailedResponse = "d2c_CastSkillFailedResponse"

Proto.d2c_CastSkillSuccessedResponse = "d2c_CastSkillSuccessedResponse"

Proto.d2c_SkillChargeCountChanged = "d2c_SkillChargeCountChanged"

Proto.d2c_ResetSkillCD = "d2c_ResetSkillCD"

Proto.d2c_AddStatusBuff = "d2c_AddStatusBuff"

Proto.d2c_RemoveStatusBuff = "d2c_RemoveStatusBuff"

Proto.FightResultType = {
    WIN     = 0,
    LOSE    = 1,
    DRAW    = 2,
}

Proto.Award = "Award"

Proto.d2c_ShowAward = "d2c_ShowAward"

Proto.d2c_ShowArenaAward = "d2c_ShowArenaAward"

Proto.d2c_ShowBattlegroundAward = "d2c_ShowBattlegroundAward"

-- message d2c_ShowActivityDungeonAward {
--     FightResultType result_type = 1;
--     repeated Award awards = 2;
-- }

Proto.d2c_ShowAssociationDungeonAward = "d2c_ShowAssociationDungeonAward"

Proto.d2c_ShowGuildbossAward = "d2c_ShowGuildbossAward"

Proto.d2c_ShowWorldbossAward = "d2c_ShowWorldbossAward"

Proto.c2d_QuitDungeon = "c2d_QuitDungeon"
Proto.c2d_QuitDungeon_QuitReason = {
        QUIT_BUTTON = 0, -- 游戏中点击退出副本按钮
        BACK_TO_PORT = 1, -- 死亡后不花钱原地复活，而选择退出副本回城选项
}

Proto.c2d_LeaveDungeon = "c2d_LeaveDungeon"

--///////////////////////////////////////////////////////////////////////////////////////////
-- Actor init data
-- 船只外观表现
-- 字段均为各部位所对应的换装res_id，0表示无换装
Proto.ShipRes = "ShipRes"



Proto.ShipSkill = "ShipSkill"

Proto.SkillInfo = "SkillInfo"

Proto.ShipPropertyEffect = "ShipPropertyEffect"

Proto.CannonBall = "CannonBall"

Proto.PlayerActorInitData = "PlayerActorInitData"

Proto.PlayerControllerInitData = "PlayerControllerInitData"

Proto.NpcActorInitData = "NpcActorInitData"

Proto.SceneItemInfo = "SceneItemInfo"

Proto.TriggerActorCustomData = "TriggerActorCustomData"

Proto.TriggerActorInitData = "TriggerActorInitData"
Proto.TriggerActorInitData_ECollisionType = {
        ONLY_SERVER = 0,
        ONLY_CLIENT = 1,
        ALL = 2,
        ALL_NO = 3,
}

Proto.DummyActorInitData = "DummyActorInitData"

Proto.DestructibleActorInitData = "DestructibleActorInitData"

Proto.d2c_PlayMatinee = "d2c_PlayMatinee"

Proto.d2c_StopMatinee = "d2c_StopMatinee"

Proto.d2c_ShowDialog = "d2c_ShowDialog"

--停船
Proto.d2c_StopMove = "d2c_StopMove"

--切换为 Common 模式
Proto.d2c_SwitchCommonHandlerMode = "d2c_SwitchCommonHandlerMode"

--
Proto.d2c_ResetCameraControl = "d2c_ResetCameraControl"

Proto.d2c_SetCameraYaw = "d2c_SetCameraYaw"

-- 发送玩家个人统计信息
Proto.d2c_PlayerStatisticsData = "d2c_PlayerStatisticsData"

Proto.PlayerBattleStatisticsDamageRecord = "PlayerBattleStatisticsDamageRecord"

Proto.ShipBattleSummaryData = "ShipBattleSummaryData"

Proto.ShipDetailedStatistics = "ShipDetailedStatistics"


Proto.d2c_PlayerBattleFinishStatisticsData = "d2c_PlayerBattleFinishStatisticsData"

Proto.d2c_PlayerRealTimeStatisticsData = "d2c_PlayerRealTimeStatisticsData"


--隐藏剧情对话框
Proto.c2d_CloseDialog = "c2d_CloseDialog"


Proto.d2c_OpenDialogBoard = "d2c_OpenDialogBoard"

-- Toast
Proto.d2c_BattleToast = "d2c_BattleToast"

-- 击杀toast
Proto.d2c_BattleKillToast = "d2c_BattleKillToast"
Proto.d2c_BattleKillToast_EType = {
        INJURY = 0,
        KILL   = 1,
}

-- 自动战斗
Proto.c2d_AutoBattle = "c2d_AutoBattle"

Proto.d2c_AutoBattle = "d2c_AutoBattle"

Proto.d2c_CampTypeChanged = "d2c_CampTypeChanged"

--副本中与npc开始交互
Proto.c2d_BattleStartInteractionNpc = "c2d_BattleStartInteractionNpc"

--进入npc交互范围
Proto.c2d_BattleTriggerInteractionNpc = "c2d_BattleTriggerInteractionNpc"

--开始采集
Proto.d2c_StartCollection = "d2c_StartCollection"

--采集中断
Proto.c2d_CollectionBreak = "c2d_CollectionBreak"

Proto.d2c_CollectionBreak = "d2c_CollectionBreak"

--进入人船变化volume
Proto.c2d_StartChangeDisplay = "c2d_StartChangeDisplay"

Proto.c2d_BreakChangeDisplay = "c2d_BreakChangeDisplay"

Proto.d2c_BreakChangeDisplay = "d2c_BreakChangeDisplay"


--交互完成
Proto.d2c_InteractionEnd = "d2c_InteractionEnd"


-- 重试
Proto.c2d_RetryGame = "c2d_RetryGame"


-- 请求战斗统计数据
Proto.c2d_RequestStatisticsData = "c2d_RequestStatisticsData"


--选择复活方式
Proto.c2d_ReviveMode = "c2d_ReviveMode"

-- 复活倒计时
Proto.d2c_ReviveCountdown = "d2c_ReviveCountdown"

-- 倒计时
Proto.d2c_Countdown = "d2c_Countdown"

-- 占圈显示控制
Proto.d2c_ShowOccupy = "d2c_ShowOccupy"

-- Buff数据结构
Proto.Buff = "Buff"

Proto.d2c_CharacterBuffChanged = "d2c_CharacterBuffChanged"
Proto.d2c_CharacterBuffChanged_EBuffChangedType = {
        ADD = 0, -- 新增
        UPDATE = 1, -- 刷新
        REMOVE = 2, -- 移除
}

Proto.ETacticsCommandType = {
    ATTACK  = 0, -- 攻击
    GATHER  = 1, -- 集合
    SOS     = 2, -- 求助
}

Proto.c2d_SendTacticsCommand = "c2d_SendTacticsCommand"

Proto.d2c_MulticastTacticsCommand = "d2c_MulticastTacticsCommand"

-- 隐藏战斗UI
Proto.d2c_HideBattleUI = "d2c_HideBattleUI"

-- 是否是机器人
Proto.c2d_IsBot = "c2d_IsBot"

Proto.d2c_IsBot = "d2c_IsBot"

--////////////////////////////////////////////////////////////////
-- FFA
Proto.c2d_JumpFromTransporter = "c2d_JumpFromTransporter"


Proto.d2c_JumpFromTransporter = "d2c_JumpFromTransporter"


-- 开伞
Proto.c2d_ParachuteOpen = "c2d_ParachuteOpen"

Proto.d2c_ParachuteOpen = "d2c_ParachuteOpen"

-- 跳伞着陆或着海
Proto.d2c_ParachutionEnd = "d2c_ParachutionEnd"

-- 吃鸡结算
Proto.d2c_FFAPlayerResult = "d2c_FFAPlayerResult"

Proto.BattleResultAward = "BattleResultAward"

Proto.FFAPlayerResult = "FFAPlayerResult"



-- 吃鸡队伍结算
Proto.d2c_FFATeamResult = "d2c_FFATeamResult"

Proto.c2d_FFADeathPlayback = "c2d_FFADeathPlayback"


Proto.FFADeathPlaybackWeapon = "FFADeathPlaybackWeapon"

Proto.FFADeathPlayback = "FFADeathPlayback"

Proto.d2c_FFADeathPlayback = "d2c_FFADeathPlayback"

-- 击杀Boss额外胜利结算，为了不影响原来的流程，新增一个协议
Proto.d2c_FFAKillBossResult = "d2c_FFAKillBossResult"

Proto.d2c_FFAShowCoreArea = "d2c_FFAShowCoreArea"

-- 击杀
Proto.d2c_FFAKillInfo = "d2c_FFAKillInfo"

-- 玩家选点
Proto.c2d_FFASelectionPoint = "c2d_FFASelectionPoint"

Proto.d2c_FFASelectionPoint = "d2c_FFASelectionPoint"

Proto.c2d_FFACancelSelectionPoint = "c2d_FFACancelSelectionPoint"

Proto.d2c_FFACancelSelectionPoint = "d2c_FFACancelSelectionPoint"

Proto.d2c_FFATransporterPlayerCount = "d2c_FFATransporterPlayerCount"

-- 小地图标记操作类型
Proto.ESignType = {
    SNONE           = 0,
    SIGN            = 1,
    DELETE          = 2,
}

-- 小地图标记
Proto.c2d_FFAMapSign = "c2d_FFAMapSign"

-- 队员逃跑提示
Proto.d2c_FFATeammateLeave = "d2c_FFATeammateLeave"

-- 人船共用object，当pawn删除时并不知道object是否应该被删，所以额外加了个这个来告诉客户端object是否被真删了
-- PS：等过会版本完成后要重新整理一遍object的创建销毁流程，现阶段先凑合
Proto.d2c_DestroyGameObject = "d2c_DestroyGameObject"

--////////////////////////////////////////////////////////////////
-- Human weapon usage
Proto.c2d_HumanStartAttack = "c2d_HumanStartAttack"

Proto.c2d_HumanFinishAttack = "c2d_HumanFinishAttack"

Proto.c2d_HumanCancelAttack = "c2d_HumanCancelAttack"

Proto.c2d_HumanReload = "c2d_HumanReload"

Proto.c2d_HumanAim = "c2d_HumanAim"

Proto.c2d_HumanSetCurrentWeapon = "c2d_HumanSetCurrentWeapon"

-- 人物移动状态改变
Proto.c2d_ChangeMovementState = "c2d_ChangeMovementState"

Proto.c2d_ChangeContinuousRun = "c2d_ChangeContinuousRun"

Proto.c2d_ChangeHumanWeaponFireType = "c2d_ChangeHumanWeaponFireType"

Proto.c2d_HoldThrownItem = "c2d_HoldThrownItem"

Proto.c2d_UnholdThrownItem = "c2d_UnholdThrownItem"

Proto.c2d_ChangeHumanThrowType = "c2d_ChangeHumanThrowType"

Proto.d2c_ChangeHumanWeaponFireType = "d2c_ChangeHumanWeaponFireType"

Proto.c2d_CancelThrowExplosive = "c2d_CancelThrowExplosive"

Proto.rShipAvatarResData = "rShipAvatarResData"

Proto.rShipWeaponResData = "rShipWeaponResData"

Proto.rShipPartBrokenStatus = "rShipPartBrokenStatus"

Proto.c2d_ShipAvatarResUpdate = "c2d_ShipAvatarResUpdate"

Proto.c2d_ChangeShipPosture = "c2d_ChangeShipPosture"

-- 角色身上携带的Buff数组
Proto.rCharacterAllBuff = "rCharacterAllBuff"

-- 角色的可救援状态信息
Proto.rRescuingInfo = "rRescuingInfo"

-- 同步舰船武器装填状态
Proto.rShipWeaponBulletLoadingInfo = "rShipWeaponBulletLoadingInfo"

Proto.ProgressBar = "ProgressBar"

-- 开始读条
Proto.c2d_StartProgressBar = "c2d_StartProgressBar"

-- 取消读条
Proto.c2d_AbortProgressBar = "c2d_AbortProgressBar"


Proto.rHumanAvatarResData = "rHumanAvatarResData"

Proto.rHumanAvatarData = "rHumanAvatarData"


Proto.HumanWeaponAvatarData = "HumanWeaponAvatarData"

Proto.HumanPrimaryHandGunAvatarData = "HumanPrimaryHandGunAvatarData"

Proto.HumanSecondHandGunAvatarData = "HumanSecondHandGunAvatarData"

Proto.HumanPrimaryLongGunAvatarData = "HumanPrimaryLongGunAvatarData"

Proto.HumanSecondLongGunAvatarData = "HumanSecondLongGunAvatarData"

Proto.d2c_FFAShowDialog = "d2c_FFAShowDialog"

-- 伤害通知
Proto.d2c_NotifyOnHitPlayer = "d2c_NotifyOnHitPlayer"

-- 请求救援队友
Proto.c2d_RequestRescueTeammate = "c2d_RequestRescueTeammate"

-- 通知Progressbar start失败
Proto.d2c_NotifyProgressBarStartFailed = "d2c_NotifyProgressBarStartFailed"

-- 攀爬
Proto.c2d_RootMotionJump = "c2d_RootMotionJump"

Proto.rHumanRootMotionJump = "rHumanRootMotionJump"

-- 新攀爬
Proto.c2d_RootMotionJumpNew = "c2d_RootMotionJumpNew"

Proto.rHumanRootMotionJumpNew = "rHumanRootMotionJumpNew"

-- 队伍中玩家同步信息
Proto.TeamInfo = "TeamInfo"
Proto.TeamInfo_EState = {
        NONE               = 0,
        OFFLINE            = 1,
        DYING              = 2,
        DEAD               = 3,
        DRIVING            = 4,
        PARACHUTING        = 5,
        ADDITIONALSUCCESS  = 6,
        INPLANE            = 7,
}

-- 队伍中队友的基础信息,都为不可变信息
Proto.TeammateBaseInfo = "TeammateBaseInfo"

Proto.rBattleTeamBaseInfo = "rBattleTeamBaseInfo"

Proto.rBattleWatchTeamBaseInfo = "rBattleWatchTeamBaseInfo"

-- 队伍中队友的血量信息
Proto.TeammateHealthInfo = "TeammateHealthInfo"
Proto.rBattleTeamHealthInfo = "rBattleTeamHealthInfo"
Proto.rBattleWatchTeamHealthInfo = "rBattleWatchTeamHealthInfo"

-- 队伍中队友的状态信息
Proto.TeammateStateInfo = "TeammateStateInfo"
Proto.TeammateStateInfo_EState = {
                NONE               = 0,
                OFFLINE            = 1,
                DYING              = 2,
                DEAD               = 3,
                DRIVING            = 4,
                PARACHUTING        = 5,
                ADDITIONALSUCCESS  = 6,
                INPLANE            = 7,
}

Proto.rBattleTeamStateInfo = "rBattleTeamStateInfo"
Proto.rBattleWatchTeamStateInfo = "rBattleWatchTeamStateInfo"

-- 队伍中队友的位置信息
Proto.TeammatePosInfo = "TeammatePosInfo"
Proto.rBattleTeamPosInfo = "rBattleTeamPosInfo"
Proto.rBattleWatchTeamPosInfo = "rBattleWatchTeamPosInfo"


-- 队伍中队友的选点信息
Proto.TeammateSignInfo = "TeammateSignInfo"
Proto.rBattleTeamSignInfo = "rBattleTeamSignInfo"
Proto.rBattleWatchTeamSignInfo = "rBattleWatchTeamSignInfo"

-- 队伍的人物信息,此协议为了替换掉原来旧的rTeamInfos协议
Proto.rTeamPlayersInfo = "rTeamPlayersInfo"
Proto.rWatchTeamPlayersInfo = "rWatchTeamPlayersInfo"

Proto.d2c_SyncHumanExtraPackageCapacityValue = "d2c_SyncHumanExtraPackageCapacityValue"

Proto.d2c_SyncShipExtraPackageCapacityValue = "d2c_SyncShipExtraPackageCapacityValue"

Proto.d2c_SyncShipExtraMaterialCapacityRatio = "d2c_SyncShipExtraMaterialCapacityRatio"

Proto.d2c_SyncAirDropVisibility = "d2c_SyncAirDropVisibility"

--副本内聊天
Proto.c2d_Chat = "c2d_Chat"

Proto.d2c_Chat = "d2c_Chat"

Proto.c2d_ChatRoomMemberId = "c2d_ChatRoomMemberId"

Proto.d2c_ChatRoomMemberId = "d2c_ChatRoomMemberId"

Proto.c2d_PointLocation = "c2d_PointLocation"
Proto.c2d_PointLocation_PointType = {
        DROPITEM = 0, --指示的是掉落物
        LOCATION = 1, --指示的是坐标
}

Proto.d2c_PointLocation = "d2c_PointLocation"
Proto.d2c_PointLocation_PointType = {
        DROPITEM = 0, --指示的是掉落物
        LOCATION = 1, --指示的是坐标
}

Proto.d2c_NotifyNpcReset = "d2c_NotifyNpcReset"


Proto.c2d_EnterFreeView = "c2d_EnterFreeView"

Proto.c2d_TestNet = "c2d_TestNet"

Proto.d2c_TestNet = "d2c_TestNet"

-- 通知请求上马失败
Proto.d2c_RequestVehicleFailed = "d2c_RequestVehicleFailed"

Proto.c2d_RequestVehicleState = "c2d_RequestVehicleState"

Proto.rHumanVehicleState = "rHumanVehicleState"

Proto.rHumanVehicleStateNew = "rHumanVehicleStateNew"

-- 用于在地图上显示机器人的位置和状态（debug）
Proto.BotInfo = "BotInfo"

Proto.d2c_SyncBotInfos = "d2c_SyncBotInfos"

Proto.d2c_SearchPropDataForGM = "d2c_SearchPropDataForGM"

Proto.c2d_SearchPropDataForGM = "c2d_SearchPropDataForGM"

-- 处理任务相关
Proto.d2c_ProcessQuest = "d2c_ProcessQuest"
Proto.d2c_ProcessQuest_EPQuestType = {
        ADD_QUEST = 0, --新增任务
        UPDATE_QUEST = 1, --更新任务进度信息
        COMPLETE_QUEST = 2, --完成任务
}


--额外胜利逃出选择
Proto.d2c_AdditionalSuccessChoice = "d2c_AdditionalSuccessChoice"

Proto.c2d_AdditionalSuccessChoice = "c2d_AdditionalSuccessChoice"
Proto.c2d_AdditionalSuccessChoice_EASResultType = {
        EXIST_BATTLE = 0, --逃出升天
        FIGHTING     = 1, --继续战斗
}

Proto.d2c_AdditionalSuccessResult = "d2c_AdditionalSuccessResult"
Proto.d2c_AdditionalSuccessResult_EASResultType = {
        EXIST_BATTLE = 0, --逃出升天
        FIGHTING     = 1, --继续战斗
}

--额外胜利任务被选出
Proto.d2c_AdditionalSuccessQuestInfo = "d2c_AdditionalSuccessQuestInfo"

Proto.d2c_ShowCommonToast = "d2c_ShowCommonToast"

Proto.d2c_DungeonAndPlayerState = "d2c_DungeonAndPlayerState"

--如果重连前已经结算了，需要进副本后显示结算界面
Proto.d2c_ReLoginRefreshBattleResultWnd = "d2c_ReLoginRefreshBattleResultWnd"

--断线重连后，发送最近使用过的载具信息
Proto.d2c_ReLoginRecentUsedVehicle = "d2c_ReLoginRecentUsedVehicle"

Proto.c2d_TeleportToSafeLocation = "c2d_TeleportToSafeLocation"

Proto.c2d_HideOtherSelectionPoint = "c2d_HideOtherSelectionPoint"

Proto.c2d_SwitchDoor = "c2d_SwitchDoor"

Proto.d2c_BattleGameOver = "d2c_BattleGameOver"

Proto.d2c_MulticastServerLog = "d2c_MulticastServerLog"

Proto.c2d_RequestCheckCheater = "c2d_RequestCheckCheater"

Proto.d2c_SyncSelfWeaponAvatar = "d2c_SyncSelfWeaponAvatar"

Proto.c2d_RequestNearbyDiamond = "c2d_RequestNearbyDiamond"

Proto.d2c_NearbyDiamond = "d2c_NearbyDiamond"

--rFFAProcessState 中的State
Proto.d2c_FFAProcessStateChanged = "d2c_FFAProcessStateChanged"

-- export from src\dungeon_common.proto end
---------------------------------------------



---------------------------------------------
-- export from src\dungeon_common\battle_humanweapon.proto begin




Proto.HumanBodyType = {
    NONE        = 0,
    HEAD        = 1,
    BODY        = 2,
    ALLFOURS    = 3,
}

Proto.GunVector3D = "GunVector3D"

Proto.c2d_HumanWeaponReload = "c2d_HumanWeaponReload"

Proto.c2d_HumanWeaponCancelReload = "c2d_HumanWeaponCancelReload"

Proto.c2d_HumanWeaponSetAim = "c2d_HumanWeaponSetAim"

-- 因为老消息有叫HumanSetCurrentWeapon，所以这里改了个名
Proto.c2d_HumanWeaponSetCurrent = "c2d_HumanWeaponSetCurrent"

Proto.c2d_HumanWeaponSetCurrentTemporary = "c2d_HumanWeaponSetCurrentTemporary"

Proto.d2c_HumanSetCurrentWeapon = "d2c_HumanSetCurrentWeapon"

-- 这个是为了服务器控制客户端用的，因为客户端先行，所以这里服务器如果想让客户端停止干嘛，那么先发个这个
Proto.d2c_HumanWeaponLock = "d2c_HumanWeaponLock"

Proto.c2d_HumanWeaponUnlock = "c2d_HumanWeaponUnlock"

-- 这个现阶段只为了服务器上因状态改变导致速度改变
Proto.c2d_HumanAttackStart = "c2d_HumanAttackStart"


-- 这个现阶段只为了服务器上因状态改变导致速度改变， 如果未来服务器想要知道是否是cancel的，那么可以在加个cancel变量
Proto.c2d_HumanAttackEnd = "c2d_HumanAttackEnd"


--/////////////////////////////////////////////////////////////////////////////////
-- 原则上客户端没打中直接通过服务器转发，打中后才发给服务器进行校验伤害, XXXRequest，真正请求计算，XXXXRoute服务器纯转发
-- 枪，没把rHumanGunAttackNotify当做数据结构用是为了省层table
-- 下发包带weaponid是为了判断是否是同一把枪，绝大多数应该是同一把枪
Proto.c2d_HumanGunAttackOnceRequest = "c2d_HumanGunAttackOnceRequest"

Proto.c2d_HumanGunAttackMultiRequest = "c2d_HumanGunAttackMultiRequest"

-- message d2c_HumanGunAttackResponse {
--     GunVector3D start   = 1;
--     repeated GunVector3D ends = 2;
-- }

Proto.c2d_HumanBowPreAttack = "c2d_HumanBowPreAttack"

Proto.c2d_HumanAttackSubstateRequest = "c2d_HumanAttackSubstateRequest"

Proto.c2d_HumanCancelBowAttack = "c2d_HumanCancelBowAttack"

Proto.c2d_HumanGunAttackRoute = "c2d_HumanGunAttackRoute"

Proto.c2d_HumanProjectAttackRoute = "c2d_HumanProjectAttackRoute"

Proto.c2d_HumanDualWieldAttack = "c2d_HumanDualWieldAttack"



-- 纯转发，客户端自己不rep
Proto.rHumanGunAttackRoute = "rHumanGunAttackRoute"

Proto.rHumanPorjectGunAttackRoute = "rHumanPorjectGunAttackRoute"

-- 这俩东西不管中没中都会给每个客户端发
-- 这里可以考虑吧start去掉
Proto.rHumanGunAttackOnceResult = "rHumanGunAttackOnceResult"

Proto.rHumanGunAttackMultiResult = "rHumanGunAttackMultiResult"

Proto.rHumanDualWieldAttack = "rHumanDualWieldAttack"

Proto.rHumanMeleeAttackRoute = "rHumanMeleeAttackRoute"



-- 客户端自己打到了才上发这个
Proto.c2d_HumanAttackRequest = "c2d_HumanAttackRequest"

-- 每次开始攻击会发这个
Proto.c2d_HumanMeleeAttackRoute = "c2d_HumanMeleeAttackRoute"

-- 近战命中人物时下发
Proto.rHumanMeleeAttackHits = "rHumanMeleeAttackHits"

-- 投掷物
Proto.c2d_HumanHoldThrownWeapon = "c2d_HumanHoldThrownWeapon"

Proto.c2d_HumanUnholdThrownWeapon = "c2d_HumanUnholdThrownWeapon"

Proto.c2d_HumanSelectThrownWeapon = "c2d_HumanSelectThrownWeapon"

Proto.c2d_HumanChangeThrowType = "c2d_HumanChangeThrowType"

Proto.c2d_HumanCancelThrow = "c2d_HumanCancelThrow"

Proto.c2d_HumanBeginThrowRequest = "c2d_HumanBeginThrowRequest"

-- 真扔，服务器spawn投掷物的actor，投掷点应该是在蓝图里配好的，低抛，高抛也应该记了，不需要客户端在传了
Proto.c2d_HumanThrowRequest = "c2d_HumanThrowRequest"

Proto.d2c_HumanThrowResponse = "d2c_HumanThrowResponse"

Proto.c2d_HumanThrowReady = "c2d_HumanThrowReady"

Proto.c2d_HumanThrowExplodeBegin = "c2d_HumanThrowExplodeBegin"

Proto.c2d_EnableHumanMove = "c2d_EnableHumanMove"

Proto.c2d_ChangeSwimmingType = "c2d_ChangeSwimmingType"

-- 拾取物品完成时
Proto.rHumanPickupItem = "rHumanPickupItem"

Proto.rHumanJumpBuffConfig = "rHumanJumpBuffConfig"

-- export from src\dungeon_common\battle_humanweapon.proto end
---------------------------------------------



---------------------------------------------
-- export from src\dungeon_common\battle_item.proto begin




-- ========================================================================================================
-- Item

-- =====================================共用的enum和message==================================

-- d2c回包的状态码（需要考虑是否单独创建一个文件来存放，可以达到不管是哪个系统，只要看到错误码就知道含义的效果）
Proto.ItemReturnCode = {
    OK                                       = 0,    -- 成功
    MATERIAL_NOT_ENOUGH                      = 1,    -- 材料不足
    KEY_ITEMS_NOT_ENOUGH                     = 2,    -- 图纸不足
    PREREQUISITE_ITEMS_NOT_ENOUGH            = 3,    -- 前置物品不足
    ITEM_TYPE_CANNOT_BUILD                   = 4,    -- 物品类型不能建造
    INACCEPTABLE_PLAYER_SHIP_BUILDING_LEVEL  = 5,    -- 不能建造这个等级的船
    NOT_COMPATIBLE                           = 6,    -- 物品不兼容无法安装无法建造
    INVENTORY_FULL                           = 7,    -- 背包空间不足（拾取失败）
    INVENTORY_CAPACITY_NOT_ENOUGHT           = 8,    -- 背包容量不足（已承载容量太大，背包不能卸下，不能替换成容量小的背包）
    CANNOT_BUILD_UNKNOWN_ERROR               = 10,   -- 其他未知错误
    ITEM_HAS_ALREADY_PICKED                  = 11,   -- 当前的拾取材料数量已发生变化，请重新操作
    ITEM_HAS_OWNER                           = 12,   -- 物品已经被别的玩家拾取了
    CANNOT_PICKUP_PARACHUTING                = 13,   -- 跳伞中不能拾取
    CANNOT_PICKUP_NOT_ALIVE                  = 14,   -- 重伤或死亡不能拾取
    CANNOT_PICKUP_CATEGORY_INVALID           = 15,   -- 不可拾取的道具类型
    CANNOT_PICKUP_DISTANCE_INVALID           = 16,   -- 距离太远不能拾取
}

-- 物品位置
Proto.ItemStorageLocation = "ItemStorageLocation"

-- 物品
Proto.BattleItem = "BattleItem"

-- 场景中的物品包（因为有可能要一次性同步给客户端附近的多个物品包，所以把这部分数据结构单独定义了）
Proto.SceneItemRoom = "SceneItemRoom"

-- ===================================物品的同步协议=====================================

-- 同步新增item
Proto.d2c_SyncAddItem = "d2c_SyncAddItem"

-- 同步移除item
Proto.d2c_SyncRemoveItem = "d2c_SyncRemoveItem"

-- 同步Item叠加数量
Proto.d2c_SyncItemStackCount = "d2c_SyncItemStackCount"

-- 同步Item的耐久度
Proto.d2c_SyncItemDurability = "d2c_SyncItemDurability"

-- 同步Item位置
Proto.d2c_SyncItemStorageLocation = "d2c_SyncItemStorageLocation"

-- 复杂的Item操作集合（比如在玩家换船的时候会有比较复杂的物品操作，所以可以集中一起发给客户端）
Proto.d2c_BatchItemOps = "d2c_BatchItemOps"

-- 通知客户端调用所有物品的OnUnequipOnClient，在换船的时候会发
Proto.d2c_OnUnequipAllShipEquipItems = "d2c_OnUnequipAllShipEquipItems"

-- 同步地上的物品
Proto.d2c_SyncSceneItemsDetail = "d2c_SyncSceneItemsDetail"

-- 同步新进入地上的包里的item（因为要给已经打开包的客户端同步数据）
Proto.d2c_SyncAddSceneItem = "d2c_SyncAddSceneItem"

-- 同步地上的包里移除item（因为要给已经打开包的客户端同步数据）
Proto.d2c_SyncRemoveSceneItem = "d2c_SyncRemoveSceneItem"

-- 同步移除一个箱子（因为要给已经打开包的客户端同步数据）
Proto.d2c_SyncRemoveScenePackage = "d2c_SyncRemoveScenePackage"

-- 重置物品数据
Proto.d2c_ResetBattleItemData = "d2c_ResetBattleItemData"

-- =========================================客户端的请求和回包=============================================

-- 制造物品
Proto.c2d_BuildItem = "c2d_BuildItem"

Proto.d2c_BuildItem = "d2c_BuildItem"

-- 主动取消制造物品
Proto.c2d_CancelBuildItem = "c2d_CancelBuildItem"

-- 制造物品被取消（主动取消或者打断）
Proto.d2c_BuildItemCancel = "d2c_BuildItemCancel"

-- 制造物品完成
Proto.d2c_BuildItemFinish = "d2c_BuildItemFinish"

-- 装备物品
Proto.c2d_EquipItem = "c2d_EquipItem"

Proto.d2c_EquipItem = "d2c_EquipItem"

-- 装备可叠加的物品
Proto.c2d_EquipStackableItem = "c2d_EquipStackableItem"

Proto.d2c_EquipStackableItem = "d2c_EquipStackableItem"

-- 已装备的物品交换位置
Proto.c2d_ExchangeStorageLocation = "c2d_ExchangeStorageLocation"

Proto.d2c_ExchangeStorageLocation = "d2c_ExchangeStorageLocation"

-- 卸下物品, 如果count有值且大于0小于这个物品的叠加数则表示部分卸下
Proto.c2d_UnequipItem = "c2d_UnequipItem"

Proto.d2c_UnequipItem = "d2c_UnequipItem"

-- 捡起物品
Proto.c2d_PickupItem = "c2d_PickupItem"

Proto.d2c_PickupItem = "d2c_PickupItem"

-- 丢弃物品
Proto.c2d_ThrowAwayItem = "c2d_ThrowAwayItem"

-- 丢弃物品
Proto.d2c_ThrowAwayItem = "d2c_ThrowAwayItem"

-- 丢弃物品之后捡起物品
Proto.c2d_ThrowAwayAndPickupItem = "c2d_ThrowAwayAndPickupItem"

Proto.d2c_ThrowAwayAndPickupItem = "d2c_ThrowAwayAndPickupItem"

-- 开始查看物品
Proto.c2d_BeginViewSceneItems = "c2d_BeginViewSceneItems"

-- 结束查看物品
Proto.c2d_EndViewSceneItems = "c2d_EndViewSceneItems"

-- 消耗品使用
Proto.c2d_ConsumeItemRequest = "c2d_ConsumeItemRequest"

-- 消耗品使用结果（准备阶段）
Proto.d2c_ConsumeItemStart = "d2c_ConsumeItemStart"
Proto.d2c_ConsumeItemStart_ReturnCode = {
        OK                              = 0, -- 开始准备阶段
        HP_LIMIT                        = 1, -- 消耗品不满足血量需求
        NO_ITEM_FOUND                   = 2, -- 没有找到该消耗品
        NOT_OWNER                       = 3, -- 或该消耗品不属于自己
        ITEM_NOT_CONSUMABLE             = 4, -- 该物品不属于消耗品
        SHIP_CAN_NOT_USE                = 5, -- 船只不可使用该消耗品
        HUMAN_CAN_NOT_USE               = 6, -- 人不可使用该消耗品
        CRAWL_CAN_NOT_USE               = 7, -- 匍匐不可使用消耗品
        PLAYER_DIED                     = 8, -- 玩家已死
        PLAYER_IN_DYING                 = 9, -- 玩家重伤
}

-- 打断消耗品使用
Proto.c2d_ConsumeItemInterrupt = "c2d_ConsumeItemInterrupt"

-- 消耗品使用打断
Proto.d2c_ConsumeItemInterrupt = "d2c_ConsumeItemInterrupt"

-- 消耗品使用成功
Proto.d2c_ConsumeItemSuccess = "d2c_ConsumeItemSuccess"

-- 消耗品使用完成
Proto.d2c_ConsumeItemEnd = "d2c_ConsumeItemEnd"

-- 给客户端同步船的战备
Proto.d2c_SyncShipPreparation = "d2c_SyncShipPreparation"

-- export from src\dungeon_common\battle_item.proto end
---------------------------------------------



---------------------------------------------
-- export from src\dungeon_common\battle_repcommon.proto begin

-- 此文件是d2c_rep和dungeon_common共用的数据结构，非共用不要加到这里




Proto.BattleToastInfo = "BattleToastInfo"
Proto.BattleToastInfo_EToastType = {
        COMMON      = 0,
        SPECIAL     = 1,
}

-- export from src\dungeon_common\battle_repcommon.proto end
---------------------------------------------



---------------------------------------------
-- export from src\dungeon_common\battle_ship.proto begin




--//////////////////////////////////////////////////////////////////////
-- c2d

-- 请求激活舰船武器
Proto.c2d_RequestShipActivateWeaponItem = "c2d_RequestShipActivateWeaponItem"

-- 请求装备舰船投掷物 
Proto.c2d_RequestShipEquipThrownItem = "c2d_RequestShipEquipThrownItem"

-- 请求开火
Proto.c2d_RequestShipFire = "c2d_RequestShipFire"

-- 请求装弹
Proto.c2d_RequestShipLoadBullet = "c2d_RequestShipLoadBullet"

-- 请求改变开镜状态
Proto.c2d_RequestShipChangeAimState = "c2d_RequestShipChangeAimState"

--//////////////////////////////////////////////////////////////////////
-- d2c

-- 通知客户端激活的舰船武器改变
Proto.d2c_NotifyActiveShipWeaponItemChanged = "d2c_NotifyActiveShipWeaponItemChanged"

-- 通知客户端装备的投掷物改变
Proto.d2c_NotifyEquippedShipThrownItemChanged = "d2c_NotifyEquippedShipThrownItemChanged"

-- 通知客户端开始CD
Proto.d2c_NotifyShipWeaponFiringCdBegan = "d2c_NotifyShipWeaponFiringCdBegan"

-- 舰船武器开始装弹通知
Proto.d2c_NotifyShipWeaponBulletLoadingBegan = "d2c_NotifyShipWeaponBulletLoadingBegan"

-- 舰船武器结束装弹通知
Proto.d2c_NotifyShipWeaponBulletLoadingEnded = "d2c_NotifyShipWeaponBulletLoadingEnded"

-- 通知客户端开镜状态改变
Proto.d2c_NotifyShipAimStateChanged = "d2c_NotifyShipAimStateChanged"

-- 通知客户端开镜状态改变
Proto.d2c_NotifyShipFiringOperationChanged = "d2c_NotifyShipFiringOperationChanged"

-- export from src\dungeon_common\battle_ship.proto end
---------------------------------------------



---------------------------------------------
-- export from src\dungeon_common\battle_testautomation.proto begin




Proto.d2c_NotifyClientToQuitDungeon = "d2c_NotifyClientToQuitDungeon"


-- export from src\dungeon_common\battle_testautomation.proto end
---------------------------------------------



---------------------------------------------
-- export from src\dungeon_common\gamecore_watch.proto begin





Proto.ShipWeaponRotationRange = "ShipWeaponRotationRange"

Proto.AttachmentState = "AttachmentState"

Proto.WeaponParams = "WeaponParams"

Proto.WeaponState = "WeaponState"

Proto.EquipmentState = "EquipmentState"


Proto.Vector = "Vector"

Proto.HumanKeyPosition = "HumanKeyPosition"


Proto.HumanExtentState = "HumanExtentState"

Proto.ShipKeyPosition = "ShipKeyPosition"

Proto.ShipExtentState = "ShipExtentState"

Proto.PlayerState = "PlayerState"

Proto.VisibleItemState = "VisibleItemState"

Proto.VisiblePlayerState = "VisiblePlayerState"

Proto.VisibleVehicleState = "VisibleVehicleState"

Proto.VehicleState = "VehicleState"

Proto.CameraState = "CameraState"

Proto.PoisonCircleState = "PoisonCircleState"

Proto.BackpackItem = "BackpackItem"


Proto.Backpack = "Backpack"

Proto.HeardSound = "HeardSound"

Proto.CanBuildItemsList = "CanBuildItemsList"

Proto.BuildList = "BuildList"

Proto.EquipmentItem = "EquipmentItem"

Proto.HumanStatCache = "HumanStatCache"

Proto.ShipStatCache = "ShipStatCache"

Proto.PackageItem = "PackageItem"

Proto.ThrownWeaponState = "ThrownWeaponState"

Proto.ShipMovementState = "ShipMovementState"

Proto.TookDamage = "TookDamage"


Proto.TorpedoState = "TorpedoState"

Proto.SmokeState = "SmokeState"

Proto.DamageRegion = "DamageRegion"

Proto.MakeDamage = "MakeDamage"

Proto.BotState = "BotState"

Proto.d2c_GameCoreAIBotStatus = "d2c_GameCoreAIBotStatus"


Proto.BotTeammateInfo = "BotTeammateInfo"


Proto.d2c_GameCoreTeammates = "d2c_GameCoreTeammates"

Proto.c2d_ToggleBotByIndex = "c2d_ToggleBotByIndex"

Proto.c2d_ToggleBotById = "c2d_ToggleBotById"

Proto.d2c_ToggleBotResult = "d2c_ToggleBotResult"


-- export from src\dungeon_common\gamecore_watch.proto end
---------------------------------------------



---------------------------------------------
-- export from src\dungeon_common\game_watch.proto begin

-- For communication between client and dungeon through RPC.






Proto.c2d_WatchTeammateBattle = "c2d_WatchTeammateBattle"

Proto.c2d_StopWatchTeammateBattle = "c2d_StopWatchTeammateBattle"
Proto.c2d_StopWatchTeammateBattle_EStopType = {
		NONE = 0,
		ABORT = 1,
		FINISH = 2,
}

Proto.WatchMateInfo = "WatchMateInfo"



Proto.d2c_NotifyWatchTeamMate = "d2c_NotifyWatchTeamMate"

Proto.d2c_NotifyWatchMateKillInfo = "d2c_NotifyWatchMateKillInfo"

Proto.d2c_NotifyStopWatchTeammateBattle = "d2c_NotifyStopWatchTeammateBattle"

Proto.d2c_NotifyViewerChangeAimState = "d2c_NotifyViewerChangeAimState"

Proto.d2c_NotifyViewerCarronadeCameraActiveChanged = "d2c_NotifyViewerCarronadeCameraActiveChanged"

Proto.d2c_NotifyViewerMovementState = "d2c_NotifyViewerMovementState"


Proto.d2c_NotifyViewerIsMovingNow = "d2c_NotifyViewerIsMovingNow"

Proto.d2c_NotifyViewerMovementMode = "d2c_NotifyViewerMovementMode"

Proto.d2c_NotifyViewersWeaponBullet = "d2c_NotifyViewersWeaponBullet"

-- 观战玩家信息
Proto.c2d_FFAWatchMateTips = "c2d_FFAWatchMateTips"

Proto.d2c_FFAWatchMateTips = "d2c_FFAWatchMateTips"

Proto.d2c_NotifyViewersGetInVehicle = "d2c_NotifyViewersGetInVehicle"
--

-- export from src\dungeon_common\game_watch.proto end
---------------------------------------------

return Proto