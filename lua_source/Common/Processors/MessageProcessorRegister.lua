-- Register Managers those used for Common module
local luaclass = require("luaclass")
local MessageProcessorReigster = luaclass("MessageProcessorReigster")

local Binder = require("ManagerGroupChangeBinder")
local ManagerGroupDef = require("ManagerGroupDef")
-- local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

function MessageProcessorReigster:RegisterAllProcessors(ProcessorMgr)
    local nDefaultGroupID = ManagerGroupDef.nDefaultGroupID
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(dynamic_require("ActorCppDelegateProcessor")))
    Binder:Bind(nDefaultGroupID, ProcessorMgr:Register(dynamic_require("GlobalGameCppDelegateProcessor")))

    local nBattleGroupID = ManagerGroupDef.nBattleGroupID

    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("SkillPacketProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("C2DDungeonPacketProcessor")))

    -- Delegate
    --Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("PropertyCppDelegateProcessor")))
    -- Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattleShipPropertyBlackboardCppDelegateProcessor")))
    -- Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("DataTableCppDelegateProcessor")))
    -- Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("FightCppDelegateProcessor")))


    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("GameModeCppDelegateProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("GameStateCppDelegateProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("LevelCppDelegateProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("PlayerCppDelegateProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattlePathNodeCppDelegateProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("PlayerStateCppDelegateProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattleNpcInteractionProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattleReviveProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("AbilityPacketProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("BattleItemPacketProcessor")))
    if GWithEditor or CommonShell.GetCommon(GWorld):IsGMEnabled() then
        Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattleGMCppDelegateProcessor")))
    end
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("BattleChatPacketProcessor")))

    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(require("BattleHumanWeaponProcessorNew")))

    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("GameCoreWatchPacketProcessor")))

    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("GameWatchProcessor")))
    Binder:Bind(nBattleGroupID, ProcessorMgr:Register(dynamic_require("ShipWeaponPacketProcessor")))
    
end

return MessageProcessorReigster
