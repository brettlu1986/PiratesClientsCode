local Proto = {}

---------------------------------------------
-- export from src\dungeon_lobby.proto begin

--
-- Shared messages between lobby and dungeon.
--





-- 传入副本内的玩家数据
Proto.PlayerInfo = "PlayerInfo"





Proto.AccountAwardType = {
    REGULAR  = 0, -- 常规奖励, 不弹奖励窗
    SPECIAL  = 1, -- 特殊奖励, 弹出奖励窗口
}

Proto.Award = "Award"

-- 单人战斗数据
-- 会路由到玩家所在的 lobby 节点做结算处理
Proto.PlayerStats = "PlayerStats"





-- Team战斗数据
Proto.TeamStats = "TeamStats"


-- export from src\dungeon_lobby.proto end
---------------------------------------------

return Proto