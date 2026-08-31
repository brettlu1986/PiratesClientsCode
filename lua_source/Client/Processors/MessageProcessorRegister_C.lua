local luaclass = require("luaclass")
local MessageProcessorReigsterClass = require("MessageProcessorRegister")
local MessageProcessorRegister_C = luaclass("MessageProcessorRegister_C", MessageProcessorReigsterClass)

local Binder = require("ManagerGroupChangeBinder")
local ManagerGroupDef = require("ManagerGroupDef")


function MessageProcessorRegister_C:RegisterAllProcessors(ProcessorMgr)
    MessageProcessorRegister_C.super.RegisterAllProcessors(self, ProcessorMgr)

    local nImmortalGroupID = ManagerGroupDef.nImmortalGroupID
    Binder:Bind(nImmortalGroupID, ProcessorMgr:Register(require("ReloginPacketProcessor")))

    local nDefaultGroupID = ManagerGroupDef.nDefaultGroupID
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("GlobalPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("FriendPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("TeamPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("PlayerBasicInfoPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("LobbyChatPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("ItemPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("CurrencyPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("IAPPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("MailPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("SeasonPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("HomelandPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("ShopPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("GuidePacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("SurveyAwardPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("NoobAwardPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("ShipPreparationPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("SailorPacketProcessor")))
    -- Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("PartnerPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("AwardPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("FirstBattlePacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("SchedulePacketProcessor")))

    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("ItemBuffProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("PlayerInfoPacketProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("SDKCppDelegateProcessor")))

    -- 潜在需求
    -- Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(require("GlobalGameCppDelegateProcessor_C")))

    local nLoginGroupID = ManagerGroupDef.nLoginGroupID
    Binder:Bind(nLoginGroupID, ProcessorMgr:Register(require("LoginPacketProcessorNew")))

    local nLobbyGroupID = ManagerGroupDef.nLobbyGroupID
    Binder:Bind(nLobbyGroupID, ProcessorMgr:Register(require("LobbyPacketProcessor")))
    Binder:Bind(nLobbyGroupID, ProcessorMgr:Register(require("StatsPacketProcessor")))

    --local nHubGroupID = ManagerGroupDef.nHubGroupID

    local nBattleGroupID = ManagerGroupDef.nBattleGroupID
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("D2CDungeonPacketProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("DungeonPacketProcessor_C")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattlePacketProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattleCommonRepProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("PVPOccupyRepProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("SocietyGuardRepProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattlePlayerStateRepProcessor")))

    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattleHumanWeaponClientProcessorNew")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("HumanAvatarPacketProcessor")))

    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("GameTestAutomationPacketProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("ParachutingPacketProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattleTrainingCampGameStatePropertyProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattleFFAGameStatePropertyProcessor")))
    -- if not GShippingBuild then
    -- end

end

return MessageProcessorRegister_C;
