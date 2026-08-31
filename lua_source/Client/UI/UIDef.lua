-----------------------------------------------------
--File Name    : UIDef.lua
--Author       : Song Fuhao
--Create Time  : 2016-08-16
--Description  : UI相关常量定义
-----------------------------------------------------

local UIDef = {}

--[[
    UI地图模式常量
]]
UIDef.UI_MAP_MODE =
{
    WILD_OCEAN   = 1,           --野外
    BATTLE  = 2,                --战斗副本
    TOWN = 3,                   --主城
    OTHER = 4,
}


--[[
    Wnd定义
]]
UIDef.UI_FULLSCREEN_MASK            = "UI_FullscreenMask"               -- 全屏透明遮罩，可用于部分时候屏蔽所有点击使用
UIDef.UI_DIALOG_BOARD               = "UI_DialogBoard"                  -- 简单的提示对话框
UIDef.UI_TOAST_BOARD                = "UI_ToastBoard"                   -- Toast面板
UIDef.UI_TIPS_BOARD                 = "UI_TipsBoard"                    -- Toast面板
UIDef.UI_LOGIN                      = "UI_GameLogin"                    -- 登录界面
UIDef.UI_SELECTLEVEL                = "UI_SelectLevel"                  -- 选择新手老手及诶按
UIDef.UI_ANNOUNCEMENT               = "UI_Announcement"                 -- 登录公告
UIDef.UI_SELECT_ROLE                = "UI_SelectRole"                   -- 选角色界面
UIDef.UI_CREATE_ROLE                = "UI_CreateRole"                   -- 选角色界面
UIDef.UI_LOBBY                      = "UI_Lobby"                        -- 大厅界面
UIDef.UI_ITEM_TOAST_BOARD           = "UI_ItemToastBoard"               -- ItemToast面板
UIDef.UI_SPECIAL_TOAST_BOARD        = "UI_SpecialToastBoard"            -- 副本内特殊Toast面板
UIDef.UI_ITEM_EQUIP_TOAST_BOARD     = "UI_ItemEquipToastBoard"          -- 装配或卸下配件或消耗品的效果弹窗
UIDef.UI_BATTLE_MAIN                = "UI_BattleMain"                   -- 副本界面
UIDef.UI_MAIN                       = "UI_Main"                         -- 主界面
UIDef.UI_WINDOWS_BG                 = "UI_WindowsBG"                    -- 通用窗口底部背景虚化
UIDef.UI_WINDOWS_TOP_BAR            = "UI_WindowsTopBar"                -- 通用窗口顶部金币条
UIDef.UI_SHIP_BUILD_DETAIL          = "UI_ShipBuildDetail"              -- 造船界面
UIDef.UI_SHIP_BUILD                 = "UI_ShipBuild"                    -- 造船树界面
UIDef.UI_LEAVE_PORT                 = "UI_LeavePort"                    -- 离港界面
UIDef.UI_CHANGE_SHIP                = "UI_ChangeShip"                   -- 换船界面
UIDef.UI_SHIP_ENHANCE               = "UI_ShipEnhance"                  -- 强化界面入口
UIDef.UI_SNACK_BAR                  = "UI_Snackbar"                     -- Snack消息界面
UIDef.UI_WORLD_MAP                  = "UI_WorldMap"                     -- 世界地图界面
UIDef.UI_BACKPACK                   = "UI_BackPack"                     -- 背包界面
UIDef.UI_LOADING                    = "UI_Loading"                      -- Loading界面
UIDef.UI_LOADING_DIALOG             = "UI_LoadingDialog"                -- LoadingDialog界面
UIDef.UI_COUNTDOWN                  = "UI_Countdown"                    -- 倒计时界面
UIDef.UI_FIVECOUNTDOWN              = "UI_FiveCountDown"                -- 选点倒计时界面
UIDef.UI_OWNED_SHIP                 = "UI_OwnedShip"                    -- 拥有船只界面
UIDef.UI_INTERACTION                = "UI_Interaction"                  -- 交互界面
UIDef.UI_REDEEM_SHIP                = "UI_RedeemShip"                   -- 赎回船只界面
UIDef.UI_DIALOG_MESSAGE             = "UI_DialogMessage"                -- 信息弹窗界面
UIDef.UI_ERROR_DIALOG               = "UI_ErrorDialog"                  -- 错误对话框，优先级最高
-- UIDef.UI_DISCONNECTDIALOG           = "UI_DisconnectDialog"             -- 断线框会被退出游戏框顶掉，所以单加一个窗口
UIDef.UI_RETRY_CONNECT_DIALOG       = "UI_RetryConnectDialog"           -- 断线框会被退出游戏框顶掉，所以单加一个窗口
UIDef.UI_WAIT_CONNECT_DIALOG        = "UI_WaitConnectDialog"            -- 断线菊花界面
UIDef.UI_DIALOG_TRADE               = "UI_DialogTrade"                  -- 交易弹窗界面
UIDef.UI_DIALOG_COST_ITEM           = "UI_DialogCostItem"               -- 材料消耗弹窗界面
UIDef.UI_CHAT_MAIN                  = "UI_ChatMain"                     -- 聊天界面
UIDef.UI_FRIEND_MAIN                = "UI_FriendMain"                   -- 好友主界面
UIDef.UI_TEAMMAIN                   = "UI_TeamMain"                     -- 组队界面
UIDef.UI_TEAM_MAIN_POP_NEARRBY      = "UI_TeamMainPopNearby"            -- 组队附近玩家List界面
UIDef.UI_TEAM_MAIN_POP_INVITE       = "UI_TeamMainPopInvite"            -- 组队邀请玩家List界面
UIDef.UI_TEAM_INVITE_LIST           = "UI_TeamInviteList"               -- 组队队长邀请玩家加入队伍列表界面
UIDef.UI_Player_TIPS                = "UI_PlayerTips"                   -- 玩家个人信息
UIDef.UI_QUEST_WINDOW               = "UI_QuestWindow"                  -- 任务界面
UIDef.UI_TOOL_TIP                   = "UI_ToolTip"                      -- 通用tooltip
UIDef.UI_SHIP_ACCESSORY_BUILD       = "UI_ShipAccessoryBuild"           -- 配件制造
UIDef.UI_SELECT_ACCESSORY_SKILL     = "UI_SelectAccessorySkill"         -- 配件技能选择
UIDef.UI_WORK_SHOP                  = "UI_WorkShop"                     -- 工坊
UIDef.UI_SHIP_CABIN                 = "UI_ShipCabin"                    -- 货仓
UIDef.UI_PRICING_LIST               = "UI_PricingList"                  -- 货物价格清单
UIDef.UI_TRADE                      = "UI_Trade"                        -- 货物交易界面
UIDef.UI_TRADE_TIP                  = "UI_TradeTip"                     -- 货物交易买卖界面
UIDef.UI_TRADE_URGENT               = "UI_TradeUrgent"                  -- 专属贸易
UIDef.UI_TRADE_List                 = "UI_TradeList"                    -- 货物交易列表
UIDef.UI_MAP_TIP                    = "UI_MapTip"                       -- M地图中的对象信息界面
UIDef.UI_OWNED_SHIP_OPTION          = "UI_OwnedShipOption"              -- 船只配置和消耗品
UIDef.UI_BLACKSCREEN                = "UI_BlackScreen"
UIDef.UI_AWARD                      = "UI_Award"                        -- 通用发奖界面
UIDef.UI_PVP_MAIN                   = "UI_PVPMain"                      -- PVP主界面
UIDef.UI_PVP_AWARD                  = "UI_PVPAward"                     -- PVP奖励
UIDef.UI_PVP_MATCH                  = "UI_PVPMatch"                     -- PVP匹配
UIDef.UI_PVP_RANK                   = "UI_PVPRank"                      -- PVP排行榜
UIDef.UI_PVP_VS                     = "UI_PVPVS"                        -- PVP对战信息
UIDef.UI_EMAIL                      = "UI_Email"                        -- 邮件界面
UIDef.UI_BATTLE_RESULT              = "UI_BattleResult"                 -- 结算界面
UIDef.UI_RULE_INTRODUCE             = "UI_RuleIntroduce"                -- 规则说明界面
UIDef.UI_CUSTOMERHELPER             = "UI_CustomerHelper"               -- 客服说明
UIDef.UI_DIALOG_GOODS_FULL          = "UI_DialogGoodsFull"              -- 货仓已满时，无法领取的道具提示窗口
UIDef.UI_QUEST_COMPLETE             = "UI_QuestComplete"                -- 任务完成时提示效果
UIDef.UI_COOP                       = "UI_CoOp"                         -- 任务完成时提示效果
UIDef.UI_GUIDE                      = "UI_Guide"                        -- 新手指引提示
UIDef.UI_COMMON_SUCCESS             = "UI_CommonSuccess"                -- 通用成功界面
UIDef.UI_EXPERIENCE_LEVELUP         = "UI_ExperienceLevelUp"            -- 等级提升界面
UIDef.UI_DEBUG_WIDGET               = "UI_DebugWidget"                  -- 游戏调试面板
UIDef.UI_EQUIPMENT_TIPS             = "UI_EquipmentTips"                -- 新装备提示界面
UIDef.UI_SHOP_TIP                   = "UI_ShopTip"                      -- 商店购买界面
UIDef.UI_WELFARE                    = "UI_Welfare"                      -- 福利窗口
UIDef.UI_ACTIVE_LIVENESS            = "UI_ActiveLiveness"               -- 活跃度窗口
-- UIDef.UI_RECONNECTING               = "UI_Reconnecting"                 -- 断线重连 菊花窗口
UIDef.UI_BOSS_CARD                  = "UI_BossCard"                     -- matinee动画时的boss名字片
UIDef.UI_COUNT_DOWN                 = "UI_DialogCountDown"              -- 单人休闲赛匹配窗口
UIDef.UI_PVP_SINGLE_MATCH           = "UI_PvpSingleMatch"               -- 单人排位赛匹配窗口
UIDef.UI_PVP02                      = "UI_Pvp02"                        -- 竞技场主界面
UIDef.UI_COUNT_DOWN2                = "UI_CountDown2"                   -- 倒计时
UIDef.UI_FACTION_CHANGE             = "UI_FactionChange"                -- 势力更换
UIDef.UI_FACTION_ENTER              = "UI_FactionEnter"                 -- 阵营副本进入界面
UIDef.UI_MATINEE_PANEL              = "UI_MatineePanel"                 -- matinee界面包含跳过按钮
UIDef.UI_SETTING                    = "UI_Setting"                      -- 设置界面
UIDef.UI_CAMERA_SHOT_RESULT         = "UI_CameraShotResult"             -- 拍照结果
UIDef.UI_CHAPTER_NAME               = "UI_ChapterName"                  -- matinee动画时的章节界面
UIDef.UI_REVIVE                     = "UI_Revive"                       -- 副本复活界面
UIDef.UI_BATTLE_REBORN_WAIT         = "UI_BattleRebornWait"             -- 死亡等待界面
UIDef.UI_QUESTION_ACTIVITY          = "UI_QuestionActivity"             -- 答题活动界面
UIDef.UI_QUESTION_RESULT            = "UI_QuestionResult"               -- 答题活动结束结算
UIDef.UI_QUESTION_RANK_AWARD        = "UI_QuestionRankAward"            -- 答题活动排行榜奖励
UIDef.UI_SERVER_COMMON_DIALOG       = "UI_ServerCommonDialog"           -- 服务器控制通用对话框
UIDef.UI_FISHING                    = "UI_Fishing"                      -- 钓鱼界面
UIDef.UI_FISHING_EXCHANGE           = "UI_FishingExchange"              -- 钓鱼兑换界面
UIDef.UI_FISHING_RESULT             = "UI_FishingResult"                -- 钓鱼结束界面
UIDef.UI_BIG_MEAL_ACTIVITY          = "UI_BigMealActivity"              -- 海盗大餐活动
UIDef.UI_MEDIAPLAYER                = "UI_MediaPlayer"                  -- media
UIDef.UI_BATTLE_BEGIN               = "UI_BattleBegin"                  -- 战斗开始
UIDef.UI_BATTLE_STATISTICS_DATA     = "UI_BattleStatisticsData"         -- 战斗统计UI
UIDef.UI_NPC_DIALOG_BOARD           = "UI_NPCDialogBoard"               -- NPC喊话
UIDef.UI_TEST_WND                   = "UI_TestWnd"
UIDef.UI_LETTER_MAIN                = "UI_LetterMain"                  -- 书信界面
UIDef.UI_RUBBING_GAME               = "UI_RubbingGame"                  -- 炭拓印
UIDef.UI_BATTLEGROUND               = "UI_BattleGround"                 -- 战场
UIDef.UI_BATTLEGROUNDSUB            = "UI_BattleGroundSub"              -- 战场
UIDef.UI_BATTLEGROUND_RANK          = "UI_BattleGroundRank"             -- 战场排行榜
UIDef.UI_BATTLEDEADMODE             = "UI_BattleDeadMode"               -- 突然死亡模式
UIDef.UI_JIGSAW_PUZZLE              = "UI_JigsawPuzzle"                 -- 拼图
UIDef.UI_JIGSAW_PUZZLE_TOTURIAL     = "UI_JigsawPuzzleToturial"         -- 拼图教学
UIDef.UI_SATISFACTION               = "UI_Satisfaction"                 -- 问卷调查
UIDef.UI_DRINKINGGAME               = "UI_DrinkingGame"                 -- 拼酒
UIDef.UI_SHIPEQUIP                  = "UI_ShipEquip"                    -- 舰船装备
UIDef.UI_SEVENDAY                   = "UI_SevenDay"                     -- 七日奖励
UIDef.UI_ASSOCIATION                = "UI_Association"                  -- 协会任务面板
UIDef.UI_SHIPMODPART_DECOMPOSE      = "UI_ShipModPartDecompose"         -- 舰船改造零件的分解界面
UIDef.UI_CONTRACT_LETTER            = "UI_ContractLetter"               -- 合约界面
UIDef.UI_MATINEE_INTRODUCTION       = "UI_MatineeIntroduction"          -- matinee 黑屏字幕
UIDef.UI_ACTIVE_LIVENESS_NEW        = "UI_ActiveLivenessNew"            -- 新活跃度界面
UIDef.UI_WAITING                    = "UI_Waiting"                      -- 通用等待网络回包界面
UIDef.UI_TOWN_PORTAL                = "UI_TownPortal"                   -- 快速回城界面
UIDef.UI_SET_PLAYER_NAME            = "UI_SetPlayerName"                -- 新手副本结束后玩家起名，创建角色界面
UIDef.UI_SKIP_GUIDE                 = "UI_SkipGuide"                    -- 跳过新手副本
UIDef.UI_BLACK_MASK                 = "UI_BlackMask"                    -- 新手副本黑屏
UIDef.UI_MATINEE_QTE                = "UI_MatineeQTE"                   -- MatineeQTE
UIDef.UI_EXPLORE                    = "UI_Explore"                      -- 协会探索UI
UIDef.UI_GUILDLIST                  = "UI_GuildList"
UIDef.UI_GUILDCREATE                = "UI_GuildCreate"
UIDef.UI_GUILD                      = "UI_Guild"
UIDef.UI_GUILDREQUESTPLAYERLIST     = "UI_GuildRequestPlayerList"
UIDef.UI_GUILD_INVITE_LIST          = "UI_GuildInviteList"
UIDef.UI_GUILD_PLAYER_TIPS          = "UI_GuildPlayerTips"
UIDef.UI_GUILD_ASSIGN_DUTY          = "UI_GuildAssignDuty"
UIDef.UI_GUILD_ACTIVENESS           = "UI_GuildActiveness"
UIDef.UI_SCHEDULE                   = "UI_Schedule"                     -- 活动界面
UIDef.UP_FFA_BUFF_TIPS              = "UP_FFABuffTips"                  -- 活动界面
UIDef.UI_SCHEDULE_NOOB_LOGIN        = "UI_ScheduleNoobLogin"                -- 新手登录活动
UIDef.UI_SCHEDULE_NOOB_LOGIN_NEXT_DAY = "UI_ScheduleNoobLoginNextDay"
UIDef.UI_SCHEDULE_NOOB_LOGIN_SECOND_DAY = "UI_ScheduleNoobLoginSecondDay"
UIDef.UI_SCHEDULE_CONTINUOUS        = "UI_ScheduleContinuous"           -- 连续登录界面
UIDef.UI_SCHEDULE_CHEST_POP         = "UI_ScheduleChestPop"           -- 宝箱抽奖
UIDef.UI_SCHEDULE_ROULETTE_POP      = "UI_ScheduleRoulettePop"          -- 幸运轮盘推送
UIDef.UI_SCHEDULE_ROULETTE          = "UI_ScheduleRoulette"             -- 幸运轮盘
UIDef.UI_SCHEDULE_SEAADVENTURE      = "UI_ScheduleSeaAdventure"         --航海大冒险
UIDef.UI_SCHEDULE_SEAADVENTURE_POP   = "UI_ScheduleSeaAdventureGoTo"         --航海大冒险推送
UIDef.UI_LOBBY_SCHEDULE_SHOW        = "UI_LobbyScheduleShow"
UIDef.UI_LOBBY_SCHEDULE_QUESTION    = "UI_Question"

