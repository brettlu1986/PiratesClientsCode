local Proto = {}

---------------------------------------------
-- export from src\kvp.proto begin



-- key_group 定义
Proto.GroupId = {

    -- Common usage
    COMMON = 0,

    -- 1-999 are reserved for Quest System
    -- New groups starts at 1000
    _RESERVED_QUEST_BEGIN_ = 1,
    _RESERVED_QUEST_END_   = 999,

    
    ESCORT                 = 1000,             -- 押运玩法
    SOCIETYEXPLORER        = 1001,             -- 协会探险者
    SOCIETYPRIVATEER       = 1002,             -- 协会私掠公司
    SOCIETYGUARD           = 1003,             -- 协会皇家护卫队
    SCARCE_TRADE           = 1004,             -- 紧急贸易
    SMUGGLE                = 1006,             -- 走私玩法
    CAPTURE                = 1007,             -- 捕获任务
    QUEST                  = 1008,             -- 任务配置
    WELFARE                = 1009,             -- 福利数据
    ACTIVITY               = 1010,             -- 活动 key：enum Activity
    QNA                    = 1011,             -- 答题玩法
    LASTACTIVITY           = 1012,             -- 昨天的活动状态 key：enum Activity
    WELFAREGETBACK         = 1013,             -- 福利找回 key：enum Activity
    MEAL                   = 1014,             -- 大餐玩法
    CAMERASHOT			   = 1015,			   -- 拍照活动
    FISHING                = 1016,             -- 钓鱼活动
    SALVAGE                = 1017,             -- 打捞活动
    ACTIVITY_DUNGEON       = 1018,             -- 活动副本
    DAILY_TRADE            = 1019,             -- 每日商会
    GUILDACTIVENESS        = 1020,             -- 帮会活跃度 key：enum Activity
    GUILD                  = 1021,             -- 帮会    
    WORLD_BOSS             = 1022,             -- 世界boss
    AVG                    = 1023,             -- 历险
}

Proto.Common = {
    SKIP_TUTORIAL = 0,                           -- 是否跳过新手教学
    SURVEY_AWARD = 1,                            -- 问卷调查是否已领奖

    -- Faction begin
    LOOT_FLAG_RECEIVE_TIME = 10,                -- 掠夺旗领取时间 (GameWeek)
    FACTION_DUNGEON_COUNT  = 11,                -- 阵营副本累计次数
    FACTION_DUNGEON_TIME   = 12,                -- 阵营副本计次时间 (GameWeek)
}

-- 押运玩法 key_id 定义
Proto.Escort = {
    DATE                = 0,
    NPC_TEMPLATE_ID     = 1,
    SCENE_ID        = 2,
    ITEM_GENRE      = 3,
    ITEM_DETAIL_TYPE= 4,
    ITEM_PARTICULAR = 5,
    
    IN_PROGRESS     = 6,
    BATTLE_RADIUS  = 7,
    
    MISSION_ID      = 8,
    
    FINISHED_COUNT  = 9,
    
    FAILURE_PHASE   = 10,       -- 是否处于任务失败阶段，任务失败需指引回接收押运npc处
    ACCEPT_NPC_TEMPLATE_ID = 11,    -- 接任务时的npc_template_id
    ACCEPT_SCENE_ID    = 12,   -- 接任务时的场景id
}

Proto.SocietyExplorer = {
    SE_INVALID                = 0,
    SE_DATE                   = 1,      -- 最近一次活动时间
    SE_DATA_ID                = 2,      -- 当前活动数据表中ID
    SE_NEED_BATTLE            = 3,      -- 是否需要进入战斗1是0否
    SE_SALVAGE_X              = 4,      -- 打捞NPC位置X
    SE_SALVAGE_Y              = 5,      -- 打捞NPC位置Y
    SE_FINISHED_COUNT         = 6,
    SE_IN_PROGRESS            = 7,      -- 是否接取活动1是0否
}

