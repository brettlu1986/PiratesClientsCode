local luaclass = require("luaclass")
local BattleOperationDef = luaclass("BattleOperationDef")

local tbOperations = nil
local tbOperationDynamicRequires = nil
local tbOperators = nil
local tbNames = nil

BattleOperationDef.Register = function(szJsonKey, szFileName, bDynamicRequire)
    tbOperations[szJsonKey] = szFileName
    if(bDynamicRequire) then
        tbOperationDynamicRequires[szJsonKey] = bDynamicRequire
    end
end

BattleOperationDef.RegisterOperator = function(szJsonKey, fnFunc)
    tbOperators[szJsonKey] = fnFunc
end

BattleOperationDef.DeclareName = function(self, szKey)
    self[szKey] = "__"..szKey
    table.insert(tbNames, szKey)
end

-------------------------------------------------------------------------------------------

function BattleOperationDef:DeclareNames()
    local DeclareName = self.DeclareName

    DeclareName(self, "CurrentPoint")
    DeclareName(self, "CurrentObject")
    DeclareName(self, "CurrentPlayerStart")
    DeclareName(self, "FactionPoint")
end

function BattleOperationDef:RegisterOperators()
    local RegisterOperator = self.RegisterOperator

    RegisterOperator("And", function(A, B) return A and B end)
    RegisterOperator("Or", function(A, B) return A or B end)

    RegisterOperator("MoreThan", function(A, B) return A > B end)
    RegisterOperator("MoreThanOrEqual", function(A, B) return A >= B end)
    RegisterOperator("Equal", function(A, B) return A == B end)
    RegisterOperator("LessThan", function(A, B) return A < B end)
    RegisterOperator("LessThanOrEqual", function(A, B) return A <= B end)
    RegisterOperator("NotEqual", function(A, B) return A ~= B end)

    RegisterOperator("Add", function(A, B) return A + B end)
    RegisterOperator("Subtract", function(A, B) return A - B end)
    RegisterOperator("Multiply", function(A, B) return A * B end)
    RegisterOperator("Divide", function(A, B) return A / B end)
end

function BattleOperationDef:RegisterSettings()
    local Register = self.Register

    Register("Setting_Faction", "JGMFactionSetting", true)
    Register("Setting_Provocative", "JGMProvocativeSetting", true)
    Register("Setting_DungeonPVE", "JGMDungeonPVESetting", true)
    Register("Setting_CaptureFlag", "JGMCaptureFlagSetting", true)
    Register("Setting_Conquest", "JGMConquestSetting", true)
    Register("Setting_Association", "JGMAssociationSetting", true)
    Register("Setting_Challenge", "JGMChallengeSetting", true)
    Register("Setting_ActivityPVE", "JGMActivityPVESetting", true)
    Register("Setting_GuildBoss", "JGMGuildBossSetting", true)
    Register("Setting_WorldBoss", "JGMWorldBossSetting", true)
    Register("Setting_FFA", "JGMFFASetting", true)
    Register("Setting_TrainingCamp", "JGMTrainingCampSetting", true)
end

function BattleOperationDef:RegisterSteps()
    local Register = self.Register

    Register("Step_Simple", "BattleTargetActionStep")
    Register("Step_Parallel", "BattleParrallelStep")
    Register("Step_Sequence", "BattleSequenceStep")
    Register("Step_Loop", "BattleLoopStep")
    Register("Step_Condition", "BattleConditionStep")
    Register("Step_While", "BattleWhileStep")
    Register("Step_SequenceReset", "BattleSequenceResetStep")
    Register("Step_Occupy", "BattleOccupyStep")
    -- Register("Step_FFAPlayerTransport", "FFAPlayerTransportStep")
    Register("Step_FFAPoisonCircle", "FFAPoisonCircleStep")
    Register("Step_FFAAirdrop", "FFAAirdropStep")
    Register("Step_FFASelectionPoint", "FFASelectionPointStep")
    Register("Step_FFAParachuting", "FFAParachutingStep")
    Register("Step_ReleaseDungeonStep", "BattleReleaseDungeonStep")
    Register("Step_FFABotSpawn", "FFABotSpawnStep")
    Register("Step_TrainingCampRemoveItem", "TrainingCampRemoveItemStep")
end

