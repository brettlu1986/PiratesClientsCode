local luaclass = require("luaclass")
local GameComponentRegister = luaclass("GameComponentRegister")

local GameComponentTypeDefine = require("GameComponentTypeDefine")
-- local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local C = GameComponentTypeDefine.tbClassType
local E = GameComponentTypeDefine.tbEnvironmentType
local A = GameComponentTypeDefine.tbActorType
local L = GameComponentTypeDefine.tbLifeCycleType

-- GameComponentCreateHelper:Register(szClassName, nType, nEnvironmentType, nActorType, nLifeCycleType, bDynamicRequire, szComponentName)
-- szClassName: require的component名称
-- nObjectType: Object的类别，值参考GameComponentTypeDefine.tbObjectClassType
-- nEnvironmentType：战斗或者公海，值参考GameComponentTypeDefine.tbEnvironmentType
-- nActorType：船或者人，值参考GameComponentTypeDefine.tbActorType
-- nLifeCycleType：Component的生命周期，WithUEActor：随着UEActor创建和销毁；WithGameObject，随着GameObject创建和销毁，与UEActor的生命周期无关
-- bDynamicRequire：是否需要dynamic_require
-- szComponentName：生成的成员变量名称，默认nil，生成和szClassName一样的成员变量，GameObject创建完Component后可以直接使用GameObject.ComponentName访问


