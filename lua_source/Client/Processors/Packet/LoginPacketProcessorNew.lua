-- 全局网络消息放这里
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local LoginPacketProcessorNew = luaclass("LoginPacketProcessorNew", NetMessageProcessorBase)

local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local ProcedureTool = require("ProcedureTool")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local UIUtils = require("UIUtils")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local UITextDef = require("UITextDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectSystem = require("GameObjectSystem_C")
local IAPSystem = require("IAPSystem")
local TutorialDungeonIni = require("TutorialDungeonIni")
local GVoiceSDKSystem = require("GVoiceSDKSystem")
local SurveyHelper = require("SurveyHelper")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local LoginResponseHelper = require("LoginResponseHelper")
local EnterLastDungeonHelper = require("EnterLastDungeonHelper")
local TransformEventDef = require("TransformEventDef")
local DataSDKHelper = require("DataSDKHelper")

function LoginPacketProcessorNew:Init()
    LoginPacketProcessorNew.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

function LoginPacketProcessorNew:RegisterPackets()
    self:BindMethod(Proto.s2c_LoginError, self, self.OnLoginError)
    self:BindMethod(Proto.s2c_NewPlayer, self, self.OnNewPlayer)
    self:BindMethod(Proto.s2c_CreatePlayerError, self, self.OnCreatePlayerError)
    self:BindMethod(Proto.s2c_PlayerData, self, self.OnPlayerData)

    -- 测试用
    -- self:BindMethod(Proto.s2c_PlayerList, self, function(_, tbPacket)
    --     UIUtils.HideLoadingDialog()
    --     if #tbPacket.players > 0 then
    --         local Socket = NetworkManager:GetHubServerProxy()
    --         local tbSelectRole = tbPacket.players[1]
    --         local c2s_EnterGame =
    --         {
    --             player_id = tbSelectRole.id
    --         }
    --         if(not Socket:SendPacket(Proto.c2s_EnterGame, c2s_EnterGame)) then
    --             UIUtils.ShowToast("Send login packet failed.")
    --             logwarning("Send login packet failed.")
    --         end
    --         -- ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_SelectRole, tbPacket.players)
    --     else
    --         ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_CreateRole, nil)
    --     end
    -- end)
end

function LoginPacketProcessorNew:OnLoginError(tbPacket)
	LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.HUB_LOGIN_ERROR)
    local nRetCode = tbPacket.return_code
    if nRetCode == Proto.ReturnCode.LOGIN_FAIL then
        UIUtils.ShowToast(UITextDef.LOGIN_FAIL)
    elseif nRetCode == Proto.ReturnCode.REVISION_CHECK_FAILED then
        UIUtils.ShowToast(UITextDef.REVISION_CHECK_FAILED)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_LOGIN_ERROR)
end

function LoginPacketProcessorNew:OnNewPlayer()
    LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.HUB_LOGIN_NEWPLAYER)

    EventManager:OnFireEvent(ClientEventDef.EV_NEW_PLAYER)
    -- local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    -- local szCompleteSingel = pSaveGameMgr:GetStringData("GUIDE_SINGLE_BE_COMPLETE")
    -- local bComplete = szCompleteSingel =="1"
    if TutorialDungeonIni.bEnabled then
        UIManager:OpenWnd(UIDef.UI_SELECTLEVEL)
    else
        ProcedureTool:EnterCreateRole()
    end
end

function LoginPacketProcessorNew:OnCreatePlayerError(tbPacket)
	LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.HUB_LOGIN_ERROR)
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

-- local function SendDeviceInfo()
--     local nDeviceLevel = RenderExtendBlueprintFunctions.GetDevicePerformanceLevel()
--     local szDeviceMake = RenderExtendBlueprintFunctions.GetDeviceMake()
--     local szDeviceModel = RenderExtendBlueprintFunctions.GetDeviceModel()
--     local szOsVersion   = RenderExtendBlueprintFunctions.GetOSVersion()
--     local szClientAppVersion = GlobalVariableSystem:GetAppVersion()
--     local szClientResVersion = GlobalVariableSystem:GetResVersion()
--     log("DeviceInfo: nDeviceLevel " .. nDeviceLevel .. " szDeviceMake " .. szDeviceMake.. " szDeviceModel " .. szDeviceModel .. " OSVersion " .. szOsVersion .. " ClientAppVersion " .. szClientAppVersion .. " ClientResVersion " .. szClientResVersion)
--     local tbParams = {}
--     tbParams.brand = szDeviceMake
--     tbParams.model = szDeviceModel
--     tbParams.performance_level = nDeviceLevel
--     tbParams.os_version = szOsVersion
--     tbParams.client_app_version = szClientAppVersion
--     tbParams.client_res_version = szClientResVersion
--     NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_DeviceInfo, tbParams)
-- end

