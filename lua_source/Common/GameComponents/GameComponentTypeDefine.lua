local GameComponentTypeDefine = {}


GameComponentTypeDefine.tbClassType = {}
GameComponentTypeDefine.tbClassType.PlayerSelf  = 1
GameComponentTypeDefine.tbClassType.PlayerOther = 1<<1
GameComponentTypeDefine.tbClassType.Npc         = 1<<2
GameComponentTypeDefine.tbClassType.Player      = GameComponentTypeDefine.tbClassType.PlayerSelf|GameComponentTypeDefine.tbClassType.PlayerOther
GameComponentTypeDefine.tbClassType.Character   = GameComponentTypeDefine.tbClassType.Player|GameComponentTypeDefine.tbClassType.Npc
GameComponentTypeDefine.tbClassType.Trigger     = 1<<3
GameComponentTypeDefine.tbClassType.Dummy       = 1<<4
GameComponentTypeDefine.tbClassType.AtmoSphereNpc = 1<<5
GameComponentTypeDefine.tbClassType.AtmoSphereShipNpc = 1<<6
GameComponentTypeDefine.tbClassType.Horse =  1<<7
GameComponentTypeDefine.tbClassType.Vehicle = GameComponentTypeDefine.tbClassType.Horse
GameComponentTypeDefine.tbClassType.DestructibleObject = 1<<8

GameComponentTypeDefine.tbEnvironmentType = {}
GameComponentTypeDefine.tbEnvironmentType.BattleClient = 1
GameComponentTypeDefine.tbEnvironmentType.BattleServer = 1 << 1
GameComponentTypeDefine.tbEnvironmentType.Battle = GameComponentTypeDefine.tbEnvironmentType.BattleClient | GameComponentTypeDefine.tbEnvironmentType.BattleServer
GameComponentTypeDefine.tbEnvironmentType.Lobby = 1 << 2
GameComponentTypeDefine.tbEnvironmentType.All = GameComponentTypeDefine.tbEnvironmentType.Battle | GameComponentTypeDefine.tbEnvironmentType.Lobby


GameComponentTypeDefine.tbActorType = {}
GameComponentTypeDefine.tbActorType.None = 0
GameComponentTypeDefine.tbActorType.Ship = 1<<1
GameComponentTypeDefine.tbActorType.Human = 1<<2
GameComponentTypeDefine.tbActorType.ShipCollection = 1<<3
GameComponentTypeDefine.tbActorType.HumanCollection = 1<<4
GameComponentTypeDefine.tbActorType.Vehicle = 1<<5
GameComponentTypeDefine.tbActorType.DestructibleObject = 1<<6
GameComponentTypeDefine.tbActorType.Collection = GameComponentTypeDefine.tbActorType.ShipCollection | GameComponentTypeDefine.tbActorType.HumanCollection
GameComponentTypeDefine.tbActorType.All = GameComponentTypeDefine.tbActorType.Ship | GameComponentTypeDefine.tbActorType.Human | GameComponentTypeDefine.tbActorType.ShipCollection | GameComponentTypeDefine.tbActorType.HumanCollection


GameComponentTypeDefine.tbLifeCycleType =
{
    WithGameObject =   1,
    WithUEActor    =   2,
    WithUEController  = 3,
}


return GameComponentTypeDefine