function GameComponentRegister:RegisterComponents(GameComponentCreateHelper)
    local H = GameComponentCreateHelper

    H:Register("CustomReplicationComponent",    C.Character,    E.Battle,       A.Ship|A.Human,         L.WithUEActor,      false)
    H:Register("DelegateComponent",             C.Character,    E.Battle,       A.Ship|A.Human,         L.WithGameObject)
    H:Register("ShipBattlePropertyComponent",   C.Character,    E.Battle,       A.Ship|A.Human,         L.WithGameObject)
    H:Register("HumanBattlePropertyComponent",  C.Character,    E.Battle,       A.Ship|A.Human,         L.WithGameObject)

    -- GameCharacter
    H:Register("HumanAvatarComponentNew",       C.Character,    E.Battle,       A.Human,                L.WithUEActor,      true,  "HumanAvatarComponent")
    H:Register("ShipAvatarComponent",           C.Character,    E.Battle,       A.Ship,                 L.WithUEActor,      true)
    H:Register("BattleHumanMovementComponent",  C.Character,    E.Battle,       A.Human,                L.WithUEActor)
    H:Register("BattleShipMovementComponent",   C.Character,    E.Battle,       A.Ship,                 L.WithUEActor,      true)
    H:Register("BattleCampComponent",           C.Character,    E.Battle,       A.All,                  L.WithUEActor)
    H:Register("BuffComponentServer",           C.Character,    E.BattleServer, A.All,                  L.WithGameObject)
    H:Register("DamageCalculateComponent",      C.Character,    E.BattleServer, A.Ship|A.Human,         L.WithGameObject)
    H:Register("BattleDyingComponent",          C.Character,    E.BattleServer, A.Ship|A.Human,         L.WithGameObject)
    H:Register("BattleRescuingComponent",       C.Character,    E.BattleServer, A.Ship|A.Human,         L.WithGameObject,   true)
    H:Register("BattleItemComponentServer",     C.Character,    E.BattleServer, A.Ship|A.Human,         L.WithGameObject)
    H:Register("ProgressBarComponent",          C.Character,    E.Battle,       A.Ship|A.Human,         L.WithUEActor,      true)
    H:Register("ShipVisibilityComponent",       C.Character,    E.BattleServer, A.Ship,                 L.WithUEActor)
    H:Register("HumanConcealComponent",         C.Character,    E.Battle,       A.Human,                L.WithUEActor,      true)
    H:Register("BattleShipWeaponComponent",     C.Character,    E.Battle,       A.Ship|A.Human,         L.WithGameObject)

    -- npc应该也有这个玩意
    H:Register("HumanWeaponComponentNew",       C.Character,    E.Battle,       A.Human,                L.WithUEActor,      true,  "HumanWeaponComponent")
    H:Register("HumanMovementStateComponent",   C.Character,    E.Battle,       A.Human,                L.WithUEActor,      true)
    H:Register("HumanWeaponAvatarComponentNew", C.Character,    E.Battle,       A.Human,                L.WithUEActor,      true,  "HumanWeaponAvatarComponent")
    H:Register("ShipWeaponAttachmentComponent", C.Character,    E.Battle,       A.Ship,                 L.WithGameObject,   true)
    H:Register("HumanVehicleComponent",         C.Character,    E.Battle,       A.Human,                L.WithUEActor,      true,   "GameVehicleComponent")
    H:Register("SAIComponent",                  C.Character,    E.BattleServer, A.Ship|A.Human,         L.WithGameObject)

    -- GamePlayer
    H:Register("ConsumableItemComponentServer", C.Player,       E.BattleServer, A.Ship|A.Human,         L.WithGameObject,   true)
    H:Register("BattleTeamComponent",           C.Player,       E.Battle,       A.All,                  L.WithGameObject,   true)
    H:Register("BattleShipSkinComponent",       C.Player,       E.Battle,       A.All,                  L.WithGameObject)
    H:Register("WatchBattleComponent",          C.PlayerSelf,   E.Battle,       A.Ship|A.Human,         L.WithGameObject,   true)

    -- GamePlayerSelf
    H:Register("SkillComponentServer",          C.PlayerSelf,   E.BattleServer, A.Ship|A.Human,         L.WithGameObject)
    H:Register("ShipMoraleComponent",           C.PlayerSelf,   E.Battle,       A.Ship|A.Human,         L.WithGameObject)
    H:Register("HumanMoraleComponent",          C.PlayerSelf,   E.Battle,       A.Ship|A.Human,         L.WithGameObject)
    H:Register("PropertyComboComponent",        C.PlayerSelf,   E.BattleServer, A.Ship|A.Human,         L.WithGameObject)

    -- GamePlayerOther

    -- GameNpc
    H:Register("NpcAIStateComponent",           C.Npc,          E.Battle,       A.Ship|A.Human,         L.WithUEActor,      true)

    -- GameTrigger
    H:Register("BattleTriggerComponent",        C.Trigger,      E.Battle,       A.All,                  L.WithUEActor)

    -- Vehicle

    H:Register("CustomReplicationComponent",    C.Vehicle,      E.Battle,       A.Vehicle,              L.WithUEActor,      false)
    H:Register("VehicleMovementComponent",      C.Vehicle,      E.Battle,       A.Vehicle,              L.WithUEActor,      true)
    H:Register("VehiclePropertyComponent",      C.Vehicle,      E.Battle,       A.Vehicle,              L.WithUEActor)
    H:Register("VehicleBattleDyingComponent",   C.Vehicle,      E.Battle,       A.Vehicle,              L.WithUEActor,      false, "BattleDyingComponent")
    H:Register("BuffComponentServer",           C.Vehicle,      E.BattleServer, A.Vehicle,              L.WithGameObject)

    -- GameDummy

    -- 有潜在需求的先留着
    -- H:Register("BattleFactionComponent",        C.Player,       E.BattleServer, A.Ship,              L.WithUEActor)
    -- H:Register("BattlePlayerStateComponent",    C.PlayerSelf,   E.Battle,       A.Ship,              L.WithUEController)

    -- Destructible Object
    H:Register("DestructibleObjectPropertyComponent",       C.DestructibleObject,      E.Battle,       A.DestructibleObject,              L.WithUEActor)
    H:Register("DestructibleObjectAIComponent",             C.DestructibleObject,      E.BattleServer, A.DestructibleObject,              L.WithUEActor)
    H:Register("BuffComponentServer",                       C.DestructibleObject,      E.BattleServer, A.DestructibleObject,              L.WithGameObject)
end

return GameComponentRegister