UIDef.UI_WORLDBOSS_MAIN             = "UI_WorldBossMain"                -- 世界boss入口界面
UIDef.UI_WORLDBOSS_LEADERBOARD      = "UI_WorldBossLeaderboard"         -- 世界boss伤害排行界面
UIDef.UI_WORLDBOSS_AWARD_PREVIEW    = "UI_WorldBossAwardPreview"        -- 世界boss排行奖励界面
UIDef.UI_MATINEE_TOAST              = "UI_MatineeToast"                 -- matinee toast

UIDef.UI_AUTOTRAVEL_TIP             = "UI_AutoTravelTip"                -- 自动漫游进度提示
UIDef.UI_AUTOTRAVEL_BLACK           = "UI_AutoTravelBlack"              -- 停止渲染黑屏
UIDef.UI_LOADING_NEW                = "UI_LoadingNew"
UIDef.UI_BUILD_ITEM                 = "UI_BuildItem"                    -- 物品建造UI
UIDef.UI_BUILD_ITEM_TIPS            = "UI_BuildItemTips"                -- 物品建造UI的tips
UIDef.UI_BUILD_ITEM_TIPS_NEW        = "UI_BuildItemTipsNew"             -- 新版物品建造UI的tips
UIDef.UI_BUILD_COMMON_ITEM_TIPS     = "UI_BuildCommonItemTips"          -- 建造人装备和舰船武器的tips
UIDef.UI_BUILD_SHIP_PART_TIPS       = "UI_BuildShipPartTips"            -- 建造舰船零件的tips
UIDef.UI_BUILD_SHIP_TIPS            = "UI_BuildShipTips"                -- 建造舰船的tips
UIDef.UI_FFABACKPACK                = "UI_FFABackpack"                  -- 新的背包界面
UIDef.UI_PICKUP_BOX                 = "UI_PickupBox"                    -- 拾取箱子界面
UIDef.UI_PICKUP_ITEM                = "UI_PickupItem"                   -- 拾取掉落物界面
UIDef.UI_PICKUP_EXCHANGE_ITEM       = "UI_PickupExchangeItem"           -- 拾取替换界面
UIDef.UI_FFA_MAIN                   = "UI_FFAMain"                      -- FFA主界面
UIDef.UI_FFA_RESULT                 = "UI_FFAResult"                    -- FFA结算界面
UIDef.UI_FFA_PVP_MAIN               = "UI_FFAPVPMain"                   -- FFA非吃鸡玩法主界面
UIDef.UI_FFA_PVP_DEAD               = "UI_FFAPVPDead"                   -- FFA非吃鸡玩法死亡界面
UIDef.UI_FFA_PVP_RESULT             = "UI_FFAPVPResult"                 -- FFA非吃鸡玩法结算界面
UIDef.UI_FFA_SELECT_BORNPOINT       = "UI_FFASelectBornPoint"           -- FFA选择跳伞点界面
UIDef.UI_LOBBY_SHIP                 = "UI_LobbyShip"                    -- 船备战界面
UIDef.UI_LOBBY_SHIP_DETAIL          = "UI_LobbyShipDetail"              -- 船备战界面
UIDef.UI_SAILOR_MAIN                = "UI_SailorMain"                   -- 水手界面
UIDef.UI_SAILOR_LEVEL_UP_RESULT     = "UI_SailorLevelUpResult"          -- 水手一键升级界面
UIDef.UI_PARTNER_MAIN               = "UI_PartnerMain"                  -- 伙伴界面
UIDef.UI_PARTNER_DETAIL             = "UI_PartnerDetail"                -- 伙伴详情界面
UIDef.UI_PARTNER_SUMMON_RESULT      = "UI_PartnerSummonResult"          -- 伙伴招募结果
UIDef.UI_PARTNER_LEVEL_UP           = "UI_PartnerLevelUp"               -- 伙伴升星
UIDef.UI_LOBBY_BACKPACK             = "UI_LobbyBackpack"                -- 大厅的背包界面
UIDef.UI_LOBBY_AWARD_ITEM           = "UI_LobbyAwardItem"               -- 大厅的获得道具的界面
UIDef.UI_LOBBY_LEVEL_UP_AWARD_ITEM  = "UI_LobbyLevelUpAwardItem"        -- 大厅的升级获得道具的界面
UIDef.UI_LOBBY_AWARD_DISPLAY_SHIP   = "UI_LobbyAwardDisplayShip"
UIDef.UI_LOBBY_AWARD_DISPLAY_FASHION="UI_LobbyAwardDisplayFashion"
UIDef.UI_TEAM_MEMBER_OFFLINE        = "UI_TeamMemberOffline"            -- 副本内队友离线提示界面
UIDef.UI_FFA_BATTLE_RESULT          = "UI_FFABattleResult"              -- 战斗结算界面
UIDef.UI_FFA_BATTLE_STATISTICS      = "UI_FFABattleStatistics"          -- 战斗统计界面
UIDef.UI_FFA_BATTLE_SHARE           = "UI_FFABattleShare"               -- 战斗结算分享截屏界面

