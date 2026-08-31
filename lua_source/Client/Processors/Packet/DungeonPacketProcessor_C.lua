--
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local DungeonPacketProcessor_C = luaclass("DungeonPacketProcessor_C", NetMessageProcessorBase)
local Proto = require("DungeonCommonProtoNames")

local NetworkManager = dynamic_require("NetworkManager")

local UIDef = require("UIDef")
-- local BattleInteractionSystem = dynamic_require("BattleInteractionSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIManager = require("UIManager")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local InteractionHelper = require("InteractionHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local DgProto = require("DungeonRepProtoNames")
local InteractionSystem = require("InteractionSystem")
local BattleReviveSystem = dynamic_require("BattleReviveSystem")
local ToastSystem = require("ToastSystem")
-- local HandlerManagerHelper = require("HandlerManagerHelper")
local NpcDialogBoardHelper = require("NpcDialogBoardHelper")
-- local BitHelper = require("BitHelper")
local BattleCoreAreaSystem = require("BattleCoreAreaSystem")
local BotDistributionSystem = dynamic_require("BotDistributionSystem")
-- local BattleHistorySystem = require("BattleHistorySystem")
local BattleQuestSystem = dynamic_require("BattleQuestSystem")
local UIUtils = require("UIUtils")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local DungeonDataTable = require("DungeonDataTable")
local UIMapResDataTable = require("UIMapResDataTable")
local EngineSettingSystem = require("EngineSettingSystem")
local CameraGameHelper = require("CameraGameHelper")
local BattleResultSystem = dynamic_require("BattleResultSystem")
local MiniMapSystem = require("MiniMapSystem")

DungeonPacketProcessor_C.fnToastCallback = nil
-- DungeonPacketProcessor_C.nWeaponEnabledOverlapId = -1
-- local COORDINATE_PROPORTION = 100

-- 注册处理包
function DungeonPacketProcessor_C:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    self:BindMethod(Proto.d2c_ShowAward, self, self.OnShowPVEBattleResultAward)
    self:BindMethod(Proto.d2c_ShowArenaAward, self, self.OnShowPVPBattleResultAward)
    self:BindMethod(Proto.d2c_ShowBattlegroundAward, self, self.OnShowBattlegroundAward)
    -- self:BindMethod(Proto.d2c_ShowActivityDungeonAward, self, self.OnShowActivityDungeonAward)
    -- self:BindMethod(Proto.d2c_ShowAssociationDungeonAward, self, self.OnShowAssociationDungeonAward)
    -- self:BindMethod(Proto.d2c_ShowWorldbossAward, self, self.OnShowWorldbossAward)
    -- self:BindMethod(Proto.d2c_ShowGuildbossAward, self, self.OnShowGuildbossAward)
    --self:BindMethod(Proto.d2c_ShowDialog, self, self.ShowDialog)
    self:BindMethod(Proto.d2c_StopMove, self, self.StopMove)
    self:BindMethod(Proto.d2c_SwitchCommonHandlerMode, self, self.SwitchCommonHandlerMode)
    self:BindMethod(Proto.d2c_ResetCameraControl, self, self.ResetCameraControl)
    self:BindMethod(Proto.d2c_SetCameraYaw, self, self.SetCameraYaw)
    self:BindMethod(Proto.d2c_PlayerStatisticsData, self, self.OnRecvPlayerStatisticsData)
    self:BindMethod(Proto.d2c_BattleToast, self, self.OnRecvToast)
    self:BindMethod(Proto.d2c_AutoBattle, self, self.OnRecvAutoBattle)
    self:BindMethod(Proto.d2c_CampTypeChanged, self, self.OnRecvCampTypeChanged)
    self:BindMethod(Proto.d2c_StartCollection, self, self.OnRecvStartCollection)
    self:BindMethod(DgProto.rReviveInfoAndShow, self, self.OnRepReviveInfoAndShow)
    self:BindMethod(Proto.d2c_InteractionEnd, self, self.OnInteractionEnd)
    self:BindMethod(Proto.d2c_CollectionBreak, self, self.OnInteractionBreak)
    self:BindMethod(Proto.d2c_BreakChangeDisplay, self, self.OnBreakChangeDisplay)
    self:BindMethod(Proto.d2c_ReviveCountdown, self, self.WaitReset)
    self:BindMethod(Proto.d2c_OpenDialogBoard, self, self.OpenDialogBoard)
    self:BindMethod(DgProto.rBattleFlagState, self, self.OnRepBattleFlagState)
    self:BindMethod(Proto.d2c_Countdown, self, self.OnCountdown)
    self:BindMethod(Proto.d2c_ShowOccupy, self, self.OnShowOccupy)
    self:BindMethod(Proto.d2c_MulticastTacticsCommand, self, self.OnReceiveTacticsCommand)
    self:BindMethod(Proto.d2c_PlayerRealTimeStatisticsData, self, self.OnRecvPlayerRealTimeStatisticsData)
    self:BindMethod(Proto.d2c_PlayerBattleFinishStatisticsData, self, self.OnRecvPlayerBattleFinishStatisticsData)
    self:BindMethod(Proto.d2c_HideBattleUI, self, self.OnHideBattleUI)
    -- self:BindMethod(Proto.d2c_ParachutionEnd, self, self.OnParachutionEnd)
    self:BindMethod(Proto.d2c_DestroyGameObject, self, self.OnDestroyGameObject)
    self:BindMethod(Proto.d2c_FFATeamResult, self, self.OnFFAPlayerResult)
    self:BindMethod(Proto.d2c_FFAKillBossResult, self, self.OnFFAKillBossResult)
    self:BindMethod(Proto.d2c_FFAShowDialog, self, self.OnFFAShowDialog)
    self:BindMethod(Proto.d2c_FFAKillInfo, self, self.OnFFAKillInfo)
    -- self:BindMethod(Proto.d2c_FFASelectionPoint, self, self.OnFFASelectionPoint)
    -- self:BindMethod(Proto.d2c_FFATransporterPlayerCount, self, self.OnFFATransporterPlayerCount)
    self:BindMethod(Proto.d2c_FFATeammateLeave, self, self.OnFFATeammateLeave)
    self:BindMethod(Proto.d2c_NotifyNpcReset, self, self.OnNotifyNpcReset)
    self:BindMethod(Proto.d2c_FFAShowCoreArea, self, self.OnFFAShowCoreArea)
    self:BindMethod(Proto.d2c_BattleKillToast, self, self.OnBattleKillToast)
    self:BindMethod(Proto.d2c_TestNet, self, self.OnTestNet)
    self:BindMethod(Proto.d2c_SyncBotInfos, self, self.OnSyncBotInfos)
    self:BindMethod(Proto.d2c_SearchPropDataForGM, self, self.SearchPropDataForGM)
    self:BindMethod(Proto.d2c_ProcessQuest, self, self.OnProcessQuest)
    self:BindMethod(Proto.d2c_AdditionalSuccessChoice, self, self.OnAdditionalSuccessChoice)
    self:BindMethod(Proto.d2c_AdditionalSuccessQuestInfo, self, self.OnASQuestInfo)
    self:BindMethod(Proto.d2c_AdditionalSuccessResult, self, self.OnASQuestResult)
    self:BindMethod(Proto.d2c_ShowCommonToast, self, self.ShowCommonToast)
    self:BindMethod(Proto.d2c_DungeonAndPlayerState, self, self.DungeonAndPlayerState)
    self:BindMethod(Proto.d2c_FFADeathPlayback, self, self.OnFFADeathPlayback)
    self:BindMethod(Proto.d2c_ReLoginRecentUsedVehicle, self, self.OnReloginUsedVehicle)
    self:BindMethod(Proto.d2c_FFAProcessStateChanged, self, self.OnFFAProcessStateChanged)
end

-- 初始化
function DungeonPacketProcessor_C:Init()
    DungeonPacketProcessor_C.super.Init(self)
    self:RegisterPackets()
    return true
end

-- 结束
function DungeonPacketProcessor_C:Uninit()
    DungeonPacketProcessor_C.super.Uninit(self)
end

-- tbPacket : d2c_ShowAward
function DungeonPacketProcessor_C:OnShowPVEBattleResultAward(tbPacket, nSocketId)
    -- 1、d2c发送给客户端 d2c_ShowAward
    local tbPlayerAward = {}
    tbPlayerAward.nResultType = tbPacket.result_type
    tbPlayerAward.tbAwardList = {}
    local tbAwardList = tbPlayerAward.tbAwardList
    local tbAward = nil
    for k, award in pairs(tbPacket.awards) do
        tbAward = {}
        tbAward.g = award.g
        tbAward.d = award.d
        tbAward.p = award.p
        tbAward.count = award.count
        table.insert(tbAwardList, tbAward)
    end

    -- 2、抛事件
    UIManager:OpenWnd(UIDef.UI_BATTLE_RESULT, tbPlayerAward)
end

function DungeonPacketProcessor_C:OnShowPVPBattleResultAward(tbPacket, nSocketId)
    -- 1、d2c发送给客户端 d2c_ShowArenaAward
    local tbPlayerAward = {}
    tbPlayerAward.nResultType = tbPacket.result_type
    tbPlayerAward.nDelataArenaPoint = tbPacket.delta_arena_point
    tbPlayerAward.tbAwardList = {}
    tbPlayerAward.bEnableArenaPoint = tbPacket.enable_arena_point
    local tbAwardList = tbPlayerAward.tbAwardList
    local tbAward = nil
    for k, award in pairs(tbPacket.awards) do
        tbAward = {}
        tbAward.g = award.g
        tbAward.d = award.d
        tbAward.p = award.p
        tbAward.count = award.count
        table.insert(tbAwardList, tbAward)
    end
    -- 2、抛事件
    UIManager:OpenWnd(UIDef.UI_BATTLE_RESULT,tbPlayerAward)
end

function DungeonPacketProcessor_C:OnShowBattlegroundAward(tbPacket, nSocketId)
    -- 1、d2c发送给客户端 d2c_ShowBattlegroundAward
    local tbPlayerAward = {}
    tbPlayerAward.nResultType = tbPacket.result_type
    tbPlayerAward.tbAwardList = {}
    -- tbPlayerAward.tbFirstWinAwardAwardList = {}
    local tbAwardList = tbPlayerAward.tbAwardList
    local tbAward = nil
    for k, award in pairs(tbPacket.awards) do
        tbAward = {}
        tbAward.g = award.g
        tbAward.d = award.d
        tbAward.p = award.p
        tbAward.count = award.count
        table.insert(tbAwardList, tbAward)
    end

    -- local tbFirstWinAwardAwardList = tbPlayerAward.tbFirstWinAwardAwardList
    local tbFirstWinAward = nil
    for k, firstAward in pairs(tbPacket.daily_first_win_awards) do
        tbFirstWinAward = {}
        tbFirstWinAward.g = firstAward.g
        tbFirstWinAward.d = firstAward.d
        tbFirstWinAward.p = firstAward.p
        tbFirstWinAward.count = firstAward.count
        tbFirstWinAward.bFirstAward = true
        table.insert(tbAwardList, tbFirstWinAward)
    end

    -- 2、抛事件
    UIManager:OpenWnd(UIDef.UI_BATTLE_RESULT,tbPlayerAward)
end

-- -- tbPacket : d2c_ShowActivityDungeonAward
-- function DungeonPacketProcessor_C:OnShowActivityDungeonAward(tbPacket, nSocketId)
--     -- 1、d2c发送给客户端 d2c_ShowActivityDungeonAward
--     local tbPlayerAward = {}
--     tbPlayerAward.nResultType = tbPacket.result_type
--     tbPlayerAward.tbAwardList = {}
--     local tbAwardList = tbPlayerAward.tbAwardList
--     local tbAward = nil
--     for k, award in pairs(tbPacket.awards) do
--         tbAward = {}
--         tbAward.g = award.g
--         tbAward.d = award.d
--         tbAward.p = award.p
--         tbAward.count = award.count
--         table.insert(tbAwardList, tbAward)
--     end

--     -- 2、抛事件
--     UIManager:OpenWnd(UIDef.UI_BATTLE_RESULT, tbPlayerAward)
-- end

-- -- tbPacket : d2c_ShowAssociationDungeonAward
-- function DungeonPacketProcessor_C:OnShowAssociationDungeonAward(tbPacket, nSocketId)
--     -- 1、d2c发送给客户端 d2c_ShowAssociationDungeonAward
--     local tbPlayerAward = {}
--     tbPlayerAward.nResultType = tbPacket.result_type
--     tbPlayerAward.tbAwardList = {}
--     local tbAwardList = tbPlayerAward.tbAwardList
--     local tbAward = nil
--     for k, award in pairs(tbPacket.awards) do
--         tbAward = {}
--         tbAward.g = award.g
--         tbAward.d = award.d
--         tbAward.p = award.p
--         tbAward.count = award.count
--         table.insert(tbAwardList, tbAward)
--     end

--     -- 2、抛事件
--     UIManager:OpenWnd(UIDef.UI_BATTLE_RESULT, tbPlayerAward)
-- end

-- -- tbPacket : d2c_ShowWorldbossAward
-- function DungeonPacketProcessor_C:OnShowWorldbossAward(tbPacket, nSocketId)
--     -- 1、d2c发送给客户端 d2c_ShowWorldbossAward
--     local tbPlayerAward = {}
--     tbPlayerAward.nResultType = tbPacket.result_type
--     tbPlayerAward.tbAwardList = {}
--     local tbAwardList = tbPlayerAward.tbAwardList
--     local tbAward = nil
--     for k, award in pairs(tbPacket.awards) do
--         tbAward = {}
--         tbAward.g = award.g
--         tbAward.d = award.d
--         tbAward.p = award.p
--         tbAward.count = award.count
--         table.insert(tbAwardList, tbAward)
--     end

--     -- 2、抛事件
--     UIManager:OpenWnd(UIDef.UI_BATTLE_RESULT, tbPlayerAward)
-- end

-- -- tbPacket : d2c_ShowGuildbossAward
-- function DungeonPacketProcessor_C:OnShowGuildbossAward(tbPacket, nSocketId)
--     -- 1、d2c发送给客户端 d2c_ShowGuildbossAward
--     local tbPlayerAward = {}
--     tbPlayerAward.nResultType = tbPacket.result_type
--     tbPlayerAward.tbAwardList = {}
--     local tbAwardList = tbPlayerAward.tbAwardList
--     local tbAward = nil
--     for k, award in pairs(tbPacket.awards) do
--         tbAward = {}
--         tbAward.g = award.g
--         tbAward.d = award.d
--         tbAward.p = award.p
--         tbAward.count = award.count
--         table.insert(tbAwardList, tbAward)
--     end

--     -- 2、抛事件
--     UIManager:OpenWnd(UIDef.UI_BATTLE_RESULT, tbPlayerAward)
-- end

-- function DungeonPacketProcessor_C:ShowDialog(tbPacket, nSenderUniqueId)
--     InteractionSystem:OnInteractionEnd()
--     local nDialogId = tbPacket.dialog_id
--     local bDialogBoard = tbPacket.dialog_board
--     BattleInteractionSystem:OnShowDialog(nDialogId, bDialogBoard)
-- end

function DungeonPacketProcessor_C:StopMove(tbPacket, nSenderUniqueId)
    log("DungeonPacketProcessor_C:StopMove")
    --HandlerManagerHelper.SetNavStateDispatcher:call(0)

    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    if pUEActor then
        pUEActor.ShipMovementComponent:Brake()
    end

end

function DungeonPacketProcessor_C:SwitchCommonHandlerMode(tbPacket, nSenderUniqueId)
    log("DungeonPacketProcessor_C:SwitchCommonHandlerMode")
    -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.ShipCommonMode)
