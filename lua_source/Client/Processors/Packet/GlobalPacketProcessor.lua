-- 全局网络消息放这里
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local GlobalPacketProcessor = luaclass("GlobalPacketProcessor", NetMessageProcessorBase)

local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local NetworkManager = dynamic_require("NetworkManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local Proto = require("ClientProtoNames")
local ProcedureTool = require("ProcedureTool")
local DefaultNetworkProxy = require("DefaultNetworkProxy")
-- local PlayerSelfHelper = require("GamePlayerSelfHelper")
local NPCSystem = require("NPCSystem")
local ReconnectSystem = require("ReconnectSystemNew")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local UIDef = require("UIDef")
local DisconnectType = require("DisconnectTypeNew")
local BattleKickPlayerReasonDef = require("BattleKickPlayerReasonDef")
local UIManager = require("UIManager")

local DisconnectReasonType = DefaultNetworkProxy.DisconnectReason

GlobalPacketProcessor.nDisconnectReason = -1
GlobalPacketProcessor.tbDisconnectParam = nil

function GlobalPacketProcessor:OnConnected(bResult)
    EventManager:OnFireEvent(ClientEventDef.EV_CONNECTED, bResult)
end

function GlobalPacketProcessor:OnDisconnected(nSocketId, nDisconnectReason)
    EventManager:OnFireEvent(ClientEventDef.EV_DISCONNECTED, nDisconnectReason)

    if nDisconnectReason == DisconnectReasonType.Disconnect_Initiative then
        log("set enter game false, initiative disconnect")
        ProcedureTool:ReturnToStartGame()
    elseif nDisconnectReason == DisconnectReasonType.Disconnect_Passivity then
        log("Disconnect from hub server: ", self.nDisconnectReason)
        ReconnectSystem:DisconnectFromHubServer(self.nDisconnectReason, self.tbDisconnectParam)
        self.nDisconnectReason = -1
        self.tbDisconnectParam = nil
    end
end


function GlobalPacketProcessor:Init()
    GlobalPacketProcessor.super.Init(self)

    local HubServerNetProxy = NetworkManager:GetHubServerProxy()
    self:SetBinder(HubServerNetProxy)
    if(HubServerNetProxy) then
        HubServerNetProxy:BindConnected(self, self.OnConnected)
        HubServerNetProxy:BindDisconnected(self, self.OnDisconnected)
    end

    self:RegisterPackets()
    -- ServerTimeSynchronizer:Init()
    return true
end

function GlobalPacketProcessor:Uninit()
    -- ServerTimeSynchronizer:Uninit()

    local HubServerNetProxy = self:GetBinder()
    if(HubServerNetProxy) then
        HubServerNetProxy:UnbindConnected()
        HubServerNetProxy:UnbindDisconnected()
    end
    GlobalPacketProcessor.super.Uninit(self)
end

function GlobalPacketProcessor:RegisterPackets()
    self:BindMethod(Proto.s2c_ServerTime, self, self.OnServerTimeSync)
    -- self:BindMethod(Proto.s2c_SyncKVP, self, self.OnSyncKVP)
    -- self:BindMethod(Proto.s2c_DeleteKVP, self, self.OnDeleteKVP)
    -- self:BindMethod(Proto.s2c_DeleteKVPGroup, self, self.OnDeleteKVPGroup)
    self:BindMethod(Proto.s2c_Disconnect, self, self.OnDisconnectServer)
    self:BindMethod(Proto.s2c_BanPlayer, self, self.OnBanPlayer)
    -- self:BindMethod(Proto.s2c_AddNpcInfo, self, self.OnAddNpcInfo)
    -- self:BindMethod(Proto.s2c_RemoveNpcInfo, self, self.OnRemoveNpcInfo)
    -- self:BindMethod(Proto.s2c_PingInterval, self, self.OnPingInterval)
    -- self:BindMethod(Proto.s2c_NewGameDay, self, self.OnNewGameDay)
    --客户端超时给服务器发c2s_TravelDungeonFailed后会立即切到wild procedure，s2c_DungeonEnterFailed和s2c_LeaveDungeon
    --会被pengding，直到wild procedure关闭pending时才能收到这两个消息，所以需要在全局听这两个消息
    self:BindMethod(Proto.s2c_DungeonEnterFailed, self, self.OnDungeonEnterFailed)
    self:BindMethod(Proto.s2c_LeaveDungeon, self, self.OnLeaveDungeon)
    self:BindMethod(Proto.s2c_PlayerKicked, self, self.OnPlayerKicked)
    -- self:BindMethod(Proto.s2c_LogStreaming, self, self.OnRecvLogStreaming)
    --
    self:BindMethod(Proto.s2c_ShowToast, self, self.OnShowToast)
end

function GlobalPacketProcessor:OnServerTimeSync(tbPacket)
     GlobalVariableSystem:OnRecvServerSyncTime(tbPacket.unix_time_ms, tbPacket.timezone_offset_seconds)
end

-- function GlobalPacketProcessor:OnSyncKVP(tbPacket)
--     local nGroupIndex = tbPacket.key_group
--     local nKeyId = tbPacket.key_id
--     local nValue = tbPacket.value
--     --local GroupId = KVP.GroupId

--     if PlayerSelfHelper:Get() then
--         PlayerSelfHelper:Get().KVPComponent:UpdateKVP(nGroupIndex, nKeyId, nValue)
--     end
--     EventManager:OnFireEvent(ClientEventDef.EV_UPDATE_KVP, nGroupIndex, nKeyId, nValue)
--     EventManager:OnFireEvent(ClientEventDef.EV_SYNC_KVP, nGroupIndex)
-- end

-- function GlobalPacketProcessor:OnDeleteKVP(tbPacket)
--     local nGroupIndex = tbPacket.key_group
--     local nKeyId = tbPacket.key_id
--     local GroupId = tbPacket.GroupId

--     local KVPComponent = PlayerSelfHelper:Get().KVPComponent
--     local nValue = KVPComponent:Get(GroupId, nKeyId)
--     PlayerSelfHelper:Get().KVPComponent:DeleteKVP(nGroupIndex, nKeyId)

--     EventManager:OnFireEvent(ClientEventDef.OnDeleteKVP, nGroupIndex, nKeyId, nValue)
--     EventManager:OnFireEvent(ClientEventDef.EV_SYNC_KVP, nGroupIndex)
-- end

-- function GlobalPacketProcessor:OnDeleteKVPGroup(tbPacket)
--     local nGroup = tbPacket.group
--     PlayerSelfHelper:Get().KVPComponent:DeleteKVPGroup(nGroup)
--     EventManager:OnFireEvent(ClientEventDef.EV_SYNC_KVP, nGroup)
-- end

function GlobalPacketProcessor:OnAddNpcInfo(tbPacket)
    NPCSystem:AddServerNPCInfo(tbPacket.scene_id, tbPacket.actor_id,
        tbPacket.template_id, tbPacket.transform, tbPacket.usage)

    if tbPacket.usage == Proto.s2c_AddNpcInfo_NpcUsageType.GATHER then
        EventManager:OnFireEvent(ClientEventDef.EV_UPDATE_GATHER_POINT)
    end
end

function GlobalPacketProcessor:OnRemoveNpcInfo(tbPacket)
    NPCSystem:RemoveServerNPCInfo(tbPacket.actor_id)
    EventManager:OnFireEvent(ClientEventDef.EV_UPDATE_GATHER_POINT)
end

function GlobalPacketProcessor:OnDisconnectServer(tbPacket)
    -- self:ShowDisconnectDialog(tbPacket.reason)
    self.nDisconnectReason = tbPacket.reason
end

function GlobalPacketProcessor:OnBanPlayer(tbPacket)
    self.nDisconnectReason = Proto.s2c_Disconnect_Reason.BANNED
    self.tbDisconnectParam = {nDuration = tbPacket.duration, szReason = tbPacket.reason}
end

-- function GlobalPacketProcessor:OnNewGameDay(tbPacket)
--     EventManager:OnFireEvent(ClientEventDef.EV_NEW_GAME_DAY)
-- end

function GlobalPacketProcessor:OnDungeonEnterFailed(tbPacket)
    local FailReason = tbPacket.reason
    log("GlobalPacketProcessor:OnDungeonEnterFailed,fail reason=", FailReason)
    local l10Reason = nil
    if FailReason == Proto.s2c_DungeonEnterFailed_FailReason.DUNGEON_APPLY_FAILED then
        l10Reason = UISetUtils.GetL10NTextByKey("DUNGEON_NOT_READY")
    elseif FailReason == Proto.s2c_DungeonEnterFailed_FailReason.MATCH_END then
        l10Reason = UISetUtils.GetL10NTextByKey("DUNGEON_ALREADY_END")
    else
        l10Reason = UISetUtils.GetL10NTextByKey("DUNGEON_DROPPED_FROM_HUB")
    end
    UIUtils.ShowToast(l10Reason, 1)
    -- ProcedureTool:EnterWildWorld(tbPacket.scene_id, "OnDungeonEnterFailed",
    -- tbPacket.actor_id, tbPacket.transform, false, nil)

    ProcedureTool:EnterLobby(nil, true)
end

local function CloseAllConnectDialog()
    UIManager:CloseWnd(UIDef.UI_WAIT_CONNECT_DIALOG)
    -- 跟副本断开连接有断开连接弹窗，副本结束后，会收到s2c_LeaveDungeon进入大厅，需要关闭DisconnectDialog
    UIUtils.CloseConnectDialog()
end

local function DisconnectFromDungeonServer()
    local pClientShell = ClientShell.GetClient(GWorld)
    local bIsSmoothTravel = pClientShell:IsInSmoothTravel()
    pClientShell:GetDungeonShell():DisconnectFromDungeonServer(bIsSmoothTravel)
end

local function fnEnterWildWorld()
    CloseAllConnectDialog()
    DisconnectFromDungeonServer()
    -- ProcedureTool:EnterWildWorld(tbPacket.scene_id, "OnLeaveDungeon",
    --    tbPacket.actor_id, tbPacket.transform, bIsSmoothTravel, nil)
    ProcedureTool:EnterLobby()
end

function GlobalPacketProcessor:OnLeaveDungeon(tbPacket)
    local nReason = tbPacket.reason
    if nReason == Proto.s2c_LeaveDungeon_LeaveReason.CLIENT_LOGOUT_FROM_DUNGEON then
        log("GlobalPacketProcessor:OnLeaveDungeon set pending true")
        NetworkManager:SetPending(true)
        UIUtils.ShowDisconnectDialog(UITextDef.DISCONNECT_FROM_DUNGEONSERVER, UITextDef.L10N_OK, function() 
            UIUtils.CloseConnectDialog(true)
            NetworkManager:SetPending(false)
            log("GlobalPacketProcessor:OnLeaveDungeon set pending false")
            fnEnterWildWorld()
        end, DisconnectType.disconnected)
    elseif nReason == Proto.s2c_LeaveDungeon_LeaveReason.DUNGEON_DROPPED_FROM_HUB then
        log("GlobalPacketProcessor:OnLeaveDungeon DUNGEON_DROPPED_FROM_HUB maybe server internal error.")
        -- TODO 需要增加机制通知客户端退出原因
        fnEnterWildWorld()
    else
        fnEnterWildWorld()
    end

end

function GlobalPacketProcessor:OnPlayerKicked(tbPacket)
    local nReason = tbPacket.reason
    log("GlobalPacketProcessor:OnPlayerKicked,reason:", nReason)

    if nReason == BattleKickPlayerReasonDef.Normal then
        fnEnterWildWorld()
    elseif nReason == BattleKickPlayerReasonDef.TrainingCampNotifyLeave then
        CloseAllConnectDialog()
        DisconnectFromDungeonServer()

        local l10nMessage = UISetUtils.GetL10NTextByKey("NOTIFY_LEAVE_TRAININGCAMP_DUNGEON_MESSAGE")
        UIUtils.ShowConfirmDialog("", l10nMessage, function()
            ProcedureTool:EnterLobby()
        end)
    else
        fnEnterWildWorld()
    end
end

-- function GlobalPacketProcessor:OnRecvLogStreaming(tbPacket)
--     LogReportSystem:SetEnableLog(tbPacket.enable, tbPacket.max_level)
-- end

function GlobalPacketProcessor:OnShowToast(tbPacket)
    local l10nMessage = tbPacket.text_localized
    if not l10nMessage then
        l10nMessage = tbPacket.text_plain
    end
    UIUtils.ShowToast(l10nMessage)
end

return GlobalPacketProcessor
