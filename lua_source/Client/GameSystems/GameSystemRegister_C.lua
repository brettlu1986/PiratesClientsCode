-- Register Managers those used for Common module

local luaclass = require("luaclass")
local GameSystemRegister = require("GameSystemRegister")
local GameSystemRegister_C = luaclass("GameSystemRegister_C", GameSystemRegister)

local ManagerGroupDef = require("ManagerGroupDef")

function GameSystemRegister_C:RegisterSubSystems(GameSystemManager)
    GameSystemRegister_C.super.RegisterSubSystems(self, GameSystemManager)

    local nImmortalGroupID = ManagerGroupDef.nImmortalGroupID
    GameSystemManager:Register(nImmortalGroupID, require("ReconnectSystemNew"))
    GameSystemManager:Register(nImmortalGroupID, require("SensitiveWordsSystem"))

    local nDefaultGroupID = ManagerGroupDef.nDefaultGroupID
    GameSystemManager:Register(nDefaultGroupID, require("ResourceCacheSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("LoadingSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("SettingSystemNew"))
    GameSystemManager:Register(nDefaultGroupID, require("ControlModeSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("FriendSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("TeamSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("PlayerBasicInfoSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("LobbyChatSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("ItemSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("CurrencySystem"))
    GameSystemManager:Register(nDefaultGroupID, require("IAPSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("HomelandSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("ShopSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("MailSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("SeasonSystem"))
    GameSystemManager:Register(nDefaultGroupID, dynamic_require("PingSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("AwardSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("StatsSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("ScheduleSystem"))

    -- 有潜在需求的都先留着
    -- GameSystemManager:Register(nDefaultGroupID, require("CameraShotSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("MediaSystem"))
    -- GameSystemManager:Register(nDefaultGroupID, require("BattleGroundSystem"))
    -- GameSystemManager:Register(nDefaultGroupID, require("NPCSystem"))
    -- GameSystemManager:Register(nDefaultGroupID, require("NpcDialogBoardSystem"))
    -- GameSystemManager:Register(nDefaultGroupID, require("ToastSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("GuideSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("ChannelSDKSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("GVoiceSDKSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("GameTestAutomationSystemClient"))
    GameSystemManager:Register(nDefaultGroupID, require("MiniMapSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("GPerfSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("GPerfPSOSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("PlayerInfoSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("DLCSystem"))

    local nHubGroupID = ManagerGroupDef.nHubGroupID
    GameSystemManager:Register(nHubGroupID, require("PathNodeSystem"))

    local nLobbyGroupID = ManagerGroupDef.nLobbyGroupID
    GameSystemManager:Register(nLobbyGroupID, require("LobbySystem"))
    GameSystemManager:Register(nLobbyGroupID, require("MatchmakingSystem"))

    local nHomelandGroupID = ManagerGroupDef.nHomelandGroupID
    GameSystemManager:Register(nHomelandGroupID, require("HomelandSceneSystem"))
    GameSystemManager:Register(nHomelandGroupID, require("HomeLandCameraSystem"))

    local nBattleGroupID = ManagerGroupDef.nBattleGroupID
    if GWithEditor then
        GameSystemManager:Register(nBattleGroupID, require("BattlePrepareMockSystem_C"))
    end
    GameSystemManager:Register(nBattleGroupID, require("BattleTargetTrackSystem_C"))
    GameSystemManager:Register(nBattleGroupID, require("MapOpDataSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleItemSystemClient"))
    GameSystemManager:Register(nBattleGroupID, require("FlagMapLocationSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleHumanWeaponSystemClient"))
    GameSystemManager:Register(nBattleGroupID, require("BattlePickupSystem"))
    GameSystemManager:Register(nBattleGroupID, require("PoisonCircleSystem"))
    GameSystemManager:Register(nBattleGroupID, require("GameCameraSystem"))
    GameSystemManager:Register(nBattleGroupID, require("TeamHeadNameSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleCoreAreaSystem"))
    GameSystemManager:Register(nBattleGroupID, require("EngineSettingSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleTeammateSystem"))
    GameSystemManager:Register(nBattleGroupID, require("AutoBattleSystem"))
    GameSystemManager:Register(nBattleGroupID, require("ActorResourcesPreloadSystem"))
    GameSystemManager:Register(nBattleGroupID, require("FFAMiscSettingSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleExperienceSystem"))
end

return GameSystemRegister_C