end

function DungeonPacketProcessor_C:ResetCameraControl(tbPacket, nSenderUniqueId)
    -- local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    -- if isvalidhandle(pUEActor) then
    --     local CameraControlManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    --     if CameraControlManager.CurrentActiveModeComponent then
    --         CameraControlManager.CurrentActiveModeComponent:ResetToDefaultParam()
    --     end
    -- end
end

function DungeonPacketProcessor_C:SetCameraYaw(tbPacket, nSenderUniqueId)
    log("DungeonPacketProcessor_C:SetCameraYaw", tbPacket.nYaw)

    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local pUEActor = tbPlayerSelf.pUEActor
    if isvalidhandle(pUEActor) then
        CameraGameHelper.RotateToYaw(tbPlayerSelf, tbPacket.nYaw)
    end
end

function DungeonPacketProcessor_C:OnRecvPlayerStatisticsData(tbPacket)

end

function DungeonPacketProcessor_C:OnRecvPlayerRealTimeStatisticsData(tbPacket)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer and tbPlayer.ShipBattleStatisticsComponent then
        tbPlayer.ShipBattleStatisticsComponent:SetPlayerRealTimeData(tbPacket)
        EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STATISTICS_DATAS, tbPacket)
    end
end

function DungeonPacketProcessor_C:OnRecvPlayerBattleFinishStatisticsData(tbPacket)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer and tbPlayer.ShipBattleStatisticsComponent then
        tbPlayer.ShipBattleStatisticsComponent:SetPlayerBattleFinishData(tbPacket)
    end
    -- BattleHistorySystem:CacheLastDetailedBattleRecord(tbPacket.detailed)
