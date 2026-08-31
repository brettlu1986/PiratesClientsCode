
local ClientEventDef = {}
-- Common消息从1000 - 9999
-- Client消息从10000 - 49999
-- Server消息从50000 - 99999

local nNextEventId = 10000
local function Define(szEventName)
    ClientEventDef[szEventName] = nNextEventId
    nNextEventId = nNextEventId + 1
end

function ClientEventDef.Init()
    Define("EV_CONNECTED")
    Define("EV_DISCONNECTED")
    Define("EV_RECONNECTED")
    -- Define("EV_BATTLE_DISCONNECTED")
    Define("EV_BATTLE_TIMEOUT")

    Define("EV_PRE_LOAD_MAP")
    Define("EV_POST_LOAD_MAP")

    Define("EV_ENTER_PROCEDURE_WILD")
    Define("EV_LEAVE_PROCEDURE_WILD")
    Define("EV_ENTER_PROCEDURE_BATTLE")
    Define("EV_LEAVE_PROCEDURE_BATTLE")
    Define("EV_ENTER_PROCEDURE_LOBBY")
    Define("EV_LEAVE_PROCEDURE_LOBBY")
    Define("EV_ON_WAITING_DUNGEON")

    Define("EV_LOBBY_READY")
    Define("EV_HOMELAND_READY")

    Define("EV_NEW_GAME_DAY")
    Define("EV_ENTER_DUNGEON")
    -- Mock
    --Define("EV_TRY_MOCK_CLIENT_PLAYER_DATA")

    -- 在切地图时GamePlayerSelf不会销毁，但其用到的UEActor可能会被销毁
    -- 此消息是GamePlayerSelf的UEActor准备好时会发送，地图切换完毕后都会触发
    Define("EV_PLAYERSELF_READY")
    Define("EV_PLAYERSELF_UNREADY")
    Define("EV_HUB_LOGIN_REPLY")
    --Define("EV_CLIENT_RESTART")
    Define("EV_GAME_OBJECT_BEGIN_PLAY")
    Define("EV_GAME_OBJECT_BEGIN_DESTROY")

    -- UI
    Define("EV_ON_SVR_OPEN_UI")
    Define("EV_ON_SVR_CLOSE_UI")
    Define("EV_UI_LOGIN")
    Define("EV_UI_SELECT_SEX_AVATAR")
    Define("EV_UI_SELECT_ROLE_BACK")
    Define("EV_UI_CREATE_ROLE_BACK")
    Define("EV_UI_CREATE_ROLE_ACTOR")
    Define("EV_UI_ROLE_SKIP_GUIDE")
    Define("EV_UI_LOBBY_RESET")
    Define("EV_UI_LOBBY_CLOSE_AVG")
    Define("EV_UI_LOBBY_REFRESH_AVG")
    Define("EV_UI_ENTER_GAME")
    Define("EV_UI_ENTER_GAME_FAILED")
    Define("EV_UI_DELETE_ROLE")
    Define("EV_UI_SELETE_ROLE")
    Define("EV_ON_ENTER_GAME_ERROR")
    Define("EV_ON_CREATE_PLAYER_ERROR")
    Define("EV_ON_LOGIN_ERROR")
    Define("EV_UI_ROTATER_AVATAR_CREATE_ROLE")
    Define("EV_UI_ZOOM_AVATAR_CREATE_ROLE")
    Define("EV_UI_ROTATER_AVATAR_SELECT_ROLE")
    Define("EV_UI_ZOOM_AVATAR_SELECT_ROLE")
    Define("EV_MATCHMAKING_RESULT")
    Define("EV_CANCEL_MATCHMAKING")
    Define("EV_MATCHMAKING_OPEN_TIME")
    Define("EV_UI_GUIDE_ACTIVATE")
    Define("EV_UI_SELECT_POINT_BTN")
    Define("EV_UI_GUIDE_BEGIN_STEP")
    Define("EV_UI_GUIDE_END_STEP")
    Define("EV_UI_ITEMPANEL_LIST_EXPANDED")
    Define("EV_UI_ITEMPANEL_LIST_ARROW_BTN_CLICKED")
    Define("EV_UI_BATTLE_COMMAND_LIST_VISIBLE_CHANGED")
    Define("EV_UI_DEACTIVE")
    Define("EV_UI_GUIDE_ON_INVITE")
    Define("EV_UI_GUIDE_ON_SHOW_CHAT")
    Define("EV_UI_SETTINGLAYOUT_OPEN")
    Define("EV_UI_SETTINGLAYOUT_CLOSE")
    Define("EV_UI_GUIDE_ON_BATTLE_RESULT")
    Define("EV_ON_SET_ENTER_BATTLE_COUNT")
    Define("EV_ON_BINDACCOUNT_SUCCESS")
    Define("EV_ON_PAY_RESULT")
    Define("EV_SUBLEVEL_LOADED_IN_LOBBY")
    Define("EV_UI_SHIP_SET_POSTURE")
    Define("EV_UI_BATTLE_STATE_ENTERED")
    Define("EV_UI_SHIP_TOGGLE_AIM_PC")      -- 用于PC操作
    Define("EV_UI_JOYSTICK_SPRINT_PC")      -- 用于PC操作
    Define("EV_UI_SHIP_HALF_SAIL_PC")       -- 用于PC操作
    Define("EV_UI_SHIP_REEF_PC")            -- 用于PC操作
    Define("EV_UI_FREE_VIEW_PC")            -- 用于PC操作
    Define("EV_UI_SWITCH_TO_PC")            -- 用于PC操作

    -- UIMain
    Define("EV_FRESH_MAIL_STATE")
    Define("EV_FRESH_FRIEND_STATE")
    Define("EV_FICTION_CHANGE")

    -- Interaction
    Define("EV_INTERACTION_CHANGE")
    Define("EV_UI_REQUEST_INTERACTION")
    Define("EV_INTERACTION_END")
    Define("EV_INTERACTION_ABORT")
    Define("EV_INTERACTION_EXIT")
    Define("EV_INTERACTION_START")
    Define("EV_REQUEST_PROGRESS")
    Define("EV_STOP_PROGRESS")
    Define("EV_INTERACTION_CANCLE")
    Define("EV_UI_REQUEST_CHANGEDISPLAY")


    Define("EV_ON_UPINTERACTION_QUEST_ITEM_CLICK")
    Define("EV_UI_SHOW_NPC_DIALOG")
    Define("EV_UPDATE_NPC_QUEST_INFO")
    Define("EV_ON_QUEST_ACCEPT_FAIL")
    Define("EV_ON_QUEST_COMPLETE_CONDITION")
    Define("EV_ON_REFRESH_ACCEPT_QUEST")
    Define("EV_ON_QUEST_INIT_COMPLETE")
    Define("EV_ON_GOTO_QUEST")
    Define("EV_ON_UP_MAIN_QUEST_ITEM_CLICK")

    Define("EV_CURRENCY_SYNC")
    --obsolete 请使用EV_PLAYER_EXP_SYNC_NEW
    Define("EV_PLAYER_EXP_SYNC")
    --obsolete 请使用EV_PLAYER_LEVEL_UP_NEW
    Define("EV_PLAYER_LEVEL_UP")
    Define("EV_GOODS_SHOP_REFRESH")
    Define("EV_GOODS_SYNC")
    Define("EV_OCEAN_FOG_UNLOCK")
    Define("EV_PLAYERDATA_SYNC")
    Define("EV_BACKPACK_ITEM_CHOSE")
    Define("EV_SELECT_ITEM_FROM_SHIPCABIN")
    Define("EV_ITEM_GRID_CHOSE")

    --Chat
    Define("EV_RECEIVE_CHAT_MESSAGE")
    Define("EV_RECEIVE_PRIVATECHAT_MESSAGE")
    Define("EV_ADD_SYSTEM_MESSAGE")                         -- 系统频道
    Define("EV_ADD_DUNGEON_MESSAGE")                        -- 副本频道
    Define("EV_ADD_NEARBY_MESSAGE")                         -- 附近频道
    Define("EV_ADD_GUILD_MESSAGE")                          -- 公会频道
    Define("EV_CHANGE_CHAT_DIALOG_HIGHT")                   -- 聊天框高度缩放
    Define("EV_BATTLECHAT_FRIEND_NEW_MSG")
    Define("EV_CLICK_QUICK_CHAT")
    Define("EV_SELECT_HISTORY")
    Define("EV_SELECT_FRIEND_CHAT")

    --lobby聊天
    Define("EV_CLICK_TEAM_CHAT")
    Define("EV_CLICK_OPEN_TEAMING")
    Define("EV_OPEN_LOBBY_CHAT")
    Define("EV_OPEN_LOBBY_CHAT_FRIEND")
    Define("EV_REFRESH_PLAYER_BASEINFO")
    Define("EV_CLICK_EXPRESSION")
    Define("EV_CHAT_CLICK_FRIEND")
    Define("EV_CHAT_CLOSE_BTNLIST")
    Define("EV_CHAT_OPEN_BTNLIST")
    Define("EV_CHAT_TO_BATTLE_FRIEND")
    Define("EV_CHAT_SEND_FAILED")
    Define("EV_CHAT_RESET_FRIEND_UREAD_STATE")
    Define("EV_RECIEVE_TOP_MSG")
    Define("EV_SHOW_TOP_MSG")
    Define("EV_DEACTIVE_TOP_MSG")
    Define("EV_LOBBY_CHAT_BUBBLE")

    --Friend
    Define("EV_RECEIVE_RECOMMEND_FRIENDS")                  -- 收到推荐好友信息
    Define("EV_RECEIVE_SEARCH_FRIENDS")                     -- 收到搜索好友信息
    Define("EV_OPEN_CONTACT_CHAT")                          -- 打开好友联系人界面
    Define("EV_ADD_FRIEND_INFO")                            -- 新增好友
    Define("EV_DELETE_FRIEND_INFO")
    Define("EV_UPDATE_BLACK_INFO")                          -- 更新黑名单信息
    Define("EV_RECEIVE_FRIEND_APPLICAION")                  -- 收到好友申请消息
    Define("EV_RECEIVE_FRIEND_APPLICAION_REFRESH")          -- 刷新好友申请面板
    Define("EV_RECEIVE_APPLY_SUCCESS")                      -- 收到发送申请好友成功的信息
    Define("EV_APPLY_FRIEND_STATE")                         -- 申请好友信息变化
    Define("EV_UPDATE_FRIEND_INFO")                         -- 更新好友显示信息
    Define("EV_UPDATE_FRIEND_RED_TIP")                      -- 更新联系人小红点显示
    Define("EV_APPLICATION_FRIEND_TIP")                     -- 显示待申请好友的tip
    Define("EV_UPDATE_CHAT_RED_TIP")                        -- 更新好友聊天小红点

    --Friend heart
    Define("EV_RECEIVE_DONATE_HEART")                       -- 收到赠送爱心
    Define("EV_RECEIVE_RECEIVED_HEART")                     -- 收到收取爱心
    Define("EV_RECEIVE_RECEIVED_ALL_HEART")                 -- 收到收取所有爱心
    Define("EV_RECEIVE_HEART")                              -- 收取爱心
    Define("EV_REFRESH_HEART_REWARDBOX")                    -- 刷新爱心宝箱
    Define("EV_HIDE_HEART_REDTIP")                          -- 隐藏消息红点提示

    --Ship
    Define("EV_BUILD_SHIP_SUCCESS")
    Define("EV_BUILD_SHIP_FAIL")

    Define("EV_SHIP_ENHANCE_SUCCESS")
    Define("EV_SHIP_ENHANCE_FAIL")

    Define("EV_SELL_SHIP_SUCCESS")
    Define("EV_SELL_SHIP_FAIL")

    Define("EV_BUY_SHIP_POS_SUCCESS")

    Define("EV_DELETE_SOLD_SHIP")

    Define("EV_REDEEM_SHIP_SUCCESS")
    Define("EV_REDEEM_SHIP_FAIL")

    Define("EV_ADD_SHIP")
    Define("EV_ADD_SHIP_MATINEE_END")
    Define("EV_EDIT_SHIP")
    Define("EV_SWITCH_FLAG_SHIP_SUCCESS")
    Define("EV_REPAIR_SHIP_RESPONSE")
    Define("EV_ADD_SUPPLY_RESPONSE")

    Define("EV_GO_TO_SEA_SUCCESS")
    Define("EV_GO_TO_SEA_FAIL")

    Define("EV_CHANGE_SHIP_RES")            -- 有某个船改变了外观，需要在ui上刷新

    Define("EV_SHIP_SUPPLY_CHANGE")
    Define("EV_SHIP_DURABILITY_CHANGE")
    Define("EV_SHIP_LOW_DURABILITY_VISIBLITY")
    Define("EV_ON_RECV_DUNGEON_LOADING_READY")

    Define("EV_ENTER_LOADING")
    Define("EV_EXIT_LOADING")

    Define("EV_SHIP_PROPERTY_CHANGE")

    Define("EV_SHIP_HIDE_ITEM_SUCCESS")
    Define("EV_SHIP_HIDE_ITEM_FAIL")
    Define("EV_SHIP_MOUNTAIN_WARNING")

    -- UI SHIP ACTOR
    Define("EV_CREATE_UI_BP_SHIP")
    Define("EV_PREPARE_UI_SHIP_CORE_PART_DATA")

    -- Arena
    Define("EV_MATCHMAKING_BEGIN")          -- 匹配开始
    Define("EV_MATCHMAKING_MEMBER_JOIN")    -- 匹配到成员
    Define("EV_MATCHMAKING_MEMBER_LEAVE")   -- 匹配时有人离开
    Define("EV_MATCHMAKING_FINISHED")       -- 匹配完成
    Define("EV_MATCHMAKING_FORCE_CANCLE")   -- 强制取消匹配

    --Team
    Define("EV_TEAM_CREATE_SUCCESS")
    Define("EV_TEAM_CREATE_FAIL")
    Define("EV_TEAM_DISMISS_BY_LEADER")
    Define("EV_TEAM_LEAVE")
    Define("EV_TEAM_TRANSFER_LEADER")
    Define("EV_TEAMLEADER_CHANGED")
    Define("EV_TEAMKICKOUT_MEMBER")
    Define("EV_TEAM_REFRESH")
    Define("EV_TEAM_CLOSE_POPLISTAPPLY")
    Define("EV_TEAM_ADD_INVITE_MEMBER")
    Define("EV_TEAM_KICKEDOUT_BYLEADER")
    Define("EV_TEAM_QEQUEST_BY_NEAR")
    Define("EV_TEAM_APPLY_FOR")
    Define("EV_TEAM_CLOSE_POPNEARBY")
    Define("EV_TEAM_QEQUEST_JOIN_TEAM_PLAYERS")
    Define("EV_TEAM_INVITE_BTN_HIDDEN")
    Define("EV_TEAM_INVITE_BTN_VISIBLE")
    Define("EV_INVALIDATE_APPLY_JOIN_TEAM_MESSAGE")
    Define("EV_VALIDATE_APPLY_JOIN_TEAM_MESSAGE")
    Define("EV_TEAM_ADD_MEMBER")
    Define("EV_TEAM_REMOVE_MEMBER")
    Define("EV_TEAM_UPDATE_INVITE_NEARBY_PLAYERS")
    Define("EV_RECEIVE_CLICK_PLAYER_TEAMINFO")
    Define("EV_TEAM_JOINTEAMSUCCESS")
    Define("EV_CHANGE_FISHING_MODE")
    Define("EV_FISHING_STARTWAIT")
    Define("EV_TEAM_DESTORY_MEMBER_ACTOR")
    Define("EV_TEAM_CLEAR_MEMBERS")
    Define("EV_TEAM_INVITE_APPLY_WAITING")
    Define("EV_TEAM_INVITE_APPLY_WAITING_REPLY")

    --Teleport
    Define("EV_TELEPORT_ABORTED")
    Define("EV_TELEPORT_FAILED")
    Define("EV_TELEPORT_START")
    Define("EV_TELEPORT_END")

    --Navigation
    Define("EV_NAVIGATION_MOVE_START")
    Define("EV_NAVIGATION_MOVE_FINISHED")
    Define("EV_NAVIGATION_MOVE_ABORTED")
    Define("EV_NAVIGATION_START_MOVE_IN_OCEAN")
    Define("EV_NAVIGATION_END_MOVE_IN_OCEAN")
    Define("EV_NAVIGATION_RETRY_MOVE_IN_OCEAN")
    Define("EV_NAVIGATION_MOVE_BLOCKED")

    --CommonAbort
    Define("EV_COMMON_ABORT")

    -- Test
    Define("EV_LOCAL_TEST_ENTER_DUNGEON")    -- 进入副本（带loading）
    Define("EV_LOCAL_TEST_LEAVE_DUNGEON")    -- 出副本（带loading）
    Define("EV_LOCAL_TEST_ENTER_MIRROR")     -- 进入副本（镜像模式）
    Define("EV_LOCAL_TEST_LEAVE_MIRROR")     -- 出副本（镜像模式）
    Define("EV_LOCAL_TEST_SWITCH_MAP")       -- 切换地图UI事件

    -- GameState
    Define("EV_GAME_STATE_ON_ACTOR_CHANNEL_OPEN")

    Define("EV_GAME_STATE_TRAININGCAMP_RELEASE_TIME_STAMP")

    -- Battle
    -- Define("EV_GAME_STATE_ON_RECV_BASE_INFO")
    Define("EV_GAME_STATE_ON_RECV_TEAM_INFOS")
    Define("EV_GAME_STATE_ON_RECV_TEAM_SCORES")
    Define("EV_GAME_STATE_ON_RECV_STEP_REMAIN_TIME")
    Define("EV_GAME_STATE_ON_RECV_STEP_INFO")
    Define("EV_GAME_STATE_ON_RECV_OBJECTIVE")
    Define("EV_GAME_STATE_ON_RECV_STATISTICS_DATAS")
    Define("EV_GAME_STATE_ON_RECV_PVP_OCCUPY_AREA_STATE")
    Define("EV_REPLICATION_CRC_CHECK_SUCCESS")

    Define("EV_BATTLE_PORTRAIT_BEGIN")
    Define("EV_BATTLE_PORTRAIT_END")
    Define("EV_BATTLE_DISCONNECTED")
    Define("EV_BATTLE_SHOW_TARGETTRACK")
    Define("EV_BATTLE_RESTART_GAME")
    Define("EV_BATTLE_SHOW_PREGAME_CD")
    Define("EV_GAME_STATE_ON_RECV_JSON_MAIN_STEP_INFO")
    Define("EV_BATTLE_SHOW_OCCUPY")

    --Revive
    Define("EV_BATTLE_RESET_CHOOSEREVIVE")
    Define("EV_BATTLE_REVIVE_REST")

    --PlayerState
    Define("EV_PLAYER_STATE_ON_ACTOR_CHANNEL_OPEN")

    -- Skill
    Define("EV_SKILL_CAST_BY_ID")
    Define("EV_SKILL_CAST_SUCCESSED")
    Define("EV_SKILL_RESET_CD")

    -- Workshop
    Define("EV_WORKSHOP_COMPLETE")
    Define("EV_WORKSHOP_START")
    Define("EV_WORKSHOP_PICKUP_MATERIAL")
    Define("EV_WORKSHOP_SYNC_ALL")
    Define("EV_WORKSHOP_SYNC")

    -- Lobby Item 大厅道具
    Define("EV_ADD_LOBBY_ITEM")                        -- 新增物品
    Define("EV_REMOVE_LOBBY_ITEM")                     -- 删除物品，某个instance_id的物品被移除（不包含单纯数量减少的情况）
    Define("EV_CHANGE_LOBBY_ITEM_STACK_COUNT")         -- 物品数量改变
    Define("EV_CHANGE_LOBBY_ITEM_EXPIRED_AT")          -- 物品过期时间改变
    Define("EV_USE_LOBBY_ITEM_SUCCESS")                -- 物品使用成功
    Define("EV_USE_LOBBY_ITEM_SUCCESS_ID")             -- 物品使用成功带id
    Define("EV_USE_LOBBY_ITEM_FAIL")                   -- 物品使用失败
    Define("EV_SELL_LOBBY_ITEM_SUCCESS")               -- 物品出售成功
    Define("EV_SELL_LOBBY_ITEM_FAIL")                  -- 物品出售失败
    Define("EV_EQUIP_LOBBY_FASHION")                   -- 装备人的时装成功
    Define("EV_UNEQUIP_LOBBY_FASHION")                 -- 脱下人的时装成功
    Define("EV_EQUIP_LOBBY_DECORATION")                -- 装备人的饰品成功
    Define("EV_UNEQUIP_LOBBY_DECORATION")              -- 脱下人的饰品成功
    Define("EV_EQUIP_LOBBY_WEAPON_FASHION")            -- 穿人武器的时装成功
    Define("EV_UNEQUIP_LOBBY_WEAPON_FASHION")          -- 脱人武器的时装成功
    Define("EV_CHANGE_NEW_STATE_IN_BACKPACK")          -- 背包里是否有新道具状态发生变化
    Define("EV_SELECT_LOBBY_ITEM")
    Define("EV_NEW_ITEM_RECORD_STATE_CHANGED")
    Define("EV_LOBBY_FASHION_DO_CHANGED")              -- 穿脱时装
    Define("EV_LOBBY_FASHION_FLAG_MODIFIED")           -- 人时装额外标识数据修改
    
    -- Item
    Define("EV_ADD_ITEM")                  -- 新增物品
    Define("EV_REMOVE_ITEM")               -- 删除物品，某个instance_id的物品被移除（不包含单纯数量减少的情况）
    Define("EV_REMOVE_ITEM_NOTICE")        -- 删除物品的通知
    Define("EV_ITEM_CHANGE")               -- 新增，删除，改变物品属性，需要刷新UI数据
    Define("EV_ITEM_CHANGE_POS")           -- 物品位置变化
    Define("EV_REQUEST_USE_ITEM")          -- 请求使用物品
    Define("EV_USE_ITEM_SUCCESS")          -- 物品使用成功
    Define("EV_USE_ITEM_FAIL")             -- 物品使用失败
    Define("EV_SYNC_ITEM_PROPERTIES")      -- 修改了物品可变属性（配件鉴定）
    Define("EV_SYNC_ITEM_UNLOCK")          -- 解锁物品的制造（配件的制造需要解锁）
    Define("EV_CREATE_ACCESSORY_SUCCESS")  -- 制造配件成功
    Define("EV_CREATE_ACCESSORY_FAIL")     -- 制造配件失败
    Define("EV_SELECT_CONSUMABLE")         -- 船只选择了消耗品
    Define("EV_RESET_CONSUMABLE")          -- 船只卸下了消耗品
    Define("EV_SELECT_ACCESSORY_SUCCESS")  -- 船只选择配件成功
    Define("EV_RESET_ACCESSORY_SUCCESS")   -- 船只卸下配件成功
    Define("EV_SELECT_DRESS_SUCCESS")      -- 穿外装成功
    Define("EV_RESET_DRESS_SUCCESS")       -- 脱外装成功
    Define("EV_SELL_ITEM_SUCCESS")         -- 卖物品成功
    Define("EV_SELL_ITEM_FAIL")            -- 卖物品失败
    Define("EV_SELECT_EQUIPMENT_SUCCESS")  -- 船只装配装备成功
    Define("EV_RESET_EQUIPMENT_SUCCESS")   -- 船只卸下装备成功
    Define("EV_AUTO_SELECT_EQUIPMENT_SUCCESS")  -- 船只一键装配装备成功
    Define("EV_AUTO_RESET_EQUIPMENT_SUCCESS")   -- 船只一键卸下装备成功
    Define("EV_SELECT_MODPART_SUCCESS")         -- 船只装备改造零件成功
    Define("EV_RESET_MODPART_SUCCESS")          -- 船只卸下改造零件成功
    Define("EV_AUTO_RESET_MODPART_SUCCESS")     -- 船只一键卸下改造零件成功
    Define("EV_SPLIT_MODPART_SUCCESS")          -- 拆解改造零件成功
    Define("EV_EQUIPMENT_VISIBILITY")           -- 显示快捷装配界面
    Define("EV_CONSUMABLE_START_USE")           -- 消耗品开始使用，参数为 item_instance_id
    Define("EV_CONSUMABLE_USE_INTERRUPTED")     -- 消耗品使用中断，参数为 item_instance_id
    Define("EV_CONSUMABLE_USE_SUCCESS")         -- 消耗品使用成功，注意，并非效果结束，而是开始生效，参数为 item_instance_id
    Define("EV_CONSUMABLE_USE_END")             -- 消耗品使用结束

    -- Trade
    Define("EV_TRADE_SINGLE_CARGO")         -- 预交易单个货物
    Define("EV_REFRESH_BUY_LIST")           -- 刷新购买货物信息
    Define("EV_REFRESH_SELL_LIST")          -- 刷新出售货物信息
    Define("EV_ACTIVE_SCARCE_TRADE")        -- 激活紧急贸易
    Define("EV_REFRESH_OUTDATED_DATA")      -- 刷新过期贸易数据

    -- Mail
    Define("EV_MAIL_ALL")                   -- 收到邮件数据
    Define("EV_MAIL_NEW")                   -- 新邮件
    Define("EV_MAIL_READ")                  -- 读邮件成功
    Define("EV_MAIL_CLAIM_SUCCESS")         -- 收取附件成功
    Define("EV_MAIL_BACKPACK_FULL")         -- 背包已满
    Define("EV_MAIL_DELETE_SUCCESS")        -- 删除邮件成功
    Define("EV_MAIL_EXPIRE")                -- 邮件过期
    Define("EV_MAIL_MAILBOX_FULL")          -- 邮箱已满，被新邮件顶掉
    Define("EV_MAIL_NOT_CLAIMED")           -- 附件未领取

    Define("EV_UPDATE_KVP")
    Define("EV_DELETE_KVP")

    --区域判断
    Define("EV_ACTOR_AREA_ENTER")                 -- 进入Actor区域
    Define("EV_ACTOR_AREA_LEAVE")                 -- 离开Actor区域


    --Arena new
    Define("EV_REQUEST_MATCH_MAKING_SUCCESS")       --请求匹配成功
    Define("EV_ASK_MATCH_MAKING")                   --广播问询队伍成员是否开始匹配
    Define("EV_ANSWER_MATCH_MAKING")                --广播回复队伍成员是否开始匹配
    Define("EV_MATCH_MAKING_BEGIN")                 --匹配开始
    Define("EV_MATCH_MAKING_CANCELLED")             --匹配已取消
    Define("EV_MATCH_MAKING_SUCCESS")               --匹配成功
    Define("EV_MATCH_MAKING_FAILED")                --匹配失败
    Define("EV_ARENA_LEADER_BOARD_RANK_UPDATE")     --刷新当前排名
    Define("EV_ARENA_LEADER_BOARD_LIST_UPDATE")     --刷新排行榜列表
    Define("EV_ARENA_AWARD_STATE_CHANGED")          --段位奖励状态发生改变
    Define("EV_ARENA_SYNC_QUEUE_STATUS")            --同步排位赛实力相似玩家的数量
    Define("EV_COOP_INFO")                          --COOP奖励次数

    -- M地图
    Define("EV_CLICK_PORT_LIST")            -- 选中列表中的港口
    Define("EV_REFRESH_PORT_LIST")          -- 刷新港口列表
    Define("EV_OPEN_OBSERVED_PORT_MAP")     -- 打开所要察看的港口地图
    Define("EV_REFRESH_NAVIGATION_POINT")   -- 刷新导航路径点
    Define("EV_UPDATE_GATHER_POINT")        -- 更新采集点
    Define("EV_NAVIGATION_CLICK")               -- 点击寻路
    Define("EV_REFRESH_STATIC_PORT")        -- 在M地图上强制显示港口
    Define("EV_MAP_REFRESH_DYNAMIC_FLAG")   -- 刷新游戏对象在地图上的显示标记

    --新手指引
    Define("EV_GUIDE_CLICK_ANYWHERE")       --新手指引，点击任意位置
    Define("EV_GUIDE_DUNGEON_NEXT")         --新手副本中进行下一步
    Define("EV_GUIDE_STEP_END")             --新手指引单步结束
    Define("EV_GUIDE_DUNGEON_COMPLETED")    --新手副本最后一步完成
    Define("EV_GUIDE_DUNGEON_SPAWN_NPC")    --新手副本刷怪
    Define("EV_GUIDE_SKIP_DUNGEON")         --跳过新手副本
    Define("EV_GUIDE_TASK_SHOW")
    Define("EV_GUIDE_CLICK_SELECT")
    Define("EV_QUIDE_SAIL_STATE_CHANGED")
    Define("EV_GUIDE_DOUBLE_FIRED")
    Define("EV_UI_ANIMATION_END")
    Define("EV_UI_STACK_BACK")
    Define("EV_UI_STACK_TOP")
    Define("EV_GUIDE_SELECT_TAB")
    Define("EV_GUIDE_INTERRUPT_TOUCH")
    Define("EV_GUIDE_MAIN_TASK_VISIBLE")
    Define("EV_GUIDE_ON_SCHEDULE_LIST")
    Define("EV_GUIDE_BATTLE_OBJECTIVE_VISIBLE")
    Define("EV_GUIDE_CLICK_ITEM")
    Define("EV_GUIDE_CLICK_BORDER")
    Define("EV_GUIDE_MAIN_MENU_VISIBLE")
    Define("EV_GUIDE_TOOL_TIP_SHOW")
    Define("EV_GUIDE_INTERACTION_BTN_VISIBLE")
    Define("EV_GUIDE_TUTORIAL_START")
    Define("EV_GUIDE_PRE_LEVEL_LOBBY")
    Define("EV_UI_ON_FFAHUMAN_ACTIVATE")
    Define("EV_TOWN_PORTAL_CD_TIME_CHANGED")--回城CD时间改变
    Define("EV_UI_ON_HORSE_BTN_DOWN")--当玩家下马时
    Define("EV_UI_ON_HORSE_BTN_UP")--当玩家上马时
    Define("EV_UI_ON_HORSE_BTN_UP_VISIBLE")--当玩家上马时
    Define("EV_UI_ON_ITEM_PANLE_CLICKED")
    Define("EV_GUIDE_FORCE_END_MOVE")
    Define("EV_GUIDE_ENABLE_CONTINOUS")
    Define("EV_FFA_CHANGE_DISPLAY_ENABLE")
    Define("EV_RELEASE_FIGHT_BTN")
    Define("EV_FFA_TEAM_INFO_ENABLE")
    Define("EV_FFA_CLOSE_PICKUP")
    Define("EV_SET_FIGHT_BTN_ENABLE")
    Define("EV_SET_SHOW_AUTOSWIMING")
    Define("EV_SET_AIM_BTN_ENABLE")
    Define("EV_SET_GYRO_CHECK_ENABLE")
    Define("EV_STOP_SHIP_RUDDER_MOVE")
    Define("EV_SHIP_WEAPON_BULLET_COUNT")
    Define("EV_SHIP_WEAPON_LOAD_FINISH")
    Define("EV_GUIDE_UI_MODE")
    Define("EV_FFA_SELECT_TRANSPORTER_SET_NOOB_DUNGEON")
    Define("EV_GUIDE_CALL_FUNC")
    Define("EV_GUIDE_CAN_BUILD_ANIM_ENABLE")
    Define("EV_GUIDE_LOBBY_SPECIAL_WIDGET_OPEN")
    Define("EV_GUIDE_UI_SHOW")

    --ToolTip
    Define("EV_TOOL_TIP_HIDE")

    --CinematicMode
    Define("EV_ENTER_CINEMATIC_MODE")
    Define("EV_EXIT_CINEMATIC_MODE")

    Define("EV_PLAYER_SELF_CAUSED_INVALID_ATTACK")
    Define("EV_PLAYER_SELF_CAUSED_DAMAGE")
    Define("EV_PLAYER_SELF_CAUSED_BROKEN")
    Define("EV_PLAYER_SELF_TOOK_INVALID_ATTACK")
    Define("EV_PLAYER_SELF_TOOK_DAMAGE")
    Define("EV_PLAYER_SELF_TOOK_BROKEN")
    Define("EV_PLAYER_SELF_TARGET_CHANGED")
    Define("EV_PLAYER_SELF_TOOK_CURE")

    Define("EV_ENTER_SPECTATOR_MODE")
    Define("EV_EXIT_SPECTATOR_MODE")

    --Shop
    Define("EV_REFRESH_SHOP")
    Define("EV_GO_SHOPPING_SUCCESS")             -- 购买成功
    Define("EV_REFRESH_SHOP_FINISH")             -- 商店刷新结束
    Define("EV_SHOP_NOT_ENOUGH_CURRENCY")        -- 购买货币不足

    --IAP
    Define("EV_ON_IAP_BEGIN")
    Define("EV_ON_IAP_END")
    Define("EV_SHOW_DEFAULT_IAP_DATA")
    Define("EV_ON_FRESH_FIRST_PURCHASE")

    --Matinee
    Define("EV_ON_MATINEE_PLAY")
    Define("EV_ON_MATINEE_QTE_END")

    --welfare
    Define("EV_WELFARE_TIME_UPDATE")
    Define("EV_WELFARE_GETBACK_SUCCESS")
    Define("EV_WELFARE_GETBACK_FAIL")
    Define("EV_SYNC_KVP")
    Define("EV_WELFARE_GETBACK_OPEN")
    Define("EV_WELFARE_TREASURE_SYNC")
    Define("EV_WELFARE_TREASURE_BACK")
    Define("EV_REFRESH_TREASURER_RED_DOT")

    Define("EV_RECEIVE_WELFARE_AWARD")

    --HUB BUFF
    Define("EV_REFRESH_BUFF")

    -- Misc
    Define("EV_AUTO_BATTLE")

    --world
    Define("EV_GO_TO_POSITION") -- 服务器告诉客户端寻路到某个位置

    --NPC改变交互属性
    Define("EV_BATTLE_FULL_HEAD_INFO_STATE_CHANGED")

    -- Camera
    Define("EV_SHOT_LEAVE_CAMERA_MODE")
    Define("EV_SHOT_CAMERA_SHOT_BEGIN")
    Define("EV_SHOT_CAMERA_SHOT_BEFORE_FINISH")
    Define("EV_SHOT_CAMERA_SHOT_FINISH")
    Define("EV_SHOT_CAMERA_SHOT_SUCCESS")
    Define("EV_SHOT_MODE_STATE_CHANGED")
    Define("EV_SHOT_ENTER_CAMERA_MODE")
    Define("EV_SHOT_AUTO_LEAVE_CAMERA_MODE")

    Define("EV_CHANGE_SENSE_VALUE")
    Define("EV_CHANGE_CAMERA_SENSE_VALUE")
    Define("EV_CHANGE_GYRO_SENSE_VALUE")

    --答题活动
    Define("EV_QUESTION_PLAYER_JOIN")
    Define("EV_QUESTION_PLAYER_LEAVE")
    Define("EV_QUESTION_ASSIGN_QUESTION")
    Define("EV_QUESTION_PUBLISH_PLAYER_ANSWER")
    Define("EV_QUESTION_RESULT")

    --海盗大餐活动
    Define("EV_BIG_MEAL_FREE_FOOD_SUCCESS")
    Define("EV_BIG_MEAL_LIMIT_FOOD_SUCCESS")
    Define("EV_BIG_MEAL_BUY_FOOD_SUCCESS")

    --Actor Trigger
    Define("EV_ACTOR_TRIGGER_IN")
    Define("EV_ACTOR_TRIGGER_OUT")

    --Mixing Mini Game
    Define("EV_MIXING_SUCCESS")
    Define("EV_MIXING_FAIL")

    --采集中断
    Define("EV_UI_COLLECTION_BREAK")
    -- 点击玩家
    Define("EV_ON_CLICK_PLAYER")
    --点击完按钮返回
    Define("EV_BATTLE_INTERACTIONDLG_END_NPC")

    Define("EV_BATTLE_CHANGINGDISPLAY_BREAK")

    --fishing
    Define("EV_FISHING_START")
    Define("EV_FISHING_RESULT")
    Define("EV_FISHING_BAIT")
    Define("EV_FISHING_TEAM")
    Define("EV_STOCK_FISH")
    Define("EV_FISHING_LEAVEANIMATION")
    Define("EV_FISHING_REQUEST")
    Define("EV_FISHING_LEAVEING")
    Define("EV_FISHING_EXCHANGE")
    Define("EV_FISHING_WAITSTATECHANGE")

    --海上随机采集和陆地采集
    Define("EV_RANDOM_GATHER_START")

    --战斗结果
    Define("EV_BATTLE_RESULT")
    Define("EV_BATTLE_GAME_START")
    Define("EV_BATTLE_OPEN_RESULT")

    Define("EV_VIDEO_CLOSED")

    --ui窗口
    Define("EV_PRE_OPEN_UI")
    Define("EV_OPEN_UI")
    Define("EV_PRE_CLOSE_UI")
    Define("EV_POST_EXIT_UI")
    Define("EV_PRE_DESTROY_UI")
    Define("EV_DESTROY_UI")

    Define("EV_UI_MANAGER_OPEN_UI_FINISH")
    Define("EV_UI_MANAGER_CLOSE_UI_FINISH")

    Define("EV_BATTLE_FLAG_STATE")

    Define("EV_WND_SATISFACTION_CLOSED")

    --触摸到非gameobject的actor
    Define("EV_TOUCH_TOUCHABLE_ACTOR")

    Define("EV_BATTLEGROUND_LEADER_BOARD_RANK_UPDATE")     --刷新当前排名
    Define("EV_BATTLEGROUND_LEADER_BOARD_LIST_UPDATE")     --刷新排行榜列表

    -- Battle UI Visible
    Define("EV_UI_ATTACK_VISIBLE")
    Define("EV_UI_INTERACTION_VISIBLE")
    Define("EV_UI_SHIP_INFO_VISIBLE")
    Define("EV_UI_BATTLE_DEAD_STATE")
    Define("EV_UI_BATTLE_OPEN")
    Define("EV_UI_PRE_CHANGE_DISPLAY")
    Define("EV_UI_CHANGE_DISPLAY")
    Define("EV_UI_TOGGLE_PICKUP_PANEL_VISIBILITY")


    Define("EV_SPECIAL_COIN_ENABLE") -- 开关特殊货币显示

    Define("EV_RECEIVE_BATTLE_COMMAND") -- 收到战斗指令
    Define("EV_SHOW_BATTLE_COMMAND_ON_TARGET_HEAD") -- 在目标头上显示战斗指令图标

    --拆解零件
    Define("EV_MODPART_SELECT_TO_EQUIP")
    Define("EV_MODPART_DECOMPOSE_SELECT")

    -- 协会系统
    Define("EV_ASSOCIATION_OPEN_WND")                   -- 打开协会界面
    Define("EV_ASSOCIATION_UPDATE_QUEST")               -- 更新任务状态
    Define("EV_ASSOCIATION_REFRESH_QUEST_LIST")         -- 刷新任务列表
    Define("EV_ASSOCIATION_RECEIVE_DATA")

    --拼图
    Define("EV_PUZZLE_ITEM_IN_POSITION")                -- 拼图图块位移坐标进入正确区域

    Define("PLAYER_CUASED_DAMAGE_WITH_LEVEL")           -- 玩家造成了伤害（带有伤害等级信息）

    Define("EV_DRINKING_STARTQTE")

    -- 公会
    Define("EV_GUILD_LIST")
    Define("EV_GUILD_SEARCH")
    Define("EV_GUILD_AUTO_REQUEST")
    Define("EV_GUILD_REQUESTJOIN")
    Define("EV_GUILD_DATA")
    Define("EV_GUILD_ACTIVITY")
    Define("EV_GUILD_MEMBERLIST")
    Define("EV_GUILD_BUY_MEMBER")
    Define("EV_GUILD_ANNOUNCEMENT")
    Define("EV_GUILD_FORBID_CHAT")
    Define("EV_GUILD_INVITED_JOIN")
    Define("EV_GUILD_INVITED_JOIN_INGORE")
    Define("EV_GUILD_KICK")
    Define("EV_GUILD_HAS_JOIN")
    Define("EV_GUILD_JOINLIST")
    Define("EV_GUILD_AUTO_JOIN")
    Define("EV_GUILD_REQUEST_LEVEL_SEND")
    Define("EV_GUILD_REQUEST_LEVEL")
    Define("EV_GUILD_MANAGERJOINLIST")
    Define("EV_GUILD_MEMBER_DUTY")
    Define("EV_GUILD_NEXTPRESIDENT")
    Define("EV_GUILD_DISSOLVE")



    --世界boss
    Define("EV_WORLDBOSS_LEADERBOARD_UPDATED")

    -- 吃鸡玩法
    Define("EV_FFA_INFO_CHANGED")
    Define("EV_FFA_TRANSPORT_INFO")             -- 飞机跳伞基础信息
    Define("EV_FFA_TRANSPORT_STATE_CHANGED")    -- 飞机跳伞状态改变
    Define("EV_FFA_TRANSPORT_PLAYER_COUNT")     -- 飞机上人数改变
    Define("EV_FFA_PARACHUTION_END")
    Define("EV_FFA_POISONCIRCLE_UPDATE")        -- 毒圈更新
    Define("EV_FFA_POISONCIRCLE_TIMERUPDATE")   -- 毒圈时间更新
    Define("EV_FFA_POISONCIRCLE_TIMER_COUNTDOWN")   -- 毒圈时间开始倒计时
    Define("EV_FFA_POISONCIRCLE_LAST_TEN_SEC")   -- 毒圈倒计时10s
    Define("EV_FFA_POISONCIRCLE_TIME_UP")       -- 毒圈倒计时0s
    Define("EV_FFA_PROCESS_STATE_CHANGED")      -- 新跳伞流程状态改变
    Define("EV_FFA_SELECT_POINT")               -- 跳伞选点通知
    Define("EV_FFA_SELECT_TRANSPORTER_PLAYER_COUNT")
    Define("EV_FFA_SELECT_POINT_TRANSPORTER")
    Define("EV_FFA_SELECT_POINTES")             -- 所有跳伞点
    Define("EV_FFA_SELECT_POINTES_UPDATE")
    Define("EV_FFA_SELECT_POINTE_SUCCES")       -- 选点成功
    Define("EV_FFA_SELECT_POINT_CANCEL")        -- 取消选点
    Define("EV_FFA_TEAM_INFO_CHANGED")          -- 队伍信息改变
    Define("EV_FFA_TRANSPORT_INFO_NEW")         -- 新飞机跳伞基础信息
    Define("EV_FFA_MAP_SCOPE_CHANGE")
    Define("EV_FFA_TRANSPORTER_MATINEE_COMPLETE") -- 跳伞matinee播放完成
    Define("EV_FFA_ENABLE_SELECTPOINT_MAP_PINCH") -- 是否允许用手指缩放选点地图
    Define("EV_FFA_ENTER_DUNGEON_IN_BATTLE") -- 跳伞落地后进入游戏

    Define("EV_FFA_HUMAN_CRAWL_TO_CROUCH")      -- 人趴变蹲

    --FFA Map op
    Define("EV_FFA_MAP_OP_ADD_SPECIAL_GO")
    Define("EV_FFA_MAP_OP_REMOVE_SPECIAL_GO")
    Define("EV_FFA_MAP_OP_ADD_PATH")
    Define("EV_FFA_MAP_OP_REMOVE_PATH")
    Define("EV_PLAYERSELF_BINDREPLICATE_UEACTOR")
    Define("EV_BATTLE_ITEM_SYNC_SCENE_ITEM")    --同步场景中掉落的物品
    Define("EV_BATTLE_ITEM_ADD_SCENE_ITEM")     --增加场景中掉落的物品
    Define("EV_BATTLE_ITEM_REMOVE_SCENE_ITEM")  --移除场景中掉落的物品
    Define("EV_BATTLE_ITEM_REMOVE_SCENE_ITEM_PACKAGE")  --移除场景中掉落的箱子
    Define("EV_BATTLE_PICKUP_CLEAR")            --拾取列表清空end

    Define("EV_BATTLE_PICKUP_ENTER")            --进入拾取物范围
    Define("EV_BATTLE_PICKUP_LEAVE")            --离开拾取物范围
    Define("EV_BATTLE_PICKUP_REMOVE")           --服务器通知移除拾取物
    Define("EV_BATTLE_REFRESH_PICKUP_LIST")     --刷新拾取物列表
    Define("EV_BATTLE_BEGIN_PICKUP")
    Define("EV_ON_CLICK_PICKUP_BOX")            --点击打开箱子按钮
    Define("EV_ON_LEAVE_PICKUP_BOX")            --离开箱子trigger
    Define("EV_ON_CLOSE_PICKUP_BOX")            --关闭箱子

    Define("EV_FFA_BATTLE_TOAST")           --吃鸡战斗击杀toast

    Define("EV_SHIP_AVATAR_RES_CHANGED")            --船的外装改变
    Define("EV_FFA_CONTROL_MODE_ACTIVATE")          --战斗控制状态激活
    Define("EV_FFA_CONTROL_MODE_DEACTIVATE")        --战斗控制状态无效
    Define("EV_FFA_RADARMAP_SOUND")                 --雷达地图声音事件
    Define("EV_FFA_RADARMAP_ENEMY_SOUND")           --雷达地图敌人声音事件

    Define("EV_FFA_DEL_FLAG_POS")               --删除地图标记
    Define("EV_FFA_ADD_FLAG_POS")               --添加地图标记
    Define("EV_UI_DRAG_START")                  --开始拖拽操作
    Define("EV_UI_DRAG_END")                    --结束拖拽操作
    Define("EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_ADDED")           --通知刷新人ui
    Define("EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_REMOVED")           --通知刷新人ui
    Define("EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_STACK_COUNT_CHANGED")           --通知刷新人ui
    Define("EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_EXCHANGE")
    Define("EV_FFA_HUMAN_SHORT_CUT_ITEM_SELECTED")      --人物界面快捷操作物品选定
    Define("EV_FFA_HUMAN_SHORT_CUT_ITEM_ACTIVATED")     --人物界面快捷操作物品启用激活
    Define("EV_FFA_HUMAN_SHORT_CUT_ITEM_DEACTIVATED")   --人物界面快捷操作物品取消激活
    Define("EV_FFA_HUMAN_SWIMMING_STAMINA_CHANGE")      --当游泳掉血时



    Define("EV_ON_PLAYER_SHIP_CHANGED_CLIENT")      -- 换船后

    -- Battle Item
    Define("EV_BATTLE_ITEM_EQUIPED_CLIENT")     -- 装配物品
    Define("EV_BATTLE_ITEM_UNEQUIPED_CLIENT")   -- 卸下物品

    Define("EV_BATTLE_ITEM_ADD_CLIENT")                 -- 增加物品
    Define("EV_BATTLE_ITEM_REMOVE_CLIENT")              -- 移除物品
    Define("EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_CLIENT")          -- 物品换位置
    Define("EV_BEFORE_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_CLIENT")  -- 两个已装备物品交换位置之前
    Define("EV_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_CLIENT")        -- 两个已装备物品交换位置
    Define("EV_BATTLE_ITEM_CHANGE_DURABILITY_CLIENT")   -- 物品修改耐久
    Define("EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT")   -- 物品修改叠加数量

    -- Battle Item Build
    Define("EV_BATTLE_ITEM_BUILD_FINISH_CLIENT")       -- 建造物品成功
    Define("EV_BATTLE_ITEM_BUILD_CANCEL_CLIENT")       -- 建造物品取消
    Define("EV_SHIP_BUILD_FINISH_CLIENT")              -- 建造船成功
    Define("EV_SHIP_BUILD_GRADE_CHANGED_CLIENT")       -- 可建造的船的等级发生改变

    -- PICKUP ITEM
    Define("EV_PICK_UP_FINISH")

    Define("EV_ON_RESET_BATTLE_ITEM")

    Define("EV_HUMAN_WEAPON_ON_EQUIPED_CLIENT")             -- 人装备武器
    Define("EV_HUMAN_WEAPON_ON_UNEQUIPED_CLIENT")           -- 人卸下武器
    Define("EV_HUMAN_ARMOR_ON_EQUIPED_CLIENT")              -- 人装备护甲
    Define("EV_HUMAN_ARMOR_ON_UNEQUIPED_CLIENT")            -- 人卸下护甲
    Define("EV_HUMAN_WEAPON_FIRE_TYPE_CHANGED_CLIENT")      -- 人枪切换制式
    Define("EV_HUMAN_WEAPON_ATTACHMENT_CHANGED_CLIENT")     -- 人武器换配件
    Define("EV_HUMAN_WEAPON_ACCUMULATE")                    -- 人武器蓄力
    Define("EV_HUMAN_WEAPON_STATE_CHANGED_CLIENT")

    Define("EV_ON_SHIP_WEAPON_EQUIPPED_CLIENT")                 -- 舰船武器装备
    Define("EV_ON_SHIP_WEAPON_UNEQUIPPED_CLIENT")               -- 舰船武器卸下
    Define("EV_ON_SHIP_WEAPON_FIRED_CLIENT")                    -- 舰船武器开火
    Define("EV_ON_SHIP_WEAPON_FIRING_SUCCEED_CLIENT")           -- 舰船武器进入CD
    Define("EV_ON_SHIP_WEAPON_BULLET_LOAD_BEGAN_CLIENT")        -- 舰船武器子弹装载开始
    Define("EV_ON_SHIP_WEAPON_BULLET_LOAD_ENDED_CLIENT")        -- 舰船武器子弹装载结束
    Define("EV_ON_SHIP_WEAPON_FIRING_CD_BEGAN_CLIENT")          -- 舰船武器开火CD开始
    Define("EV_ON_SHIP_WEAPON_FIRING_OPERATION_CHANGED_CLIENT") -- 舰船武器开火状态改变(tbCharacter, WeaponItem, nFiringOperation)

    -- BUILD ITEM
    Define("EV_BEGIN_ITEM_BUILD")
    Define("EV_RESERVE_ITEM_BUILD")
    Define("EV_CANCEL_RESERVE_ITEM_BUILD")
    Define("EV_ON_SYNC_SHIP_PREPARATION")       --同步战备数据
    Define("EV_FFA_RESULT")                     --FFA战斗结束
    Define("EV_FFA_KILL_BOSS_RESULT")           --FFA击杀boss战斗结束
    Define("EV_HUMAN_POSE_CHANGED")              --人物姿態變化
    Define("EV_HUMAN_MOVE_TYPE_CHANGED")              --人物移動狀態變化
    Define("EV_FFA_SHOWDIALOG")
    Define("EV_FFA_KILLINFO")
    Define("EV_FFA_QUICK_BUILD")                --当可以快捷建造时
    Define("EV_REQUEST_THROW_AWAY_ITEM")       -- 请求丢弃物品
    Define("EV_HUMAN_MOVE_LOCK")                --锁定奔跑
    Define("EV_HUMAN_SPRINT")                   --开始冲刺
    Define("EV_HUMAN_SPRINT_CONTINUOUS")        --出现锁定奔跑按钮

    Define("EV_BACKPACK_LISTITEM_SELECTED")     -- 背包界面列表物品选中

    -- FFA 竞技场
    Define("EV_FFA_ARENA_MATCH_MAKING_SUCCESS")     -- 匹配成功
    Define("EV_FFA_ARENA_MATCH_MAKING_CANCELLED")   -- 匹配取消
    Define("EV_FFA_ARENA_MATCH_MAKING_BEGIN")       -- 匹配开始
    Define("EV_FFA_ARENA_MATCH_MAKING_FAILED")      -- 匹配失败
    Define("EV_FFA_ARENA_MATCHING_PLAYER_COUNT")    -- 匹配中玩家数, nPlayerCount, nMaxPlayerCount

    Define("EV_FFA_AIM_STATE_CHANGED")                      --开镜状态
    Define("EV_FREE_VIEW_START")
    Define("EV_FREE_VIEW_END")
    Define("EV_USER_WIDGET_TOUCH_END")

    Define("EV_ON_ENTER_RESCUING_TRIGGER")
    Define("EV_ON_EXIT_RESCUING_TRIGGER")

    -- 镜头事件
    Define("EV_MOVEMENT_CAMERE_OFFSET")             --镜头开始移动
    Define("EV_ACTIVE_CAMERA_GROUP")                --相机对应的 camera group
    Define("EV_DEACTIVE_CAMERA_GROUP")
    Define("EV_FIRE_CAMERA_SHAKE")                  --镜头抖动
    Define("EV_SET_CAMERA_FORBOT")                  --为某个bot Target设置镜头
    Define("EV_SET_BOT_CAMERA_BACK")                --从bot身上回到玩家身上
    Define("EV_WATCH_BATTLE_STATE_CHANGE")          --各种在观战过程中 触发的镜头同步改变
    Define("EV_DEAD_CAMERA_OVER")                   --死亡镜头结束
    Define("EV_EXIT_FREE_VIEW")                     --强制退出小眼睛
    Define("EV_FORCE_GROUND_HUMAN_VIEW")            --跳伞落地 强制恢复人视角
    Define("EV_TO_DEAD_VIEW_INSTANT")               --直接切死亡
    Define("EV_TO_FIRE_AIM_ABSORPTION")             --开枪吸附


    Define("EV_FFA_TEAM_HEAD_NAME_OBJ_CHANGED")     --吃鸡队友名字片绑定的gameobject改变
    Define("EV_FFA_TEAM_HEAD_NAME_REMOVED")         --队友死亡后名字片移除的通知

    -- HumanWeapon
    Define("EV_HUMAN_WEAPON_GUN_ATTACK")
    Define("EV_HUMAN_WEAPON_THROW_READY")
    Define("EV_HUMAN_WEAPON_THROWED")
    Define("EV_HUMAN_WEAPON_THROW_CANCEL")
    --Define("EV_HUMAN_WEAPON_STATE_ACTIVATE")
    --Define("EV_HUMAN_WEAPON_STATE_DEACTIVATE")

    Define("EV_FFA_TEAM_INFO_UPDATED")              --吃鸡队友信息更新
    Define("EV_FFA_FLAG_POINT_UPDATE")              --标记点更新

    Define("EV_ON_SAILOR_RED_DOT_VISIBLE_CHANGED")          -- 水手招募结果通知
    Define("EV_ON_SHOW_SAILOR_SUMMONING")                   -- 水手招募结果通知
    Define("EV_ON_RECEIVE_SAILOR_SUMMON_RESULT")            -- 水手招募结果通知
    Define("EV_ON_RECEIVE_SAILOR_EQUIP_RESULT")             -- 水手装备结果通知
    Define("EV_ON_RECEIVE_SAILOR_UPGRADE_RESULT")           -- 水手装备结果通知
    Define("EV_ON_RECEIVE_SAILOR_DEGRADE_RESULT")           -- 水手装备结果通知
    Define("EV_ON_RECEIVE_UPGRADE_EQUIPPED_SAILOR_RESULT")  -- 水手装备结果通知
    Define("EV_ON_RECEIVE_SAILOR_UNEQUIP_ALL_RESULT")       -- 水手全部卸载结果通知
    Define("EV_ON_RECEIVE_SAILOR_UNEQUIP_PART_RESULT")       -- 水手卸载部分结果通知
    Define("EV_ON_RECEIVE_UNLOCK_SAILOR_SLOT_RESULT")       -- 解锁水手槽位结果通知
    Define("EV_ON_ONE_KEY_EQUIP_SAILOR_STARTED")            -- 开始一键装备水手
    Define("EV_ON_RECEIVE_UNLOCK_SAILOR_SLOT_NOT_ENOUGH_MONEY")       -- 解锁水手槽位货币不足

    Define("EV_ON_PARTNER_RED_DOT_VISIBLE_CHANGED")         -- 伙伴红点状态变化
    Define("EV_ON_PARTNER_SUNMMON_RESULT_CLOSED")           -- 伙伴招募结果页面关闭
    Define("EV_ON_PARTNER_SUNMMON_AGAIN")                   -- 伙伴招募结果页面下再次召唤
    Define("EV_ON_RECEIVE_SUMMON_PARTNER_RESULT")           -- 伙伴招募结果通知
    Define("EV_ON_RECEIVE_COMPOUND_PARTNER_RESULT")         -- 伙伴合成结果通知
    Define("EV_ON_RECEIVE_PARTNER_LEVEL_UP_RESULT")         -- 伙伴升星结果通知
    Define("EV_ON_RECEIVE_EQUIP_PARTNER_RESULT")            -- 伙伴上阵结果通知
    Define("EV_ON_RECEIVE_UNEQUIP_PARTNER_RESULT")          -- 伙伴下阵结果通知
    Define("EV_ON_RECEIVE_COMPOUND_PARTNER_RESULT")         -- 伙伴合成结果通知

    Define("EV_ON_RECEIVE_UNLOCK_SHIP_SLOT_RESULT")         -- 船备战槽位解锁通知
    Define("EV_ON_RECEIVE_EQUIP_SHIP_RESULT")               -- 船备战舰船装备通知
    Define("EV_ON_RECEIVE_UNEQUIP_SHIP_RESULT")             -- 船备战舰船卸载通知
    Define("EV_ON_RECEIVE_ACTIVATE_SHIP_PART_RESULT")       -- 船备战激活零件套装通知
    Define("EV_ON_RECEIVE_ACTIVATE_SHIP_WEAPON_RESULT")     -- 船备战激活武器通知
    Define("EV_ON_RECEIVE_SHIP_SKIN_CHANGED")               -- 船备战皮肤装载通知
    Define("EV_ON_RECEIVE_UNEQUIP_SHIP_SKIN_RESULT")        -- 船备战皮肤卸载通知
    Define("EV_ON_FIGHTBDR_MOUSE_DOWN")                     -- 当右侧开火按钮按下时
    Define("EV_ON_RECEIVE_UNLOCK_SHIP_SLOT_NOT_ENOUGH_MONEY")         -- -- 解锁舰船槽位货币不足

    -- lobby friend
    Define("EV_ON_REFRESH_FRIENDS") -- 好友列表
    Define("EV_ON_SEARCH_FRIEND")   -- 查找
    Define("EV_ON_REFRESH_APPLY_FRIENDS") -- 好友申请列表
    Define("EV_ON_REFRESH_BLACK_LIST") -- 黑名单列表
    -- Define("EV_ON_REFRESH_APPLY_COUNT")
    Define("EV_ON_REFRESH_RECENT_TEAM")-- 最近组队
    Define("EV_ON_REFRESH_RECENT_TEAM_STATE")-- 最近组队

    -- currency
    Define("EV_CURRENCY_COUNT_SYNC")    --货币数量同步

    --watch battle
    Define("EV_REFRESH_WATCH_MATE")  --观战队友切换刷新
    Define("EV_SHOW_WATCH_MATE_TIPS") --显示队友详情
    Define("EV_PAWN_DEAD_WATCHER_CHECK")

    --mail
    Define("EV_ALL_MAILS_RECEIVED")           --获取到所有邮件
    Define("EV_NEW_MAIL_NOTIFY_RECEIVED")     --收到有新邮件的通知
    Define("EV_NEW_MAIL_DELETE_RECEIVED")     --收到有新邮件的通知
    Define("EV_MARK_MAIL_READ_RECEIVED")     --邮件已读通知
    Define("EV_MAIL_ATTACHMENT_GOT_RECEIVED")     --领取到邮件附件的通知
    Define("EV_INVITOR_INFO_RECEIVED")     --收到邀请邮件中邀请者的状态

    --lobby team
    Define("EV_TEAM_SYNC")                      --组队信息同步
    Define("EV_TEAM_CHANGED")                   --队伍成员改变
    Define("EV_TEAM_LEADER_CHANGED")            --队长改变
    Define("EV_TEAM_MEMBER_SUMMARY_CHANGED")    --队友信息改变
    Define("EV_TEAM_MEMBER_READY_MATCH")        --队友准备状态改变
    Define("EV_TEAM_INVITE_APPLY")              --组队邀请申请
    Define("EV_TEAM_MATCH_CONDITION_CHANGED")   --队友匹配信息改变

    -- npc  ai
    Define("EV_NPC_RESET_TIMER")                --npc即将重置通知

    -- player info
    Define("EV_OTHER_PLAYER_BASIC_INFO_RECEIVED")   --通知收到其他玩家的基础数据（该事件是对summary信息的封装处理，方便外层统一使用）
    Define("EV_PLAYER_EXP_SYNC_NEW")
    Define("EV_PLAYER_LEVEL_UP_NEW")
    Define("EV_PLAYER_NAME_CHANGED")

	Define("EV_ON_REFRESH_SEASON_PASS")            --更新战阶通行证
    Define("EV_ON_REFRESH_SEASON_RANK")            --更新段位
    Define("EV_ON_SELECT_AWARD")
    Define("EV_ON_GET_SEASON_DATA")
    Define("EV_ON_REFRESH_STATS")            --统计信息
    Define("EV_ON_REFRESH_HISTORY_STATS")    --历史统计信息
    Define("EV_ON_REFRESH_HISTORY_STATS_DETAIL")    --历史统计详细信息
    Define("EV_ON_REFRESH_SEASON_CHALLENGE")            --赛季任务信息
    Define("EV_ON_REFRESH_SEASON_CHALLENGE_WEEKLY_AWARD")            --赛季周任务奖励
    Define("EV_ON_REFRESH_SEASON_CHALLENGE_AWARD_STATUS") --赛季任务小红点
    Define("EV_SEASON_CHALLENGE_REFRESH_FINISH") --赛季任务小红点
    Define("EV_SEASON_STATUS")
    Define("EV_SEASON_HISTRORY_SUMMARIES")  --赛季档案概要
    Define("EV_SEASON_HISTRORY_DETAILS")    --赛季档案详情
    Define("EV_SEASON_RESULT_AWARD_GET")    --赛季结算
    Define("EV_SEASON_POINT_RANKING")       --赛季排行榜
    Define("EV_SEASON_BATTLE_TIER_AWARD")   --赛季战阶奖励

	--中心区域提示
    Define("EV_SHOW_CORE_AREA")                 --显示中心区域
    Define("EV_EXIT_OPEN_AIM_CAMERA")       --退出准镜状态


    Define("EV_IN_VEHICLE_AREA")                 --进入坐骑区域 Param: tbVehicle ,bIn/bOut
    Define("EV_ON_MOVE_STOPPED")                 -- 下马后马的速度减为0，停止tick时
    Define("EV_ON_HORSE_SCARED")
    Define("EV_ON_JUMP_MODE_CHANGED")

    Define("EV_START_CHANGE_HUMAN_WEAPON")

    --家园
    Define("EV_ENTER_PROCEDURE_HOMELAND")
    Define("EV_LEAVE_PROCEDURE_HOMELAND")
    Define("EV_HOMELAND_LOADED")
    Define("EV_HOMELAND_BLOCK_ENTER")           -- 进入家园地块
    Define("EV_HOMELAND_BLOCK_LEAVE")           -- 离开家园地块
    Define("EV_LANDMARK_UPGRADE_BEGIN")         -- 标志性建筑开始升级
    Define("EV_LANDMARK_UPGRADE_COMPLETE")      -- 标志性建筑升级完成
    Define("EV_HOMELAND_BUY_BLOCK")             -- 购买地块
    Define("EV_PLACE_ITEM_BUILDING")            -- 放置建筑
    Define("EV_REMOVE_ITEM_BUILDING")           -- 拆除建筑
    Define("EV_SWITCH_HOMELAND_SCENE")          -- 切换家园场景
    Define("EV_CHANGE_HOMELAND_MODE")           -- 切换家园模式
    Define("EV_HOMELAND_PURCHASE_SCENE")        -- 购买家园场景
    Define("EV_HOMELAND_BUILDING_LOADED")       -- 地块上的建筑加载完毕
    Define("EV_HOME_ITEM_RESEARCH_BEGIN")       -- 道具研发开始
    Define("EV_HOME_ITEM_RESEARCH_COMPLETE")    -- 道具研发完成
    Define("EV_TRANSPORT_TREASURE_ARRIVED")     -- 宝藏运到藏宝处
    Define("EV_HOMELAND_ENTER_MATINEE_FINISHED") -- 进入家园动画播完
    Define("EV_HOMELAND_LEAVE_MATINEE_FINISHED") -- 离开家园动画播完
    Define("EV_HOMELAND_POST_ENTER_PROCEDURE_FINISHED") -- 进入家园后的需要执行的过程结束
    Define("EV_HOMELAND_PRE_LEAVE_PROCEDURE_BEGIN") -- 离开家园前的需要执行的过程开始
    Define("EV_HOMELAND_PRE_LEAVE_PROCEDURE_FINISHED") -- 离开家园前的需要执行的过程结束


    Define("EV_BOT_INFO_UPDATED")               -- 地图上机器人信息更新
    Define("EV_NPC_BATTLE_STATE_CHANGED")       -- NPC战斗状态变化

    Define("EV_STARTGAME_SOUND_01")
    Define("EV_STARTGAME_SOUND_02")
    Define("EV_STARTGAME_SOUND_03")
    Define("EV_STARTGAME_SOUND_04")
    Define("EV_STARTGAME_SOUND_05")
    Define("EV_STARTGAME_SOUND_06")


    Define("EV_GUIDE_SET_MODULE")
    Define("EV_GUIDE_FORCE_END_MODULE")
    Define("EV_GUIDE_SHOW_SPACE_SCREEN")
    Define("EV_GUIDE_DELAY_RESPONSE")
    Define("EV_GUIDE_UI_ACTIVATE")
    Define("EV_GUIDE_SHOW_TURERIGHT_EFFECT")

    --活动
    Define("EV_ACTIVIEY_SEVENDAY_CHECKIN")      -- 七日登陆
    Define("EV_ACTIVIEY_SEVENDAY_GETREWARD")    -- 七日登陆领奖
    Define("EV_ACTIVIEY_SEVENDAY_NEXT_DAY")     -- 七日登陆跨天

    Define("EV_SEND_PROP_DATA_FOR_GM")

    Define("EV_ON_AWARD_SEASON")

    Define("EV_FFA_ADDITIONALSUCCESS_CHOICE")
    Define("EV_MAP_PINCH_CHANGED")

    --Quest
	Define("EV_QUEST_NEW")
	Define("EV_QUEST_UPDATE")

    Define("EV_SETTING_LEFT_HAND_FIRE")
    Define("EV_SETTING_HUMAN_GYRO")
    Define("EV_SETTING_SHIP_GYRO")
    Define("EV_SETTING_AIM_ASSIST")
    Define("EV_SETTING_SHIP_SAIL_OPACITY_CHANGED")


    Define("EV_LAYOUT_STYLE_CHANGED")
    Define("EV_LAYOUT_CHANGED")
    Define("EV_OPERATION_MODE_CHANGED")

    --首战时间刷新
    Define("EV_FIRST_BATTLE_REFRESH_TIME")

    Define("EV_NPC_RISKALERTLEVEL_CHANGED")       -- NPC警戒值变化
    Define("EV_NPC_RISKALERTTARGET_CHANGED")       -- NPC警戒目标变化
    Define("EV_NPC_ATTACKTARGET_CHANGED")       -- NPC攻击目标变化

    Define("EV_SHOW_LOGIN")       -- 登录界面show
    Define("EV_SHOW_CREATE_ROLE")       -- 创建角色界面show
    Define("EV_BATTLE_WAIT_STAGE_STATE_CHANGED")       -- 集合区/战斗区转换

    Define("EV_ENTER_LAST_DUNGEON_FAILED")

    Define("EV_FFA_MAP_OP_REFRESH_AIR_DROP")

    Define("EV_NOTIFY_BATTLE_FINISHED")
    Define("EV_LOGIN_SERVER_INFO_COMPLETED")

    --Schedule
    Define("EV_SCHEDULE_ITEM_UPDATE")
    Define("EV_SCHEDULE_NOOB_LOGIN_REFRESH")
    Define("EV_SCHEDULE_BATTLE_STAR_REFRESH")
    Define("EV_SCHEDULE_BATTLE_STAR_TIP_HIDE")
    Define("EV_SCHEDULE_SELECT_REFRESH")
    Define("EV_SCHEDULE_FIXED_TIME_AWARD_REFRESH")
    Define("EV_SCHEDULE_CONTINUOUS_REFRESH")
    Define("EV_SCHEDULE_CHEST_REFRESH")
    Define("EV_SCHEDULE_ROULETTE_REFRESH")
    Define("EV_SCHEDULE_ACTIVATE")
    Define("EV_SCHEDULE_DEACTIVATE")
    Define("EV_SCHEDULE_USE_ITEM")
    Define("EV_SCHEDULE_TASK_REFRESH")
    Define("EV_SCHEDULE_ROULETTE_SUCCESS")
    Define("EV_SCHEDULE_AWARD")    
    Define("EV_SEA_ADVENTURE_REFRESH")
    Define("EV_QUESTION_REFRESH")
    Define("EV_SEA_DICE_COUNT_CHANGE")
    Define("EV_SEA_ADVENTURE_DICE_ROLL")
    Define("EV_SEA_ADVENTURE_REFRESH_CIRLEREWARD")
    -- Define("EV_SEA_ADVENTURE_DICE_REWARD_OK")

    Define("EV_LOBBY_SHIELD_MASK")
    Define("EV_ON_CLICK_FULLSCREEN_MASK")
    Define("EV_MAP_SYMBOL_VISIBLE_CHANGED")

    Define("EV_ON_NEXT_POP")
    Define("EV_ON_NEXT_UI_POP")
    Define("EV_ON_OVER_POP")
    Define("EV_ON_PAUSE_POP")
    Define("EV_ON_RESUME_POP")
    -- Define("EV_LOBBY_RECONNECTED")
    Define("EV_POST_PROCESS_EFFECT")
    Define("EV_FFA_SETTING")
    Define("EV_FFA_DEAD_PLAYBACK")

    Define("EV_SHOW_FLOAT_NUM")
    Define("EV_SHOW_FLOAT_DAMAGE_INFO")
	Define("EV_CHECK_WIN_AIM_CAMERA")
	Define("EV_RECOMMEND_MEDICINE_CHANGED")
    Define("EV_SETTING_CHANGE_DISPLAY")
    Define("EV_SETTING_AUTO_ROT")

    Define("EV_ITEM_BUFF_BTN_VISIBLE")
    Define("EV_REFRESH_ITEM_BUFFS")
    Define("EV_SHOW_RENAME_PLAYER")

    Define("EV_REFRESH_WELFARE_DATA")
    Define("EV_GO_TO_SHOP_ITEM")
    Define("EV_REFRESH_VIP_CARD_ITEM")
    Define("EV_SHOW_WELFARE")
    Define("EV_REFRESH_WELFARE_TIP_ICON")

    Define("EV_TEAM_MODE_INFO")

    Define("EV_RELOGIN_USED_VEHICLE")

    Define("EV_WATCH_BOT")
    Define("EV_WATCH_BOT_OVER")
    Define("EV_SET_WATCH_BOT_SOUND_TARGET")
    Define("EV_WATCH_BOT_DESTROY")


    Define("EV_ON_REQUEST_VEHICLE_FAILED")
    Define("EV_SYNC_BOT_INFO")
    Define("EV_SYNC_BOT_TEAM")
    Define("EV_REFRESH_WATCH_BOT")

    Define("EV_NEARBY_DIAMOND_REFRESHED")
    Define("EV_SHOW_HUMAN_SHIP_PORT")
    Define("EV_SHOW_PLAYER_NAME_HEAD")
    Define("EV_WATCH_CARRONADE_CAMERA")

    Define("EV_SHOW_DOOR_SWITCH")

    --GVoiceSDK
    Define("EV_GV_ON_JOIN_ROOM")
    Define("EV_GV_ON_STATUS_UPDATE")
    Define("EV_GV_ON_QUIT_ROOM")
    Define("EV_GV_ON_MEMBER_VOICE")
    Define("EV_GV_ON_RECORDING")
    Define("EV_GV_ON_MIC_CTR_OPEN")
    Define("EV_GV_ON_SPEAKER_CTR_OPEN")
    Define("EV_GV_ON_JOIN_ROOM_SUCCESS")
    Define("EV_GV_ON_MEMBER_VOICE_STATE")
    Define("EV_GV_ON_MEMBER_VOICE_DETAIL")
    Define("EV_GV_ON_ROOM_MEMBER_INFO")
    Define("EV_GV_ON_VOICE_SINGLE_PLAYER")
    Define("EV_GV_ON_VOICE_MEMBER_ID_CHANGE")
    Define("EV_GV_ON_VOICE_EVENT")
    Define("EV_GV_ON_VOICE_GET_MEMBERINFO")
    Define("EV_GV_ON_VOICE_ROOM_MEMBER_INFO")

    Define("EV_GV_ON_CLICK_SURVEY")
    Define("EV_CLEAR_ALL_FLAG_POINT")
    Define("EV_CLEAR_ALL_TEAM_HEAD_NAME")

    Define("EV_ADD_LOG_TO_SCREEN")
    Define("EV_GAME_OVER_CAMERA_DETACH")

    -- app切后台
    Define("EV_APP_WILL_DEACTIVE")
    Define("EV_APP_WILL_ENTER_BACKGROUND")
    Define("EV_APP_HAS_ENTERED_FOREGROUND")

    Define("EV_NEW_PLAYER")
    Define("EV_WATCH_BATTLE_MOVEMENT_STATE_CHANGE")
    Define("EV_INHIBIT_ATTACK_ACTIVE")
    Define("EV_ENTER_PROCEDURE_LOGIN")
    Define("EV_LOBBY_SUBLEVEL_LOAD_FINISHED")


    Define("EV_AIDBUEG_PARAM")

    --人外观
    Define("EV_DEFAULT_APPEARANCE_SELECTED")
    Define("EV_HUMAN_AVATAR_COMMIT_FINISHED")


    Define("EV_LOBBYSAILOR_TO_PRE")
    Define("EV_LOBBYSAILOR_TO_NEXT")
    Define("EV_LOBBYSAILOR_EQUIPITEM_SELECT")
    Define("EV_LOBBYSAILOR_LEVELUP_SAILOR")

    --船长界面
    Define("EV_LOBBY_CAPTAIN_GO_FITTING")
    Define("EV_LOBBY_CAPTAIN_QUIT_FITTING")
    Define("EV_LOBBY_CAPTAIN_CALL_TO_DEACIVATE_FEATURE")
    Define("EV_LOBBY_CAPTAIN_CALL_TO_ACIVATE_FEATURE")
    Define("EV_LOBBY_CAPTAIN_HUMAN_FASHION_TYPE_SWITCHED")
    Define("EV_LOBBY_CAPTAIN_SELECT_AVATAR_ITEM")
    Define("EV_LOBBY_CAPTAIN_FITTING_AVATAR_ITEM")
    Define("EV_LOBBY_CAPTAIN_UNFITTING_AVATAR_ITEM")
    Define("EV_LOBBY_HUMAN_LEVEL_SWITCHED")
    Define("EV_LOBBY_CAPTAIN_BUY_ITEM")

    
    
    Define("EV_NOTIFY_FASHION_FLAG_CHANGED")

    Define("EV_LOBBY_CAPTAIN_PICK_ITEM")
    Define("EV_LOBBY_CAPTAIN_UNPICK_ITEM")

    Define("EV_LOBBY_CAPTAIN_WEAPON_RANGE_TYPE_SWITCHED")
    Define("EV_LOBBY_CAPTAIN_WEAPON_INSTANCE_TYPE_SWITCHED")

    Define("EV_LOBBY_SUB_SYSTEM_ACTIVATE")

    Define("EV_PLAYER_SUMMARIES_RECEIVED")
    Define("EV_PLAYER_SEASON_SUMMARY_RECEIVED")
    Define("EV_PLAYER_SEASON_BASIC_INFO_RECEIVED")
    Define("EV_PLAYER_SUMMARY_CHANGE_NOTIFIED")

    Define("EV_REFRESH_RELATION_FRIENDS")
    Define("EV_RELATION_NOT_PROCESS_REDDOT")

    Define("EV_UPDATE_TEAMMATE_RELATION")
    Define("EV_UPDATE_HEADRELATION")
    Define("EV_DUNGEON_RECEIVE_INVITE")
    Define("EV_ACCEPT_RESERVATION_SUCCESS")
    Define("EV_NOTIFY_RESERVATION_RESULT")
    Define("EV_SEND_CHECK_RESERVATIO_LIST_OK")
    Define("EV_RELATION_SHIP_CHANGED")
    Define("EV_REFRESH_IMTIMACY_CHANGE")

    -- 大厅舰船相关
    Define("EV_ON_REFRESH_SHIP_TIP_ICON")

    --Noob Award
    Define("EV_NOOB_GUIDE_AWARD_STATE")
    Define("EV_NOOB_SURVEY_AWARD_STATE")

    Define("EV_NOOB_GUIDE_AWARD")
    Define("EV_NOOB_SURVEY_AWARD")

    Define("EV_UPDATE_CLEAR_RESERVATION")

    Define("EV_POINT_LOCATE")
    Define("EV_TEAM_MEMBER_POINT_LOCATE")
    Define("EV_POINT_DROP_ITEM_LOCATE")

    Define("EV_UI_PUSH_AWARD")
    Define("EV_PUSH_LOBBY_AWARD")

    --client log event
    Define("EV_CLIENT_LOG_EVENT_ACCOUNT_LOGIN")
    Define("EV_CLIENT_LOG_EVENT_ACCOUNT_LOGOUT")
    Define("EV_CLIENT_LOG_EVENT_RETURN_TO_START_GAME")
    Define("EV_CLIENT_LOG_EVENT_ROLE_LOGIN")
    Define("EV_CLIENT_LOG_EVENT_ROLE_LOGOUT")
    Define("EV_CLIENT_LOG_EVENT_ROLE_LEVEL_UP")
    Define("EV_CLIENT_LOG_EVENT_PAY_FINISH")
    Define("EV_CLIENT_LOG_EVENT_MISSION_BEGIN")
    Define("EV_CLIENT_LOG_EVENT_MISSION_SUCCESS")
    Define("EV_CLIENT_LOG_EVENT_MISSION_FAIL")
    Define("EV_CLIENT_LOG_EVENT_CURRENCY_GAIN")
    Define("EV_CLIENT_LOG_EVENT_CURRENCY_PURCHASED")
    Define("EV_CLIENT_LOG_EVENT_CURRENCY_CONSUME")
    Define("EV_CLIENT_LOG_EVENT_ITEM_GAIN")
    Define("EV_CLIENT_LOG_EVENT_ITEM_CONSUME")
    Define("EV_CLIENT_LOG_EVENT_LOAD_RESOURCE")
    Define("EV_CLIENT_LOG_EVENT_LOAD_CONFIG")
    Define("EV_CLIENT_LOG_EVENT_OPEN_ANNOUNCEMENT")
    Define("EV_CLIENT_LOG_EVENT_CLOSE_ANNOUNCEMENT")
    Define("EV_CLIENT_LOG_EVENT_NEW_USER_MISSION")
    Define("EV_CLIENT_LOG_EVENT_AWARD_GAIN")
    Define("EV_CLIENT_LOG_EVENT_LOADING_TRANSFORM")
    Define("EV_CLIENT_LOG_EVENT_GUIDE_END")
    Define("EV_CLIENT_LOG_EVENT_IMAGE_QUALITY_CHANGE")

    Define("EV_REFRESH_RETRY_CONNECT_DIALOG")
    Define("EV_CLOSE_RETRY_CONNECT_DIALOG")
    Define("EV_MELEE_COMBO_ATTACK_BGEIN")
    Define("EV_MELEE_COMBO_ATTACK_OVER")

    Define("EV_SEND_COIN_SUCCESS")
	Define("EV_TEAM_ORDER_RESULT")
    Define("EV_LOBBYMAIN_BLEND_CAMERA_END")
    Define("EV_LOBBY_TEAM_INVITE_APPLY_WAIT_TIME_OUT")
    Define("EV_SHOW_TOOL_TIP")
    Define("EV_LOBBY_MATCHMAKING_MODE_CHANGED")
    Define("EV_LOBBY_TEAM_POP_MENU")
    Define("EV_UPGRADE_DECORATION_FINISH")

    Define("EV_PLAY_SHIP_TO_HUMAN_ANI")
    Define("EV_VIEWPORT_RESIZED")
    Define("EV_GET_FRIEND_RELATIONS")
    Define("EV_LOBBY_MAIN_PLAYER_SUMMARY_CHANGE")
    Define("EV_PARACHUTE_SHOW_PLAYER")

    -- DLC
    Define("EV_DLC_FINISHED")
    Define("EV_DLC_FAILED")
    Define("EV_DLC_PROGRESS")
end

ClientEventDef.Init()

return ClientEventDef
