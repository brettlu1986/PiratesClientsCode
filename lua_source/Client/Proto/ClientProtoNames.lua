local Proto = {}

---------------------------------------------
-- export from src\client2.proto begin

-- Message definitions for network packets for the game
-- Note: Follow the style guide when writing message definitions:
-- https://developers.google.com/protocol-buffers/docs/style






-- export from src\client2.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\activity.proto begin






Proto.Activity = "Activity"

Proto.RewardState = {
    UNRECEIVED   = 0, --未领取
    RECEIVE      = 1, --可领取
    RECEIVED     = 2, --已领取
}

Proto.s2c_NotifyActivity = "s2c_NotifyActivity"

Proto.s2c_ResetActivity = "s2c_ResetActivity"


Proto.c2s_UseActivityItem = "c2s_UseActivityItem"

Proto.s2c_UseActivityItem = "s2c_UseActivityItem"

Proto.c2s_GetDrawActivityInfo = "c2s_GetDrawActivityInfo"

Proto.s2c_GetDrawActivityInfo = "s2c_GetDrawActivityInfo"

Proto.c2s_GetBoxActivityInfo = "c2s_GetBoxActivityInfo"

Proto.s2c_GetBoxActivityInfo = "s2c_GetBoxActivityInfo"

Proto.c2s_OpenBox = "c2s_OpenBox"

Proto.s2c_OpenBox = "s2c_OpenBox"

Proto.c2s_GetRollActivityInfo = "c2s_GetRollActivityInfo"

Proto.s2c_GetRollActivityInfo = "s2c_GetRollActivityInfo"

Proto.c2s_RollDice = "c2s_RollDice"

Proto.s2c_RollDice = "s2c_RollDice"
Proto.s2c_RollDice_Move = {
        FORWARD  = 0,
        BACKWARD = 1,
        ORIGIN   = 2,
        STILL    = 3,
}

Proto.c2s_GetDiceReward = "c2s_GetDiceReward"

Proto.s2c_GetDiceReward = "s2c_GetDiceReward"

Proto.c2s_GetQuestionActivityInfo = "c2s_GetQuestionActivityInfo"

Proto.s2c_GetQuestionActivityInfo = "s2c_GetQuestionActivityInfo"

Proto.c2s_GetQuestionReward = "c2s_GetQuestionReward"

Proto.s2c_GetQuestionReward = "s2c_GetQuestionReward"

-- export from src\client2\activity.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\appearance.proto begin






-- ============================================================================

Proto.Appearance = "Appearance"

Proto.c2s_ReplaceWithAppearance = "c2s_ReplaceWithAppearance"

Proto.s2c_ReplaceWithAppearance = "s2c_ReplaceWithAppearance"

-- export from src\client2\appearance.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\award.proto begin





-- ============================================================================

-- 奖励弹窗通知类型
Proto.AwardSourceType = {
    ITEM_CHEST                  = 0,  -- 道具奖励宝箱
    SEASON_BATTLE_PASS          = 1,  -- 赛季通行证
    SEASON_RANK                 = 2,  -- 赛季段位
    SEASON                      = 3,  -- 赛季结算
    ITEM_SELL                   = 4,  -- 背包道具出售
    SUMMON_PARTNER              = 5,  -- 伙伴十连抽           false
    ITEM_UNLOCK_CARD            = 6,  -- 解锁卡               false
    SEASON_CHALLENGE            = 7,  -- 赛季任务
    SUMMON_SAILOR               = 8,  -- 水手抽取             false
    SAILOR_DEGRADE              = 9,  -- 水手降级
    MAIL_ATTACHMENT             = 10, -- 邮件附件发放
    ACCOUNT_REGULAR_AWARD       = 11, -- 局内结算常规奖励      false
    ACCOUNT_SPECIAL_AWARD       = 12, -- 局内结算特殊奖励
    UNLOCK_SHIP                 = 13, -- 解锁船只               false
    EXCHANGE_BUILDING           = 14, -- 装饰物兑换
    CHECKIN                     = 15, -- 签到
    NOOB_BATTLE_AWARD           = 16, -- 新手战斗奖励
    RESEARCH                    = 17, -- 研发
    NEW_PLAYER                  = 18, -- 新玩家创建奖励          false
    FIRST_BATTLE                = 19, -- 首战奖励
    GM_CMD                      = 20, -- GM命令获取
    SHOPPING                    = 21, -- 商店购买
    IAP                         = 22, -- IAP购买
    IAP_FIRST_PURCHASE          = 23, -- 首充奖励
    NOOB_LOGIN_ACTIVITY         = 24, -- 新手登录活动奖励
    VIP                         = 25, -- vip 奖励
    NOOB_SURVEY_AWARD           = 26, -- 问卷调查奖励
    PLAYER_LEVEL_UP_AWARD       = 27, -- 主角等级提升
    TIMED_AWARD                 = 28, -- 定时奖励
    CONTINUOUS_AWARD            = 29, -- 连续签到奖励
    NOOB_SHIP_AWARD             = 30, -- 新手船奖励
    DRAW_TASK_AWARD             = 31, -- 幸运转盘任务奖励
    DRAW_ACTIVITY_AWARD         = 32, -- 幸运转盘奖励
    BOX_ACTIVITY_AWARD          = 33, -- 宝箱抽奖任务奖励
    BOX_TASK_AWARD              = 34, -- 宝箱抽奖任务奖励
    ROLL_TASK_AWARD             = 35, -- 航海大冒险任务奖励
    ROLL_TILE_AWARD             = 36, -- 航海大冒险格子奖励
    ROLL_CIRCLE_AWARD           = 37, -- 航海大冒险满圈奖励
    QUESTION_ACTIVITY_AWARD     = 38, -- 问卷调查活动奖励
}

Proto.s2c_AwardNotification = "s2c_AwardNotification"


Proto.s2c_AwardBegin = "s2c_AwardBegin"

Proto.s2c_AwardEnd = "s2c_AwardEnd"

-- export from src\client2\award.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\battle.proto begin





-- ============================================================================

Proto.Battle = "Battle"

-- 通知客户端首战时间
Proto.s2c_NotifyBattleTime = "s2c_NotifyBattleTime"

-- 战斗结束
Proto.s2c_BattleEnd = "s2c_BattleEnd"


-- export from src\client2\battle.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\buff.proto begin





-- ============================================================================

Proto.Buffs = "Buffs"

Proto.Buff = "Buff"

Proto.c2s_GetBuff = "c2s_GetBuff"

Proto.s2c_SyncBuff = "s2c_SyncBuff"

-- export from src\client2\buff.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\chat.proto begin





-- ========================================================================================================
-- Chat System

Proto.ChatChannel = {
    CHAT_FRIEND = 0,		    -- 好友
    CHAT_TEAM = 1,              -- 队伍
    CHAT_WORLD = 2,		        -- 世界
    CHAT_ROOM = 3,              -- 聊天室
    CHAT_CORPS = 4,             -- 军团
}

Proto.c2s_Chat = "c2s_Chat"

-- 错误的时候回包
Proto.s2c_ChatError = "s2c_ChatError"

Proto.s2c_Chat = "s2c_Chat"

-- 玩家的禁言信息
Proto.Banned = "Banned"

Proto.s2c_BanChat = "s2c_BanChat"

Proto.s2c_UnbanChat = "s2c_UnbanChat"


-- export from src\client2\chat.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\checkin.proto begin






-- ============================================================================

Proto.c2s_GetCheckInInfo = "c2s_GetCheckInInfo"

Proto.s2c_GetCheckInInfo = "s2c_GetCheckInInfo"


Proto.c2s_CheckInAward = "c2s_CheckInAward"

Proto.s2c_CheckInAward = "s2c_CheckInAward"

Proto.c2s_GetTimedAwardInfo = "c2s_GetTimedAwardInfo"

Proto.s2c_GetTimedAwardInfo = "s2c_GetTimedAwardInfo"
Proto.s2c_GetTimedAwardInfo_TimedAwardFlag = {
        TIMED_BEFORE        = 0, -- 未到领奖时间
        TIMED_OUT           = 1, -- 领奖时间已过
        TIMED_ON            = 2, -- 已经可以领奖
        TIMED_AWARDED       = 3, -- 已经领取奖励
}

Proto.c2s_TimedAward = "c2s_TimedAward"

Proto.s2c_TimedAward = "s2c_TimedAward"

-- export from src\client2\checkin.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\currency.proto begin






-- ============================================================================

Proto.Currency = "Currency"

-- 同步货币堆叠数量
Proto.s2c_SyncCurrencyCount = "s2c_SyncCurrencyCount"

Proto.CurrencyCeiling = "CurrencyCeiling"

Proto.CurrencyCeilings = "CurrencyCeilings"

-- 同步货币周期获取数量
Proto.s2c_SyncPeriodicCurrencyCeilings = "s2c_SyncPeriodicCurrencyCeilings"

-- 主动刷新货币上限周期
Proto.c2s_RefreshCurrencyCeilings = "c2s_RefreshCurrencyCeilings"

Proto.s2c_RefreshCurrencyCeilings = "s2c_RefreshCurrencyCeilings"

-- export from src\client2\currency.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\decoration.proto begin






-- ============================================================================

Proto.s2c_SyncDecoration = "s2c_SyncDecoration"

Proto.c2s_PutOnDecoration = "c2s_PutOnDecoration"

Proto.s2c_PutOnDecoration = "s2c_PutOnDecoration"

Proto.c2s_TakeOffDecoration = "c2s_TakeOffDecoration"

Proto.s2c_TakeOffDecoration = "s2c_TakeOffDecoration"

Proto.c2s_UpgradeDecoration = "c2s_UpgradeDecoration"