end

function DungeonPacketProcessor_C:OnRecvToast(tbPacket)
    -- TODO:这里换成新的Toast
    local tbInfo = tbPacket.tbInfo
    ToastSystem:ShowToast(
        tbInfo.nServerInstanceId,
        tbInfo.nToastId,
        tbInfo.szParam0,
        tbInfo.szParam1,
        tbInfo.szParam2,
        tbInfo.nToastType,
        tbInfo.nCampType,
        tbInfo.nWaitTime)
end

function DungeonPacketProcessor_C:OnBattleKillToast(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_BATTLE_TOAST,
        tbPacket.nType,
        tbPacket.szKiller,
        tbPacket.szDeader,
        tbPacket.nKillerInstanceId,
        tbPacket.nDeaderInstanceId,
        tbPacket.nDamageType,
        tbPacket.nWeaponTemplateId)
end

function DungeonPacketProcessor_C:OnTestNet()
    log("----------------dungeon time out test ack")
end

function DungeonPacketProcessor_C:OnRecvAutoBattle(tbPacket)
    GamePlayerSelfHelper:Get().BattleAIComponent.bEnable = tbPacket.enable
    EventManager:OnFireEvent(ClientEventDef.EV_AUTO_BATTLE, tbPacket.enable)
end

function DungeonPacketProcessor_C:OnRecvCampTypeChanged(tbPacket)
    -- 单机模式不重复设值
    if not GlobalVariableSystem:IsStandalone() then
        local tbCharacter = GameObjectSystem:FindByInstanceId(tbPacket.instance_id)
        if tbCharacter and tbCharacter.BattleCampComponent then
            tbCharacter.BattleCampComponent:SetCampType(tbPacket.camp_type)
        end
    end