UIDef.UI_HOME_MAIN                  = "UI_HomeMain"                     -- 家园主界面
UIDef.UI_HOME_BUILD                 = "UI_HomeBuild"                    -- 家园建造界面
UIDef.UI_HOME_PACK                  = "UI_HomePack"                     -- 家园仓库
UIDef.UI_HOME_PART_RESEARCH         = "UI_HomePartResearch"             -- 家园零件研发
UIDef.UI_HOME_WEAPON_RESEARCH       = "UI_HomeWeaponResearch"           -- 家园武器研发
UIDef.UI_HOME_STYLE                 = "UI_HomeStyle"                    -- 家园风格

UIDef.UI_LOBBY_SHOP                 = "UI_LobbyShop"                    -- 商店界面
UIDef.UI_LOBBY_SHOP_ITEM_PURCHASE   = "UI_LobbyShopItemPurchase"        -- 商城物品购买确认对话框
UIDef.UI_LOBBY_SHOP_GIFTBOX_PURCHASE   = "UI_LobbyShopGiftBoxPurchase"  -- 商城礼包购买确认对话框

UIDef.UI_LOBBY_IAP                  = "UI_LobbyIAP"                     -- 充值界面
UIDef.UI_FIRST_PRIZE                = "UI_FirstPrize"                   -- 首充活动

UIDef.UI_LOBBY_FRIEND               = "UI_LobbyFriend"                  -- 好友界面
UIDef.UI_LOBBY_FRIEND_ADD           = "UI_LobbyFriendAdd"               -- 添加好友界面
UIDef.UI_LOBBY_FRIEND_APPLYLIST     = "UI_LobbyFriendApplyList"         -- 申请好友列表界面
UIDef.UI_LOBBY_FRIEND_BLACKLIST     = "UI_LobbyFriendBlackList"         -- 黑名单界面
UIDef.UI_CAPTAIN                    = "UI_Captain"                      -- 船长界面
UIDef.UI_MAIL                       = "UI_Mail"                         -- 邮箱界面
UIDef.UI_MAIL_TIP                   = "UI_MailTip"                      -- 邮箱界面弹窗

UIDef.UI_PROGRESS_BAR               = "UI_ProgressBar"                  -- 读条弹窗

UIDef.UI_WATCHBATTLE                = "UI_WatchBattle"                  -- 观战界面
UIDef.UI_WATCHBATTLE_RESULT         = "UI_WatchBattleResult"            -- 是否进入观战选择弹窗
UIDef.UI_BOT_WATCH                  = "UI_BotWatch"                     -- bot观战界面

UIDef.UI_LOBBY_TEAM_INVITE          = "UI_LobbyTeamInvite"              -- 大厅组队邀请/申请界面

UIDef.UI_PLAYER_INFO                = "UI_PlayerInfo"                   -- 查看玩家信息

UIDef.UI_SEASON_RANK                = "UI_SeasonRank"                   -- 段位界面
UIDef.UI_SEASON_RANK_ADVANCE        = "UI_SeasonRankAdvance"            -- 段位升级界面
UIDef.UI_SEASON_RECORD              = "UI_SeasonRecord"                 -- 赛季档案
UIDef.UI_SEASON_BATTLEPASS          = "UI_SeasonBattlePass"             -- 赛季通行证界面
UIDef.UI_SEASON_CHALLENGE           = "UI_SeasonChallenge"              -- 赛季任务界面
UIDef.UI_SEASON_BATTLEPASS_ADVANCE  = "UI_SeasonBattlePassAdvance"      -- 赛季通行证界面进阶
UIDef.UI_SEASON_BATTLEUP            = "UI_SeasonBattleUp"               -- 赛季通行证界面进阶成功
UIDef.UI_SEASON_RANKUP              = "UI_SeasonRankUp"                 -- 段位改变界面
UIDef.UI_COMMON_BUTTON_LIST_CONTENT = "UI_CommonButtonListContent"      -- 通用按钮列表Content UI
UIDef.UI_SEASON_SHARE               = "UI_SeasonShare"                  -- 战绩分享
UIDef.UI_SEASON_GO                  = "UI_SeasonGo"                     -- 新赛季开启
UIDef.UI_SEASON_RANK_RESULT         = "UI_SeasonRankResult2"             -- 赛季结算
UIDef.UI_SEASON_BATTLE_TIER_BUY     = "UI_SeasonBattleTierBuy"          -- 购买战阶

UIDef.UI_PLAYER_LEVEL_UP            = "UI_PlayerLevelUp"                -- 通用按钮列表Content UI

UIDef.UI_SYSTEMNOTIFACTION          = "UI_SystemNotifaction"            -- 系统跑马灯
UIDef.UI_TOPMSGNOTIFACTION          = "UI_TopMsgNotifaction"            -- 大喇叭跑马灯

UIDef.UI_SEVEN_DAY                  = "UI_SevenDay"

UIDef.UI_EXIT_GAME_DIALOG           = "UI_ExitGameDialog"               -- 退出游戏对话框
UIDef.UI_SETTING_LAYOUT             = "UI_SettingLayout"                -- 界面布局

UIDef.UI_ADDITIONAL_SUCCESS         = "UI_AdditionalSuccess"            -- 额外胜利选择框
UIDef.UI_REAL_TIME_DEBUG_INFO_LAYER = "UI_RealTimeDebugInfoLayer"       -- 一个用于实时展示Debug信息的UI，如Location
UIDef.UI_PRINT_SCREEN               = "UI_PrintScreen"                   -- 用于显示日志到屏幕上
UIDef.UI_LOGIN_REQUEST_INFO_MASK    = "UI_LoginRequestInfoMask"         -- 登陆界面获取服务器信息的提示界面
UIDef.UI_FFA_BATTLE_DEAD_PLAYBACK   = "UI_FFABattleDeadPlayback"        -- 死亡回放界面
UIDef.UI_BATTLE_WIN_PROMPT          = "UI_BattleWinPrompt"              -- 战斗胜利提示界面