Proto.SocietyPrivateer = {
    SP_INVALID             = 0,
    SP_DATE                = 1,         -- 最近一次活动时间
    SP_DATA_ID             = 2,         -- 当前活动数据表中ID
    SP_FINISHED_COUNT      = 3,
    SP_IN_PROGRESS         = 4,         -- 是否接取活动1是0否
}

Proto.SocietyGuard = {
    ACCEPTED_DATE           = 1,
    FINISHED_COUNT          = 2,
    IN_PROGRESS             = 3,
    RANDOM_TEMP_NPC_ID      = 4,
}

Proto.ScarceTrade = {
    CARGO_GENRE         = 0,
    CARGO_DETAIL_TYPE   = 1,
    CARGO_PARTICULAR    = 2,
    LAST_TIME_ACTIVATE  = 3,
    IS_ACTIVATE         = 4,
    DESTINATION_ID      = 5,            -- 目的地港口id
    COMPLETE_COUNT      = 6,            -- 已经交付了多少货物
    RANDOM_COUNT        = 7,            -- 已经随机了多少次
    PLAYER_LEVEL        = 8,            -- 激活本次紧急贸易时的玩家等级
    NPC_TEMPALTE_ID     = 9,            -- 港口随机的任务Npc id
    RECOMMEND_PROT      = 10,           -- 推荐的购买港口
}

-- 走私玩法 key_id 定义
Proto.Smuggle = {
    SG_INVALID             = 0,
    SG_DATE                = 1,
    SG_DATA_ID             = 2,
    SG_OPTION              = 3,
    SG_FINISHED_COUNT      = 4,
    SG_IN_PROGRESS         = 5,
}

-- 捕获任务
Proto.Capture = {
    IS_ACTIVATE             = 0,
    SCENE_ID                = 1,
    NPC_TEMPLATE_ID         = 2,
    QUESET_NPC_ID           = 3,
    AWARD_ID                = 4,
}

-- 任务配置
Proto.Quest = {
    OPEN_ACTIVITY_GUIDE    = 0,
}

-- 福利
Proto.Welfare = {
    -- 刷新时间
    WELFARE_UPDATED_DAY_TIME            = 0,          -- 日更新刷新时间
    WELFARE_UPDATED_WEEK_TIME           = 1,          -- 周更新刷新时间
    WELFARE_UPDATED_MONTH_TIME          = 2,          -- 月更新刷新时间

    WELFARE_LAST_AWARD_TIME             = 3,          -- 上次获得奖励时间，用来做奖励找回
    
    -- 签到
    CHECKIN_STATE_BITS                  = 10,         -- 签到领取数据
    CHECKIN_CUMULATIVE_STATE_BITS       = 11,         -- 累计签到领取数据
    
    -- 七日
    NEW_PLAYER_STATE_BITS               = 20,         -- 七日领取数据
    
    -- 在线
    ONLINE_STATE_BITS                   = 30,         -- 在线领取数据
    
    -- 活跃
    ACTIVE_STATE_BITS                   = 40,         -- 活跃领取数据                
    ACTIVE_DEGREE                       = 41,         -- 活跃度      
    
    -- 神秘宝藏
    TREASURE_TIMES                      = 50,         -- 神秘宝藏已开启次数
}

Proto.Qna = {
    QNA_JOIN_COUNT                  = 0,        -- 参与次数
    QNA_JOIN_TIME                   = 1,        -- 参与时间
}

Proto.Meal = {
    MEAL_GET_FREE_FOOD_TIME             = 0,          -- 领取免费食物的活动时间
    MEAL_GET_LIMIT_FOOD_TIME            = 1,          -- 领取、购买限量食物的活动时间
}