function LoginPacketProcessorNew:OnPlayerData(tbPacket)
	LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.HUB_LOGIN_PLAYER_DATA)
    GlobalVariableSystem:SetWithLobby(true)
    GamePlayerSelfHelper:SetEnableSaveComponents(false)
    GameObjectSystem:DestroyAll()
    GamePlayerSelfHelper:SetEnableSaveComponents(true)

    -- 模拟新流程
    -- local tbOldPacket = tbPacket
    -- tbPacket = {}
    -- local tbData = {}
    -- tbPacket.data = tbData
    -- tbData.id = tbOldPacket.player_id
    -- tbData.name = tbOldPacket.name
    -- tbData.avatar_id = tbOldPacket.data.avatar.avatar_id
    -- tbData.level = tbOldPacket.data.basic.level
    -- tbData.exp = tbOldPacket.data.basic.exp

    local tbPlayerData = tbPacket.data
    local nPlayerId = tbPlayerData.id
    --log event system onRoleLogin
    EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_ROLE_LOGIN, tbPacket.data)
    GlobalVariableSystem.nSelfLobbyPlayerId = nPlayerId
    GVoiceSDKSystem:InitWithPlayerID(tostring(nPlayerId))
    SurveyHelper.SetLoginStatus(true)
    -- 切换本地数据存储保存的UserId
	ClientShell.GetClient(GWorld):GetSaveGameManager():SetSlotUserId(nPlayerId)

    log(string.format("OnRecvPlayerDataNew, name = %s, player_id = %d, ip = %s", tbPlayerData.name, tbPlayerData.id, EngineExtActorShell.GetLocalHostAddress()))

    -- local tbCurrentServerData = GlobalVariableSystem.tbCurrentServerData
    -- local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
	-- pChannelSdkManager:SetRoleIdAndName(tostring(nPlayerId), tbPlayerData.name)
    --世游版本暂时不统计
    --pChannelSdkManager:SetRoleLevel(tostring(tbPlayerData.level))
    -- pChannelSdkManager:SetServerIDAndName(tbCurrentServerData.id, tbCurrentServerData.name)
    DataSDKHelper.OnEnterGame()
    BuglyCrashReportBPLibrary.SetUserIdentifier(tbPlayerData.name)

    --SendDeviceInfo()

    -- 在这里并不创建Actor，等切到wildprocedure才创建actor，这里只是创出个壳
    local bDungeon = GlobalVariableSystem:IsInDungeon()
    GlobalVariableSystem:SetInDungeon(false)
    GameObjectSystem:CreatePlayerSelfWithHubLoginData(tbPacket)
    GlobalVariableSystem:SetInDungeon(bDungeon)

    if IAPSystem:IsIAPEnabled() then
        -- 请求恢复订单
        IAPSystem:RequestRestoreOrder()
    end
    IAPSystem:ReceiveFirstPurchaseState(tbPlayerData.iap.first_purchase_state)
    EventManager:OnFireEvent(ClientEventDef.EV_PLAYERDATA_SYNC, tbPacket)
    GlobalVariableSystem:SetDungeonSessionId(tbPlayerData.dungeon.game_session_id)

    if GlobalVariableSystem.bNewReconnect then
        local bEnterLastDungeon = EnterLastDungeonHelper:ShouldGotoLastDungeon(tbPacket)
        if bEnterLastDungeon then
            GameObjectSystem:RestorePlayerSelfObject(false, nPlayerId, nil, true)
            GameObjectSystem:DestroyAll()
            EnterLastDungeonHelper:EnterLastDungeon(EnterLastDungeonHelper:GetLastDungeonId(tbPacket))
        else
            local tbParam = {}
            tbParam.tbPlayerData = tbPlayerData
            tbParam.bShowLoading = GlobalVariableSystem.bEnterLobbyLoading
            ProcedureTool:EnterLobby(tbParam)
        end
    else
        local tbParam = {}
        tbParam.tbPlayerData = tbPlayerData
        tbParam.bShowLoading = GlobalVariableSystem.bEnterLobbyLoading
        ProcedureTool:EnterLobby(tbParam)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_LOADING_TRANSFORM, TransformEventDef.TARGET_EVENT_NAME.LOGIN_FINISHI)
end

return LoginPacketProcessorNew
