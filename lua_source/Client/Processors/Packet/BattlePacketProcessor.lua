-- 在战斗中受到的hubserver的消息，返回大世界，结算消息等
local luaclass = require("luaclass")
--local CreatePlayerPacketProcessor = require("CreatePlayerPacketProcessor")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local BattlePacketProcessor = luaclass("BattlePacketProcessor", NetMessageProcessorBase)

-- local UIDef = require("UIDef")
-- local UIManager = require("UIManager")
local NetworkManager = dynamic_require("NetworkManager")
local ProcedureTool = require("ProcedureTool")
local Proto = require("ClientProtoNames")
-- local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local DungeonDataTable = require("DungeonDataTable")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

-- 注册处理包
function BattlePacketProcessor:RegisterPackets()
    --BattlePacketProcessor.super.RegisterPackets(self)
    --self:BindMethod(Proto.s2c_LeaveDungeon, self, self.OnLeaveDungeon)
    -- self:BindMethod(Proto.s2c_LeaveLocalDungeon, self, self.OnLeaveLocalDungeon)
    -- self:BindMethod(Proto.s2c_ShowLocalDungeonAward, self, self.OnShowLocalDungeonAward)
    -- self:BindMethod(Proto.s2c_RetryLocalGame, self, self.OnRetryLocalGame)
    self:BindMethod(Proto.s2c_EnterDungeon, self, self.OnEnterDungeon)
    self:BindMethod(Proto.s2c_LastDungeonEnd, self, self.OnEnterLastDungeonFailed)
    self:BindMethod(Proto.s2c_CreatePlayerError, self, self.OnCreatePlayerError)
end

-- function BattlePacketProcessor:OnShowLocalDungeonAward(s2c_ShowLocalDungeonAward)
--     -- 1、d2c发送给客户端 d2c_ShowAward
--     local tbPlayerAward = {}
--     tbPlayerAward.nResultType = s2c_ShowLocalDungeonAward.result
--     tbPlayerAward.tbAwardList = {}
--     local tbAwardList = tbPlayerAward.tbAwardList
--     local tbAward = nil
--     for k, award in pairs(s2c_ShowLocalDungeonAward.awards) do
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

-- 初始化
function BattlePacketProcessor:Init()
    log("BattlePacketProcessor:Init")
    BattlePacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

-- 结束
function BattlePacketProcessor:Uninit()
    log("BattlePacketProcessor:Uninit")
    BattlePacketProcessor.super.Uninit(self)
end

-- function BattlePacketProcessor:OnLeaveDungeon(tbPacket)
--     local pClientShell = ClientShell.GetClient(GWorld)
--     local bIsSmoothTravel = pClientShell:IsInSmoothTravel()
--     local nReason = tbPacket.reason
--     if nReason == Proto.s2c_LeaveDungeon_LeaveReason.DUNGEON_DROPPED_FROM_HUB then
--         log("BattlePacketProcessor:OnLeaveDungeon DUNGEON_DROPPED_FROM_HUB maybe server internal error.")
--         -- TODO 需要增加机制通知客户端退出原因
--     end

--     pClientShell:GetDungeonShell():DisconnectFromDungeonServer(bIsSmoothTravel)

--     ProcedureTool:EnterWildWorld(tbPacket.scene_id, "OnLeaveDungeon",
--         tbPacket.actor_id, tbPacket.transform, bIsSmoothTravel, nil)
-- end

-- function BattlePacketProcessor:OnLeaveLocalDungeon(tbPacket)
--     -- ProcedureTool:EnterWildWorld(tbPacket.scene_id, "OnLeaveLocalDungeon",
--     --     tbPacket.actor_id, tbPacket.transform, false, nil)
--     ProcedureTool:EnterLobby()
-- end

-- function BattlePacketProcessor:OnRetryLocalGame()
--     EventManager:OnFireEvent(CommonEventDef.EV_RECEIVE_BATTLE_RETRY_GAME_FROM_HUB)
-- end

function BattlePacketProcessor:OnEnterDungeon(tbPacket)
    local NetworkMgr = ClientShell.GetClient(GWorld):GetClientNetworkManager()
    local nTemplateId = tbPacket.dungeon_template_id
    local szDungeonSessionId = tbPacket.game_session_id
    local szIP = NetworkMgr:ConvertIPToString(tbPacket.udp_ipv4);
    local DungeonData = DungeonDataTable:GetTemplate(nTemplateId)
    if(DungeonData == nil) then
        logerror("BattlePacketProcessor:OnEnterDungeon failed, cannot find Dungeon id: ", nTemplateId)
        return
    end
    local szTargetIP = szIP..":"..tbPacket.udp_port
    local nToken = tbPacket.token
    local nPlayerId = PlayerSelfHelper:Get():GetPlayerId()
    GlobalVariableSystem:SetDungeonSessionId(tbPacket.game_session_id)
    EventManager:OnFireEvent(ClientEventDef.EV_ENTER_DUNGEON, szTargetIP, nToken, nPlayerId, nTemplateId, nil--[[szPlayerName]], szDungeonSessionId, tbPacket.encrypt)
end

function BattlePacketProcessor:OnEnterLastDungeonFailed(tbPacket)
    log("OnEnterLastDungeonFailed")
    EventManager:OnFireEvent(ClientEventDef.EV_ENTER_LAST_DUNGEON_FAILED)

    ClientShell.GetClient(GWorld):GetDungeonShell():DisconnectFromDungeonServer(false)
    ProcedureTool:EnterLobby()
    UIUtils.ShowToast(UITextDef.FAILED_ENTER_LAST_DUNGEON)
end

function BattlePacketProcessor:OnCreatePlayerError(tbPacket)
    UIUtils.HideLoadingDialog()
    local nRetCode = tbPacket.return_code
    if nRetCode == Proto.ReturnCode.NAME_UNAVAILABLE then
        UIUtils.ShowToast(UITextDef.NAME_UNAVAILABLE)
    elseif nRetCode == Proto.ReturnCode.PLAYER_NAME_LENGTH then
        UIUtils.ShowToast(UITextDef.USER_NAME_LEN_ERROR)
    elseif nRetCode == Proto.ReturnCode.PLAYER_NAME_CHAR then
        UIUtils.ShowToast(UITextDef.NAME_ILLEGAL)
    elseif nRetCode == Proto.ReturnCode.INVALID_REQUEST then
        UIUtils.ShowToast(UITextDef.INVALID_REQUEST)
    elseif nRetCode == Proto.ReturnCode.SERVER_ERROR then
        UIUtils.ShowToast(UITextDef.SERVER_ERROR)
    elseif nRetCode == Proto.ReturnCode.PLAYER_COUNT_LIMIT then
        UIUtils.ShowToast(UITextDef.PLAYER_COUNT_LIMIT)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_CREATE_PLAYER_ERROR)
end

return BattlePacketProcessor