Proto.s2c_UpgradeDecoration = "s2c_UpgradeDecoration"

Proto.c2s_GetDecoration = "c2s_GetDecoration"

Proto.s2c_GetDecoration = "s2c_GetDecoration"

-- export from src\client2\decoration.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\dungeon.proto begin





-- ========================================================================================================
-- Dungeon

-- 客户端准备进入副本，服务器已将玩家从世界移除，客户端需要显示loading，并将除自己外的其余场景内对象删除，以防进入失败时，服务器重新把玩家加回到场景中，
-- 让客户端重新添加相同的场景内对象报重复创建对象错误
Proto.s2c_WaitingDungeon = "s2c_WaitingDungeon"

Proto.s2c_EnterDungeon = "s2c_EnterDungeon"

Proto.Transform = "Transform"

-- TODO need to rename to s2c_ExitDungeon to keep aligned with defination in ../dungeon.proto
Proto.s2c_LeaveDungeon = "s2c_LeaveDungeon"
Proto.s2c_LeaveDungeon_LeaveReason = {
        NO_REASON = 0,
        DUNGEON_DROPPED_FROM_HUB = 1,
        CLIENT_LOGOUT_FROM_DUNGEON = 2, -- 副本服务器检测到客户端离开，对应 ../dungeon.proto 中 d2s_PlayerExit 协议，若 d2s_PlayerExit 为副本服务器向 hub 发送的第一个关于玩家离开的协议（非 d2s_MatchEnd, d2s_QuitDungeon 或 d2s_LeaveDungeon 等，则通常认为玩家与副本服务器掉线，Hub 发送此 reason 给 client）
}

-- 玩家要求离开副本
Proto.c2s_LeaveDungeon = "c2s_LeaveDungeon"

-- 玩家被副本踢出，reason 由副本经 matchmaker 透传，具体含义由副本和客户端商定
Proto.s2c_PlayerKicked = "s2c_PlayerKicked"

-- 客户端进副本超时后发给服务器，此包在进入Procedure_Battle后如果长时间未收到controller的beginplay会触发
Proto.c2s_TravelDungeonFailed = "c2s_TravelDungeonFailed"

-- 进入副本失败，在 s2c_WaitingDungeon 协议后真正进入副本之前（Dungeon 认为的真正进入副本之前）任何时候发送
Proto.s2c_DungeonEnterFailed = "s2c_DungeonEnterFailed"
Proto.s2c_DungeonEnterFailed_FailReason = {
        DUNGEON_APPLY_FAILED    = 0, -- 副本申请失败
        CLIENT_TRAVEL_FAILED    = 1, -- 客户端发送 c2s_TravelDungeonFailed
        DUNGEON_DROPPED         = 2, -- 副本服务器和 hub 间掉线
        MATCH_END               = 3, -- 战斗结束
        UNKNOWN_REASON          = 4, -- 未知错误
}

-- ================================================================================================================

Proto.c2s_StartMatchmaking = "c2s_StartMatchmaking"

Proto.s2c_StartMatchmaking = "s2c_StartMatchmaking"
Proto.s2c_StartMatchmaking_Reason = {
        SUCCESS = 0, -- 请求成功
        TIMEOUT = 1, -- 请求超时
        CONNECT_ERROR = 2, -- 连接错误
        MATCHMAKER_NOT_FOUND = 3, -- 匹配服务未找到
        NOT_TEAM_LEADER = 4, -- 非队长
        TEAM_MEMBER_NOT_READY = 5, -- 有队友未准备好
        COLLECT_PLAYER_PROPERTIES_ERROR = 6, -- 收集玩家数据错误
        STATUS_ERROR = 7, -- 玩家状态错误，如正在匹配中，正在副本中等等
        ROUND_NUMBER_CHECK_FAILED = 8, -- 匹配轮数检查失败
        NOT_IN_OPEN_TIME = 9,   --匹配类型未在开放时间内
        UNKNOWN_REASON = 100, -- 未知错误
}

Proto.c2s_CancelMatchmaking = "c2s_CancelMatchmaking"

Proto.s2c_CancelMatchmaking = "s2c_CancelMatchmaking"
Proto.s2c_CancelMatchmaking_Reason = {
        PLAYER_CANCEL = 0, -- 取消匹配成功
        MATCHMAKING_TIMEOUT = 1, -- 匹配超时导致取消匹配
        MATCHMAKING_RESET   = 2, -- 匹配重置，发生在匹配中，持续查询匹配服务状态不正确
        NOT_IN_MATCHMAKING = 11, -- 未在匹配中
        NOT_TEAM_LEADER = 12, -- 非队长
        MATCHMAKING_COMPLETE = 13, -- 已经匹配成功
        REQUEST_NOT_FOUND = 14, -- 匹配请求未找到
        REQUEST_TIMEOUT = 15, -- 请求超时
        REQUEST_FAILED = 16, -- 请求失败
        UNKNOWN_REASON = 100, -- 未知错误
}

-- 副本状态，跟随 s2c_PlayerData 发送
Proto.Dungeon = "Dungeon"

-- 若 s2c_DungeonState 中 is_in_dungeon 为 true，回应是否回到上一场战斗
Proto.c2s_EnterLastDungeon = "c2s_EnterLastDungeon"
Proto.c2s_EnterLastDungeon_Answer = {
        YES                 = 0, -- 回副本
        NO                  = 1, -- 留在大厅（放弃回副本，以后也不会以原玩家身份重回副本）
        ALREADY_IN_DUNGEON  = 2, -- 已经在副本中
}

-- 上一场战斗已结束
Proto.s2c_LastDungeonEnd = "s2c_LastDungeonEnd"

-- export from src\client2\dungeon.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\friend.proto begin






-- ============================================================================
-- Friend System
-- 好友申请来源
Proto.FriendSource = {
    PRECISE        = 0,  -- 精确查找
    FUZZY          = 1,  -- 模糊查找
    FRIEND_RECENT  = 2,  -- 好友界面最近组队
    TEAM_RECENT    = 3,  -- 队伍界面最近组队
    NEARBY         = 4,  -- 附近组队
    CHATTING       = 5,  -- 聊天
    GAME_RESULT    = 6,  -- 游戏结算
    PLAYER_INFO    = 7,  -- 查看玩家信息
    TRAINING_CAMP  = 8,  -- 训练营
}

-- 申请好友信息数据
Proto.ApplyFriendInfo = "ApplyFriendInfo"

-- 添加好友返回结果
Proto.AddFriendResult = "AddFriendResult"

-- 好友好感度信息
Proto.FriendIntimacy = "FriendIntimacy"

-- 亲密关系的状态
Proto.RelationshipState = {
    EMPTY = 0,                -- 没有建立过任何亲密关系
    APPLYING = 1,                -- 正在申请建立
    ESTABLISHED = 2,                -- 已经建立
    CANCELING = 3,                -- 正在申请取消
}

-- 好友亲密关系信息
Proto.FriendRelationship = "FriendRelationship"

-- 好友信息
Proto.FriendInfo = "FriendInfo"

-- 好友预约组队
Proto.FriendReservation = "FriendReservation"
Proto.FriendReservation_FriendReservationState = {
        NONE = 0,                -- 被预约的玩家没有收到过这条预约信息
        APPLYING = 1,            -- 被预约的玩家收到了这条信息但是拒绝了/没有处理
        ESTABLISHED = 2,         -- 被预约的玩家收到了这条信息并且接受了
}

-- 精确查找
Proto.c2s_PreciseSearch = "c2s_PreciseSearch"

Proto.s2c_PreciseSearch = "s2c_PreciseSearch"

-- 申请好友
Proto.c2s_ApplyFriend = "c2s_ApplyFriend"

Proto.s2c_ApplyFriend = "s2c_ApplyFriend"

-- 主动推送好友申请
Proto.s2c_NotifyApplyFriend = "s2c_NotifyApplyFriend"

-- 删除申请好友
Proto.c2s_DeleteApplyFriend = "c2s_DeleteApplyFriend"

Proto.s2c_DeleteApplyFriend = "s2c_DeleteApplyFriend"

-- 获得好友申请列表
Proto.c2s_GetApplyFriends = "c2s_GetApplyFriends"

Proto.s2c_GetApplyFriends = "s2c_GetApplyFriends"

-- 获得申请好友列表数量
Proto.c2s_GetApplyFriendCount = "c2s_GetApplyFriendCount"

Proto.s2c_GetApplyFriendCount = "s2c_GetApplyFriendCount"

-- 删除所有好友申请
Proto.c2s_DeleteAllApplyFriend = "c2s_DeleteAllApplyFriend"

Proto.s2c_DeleteAllApplyFriend = "s2c_DeleteAllApplyFriend"

-- 同意所有好友申请
Proto.c2s_AddAllApplyFriend = "c2s_AddAllApplyFriend"

Proto.s2c_AddAllApplyFriend = "s2c_AddAllApplyFriend"

-- 获得好友列表
Proto.c2s_GetFriends = "c2s_GetFriends"

Proto.s2c_GetFriends = "s2c_GetFriends"

-- 添加好友
Proto.c2s_AddFriend = "c2s_AddFriend"

Proto.s2c_AddFriend = "s2c_AddFriend"

-- 主动推送好友添加成功通知
Proto.s2c_NotifyAddFriend = "s2c_NotifyAddFriend"

-- 删除好友
Proto.c2s_DeleteFriend = "c2s_DeleteFriend"

Proto.s2c_DeleteFriend = "s2c_DeleteFriend"

-- 主动推送删除好友通知
Proto.s2c_NotifyDeleteFriend = "s2c_NotifyDeleteFriend"