function BattleOperationDef:RegisterActions()
    local Register = self.Register

    Register("Action_Group", "BattleGroupAction")
    Register("Action_CreateTimer", "BattleCreateTimerAction")
    Register("Action_CreateFloatTimer", "BattleCreateTimerAction")
    Register("Action_Condition", "BattleConditionAction")
    Register("Action_PrintLog", "BattlePrintLogAction")
    Register("Action_SetInt", "BattleSetNumberAction")
    Register("Action_SetBool", "BattleSetBoolAction")
    Register("Action_SetString", "BattleSetStringAction")
    Register("Action_OperateIntKey", "BattleOperateNumberAction")
    Register("Action_OperateIntValue", "BattleOperateNumberAction")
    Register("Action_SelectPlayerStart", "BattleSelectPlayerStartAction")
    Register("Action_SpawnNpc", "BattleSpawnAction")
    Register("Action_SpawnBySpawnerId", "BattleSpawnAction")
    Register("Action_SpawnAll", "BattleSpawnAction")
    Register("Action_SpawnTrigger", "BattleSpawnAction")
    Register("Action_DestroyAllNpcs", "BattleDestroyNpcAction")
    Register("Action_DestroyNpc", "BattleDestroyNpcAction")
    Register("Action_DestroyTrigger", "BattleDestroyTriggerAction")
    Register("Action_DestroyAllTriggers", "BattleDestroyTriggerAction")
    Register("Action_Toast", "BattleToastAction")
    Register("Action_Objective", "BattleObjectiveAction")
    Register("Action_TargetTracking", "BattleTargetTrackingAction")
    Register("Action_DefineKey", "BattleDefineBBKeyAction")
    Register("Action_UndefineKey", "BattleDefineBBKeyAction")
    Register("Action_GetNpcCount", "BattleGetNpcCountAction")
    Register("Action_PrintKeyValue", "BattlePrintKeyValueAction")
    Register("Action_SpecialToast", "BattleToastAction")
    Register("Action_AddNpcBuff", "BattleAddNpcBuffAction")
    Register("Action_AddPlayerBuff", "BattleAddPlayerBuffAction")
    Register("Action_ShowDialog", "BattleInteractionDialogAction")
    Register("Action_ShowHeadDialog", "BattleInteractionHeadDialogAction")
    Register("Action_SetPlayerAutoBattleEnable", "BattlePlayerAutoBattleAction")
    Register("Action_SetPlayerAutoBattleParam", "BattlePlayerAutoBattleAction")
    Register("Action_NpcChangeCamp", "BattleNpcChangeCampAction")
    Register("Action_NpcChangeInteraction", "BattleNpcChangeInteraction")
    Register("Action_DummySwitch", "BattleSpawnDummyAction")
    Register("Action_PlayMatinee", "BattlePlayMatineeAction", true)
    Register("Action_TeleportNpc", "BattleTeleportNpcAction")
    Register("Action_TeleportPlayer", "BattleTeleportPlayerAction")
    Register("Action_NpcChangeAI", "BattleChangeNpcAIAction")
    Register("Action_PlayerAcquireSkill", "BattlePlayerAcquireSkillAction")
    Register("Action_PlayerRequestCastSkill", "BattlePlayerRequestCastSkillAction")
    Register("Action_NpcAcquireSkill", "BattleNpcAcquireSkillAction")
    Register("Action_NpcRequestCastSkill", "BattleNpcRequestCastSkillAction")
    Register("Action_SelectTransformPoint", "BattleSelectPointAction")
    Register("Action_NpcFollowPlayer", "BattleNpcFollowPlayerAction")
    Register("Action_DungeonEnd", "BattleDungeonEndAction")
    Register("Action_SetFactionPoint", "BattleSetFactionPointAction")
    Register("Action_SpawnNpcWithPositionAndCamp", "BattleSpawnNpcWithPositionAndCampAction")
    Register("Action_SelectPlayerStartRevive", "BattleSelectPlayerStartReviveAction")
    Register("Action_PlayerResult", "BattlePlayerResultAction")
    Register("Action_SetStepRemainTime", "BattleSetStepRemainTimeAction")
    Register("Action_GroupRandom", "BattleGroupRandomAction")
    Register("Action_DestroyTimer", "BattleDestroyTimerAction")
    Register("Action_GetPlayerId", "BattleGetPlayerIdAction")
    Register("Action_SetNpcInteraction", "BattleSetNpcInteractionAction")
    Register("Action_PlayerReviveImmediately", "BattlePlayerReviveImmediatelyAction")
    Register("Action_SpawnLocalDummy", "BattleSpawnLocalDummy")
    Register("Action_DestroyLocalDummy", "BattleDestroyLocalDummy")
    Register("Action_CountDown", "BattleCountDownAction")
    Register("Action_GetObjName", "BattleGetObjNameAction")
    Register("Action_SetCaptureFlagInfo", "BattleSetCaptureFlagInfoAction")
    Register("Action_ShowOccupy", "BattleShowOccupyAction")
    Register("Action_NpcNotDestroy", "BattleNpcNotDestroyAction")
    Register("Action_SetPlayerAIInteractionPoint", "BattleSetPlayerAIInteractionPointAction")
    Register("Action_RobotAIStart", "BattleRobotAIStartAction")
    Register("Action_PlayerResultAllLose", "BattlePlayerResultAllLoseAction")
    Register("Action_GetPlayerCount", "BattleGetPlayerCountAction")
    Register("Action_SpawnRandomNpcInTrigger", "BattleSpawnRandomNpcInTriggerAction")
    Register("Action_SetBattleStatistics", "BattleSetBattleStatisticsAction")
    Register("Action_SetForcedTargetToAttack", "BattleSetForcedTargetToAttackAction")
    Register("Action_SelectVolumePoint", "FFASelectVolumePointAction")
    Register("Action_SpawnFog", "BattleSpawnAction")
    Register("Action_BroadcastShowDialog", "BattleShowDialogAction")
    Register("Action_SetFFAProcessState", "BattleSetFFAProcessStateAction")
    Register("Action_CreateTimerBb", "BattleCreateTimerBbAction")
    Register("Action_LoginRejected", "BattleLoginRejectedAction")
    Register("Action_SetStepRemainTimeBb", "BattleSetStepRemainTimeBbAction")
    Register("Action_FFAShowCoreArea", "BattleFFAShowCoreAreaAction")
    Register("Action_GetTeamMode", "BattleGetTeamModeAction")
    Register("Action_SetAdditionalSuccess", "BattleSetAdditionalSuccessAction")
    Register("Action_ReceiveQuest", "BattleReceiveQuestAction")
    Register("Action_UpdateQuestProgress", "BattleUpdateQuestProgressAction")
    Register("Action_SetAdditionalSuccessCount", "BattleSetAdditionalSuccessCountAction")
    Register("Action_TryAdditionalSuccess", "BattleTryAdditionalSuccessAction")
    Register("Action_SendPlayerDialog", "BattleSendPlayerDialogAction")
    Register("Action_SelectAdditionalSuccessQuest", "BattleSelectAdditionalSuccessQuestAction")
    Register("Action_AddPlayerItem", "BattleAddPlayerItemAction")
    Register("Action_RemovePlayerItem", "BattleRemovePlayerItemAction")
    Register("Action_SetWorldPause", "BattleSetWorldPauseAction")
    Register("Action_EnableSky", "BattleEnableSkyAction")
    Register("Action_NpcMoveTo", "BattleNpcMoveToAction")
