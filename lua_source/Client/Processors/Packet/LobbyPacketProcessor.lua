local luaclass = require("luaclass")
local CreatePlayerPacketProcessor = require("CreatePlayerPacketProcessor")
local LobbyPacketProcessor = luaclass("LobbyPacketProcessor", CreatePlayerPacketProcessor)

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local ProcedureTool = require("ProcedureTool")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local DungeonDataTable = require("DungeonDataTable")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local MatchmakingSystem = require("MatchmakingSystem")
--local CppDelegate = require("CppDelegate")
local ScreenCaptureHelper = require("ScreenCaptureHelper")

local MATCH_TIME_OUT_EXIT_TIME = 4

local MATCHMAKING_RETURN_CODE =
{
    [Proto.s2c_StartMatchmaking_Reason.SUCCESS] = UISetUtils.GetL10NTextByKey("MATCH_SUCCESS"),
    [Proto.s2c_StartMatchmaking_Reason.TIMEOUT] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_TIMEOUT")),
    [Proto.s2c_StartMatchmaking_Reason.CONNECT_ERROR] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_CONNECT_ERROR")),
    [Proto.s2c_StartMatchmaking_Reason.MATCHMAKER_NOT_FOUND] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_MATCHMAKER_NOT_FOUND")),
    [Proto.s2c_StartMatchmaking_Reason.NOT_TEAM_LEADER] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_NOT_TEAM_LEADER")),
    [Proto.s2c_StartMatchmaking_Reason.TEAM_MEMBER_NOT_READY] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_TEAM_MEMBER_NOT_READY")),
    [Proto.s2c_StartMatchmaking_Reason.COLLECT_PLAYER_PROPERTIES_ERROR] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_COLLECT_PLAYER_PROPERTIES_ERROR")),
    [Proto.s2c_StartMatchmaking_Reason.STATUS_ERROR] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_STATUS_ERROR")),
    [Proto.s2c_StartMatchmaking_Reason.ROUND_NUMBER_CHECK_FAILED] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_ROUND_NUMBER_CHECK_FAILED")),
    [Proto.s2c_StartMatchmaking_Reason.NOT_IN_OPEN_TIME] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_NOT_IN_OPEN_TIME")),
    [Proto.s2c_StartMatchmaking_Reason.UNKNOWN_REASON] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_UNKNOWN_ERROR")),
}

local CANCEL_MATCHMAKING_RETURN_CODE =
{
    [Proto.s2c_CancelMatchmaking_Reason.PLAYER_CANCEL] = UISetUtils.GetL10NTextByKey("CANCEL_MATCH_BY_PLAYER"),
    [Proto.s2c_CancelMatchmaking_Reason.MATCHMAKING_TIMEOUT] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("CANCEL_MATCH_BY_MATCHMAKING_TIMEOUT")),
    [Proto.s2c_CancelMatchmaking_Reason.MATCHMAKING_RESET] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("CANCEL_MATCH_BY_MATCHMAKING_RESET")),
    [Proto.s2c_CancelMatchmaking_Reason.NOT_IN_MATCHMAKING] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("CANCEL_MATCH_NOT_IN_MATCHMAKING")),
    [Proto.s2c_CancelMatchmaking_Reason.NOT_TEAM_LEADER] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("CANCEL_MATCH_NOT_TEAM_LEADER")),
    [Proto.s2c_CancelMatchmaking_Reason.MATCHMAKING_COMPLETE] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("CANCEL_MATCH_MATCHMAKING_COMPLETE")),
    [Proto.s2c_CancelMatchmaking_Reason.REQUEST_NOT_FOUND] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("CANCEL_MATCH_REQUEST_NOT_FOUND")),
    [Proto.s2c_CancelMatchmaking_Reason.REQUEST_TIMEOUT] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("CANCEL_MATCH_REQUEST_TIMEOUT")),
    [Proto.s2c_CancelMatchmaking_Reason.REQUEST_FAILED] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("CANCEL_MATCH_REQUEST_FAILED")),
    [Proto.s2c_CancelMatchmaking_Reason.UNKNOWN_REASON] = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("CANCEL_MATCH_UNKNOWN_REASON")),
}

LobbyPacketProcessor.bWaitLoadingReady = false

function LobbyPacketProcessor:Init()
    log("LobbyPacketProcessor:Init")
    LobbyPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

function LobbyPacketProcessor:Uninit()
    log("LobbyPacketProcessor:Uninit")
    LobbyPacketProcessor.super.Uninit(self)
    self.bWaitLoadingReady = false
end

function LobbyPacketProcessor:RegisterPackets()
    LobbyPacketProcessor.super.RegisterPackets(self)
    --self:BindMethod(Proto.s2c_GetAVGProgress, self, self.OnGetAVGProgress)
    -- self:BindMethod(Proto.s2c_FFAStartGameFailed, self, self.OnFFAStartGameFailed)
    self:BindMethod(Proto.s2c_StartMatchmaking, self, self.OnStartMatchmaking)
    self:BindMethod(Proto.s2c_CancelMatchmaking, self, self.OnCancelMatchmaking)
    self:BindMethod(Proto.s2c_EnterDungeon, self, self.OnEnterDungeon)
    self:BindMethod(Proto.s2c_MatchmakingOpenTime, self, self.OnMatchmakingOpenTime)
end

-- function LobbyPacketProcessor:OnGetAVGProgress(tbPacket)
--     local nAVGId = tbPacket.avg_id
--     EventManager:OnFireEvent(ClientEventDef.EV_UI_LOBBY_REFRESH_AVG, nAVGId)
-- end

