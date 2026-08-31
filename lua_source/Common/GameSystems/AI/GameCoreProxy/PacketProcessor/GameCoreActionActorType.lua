local GameCoreActionActorType = { }

GameCoreActionActorType.Human = 1 << 1
GameCoreActionActorType.Ship = 1 << 2
GameCoreActionActorType.Horse = 1 << 3
GameCoreActionActorType.All = GameCoreActionActorType.Human | GameCoreActionActorType.Ship | GameCoreActionActorType.Horse
GameCoreActionActorType.HumanAndShip = GameCoreActionActorType.Human | GameCoreActionActorType.Ship

return GameCoreActionActorType