end

function DungeonPacketProcessor_C:OnRecvStartCollection(tbPacket)
    InteractionHelper:CreateExplore(tbPacket.nresoueid,true)
end

function DungeonPacketProcessor_C:OnRepReviveInfoAndShow(tbPacket)
    BattleReviveSystem:RevivePanlShow(tbPacket.ReviveType , tbPacket.bIsDie,
    tbPacket.nWaitReviveTime, tbPacket.bIsCanRevive, tbPacket.nCostType, tbPacket.nCostNum)
end

function DungeonPacketProcessor_C:OnRepBattleFlagState(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_FLAG_STATE, tbPacket)
end

function DungeonPacketProcessor_C:OnInteractionEnd(tbPacket)
    -- InteractionSystem:OnInteractionEnd()
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_INTERACTIONDLG_END_NPC)
end

function DungeonPacketProcessor_C:OnInteractionBreak(tbPacket)
    InteractionSystem:OnDungCollectionBreak()
end

function DungeonPacketProcessor_C:OnBreakChangeDisplay(tbPacket)
    InteractionSystem:OnDungCollectionBreak()
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_CHANGINGDISPLAY_BREAK)
end

function DungeonPacketProcessor_C:WaitReset(tbPacket)
    BattleReviveSystem:WaitReset(tbPacket.type, tbPacket.countdown)