UIDef.UI_SHOP_WELFARE               = "UI_ShopWelfare"                  -- 福利
UIDef.UI_SPEAKER_CONTENT            = "UI_SpeakerContent"               -- 喇叭使用
UIDef.UI_ROSE_SELECT_FRIEND         = "UI_RoseSelectFriend"             -- 鲜花选择好友
UIDef.UI_USE_ROSE                   = "UI_UseRose"                      -- 鲜花使用

UIDef.UI_CROSSHAIRS_DEBUG           = "UI_CrosshairsDebug"              -- 准星距离测试UI

UIDef.UI_ACTIVATION_CODE            = "UI_ActivationCode"               -- 激活码界面
UIDef.UI_LOBBY_MAIN                 = "UI_LobbyMain"                    -- 大厅3d版主界面
UIDef.UI_LOBBY_BOTTOM_MENU          = "UI_LobbyBottomMenu"              -- 大厅界面底部菜单
UIDef.UI_LOBBY_CHAT                 = "UI_LobbyChat"                    -- 大厅聊天界面

UIDef.UI_LOBBY_SHIP_OVERVIEW        = "UI_LobbyShipOverview"            -- 舰船总览
UIDef.UI_LOBBY_SHIP_HULL            = "UI_LobbyShipHull"                -- 船体
UIDef.UI_LOBBY_SHIP_WEAPON          = "UI_LobbyShipWeapon"              -- 武器
UIDef.UI_LOBBY_SHIP_PART            = "UI_LobbyShipPart"                -- 零件
UIDef.UI_LOBBY_SHIP_HANDBOOK        = "UI_LobbyShipHandbook"            -- 图鉴
UIDef.UI_LOBBY_SHOW_SHIP            = "UI_LobbyShowShip"                -- 舰船展示
UIDef.UI_LOBBY_SHOW_SHIP_WEAPON     = "UI_LobbyShowShipWeapon"          -- 船武器展示
UIDef.UI_LOBBY_SHOW_SHIP_PART       = "UI_LobbyShowShipPart"            -- 船零件展示

UIDef.UI_LOBBY_CAPTAIN_DECORATION   = "UI_LobbyCaptainDecoration"       -- 新版本 饰品
UIDef.UI_LOBBY_DECORATION_SHOW      = "UI_DecorationShow"               -- 饰品展示

UIDef.UI_LOBBY_TEAM                 = "UI_LobbyTeam"                    -- 大厅队伍
UIDef.UI_LOBBY_TEAM_LIST            = "UI_LobbyTeamList"                -- 大厅组队列表

UIDef.UI_LOBBY_SAILOR_MAIN          = "UI_LobbySailorMain"              --新水手
UIDef.UI_LOBBY_SAILOR_EQUIPPING     = "UI_LobbySailorEquipping"         --新水手镶嵌
UIDef.UI_LOBBY_SAILOR_BAG           = "UI_LobbySailorBag"              --新水手背包
UIDef.UI_LOBBY_SAILOR_SUMMONING     = "UI_LobbySailorSummoning"        --新兑换



UIDef.UI_LOBBY_CAPTAIN                = "UI_LobbyCaptain"                 --新版船长界面

UIDef.UI_LOBBY_CAPTAIN_VISUAL         = "UI_LobbyCaptainVisual"                 --新新版船长界面


UIDef.UI_LOBBY_HUMAN_FASHION_SHOW     = "UI_LobbyHumanFashionShow"         --人时装展示
UIDef.UI_LOBBY_HUMAN_WEAPON_SHOW      = "UI_LobbyHumanWeaponShow"         --人时装展示

UIDef.UI_EFFECT_CHANGE_DISPLAY        = "UI_EffectChangeDisplay"  --人船切换完成后的界面
UIDef.UI_LOBBY_TEAM_ORDER             = "UI_LobbyTeamOrder"
UIDef.UI_FRIEND_RELATION_LEVELUP      = "UI_LobbyFriendLevelup"
UIDef.UI_FRIEND_RELATION_TIPS         = "UI_RelationInfoTips"
UIDef.UI_LOBBY_BACKPACK_TIPS          = "UI_LobbyBackpackTips"
UIDef.UI_RENAME_PLAYER                = "UI_RenamePlayer"
UIDef.UI_LOBBY_MAIN_DRAG              = "UI_LobbyMainDrag"
UIDef.UI_LOBBY_MATCHMAKING            = "UI_LobbyMatchmaking"




--[[
    Prefab定义
]]
--Debug面板扩展
UIDef.UP_DEBUG_UI_PANEL             = 'UP_DebugUIPanel'                 -- DebugUI面板
UIDef.UP_DEBUG_GM_PANEL             = 'UP_DebugGMPanel'                 -- DebugGM面板
UIDef.UP_DEBUG_GM_INSTANCE_PANEL    = 'UP_DebugGMInstancePanel'         -- DebugGM实例面板
UIDef.UP_DEBUG_SCENE_PANEL          = 'UP_DebugScenePanel'              -- Debug场景面板
UIDef.UP_DEBUG_CUSTOM_PANEL         = 'UP_DebugCustomPanel'             -- Debug自定义面板
UIDef.UP_DEBUG_HUMAN_WEAPON_PANEL   = "UP_DebugHumanWeaponPanel"        -- Debug人武器
UIDef.UP_DEBUG_HUMAN_WEAPON_LIST_ITEM = "UP_DebugHumanWeaponListItem"      -- Debug人武器面板中的每条属性单元
UIDef.UP_DEBUG_SCENE_LIST_ITEM      = "UP_DebugSceneListItem"           -- Debug场景面板列表Item
UIDef.UP_DYNAMIC_DEBUG_SCENE_BUTTON = "UP_DebugSceneDynamicItem"        -- Debug场景面板按钮
UIDef.UP_DEBUG_SHIP_MOVE_SLIDER_CONTROLLER = "UP_DebugShipMoveSliderController"     -- Debug船速面板中的slider item
UIDef.UP_DEBUG_SHIP_MOVE_INPUT_CONTROLLER = "UP_DebugShipMoveInputController"       -- Debug船速面板中的input item

