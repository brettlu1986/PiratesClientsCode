local Proto = {}

---------------------------------------------
-- export from src\dungeon.proto begin

-- For communication between hubserver and dungeon dedicated server.





-- d2s == dungeon to hubserver
-- Dungeon register to hubserver
-- NOTE: This proto message is used in c++ source code rather than lua.
-- Modify the definition of this message will cause c++ runtime error. Please make sure to make
-- corresponding adjustment in c++ source code.
Proto.d2s_Register = "d2s_Register"

Proto.BotInfo = "BotInfo"

Proto.PlayerInfo = "PlayerInfo"

-- Tell dungeon to prepare for client to connect
Proto.s2d_PlayerPrepare = "s2d_PlayerPrepare"

Proto.d2s_PlayerReady = "d2s_PlayerReady"

-- Notify hubserver that player has entered the dungeon.
Proto.d2s_PlayerEnter = "d2s_PlayerEnter"

-- Notify hubserver game start
Proto.d2s_GameStart = "d2s_GameStart"

-- Notify hubserver that player has left the dungeon.
Proto.d2s_PlayerExit = "d2s_PlayerExit"

-- Notify hubserver match end and ask hub to pull players back to hub
Proto.d2s_MatchEnd = "d2s_MatchEnd"

-- Notify hubserver that the dungeon has reset and is ready to be reused
Proto.d2s_DungeonRelease = "d2s_DungeonRelease"

-- Player press "quit" button before game end
Proto.d2s_QuitDungeon = "d2s_QuitDungeon"
Proto.d2s_QuitDungeon_QuitReason = {
        QUIT_BUTTON = 0, -- 游戏中点击退出副本按钮
        BACK_TO_PORT = 1, -- 死亡后不花钱原地复活，而选择退出副本回城选项
}

-- Player leaves dungeon. Player early exits when displaying game result.
Proto.d2s_LeaveDungeon = "d2s_LeaveDungeon"

-- 该玩家因为部分原因被副本踢掉了
Proto.d2s_PlayerKicked = "d2s_PlayerKicked"

Proto.s2d_KickPlayer = "s2d_KickPlayer"

-- Tell dungeon player has left dungeon and will not be back. It's safe to do cleanup task like
-- destroy actor, calculate player result, etc.
Proto.s2d_NotifyPlayerLeave = "s2d_NotifyPlayerLeave"

-- 停止接收新玩家（异步过程，直到 s2d_StopAcceptingNewPlayers 收到后，才不会收到新的 s2d_PlayerPrepare
-- 玩家的进入行为不受此限制）
Proto.d2s_StopAcceptingNewPlayers = "d2s_StopAcceptingNewPlayers"

-- 响应停止接收新玩家
Proto.s2d_StopAcceptingNewPlayers = "s2d_StopAcceptingNewPlayers"

-- ============== ffa ===============================
-- 阻止进入吃鸡副本
Proto.d2s_LoginRejected = "d2s_LoginRejected"
Proto.d2s_LoginRejected_Reason = {
        GAME_HAS_STARTED = 0, -- 游戏已经开始，过了准备阶段
}

-- 吃鸡结果
Proto.d2s_FFAResult = "d2s_FFAResult"

Proto.s2d_GameSession = "s2d_GameSession"

Proto.RevisionCheckInfo = "RevisionCheckInfo"
Proto.RevisionCheckInfo_Platform = {
        UNKNOWN = 0,
        IOS     = 1,
        ANDROID = 2,
        WINDOWS = 3,
}


-- Both dungeon and dungeon proxy use this message
Proto.Ping = "Ping"

-- export from src\dungeon.proto end
---------------------------------------------

return Proto