end

function BattleOperationDef:RegisterTargets()
    local Register = self.Register

    Register("Target_TimerEnd", "BattleTimerCheckTarget")
    Register("Target_Group", "BattleGroupTarget")
    Register("Target_Instant", "BattleInstantTarget")
    Register("Target_NpcDead", "BattleNpcDeadTarget")
    Register("Target_NpcRemainCount", "BattleNpcRemainCountTarget")
    Register("Target_NpcInTrigger", "BattleNpcCountInTriggerTarget")
    Register("Target_PlayerInTrigger", "BattlePlayerCountInTriggerTarget")
    Register("Target_PlayerEnterTrigger", "BattlePlayerEnterTriggerTarget")
    Register("Target_PlayerLeaveTrigger", "BattlePlayerLeaveTriggerTarget")
    Register("Target_NpcHp", "BattleNpcHpTarget")
    Register("Target_CheckIntKey", "BattleBlackboardIntTarget")
    Register("Target_CheckIntValue", "BattleBlackboardIntTarget")
    Register("Target_CheckBoolKey", "BattleBlackboardBoolTarget")
    Register("Target_CheckBoolValue", "BattleBlackboardBoolTarget")
    Register("Target_CheckStringKey", "BattleBlackboardStringTarget")
    Register("Target_CheckStringValue", "BattleBlackboardStringTarget")
    Register("Target_TeamDead", "BattleTeamDeadTarget")
    Register("Target_ShowDialogueEnd",   "BattleInteractionDialogTarget")
    Register("Target_StartNpcInterAction", "BattleNpcInteractionStartTarget")
    Register("Target_PlayerHp", "BattlePlayerHpTarget")
    Register("Target_NpcCreate", "BattleNpcCreateTarget")
    Register("Target_NpcInInteractionArea", "BattleTariggerNpcInteractionTarget")
    Register("Target_TorpedoDiscovery", "BattleTorpedoDiscoveryTarget")
    Register("Target_Collection", "BattleCollectionTarget")
    Register("Target_PlayerDead", "BattlePlayerDeadTarget")
    Register("Target_OneFactionLeft", "BattleOneFactionLeftTarget")
    Register("Target_PlayMatineEnd", "BattlePlayMatineeEndTarget")
    Register("Target_CollectionStart", "BattleCollectionStartTarget")
    Register("Target_IntoFight", "BattleIntoFightTarget")
    Register("Target_PlayerQuit", "BattlePlayerQuitTarget")
    Register("Target_OccupyStateChange", "BattleOccupyStateChangeTarget")
    Register("Target_OccupyScoreChange", "BattleOccupyScoreChangeTarget")
    Register("Target_TeamRemainCount", "BattleTeamRemainCountTarget")
    Register("Target_PlayerLoginCount", "BattlePlayerLoginCountTarget")
    Register("Target_PlayerLoginCountBb", "BattlePlayerLoginCountBbTarget")
    Register("Target_PlayerBotLoginCountBb", "BattlePlayerBotLoginCountBbTarget")
    Register("Target_TeamItemCount", "BattleTeamItemCountTarget")
    Register("Target_AdditionalSuccessReturn", "BattleAdditionalSuccessReturnTarget")
    Register("Target_TeamItemChange", "BattleTeamItemChangeTarget")
    Register("Target_BuffRemoved", "BattleBuffRemovedTarget")