-- function LobbyPacketProcessor:OnFFAStartGameFailed(tbPacket)
--     EventManager:OnFireEvent(ClientEventDef.EV_UI_ENTER_GAME_FAILED, tbPacket.reason)
-- end

function LobbyPacketProcessor:OnWaitingDungeon(tbPacket)
    if(GlobalVariableSystem.bQuickBattleLoading) then
        EventManager:OnFireEvent(ClientEventDef.EV_LOBBY_SHIELD_MASK)
        return
    end

    local tbParam = {}
    tbParam.nDungeonId = tbPacket.dungeon_template_id
    tbParam.bStandalone = false
    tbParam.bWaitLoadingReady = self.bWaitLoadingReady
    if ProcedureTool:EnterDungeon(tbParam) then
        EventManager:OnFireEvent(ClientEventDef.EV_ON_WAITING_DUNGEON)
    else
        log("LobbyPacketProcessor:OnWaitingDungeon failed disconnect")
    end
end

function LobbyPacketProcessor:OnEnterDungeon(tbPacket)
    if(not GlobalVariableSystem.bQuickBattleLoading) then
        return
    end

    local NetworkMgr = ClientShell.GetClient(GWorld):GetClientNetworkManager()
    local nTemplateId = tbPacket.dungeon_template_id
    local szIP = NetworkMgr:ConvertIPToString(tbPacket.udp_ipv4);
    local DungeonData = DungeonDataTable:GetTemplate(nTemplateId)
    if(DungeonData == nil) then
        logerror("BattlePacketProcessor:OnEnterDungeon failed, cannot find Dungeon id: ", nTemplateId)
        return
    end

    GlobalVariableSystem:SetDungeonSessionId(tbPacket.game_session_id)
    local szTargetIP = szIP..":"..tbPacket.udp_port
    local nToken = tbPacket.token
    local nPlayerId = PlayerSelfHelper:Get():GetPlayerId()

    local tbParam = {}
    tbParam.nDungeonId = tbPacket.dungeon_template_id
    tbParam.bStandalone = false
    --tbParam.bWaitLoadingReady = self.bWaitLoadingReady
    tbParam.szTargetIp = szTargetIP
    tbParam.nToken = nToken
    tbParam.nPlayerId = nPlayerId
    tbParam.bQuickBattleLoading = true
    tbParam.szDungeonSessionId = tbPacket.game_session_id
    tbParam.nEncryptionSeed = tbPacket.encrypt
    ScreenCaptureHelper.Capture(function(nWidth, nHeight, pShotTexture)
        tbParam.tbLoadingInfo = {
            pTexture = pShotTexture,
            nWidth = nWidth,
            nHeight = nHeight
        }

        if ProcedureTool:EnterDungeon(tbParam) then
            EventManager:OnFireEvent(ClientEventDef.EV_ON_WAITING_DUNGEON)
        else
            log("LobbyPacketProcessor:OnEnterDungeon failed disconnect")
        end
    end)
end

function LobbyPacketProcessor:OnStartMatchmaking(tbPacket)
    local bSuccess = tbPacket.success
    local l10nText = MATCHMAKING_RETURN_CODE[tbPacket.reason]
    if not l10nText then
        l10nText = L10N:Format(UISetUtils.GetL10NTextByKey("MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("MATCH_UNKNOWN_ERROR"))
    end
    UIUtils.ShowToast(l10nText)
    MatchmakingSystem:OnStartMatchmaking(bSuccess)
    EventManager:OnFireEvent(ClientEventDef.EV_MATCHMAKING_RESULT, bSuccess, tbPacket.reason)
end

function LobbyPacketProcessor:OnCancelMatchmaking(tbPacket)
    local bSuccess = tbPacket.success
    local l10nText = CANCEL_MATCHMAKING_RETURN_CODE[tbPacket.reason]
    if not l10nText then
        l10nText = L10N:Format(UISetUtils.GetL10NTextByKey("CANCEL_MATCH_FAILED_FORMAT"), UISetUtils.GetL10NTextByKey("CANCEL_MATCH_UNKNOWN_ERROR"))
    end
    UIUtils.ShowToast(l10nText)
    if tbPacket.reason == Proto.s2c_CancelMatchmaking_Reason.MATCHMAKING_TIMEOUT then
        UIUtils.ShowCountDownDialog(UISetUtils.GetL10NTextByKey("LOBBY_MATCH_TIME_OUT_TITLE"),
        UISetUtils.GetL10NTextByKey("LOBBY_MATCH_TIME_OUT_INFO"), UISetUtils.GetL10NTextByKey("UIQUESTIONRESULT_BUTTON_OK"),
        nil, nil, nil, GlobalVariableSystem:GetLocalTime() + MATCH_TIME_OUT_EXIT_TIME, nil)
    end
    MatchmakingSystem:OnCancelMatchmaking(bSuccess)
    EventManager:OnFireEvent(ClientEventDef.EV_CANCEL_MATCHMAKING, bSuccess)
end

function LobbyPacketProcessor:OnMatchmakingOpenTime(tbPacket)
    if tbPacket.code == Proto.ReturnCode.OK then
        EventManager:OnFireEvent(ClientEventDef.EV_MATCHMAKING_OPEN_TIME, tbPacket.openTimes, tbPacket.openModes)
    end
end

return LobbyPacketProcessor