-- 通知有好友信息变化
Proto.s2c_NotifyFriendSummaryChanged = "s2c_NotifyFriendSummaryChanged"

-- 主动推送好友好感度信息变化
Proto.s2c_NotifyFriendIntimacyChanged = "s2c_NotifyFriendIntimacyChanged"

-- 发送好友预约组队申请
Proto.c2s_SendFriendReservation = "c2s_SendFriendReservation"

Proto.s2c_SendFriendReservation = "s2c_SendFriendReservation"

-- 告知有人向你发起组队预约
Proto.s2c_NotifyFriendReservationApply = "s2c_NotifyFriendReservationApply"

-- 处理好友预约组队申请
Proto.c2s_AcceptFriendReservation = "c2s_AcceptFriendReservation"

Proto.s2c_AcceptFriendReservation = "s2c_AcceptFriendReservation"

-- 告知发起预约的玩家预约结果
Proto.s2c_NotifyFriendReservationResult = "s2c_NotifyFriendReservationResult"

-- 执行预约
Proto.s2c_NotifyFriendReservation = "s2c_NotifyFriendReservation"

-- 客户端告知服务器本地存档内的已预约成功的好友Id
Proto.c2s_SendReservationList = "c2s_SendReservationList"

Proto.s2c_SendReservationList = "s2c_SendReservationList"

Proto.s2c_NotifyReservationList = "s2c_NotifyReservationList"

-- 好友间赠送道具
Proto.c2s_SendFriendGift = "c2s_SendFriendGift"

Proto.s2c_SendFriendGift = "s2c_SendFriendGift"

-- 申请建立亲密关系
Proto.c2s_ApplyCreateRelationship = "c2s_ApplyCreateRelationship"

Proto.s2c_ApplyCreateRelationship = "s2c_ApplyCreateRelationship"

-- 处理亲密关系建立申请
Proto.c2s_HandleCreateRelationshipApply = "c2s_HandleCreateRelationshipApply"

Proto.s2c_HandleCreateRelationshipApply = "s2c_HandleCreateRelationshipApply"

-- 申请撤销亲密关系
Proto.c2s_ApplyCancelRelationship = "c2s_ApplyCancelRelationship"

Proto.s2c_ApplyCancelRelationship = "s2c_ApplyCancelRelationship"

-- 处理亲密关系撤销申请
Proto.c2s_HandleCancelRelationshipApply = "c2s_HandleCancelRelationshipApply"

Proto.s2c_HandleCancelRelationshipApply = "s2c_HandleCancelRelationshipApply"

-- 设置亲密关系优先显示
Proto.c2s_SetRelationshipPriority = "c2s_SetRelationshipPriority"

Proto.s2c_SetRelationshipPriority = "s2c_SetRelationshipPriority"

-- 告知客户端优先显示的好友Id已经发生了变化
Proto.s2c_NotifyRelationshipPriority = "s2c_NotifyRelationshipPriority"

Proto.RelationshipChangeReason = "RelationshipChangeReason"
Proto.RelationshipChangeReason_ChangeReason = {
        CREATE = 0,                 -- 创建亲密关系
        CANCEL = 1,                 -- 撤销亲密关系
        TEAM_UP_BATTLE = 2,         -- 组队游戏
        SEND_GIFT = 3,              -- 赠送道具
        USE_FRIENDSHIP_CARD = 4,    -- 使用好感度道具
}

-- 告知客户端亲密关系发生了变化
Proto.s2c_NotifyRelationshipChange = "s2c_NotifyRelationshipChange"

-- 获取某个玩家的全部亲密关系
Proto.c2s_GetFriendRelationships = "c2s_GetFriendRelationships"

Proto.s2c_GetFriendRelationships = "s2c_GetFriendRelationships"

-- 获取一个列表中玩家互相的亲密关系
Proto.c2s_GetFriendRelationshipsByList = "c2s_GetFriendRelationshipsByList"

Proto.s2c_GetFriendRelationshipsByList = "s2c_GetFriendRelationshipsByList"

-- export from src\client2\friend.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\history.proto begin






-- ============================================================================
-- 历史战绩请求协议

Proto.HistoryStatsBase = "HistoryStatsBase"


Proto.HistoryStatsDetail = "HistoryStatsDetail"



Proto.c2s_GetHistoryStatsDetail = "c2s_GetHistoryStatsDetail"

Proto.s2c_GetHistoryStatsDetail = "s2c_GetHistoryStatsDetail"

Proto.c2s_GetHistoryStats = "c2s_GetHistoryStats"

Proto.s2c_GetHistoryStats = "s2c_GetHistoryStats"


-- export from src\client2\history.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\homeland.proto begin






-- ============================================================================
-- 家园数据

-- 标志性建筑
Proto.Landmark = "Landmark"
Proto.Landmark_LandmarkStatus = {
        IDLE                    = 0,   -- 空闲
        UPGRADING               = 1,   -- 升级中
}

-- 地块
Proto.Block = "Block"

-- 场景
Proto.Scene = "Scene"

-- 家园
Proto.Homeland = "Homeland"

-- ============================================================================
-- 请求协议

Proto.c2s_GetHomeland = "c2s_GetHomeland"
Proto.s2c_GetHomeland = "s2c_GetHomeland"

-- 进入家园
Proto.c2s_EnterHomeland = "c2s_EnterHomeland"

-- 购买场景
Proto.c2s_PurchaseScene = "c2s_PurchaseScene"
Proto.s2c_PurchaseScene = "s2c_PurchaseScene"

-- 切换场景
Proto.c2s_SwitchScene = "c2s_SwitchScene"
Proto.s2c_SwitchScene = "s2c_SwitchScene"

-- 标志性建筑升级
Proto.c2s_LandmarkUpgrade = "c2s_LandmarkUpgrade"
Proto.s2c_LandmarkUpgrade = "s2c_LandmarkUpgrade"

-- 建筑完成升级
Proto.c2s_LandmarkUpgradeComplete = "c2s_LandmarkUpgradeComplete"
Proto.s2c_LandmarkUpgradeComplete = "s2c_LandmarkUpgradeComplete"

-- 购买地块
Proto.c2s_PurchaseBlock = "c2s_PurchaseBlock"
Proto.s2c_PurchaseBlock = "s2c_PurchaseBlock"

-- 摆放建筑
Proto.c2s_PlaceBuilding = "c2s_PlaceBuilding"
Proto.s2c_PlaceBuilding = "s2c_PlaceBuilding"

-- 拆除建筑
Proto.c2s_DestroyBuilding = "c2s_DestroyBuilding"
Proto.s2c_DestroyBuilding = "s2c_DestroyBuilding"

-- 装饰物兑换
Proto.c2s_ExchangeBuilding = "c2s_ExchangeBuilding"
Proto.s2c_ExchangeBuilding = "s2c_ExchangeBuilding"

-- 出售装饰性建筑
Proto.c2s_SellDecorativeBuilding = "c2s_SellDecorativeBuilding"
Proto.s2c_SellDecorativeBuilding = "s2c_SellDecorativeBuilding"

-- 研发武器和零件
Proto.c2s_ResearchItem = "c2s_ResearchItem"
Proto.s2c_ResearchItem = "s2c_ResearchItem"

-- 研发武器和零件完成
Proto.c2s_ResearchItemComplete = "c2s_ResearchItemComplete"
Proto.s2c_ResearchItemComplete = "s2c_ResearchItemComplete"

Proto.s2c_ResearchItems = "s2c_ResearchItems"

-- export from src\client2\homeland.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\iap.proto begin






-- ==================================== 数据结构 =======================================
Proto.FirstPurchaseState = {
    NONE            = 0,    -- 首充未达标
    DEBT            = 1,    -- 首充未领取奖励
    DONE            = 2,    -- 奖励已领取
}

Proto.Iap = "Iap"
-- 同步玩家首充状态
Proto.s2c_SyncFirstPurchaseState = "s2c_SyncFirstPurchaseState"

-- 申请支付
Proto.c2s_RequestPurchase = "c2s_RequestPurchase"

Proto.s2c_RequestPurchase = "s2c_RequestPurchase"

-- 推送支付结果
Proto.s2c_NotifyPurchaseResult = "s2c_NotifyPurchaseResult"

-- 申请恢复订单
Proto.c2s_RequestRestoreOrder = "c2s_RequestRestoreOrder"

Proto.s2c_RequestRestoreOrder = "s2c_RequestRestoreOrder"

Proto.c2s_ApplyFirstPurchaseReward = "c2s_ApplyFirstPurchaseReward"

Proto.s2c_ApplyFirstPurchaseReward = "s2c_ApplyFirstPurchaseReward"

-- export from src\client2\iap.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\item.proto begin






-- ============================================================================

Proto.Item = "Item"

-- 获取新道具
Proto.s2c_AddItem = "s2c_AddItem"

-- 同步Item堆叠数量
Proto.s2c_SyncItemStackCount = "s2c_SyncItemStackCount"

Proto.s2c_SyncItemExpiredAt = "s2c_SyncItemExpiredAt"

Proto.AddedItem = "AddedItem"

-- 添加新的道具客户端弹出奖励窗口
Proto.s2c_AddItemNotification = "s2c_AddItemNotification"

-- 出售道具
Proto.c2s_SellItem = "c2s_SellItem"

Proto.s2c_SellItem = "s2c_SellItem"

-- 使用道具
Proto.c2s_UseItem = "c2s_UseItem"

Proto.s2c_UseItem = "s2c_UseItem"

Proto.HoldLimitItem = "HoldLimitItem"

-- 达到持有数量的道具
Proto.s2c_ReachHoldLimitToast = "s2c_ReachHoldLimitToast"