-- 正式UP
UIDef.UP_DIALOG_FRAME               = "UP_DialogFrame"                  -- Dialog框体UI
UIDef.UP_WINDOW_FRAME               = "UP_WindowFrame"                  -- 一般二级UI框体
UIDef.UP_CUTOUT_SCREEN_ADAPTER      = "UP_CutoutScreenAdapter"          -- 异形屏适配框体
UIDef.UP_SERVER_LIST_ITEM           = "UP_ServerListItem"               -- 登录界面右侧服务器列表Item
UIDef.UP_TOAST_ITEM                 = 'UP_ToastItem'                    -- 自动消失的提示Item
--UIDef.UP_SPECIALTOAST_ITEM          = "UP_SpecialToast"                 -- 特殊toast
UIDef.UP_TOAST_GET_ITEM             = "UP_ToastGetItem"
UIDef.UP_TOAST_ITEM_EQUIP           = "UP_ToastItemEquip"               -- 配件或消耗品的装配或卸下的描述
UIDef.UP_RADAR_MAP                  = "UP_RadarMapNormal"
UIDef.UP_RADAR_MAP_NEW              = "UP_RadarMapNew"
UIDef.UP_SHIP_LIST_ITEM             = "UP_ShipListItem"
UIDef.UP_TITLE_BAR                  = "UP_TitleBar"                     -- 通用框架
UIDef.UP_SHIP_PERFORMANCE           = "UP_ShipPerformance"
UIDef.UP_SHIP_PERFORMANCE_ITEM      = "UP_ShipPerformanceItem"
UIDef.UP_SHIP_PERFORMANCE_SUB_ITEM  = "UP_ShipPerformanceSubItem"
UIDef.UP_SHIP_PROPERTY_BAR          = "UP_ShipPropertyBar"
UIDef.UP_SHIP_CATEGORY_FILTER       = "UP_ShipCategoryFilter"
UIDef.UP_SHIP_LIST                  = "UP_ShipList"
UIDef.UP_SHIP_BUILD_LIST_ITEM       = "UP_ShipBuildListItem"
UIDef.UP_SHIP_BUILD_LIST_SUB_ITEM   = "UP_ShipBuildListSubItem"
UIDef.UP_SHIP_NAME_TYPE             = "UP_ShipNameType"
UIDef.UP_SHIP_ENHANCE_TYPE          = "UP_ShipEnhanceType"
UIDef.UP_SHIP_ENHANCE_SUB           = "UP_ShipEnhanceSub"
UIDef.UP_SHIP_BUFF_ITEM             = "UP_ShipBuffItem"                 -- 战斗界面Buff列表Item
UIDef.UP_SHIP_PART_BROKEN_ITEM      = "UP_ShipPartBrokenItem"           -- 战斗部件破损列表Item
UIDef.UP_SHIP_BUFF                  = "UP_ShipBuff"                     -- 战斗界面Buff信息面板
UIDef.UP_WORLD_MAP                  = "UP_WorldMapNormal"
UIDef.UP_WORLD_MAP_NEW              = "UP_WorldMapNew"
UIDef.UP_MAP_OBJ                    = "UP_MapObj"                       -- 地图上显示的对象基类
UIDef.UP_WORLD_MAP_OBJ              = "UP_WorldMapObj"                  -- 世界地图显示的对象
UIDef.UP_MAP_OBJ_PLAYER             = "UP_MapObjForPlayer"              -- 地图上显示的玩家对象
UIDef.UP_MAP_OBJ_AI_NPC             = "UP_MapObjForAINPC"               -- 地图上显示的ai npc对象
UIDef.UP_BATTLE_OCCUPY_01           = "UP_BattleOccupy01"               -- 战斗界面占圈玩法面板
UIDef.UP_BATTLE_OCCUPY_02           = "UP_BattleOccupy02"               -- 战斗界面占圈玩法面板
UIDef.UP_GAME_MODE_COMMON           = "UP_GameModeCommon"               -- 战斗界面通用玩法面板
UIDef.UP_SKILL_BUTTON               = "UP_SkillButton"                  -- 战斗界面需要CD计时的技能按钮
UIDef.UP_SKILL_PANEL                = "UP_SkillPanel"                   -- 战斗界面右下角技能面板
UIDef.UP_BOSS_HP                    = "UP_BossHp"                       -- 战斗界面boos血条
UIDef.UP_MONEY_COST                 = "UP_MoneyCost"                    -- 通用金币银币
UIDef.UP_ITEM_COST                  = "UP_ItemCost"                     -- 通用消耗材料
UIDef.UP_SHIP_SKILL                 = "UP_ShipSkill"
UIDef.UP_SHIP_SKILL_LIST            = "UP_ShipSkillList"
UIDef.UP_SHIP_DETAIL                = "UP_ShipDetail"
UIDef.UP_DIALOG_COMMON              = "UP_DialogCommon"
UIDef.UP_DIALOG_COMMON1             = "UP_DialogCommon1"
UIDef.UP_INTERACTION_QUEST_ITEM     = "UP_InteractionQuestItem"
UIDef.UP_CHAT_MAIN_LIST_ITEM        = "UP_ChatMainListItem"
UIDef.UP_BACK_PACK_ITEM             = "UP_BackPackItem"
UIDef.UP_SHOOT_INFO                 = "UP_ShootInfo"                    -- 战斗界面命中信息面板
UIDef.UP_SHOOT_INFO_ITEM            = "UP_ShootInfoItem"                -- 战斗界面命中信息列表Item
UIDef.UP_CHAT_CONSOLE               = "UP_ChatConsole"
UIDef.UP_TEAM_MAIN_ITEM             = "UP_TeamMainItem"                 -- 组队主界面玩家Item
UIDef.UP_TEAM_MAIN_POP_ITEM         = "UP_TeamMainPopItem"              -- 组队界面List共有列表Item
UIDef.UP_TEAM_MAIN_POP_APPLYFOR_LIST= "UP_TeamPopApplyforList"          -- 组队申请玩家List界面
UIDef.UP_MAIN_LEFT_PANEL            = "UP_MainLeftPanel"                -- 主界面左侧面板
UIDef.UP_MAIN_LEFT_TASK             = "UP_MainLeftTask"                 -- 主界面左侧任务面板
UIDef.UP_MAIN_LEFT_TEAM             = "UP_MainLeftTeam"                 -- 主界面左侧队伍面板
UIDef.UP_MAIN_LEFT_TEAM_ITEM        = "UP_MainLeftTeamItem"             -- 主界面左侧任务列表Item
UIDef.UP_MAIN_CHAT_MINI             = "UP_MainChatMini"                 -- 主界面底部聊天面板
UIDef.UP_MAIN_CHAT_MINI_ITEM        = "UP_MainChatMiniItem"             -- 主界面底部聊天列表Item
UIDef.UP_MAIN_MENU                  = "UP_MainMenu"                     -- 主界面右下角菜单
UIDef.UP_MAIN_PLAYER_INFO           = "UP_MainPlayerInfo"               -- 主界面左上角玩家信息
UIDef.UP_EQUIPMENT_TIPS_ITEM        = "UP_EquipmentTipsItem"            -- 主界面的弹出物品使用框中的物品图标
UIDef.UP_NORMAL_SKILL_TIP           = "UP_NormalSkillTip"
UIDef.UP_EQUIP_ITEM_TIP             = "UP_EquipItemTip"
UIDef.UP_SHOP_ITEM                  = "UP_ShopItem"
UIDef.UP_TEXT_TIPS                  = "UP_TextTips"
UIDef.UP_ITEM_COST_ONE              = "UP_ItemCostOne"
UIDef.UP_BATTLE_OBJECTIVE           = "UP_BattleObjective"
UIDef.UP_MASK_BUTTON                = "UP_MaskButton"
UIDef.UP_PVP_COUNT_DOWN             = "UP_PvpCountDown"
UIDef.UP_PVP_RESULT_RED             = "UP_PvpResultRed"
UIDef.UP_PVP_RESULT_BLUE            = "UP_PvpResultBlue"
UIDef.UP_PVP_SHIP_CATEGORY_COUNT    = "UP_PvpShipCategoryCount"
UIDef.UP_SHIP_EQUIP_TIP_CONTENT     = "UP_ShipEquipTipContent"
UIDef.UP_MATINEE_QTE_AIM            = "UP_MatineeQTEAim"
UIDef.UP_MATINEE_QTE_FIRE           = "UP_MatineeQTEFire"
UIDef.UP_MATINEE_QTE_SAIL           = "UP_MatineeQTESail"
UIDef.UP_LOBBY_BACKPACK_ITEM        = "UP_LobbyBackpackItem"
UIDef.UP_LOBBY_DISPLAY_ITEM         = "UP_LobbyDisplayItem"
UIDef.UP_LOBBY_SHOP_DISPLAY_ITEM    = "UP_LobbyShopDisplayItem"
UIDef.UP_LOBBY_SHOP_DISPLAY_ITEMNEW = "UP_LobbyShopDisplayItemNew"
UIDef.UP_LOBBY_BACKPACK_SUB         = "UP_LobbyBackpackSub"
--UIDef.UP_LOBBY_BACKPACK_TIPS        = "UP_LobbyBackpackTips"
UIDef.UP_LOBBY_ITEM_TIPS            = "UP_LobbyItemTips"
UIDef.UP_COIN_DETAIL_TIPS           = "UP_CoinDetailTips"
UIDef.UP_LOBBY_TEAMING              = "UP_LobbyChatTeaming"
UIDef.UP_RADAR_MAP_WATCH_MATE       = "UP_RadarMapWatchMate"
UIDef.UP_PROGRESS_BAR_WATCH_MATE    = "UP_ProgressbarWatchMate"
UIDef.UP_LOBBY_DISPLAY_ITEM_ASYNC   = "UP_LobbyDisplayItemAsync"
UIDef.UP_PROGRESS_BAR_NEW           = "UP_ProgressBarNew"

--TabButton
UIDef.UP_TAB_BUTTON                 = "UP_TabButton"
UIDef.UP_TAB_BUTTON_NEW             = "UP_TabButtonNew"
UIDef.UP_TAB_BUTTON_HBR             = "UP_TabButtonHbr"
UIDef.UP_TAB_BUTTON_UP_NEW          = "UP_TabButtonUpNew"
UIDef.UP_TAB_BUTTON_RIGHT           = "UP_TabButtonRight"
UIDef.UP_TAB_BUTTON_LOBBY           = "UP_TabButtonLobby"
UIDef.UP_TAB_BUTTON_BUILD_RIGHT     = "UP_TabButtonBuildRight"

