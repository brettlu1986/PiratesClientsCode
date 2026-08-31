local ManagerGroupDef = {}

ManagerGroupDef.nImmortalGroupID = 0    -- 启动游戏到终止游戏一直存在
ManagerGroupDef.nDefaultGroupID = 1     -- 默认组，会在Procedure_Update初始化，回到更新流程会Uninit
ManagerGroupDef.nLoginGroupID = 2     -- 登录组，会在Procedure_Login初始化，退出Login会Uninit
ManagerGroupDef.nLobbyGroupID = 3     -- 大厅组
ManagerGroupDef.nHubGroupID = 4        -- 野外大世界，Procedure_WildWorld初始化， Procedure_WildWold离开时Uninit
ManagerGroupDef.nBattleGroupID = 5      -- 战斗，Procedure_Battle初始化，Procedure_Battle离开时Uninit
ManagerGroupDef.nHomelandGroupID = 6    -- 家园组

return ManagerGroupDef