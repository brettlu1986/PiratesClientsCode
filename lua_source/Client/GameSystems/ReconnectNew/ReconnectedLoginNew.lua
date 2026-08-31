local luaclass              = require("luaclass")
local ReconnectedLogin      = luaclass("ReconnectedLogin")
local GlobalVariableSystem  = require("GlobalVariableSystem_C")
local CppDelegate           = require("CppDelegate")
local ClientEventDef        = require("ClientEventDef")
-- local ProcedureTool         = require("ProcedureTool")
local NetworkManager        = dynamic_require("NetworkManager")
local DisconnectType        = require("DisconnectTypeNew")
local Proto                 = require("ClientProtoNames")
local EventManager          = require("EventManager")
local UILogin               = require("UILogin")
local ChannelSDKSystem      = require("ChannelSDKSystem")
local LoginResponseHelper   = require("LoginResponseHelper")
local UITextDef             = require("UITextDef")
local UIUtils               = require("UIUtils")
local ProcedureTool         = require("ProcedureTool")
local LoginRequestHelper    = require("LoginRequestHelper")

ReconnectedLogin.HydraClient = nil
ReconnectedLogin.OnHydraResponseDelegate = nil
ReconnectedLogin.HydraResponse = nil
ReconnectedLogin.SelfEventHelper = nil
ReconnectedLogin.tbParam         = nil

local LOGIN_WITH_ACCOUNT      = 0
-- local LOGIN_WITH_DEVICE_ID    = 1
-- local TOKEN_MAX_TIME = 5 * 60 --5分钟
local RESPONSE_ANTIADDICTION = "AntiAddiction"
local RESPONSE_USERBANNED = "UserBanned"

local function OnSdkLoginFail(self)
    self:HydraResponesFailed()
	log("ReconnectedLoginNew:OnSdkLoginFail()")
end

local function OnSdkLoginSuccess(self, szJsonData)
	log("reconnedLoginNew OnSdkLoginSuccess ", szJsonData)
	LoginRequestHelper:OnSdkLoginSuccess(self.HydraClient, szJsonData)
end

local function BindSdkMethod(self)
	local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
	self.OnSdkLoginFailDelegate = CppDelegate:BindMethod(pChannelSdkManager.OnSdkLoginFail, self, OnSdkLoginFail)
	self.OnSdkLoginSuccessDelegate = CppDelegate:BindMethod(pChannelSdkManager.OnSdkLogin, self, OnSdkLoginSuccess)
end

local function UnbindSdkMethod(self)
	if self.OnSdkLoginSuccessDelegate then
		self.OnSdkLoginSuccessDelegate:Unbind()
		self.OnSdkLoginSuccessDelegate = nil
	end    
	if self.OnSdkLoginFailDelegate then
		self.OnSdkLoginFailDelegate:Unbind()
		self.OnSdkLoginFailDelegate = nil
	end
end

function ReconnectedLogin:Init(tbParam)
    self.tbParam = tbParam

    self:CreateHydraClient()
    BindSdkMethod(self)
end

function ReconnectedLogin:Uninit()
    UnbindSdkMethod(self)
    self:DestroyHydraClient()
end

function ReconnectedLogin:CheckTokenOutDate()
    if not GlobalVariableSystem.szToken then
        return true
    end

    return GlobalVariableSystem:GetLocalTime() - GlobalVariableSystem.nTokenTime >= GlobalVariableSystem.nTokenMaxTime
end

function ReconnectedLogin:Reconnect()
    if self:CheckTokenOutDate() then
        log("token is out date")
        self:OnUILogin()
    else
        log("token is not out date")
        local szHubServerUrl = GlobalVariableSystem:GetLobbyServerAddress()
        self:ConnectToHubServer(szHubServerUrl)
    end
end

function ReconnectedLogin:LoginWithAccount(szUsername, szPassword)
    log("ReLogin with account:", szUsername, self.HydraClient.ServerURL)
    LoginRequestHelper:LoginWithAccount(self.HydraClient, szUsername, szPassword)
end

function ReconnectedLogin:LoginWithDeviceId()
	local szDeviceId = KismetSystemLibrary.GetDeviceId()
    log("reconnectLogin with device id: " ..szDeviceId)
    LoginRequestHelper:LoginWithDeviceId(self.HydraClient, szDeviceId)
end