--在UI_OwnedShip中使用
UIDef.UP_SHIP_CONFIG                = "UP_ShipConfig"                   -- 船只配置页面包含“消耗品”和“配件”
UIDef.UP_TAB_CONTENT_ACCESSORY      = "UP_TabContentAccessory"          -- 配件页面
UIDef.UP_OWNED_SHIP_BUTTON_LIST     = "UP_OwnedShipButtonList"          -- 配件页面的右侧标签栏
UIDef.UP_TAB_CONTENT_CONSUMABLE     = "UP_TabContentConsumable"         -- 消耗品页面
--在UI_SelectAccessorySkill中使用
UIDef.UP_PASSIVE_SKILL_ITEM         = "UP_PassiveSkillItem"             -- 配件鉴定技能图标
UIDef.UP_EQUIPMENT                  = "UP_Equipment"                    -- 已装配的人物外装
--在UI_ShipAccessoryBuild中使用
UIDef.UP_ACCESSORY_LIST             = "UP_AccessoryList"                -- 配件列表
UIDef.UP_ACCESSORY_BUTTON_LIST_LEFT = "UP_AccessoryButtonListLeft"      -- 配件类型标签
UIDef.UP_ACCESSORY_LIST_ITEM        = "UP_AccessoryListItem"            -- 配件列表Item
UIDef.UP_ITEM_EQUIPPED_LIST         = "UP_ItemEquippedList"             -- 已装配的配件消耗品的列表
UIDef.UP_ITEM_EQUIPPED              = "UP_ItemEquipped"                 -- 已装配的配件消耗品的格子
UIDef.UP_PASSIVE_SKILL_LIST         = "UP_PassiveSkillList"             -- 可鉴定的技能
UIDef.UP_WORK_SHOP_ITEM             = "UP_WorkShopItem"                 -- 工坊生产线
UIDef.UP_WORK_SHOP_GRID_ITEM        = "UP_WorkShopGridItem"             -- 工坊生产线输入输出格子
UIDef.UP_SHIP_CABIN_ITEM            = "UP_ShipCabinItem"                -- 船货仓格子
UIDef.UP_QUEST_AWARD_ITEM           = "UP_QuestAwardItem"               -- 任务奖励Tip
UIDef.UP_ITEM_GRID_BASE             = "UP_ItemGridBase"                 -- 道具格子
UIDef.UP_TRADE_CARGO                = "UP_TradeCargo"                   -- 交易物品tip
UIDef.UP_NPC_HEAD_INFO              = "UP_NpcHeadInfo"                  -- 交易物品tip
UIDef.UP_CHAT_ITEM                  = "UP_ChatItem"                     -- 聊天输入物品tip
UIDef.UP_NAME_WIDGET                = "UP_NameWidget"
UIDef.UP_QUEST_WIDGET               = "UP_QuestWidget"
UIDef.UP_FACTION_WIDGET             = "UP_FactionWidget"
UIDef.UP_DIALOG_WIDGET              = "UP_DialogWidget"
UIDef.UP_NPC_HEAD_ICON_WIDGET       = "UP_NpcHeadIconWidget"
UIDef.UP_BATTLE_HEAD_INFO           = "UP_BattleHeadInfo"
UIDef.UP_PVP_VS                     = "UP_PvpVS"
UIDef.UP_PVP_VS_BLUE_ITEM           = "UP_PvpBlueItem"
UIDef.UP_PVP_VS_RED_ITEM            = "UP_PvpRedItem"
UIDef.UP_PORT_LIST                  = "UP_PortList"
UIDef.UP_AutoRoad                   = "UP_AutoRoad"
UIDef.UP_VIRTUAL_JOYSTICK           = "UP_VirtualJoystick"              -- 虚拟摇杆
UIDef.UP_SHIP_DROP_ITEM             = "UP_ShipDropItem"                 -- 战斗中冒血数字及其他身上掉落UI
UIDef.UP_DYNAMIC_DEBUG_BUTTON       = "UP_DynamicDebugButton"           -- 动态创建的调试按钮
--在Welfare界面中使用
UIDef.UP_WELFARE_SIGN_SUB01         = "UP_WelfareSignSub01"             -- 签到奖励道具
UIDef.UP_WELFARE_SIGN_SUB02         = "UP_WelfareSignSub02"             -- 累计签到奖励道具
UIDef.UP_WELFARE_GET_BACK           = "UP_WelfareGetBack"               -- 福利找回
UIDef.UP_WELFARE_GET_BACK_LIST_ITEM = "UP_WelfareGetBackListItem"       -- 福利找回的一行
--答题活动
UIDef.UP_QUESTION_SUB               = "UP_QuestionSub"
UIDef.UP_QUESTION_PLAYER_ANSWER_SUB = "UP_QuestionPlayerAnswerSub"
UIDef.UP_QUESTION_PLAYER_RANK_SUB   = "UP_QuestionPlayerRankSub"
UIDef.UP_QUESTION_RANK_AWARD_SUB    = "UP_QuestionRankAwardSub"
UIDef.UP_SELECT_ROLE                = "UP_SelectRole"

UIDef.UP_CAMERA_SHOT                = "UP_CameraShot"
UIDef.UP_BATTLEGROUND               = "UP_BattleGround"
UIDef.UP_BATTLEFLAGTIP              = "UP_BattleFlagTip"


UIDef.UP_HUBBUFF_TIP                = "UP_HubBuffTip"
--[[
    Widget定义
]]
UIDef.UW_SHIP_HEAD_INFO             = "UW_ShipHeadInfo"
UIDef.UW_SHIP_DROP_INFO             = "UW_ShipDropInfo"
UIDef.UW_HEAD_INFO                  = "UW_HeadInfo"
UIDef.UW_MVP                        = "UW_MVP"
UIDef.UW_LOBBY_CHAT_BUBBLE          = "UW_LobbyChatBubble"


UIDef.UP_FACTION_ITEM               = "UP_FactionItem"
UIDef.UP_FACTION_PLAYER_ITEM        = "UP_FactionPlayerItem"
UIDef.UP_FACTION_TIPS               = "UP_FactionTips"

-- 活动
UIDef.UP_SCHEDULE_CATEGORY          = "UP_ScheduleCategory"             -- 活动目录
-- UIDef.UP_SCHEDULE_TAB_FIXED_AWARD   = "UP_ScheduleTabFixedAward"
-- UIDef.UP_SCHEDULE_TAB_SEVEN_DAY     = "UP_ScheduleTabSevenDay"
-- UIDef.UP_SCHEDULE_TAB_COMMON        = "UP_ScheduleTabCommon"
-- UIDef.UP_SCHEDULE_TAB_BATTLE_STAR   = "UP_ScheduleTabBattleStar"
-- UIDef.UP_SCHEDULE_TAB_CONTINUOUS    = "UP_ScheduleTabContinuous"
-- UIDef.UP_SCHEDULE_TAB_ROULETTE      = "UP_ScheduleTabRoulette"
-- UIDef.UP_SCHEDULE_TAB_CHEST         = "UP_ScheduleTabChest"
-- UIDef.UP_SCHEDULE_TAB_SEA_ADVENTURE = "UP_ScheduleTabSeaAdventure"
-- UIDef.UP_SCHEDULE_TAB_QUESTION      = "UP_ScheduleTabQuestion"

-- 钓鱼活动
UIDef.UP_FISHING_BAIT               = "UP_FishingBait"                  -- 鱼饵
UIDef.UP_FISHING_EXCHANGE           = "UP_FishingExchange"              -- 钓鱼兑换

UIDef.UP_DRINKING_BUTTON            = "UP_DrinkingButton"


UIDef.UP_EQUIP_ITEM_GRID            = "UP_EquipItemGrid"                -- 装备格子

UIDef.UP_SHIP_MOD_PART_TIP          = "UP_ShipModPartTip"

UIDef.UP_BATTLE_RESULT_DAMAGE_ITEM  = "UP_BattleResultDetailDamageItem"

-- 世界boss
UIDef.UP_WORLDBOSS_LEADERBOARD_ITEM  = "UP_WorldBossLeaderboardItem"
UIDef.UP_WORLDBOSS_AWARD_PREVIEW_ITEM  = "UP_WorldBossAwardPreviewItem"

UIDef.UP_CARRONADE_EFFECT           = "UP_CarronadeEffect"
UIDef.UP_SHIP_WEAPON_PANEL          = "UP_ShipWeaponPanel"
UIDef.UP_SHIP_WEAPON_SLOT           = "UP_ShipWeaponSlot"
UIDef.UP_SHIP_WEAPON_CANNON         = "UP_ShipWeaponCannon"

-- FFA Map Operation
UIDef.UP_MAP_OBJ_FOR_GO_PATH   = "UP_MapObjForGOPath"
UIDef.UP_MAP_OBJ_FOR_SPECIAL_GO = "UP_MapObjForSpecialGO"

UIDef.UP_WEAPON_ATTACHEMENT_ITEM    = "UP_WeaponAttachementItem"
UIDef.UP_SHIP_PART_ITEM    = "UP_ShipPart"
UIDef.UP_WEAPON_SLOT    = "UP_WeaponSlot"
UIDef.UP_BATTLE_ITEM_LISTITEM  = "UP_BattleItemListItem"
UIDef.UP_PICKUP_ITEM = "UP_PickupItem"
UIDef.UP_PICKUP_LIST_ITEM = "UP_PickupListItem"
UIDef.UP_PICKUP_EXCHANGE_ITEM = "UP_PickupExchangeItem"
UIDef.UP_HUMAN_VIRTUALSTICK = "UP_HumanVirtualJoystick"

UIDef.UP_SHIP_VIRTUALSTICK = "UP_ShipVirtualJoystick"
UIDef.UP_HUMAN_WEAPON_SLOT    = "UP_HumanWeaponSlot"
UIDef.UP_HUMAN_WEAPON_SLOT_IN_MAIN    = "UP_HumanWeaponSlotInMain"
UIDef.UP_HUMAN_WEAPON_ATTACHMENT_SLOT    = "UP_HumanWeaponAttachmentSlot"
UIDef.UP_HUMAN_ITEM_IN_PACKAGE_LIST    = "UP_HumanItemInPackageList"
UIDef.UP_MATERIAL_ITEM_IN_PACKAGE_LIST = "UP_MaterialItemInPackageList"
UIDef.UP_HUMAN_ARMOR_SLOT    = "UP_HumanArmorSlot"
UIDef.UP_HUMAN_ARMOR_SLOT_IN_MAIN    = "UP_HumanArmorSlotInMain"
UIDef.UP_HUMAN_BAG_SLOT    = "UP_HumanBagSlot"
UIDef.UP_LISTENSOUND = "UP_ListenSound"

UIDef.UP_ITEM_DETAIL_IN_PACKAGE = "UP_ItemDetailInPackage"
UIDef.UP_PACKAGE_DISCARD_PART = "UP_PackageDicardPart"
UIDef.UP_HUMAN_SHORTCUT_IN_MAIN = "UP_HumanShortcutInMain"
UIDef.UP_BTN_IMG_GRID = "UP_BtnImgGrid"
UIDef.UP_PROGRESS_BAR_BOOM = "UP_ProgressBarBoom"

