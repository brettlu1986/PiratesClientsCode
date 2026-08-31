local CommonEventDef = {}

-- Common消息从1000 - 9999
-- Client消息从10000 - 49999
-- Server消息从50000 - 99999

local nNextEventId = 1000
local function Define(szEventName)
    CommonEventDef[szEventName] = nNextEventId
    nNextEventId = nNextEventId + 1
end

function CommonEventDef.Init()
    --Mock
    Define("EV_GAME_MODE_TRY_MOCK_PLAYER_DATA")
    Define("EV_GAME_MODE_TRY_MOCK_APPROVE_LOGIN")

    -- GameMode
    Define("EV_GAME_MODE_PRE_START_PLAY")
    Define("EV_GAME_MODE_START_PLAY")
    Define("EV_GAME_MODE_END_PLAY")
    Define("EV_GAME_MODE_ON_PLAYER_LOGIN")
    Define("EV_GAME_MODE_ON_PLAYER_RELOGIN") --重连成功
    Define("EV_GAME_MODE_ON_PLAYER_LOGOUT")
    Define("EV_GAME_MODE_ON_FINISHED")
    Define("EV_GAME_MODE_PRE_ON_ALL_PLAYER_LOGOUT")
    Define("EV_GAME_MODE_ON_ALL_PLAYER_LOGOUT")
    Define("EV_GAME_MODE_ON_NO_PLAYER_ENTER")
    Define("EV_GAME_MODE_ON_RELEASE_DUNGEON")

    Define("EV_SKILL_GLOBAL_CD_STARTED")

    Define("EV_BATTLE_PLAYER_LOGOUT")
    Define("EV_BATTLE_PLAYER_POST_LOGOUT")
    Define("EV_BATTLE_STEP_START")
    Define("EV_BATTLE_STEP_COMPLETE")
    Define("EV_BATTLE_TARGET_START")
    Define("EV_BATTLE_TARGET_COMPLETE")
    Define("EV_BATTLE_STEP_RESET")

    Define("EV_BATTLE_DUNGEON_END")
    Define("EV_BATTLE_PLAYER_RESULT")

    Define("EV_GAME_SESSION_RECEIVED")

    -- 战斗中恢复玩家到出生点（位置根据FindPlayerStartJsonData方法获得）
    Define("EV_BATTLE_RESET_PLAYER_POSITION")

    Define("EV_BATTLE_TEAM_SCORE_CHANGE")
    Define("EV_BATTLE_OCCUPY_TYPE_CHANGE")

    Define("EV_SHOW_PVE_BATTLE_RESULT_AWARD")
    Define("EV_SHOW_PVP_BATTLE_RESULT_AWARD")

    --Battle ship actor Events
    --Define("EV_SHIP_BATTLE_PAWN_SELF_ON_BEGIN_PLAY")
    --Define("EV_SHIP_BATTLE_PAWN_SELF_ON_DESTROY")
    Define("EV_SHIP_BATTLE_ON_BEGIN_SPECTATING")
    Define("EV_SHIP_BATTLE_ON_END_SPECTATING")

    -- GameState
    Define("EV_GAME_STATE_ON_BEGIN_PLAY")
    Define("EV_GAME_STATE_ON_END_PLAY")

    --PlayerState
    Define("EV_PLAYER_STATE_ON_END_PLAY")

    -- GameObject
    Define("EV_GAME_OBJECT_POST_ACTOR_CREATE")
    Define("EV_GAME_OBJECT_POST_CREATE")
    Define("EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY")
    Define("EV_GAME_OBJECT_PRE_DESTORY")

    Define("EV_GAME_OBJECT_ON_PAWN_PRE_DEAD")
    Define("EV_GAME_OBJECT_ON_PAWN_DEAD_ONVEHICLE")
    Define("EV_GAME_OBJECT_ON_PAWN_DEAD")
    Define("EV_GAME_OBJECT_ON_PAWN_REBORN")
    Define("EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED")
    Define("EV_GAME_OBJECT_ON_PAWN_RESCUING_CHANGED")

    -- NPC
    Define("EV_GAME_OBJECT_ON_NPC_POST_CREATE")

    -- Trigger
    Define("EV_GAME_TRIGGER_ENTER")
    Define("EV_GAME_TRIGGER_LEAVE")
    Define("EV_PLAYER_ENTER_TRIGGER")
    Define("EV_PLAYER_LEAVE_TRIGGER")

    -- AreaManager
    Define("EV_GAME_AREA_ENTER")
    Define("EV_GAME_AREA_LEAVE")
    Define("EV_GAME_ACTOR_ENTER_TRIGER_GROUP")
    Define("EV_GAME_ACTOR_LEAVE_TRIGER_GROUP")

    -- BattleMatinee
    Define("EV_BATTLE_MATINEE_PLAY")
    Define("EV_BATTLE_MATINEE_END")

    -- Bot
    -- 机器人队友/对手开始战斗
    Define("EV_BATTLE_TEAM_BOT_START")

    --BattleInteraction
    Define("EV_BATTLE_INTERACTIONDLG_END")
    --npcstartNpcInteraction
    Define("EV_BATTLE_INTERACTIONDLG_START_NPC")
    --npcstartNpccollection
    Define("EV_BATTLE_COLLECTION_START_NPC")

    Define("EV_BATTLE_TEAM_ID_CHANGED")
    Define("EV_BATTLE_CAMP_TYPE_CHANGED")
    Define("EV_BATTLE_COLLECTION_END")
    Define("EV_BATTLE_COLLECTION_START")

    --进入npc交互范围
    Define("EV_BATTLE_TARIGGER_INTERACTION")

    --复活
    Define("EV_BATTLE_REVIVE_INFOANDSHOW")
    --复活结果
    Define("EV_BATTLE_REVIVE_RESULT")
    --重试副本
    Define("EV_RECEIVE_BATTLE_RETRY_GAME_FROM_HUB")
    --重试副本
    Define("EV_BATTLE_RETRY_GAME")
    --复活成功
    Define("EV_BATTLE_REVIVE_SUCCE")
    --自动战斗状态切换
    Define("EV_PLAYER_AUTO_BATTLE_STATE_CHANGED")

    --战斗统计
    Define("EV_BATTLE_DATA_STATISTICS_PLAYER_LUA_EVENT")

    --收到playerprepare信息
    Define("EV_ON_PLAYER_PREPARE")

    -- 释放技能
    Define("EV_PAWN_CAST_SKILL")

    -- GridTriggerManager
    --Define("EV_GAME_ACTOR_ENTER_VOLUME")
    --Define("EV_GAME_ACTOR_LEAVE_VOLUME")
    Define("EV_GRID_TYPE_CHANGED")

    -- Buff 相关
    Define("EV_TRIGGER_REMOVE_BUFF")
    Define("EV_ON_BUFF_ADD")
    Define("EV_ON_BUFF_REMOVE")
    Define("EV_ON_BUFF_REFRESH")

    -- 吃鸡玩法
    Define("EV_FFA_JUMP_FROM_TRANSPORTER")      -- 跳伞
    Define("EV_FFA_PARACHUTION_END")            -- 跳伞着地
    Define("EV_FFA_PARACHUTE_OPEN")             -- 开伞
    Define("EV_FFA_PARACHUTING_INFO")
    Define("EV_FFA_PARACHUTING_REACH_SEALEAVEL")             -- 到达海平面
    -- Define("EV_FFA_DESTRUCTIBLEOBJECT_TAKE_DAMAGE")     -- 可破坏物受到伤害
    -- Define("EV_FFA_DESTRUCTIBLEOBJECT_MESHCHANGE")     -- 可破坏物改变形态
    Define("EV_FFA_ENTER_POISONCIRCLE")         -- 进入毒圈
    Define("EV_FFA_LEAVE_POISONCIRCLE")         -- 离开毒圈
    Define("EV_FFA_POISONCIRCLE_INFO_CHANGED")         -- 毒圈
    Define("EV_FFA_SELECTION_POINT")            -- 选点
    Define("EV_FFA_BOT_AUTO_SELECTION_POINT_START") -- 机器人自动选点开始
    Define("EV_FFA_BOT_AUTO_SELECTION_POINT_END") -- 机器人自动选点结束
    Define("EV_FFA_MAP_SIGN")                   -- 标记
    Define("EV_FFA_PROCESS_STATE_CHANGED")      -- 流程状态改变
    Define("EV_FFA_ENTERPLAYER_SELECTPOINT")    -- 过了自动选点阶段，进入玩家
    Define("EV_FFA_AIRDROP_END")                -- 空投物落地

    Define("EV_ON_TAKE_DAMAGE")                     -- 受到伤害(tbTaker, tbCauser, nDamage, tbDamageExtraData)
    Define("EV_ON_TAKE_CURE")                       -- 角色收到治疗
    Define("EV_ON_MELEE_ATTACK")                    -- 近战攻击

    Define("EV_CREATE_AIRDROP_BOX")                        -- 创建空投宝箱

    Define("EV_ON_SHIP_ACTIVE_WEAPON_ITEM_CHANGED")             -- 激活的舰船武器改变(tbCharacter, NewActiveWeaponItem, OldActiveWeaponItem)
    Define("EV_ON_SHIP_AIM_STATE_CHANGED")                      -- 舰船开镜状态改变(tbCharacter, bIsInAim)
    Define("EV_ON_SHIP_TELESCOPE_SCALE_CHANGED")                -- 舰船准镜倍数改变
    Define("EV_ON_SHIP_WEAPON_EQUIPPED_SERVER")                 -- 舰船武器装备
    Define("EV_ON_SHIP_WEAPON_UNEQUIPPED_SERVER")               -- 舰船武器卸下
    Define("EV_ON_SHIP_WEAPON_FIRED_SERVER")                    -- 舰船武器开火
    Define("EV_ON_SHIP_WEAPON_FIRING_SUCCEED_SERVER")           -- 舰船武器进入CD
    Define("EV_ON_SHIP_WEAPON_BULLET_LOAD_BEGAN_SERVER")        -- 舰船武器子弹装载开始
    Define("EV_ON_SHIP_WEAPON_BULLET_LOAD_ENDED_SERVER")        -- 舰船武器子弹装载结束
    Define("EV_ON_SHIP_WEAPON_FIRING_OPERATION_CHANGED_SERVER") -- 舰船武器开火状态改变(tbCharacter, WeaponItem, nFiringOperation)

    Define("EV_ON_SHIP_CANNON_FIRING_END")                  -- 舰船火炮武器开火
    Define("EV_ON_SHIP_CANNON_BULLET_BOOM")                 -- 舰船火炮武器炮弹爆炸

    Define("EV_ON_PLAYER_SHIP_TO_CHANGE_SERVER")           -- 开始换船
    Define("EV_ON_PLAYER_SHIP_CHANGED_SERVER")             -- 换船后

    -- Battle Item
    Define("EV_BATTLE_ITEM_EQUIPED_SERVER")     -- 装配物品
    Define("EV_BATTLE_ITEM_UNEQUIPED_SERVER")   -- 卸下物品
    Define("EV_AFTER_BATTLE_ITEM_UNEQUIPED_SERVER")   -- 卸下物品把数据同步给client之后

    Define("EV_BATTLE_ITEM_ADD_SERVER")                 -- 增加物品
    Define("EV_BATTLE_ITEM_REMOVE_SERVER")              -- 移除物品
    Define("EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_SERVER")          -- 物品换位置
    Define("EV_BEFORE_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_SERVER")  -- 两个已装备物品交换位置之前
    Define("EV_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_SERVER")        -- 两个已装备物品交换位置
    Define("EV_BATTLE_ITEM_CHANGE_DURABILITY_SERVER")   -- 物品修改耐久
    Define("EV_BATTLE_ITEM_CHANGE_STACKCOUNT_SERVER")   -- 物品修改叠加数量
    Define("EV_BATTLE_ITEM_EQUIP_BULLET_WHEN_ADDED_FIRST_TIME_SERVER")   -- 当第一次加道具时装子弹
    Define("EV_DECREASE_PLAYER_BATTLE_ITEM_SERVER")     -- 扣除玩家道具（弹药，投掷物，消耗品）
    Define("EV_BATTLE_ITEM_RESET_AFTER_RELOGIN_SERVER") -- 玩家断线重连之后重置道具数据

    Define("EV_BATTLE_ITEM_REQUEST_PICK_UP_SERVER")     -- 请求拾取
    Define("EV_BATTLE_ITEM_PICK_UP_FINISH_SERVER")      -- 拾取成功
    Define("EV_BATTLE_ITEM_PICK_UP_REMAIN_SERVER")      -- 拾取后剩在地上的道具

    Define("EV_BATTLE_ITEM_AFTER_PICK_UP_SERVER")      -- 拾取成功后广播下InstanceId

    Define("EV_BATTLE_PRE_THROW_AWAY_ITEM_SERVER")      -- 丢弃物品之前
    Define("EV_BATTLE_THROW_AWAY_ITEM_FINISH_SERVER")   -- 丢弃物品之后

    Define("EV_SCENE_ITEM_ADD")  -- 场景中增加道具
    Define("EV_SCENE_ITEM_REMOVE")  -- 场景中移除道具
    Define("EV_SCENE_ITEM_ADD_DIE_BOX")  -- 场景中增加死亡盒子
    Define("EV_SCENE_ITEM_ADD_BOX")  -- 场景中增加盒子

    -- Battle Item Build
    Define("EV_BATTLE_ITEM_BUILD_FINISH_SERVER")       -- 建造物品成功
    Define("EV_BATTLE_ITEM_BUILD_CANCEL_SERVER")       -- 建造物品取消
    Define("EV_SHIP_BUILD_FINISH_SERVER")              -- 建造船成功
    Define("EV_SHIP_BUILD_GRADE_CHANGED_SERVER")       -- 可建造的船的等级发生改变

    -- Human weapon
    Define("EV_HUMAN_WEAPON_STATE_CHANGED")             -- 人武器状态改变
    Define("EV_HUMAN_CURRENT_WEAPON_CHANGED")           -- 人当前武器改变
    Define("EV_HUMAN_WEAPON_AMMO_CHANGED_SERVER")       -- 人武器子弹变化
    Define("EV_HUMAN_AIM_CHANGED")                      -- 人物瞄准切换
    Define("EV_HUMAN_WEAPON_RELOADED_ACTIVATE")         -- 人武器装弹开始
    Define("EV_HUMAN_WEAPON_RELOADED_DEACTIVATE")       -- 人武器装弹结束
    Define("EV_HUMAN_WEAPON_THROW_FINISHED")            -- 投掷物已经结束投掷
    Define("EV_HUMAN_WEAPON_ON_EQUIPED_POST")           -- 人装备武器完成
    Define("EV_HUMAN_WEAPON_SUB_STATE_CHANGE")          -- 人武器sub state状态改变
    Define("EV_HUMAN_WEAPON_ATTACK_IN_SERVER")          -- 人武器开火时
    --throw item standalone event
    Define("EV_HUMAN_WEAPON_STANDALONE_THROW_FINISHED") -- 投掷物已经结束投掷

    Define("EV_HUMAN_WEAPON_ON_EQUIPED_SERVER")         -- 人装备武器
    Define("EV_HUMAN_WEAPON_ON_UNEQUIPED_SERVER")       -- 人卸下武器
    Define("EV_HUMAN_WEAPON_ATTACHMENT_ON_EQUIPED_SERVER")  -- 人装备武器配件
    Define("EV_HUMAN_WEAPON_ATTACHMENT_ON_UNEQUIPED_SERVER")-- 人卸下武器配件
    Define("EV_HUMAN_ARMOR_ON_EQUIPED_SERVER")          -- 人装备护甲
    Define("EV_HUMAN_ARMOR_ON_UNEQUIPED_SERVER")        -- 人卸下护甲
    Define("EV_HUMAN_WEAPON_FIRE_TYPE_CHANGED_SERVER")  -- 人枪切换制式
    Define("EV_HUMAN_WEAPON_ATTACHMENT_CHANGED_SERVER") -- 人武器换配件
    Define("EV_HUMAN_WEAPON_DAMAGE")                    -- 人武器造成伤害

    Define("EV_START_CHANGEDISPLAY")        -- 开始人船变换
    Define("EV_END_CHANGEDISPLAY")          -- 结束人船变换

    Define("EV_INIT_GAME_MODE_COMPLETE")    -- 初始化gamemode结束
    Define("EV_INTERRUPT_CONTINUOUS_RUN")       --打断疾跑

    Define("EV_HUMAN_MOVEMENT_STATE_CHANGED")   --打断疾跑
    Define("EV_HUMAN_CONTINUE_RUN_RECOVER")     --检查是否需要恢复疾跑状态
    Define("EV_HUMAN_SWIMMING_STAMINA_CHANGE")     --检查是否需要恢复疾跑状态
    Define("EV_DIAMOND_REFRESH_TIME_ON_MAP_CHANGED")  --地图上看见最近的宝石的刷新时间间隔改变

    Define("EV_ENTER_TRANSPORT_STEP")       --进入运输船阶段
    Define("EV_ENTER_JUMP_AREA")            --进入跳伞区域



    Define("EV_FREE_VIEW_FIGHT_UP")         --小眼睛触摸在 攻击按钮抬起
    Define("EV_FIGHT_BTN_FREE_UP")          --攻击按钮触摸 在小眼睛抬起

    -- Consumable item.
    Define("EV_CONSUMABLE_ITEM_CONSUME_SUCCESS")    -- 消耗品使用成功, nCharacterServerInstanceId, nItemTemplateId, nCount

    -- OLD_PVP
    Define("EV_ENTER_PVPOCCUPY_STEP")           --进入占圈阶段

    -- progressbar
    Define("EV_PROGRESS_CHANGED")

    -- 濒死状态
    Define("EV_PLAYER_ENTER_DYING_STATE")
    Define("EV_PLAYER_EXIT_DYING_STATE")

    Define("EV_REQUEST_CHANGE_WATCH_MATE")
    Define("EV_REQUEST_CHANGE_WATCH_OTHER")
    Define("EV_CHANGE_WATCH_MATE")
    Define("EV_STOP_WATCH_MATE")
    Define("EV_MATE_CHANGE_AIM_STATE")
    Define("EV_MATE_MOVEMENT_STATE")
    Define("EV_MATE_BULLET_CHANGED")
    Define("EV_MATE_KILL_INFO_CHANGED")
    Define("EV_MATE_CARRONADE_ACTIVE_CHANGE")
    Define("EV_WATCH_MATE_TIPS")
    Define("EV_WATCH_MATE_ON_VEHICLE")
    Define("EV_DUNGEON_GAME_OVER")
    Define("EV_MEMBER_ENTER_WATCH")
    Define("EV_MEMBER_LEAVE_WATCH")

    --改变毒圈中心位置 （为了测试）
    Define("EV_MODIFY_POISONCIRCLE_POS")

    Define("EV_HUMAN_WEAPON_CHEAT_ATTACK")        -- AI攻击事件

    --battle聊天
    Define("EV_BATTLECHAT_TEAM_NEW_MSG")   --副本内队内聊天消息

    --和hubserver断开连接
    Define("EV_ON_DISCONNECT_WITH_HUB")
    --movement 影响aim 状态
    Define("EV_MOVEMENT_CRAWL_CHANGE_AIM_STATE")

    Define("EV_ACTIVE_CRAWL_CAMERA")
    Define("EV_DEACTIVE_CRAWL_CAMERA")
    -- 载具
    Define("EV_ON_VEHICLE_STATE_CHANGE")
    Define("EV_ON_VEHICLE_DEAD")

    -- 移动距离
    Define("EV_STATS_MOVEMENTDISTANCE")
    -- 金币复活
    Define("EV_STATS_PAIDREVIVE")

    -- NPC AI 仇恨
    Define("EV_NPC_ENMITY_ADD")
    Define("EV_NPC_ENMITY_CLEAR")

    --额外胜利选择结果
    Define("EV_ADDITIONALSUCCESS_ENABLE")
    Define("EV_ADDITIONALSUCCESS_CHOICE")
    Define("EV_ADDITIONALSUCCESS_RESULT")
    Define("EV_ADDITIONALSUCCESS_COUNT_UPDATE")

    -- NPC AI 警戒
    Define("EV_NPC_RISK_ALERT_FULL")
    Define("EV_NPC_RISK_ALERT_LEVEL_CHANGED")
    Define("EV_NPC_RISK_ALERT_FOUND_TARGET")
    Define("EV_NPC_RISK_ALERT_LOSE_TARGET")
    Define("EV_NPC_RISK_ALERT_RESET")

    --集合区逃跑
    Define("EV_FFA_WAIT_STAGE_LEAVE_DUNGEON")

    --战斗区逃跑
    Define("EV_FFA_BATTLE_STAGE_LEAVE_DUNGEON")

    --重连后刷新结算界面
    Define("EV_FFA_RELOGIN_REFRESH_BATTLE_RESULT")

    --队伍吃鸡获得胜利
    Define("EV_FFA_TEAM_WIN")

    --玩家吃鸡获得胜利
    Define("EV_FFA_PLAYER_WIN")

    --玩家切换到游泳状态
    Define("EV_NOTIFY_BOT_CHANGED_TO_SWIM")

    --该玩家战斗已经结束
    Define("EV_PLAYER_BATTLE_END")

    --该Team所有人战斗已经结束
    Define("EV_BATTLE_TEAM_BATTLE_END")

    --机器人队伍战斗结束
    Define("EV_BOT_TEAM_BATTLE_END")

    Define("EV_MORALE_PHASE_CHANGED")

    Define("EV_FFA_POISONCIRCLE_SHRINK_FINISH")         -- 毒圈收缩结束
    -- AI武器声音
    Define("EV_PERCEPTION_WEAPON_FIRE_SOUND")
    -- 毒圈数据初始化完成通知 仅用于GameCoreAgent模式
    Define("EV_POISONCIRCLE_DATA_INIT")
    -- 副本停止新的玩家进入
    Define("EV_NOTIFY_STOPACCEPTINGNEWPLAYERS")

    -- 毒圈收缩开始
    Define("EV_FFA_POISONCIRCLE_SHRINK_START")
    Define("EV_FFA_PRINT_POISONCIRCLE_INFO")
    Define("EV_SPAWN_TYPE_OVER")
    Define("EV_HUMAN_PICKUP_ACTION")

    --------数据埋点事件集合-------------
    Define("EV_LOG_BATTLE_BEGIN")
    Define("EV_LOG_BATTLE_END")
    -- Define("EV_LOG_CHOOSE_DROP_ZONE")
    -- Define("EV_LOG_DROP_LOCATION")
    -- Define("EV_LOG_CHANGE_DISPLAY")
    --------数据埋点事件集合结束----------

    Define("EV_BATTLE_TEAMINFO_CHANGED")
    Define("EV_AI_BATTLELOGIC_START")

	Define("EV_DOOR_SWITCHED")

    -- GameCore AI Event
    Define("EV_GAMECORE_AGENT_DESTROY")
    Define("EV_AI_POISON_CIRCLE_SHRINKING")
    Define("EV_GAMECORE_STATUS_CHANGED")

    Define("EV_SHIP_ARMOR_ON_EQUIPED_SERVER")
    Define("EV_SHIP_ARMOR_ON_UNEQUIPED_SERVER")

    Define("EV_PLAYER_ENTER_RESCUINGTRIGGER")
    Define("EV_PLAYER_LEAVE_RESCUINGTRIGGER")

    -- 反外挂检测
    Define("EV_CHEATER_CHECK")

    --Level相关
    Define("EV_LEVEL_ADDED_TO_WORLD")

    --AI 烟雾相关
    Define("EV_SPAWN_SMOKE")
    Define("EV_SPAWN_FOG_TRIGGER")

    Define("EV_ON_CHARACTER_ATTACKED") -- 玩家发起了一起攻击

    Define("EV_SHIP_WEAPON_ATTACHMENT_ON_EQUIPED_SERVER")  -- 船装备武器配件
    Define("EV_SHIP_WEAPON_ATTACHMENT_ON_UNEQUIPED_SERVER")-- 船卸下武器配件
end

CommonEventDef.Init()

return CommonEventDef