function ReconnectedLogin:OnUILogin()--tbServerData, nLoginMode, szUsername, szPassword)
    local tbServerData = GlobalVariableSystem.tbCurrentServerData
    local nLoginMode   = GlobalVariableSystem.nLoginMode
    local szUsername   = GlobalVariableSystem.szUserName
    local szPassword   = GlobalVariableSystem.szUserPassword

    local szHydraServerUrl = tbServerData.hydra
    self.HydraClient.ServerURL = szHydraServerUrl
    if nLoginMode == LOGIN_WITH_ACCOUNT then
        self:LoginWithAccount(szUsername, szPassword)
    elseif nLoginMode == UILogin.LOGIN_WITH_THIRD_PARTY_ACCOUNT then
        local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
        if pChannelSdkManager:IsLoginSdkSuccessful() then
            pChannelSdkManager:Login()
            GamePlatformMiscLibrary.LogDebug("login by third party sdk")
            log("login by third party sdk")
        else
            log("pChannelSdkManager:LoginSdkAndGame()")
            GamePlatformMiscLibrary.LogDebug("pChannelSdkManager:LoginSdkAndGame()")
            LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.SDK_LOGIN_FAILED)
            pChannelSdkManager:LoginSdkAndGame()
        end
    else
        self:LoginWithDeviceId()
    end
end

function ReconnectedLogin:SendLoginToHubServer()
    log("ReconnectedLogin:SendLoginToHubServer")
    if not GlobalVariableSystem.szToken then
        self:Callback()
        return
    end

    local Socket = NetworkManager:GetHubServerProxy()
    local ePlatform = ChannelSDKSystem:GetProtoPlatformEnum()
    local szChannelID = ChannelSDKSystem:GetChannelID()
    --logdebug("szChannelID = " .. szChannelID)
    local c2s_Login =
    {
        token = GlobalVariableSystem.szToken,
        -- reconnecting = true
        platform = ePlatform,
        channel = szChannelID,
        res_version = GlobalVariableSystem:GetResVersion()
    }
    GlobalVariableSystem:OnSendLoginRequest()
    if(not Socket:SendPacket(Proto.c2s_Login, c2s_Login)) then
        self:Callback()
    end
end

function ReconnectedLogin:ConnectToHubServer(szParam)
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    if not HubServerProxy:Connect(szParam) then
        log("ReconnectedLogin:ConnectToHubServer no connect")
        self:Callback()
    end
end

function ReconnectedLogin:HydraResponesFailed()
    local tbParam = self.tbParam
    if not tbParam then
        logerror("reconnect login not call back")
        return
    end
    local Func = function()
        tbParam.fnConnectedHydraFailed(tbParam.tbHandle)
    end

    Func()
end

function ReconnectedLogin:Callback()
    local tbParam = self.tbParam
    if not tbParam then
        logerror("reconnect login not call back")
        return
    end
    local Func = function()
        tbParam.fnConnectedHubFailed(tbParam.tbHandle)
    end

    Func()
end

--以后会根据时间判断token是否过期，是否重新获取token.
--目前只要断线，就会重新获取token
function ReconnectedLogin:OnHydraResponse(bSuccessed, HydraResponse)
    log("--------ReconnectLogin Resp:", bSuccessed, HydraResponse, HydraResponse.code, HydraResponse.data.hydra_id, HydraResponse.data.token, HydraResponse.data.expires_in)
    self.HydraResponse = HydraResponse
    if not bSuccessed then
        self:HydraResponesFailed()
    else
        if HydraResponse.code == 200 then
            --log event onAccountLogin
            EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_ACCOUNT_LOGIN)
            GlobalVariableSystem:SetToken(HydraResponse.data.token, GlobalVariableSystem:GetLocalTime(), HydraResponse.data.expires_in)
            local szHubServerUrl = GlobalVariableSystem:GetLobbyServerAddress()
            self:ConnectToHubServer(szHubServerUrl)
		elseif HydraResponse.code == 403 then
            local errorMsg = "ReLogin failed 403 : " .. HydraResponse.error.type .. " " .. HydraResponse.error.message
            logwarning(errorMsg)
			if HydraResponse.error.type == RESPONSE_ANTIADDICTION then
				if not LoginResponseHelper:Relogin(HydraResponse.error.code, HydraResponse.error.message) then
					logerror("re login failed: Antiaddiction code is blank ", HydraResponse.error.code)
				end
			elseif HydraResponse.error.type == RESPONSE_USERBANNED then
                local l10nText = UITextDef.USER_BANNED_INGAME
                UIUtils.ShowDisconnectDialog(l10nText, UITextDef.L10N_OK, function()
                    ProcedureTool:ReturnToStartGame()
                end, DisconnectType.disconnected)
			end
            -- if self.tbParam.tbHandle and self.tbParam.tbHandle.CloseReconnectingDialog then
            --     self.tbParam.tbHandle:CloseReconnectingDialog(true)
            -- end
        else
            self:Callback()
        end
    end
end

function ReconnectedLogin:CreateHydraClient()
    local HydraClient = ClientShell.GetClient(GWorld):GetHydraClient()
    self.HydraClient = HydraClient
    self.HydraResponse = nil
    self.OnHydraResponseDelegate = CppDelegate:BindMethod(HydraClient.OnHydraResponse, self, self.OnHydraResponse)
end

function ReconnectedLogin:DestroyHydraClient()
    self.OnHydraResponseDelegate:Unbind()
    self.HydraResponse = nil
    self.HydraClient = nil
end

return ReconnectedLogin