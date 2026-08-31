local Proto = {}

---------------------------------------------
-- export from src\data.proto begin

-- For game data persistent and storage





--================================================================
-- 通用 message ，今后需要挪到 common.proto 以被 data.proto, dungeon.proto, client.proto import.
-- 暂时写在此处

Proto.GameResult = {
    GAME_WIN  = 0,
    GAME_LOSE = 1,
    GAME_TIE  = 2,
}

-- TODO rename removing 'Data' suffix
Proto.PlayerBattleStatsData = "PlayerBattleStatsData"

--================================================================

Proto.Transform = "Transform"

Proto.Vector3D = "Vector3D"

Proto.NavigationData = "NavigationData"

Proto.ItemType = "ItemType"

Proto.Currency = "Currency"

Proto.PlayerBasic = "PlayerBasic"

Proto.AvatarBodyPart = "AvatarBodyPart"

Proto.Avatar = "Avatar"

Proto.Scene = "Scene"


Proto.ShipEnhance = "ShipEnhance"

Proto.SupplyType = {
    GOLD = 0,
    SILVER = 1,
}

-- 船只消耗品槽位
Proto.ShipConsumableSlotId = {
    NONE = 0,                   -- 无效，占位

    CAMOUFLAGE = 1,             -- 船身涂装
    CANNONBALL = 2,             -- 炮弹
    FLAG1 = 3,                  -- 旗帜1
    FLAG2 = 4,                  -- 旗帜2
    FLAG3 = 5,                  -- 旗帜3
}

Proto.ShipConsumableSlot = "ShipConsumableSlot"

Proto.ShipItemSlotId = {
    ITEM_SLOT_NONE  = 0,                  -- 无效，占位
    ITEM_SLOT_CAMOUFLAGE = 1,             -- 船身涂装
    ITEM_SLOT_CANNONBALL = 2,             -- 炮弹
    ITEM_SLOT_FLAG1 = 3,                  -- 旗帜1
    ITEM_SLOT_FLAG2 = 4,                  -- 旗帜2
    ITEM_SLOT_FLAG3 = 5,                  -- 旗帜3

    ITEM_SLOT_FIGUREHEAD = 6,             -- 船首像
    ITEM_SLOT_SAIL   = 7,                 -- 船帆
    ITEM_SLOT_ANCHOR = 8,                 -- 船锚
    ITEM_SLOT_LIGHT  = 9,                 -- 船灯
}

Proto.ShipModpartSlot = "ShipModpartSlot"

Proto.Ship = "Ship"

Proto.SoldShip = "SoldShip"

Proto.ShipList = "ShipList"

Proto.ItemPosition = "ItemPosition"

Proto.Item = "Item"

-- 背包
Proto.Backpack = "Backpack"

Proto.ItemList = "ItemList"

-- Key-Value Pair that can store any integer data
Proto.KVP = "KVP"

Proto.TradeHistory = "TradeHistory"

Proto.TradeShop = "TradeShop"

Proto.RecommendCargo = "RecommendCargo"

Proto.PlayerTrade = "PlayerTrade"

-- 工坊生产进度
Proto.Workshop = "Workshop"

Proto.ArenaDivisionAward = "ArenaDivisionAward"
Proto.ArenaDivisionAward_State = {
        CAN_NOT_CLAIM = 0,
        CAN_CLAIM = 1,
        CLAIMED = 2,
}

Proto.ArenaStats = "ArenaStats"

Proto.ArenaGameLog = "ArenaGameLog"

-- 竞技场点数
Proto.Arena = "Arena"

-- 任务

Proto.AcceptedQuest = "AcceptedQuest"

Proto.CompletedQuest = "CompletedQuest"

Proto.Quest = "Quest"

-- 好友

-- 简要的玩家信息
Proto.PlayerInfo = "PlayerInfo"

Proto.Friend = "Friend"

--================================================================
-- 阵营 (Faction)

Proto.FactionInfo = "FactionInfo"

Proto.PlayerFaction2 = "PlayerFaction2"

--================================================================z
-- 邮件 

--附件
Proto.MailAttachment = "MailAttachment"
-- 邮件
Proto.Mail = "Mail"
-- 邮件
Proto.PlayerMail = "PlayerMail"

--================================================================z
-- 采集&捕捉
Proto.GatherAward = "GatherAward"

Proto.GatherInfo = "GatherInfo"

Proto.RandomGatherInfo = "RandomGatherInfo"

Proto.Gathers = "Gathers"

--==============================================================================
-- 商品购买记录
Proto.Goods = "Goods"

-- 商店记录
Proto.Shop = "Shop"

-- 所有的商店记录
Proto.Shops = "Shops"

--================================================================z
-- 公会
Proto.Guild = "Guild"

--================================================================z
-- Buff

Proto.Buff = "Buff"

Proto.PlayerBuff = "PlayerBuff"

--================================================================z
-- Dungeon

Proto.PlayerDungeon = "PlayerDungeon"

--================================================================z
-- Preview (for message s2c_PlayerList in login.proto)

Proto.PlayerPreview = "PlayerPreview"








Proto.Battleground = "Battleground"

Proto.PlayerCoOp = "PlayerCoOp"

--================================================================z
-- 玩家历程统计

Proto.BattleShipStats = "BattleShipStats"

Proto.StatsIndividual = "StatsIndividual"



Proto.StatsBattleRecord = "StatsBattleRecord"

Proto.PlayerBattleStats = "PlayerBattleStats"

-- 将 Player 定义放在最后
-- 为保证数据兼容性，废弃的字段需要 reserve tag/name
-- See: https://developers.google.com/protocol-buffers/docs/proto3#reserved
Proto.Player = "Player"


-- export from src\data.proto end
---------------------------------------------

return Proto