-- 获取宝箱掉落物信息
Proto.c2s_GetChestDropConfig = "c2s_GetChestDropConfig"

Proto.s2c_GetChestDropConfig = "s2c_GetChestDropConfig"



Proto.c2s_GetPlayerItems = "c2s_GetPlayerItems"


Proto.s2c_GetPlayerItems = "s2c_GetPlayerItems"

-- export from src\client2\item.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\login.proto begin






Proto.c2s_Login = "c2s_Login"

Proto.c2s_Login_Platform = {
        UNKNOWN = 0,
        IOS     = 1,
        ANDROID = 2,
        WINDOWS = 3,
}


Proto.s2c_LoginError = "s2c_LoginError"

Proto.s2c_NewPlayer = "s2c_NewPlayer"

Proto.c2s_TutorialStep = "c2s_TutorialStep"

Proto.c2s_CreatePlayer = "c2s_CreatePlayer"

Proto.s2c_CreatePlayerError = "s2c_CreatePlayerError"

Proto.s2c_PlayerData = "s2c_PlayerData"

Proto.s2c_Disconnect = "s2c_Disconnect"
Proto.s2c_Disconnect_Reason = {
        UNKNOWN             = 0,
        KICK_OUT            = 1,    -- 强制下线
        DOUBLE_LOGIN        = 2,
        SERVER_FULL         = 3,
        SERVER_MAINTENANCE  = 4,
        PING_MISSING        = 5,    -- Server doesn't receive c2s_Ping for a long time.
        BANNED              = 6,    -- 账号已被封禁
        ANTI_ADDICTION      = 7,    -- 防沉迷
}


Proto.s2c_ServerMaintenance = "s2c_ServerMaintenance"

-- export from src\client2\login.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\loop_msg.proto begin




-- ========================================================================================================
-- LoopMsg System

-- 每种跑马灯消息对应一个协议，有新的类型的跑马灯，需增加一个协议

Proto.LoopStrategy = "LoopStrategy"

Proto.s2c_LoopMsgItem = "s2c_LoopMsgItem"



Proto.s2c_LoopMsgGM = "s2c_LoopMsgGM"

-- export from src\client2\loop_msg.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\mail.proto begin





-- ========================================================================================================
-- Mail System


--附件
Proto.MailAttachment = "MailAttachment"

-- 邮件
Proto.Mail = "Mail"


Proto.Mailbox = "Mailbox"

Proto.MailboxLimit = "MailboxLimit"

Proto.MailParams_Custom = "MailParams_Custom"

Proto.MailParams_TeamInvitation = "MailParams_TeamInvitation"

Proto.MailParams_ItemExpired = "MailParams_ItemExpired"

Proto.MailParams_UseFriendshipCard = "MailParams_UseFriendshipCard"

Proto.MailParams_SendFriendGift = "MailParams_SendFriendGift"

Proto.MailParams_FriendRelationship = "MailParams_FriendRelationship"

Proto.MailParams_FriendRelationshipLevel = "MailParams_FriendRelationshipLevel"

Proto.MailParams = "MailParams"

-- 客户端用 MailType 的值作为主键去定义展示配置
Proto.MailType = {
    TYPE_INVALID = 0,                   -- 未定义，不合法
    TYPE_TEAM_INVITATION = 1,           -- 组队邀请
    TYPE_ITEM_EXPIRED = 2,              -- 道具过期
    TYPE_CUSTOM = 3,                    -- 自定义标题和内容
    TYPE_USE_FRIENDSHIP_CARD = 4,       -- 使用好感度道具增加好感度(鲜花)
    TYPE_SEND_FRIEND_GIFT = 5,          -- 好友间赠送道具
    TYPE_FRIEND_RELATIONSHIP = 6,       -- 亲密关系发生变化(申请通过,撤销通过)
    TYPE_FRIEND_RELATIONSHIP_LEVEL = 7, -- 亲密关系等级发生变化
}

Proto.MailboxType = {
    MAIL_INVALID = 0,
    MAIL_SYSTEM = 1,           -- 系统邮件
    MAIL_FRIEND = 2,           -- 好友邮件
    MAIL_MESSAGE_CENTER = 3,   -- 消息中心
}

-- 同步所有邮
Proto.c2s_PlayerMails = "c2s_PlayerMails"

Proto.s2c_PlayerMails = "s2c_PlayerMails"

-- 新邮件通知
Proto.s2c_NewMailNotify = "s2c_NewMailNotify"

-- 已读
Proto.c2s_MarkMailAsRead = "c2s_MarkMailAsRead"

Proto.s2c_MarkMailAsRead = "s2c_MarkMailAsRead"

-- 领取
Proto.c2s_ClaimMailAttachments = "c2s_ClaimMailAttachments"


Proto.s2c_ClaimMailAttachments = "s2c_ClaimMailAttachments"

-- 删除
Proto.c2s_DeleteMail = "c2s_DeleteMail"

Proto.s2c_DeleteMail = "s2c_DeleteMail"
Proto.s2c_DeleteMail_DeleteMailReason = {
        USER = 0,                      -- 用户主动删除
        EXPIRE = 1,                    -- 邮件过期
        MAILBOX_FULL = 2,              -- 邮箱已满，被新邮件顶掉
}

-- export from src\client2\mail.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\matchmaking.proto begin





-- 副本限时开放功能

Proto.c2s_MatchmakingOpenTime = "c2s_MatchmakingOpenTime"

Proto.s2c_MatchmakingOpenTime = "s2c_MatchmakingOpenTime"

Proto.OpenTime = "OpenTime"

Proto.GameMode = "GameMode"

-- export from src\client2\matchmaking.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\misc.proto begin





-- ============================================================================

-- See: GmSystem
Proto.c2s_GmCmd = "c2s_GmCmd"

-- ========================================================================================================

Proto.s2c_SyncExp = "s2c_SyncExp"

Proto.s2c_LevelUp = "s2c_LevelUp"

Proto.s2c_NameChanged = "s2c_NameChanged"

-- ========================================================================================================

-- Both client and server use this message
Proto.Ping = "Ping"

-- ========================================================================================================

-- Send current server time (Unix Time in milliseconds) to client
Proto.s2c_ServerTime = "s2c_ServerTime"

-- ========================================================================================================

-- Send given reason and duration to client to ban a player.
Proto.s2c_BanPlayer = "s2c_BanPlayer"

-- ========================================================================================================

-- export from src\client2\misc.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\noob.proto begin






-- ============================================================================

Proto.c2s_SyncNoobStage = "c2s_SyncNoobStage"

Proto.s2c_SyncNoobStage = "s2c_SyncNoobStage"

Proto.c2s_GetNoobStage = "c2s_GetNoobStage"

Proto.s2c_GetNoobStage = "s2c_GetNoobStage"

-- 待客户端优化后，删除 [问卷调查] 这组协议
-- 请求问卷调查信息
Proto.c2s_GetSurvey = "c2s_GetSurvey"

Proto.s2c_GetSurvey = "s2c_GetSurvey"

-- 请求问卷调查奖励
Proto.c2s_GetSurveyAward = "c2s_GetSurveyAward"

Proto.s2c_GetSurveyAward = "s2c_GetSurveyAward"

-- 新手奖励类型
Proto.NoobAwardType = {
    SURVEY            = 0,               -- 新手问卷调查奖励
    NOOB_SHIP         = 1,               -- 新手船奖励
}

-- 新手奖励状态
Proto.c2s_GetNoobAwardState = "c2s_GetNoobAwardState"

Proto.s2c_GetNoobAwardState = "s2c_GetNoobAwardState"

-- 领取新手奖励
Proto.c2s_ReceiveNoobAward = "c2s_ReceiveNoobAward"

Proto.s2c_ReceiveNoobAward = "s2c_ReceiveNoobAward"

-- export from src\client2\noob.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\partner.proto begin






-- ============================================================================

Proto.Partners = "Partners"



Proto.c2s_SummonPartner = "c2s_SummonPartner"
Proto.c2s_SummonPartner_SummonType = {
        ONE_TIME    = 0,
        TEN_TIMES   = 1,
}


Proto.s2c_SummonPartner = "s2c_SummonPartner"


Proto.PartnerPosition = {
    PARTNER_FIRST   = 0,
    PARTNER_SECOND  = 1,
    PARTNER_THIRD   = 2,
}

Proto.c2s_UpLevelPartner = "c2s_UpLevelPartner"

Proto.s2c_UpLevelPartner = "s2c_UpLevelPartner"

Proto.c2s_HirePartner = "c2s_HirePartner"

Proto.s2c_HirePartner = "s2c_HirePartner"

Proto.c2s_FirePartner = "c2s_FirePartner"

Proto.s2c_FirePartner = "s2c_FirePartner"

Proto.c2s_CompoundPartner = "c2s_CompoundPartner"

Proto.s2c_CompoundPartner = "s2c_CompoundPartner"

-- export from src\client2\partner.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\player.proto begin





--import "client2/shop.proto";

-- ============================================================================

Proto.Player = "Player"
--    repeated Goods goods                        = 17;   // 玩家商品购买记录

-- export from src\client2\player.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\rc.proto begin