end

function DungeonPacketProcessor_C:OpenDialogBoard(tbPacket)
    local tbCharacter = GameObjectSystem:FindByInstanceId(tbPacket.character_instance_id)
    if tbCharacter then
         NpcDialogBoardHelper:OpenDialogBoard(tbPacket.dialog_id, tbCharacter)
    else
        logerror("tbCharacter is nil")
    end
end

function DungeonPacketProcessor_C:OnCountdown(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_SHOW_PREGAME_CD, tbPacket.countdown)
end

function DungeonPacketProcessor_C:OnShowOccupy(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_SHOW_OCCUPY, tbPacket.visible)
end

function DungeonPacketProcessor_C:OnReceiveTacticsCommand(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_RECEIVE_BATTLE_COMMAND, tbPacket)
end

function DungeonPacketProcessor_C:OnHideBattleUI(tbPacket)
    local bVisible = not tbPacket.hide
    EventManager:OnFireEvent(ClientEventDef.EV_UI_ATTACK_VISIBLE, bVisible, tbPacket.play_anim)
    -- local tbPlayerSelf = GamePlayerSelfHelper:Get()
    -- local PropertyWrapperHelper = tbPlayerSelf.BattleStatusComponent.PropertyWrapperHelper
    -- if not bVisible then
    --     self.nWeaponEnabledOverlapId = PropertyWrapperHelper:Overlap_Override("bWeaponEnabled", false)
    -- elseif self.nWeaponEnabledOverlapId > -1 then
    --     PropertyWrapperHelper:RemoveOverlap("bWeaponEnabled", self.nWeaponEnabledOverlapId)
    --     self.nWeaponEnabledOverlapId = -1
    -- end