-- 活动
Proto.Activity = {
    ACTIVITY_BEGIN              = 0,         -- 
    ACTIVITY_SMUGGLE            = 1,         -- 走私
    ACTIVITY_ESCORT             = 2,         -- 押运
    ACTIVITY_GATHER             = 3,         -- 采集捕获
    ACTIVITY_TRADE              = 4,         -- 每日商会
    ACTIVITY_CO_OP              = 5,         -- 挑战副本
    ACTIVITY_SOCIETY_GUARD      = 6,         -- 皇家护卫
    ACTIVITY_ARENA              = 7,         -- 竞技场
    ACTIVITY_FACTION_DUNGEON    = 8,         -- 阵营副本
    ACTIVITY_FISHING            = 9,         -- 钓鱼
    ACTIVITY_QNA                = 10,        -- 答题
    ACTIVITY_CAMERASHOT         = 11,        -- 拍照
    ACTIVITY_MEAL               = 12,        -- 海盗大餐
    ACTIVITY_ROWING             = 13,        -- 赛艇
    ACTIVITY_BATTLEGROUND       = 15,        -- 战场
    ACTIVITY_ASSOCIATION        = 16,        -- 协会
    ACTIVITY_WORLD_BOSS         = 17,        -- 世界boss
    -- 以下ID为活动副本预留
    ACTIVITY_DUNGEON_BEGIN      = 101,
    -- ...
    ACTIVITY_DUNGEON_END        = 120,
}

-- 拍照活动
Proto.CameraShot = {
    ACCEPTED_DATE           = 1,
    FINISHED_COUNT          = 2,
    IN_PROGRESS             = 3,
    RANDOM_TARGET_ID        = 4,			-- 随机的拍照目标
    RANDOM_SCENE_ID			= 5,			-- 随机的拍照场景
    ACTIVITY_START_TIME     = 6,            -- 本次任务的活动开始时间
    FINISHED_TARGET_INDEX   = 7,            -- 可用的FINISHED_TARGET_ID_X
    FINISHED_TARGET_ID1     = 8,            -- 最近几次完成的拍照目标，最近完成的目标不会再次随机
    FINISHED_TARGET_ID2     = 9,
    FINISHED_TARGET_ID3     = 10,
    FINISHED_TARGET_ID4     = 11,
}

-- 钓鱼活动
Proto.Fishing = {
    TIME                    = 0,        -- 活动时间
    -- 1~50 预留给兑换次数
}

-- 打捞活动
Proto.Salvage = {
    ACCEPTED_DATE           = 0,        -- 最后一次接受任务时间
    POINTS                  = 1,        -- 打捞点
    IN_PROGRESS             = 2,        -- 是否接取任务1是0否
    FINISHED_COUNT          = 3,
    SALVAGED_POINT_COUNT    = 4,        -- 打捞完成的点数
    SALVAGED_POINTS         = 5,        -- 打捞完成的点
}

Proto.ActivityDungeon = {
    LAST_GAME_DAY           = 0,        -- 最近一次领奖日期
    -- 接下来的 Key 和活动副本的 ID 一一对应，用于存储累计奖励次数
}

Proto.DailyTrade = {
    LAST_JOIN_GAME_DAY      = 0,        -- 最近一次参加的gameday
    TARGET_SCENE_ID         = 1,        -- 收任务的场景id
    TARGET_NPC_ID           = 2,        -- 收任务的npc的id
    IN_PROGRESS             = 3,        -- 是否接取任务1是0否
    QUEST_ITEM              = 4,        -- 任务物品
}

Proto.Worldboss = {
    REMAIN_ENTER_NUMS       = 0,        -- 当天剩余进入次数
    LAST_JOIN_GAME_DAY      = 1,        -- 最后一次参加活动的时间
}

Proto.Guild = {
    GAME_DAY                = 0,        -- 活跃度上次更新的时间
    BOSS_AWARD_1            = 1,        -- boss贫瘠副本奖励
    BOSS_AWARD_2            = 2,        -- boss普通副本奖励
    BOSS_AWARD_3            = 3,        -- boss富有副本奖励
    AWARD_DAY               = 4,        -- boss奖励时间
}

Proto.Avg = {
    AVG_ID                  = 0,        -- 历险进度
}
-- export from src\kvp.proto end
---------------------------------------------

return Proto