Proto.ReturnCode = {
    -- Each module is assigned 100 digits

    -- General 0~99
    OK                     = 0, -- The request sent by client was successfully processed by server
    INVALID_REQUEST        = 1, -- The request sent by client was invalid
    SERVER_ERROR           = 2, -- Server internal error
    LOGIN_FAIL             = 3, -- Login failed (invalid token, internal error, etc.)
    NAME_UNAVAILABLE       = 4, -- Player name already taken
    DATA_ERROR             = 5, -- invalid data (null pointer)
    PLAYER_COUNT_LIMIT     = 6, -- 角色数量达到上限，无法创建角色
    PLAYER_NAME_LENGTH     = 7, -- 角色名字长度不符合要求
    PLAYER_NAME_CHAR       = 8, -- 角色名字包含非法字符
    PLAYER_NAME_EMPTY      = 9, -- 角色名字不能为空
    REVISION_CHECK_FAILED   = 10, -- 版本校验失败


    -- Team 100~199
    PLAYER_ALREADY_IN_TEAM       = 100, -- 玩家已经加入了队伍
    INVITEE_ALREADY_IN_TEAM      = 101, -- 被邀请人已经加入了队伍
    PLAYER_NOT_IN_TEAM           = 102, -- 玩家所在队伍已解散
    PLAYER_NOT_IN_INVITE_LIST    = 103, -- 玩家不在邀请列表
    NOT_TEAM_LEADER              = 104, -- 不是队长
    REFUSE_INVITE                = 105, -- 拒绝邀请
    REFUSE_JOIN                  = 106, -- 拒绝加入队伍
    NOT_IN_APPLY_LIST            = 107, -- 玩家不在申请列表
    INVITATION_OUT_DATE          = 108, -- 邀请已经过期
    APPLICATION_OUT_DATE         = 109, -- 申请已经过期
    PLAYER_NOT_REPLY             = 110, -- 对方未答复
    OTHER_SIDE_ALREADY_IN_TEAM   = 111, -- 对方已经加入了队伍
    CAN_NOT_INVITE_SELF          = 112, -- 不能邀请自己
    CAN_NOT_APPLY_SELF           = 113, -- 不能申请自己
    LEADER_NEED_NOT_READY        = 114, -- 队长不需要准备
    OTHER_SIDE_OFFLINE           = 115, -- 对方离线
    OTHER_SIDE_MATCHING          = 116, -- 对方匹配中
    OTHER_SIDE_BATTLING          = 117, -- 对方战斗中

    NOT_TEAM_MEMBER              = 120, -- 不是队伍成员
    TEAM_DISMISSED               = 121, -- 队伍已解散
    TEAM_FULL                    = 122, -- 队伍满员
    PLAYER_JOIN_TEAM             = 123, -- 有玩家加入队伍
    PLAYER_LEAVE_TEAM            = 124, -- 有玩家离开队伍
    KICK_OUT_PLAYER              = 125, -- 玩家被请离队伍
    RECRUIT_IN_COOLDOWN          = 126, -- 招募冷却中
    RECRUIT_NOT_ALLOW_CHANGE     = 127, -- 招募人数不允许修改


    -- Item 200~299
    ITEM_CANNOT_USE              = 200, -- 道具不可使用
    ITEM_NOT_FOUND               = 201, -- 未找到这个物品
    ITEM_CANNOT_SELL             = 202, -- 物品不能出售
    ITEM_NOT_IN_BACKPACK         = 203, -- 物品不在背包里
    ITEM_NOT_ENOUGH              = 204, -- 物品数量不足
    ITEM_EXPIRED                 = 205, -- 商品过期无法使用
    ITEM_LEVEL_LIMITED           = 206, -- 玩家等级不足
    ITEM_GENDER_NOT_MATCH        = 207, -- 玩家性别不对
    ITEM_USE_TOO_MUCH            = 208, -- 道具一次性使用数量过多



    -- Friend 300~399
    APPLY_FRIEND_LIMIT               = 300, -- 好友申请人数上限
    FRIEND_COUNT_LIMIT               = 301, -- 好友人数已达上限
    OTHER_APPLY_FRIEND_LIMIT         = 302, -- 对方申请列表上限
    OTHER_FRIEND_COUNT_LIMIT         = 303, -- 对方好友人数上限
    PLAYER_NOT_FOUND                 = 304, -- 未发现玩家数据
    CANNOT_ADD_SELF                  = 305, -- 目标玩家不能是自己
    ALREADY_IN_APPLY_FRIEND          = 306, -- 已经在申请好友列表中
    ALREADY_IN_FRIEND                = 307, -- 已经在好友列表中
    OTHER_NOT_IN_APPLY_LIST          = 308, -- 对方不在申请列表
    APPLY_FRIEND_MSG_EMPTY           = 309, -- 申请好友消息为空
    FRIEND_LIST_EMPTY                = 310, -- 好友列表为空
    APPLY_FRIEND_LIST_EMPTY          = 311, -- 好友申请列表为空
    OTHER_NOT_FRIEND                 = 312, -- 对方不是好友
    FRIEND_DB_ERROR                  = 313, -- 数据异常，请重试
    ALREADY_SEND_GIFT_TODAY          = 314, -- 今日已经赠送过
    TODAY_SEND_GIFT_LIMIT            = 315, -- 今日赠送次数已经达到上限
    RESERVATION_NO_REPLY             = 316, -- 被预约好友暂未回复，请耐心等待
    RESERVATION_ALREADY_ACCEPT       = 317, -- 该好友已被预约成功
    INTIMACY_POINT_NOT_ENOUGH        = 318, -- 好感度不足
    FRIEND_NOT_BATTLING              = 319, -- 好友不在战斗中，无法预约
    RESERVATION_NOT_FIND             = 320, -- 好友未发送过组队预约
    RELATIONSHIP_ID_INVALID          = 321, -- 亲密关系类型非法
    SELF_RELATIONSHIP_COUNT_LIMIT    = 322, -- 自己的亲密关系数量达到上限
    OTHER_RELATIONSHIP_COUNT_LIMIT   = 323, -- 对方的亲密关系数量达到上限
    RELATIONSHIP_ALREADY_EXIST       = 324, -- 亲密关系已经存在
    RELATIONSHIP_NOT_FOUND           = 325, -- 亲密关系不存在
    RELATIONSHIP_COOLING_DOWN        = 326, -- 还不能建立亲密关系
    RELATIONSHIP_CANNOT_HANDLE       = 327, -- 没有批准申请的权限
    RELATIONSHIP_APPLY_EXPIRED       = 328, -- 亲密关系申请已经过期
    INTIMACY_POINT_PERIODIC_LIMIT    = 329, -- 周期内已经不能获得好感度
    INTIMACY_POINT_MAX_LIMIT         = 330, -- 好感度已经达到上限
    FORBID_VIEW_INTIMACY             = 331, -- 禁止查看亲密关系

    -- Mail 400~499
    MAIL_NOT_EXIST                   = 401, -- 邮件不存在
    MAIL_NOT_CLAIMED                 = 402, -- 邮件未领取
    MAIL_NOT_READ                    = 403, -- 邮件未读
    MAIL_OUT_OF_DATE                 = 404, -- 邮件过期
    MAIL_CLAIMED                     = 405, -- 邮件已领取
    MAIL_READ                        = 406, -- 邮件已读
    MAIL_NOT_HAS_ATTACHMENT          = 407, -- 邮件没附件

    -- Currency 500~599
    MONEY_IS_NOT_ENOUGH              = 501, -- 金钱不足
    CURRENCY_CEILING_REFRESH_ERROR   = 502, -- 货币周期刷新时间异常

    -- Sailor 600~699
    SAILOR_NOT_FOUND                = 601, -- 水手不存在
    SAILOR_SLOT_LOCKED              = 602, -- 水手槽位未解锁
    SAILOR_ADD_FAILED               = 603, -- 水手添加失败
    SAILOR_SUMMON_ID_NOT_FOUND      = 604, -- 水手召唤id未找到
    SAILOR_CATEGORY_NOT_MATCH       = 605, -- 水手类型不匹配
    SAILOR_UPGRADE_COUNT_LIMIT      = 606, -- 水手升级数量超出拥有数量，或 <= 0
    SAILOR_UPGRADE_GRADE_LIMIT      = 607, -- 水手升级等级已达到最高等级
    SAILOR_DEGRADE_COUNT_LIMIT      = 608, -- 水手降级数量超过拥有数量，或 <= 0
    SAILOR_DEGRADE_GRADE_LIMIT      = 609, -- 水手降级等级已是最低等级
    SAILOR_EQUIPPED_ALL_TOP_GRADE   = 610, -- 上阵水手已经全部是最高等级
    SAILOR_EQUIPPED_GRADE_LIMIT     = 611, -- 升级上阵水手希望升到的等级错误，<= 当前等级
    SAILOR_EQUIPPED_EMPTY_SLOT      = 612, -- 升级上阵水手，希望升级的槽位未装备水手
    SAILOR_EQUIPPED_COUNT_LIMIT     = 613, -- 希望升级的水手列表为空
    SAILOR_SLOT_UNLOCKED            = 614, -- 水手槽位已解锁
    SAILOR_SLOT_INVALID             = 615, -- 水手槽位不合法
    SAILOR_SLOT_WRONG_ORDER         = 616, -- 水手槽位解锁顺序错误
    SAILOR_NO_FREE_SUMMON_ID        = 617, -- 此id不能免费抽
    SAILOR_COOLDOWN_LIMITED         = 618, -- 免费抽技能冷却时间
    SAILOR_CURRENCY_ID_INVALID      = 619, -- 抽取申请花费的货币类型不合法

    -- Chat 700~799
    CHAT_CHANNEL_INVALID            = 700, -- 频道不存在
    CHAT_IN_COOLDOWN                = 701, -- CD时间
    CHAT_CONTENT_LENGTH             = 702, -- 字数长度不符合
    CHAT_NO_TEAM                    = 703, -- 玩家不在队伍
    CHAT_NO_ROOM                    = 704, -- 玩家不在聊天室
    CHAT_NO_FRIEND                  = 705, -- 玩家不是好友
    CHAT_NOT_HAVE_CORPS             = 706, -- 玩家没有军团
    CHAT_BANNED                     = 707, -- 玩家被禁言

    -- Caption Wear 800~899
    WEAR_NOT_DRESSED                = 800, -- 没有穿在身上
    WEAR_NOT_FOUND                  = 801, -- 找不到这个穿戴
    WEAR_REPEATED                   = 802, -- 不能穿同样的装备
    WEAR_EXPIRED                    = 803, -- 过期, 不能穿戴

    -- Partner      900~999
    PARTNER_POOL_NOT_EXIST          = 901, -- 伙伴奖池不存在
    PARTNER_CAN_NOT_FOUND           = 902, -- 伙伴没有配置
    PARTNER_GRADE_NOT_FOUND         = 903, -- 伙伴品质配置不存在
    PARTNER_NOT_EXIST               = 904, -- 玩家没有这个伙伴
    PARTNER_FRAGMENT_NOT_ENOUGH     = 905, -- 伙伴碎片不足
    PARTNER_HIRED                   = 906, -- 伙伴不能重复上阵
    PARTNER_NOT_BE_HIRED            = 907, -- 伙伴没有上阵
    PARTNER_REPEATED                = 908, -- 不能重复获得改伙伴
    PARTNER_REACH_MAX_LEVEL         = 909, -- 伙伴已达最高等级

    -- Ship         1000~1099
    SHIP_SLOT_LOCKED                = 1001, -- 未解锁
    SHIP_SLOT_ALL_UNLOCKED          = 1002, -- 已全解锁
    SHIP_SLOT_UNLOCKED              = 1003, -- 槽位已解锁
    SHIP_SLOT_UNLOCK_IN_WRONG_ORDER = 1004, -- 解锁未按照正确顺序
    SHIP_NOT_FOUND                  = 1005, -- 没有此船（未解锁）
    SHIP_HAS_UNLOCKED               = 1006, -- 船已解锁
    SHIP_INVALID_UNLOCK_METHOD      = 1007, -- 无此解锁方式
    SHIP_CATEGORY_INVALID           = 1008, -- 不是船只
    SHIP_HAS_BEEN_EQUIPPED          = 1009, -- 船只已经上阵
    SHIP_DEFAULT_EQUIPPED           = 1010, -- 船只默认上阵，不需装备
    SHIP_NOT_EQUIPPED               = 1011, -- 船只没有上阵

    SHIP_WEAPON_NOT_FOUND           = 1021, -- 无此船武器
    SHIP_WEAPON_HAS_CHOSEN          = 1022, -- 已经是所选值
    SHIP_WEAPON_CATEGORY_INVALID    = 1023, -- 非法武器类别（不是武器）

    SHIP_PART_NOT_FOUND             = 1041, -- 无此船配件
    SHIP_PART_HAS_CHOSEN            = 1042, -- 已经是所选值
    SHIP_PART_CATEGORY_INVALID      = 1043, -- 非法配件类别（不是零件）

    SHIP_SKIN_ALREADY_OWN           = 1051, -- 已经拥有舰船皮肤
    SHIP_SKIN_SHIP_LOCKED           = 1052, -- 对应舰船未解锁
    SHIP_SKIN_CATEGORY_INVALID      = 1053, -- 非法皮肤类型
    SHIP_SKIN_NOT_FOUND             = 1054, -- 无此皮肤
    SHIP_SKIN_INVALID_BUY_METHOD    = 1055, -- 购买方式非法
    SHIP_SKIN_HAS_BEEN_EQUIPPED     = 1056, -- 皮肤已经选中

    SHIP_UNKNOWN_ERROR              = 1099, -- 未知错误

    -- Season      1100~1199
    ALREADY_COLLECT_RANK_DAILY_CHEST = 1101, -- 已经收集过段位每日宝箱
    ALREADY_ACTIVE_BATTLE_PASS       = 1102, -- 已经激活赛季通行证
    BATTLE_TIER_INVALID              = 1103, -- 战阶无效
    TICKET_IS_NOT_ENOUGH             = 1104, -- 点券不足
    BATTLE_PASS_NOT_ACTIVE           = 1105, -- 没有激活赛季通行证
    CHALLENGE_NOT_EXIST              = 1106, -- 挑战任务不存在
    CHALLENGE_WEEKLY_NOT_COMPLETED   = 1107, -- 赛季周任务没有完成
    CHALLENGE_WEEKLY_HAS_AWARDED     = 1108, -- 赛季周任务已经领奖
    CHALLENGE_HAS_EXPIRED            = 1109, -- 任务已经失效
    CHALLENGE_SUB_NOT_EXIST          = 1110, -- 挑战子任务不存在
    CHALLENGE_SUB_NOT_COMPLETED      = 1111, -- 挑战子任务没有完成
    SEASON_NOT_JOINED                = 1112, -- 赛季未参加
    OFF_SEASON_BATTLE_PASS           = 1113, -- 休赛期不允许购买通行证
    BATTLE_TIER_LEVEL_AWARD_RECEIVED = 1114, -- 已经领取赛季战阶奖励

    -- Homeland     1200~1299
    HOMELAND_LOCKED                  = 1201, -- 家园未解锁
    ALREADY_PURCHASED_SCENE          = 1202, -- 场景已购买
    SCENE_LOCKED                     = 1203, -- 场景未解锁
    NOT_OWNED_SCENE                  = 1204, -- 未购买该场景
    UNLOCK_LANDMARK_GRADE            = 1205, -- 解锁需要的标志性建筑等级不足

    PRE_LANDMARK_TOO_LOW             = 1210, -- 前置建筑等级不足
    UNCOMPLETED_TIME                 = 1211, -- 升级时间未到
    LANDMARK_MAX_UPGRADE             = 1212, -- 建筑满级

    BLOCK_HAS_ITEM                   = 1220, -- 地块已占用
    DECORATIVE_NOT_FOUND             = 1221, -- 装饰物未找到
    BLOCK_LOCKED                     = 1222, -- 地块未解锁
    ITEM_RESEARCHED                  = 1230, -- 道具已研发
    ITEM_RESEARCHING                 = 1231, -- 道具正在研发
    RESEARCH_COMPLETED               = 1232, -- 研发已完成

    -- CheckIn      1300~1399
    CHECKIN_HAS_AWARD                = 1301, -- 签到当天已经领奖
    TIMED_AWARD_BEFORE               = 1302, -- 未到领奖时间
    TIMED_AWARD_OUT                  = 1303, -- 领奖时间已过
    TIMED_AWARDED                    = 1304, -- 已经领取奖励

    -- Settings     1400~1499
    FORBID_VIEW_STATS                = 1401, -- 禁止查看个人统计
    FORBID_VIEW_HISTORY              = 1402, -- 禁止查看战绩历史记录

    -- Iap          1500~1599
    IAP_REFUSE_APPLY_PURCHASE        = 1501, -- 拒绝购买
    IAP_NOT_FOUND_PRODUCT_ID         = 1502, -- 未发现产品Id
    IAP_EXIST_PENDING_ORDER          = 1503, -- 存在未处理的订单
    IAP_FIRST_PURCHASE_LIMITED       = 1504, -- 首充金额不足
    IAP_AWARD_RECEIVED               = 1505, -- 奖励已被领取

    -- Shop         1600~1699
    SHOP_GOODS_COUNT_LIMITED         = 1601, -- 购买数量超过限制
    SHOP_ID_INVALID                  = 1602, -- 商品id不存在
    SHOP_CURRENCY_ID_INVALID         = 1603, -- 货币id不存在
    SHOP_NOT_ENOUGH_CURRENCY         = 1604, -- 货币数量不足
    SHOP_NO_SHIP_WITH_SKIN           = 1605, -- 未拥有皮肤对应的舰船
    SHOP_GOODS_OFF_SHELF             = 1606, -- 商品未上架

    -- Activity     1700~1799
    NOOB_LOGIN_AWARD_RECEIVED        = 1701, -- 奖励已领取
    NOOB_LOGIN_DAY_NOT_ENOUGH        = 1702, -- 登录天数不足
    NOOB_SURVEY_RECEIVED_AWARD       = 1703, -- 问卷调查已领奖
    CONTINUOUS_DAY_NOT_ENOUGH        = 1704, -- 连续签到天数不足
    CONTINUOUS_AWARD_RECEIVED        = 1705, -- 连续签到奖励已领取
    NOOB_AWARD_RECEIVED              = 1706, -- 新手活动已领奖
    ACTIVITY_NOT_FOUND               = 1707, -- 活动暂未开启或者已经结束
    ACTIVITY_ITEM_UNUSED             = 1708, -- 活动不能使用此道具
    ACTIVITY_REWARD_NOT_FOUND        = 1709, -- 活动奖池配置错误
    BOX_AlREADY_OPENED               = 1710, -- 宝箱已开启
    ACTIVITY_REWARD_UNRECEIVED       = 1711, -- 活动奖励不可领取
    ACTIVITY_REWARD_RECEIVED         = 1712, -- 活动奖励已领取

    -- Usable item 1800~1899
    USABLE_VIP_REPEAT_SAME_DAY          = 1800, -- 当天重复领取
    USABLE_VIP_NOT_EXIST                = 1801, -- vip 不存在
    USABLE_VIP_NOT_ENOUGH_REMAIN_TIMES  = 1802, -- vip 领完了
    USABLE_BUFF_NOT_EXIST               = 1803, -- 道具卡添加buff失败, 不存在这个配置的buff
    USABLE_RENAME_CARD_COUNT_ERROR      = 1804, -- 改名卡数量校验失败
    USABLE_RENAME_CARD_TIME_INTERVAL    = 1805, -- 改名时间太频繁
    USABLE_UNLOCK_ITEM_SUIT_REPEATED    = 1806, -- 套装加锁卡部件已拥有

    -- Caption Decoration 1900~1999
    DECORATION_NOT_DRESSED                = 1900, -- 没有穿在身上
    DECORATION_NOT_FOUND                  = 1901, -- 找不到这个饰品
    DECORATION_REPEATED                   = 1902, -- 不能穿同样的饰品
    DECORATION_EXPIRED                    = 1903, -- 过期, 不能穿戴
    DECORATION_CURRENCY_NOT_ENOUGH        = 1905, -- 原力之尘不足
    DECORATION_REACHED_MAX_GRADE          = 1906, -- 饰品已达最高等级
    DECORATION_CONFIG_NOT_FOUND           = 1907, -- 饰品配置未找到
}