end

-- function DungeonPacketProcessor_C:OnParachutionEnd(tbPacket)
--     if(not GlobalVariableSystem:IsStandalone()) then
--         EventManager:OnFireEvent(ClientEventDef.EV_FFA_PARACHUTION_END, tbPacket.is_ship)
--     end
-- end

function DungeonPacketProcessor_C:OnDestroyGameObject(tbPacket)
    local nInstanceId = tbPacket.instance_id
    log("Mark object ready to destroy", nInstanceId)
    GameObjectSystem:MarkReadyToDestroy(nInstanceId)

    local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
    if(not tbGameObject) then
        return
    end

    if(GameObjectSystem:IsReadyToDestroy(tbGameObject)) then
        log("Destroy object when ready", nInstanceId)
        GameObjectSystem:DestroyByInstanceId(nInstanceId)
    end
end

function DungeonPacketProcessor_C:OnFFAPlayerResult(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_RESULT, tbPacket)
end

function DungeonPacketProcessor_C:OnFFAKillBossResult(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_KILL_BOSS_RESULT, tbPacket)
end

function DungeonPacketProcessor_C:OnFFAShowDialog(tbPacket)
    local tbParam = {tbPacket.param1,tbPacket.param2}
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_SHOWDIALOG, tbPacket.dialog_id,tbParam)
end

function DungeonPacketProcessor_C:OnFFAKillInfo(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_KILLINFO, tbPacket)
end

-- function DungeonPacketProcessor_C:OnFFASelectionPoint(tbPacket)
--     for i, v in ipairs(tbPacket.PointInfos) do
--         local nX, nY = BitHelper:PosToXY(v.nPos)
--         v.nX = nX * COORDINATE_PROPORTION
--         v.nY = nY * COORDINATE_PROPORTION
--     end
--     EventManager:OnFireEvent(ClientEventDef.EV_FFA_SELECT_POINT, tbPacket)
-- end

-- function DungeonPacketProcessor_C:OnFFATransporterPlayerCount(tbPacket)
--     EventManager:OnFireEvent(ClientEventDef.EV_FFA_SELECT_TRANSPORTER_PLAYER_COUNT, tbPacket.nCount)
-- end