-- FFA Ship Building
UIDef.UP_SHIP_ITEM = "UP_ShipItem"
UIDef.UP_SELF_SHIP = "UP_SelfShip"
UIDef.UP_BUILDING_MATERIALS = "UP_BuildingMaterials"
UIDef.UP_BUILDING_COST_MATERIALS = "UP_BuildingCostMaterials"
UIDef.UP_BUILDING_MATERIAL = "UP_BuildingMaterial"
UIDef.UP_BUILD_SHIP_WEAPON_SLOT = "UP_BuildShipWeaponSlot"
UIDef.UP_BUILD_SHIP_PART_SLOT = "UP_BuildShipPartSlot"
UIDef.UP_BUILD_SHIP_WEAPON_ITEM = "UP_BuildShipWeaponItem"
UIDef.UP_BUILD_SHIP_PART_ITEM = "UP_BuildShipPartItem"
UIDef.UP_BUILD_SHIP_CONTENT_SUB = "UP_BuildShipContentSub"
UIDef.UP_BUILD_SHIP_SKILL = "UP_BuildShipSkill"

-- FFA Item Building
UIDef.UP_BUILD_SHIP_ITEM = "UP_BuildShipItem"
UIDef.UP_BUILD_ITEM = "UP_BuildItem"
UIDef.UP_BUILD_ITEM_TIPS = "UP_BuildItemTips"
UIDef.UP_BUILD_ITEM_TIPS_NEW = "UP_BuildItemTipsNew"
UIDef.UP_QUICK_BUILD_ITEM = "UP_QuickBuildItem"
UIDef.UP_BUILD_SHIP_TIPS = "UP_BuildShipTips"
UIDef.UP_BUILD_SHIP_TIPS_NEW = "UP_BuildShipTipsNew"

UIDef.UP_COMPASS_ITEM = "UP_FFACompassItem"
UIDef.UP_SHORTCUT_MENU_ITEM = "UP_ShortcutMenuItem"
UIDef.UP_MAP_OBJ_FOR_FFA_STATIC_POINT = "UP_MapObjForFFAStaticPoint"
UIDef.UP_FFA_BUFF_ITEM = "UP_FFABuffItem"

UIDef.UP_PVP_RADAR_MAP = "UP_PVPRadarMap"
UIDef.UP_ATTACK_WARNING_ITEM = "UP_AttackWarningItem"
UIDef.UP_FFA_SELECTPOINT_MAP = "UP_FFASelectPointMap"
UIDef.UP_MAP_OBJ_FOR_BORN_POINT = "UP_MapObjForBornPoint"
UIDef.UP_MAP_OBJ_FOR_SELF_BORN_POINT = "UP_MapObjForSelfBornPoint"
UIDef.UP_MAP_OBJ_FOR_TRANSPORTER_PATH_NODE = "UP_MapObjForTransporterPathNode"
UIDef.UP_FFA_SELECTBORN_SUB = "UP_FFASelectBornSub"
UIDef.UP_FFATRANSPORTNEW = "UP_FFATransportNew"

UIDef.UP_TEAM_HEAD_NAME = "UP_TeamHeadName"
UIDef.UP_MAP_OBJ_FOR_FFA_TEAM_MEMBER = "UP_MapObjForFFATeamMember"
UIDef.UP_MAP_OBJ_FOR_FFA_FLAG_INFO = "UP_FFAFlagInfo"
UIDef.UP_MAP_OBJ_FOR_FFA_FLAG_POINT = "UP_FFAFlagPoint"
UIDef.UP_MAP_OBJ_FOR_CORE_AREA = "UP_MapCoreAreaObj"

-- 水手相关UP
UIDef.UP_SAILOR_EQUIPPING               = "UP_SailorEquipping"
UIDef.UP_SAILOR_BAG                     = "UP_SailorBag"
UIDef.UP_SAILOR_SUMMONING               = "UP_SailorSummoning"
UIDef.UP_SAILOR_PROPERTY_ITEM           = "UP_SailorPropertyItem"
UIDef.UP_SAILOR_UP_LEVEL_PROPERTY_ITEM  = "UP_SailorUpLevelPropertyItem"
UIDef.UP_SAILOR_BAG_ITEM                = "UP_SailorBagItem"
UIDef.UP_SAILOR_MINI_BAG_ITEM           = "UP_SailorMiniBagItem"
UIDef.UP_SAILOR_DETAIL_ITEM             = "UP_SailorDetailItem"
UIDef.UP_SAILOR_UP_LEVEL_ALL            = "UP_SailorUpLevelAll"
UIDef.UP_SAILOR_UP_LEVEL_SINGLE         = "UP_SailorUpLevelSingle"

-- 伙伴相关UP
UIDef.UP_PARTNER_EQUIPPING              = "UP_PartnerEquipping"
UIDef.UP_PARTNER_BAG                    = "UP_PartnerBag"
UIDef.UP_PARTNER_SUMMONING              = "UP_PartnerSummoning"
UIDef.UP_PARTNER_EQUIPPING_ITEM         = "UP_PartnerEquippingItem"
UIDef.UP_PARTNER_MINI_ITEM              = "UP_PartnerMiniItem"
UIDef.UP_PARTNER_LEVEL_UP_ITEM          = "UP_PartnerLevelUpItem"
UIDef.UP_PARTNER_SUMMON_RESULT_ITEM     = "UP_PartnerSummonResultItem"
UIDef.UP_PARTNER_SKIN_ITEM              = "UP_PartnerSkinItem"
UIDef.UP_PARTNER_SKILL_TIPS             = "UP_PartnerSkillTips"
UIDef.UP_PARTNER_WEAPON_TIPS            = "UP_PartnerWeaponTips"
UIDef.UP_PARTNER_RELATION_ITEM          = "UP_PartnerRelationItem"
UIDef.UP_PARTNER_RELATION_TIPS          = "UP_PartnerRelationTips"

-- 船备战相关UP
UIDef.UP_LOBBY_SHIP_EQUIPPING           = "UP_LobbyShipEquipping"
UIDef.UP_LOBBY_SHIP_HANDBOOK            = "UP_LobbyShipHandbook"
UIDef.UP_LOBBY_SHIP_PART                = "UP_LobbyShipPart"
UIDef.UP_LOBBY_SHIP_WEAPON              = "UP_LobbyShipWeapon"
UIDef.UP_LOBBY_SHIP_PART_ITEM           = "UP_LobbyShipPartItem"
UIDef.UP_LOBBY_SHIP_EQUIPPING_ITEM      = "UP_LobbyShipEquippingItem"
UIDef.UP_LOBBY_SHIP_MINI_ITEM           = "UP_LobbyShipMiniItem"
UIDef.UP_LOBBY_SHIP_PART_DETAIL_ITEM    = "UP_LobbyShipPartDetailItem"
UIDef.UP_LOBBY_SHIP_HANDBOOK_ITEM       = "UP_LobbyShipHandbookItem"
UIDef.UP_LOBBY_SHIP_WEAPON_CATEGORY_ITEM= "UP_LobbyShipWeaponCategoryItem"
UIDef.UP_LOBBY_SHIP_WEAPON_ITEM         = "UP_LobbyShipWeaponItem"
UIDef.UP_LOBBY_SHIP_SKIN_ITEM           = "UP_LobbyShipSkinItem"
-- 新舰船界面
UIDef.UP_LOBBY_SHIP_COMMON_ITEM         = "UP_LobbyShipCommonItem"

-- 家园相关UP
UIDef.UP_HOME_BUILDING_SUB              = "UP_HomeBuildingSub"
UIDef.UP_HOME_BLOCK_SUB                 = "UP_HomeBlockSub"
UIDef.UP_HOME_DECORATION_ITEM           = "UP_DecorationItem"
UIDef.UP_HOME_PACK_SUB                  = "UP_HomePackSub"
UIDef.UP_HOME_ITEM_EXCHANGE             = "UP_HomeItemExchange"
UIDef.UP_HOME_EXCHANGE_TIPS             = "UP_HomeExchangeTips"
UIDef.UP_HOME_BLOCK_REMOVE_BUIDING_VIEW = "UP_HomeBlockRemoveBuildingView"
UIDef.UP_HOME_RESEARCH_SUB              = "UP_HomeResearchSub"
UIDef.UP_HOME_SHIP_PART_ITEM            = "UP_HomeShipPartItem"
UIDef.UP_HOME_STYLE_LIST_ITEM           = "UP_HomeStyleListItem"
UIDef.UP_HOME_RESEARCH_SHIP_WEAPON_ITEM = "UP_HomeResearchShipWeaponItem"
UIDef.UP_HOME_SHIP_WEAPON_ITEM          = "UP_HomeShipWeaponItem"

-- 商店相关UP
UIDef.UP_LOBBY_SHOP_ITEM                = "UP_LobbyShopItem"
UIDef.UP_LOBBY_IAP_ITEM                 = "UP_LobbyIAPItem"
UIDef.UP_LOBBY_SHOP_ITEM2               = "UP_LobbyShopItem2"

UIDef.UP_PLAYHEAD = "UP_PlayHead"

--CustomeTip的固定名称，不对应相应wnd名
UIDef.UP_CUSTOM_TIP = "UP_CUSTOM_TIP"

--CommonViewButton Type
UIDef.UP_COMMONVIEWBUTTON = "UP_CommonViewButton"
UIDef.UP_COMMONBUTTONLIST = "UP_CommonButtonList"