-- export from src\client2\rc.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\sailor.proto begin






-- ============================================================================

-- 水手槽位信息
Proto.SailorSlot = "SailorSlot"

-- 水手装备信息
Proto.EquippedSailor = "EquippedSailor"

Proto.FreeSummonSailor = "FreeSummonSailor"

Proto.SummonGroupCount = "SummonGroupCount"

Proto.Sailor = "Sailor"

-- 水手招募
Proto.c2s_SailorSummon = "c2s_SailorSummon"

Proto.s2c_SailorSummon = "s2c_SailorSummon"


Proto.c2s_SailorUpgrade = "c2s_SailorUpgrade"

Proto.s2c_SailorUpgrade = "s2c_SailorUpgrade"

Proto.c2s_SailorDegrade = "c2s_SailorDegrade"

Proto.s2c_SailorDegrade = "s2c_SailorDegrade"

Proto.EquippedSailorUpgrade = "EquippedSailorUpgrade"

-- 升级装备中水手
Proto.c2s_UpgradeEquippedSailor = "c2s_UpgradeEquippedSailor"

Proto.s2c_UpgradeEquippedSailor = "s2c_UpgradeEquippedSailor"

-- 一键卸载
Proto.c2s_SailorUnequipAll = "c2s_SailorUnequipAll"