function DungeonPacketProcessor_C:OnFFATeammateLeave(tbPacket)
    UIManager:OpenWnd(UIDef.UI_TEAM_MEMBER_OFFLINE)
end

function DungeonPacketProcessor_C:OnNotifyNpcReset(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_NPC_RESET_TIMER, tbPacket.nInstanceId, tbPacket.nTime)
end

function DungeonPacketProcessor_C:OnFFAShowCoreArea(tbPacket)
    BattleCoreAreaSystem:SetCoreAreaShow(true)
    if tbPacket.bShowDialog then
        local nDungeonId = BattleGameModeSystem.nDungeonId
        local tbTemplate = DungeonDataTable:GetTemplate(nDungeonId)
        if tbTemplate then
            local tbUIMapTemplate = UIMapResDataTable:GetTemplate(tbTemplate.nUIRadarMapId)
            if tbUIMapTemplate then
                EventManager:OnFireEvent(ClientEventDef.EV_FFA_SHOWDIALOG, tbUIMapTemplate.nDialogId)
            else
                logerror("OnFFAShowCoreArea:tbUIMapTemplate is nil,nDungeonId=", nDungeonId)
            end
        end
        
    end
    EventManager:OnFireEvent(ClientEventDef.EV_SHOW_CORE_AREA, tbPacket)
end

function DungeonPacketProcessor_C:OnSyncBotInfos(tbPacket)
    BotDistributionSystem:ReceivePacket(tbPacket)
end

function DungeonPacketProcessor_C:OnProcessQuest(tbPacket)
    BattleQuestSystem:ReceivePacket(tbPacket)
end

function DungeonPacketProcessor_C:OnASQuestInfo(tbPacket)
    BattleQuestSystem:ReceiveASQuestPacket(tbPacket)
end

function DungeonPacketProcessor_C:OnASQuestResult(tbPacket)
    BattleQuestSystem:ReceiveASResultPacket(tbPacket)
end

function DungeonPacketProcessor_C:ShowCommonToast(tbPacket)
    UIUtils.ShowToastWithL10NFormat(tbPacket.key, tbPacket.param0, tbPacket.param1, tbPacket.param2)
end

function DungeonPacketProcessor_C:OnAdditionalSuccessChoice(tbPacket)
    UIManager:OpenWnd(UIDef.UI_ADDITIONAL_SUCCESS,tbPacket)
    --EventManager:OnFireEvent(ClientEventDef.EV_FFA_ADDITIONALSUCCESS_CHOICE, tbPacket)
end

function DungeonPacketProcessor_C:SearchPropDataForGM(tbPacket)
    -- 为了便于热更新，随用随加载，仅Debug使用
    local PropValueGMHelper = require("PropValueGMHelper")
    PropValueGMHelper.HandleSearchResult(tbPacket.key, tbPacket.data)
end

function DungeonPacketProcessor_C:DungeonAndPlayerState(tbPacket)
    if tbPacket.battle == true then
        log("DungeonAndPlayerState", tbPacket.state)
        EngineSettingSystem:OnDungeonAndPlayerState()
        EventManager:OnFireEvent(ClientEventDef.EV_FFA_ENTER_DUNGEON_IN_BATTLE)
    else
        EventManager:OnFireEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, tbPacket.state, tbPacket.battle, tbPacket.launch_time)
    end
end

function DungeonPacketProcessor_C:OnFFADeathPlayback(tbPacket)
    BattleResultSystem:SyncDeadPlaybackData(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_DEAD_PLAYBACK, tbPacket)
end

function DungeonPacketProcessor_C:OnReloginUsedVehicle(tbPacket)
    MiniMapSystem:SetLastVehicleId(tbPacket.nVehicleId)
    MiniMapSystem:SetLastVehicleLocation(tbPacket.nX, tbPacket.nY)
    EventManager:OnFireEvent(ClientEventDef.EV_RELOGIN_USED_VEHICLE, tbPacket)
end

function DungeonPacketProcessor_C:OnFFAProcessStateChanged(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, tbPacket.nState)
end

return DungeonPacketProcessor_C