end

function BattleOperationDef:RegisterConditions()
    local Register = self.Register

    Register("Condition_HasTimer", "BattleHasTimerCondition")
    Register("Condition_CheckIntKey", "BattleCheckIntCondition")
    Register("Condition_CheckIntValue", "BattleCheckIntCondition")
    Register("Condition_CheckBoolKey", "BattleCheckBoolCondition")
    Register("Condition_CheckBoolValue", "BattleCheckBoolCondition")
    Register("Condition_CheckStringKey", "BattleCheckStringCondition")
    Register("Condition_CheckStringValue", "BattleCheckStringCondition")
    Register("Condition_Group", "BattleGroupCondition")
    Register("Condition_NpcCount", "BattleNpcCountCondition")
    Register("Condition_NpcInTrigger", "BattleNpcCountInTriggerCondition")
    Register("Condition_PlayerInTrigger", "BattlePlayerCountInTriggerCondition")
    Register("Condition_NpcHp", "BattleNpcHpCondition")
    Register("Condition_TeamDead", "BattleTeamDeadCondition")
    Register("Condition_OneFactionLeft", "BattleOneFactionLeftCondition")
    Register("Condition_CheckObjBuff", "BattleCheckObjBuffCondition")
    Register("Condition_CheckCampType", "BattleCheckCampTypeCondition")
    Register("Condition_CheckDoingQuest", "BattleCheckDoingQuestCondition")
    -- Register("Condition_IntoFight", "BattleIntoFightCondition")

end

function BattleOperationDef:RegisterLoginAction()
    local Register = self.Register

    Register("LoginAction_Group", "BattleGroupAction")
    Register("LoginAction_PlayMatinee", "BattlePlayMatineeLoginAction",true)
    Register("LoginAction_ShowDialog", "BattleInteractionDialogLoginAction")
    Register("LoginAction_AddPlayerBuff", "BattleAddPlayerBuffLoginAction")
    Register("LoginAction_SpecialToast", "BattleSpecialToastLoginAction")
    Register("LoginAction_HideBattleUI", "BattleHideBattleUILoginAction")
    Register("LoginAction_NpcFollowPlayer", "BattleNpcFollowPlayerLoginAction")
end

function BattleOperationDef:RegisterReviveAction()
    local Register = self.Register

    Register("ReviveAction_AddPlayerBuff", "BattleAddPlayerBuffReviveAction")
end

function BattleOperationDef:RegisterAll()
    tbOperations = {}
    tbOperationDynamicRequires = {}
    tbOperators = {}
    tbNames = {}

    self:DeclareNames()
    self:RegisterOperators()
    self:RegisterSettings()
    self:RegisterSteps()
    self:RegisterActions()
    self:RegisterTargets()
    self:RegisterConditions()
    self:RegisterLoginAction()
    self:RegisterReviveAction()
end

function BattleOperationDef:UnregisterAll()
    tbOperations = nil
    tbOperationDynamicRequires = nil
    tbOperators = nil

    if(tbNames) then
        for _, szName in ipairs(tbNames) do
            self[szName] = nil
        end
        tbNames = nil
    end
end

function BattleOperationDef:FindOperation(szName)
    return tbOperations[szName], tbOperationDynamicRequires[szName]
end

function BattleOperationDef:FindOperator(szName)
    return tbOperators[szName]
end

return BattleOperationDef()