Proto.s2c_SailorUnequipAll = "s2c_SailorUnequipAll"

-- 水手上船，替换
Proto.c2s_SailorEquip = "c2s_SailorEquip"

Proto.s2c_SailorEquip = "s2c_SailorEquip"

Proto.c2s_UnlockSailorSlot = "c2s_UnlockSailorSlot"

Proto.s2c_UnlockSailorSlot = "s2c_UnlockSailorSlot"

-- 卸载同类水手
Proto.c2s_TheSameSailorUnequip = "c2s_TheSameSailorUnequip"

Proto.s2c_TheSameSailorUnequip = "s2c_TheSameSailorUnequip"

-- export from src\client2\sailor.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\schedule.proto begin






-- ============================================================================
-- 新手登录活动

-- 领取新手登录活动奖励
Proto.c2s_GetNoobLoginAward = "c2s_GetNoobLoginAward"
Proto.s2c_GetNoobLoginAward = "s2c_GetNoobLoginAward"

-- 请求新手七日签到数据
Proto.c2s_NoobLoginSchedule = "c2s_NoobLoginSchedule"
Proto.s2c_NoobLoginSchedule = "s2c_NoobLoginSchedule"

-- 战星双倍活动
Proto.s2c_BattleStarSchedule = "s2c_BattleStarSchedule"

-- ============================================================================
-- 连续签到活动

-- 请求连续签到数据
Proto.c2s_GetContinuousSchedule = "c2s_GetContinuousSchedule"

Proto.s2c_GetContinuousSchedule = "s2c_GetContinuousSchedule"

-- 领取连续签到活动奖励
Proto.c2s_ReceiveContinuousAward = "c2s_ReceiveContinuousAward"

Proto.s2c_ReceiveContinuousAward = "s2c_ReceiveContinuousAward"

-- ============================================================================

-- 挑战类目标记录
Proto.ChallengeTargetRecord = "ChallengeTargetRecord"

-- 兑换类目标记录
Proto.ExchangeTargetRecord = "ExchangeTargetRecord"

-- 掉落类记录
Proto.DropTargetRecord = "DropTargetRecord"

-- 活动记录
Proto.ScheduleRecord = "ScheduleRecord"

-- 请求活动列表
Proto.c2s_ScheduleList = "c2s_ScheduleList"

Proto.s2c_ScheduleList = "s2c_ScheduleList"

-- 活动记录更新
Proto.s2c_RefreshScheduleRecord = "s2c_RefreshScheduleRecord"

-- 参与活动
Proto.c2s_ReachTarget = "c2s_ReachTarget"

Proto.s2c_ReachTarget = "s2c_ReachTarget"

-- export from src\client2\schedule.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\season.proto begin






-- ==================================== 数据结构 =======================================

Proto.PlayerSeasonStatus = {
    FIRST_TIME = 0, -- 玩家首次赛季
    RUNNING    = 1, -- 玩家赛季进行中
    RESET      = 2, -- 玩家赛季重置
    OFF_SEASON = 3, -- 休赛期
}

Proto.Rank = "Rank"

Proto.SeasonRank = "SeasonRank"

-- 赛季战斗通行证
Proto.SeasonBattlePass = "SeasonBattlePass"

-- 挑战基本数据
Proto.Challenge = "Challenge"

-- 赛季挑战 (任务)
Proto.SeasonChallenge = "SeasonChallenge"

-- 玩家登录需要赛季数据
Proto.SeasonPrimary = "SeasonPrimary"

-- 赛季Summary
Proto.SeasonSummary = "SeasonSummary"

-- 赛季
Proto.Season = "Season"

-- 赛季统计
Proto.SeasonStats = "SeasonStats"


-- 赛季档案概要
Proto.SeasonHistorySummary = "SeasonHistorySummary"

Proto.SeasonHistoryDetail = "SeasonHistoryDetail"

-- ===================================== 协议 ==========================================

-- 得到赛季全部数据
Proto.c2s_GetSeason = "c2s_GetSeason"

Proto.s2c_GetSeason = "s2c_GetSeason"

-- 重置赛季
Proto.c2s_ResetSeason = "c2s_ResetSeason"

Proto.s2c_ResetSeason = "s2c_ResetSeason"

-- 得到赛季统计数据
Proto.c2s_GetSeasonStats = "c2s_GetSeasonStats"

Proto.s2c_GetSeasonStats = "s2c_GetSeasonStats"

-- 得到所有赛季的赛季概要
Proto.c2s_GetSeasonHistorySummaries = "c2s_GetSeasonHistorySummaries"

Proto.s2c_GetSeasonHistorySummaries = "s2c_GetSeasonHistorySummaries"

-- 得到赛季历史详情
Proto.c2s_GetSeasonHistoryDetails = "c2s_GetSeasonHistoryDetails"

Proto.s2c_GetSeasonHistoryDetails = "s2c_GetSeasonHistoryDetails"

-- 收集段位每日宝箱
Proto.c2s_CollectRankDailyChest = "c2s_CollectRankDailyChest"

Proto.s2c_CollectRankDailyChest = "s2c_CollectRankDailyChest"

-- 通知段位变化
Proto.s2c_NotifyRankChange = "s2c_NotifyRankChange"

-- 购买战阶
Proto.c2s_BuyBattleTier = "c2s_BuyBattleTier"

Proto.s2c_BuyBattleTier = "s2c_BuyBattleTier"

-- 通知赛季战星变化
Proto.s2c_NotifyBattleStar = "s2c_NotifyBattleStar"

-- 通知赛季战阶升级变化
Proto.s2c_NotifyBattleTierUp = "s2c_NotifyBattleTierUp"

-- 激活battle Pass
Proto.c2s_BuyBattlePass = "c2s_BuyBattlePass"

Proto.s2c_BuyBattlePass = "s2c_BuyBattlePass"

-- 获得赛季积分排名
Proto.c2s_GetSeasonPointRanking = "c2s_GetSeasonPointRanking"

Proto.s2c_GetSeasonPointRanking = "s2c_GetSeasonPointRanking"

-- 领取战阶奖励
Proto.c2s_ReceiveBattleTierAward = "c2s_ReceiveBattleTierAward"

Proto.s2c_ReceiveBattleTierAward = "s2c_ReceiveBattleTierAward"

-- 一键领取战阶奖励
Proto.c2s_ReceiveAllBattleTierAward = "c2s_ReceiveAllBattleTierAward"

Proto.s2c_ReceiveAllBattleTierAward = "s2c_ReceiveAllBattleTierAward"

-- 挑战类型
Proto.ChallengeType = {
    DAILY           = 0,        -- 日
    WEEKLY          = 1,        -- 周
    SEASONAL        = 2,        -- 赛季
}

Proto.ChallengeSub = "ChallengeSub"

Proto.c2s_GetChallenge = "c2s_GetChallenge"

Proto.s2c_GetChallenge = "s2c_GetChallenge"

Proto.c2s_ChallengeSubAward = "c2s_ChallengeSubAward"

Proto.s2c_ChallengeSubAward = "s2c_ChallengeSubAward"

Proto.c2s_ChallengeWeeklyAward = "c2s_ChallengeWeeklyAward"

Proto.s2c_ChallengeWeeklyAward = "s2c_ChallengeWeeklyAward"

Proto.c2s_CurrentChallengeWeekId = "c2s_CurrentChallengeWeekId"

Proto.s2c_CurrentChallengeWeekId = "s2c_CurrentChallengeWeekId"

Proto.ChallengeAwardStatus = "ChallengeAwardStatus"

Proto.s2c_NotifyChallengeAwardStatus = "s2c_NotifyChallengeAwardStatus"