--吃鸡副本半屏ui
UIDef.FFA_HALF_SCREEN =
{
    [UIDef.UI_WORLD_MAP] = true,
    [UIDef.UI_PICKUP_BOX] = true,
    [UIDef.UI_PICKUP_ITEM] = true,
    [UIDef.UI_FFABACKPACK] = true,
    [UIDef.UI_TOAST_BOARD] = true,
    [UIDef.UI_SPECIAL_TOAST_BOARD] = true,
    [UIDef.UI_GUIDE] = true,

}

UIDef.UP_CAPTAIN_LIST_ITEM    = "UP_CaptainListItem"
UIDef.UP_CAPTAIN_SUB_TAB      = "UP_CaptainSubTab"

UIDef.UP_MAIL_LIST_ITEM      = "UP_MailListItem"

UIDef.UP_SEASON_BATTLETIER              = "UP_SeasonBattleTier"
UIDef.UP_SEASON_BATTLETIER_LISTITEM     = "UP_SeasonBattleTierListItem"
UIDef.UP_SEASON_BATTLETIER_REWARDITEM   = "UP_SeasonBattleTierRewardItem"
-- UIDef.UP_SEASON_CHALLENGE               = "UP_SeasonChallenge"
UIDef.UP_SEASON_CHALLENGE_TASKITEM      = "UP_SeasonChallengeTaskItem"
UIDef.UP_SEASON_CHALLENGE_WEAKTASKITEM  = "UP_SeasonChallengeWeakTaskItem"
UIDef.UP_SEASON_RANK                    = "UP_SeasonRank"
UIDef.UP_SEASON_RANK_RECORD             = "UP_SeasonRankRecord"
UIDef.UP_SEASON_RECORD_LISTITEM         = "UP_SeasonRecordListItem"
UIDef.UP_SEASON_BUY_BATTLETIER          = "UP_SeasonBuyBattleTier"          -- 赛季购买战阶
UIDef.UP_SEASON_TIPS                    = "UP_SeasonTips"
UIDef.UP_SEASON_RANK_MODE               = "UP_SeasonRankMode"
UIDef.UP_SEASON_AWARD_DESC              = "UP_SeasonAwardDesc"
UIDef.UP_SEASON_BATTLE_PASS_AWARD       = "UP_SeasonBattlePassAward"

UIDef.UP_PLAYER_SEASON_STAR             = "UP_PlayerSeasonStar"
UIDef.UP_PLAYER_SEASON                  = "UP_PlayerSeason"
UIDef.UP_FFA_SETTING                    = "UP_FFASetting"

UIDef.UP_LOBBY_ITEM_SUB                 = "UP_LobbyItemSub"

UIDef.UP_POP_MENU                       = "UP_PopMenu"
UIDef.UP_POP_MENU_ITEM                  = "UP_PopMenuItem"

UIDef.UP_PLAYER_BASIC_INFO              = "UP_PlayerBasicInfo"
UIDef.UP_PLAYER_RECENT_GAME_SCORE       = "UP_PlayerRecentGameScore"
UIDef.UP_PLAYER_SCORE_STATISTIC         = "UP_PlayerScoreStatistic"

UIDef.CHAT_TAB_TYPE =
{
    ETabValid        = 0,
    ETabQuickMsg     = 1,
    ETabHistory      = 2,
    ETabFriends      = 3,
    ETabWatch        = 4,
    ETabFriendsMsg   = 5,
    ETabQuickView    = 6,
}

UIDef.UP_LANDMARK_UPGRADE_VIEW                        = "UP_LandmarkUpgradeView"
UIDef.UP_LANDMARK_UPGRADE_UNLOCK_CONTENT_ITEM         = "UP_LandmarkUpgradeUnlockContentItem"

UIDef.UP_MAP_OBJ_FOR_BOT = "UP_MapObjForBot"
UIDef.UP_MAP_OBJ_FOR_BOT_POINT = "UP_MapObjForBotPoint"

UIDef.UP_NPC_HEAD_NAME = "UP_NPCNameWidget"
UIDef.UP_HOMELAND_RADAR_MAP = "UP_HomelandRadarMap"

UIDef.UP_SEVENDAY_SUB_NORMAL = "UP_SevenDaySubNormal"
UIDef.UP_SEVENDAY_SUB_SPECIAL = "UP_SevenDaySubSpecial"

UIDef.UP_SETTING_PICKUP_SUB = "UP_SettingPickUpSub"
UIDef.UP_LAYOUT_HUMAN = "UP_LayoutHuman"
UIDef.UP_LAYOUT_SHIP = "UP_LayoutShip"
UIDef.UP_LAYOUT_SHIP_JOYSTICK = "UP_LayoutShipJoystick"
UIDef.UP_LAYOUT_VEHICLE = "UP_LayoutVehicle"
UIDef.UP_LAYOUT_VEHICLE_JOYSTICK = "UP_LayoutVehicleJoystick"
UIDef.UP_SETTING_USE_SUB = "UP_SettingUseSub"
UIDef.UP_LAYOUT_SAVE_TIP = "UP_LayoutSaveTip"
UIDef.UP_LAYOUT_STYLE_TIP = "UP_LayoutStyleTip"

UIDef.UP_SCHEDULE_NOOB_LOGIN = "UP_ScheduleNoobLogin"
UIDef.UP_SCHEDULE_CONTINUOUS = "UP_ScheduleContinuous"
UIDef.UP_SEA_ADVENTURE_TILE = "UP_SeaAdventureTile"
UIDef.UP_SEA_ADVENTURE_REWARD = "UP_SeaAdventureReward"
UIDef.UP_SEA_ADVENTURE_INFO = "UP_SeaAdventureTips"


UIDef.UP_ANNOUNCEMENT = "UP_Announcement"
UIDef.UP_DIALOG_COUNTDOWN = "UP_DialogCountdown"
UIDef.UP_PLAYER_HEAD_HP = "UP_PlayerHeadHp"

UIDef.UP_FLOAT_NUM_CONTAINER = "UP_FloatNumContainer"
UIDef.UP_FLOAT_NUM = "UP_FloatNum"
UIDef.UP_FLOAT_DAMAGE_INFO = "UP_FloatDamageInfo"

UIDef.UP_ITEM_BUFF_PANEL = "UP_ItemBuffPanel"
UIDef.UP_ITEM_BUFF = "UP_ItemBuff"
UIDef.UP_SHOP_WELFARE_ITEM = "UP_ShopWelfareItem"


--引导相关
UIDef.UP_CIRCLE_CLICK_EFFECT    =   "UP_Guide_CycleClickGlow"
UIDef.UP_SQUARE_CLICK_EFFECT    =   "UP_Guide_SquareClickGlow"
UIDef.UP_RADAR_CLICK_EFFECT     =   "UP_Guide_RadarMapGlow"
UIDef.UP_GUIDE_SHIPTURN_EFFECT  =   "UP_Guide_ShipTurn_Glow"
UIDef.UP_GUIDETIPS              =   "UP_GuideTips"

UIDef.UP_BOT_HUMAN_WEAPON_SLOT_IN_MAIN = "UP_BotHumanWeaponSlotInMain"
UIDef.UP_BOT_SHIP_WEAPON_SLOT = "UP_BotShipWeaponSlot"
UIDef.UP_BOT_BUILDING_MATERIALS = "UP_BotBuildingMaterials"
UIDef.UP_BOT_BUILD_MATERIAL = "UP_BotBuildMaterial"
UIDef.UP_BOT_HUMAN_ARMOR_SLOT_IN_MAIN = "UP_BotHumanArmorSlotInMain"
UIDef.UP_BOT_FAKE_JOYSTICK = "UP_BotFakeVirtualJoystick"
UIDef.UP_BOT_SHIP_ARMOR_SLOT_IN_MAIN = "UP_BotShipArmorSlotInMain"
UIDef.UP_MAP_OBJ_PORT_MARK = "UP_MapObjPortMark"

--创建角色
UIDef.UP_CREATE_ROLE_FACE_ITEM    = "UP_CreateRoleFaceItem"
UIDef.UP_CREATE_ROLE_HAIR_ITEM    = "UP_CreateRoleHairItem"
UIDef.UP_CREATE_ROLE_COLOR_ITEM   = "UP_CreateRoleColorItem"
UIDef.UP_CREATE_ROLE_COSTUME_ITEM = "UP_CreateRoleCostumeItem"

UIDef.UP_DECORATION_LIST_ITEM = "UP_DecorationListItem"
UIDef.UP_CAPTAIN_ITEM_INFO = "UP_CaptainItemInfo"

UIDef.UP_LOBBY_TEAM_POP_MENU_ITEM = "UP_PopMenuItem"
UIDef.UP_LOBBY_SAILOR_SLOT_ITEM = "UP_LobbySailorSlotItem"
UIDef.UP_LOBBY_SAILOR_SINGLE_INFO = "UP_LobbySailorSingleInfo"


UIDef.UP_LOBBY_CAPTAIN_WEAPON_DESC_ITEM     = "UP_LobbyCaptainWeaponDescItem"

UIDef.UP_FRIEND_PLAY_TOGETHER = "UP_FriendPlayTogether"
UIDef.UP_FRIEND_ACCEPT_ORDER = "UP_FriendAcceptOrder"

UIDef.UP_LOBBY_CAPTAIN_PICKER_ITEM          =  "UP_LobbyCaptainAvatarNew"

UIDef.UP_POINT_TIP  = "UP_PointTip"
UIDef.UP_TWO_EXP = "UP_TwoExp"
return UIDef
