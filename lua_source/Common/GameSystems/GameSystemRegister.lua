-- Register Managers those used for Common module

local luaclass = require("luaclass")
local GameSystemRegister = luaclass("GameSystemRegister")

local ManagerGroupDef = require("ManagerGroupDef")

function GameSystemRegister:RegisterSubSystems(GameSystemManager)
    local nImmortalGroupID = ManagerGroupDef.nImmortalGroupID
    GameSystemManager:Register(nImmortalGroupID, require("UninitCheckSystem"))
    GameSystemManager:Register(nImmortalGroupID, dynamic_require("GlobalVariableSystem"))

    local nDefaultGroupID = ManagerGroupDef.nDefaultGroupID
    if GWithEditor or CommonShell.GetCommon(GWorld):IsGMEnabled() then
        GameSystemManager:Register(nDefaultGroupID, dynamic_require("GMSystem"))
    end
    GameSystemManager:Register(nDefaultGroupID, dynamic_require("GameObjectSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("GameWorldSystem"))
    GameSystemManager:Register(nDefaultGroupID, dynamic_require("MatineeSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("SpawnerSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("AsyncHelperSystem"))
    GameSystemManager:Register(nDefaultGroupID, require("PropertyComboSystem"))
    GameSystemManager:Register(nDefaultGroupID, dynamic_require("LogEventSystem"))
    GameSystemManager:Register(nDefaultGroupID, dynamic_require("LogReportSystem"))

    local nBattleGroupID = ManagerGroupDef.nBattleGroupID
    GameSystemManager:Register(nBattleGroupID, require("ReplicatedPropertyGenerateSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattlePrepareSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleTeamSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleGameModeSystem"))
    GameSystemManager:Register(nBattleGroupID, require("PathNodeSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleInteractionSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleDataStatisticsSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleCollectionSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleReviveSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleCommandSystem"))
    GameSystemManager:Register(nBattleGroupID, require("SessionSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleLandSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleItemSystemServer"))
    GameSystemManager:Register(nBattleGroupID, require("BattleItemDropSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("ParachutionSystem"))
    -- GameSystemManager:Register(nBattleGroupID, dynamic_require("DestructiableObjectSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BotAISystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("WatchBattleSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleHumanDecorationSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleChatSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BotDistributionSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleQuestSystem"))
    GameSystemManager:Register(nBattleGroupID, require("RelationshipSystem"))
    GameSystemManager:Register(nBattleGroupID, require("GameCoreProxyClient"))
    GameSystemManager:Register(nBattleGroupID, require("AgentStatisticsSystem"))
	GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleTemplateActorSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleResultSystem"))
    GameSystemManager:Register(nBattleGroupID, require("AIVariableSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("CheaterCheckSystemNew"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleHumanWeaponSystemNew"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("GameCoreWatchSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("DestructibleObjectInteractionalSystem"))
    GameSystemManager:Register(nBattleGroupID, require("BattleAbilitySystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("AIPresstestSystem"))
    GameSystemManager:Register(nBattleGroupID, require("SAIPoisonCircleSystem"))
    GameSystemManager:Register(nBattleGroupID, require("SAIDeliveryBotSystem"))
    GameSystemManager:Register(nBattleGroupID, require("AITemmateSystem"))
    GameSystemManager:Register(nBattleGroupID, require("AIOceanGridSystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("HumanAvatarSystem"))
    GameSystemManager:Register(nBattleGroupID, require("AIEntitySystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleSkySystem"))
    GameSystemManager:Register(nBattleGroupID, dynamic_require("BattleShipWeaponSystem"))
end

return GameSystemRegister
