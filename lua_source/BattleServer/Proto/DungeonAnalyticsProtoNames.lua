local Proto = {}

---------------------------------------------
-- export from src\dungeon_analytics.proto begin

--
-- Analytics messages for Dungeon
--




-- 每局游戏中，以系统自动弹出选点界面对应的时间作为局内时间轴起点。
-- ============================================================================
Proto.BattleTeamMode = {
	SINGLE  = 0, 					
	DOUBLE  = 1, 					
	FOUR    = 2, 					
}

Proto.BattleGameModeInfo = {
	CLASSIC  = 0, 	--经典模式							
}

-- ============================================================================
-- 对战

-- 对局总体统计
Proto.BattleState = "BattleState"


Proto.PlayerBattleStart = "PlayerBattleStart"


Proto.PlayerBattleEnd = "PlayerBattleEnd"

Proto.PlayerBattleEnd_BattleResult = {
		RESULT_WIN             = 0, --吃鸡
		RESULT_DEAD            = 1, --战死
		RESULT_WAIT_STAGE_EXIT = 2, --集合区逃跑
		RESULT_BATTLE_EXIT     = 3, --跳伞后逃跑
}

Proto.PlayerBattleEnd_LandingPointType = {
		TYPE_MANUAL   = 0, --手动
		TYPE_AUTO     = 1, --自动
		TYPE_FOLLOW   = 2, --跟随
}

Proto.PlayerBattleEnd_PlayerShape = {
		HUMAN   = 0,  --人形态
		SHIP    = 1,  --船形态
}

-- 坐标信息, 需程序确认是否好实现
Proto.GridRegionType = {
	LAND  = 0, --陆地
	OCEAN = 1, --海洋
	ROCK  = 2, --礁石
}

Proto.LocationInfo = "LocationInfo"

Proto.BattleItemCategory = {
	UNVALID                  = 0,   -- 未知分类
    MATERIAL                 = 11,  -- 材料
	SHIP_WEAPON              = 12,  -- 船的武器
	SHIP_PART                = 13,  -- 船的零件
    SHIP_WEAPON_ATTACHMENT   = 14,  -- 船的武器配件
	HUMAN_WEAPON             = 18,  -- 人的武器
	HUMAN_ARMOR              = 19,  -- 人的护甲
	HUMAN_WEAPON_ATTACHMENT  = 20,  -- 人的武器配件
	HUMAN_CONSUMABLE         = 21,  -- 消耗品
	SHIP                     = 26,  -- 船
	HUMAN_THROWN_ITEM        = 27,  -- 投掷物
	BUILD_KEY_ITEM           = 28,  -- 建造图纸
	SPECIAL_ITEM             = 30,  -- 特殊道具，玩法和活动中出现
	SHIP_THROWN_ITEM         = 31,  -- 船投掷物
}

Proto.BattleItemDetail = "BattleItemDetail"

-- ============================================================================
--地图

-- 游戏内伤害类型定义汇总
-- UNKNOWN                 = 0,        -- 未知伤害
-- POISON_CIRCLE           = 101,      -- FFA毒圈
-- FALLING                 = 102,      -- 跌落
-- DYING_REDUCE            = 103,      -- 重伤下衰减
-- KILL_SELF               = 104,      -- 自杀逻辑所受伤害
-- DROWN                   = 105,      -- 溺水
-- SHIP_BEGIN              = 200,      -- 舰船伤害类型开始
-- SHIP_WEAPON_BEGIN       = 201,      -- 舰船武器伤害类型开始
-- SHIP_SMALL_CANNON       = 201,      -- 小钢炮           近射类
-- SHIP_POWDER_KEG         = 202,      -- 火药桶（鱼雷）    爆桶类
-- SHIP_CARRONADE          = 203,      -- 臼炮             臼炮类
-- SHIP_TORPEDO            = 204,      -- 水雷             陷阱类
-- SHIP_SAKER              = 205,      -- 霰弹炮           散射类
-- SHIP_DARTLE             = 206,      -- 转轮炮           速射类
-- SHIP_ASSAULT_GUN        = 207,      -- 加农炮           连射类
-- SHIP_SNIPE_GUN          = 208,      -- 长管炮           远射类
-- SHIP_EMBOLON            = 209,      -- 撞角             冲撞类
-- SHIP_FLAMER             = 210,      -- 喷火器           近战喷火器类
-- SHIP_STERN_CANNON       = 211,      -- 船尾炮           船尾炮类
-- SHIP_WEAPON_END         = 211,      -- 舰船伤害类型结束
-- SHIP_FIRING             = 251,      -- 船造成的点燃伤害
-- SHIP_LEAKING            = 252,      -- 船造成的漏水伤害
-- SHIP_BUMPING            = 253,      -- 船撞人的伤害
-- SHIP_END                = 299,      -- 舰船伤害类型结束
-- HUMAN_BEGIN             = 300,      -- 人伤害类型开始
-- HUMAN_EMPTY_HAND        = 301,      -- 人空手伤害
-- HUMAN_MELEE             = 302,      -- 人近战武器（刀）
-- HUMAN_PISTOL            = 303,      -- 人-手枪
-- HUMAN_FLINTLOCK         = 304,      -- 人-火绳枪
-- HUMAN_MATCHLOCK         = 305,      -- 人-燧发枪
-- HUMAN_CROSSBOW          = 306,      -- 人-弩
-- HUMAN_BOW               = 307,      -- 人-弓
-- HUMAN_GRENADE           = 308,      -- 手雷伤害
-- HUMAN_FIREBOMB          = 309,      -- 燃烧弹燃烧buff伤害
-- HUMAN_FLYINGKNIFE       = 310,      -- 飞刀
-- HUMAN_END               = 399,      -- 人伤害类型结束

-- 持续战斗总次数
Proto.TotalPersistentFight = "TotalPersistentFight"


-- 战斗，开火一下算一次
Proto.OnceFight = "OnceFight"


-- 玩家使用载具
Proto.Vehicle = "Vehicle"
Proto.Vehicle_VehicleType = {
		UNVALID = 0,
		HORSE = 1,
}

-- 玩家拾取信息
Proto.Pick = "Pick"

Proto.Pick_PickType = {
		NORMAL = 0,
		DEAD_BOX = 1,
}



-- 玩家建造信息
Proto.ItemBuild = "ItemBuild"



-- export from src\dungeon_analytics.proto end
---------------------------------------------

return Proto