local luaclass = require("luaclass")
local GameComponentRegisterClass = require("GameComponentRegister")
local GameComponentRegister_C = luaclass("GameComponentRegister_C", GameComponentRegisterClass)

local GameComponentTypeDefine = require("GameComponentTypeDefine")

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


function GameComponentRegister_C:RegisterComponents(GameComponentCreateHelper)
    GameComponentRegister_C.super.RegisterComponents(self, GameComponentCreateHelper)

    local H = GameComponentCreateHelper

    -- GameCharacter
    H:Register("BuffComponentClient",           C.Character,    E.Battle,       A.All,                  L.WithGameObject)
    -- 由于如果在common里注册成all会导致mock模式下没有此component，故分开在common里注册给battle，在client里注册给lobby
    H:Register("HumanAvatarComponentNew",       C.Player,       E.Lobby,        A.Human,                L.WithGameObject,   true,   "HumanAvatarComponent")
    H:Register("AppearanceComponent",           C.PlayerSelf,   E.Lobby,        A.Human,                L.WithGameObject)

    -- GamePlayer
    H:Register("ConsumableItemComponentClient", C.Player,       E.Battle,       A.Ship|A.Human,         L.WithGameObject)
    H:Register("CameraComponent",               C.Player,       E.BattleClient, A.Ship|A.Human,         L.WithUEActor,      false)

    -- GamePlayerSelf
    H:Register("BattleItemComponentClient",     C.PlayerSelf,   E.Battle,       A.Ship|A.Human,         L.WithGameObject)
    H:Register("ItemComponent",                 C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("SailorComponent",               C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("PartnerComponent",              C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("ShipPreparationComponent",      C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("WearComponent",                 C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("LobbyPropertyComponent",        C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)   -- 大厅的人物属性都放这里，人船都放
    H:Register("FriendComponent",               C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("CurrencyComponent",             C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("SeasonComponent",               C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("TeamComponent",                 C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("HomelandComponent",             C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("ShopComponent",                 C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("StatsComponent",                C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("PlayerTriggerComponent",        C.PlayerSelf,   E.Battle,       A.Ship|A.Human,         L.WithGameObject)
    H:Register("ScheduleComponent",             C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("PlayerNewItemRecordComponent",  C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject)
    H:Register("ItemBuffComponent",             C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject,   false)
    H:Register("WelfareComponent",              C.PlayerSelf,   E.All,          A.Ship|A.Human,         L.WithGameObject,   false)
    H:Register("SoundListenComponent",          C.PlayerSelf,   E.Battle,       A.Ship|A.Human,         L.WithGameObject,   false)
    H:Register("SkillComponentClient",          C.PlayerSelf,   E.Battle,       A.Ship|A.Human,         L.WithGameObject)
    -- H:Register("PlayerHeadInfo3DComponent",     C.PlayerSelf,   E.BattleClient, A.Ship|A.Human,         L.WithUEActor,      false)
    H:Register("BattleRescuingComponent",       C.PlayerSelf,   E.BattleClient, A.Ship|A.Human,         L.WithGameObject,   true)
    H:Register("HumanVehicleTriggerComponent",  C.PlayerSelf,   E.BattleClient, A.Human,                L.WithUEActor)

    -- GamePlayerOther
    H:Register("PlayerHeadInfo2DComponent",     C.Player,       E.BattleClient, A.Ship|A.Human,         L.WithUEActor,      false,  "HeadInfoComponent")
    --PlayerOtherHead 3d widget, create in here
    H:Register("PlayerHeadInfo3DComponent",     C.Player,       E.BattleClient, A.Ship|A.Human,         L.WithUEActor,      false)
    H:Register("DelayDestroyOwnerObjectComponent", C.PlayerOther, E.BattleClient, A.Ship|A.Human,       L.WithGameObject,   false)

    --GameNpc
    --Npc 3d widget, create in here
    H:Register("NpcHeadInfoComponent",          C.Npc,          E.Battle,       A.All,                  L.WithUEActor,      false,  "HeadInfoComponent")

    -- GameDummy
    H:Register("PlayerHeadInfo2DComponent",     C.Dummy,        E.Battle,       A.All,                  L.WithGameObject,   false,  "HeadInfoComponent")

    --

    -- headless
    if(ExtendBlueprintFunctions.IsHeadlessClient()) then
        H:Register("HeadlessShipComponent",     C.PlayerSelf,   E.BattleClient, A.Ship,                 L.WithUEActor,      false)
        H:Register("HeadlessMoveComponent",     C.PlayerSelf,   E.BattleClient, A.Ship|A.Human,         L.WithUEActor,      false)
        H:Register("HeadlessStatsComponent",    C.PlayerSelf,   E.BattleClient, A.Ship|A.Human,         L.WithGameObject,   false)
    end
    -- 有潜在需求的，如果需要开启请挪到上面去
    -- Character
    -- H:Register("BattleHeadInfoComponent",       C.Character,    E.Battle,    A.Ship,                 L.WithUEActor,      false,  "HeadInfoComponent")
    -- H:Register("ShipDropInfoComponent",         C.Character,    E.Battle,    A.Ship,                 L.WithUEActor)
    -- H:Register("DialogBoardComponent",          C.Character,    E.Battle,    A.Ship,                 L.WithUEActor)
    -- H:Register("HumanAvatarComponent",          C.Character,    E.All,       A.Human,                L.WithUEActor)

    -- Player
    -- H:Register("FactionComponent",              C.Player,       E.Lobby,     A.Ship|A.Human,         L.WithGameObject)
    -- H:Register("PlayerStateComponent",          C.Player,       E.Lobby,     A.Human,                L.WithUEActor)
    -- H:Register("PlayerHeadInfoComponent",       C.Player,       E.Lobby,     A.Ship|A.Human,         L.WithUEActor,      false,  "HeadInfoComponent")
    -- H:Register("HumanMovementHubModeComponent", C.Player,       E.Lobby,     A.Human,                L.WithUEActor,      false,  "HubMovementComponent")

    -- PlayerSelf
    -- H:Register("ActorSelectorComponent",        C.PlayerSelf,   E.All,       A.Ship|A.Human,         L.WithUEActor)
    -- H:Register("ShipBattleStatisticsComponent", C.PlayerSelf,   E.Battle,    A.Ship,                 L.WithUEActor,      false)
    -- H:Register("BattleHistoryComponent",        C.PlayerSelf,   E.Lobby,     A.Ship|A.Human,         L.WithGameObject)

    -- AtmoSphereNpc
    -- H:Register("NpcHeadInfoComponent",          C.AtmoSphereNpc,E.Lobby,          A.Ship|A.Human,         L.WithUEActor,      false,  "HeadInfoComponent")
    -- H:Register("HumanAvatarComponent",          C.AtmoSphereNpc,E.Lobby,          A.Human,                L.WithUEActor)
    -- H:Register("ShipAvatarComponent",           C.AtmoSphereNpc,E.Lobby,          A.Ship,                 L.WithUEActor)
end

return GameComponentRegister_C