Proto.c2s_GetSeasonSummary = "c2s_GetSeasonSummary"

Proto.s2c_GetSeasonSummary = "s2c_GetSeasonSummary"

-- export from src\client2\season.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\setting.proto begin





-- ============================================================================
-- 玩家个人偏好设置

Proto.Setting = "Setting"

Proto.c2s_SavePlayerSettings = "c2s_SavePlayerSettings"

Proto.s2c_SavePlayerSettings = "s2c_SavePlayerSettings"




-- export from src\client2\setting.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\ship.proto begin






-- ============================================================================

Proto.EquippedShip = "EquippedShip"

Proto.ShipWeapon = "ShipWeapon"

Proto.ShipPart = "ShipPart"

Proto.ShipSkin = "ShipSkin"

-- 船只信息
Proto.Ship = "Ship"

-- 舰船相关
Proto.c2s_UnlockShipSlot = "c2s_UnlockShipSlot"

Proto.s2c_UnlockShipSlot = "s2c_UnlockShipSlot"

Proto.c2s_EquipShip = "c2s_EquipShip"

Proto.s2c_EquipShip = "s2c_EquipShip"

Proto.c2s_UnequipShip = "c2s_UnequipShip"

Proto.s2c_UnequipShip = "s2c_UnequipShip"

-- 船只武器
Proto.c2s_ChooseShipWeapon = "c2s_ChooseShipWeapon"

Proto.s2c_ChooseShipWeapon = "s2c_ChooseShipWeapon"

-- 船只零件
Proto.c2s_ChooseShipPart = "c2s_ChooseShipPart"

Proto.s2c_ChooseShipPart = "s2c_ChooseShipPart"

Proto.s2c_UnequipShipSkin = "s2c_UnequipShipSkin"

Proto.c2s_EquipShipSkin = "c2s_EquipShipSkin"

Proto.s2c_EquipShipSkin = "s2c_EquipShipSkin"

-- export from src\client2\ship.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\shop.proto begin






-- ============================================================================

Proto.GoodsCurrency = "GoodsCurrency"

-- 商品信息
Proto.Goods = "Goods"

Proto.GoodsData = "GoodsData"

Proto.c2s_RefreshGoods = "c2s_RefreshGoods"

Proto.s2c_RefreshGoods = "s2c_RefreshGoods"

Proto.c2s_GoodsData = "c2s_GoodsData"

Proto.s2c_GoodsData = "s2c_GoodsData"


Proto.ShoppingGoods = "ShoppingGoods"

-- 购买商品
Proto.c2s_GoShopping = "c2s_GoShopping"

Proto.s2c_GoShopping = "s2c_GoShopping"

-- export from src\client2\shop.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\summary.proto begin






-- ============================================================================

Proto.PlayerStatus = {
    OFFLINE = 0,
    IDLE = 1,
    MATCHMAKING = 2,
    BATTLING = 3,
}

Proto.PlayerSummary = "PlayerSummary"

Proto.c2s_PlayerSummary = "c2s_PlayerSummary"

Proto.s2c_PlayerSummary = "s2c_PlayerSummary"

Proto.c2s_PlayerSummaries = "c2s_PlayerSummaries"
Proto.s2c_PlayerSummaries = "s2c_PlayerSummaries"

Proto.s2c_NotifyPlayerSummaryChange = "s2c_NotifyPlayerSummaryChange"

-- export from src\client2\summary.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\task.proto begin






-- 任务
Proto.Task = "Task"

--提示任务完成
Proto.s2c_NotifyTask = "s2c_NotifyTask"

-- export from src\client2\task.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\team.proto begin






-- ============================================================================
-- 客户端需要处理的队伍同步协议

-- 队伍数据
Proto.TeamMember = "TeamMember"

-- 玩家登陆游戏、加入队伍、创建队伍 同步给玩家完整的队伍信息
Proto.s2c_SyncTeam = "s2c_SyncTeam"

-- ==============================================
-- 组建队伍，添加成员

-- 邀请玩家加入队伍
Proto.c2s_InviteJoinTeam = "c2s_InviteJoinTeam"
Proto.s2c_InviteJoinTeam = "s2c_InviteJoinTeam"

-- 申请加入队伍
Proto.c2s_ApplyJoinTeam = "c2s_ApplyJoinTeam"
Proto.s2c_ApplyJoinTeam = "s2c_ApplyJoinTeam"

-- 招募渠道
Proto.RecruitChannel = {
    WORLD                           = 0,    -- 世界
    ROOM                            = 1,    -- 聊天室
    CORPS                           = 2,    -- 军团
}

-- 招募队友
Proto.c2s_RecruitTeammate = "c2s_RecruitTeammate"
Proto.s2c_RecruitTeammate = "s2c_RecruitTeammate"

-- 广播通知招募队友
Proto.s2c_NotifyRecruitTeammate = "s2c_NotifyRecruitTeammate"

-- 应答聊天招募
Proto.c2s_ReplyRecruitTeammate = "c2s_ReplyRecruitTeammate"
Proto.s2c_ReplyRecruitTeammate = "s2c_ReplyRecruitTeammate"

-- 应答加入队伍
Proto.c2s_ReplyJoinTeam = "c2s_ReplyJoinTeam"
Proto.s2c_ReplyJoinTeam = "s2c_ReplyJoinTeam"

-- 查看邀请人信息
Proto.c2s_getInvitorInfo = "c2s_getInvitorInfo"
Proto.s2c_getInvitorInfo = "s2c_getInvitorInfo"

-- 通知服务器可以接受邀请邮件
Proto.c2s_EnableReceiveInviteMail = "c2s_EnableReceiveInviteMail"

-- 通知玩家有申请和邀请
Proto.s2c_NotifyInviteApply = "s2c_NotifyInviteApply"

-- 通知玩家申请和邀请结果
Proto.s2c_NotifyReplyInviteApply = "s2c_NotifyReplyInviteApply"

-- 通知队伍状态变更(成员加入、成员离队等)
Proto.s2c_NotifyTeamChanged = "s2c_NotifyTeamChanged"

-- 通知队长变更
Proto.s2c_NotifyLeaderChanged = "s2c_NotifyLeaderChanged"

-- 通知有成员信息变化
Proto.s2c_NotifyMemberSummaryChanged = "s2c_NotifyMemberSummaryChanged"

-- 通知有玩家准备好
Proto.s2c_NotifyReadyToMatch = "s2c_NotifyReadyToMatch"

-- 通知队伍成员切换匹配条件
Proto.s2c_NotifySwitchMatchCondition = "s2c_NotifySwitchMatchCondition"

-- ==============================================

-- 玩家准备好，等待匹配
Proto.c2s_ReadyToMatch = "c2s_ReadyToMatch"
Proto.s2c_ReadyToMatch = "s2c_ReadyToMatch"

-- 队长切换匹配条件
Proto.c2s_SwitchMatchCondition = "c2s_SwitchMatchCondition"

-- ==============================================
-- 队伍其他操作

-- 玩家主动离开队伍
Proto.c2s_LeaveTeam = "c2s_LeaveTeam"

-- 踢出队伍
Proto.c2s_KickOutTeamMember = "c2s_KickOutTeamMember"

-- 转移队长
Proto.c2s_TransferTeamLeader = "c2s_TransferTeamLeader"

-- 邀请申请类型
Proto.InviteApplyType = {
    INVITE_JOIN_TEAM                 = 0,    -- 邀请加入队伍
    APPLY_JOIN_TEAM                  = 1,    -- 申请加入队伍
}

-- 变动类型
Proto.ChangeType = {
    ADD_MEMBER                       = 0,   -- 有成员加入
    LEAVE_TEAM                       = 1,   -- 主动离队
    KICK_OUT_TEAM                    = 2,   -- 有成员被踢出队伍
    DISMISS                          = 3,   -- 队伍解散
}

-- 邀请来源
Proto.InviteFrom = {
    FRIEND                           = 0,
    CHAT                             = 1,
}

-- export from src\client2\team.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\ui.proto begin





Proto.s2c_ShowToast = "s2c_ShowToast"


-- export from src\client2\ui.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\usable_item.proto begin






-- ============================================================================

Proto.c2s_GetRenameTimes = "c2s_GetRenameTimes"

Proto.s2c_GetRenameTimes = "s2c_GetRenameTimes"

Proto.VipAward = "VipAward"

Proto.c2s_GetVipAwardDetails = "c2s_GetVipAwardDetails"


Proto.s2c_SyncVipAwardDetails = "s2c_SyncVipAwardDetails"

Proto.c2s_GetVipAward = "c2s_GetVipAward"

Proto.s2c_GetVipAward = "s2c_GetVipAward"

-- export from src\client2\usable_item.proto end
---------------------------------------------



---------------------------------------------
-- export from src\client2\wear.proto begin






-- ============================================================================

Proto.Wears = "Wears"

Proto.WeaponSkin = "WeaponSkin"


-- 防具时装显示为基础时装
Proto.c2s_dryFashionFlag = "c2s_dryFashionFlag"

Proto.s2c_dryFashionFlag = "s2c_dryFashionFlag"

Proto.s2c_syncWear = "s2c_syncWear"

Proto.c2s_putOnWear = "c2s_putOnWear"

Proto.s2c_putOnWear = "s2c_putOnWear"

Proto.c2s_takeOffWear = "c2s_takeOffWear"

Proto.s2c_takeOffWear = "s2c_takeOffWear"

-- 穿脱时装
Proto.c2s_fitFashion = "c2s_fitFashion"

Proto.s2c_fitFashion = "s2c_fitFashion"

-- export from src\client2\wear.proto end
---------------------------------------------

return Proto