local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_Login = luaclass("Procedure_Login", ProcedureBase)

-- local L10N = require("L10N")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local UIUtils = require("UIUtils")
local CppDelegate = require("CppDelegate")

local ClientEventDef = require("ClientEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local Proto = require("ClientProtoNames")
local SoundManager = require("SoundManager")
local UILogin = require("UILogin")
local ProcedureTool = require("ProcedureTool")
local UITextDef = require("UITextDef")
local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local GameWorldSystem = require("GameWorldSystem")
local ResourceCacheSystem = require("ResourceCacheSystem")
local EventManager = require("EventManager")
-- local MatineeSystem = dynamic_require("MatineeSystem")
local DelayTimer = require("DelayTimer")
-- local SaveGameDef = require("SaveGameDef")
local SceneDataTable = require("SceneDataTable")
local ResourceManager = require("ResourceManager")
local UIStateDef = require("UIStateDef")
-- local GameObjectSystem = require("GameObjectSystem_C")
-- local GameObjectTypeDef = require("GameObjectTypeDef")
local UISetUtils = require("UISetUtils")
-- local TemplateTypeDef = require("TemplateTypeDef")
local ServerConfigHelper = require("ServerConfigHelper")
local ServerListHelper = require("ServerListHelper")
local L10N = require("L10N")
local ChannelSDKSystem = require("ChannelSDKSystem")
local LoginResponseHelper = require("LoginResponseHelper")
local LoginRequestHelper = require("LoginRequestHelper")
--local TutorialDungeonIni = require("TutorialDungeonIni")
local TransformEventDef = require("TransformEventDef")

local REQUEST_MASK_MIN_TIME = 1
local LOBBY_SUBLEVEL = '/Game/Resources/FFA/Maps/Select/Map_FFA_Lobby'
local LOBBY_SUBLEVEL_NEW = "/Game/Resources/FFA/Maps/Outside/Map_Outside_UIhall/Map_Outside_UIhall"
local CREATE_ROLE_SUBLEVEL = "/Game/Resources/FFA/Maps/Select/Map_FFA_RoleCreation"
local CREATE_ROLE_SUBLEVEL_NEW = "/Game/Resources/FFA/Maps/Outside/Map_RoleCreation/Map_RoleCreation"

-- local CREATE_ROLE_LOOP_FEMALE_MATINEE_ID = 11
-- local CREATE_ROLE_LOOP_MALE_MATINEE_ID = 8

Procedure_Login.HydraClient = nil
Procedure_Login.OnHydraResponseDelegate = nil
--Procedure_Login.OnMatchIsWaitingToStartDelegate = nil
Procedure_Login.HydraResponse = nil
Procedure_Login.SelfEventHelper = nil
-- Procedure_Login.SoundIsPlayed = false
Procedure_Login.OnSdkLoginFailDelegate = nil
Procedure_Login.OnSdkLoginSuccessDelegate = nil

Procedure_Login.bSendLogin = false
Procedure_Login.tbDelayTimer = nil
Procedure_Login.tbSdkDelayTimer = nil
-- Procedure_Login.tbLoadingTimer = nil
Procedure_Login.bServerInfoObtained = nil
Procedure_Login.bMapLoaded = nil
Procedure_Login.tbRequestMaskTimer = nil
Procedure_Login.bSubLevelLoaded = nil
Procedure_Login.bLobbySubLevelLoaded = nil
Procedure_Login.bCreateRoleSubLevelLoaded = nil
Procedure_Login.szLobbySublevel = nil
Procedure_Login.szCreateRoleSublevel = nil
Procedure_Login.tbSublevelLoadedFlag = nil
Procedure_Login.tbLoadSublevelDelegate = nil

local bAutoLogin = true

local AutoLogin = function(self)
	bAutoLogin = false
	local OnLoginSceneReady = nil
	OnLoginSceneReady = function()
		log("AutoLogin OnLoginSceneReady............... ")
		EventManager:UnBindEvent(ClientEventDef.EV_POST_LOAD_MAP, OnLoginSceneReady)
		-- self:OnUILogin(GlobalVariableSystem.tbCurrentServerData, UILogin.LOGIN_WITH_ACCOUNT, szUsername, szPassword)
		self:OnUILogin(GlobalVariableSystem.tbCurrentServerData, UILogin.LOGIN_WITH_DEVICE_ID)
	end
	EventManager:BindEvent(ClientEventDef.EV_POST_LOAD_MAP, OnLoginSceneReady)
end

local function ClearTimer(self)
	DelayTimer:ClearTimer(self.DelayTimer)
	self.DelayTimer = nil
end

-- local function ClearLoadingTimer(self)
-- 	if self.tbLoadingTimer ~= nil then
-- 		DelayTimer:ClearTimer(self.tbLoadingTimer)
-- 		self.tbLoadingTimer = nil
-- 		UIUtils.HideLoadingDialog()
-- 	end
-- end

local function ClearRequestMaskTimer(self)
	if self.tbRequestMaskTimer then
		DelayTimer:ClearTimer(self.tbRequestMaskTimer)
		self.tbRequestMaskTimer = nil
	end
end

local function TryCloseRequestInfoMask(self)
	local bAllSublevelLoaded = true
	for k, v in pairs(self.tbSublevelLoadedFlag) do
		if not v then
			bAllSublevelLoaded = false
			break
		end
	end
	if bAllSublevelLoaded and self.bServerInfoObtained and not self.tbRequestMaskTimer then
		UIManager:CloseWnd(UIDef.UI_LOGIN_REQUEST_INFO_MASK)
	end
end

local function ClearSublevelLoadDelegate(self)
	if self.tbLoadSublevelDelegate then
		for k, v in pairs(self.tbLoadSublevelDelegate) do
			self.SelfEventHelper:UnregisterCppDelegate(v)
		end
	end
	self.tbLoadSublevelDelegate = {}
end

-- local function CheckPerformanceLevel(self)
--     local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
--     local bIsChecked = pSaveGameMgr:GetBoolData(SaveGameDef.DEVICE_PERFORMANCE_LEVEL_CHECKED)
--     if bIsChecked == false then
--         local nPerformanceLevel = RenderExtendBlueprintFunctions.GetDevicePerformanceLevel()
-- 		if(nPerformanceLevel >= 0 and nPerformanceLevel <= 2) then
-- 			log("Device performance level = ",nPerformanceLevel)
-- 			local szLevelDec = UITextDef.PERFORMANCE_LEVEL_DESC[nPerformanceLevel]
-- 			UIDialogHelper:ShowOKMessageDialog("", szLevelDec, "", UITextDef.L10N_OK, function() UIDialogHelper:CloseDialog(UIDef.UI_DIALOG_MESSAGE) end, true )
-- 			pSaveGameMgr:AddBoolData(SaveGameDef.DEVICE_PERFORMANCE_LEVEL_CHECKED, true)
-- 			pSaveGameMgr:Save()
-- 		else
-- 			logwarning("Invalid device performance level nPerformanceLevel =", nPerformanceLevel)
-- 		end
--     end
-- end

------------------------------------------------------------------------------------
-- HubServer 相关
function Procedure_Login:SendLoginToHubServer()
	if not self.HydraResponse then
		LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.HUB_LOGIN_ERROR)
		log("Procedure_Login HydraResponse is Nil")
		return
	end

	local Socket = NetworkManager:GetHubServerProxy()
	local ePlatform = ChannelSDKSystem:GetProtoPlatformEnum()
	local szChannelID = ChannelSDKSystem:GetChannelID()
	--logdebug("szChannelID = " .. szChannelID)
	local c2s_Login =
	{
		token = self.HydraResponse.data.token,
		reconnecting = false,
		platform = ePlatform,
		channel = szChannelID,
		res_version = GlobalVariableSystem:GetResVersion()
	}
	GlobalVariableSystem:OnSendLoginRequest()
	if(not Socket:SendPacket(Proto.c2s_Login, c2s_Login)) then
		--UIUtils.ShowToast("Send login packet failed.")
		LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.HUB_LOGIN_ERROR)
		logwarning("Send login packet failed.")
	-- else
	-- 	self.tbLoadingTimer = DelayTimer:DelayRun(function()
	-- 		ClearLoadingTimer(self)
	-- 	end, 2)
	end
end

function Procedure_Login:OnHubLoginReply(nReturnCode)
	if(nReturnCode == 0) then
		-- self:HideUI()
		-- TODO:弹出loading ui
		log("login successed: ")
	else
		logwarning("Login failed, errorcode: ", nReturnCode)
	end
end

function Procedure_Login:ConnectToHubServer(szParam)
	log("ConnectToHubServer start " .. szParam)
	local HubServerProxy = NetworkManager:GetHubServerProxy()
	if HubServerProxy ~= nil and HubServerProxy:IsConnect() then
		log("ConnectToHubServer start but is connected")
		return
	end
	HubServerProxy:Connect(szParam)
end

function Procedure_Login:OnHubConnectResult(bResult)
	if(bResult) then
		self.SelfEventHelper:UnregisterAll()
		self:UnbindSdkMethod()
		log("Connect to hub server successed.")
		self:SendLoginToHubServer()
		EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_LOADING_TRANSFORM, TransformEventDef.TARGET_EVENT_NAME.CONNECT_SERVER)
	else
		LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.HUB_LOGIN_ERROR)
		local l10nMessage = UISetUtils.GetL10NTextByKey("HUB_SERVER_CONNECT_FAILED")
		UIUtils.ShowToast(l10nMessage)
		log("Connect to hub server failed, Result: ", bResult)
	end
end

function Procedure_Login:BindHubMethod()
	self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_POST_LOAD_MAP, self, self.OnPostMapLoad)
	-- self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_HUB_LOGIN_REPLY, self, self.OnHubLoginReply)
	self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_CONNECTED	, self, self.OnHubConnectResult)
	self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_UI_LOGIN	, self, self.OnUILogin)
	self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_ON_LOGIN_ERROR, self, self.OnLoginError)
end

function Procedure_Login:UnbindHubMethod()
	self.SelfEventHelper:UnregisterAll()
	self.tbLoadSublevelDelegate = nil
end

------------------------------------------------------------------------------------
-- Hydra 相关
function Procedure_Login:LoginWithAccount(szUsername, szPassword)
	log("Login with account:", szUsername, szPassword)
	LoginRequestHelper:LoginWithAccount(self.HydraClient, szUsername, szPassword)
end

function Procedure_Login:LoginWithDeviceId()
	-- local pClientShell = ClientShell.GetClient(GWorld)
    -- local pSaveGameMgr = pClientShell:GetSaveGameManager()
    -- local szDeviceId = pSaveGameMgr:GetStringData(SaveGameDef.DEVICEID)
	-- if szDeviceId == nil or szDeviceId == "" then
	-- 	local pGuid = KismetGuidLibrary:NewGuid()
	-- 	szDeviceId = pClientShell:GuidToString(pGuid)
	-- 	log("===== the device id is: " ..szDeviceId)
	-- 	pSaveGameMgr:AddStringData(SaveGameDef.DEVICEID, szDeviceId)
	-- 	pSaveGameMgr:Save()
	-- end
	local szDeviceId = KismetSystemLibrary.GetDeviceId()
	log("Login with device id: " ..szDeviceId)
	LoginRequestHelper:LoginWithDeviceId(self.HydraClient, szDeviceId)
end

function Procedure_Login:OnHydraResponse(bSuccessed, HydraResponse, szHydraResponseBody)
	-- UIUtils.HideLoadingDialog()
	log("--------Login Resp:", bSuccessed, HydraResponse, HydraResponse.code, HydraResponse.data.hydra_id, HydraResponse.data.token, HydraResponse.data.expires_in)
	log("--------Login RespBody:", szHydraResponseBody)
	self.HydraResponse = HydraResponse
	local szlog = "OnHydraResponse Login Resp bSuccessed = " .. tostring(bSuccessed) .. " responseCode = " .. tostring(HydraResponse.code) .. "dydra_id = " .. tostring(HydraResponse.data.hydra_id)
	GamePlatformMiscLibrary.LogDebug(szlog)
	if not bSuccessed then
		logerror("Failed to get response from login server.")
		GamePlatformMiscLibrary.LogDebug("Failed to get response from login server.")
		LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.HYDRA_LOGIN_NOSUCCESS)
		UIUtils.ShowToastWithKey("FAILED_TO_GET_RESPONSE_FROM_LOGIN_SERVER")
	else
		if HydraResponse.code == 200 then
			--log event onAccountLogin
			EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_ACCOUNT_LOGIN, HydraResponse.data.hydra_id)
			if LoginResponseHelper:SuccessProcess(HydraResponse) then
				local szHubServerUrl = GlobalVariableSystem:GetLobbyServerAddress()

				self:ConnectToHubServer(szHubServerUrl)
			end
		else
			local bProcess, szMessage = LoginResponseHelper:FailedProcess(HydraResponse, szHydraResponseBody)
			if not bProcess then
				UIUtils.ShowToast(szMessage)
			end
		end
	end
end

function Procedure_Login:CreateHydraClient()
	local HydraClient = ClientShell.GetClient(GWorld):GetHydraClient()
	self.HydraClient = HydraClient
	self.HydraResponse = nil
	self.OnHydraResponseDelegate = CppDelegate:BindMethod(HydraClient.OnHydraResponse, self, self.OnHydraResponse)
end

function Procedure_Login:DestroyHydraClient()
	if self.OnHydraResponseDelegate then
		self.OnHydraResponseDelegate:Unbind()
		self.HydraClient = nil
		self.OnHydraResponseDelegate = nil
	end
end

-- function Procedure_Login:BindLevelEvent()
--     local OnMatchIsWaitingToStart = ClientShell.GetClient(GWorld):GetGameDelegateManager().GameMode.OnMatchIsWaitingToStart
--     local ProcessOnMatchIsWaitingToStart = function(szPath)
--         self:ShowUI()
--     end
--     self.OnMatchIsWaitingToStartDelegate = CppDelegate:Bind(OnMatchIsWaitingToStart, ProcessOnMatchIsWaitingToStart)
-- end
-- function Procedure_Login:UnbindLevelEvent()
--     local OnMatchIsWaitingToStartDelegate = self.OnMatchIsWaitingToStartDelegate
--     if (OnMatchIsWaitingToStartDelegate) then
--         OnMatchIsWaitingToStartDelegate:Unbind()
--     end
-- end
-------------------------------------------------------------------------------------------

---------------Sdk相关-------------------------------------------------------------------------

function Procedure_Login:OnSdkLoginFail()
	LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.SDK_LOGIN_FAILED)
	log("Procedure_Login:OnSdkLoginFail()")
end

function Procedure_Login:OnSdkLoginSuccess(szJsonData)
	log("Procedure_Login:OnSdkLoginSuccess ", szJsonData)
	LoginRequestHelper:OnSdkLoginSuccess(self.HydraClient, szJsonData)
end

function Procedure_Login:BindSdkMethod()
	local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
	self.OnSdkLoginFailDelegate = CppDelegate:BindMethod(pChannelSdkManager.OnSdkLoginFail, self, self.OnSdkLoginFail)
	self.OnSdkLoginSuccessDelegate = CppDelegate:BindMethod(pChannelSdkManager.OnSdkLogin, self, self.OnSdkLoginSuccess)
end

function Procedure_Login:UnbindSdkMethod()
	if self.OnSdkLoginSuccessDelegate then
		self.OnSdkLoginSuccessDelegate:Unbind()
		self.OnSdkLoginSuccessDelegate = nil
	end
	if self.OnSdkLoginFailDelegate then
		self.OnSdkLoginFailDelegate:Unbind()
		self.OnSdkLoginFailDelegate = nil
	end
end

local function ClearSdkTimer(self)
	DelayTimer:ClearTimer(self.tbSdkDelayTimer)
	self.tbSdkDelayTimer = nil
end

-------------------------------------------------------------------------------------------

----------------请求服务器信息---------------------------------------------------------------------------

--serve list
local function GetServerListComplete(self)
	self.bServerInfoObtained = true
	log("Procedure_Login:GetServerListComplete")
	TryCloseRequestInfoMask(self)
	EventManager:OnFireEvent(ClientEventDef.EV_LOGIN_SERVER_INFO_COMPLETED)
end

local function RequestServerList(self)
	ServerListHelper.RequestServerList(function() GetServerListComplete(self) end)
end

--server config
local function GetConfigComplete(self)
	RequestServerList(self)
end

local function RequestConfigFile(self)
	ServerConfigHelper.RequestConfig(function() GetConfigComplete(self) end)
end

function Procedure_Login:RequestSeverInfo()
	UIManager:PushState(UIStateDef.StateName.UI_LOGIN_STATE, nil, true)
	RequestConfigFile(self)
end

-----------------------提前load创建和大厅的sublevel-------------------------------
local function ClearResourceAsyncHandle(self)
	if self.tbResourceAsyncHandle then
		for k, v in pairs(self.tbResourceAsyncHandle) do
			ResourceManager:CancelLoadAsync(v)
		end
	end
	self.tbResourceAsyncHandle = {}
end

local function LoadSublevel(self, szSublevel)
	local pDelegate = self.tbLoadSublevelDelegate[szSublevel]
	if pDelegate then
		return
	end
	
	local pSublevel = ClientShell.GetClient(GWorld):GetStreamingLevel(GWorld, szSublevel)
	self.tbSublevelLoadedFlag[szSublevel] = pSublevel.LoadedLevel ~= nil and true or false
	log("Procedure_Login:LoadSublevel",szSublevel,self.tbSublevelLoadedFlag[szSublevel],pSublevel.LoadedLevel)
	if self.tbSublevelLoadedFlag[szSublevel] then
		pSublevel:SetShouldBeVisible(false)
	else
		local nHandle = ResourceManager:LoadAsync(szSublevel, function(szTempAssetName, pObject, nInHandle)
			pSublevel:SetShouldBeVisible(false)
			pSublevel:SetShouldBeLoaded(true)
			self.tbLoadSublevelDelegate[szSublevel] = self.SelfEventHelper:RegisterCppDelegate(
				pSublevel.OnLevelLoaded, self, function()
				self.SelfEventHelper:UnregisterCppDelegate(pDelegate)
				self.tbLoadSublevelDelegate[szSublevel] = nil
				self.tbSublevelLoadedFlag[szSublevel] = true
				log("Procedure_Login:LoadSublevel complete")
				TryCloseRequestInfoMask(self)
			end)
		end)
		if nHandle > -1 then
			self.tbResourceAsyncHandle[szSublevel] = nHandle
		end
	end
end

----------------------------------------------------------------------------

function Procedure_Login:Init()
	log("Procedure_Login:Init")
	Procedure_Login.super.Init(self)
	EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_LOADING_TRANSFORM, TransformEventDef.TARGET_EVENT_NAME.APP_START)
	self.SelfEventHelper = require("SelfEventHelper")()
	self.tbResourceAsyncHandle = {}
end

function Procedure_Login:Begin()
	Procedure_Login.super.Begin(self)
	EventManager:OnFireEvent(ClientEventDef.EV_ENTER_PROCEDURE_LOGIN)

	ExtendBlueprintFunctions.ReloadLocalizationResources()
	log("ReloadLocalizationResources")
	ClientShell.GetClient(GWorld):SetGameStatus(EPiratesGameStatus.LOGIN)
	-- KismetRenderingLibrary.SetScreenPercentage(100)
	ManagerRoot:InitGroup(ManagerGroupDef.nLoginGroupID, true)
	GamePlatformMiscLibrary.HoldBackgroud()
	self.bSendLogin = false
	self.bServerInfoObtained = false
	self.bMapLoaded = false
	self.tbRequestMaskTimer = nil
	self.tbSublevelLoadedFlag = {}
	--把原来Procedure_Config和Procedure_ServerList的处理放到这里，从Procedure_StartGame直接进入
	--Procedure_Login，获取服务器信息的同时加载登陆场景，等服务器信息都下来后才显示服务器列表信息
	self:RequestSeverInfo()
	-------------------------
	self:CreateHydraClient()
	--self:BindLevelEvent()
	self:BindHubMethod()
	self:BindSdkMethod()
	if bAutoLogin and GlobalVariableSystem.tbCurrentServerData ~= nil then
		AutoLogin(self)
	else
		local OnLoginSceneReady = nil
		OnLoginSceneReady = function()
			EventManager:UnBindEvent(ClientEventDef.EV_POST_LOAD_MAP, OnLoginSceneReady)
			--local pClientShell = ClientShell.GetClient(GWorld)
			--pClientShell:ToggleSceneRendering(true)
			LowEntryExtendedStandardLibrary.SetWorldRenderingEnabled(true)
		end
		EventManager:BindEvent(ClientEventDef.EV_POST_LOAD_MAP, OnLoginSceneReady)
	end
	bAutoLogin = false
	self.szLobbySublevel = LOBBY_SUBLEVEL
	self.szCreateRoleSublevel = CREATE_ROLE_SUBLEVEL
	if GlobalVariableSystem.bEnterLobby3D then
		self.szLobbySublevel = LOBBY_SUBLEVEL_NEW
		self.szCreateRoleSublevel = CREATE_ROLE_SUBLEVEL_NEW
	end
	self:OpenLoginMap()
	--self:OpenSubLevel()
end

function Procedure_Login:End()
	--self:UnbindLevelEvent()
	-- self.SoundIsPlayed = false
	-- local pLobbyMainStreamingLevel = ClientShell.GetClient(GWorld):GetStreamingLevel(GWorld, self.szLobbySublevel)
	-- if isvalidhandle(pLobbyMainStreamingLevel) then
	-- 	pLobbyMainStreamingLevel:SetShouldBeVisible(false)
	-- end
	ClearResourceAsyncHandle(self)
	self:HideUI()
	self:UnbindHubMethod()
	self:UnbindSdkMethod()
	self:DestroyHydraClient()
	-- MatineeSystem:Clear()
	SoundManager:StopBackgroundMusic()
	-- self.LoginMatinee:StopMatinee()
	ManagerRoot:UninitGroup(ManagerGroupDef.nLoginGroupID)
	ClientShell.GetClient(GWorld):SetGameStatus(EPiratesGameStatus.NONE)
	Procedure_Login.super.End(self)
end

function Procedure_Login:Uninit()
	ClearTimer(self)
	ClearSdkTimer(self)
	ClearResourceAsyncHandle(self)
	-- ClearLoadingTimer(self)
	ClearRequestMaskTimer(self)
	self:UnbindHubMethod()
	self:UnbindSdkMethod()
	self:DestroyHydraClient()
	Procedure_Login.super.Uninit(self)
end

function Procedure_Login:OpenLoginMap()
	local nCurrentSceneId = GlobalVariableSystem.LOGIN_MAP_ID
	if GlobalVariableSystem.bEnterLobby3D then
		nCurrentSceneId = 70003
	end
	local tbCreateData =
	{
		bLoadNewMap = true,
		--szMapName = LOGIN_MAP_NAME,
		nSceneId = nCurrentSceneId,
		bLoadAsync = false,
	}
	GameWorldSystem:CreateWorld(tbCreateData)
end

function Procedure_Login:OpenSubLevel()
	log("Procedure_Login:OpenSubLevel")
	ClearSublevelLoadDelegate(self)
	self.tbSublevelLoadedFlag = {}
	LoadSublevel(self, self.szLobbySublevel)
	LoadSublevel(self, self.szCreateRoleSublevel)

end

function Procedure_Login:ShowUI()
	-- local tbLoginMatinee = MatineeSystem:GetMatinee(CREATE_ROLE_LOOP_FEMALE_MATINEE_ID)
	-- if tbLoginMatinee then
	-- 	tbLoginMatinee:StopMatinee()
	-- end

	-- tbLoginMatinee = MatineeSystem:GetMatinee(CREATE_ROLE_LOOP_MALE_MATINEE_ID)
	-- if tbLoginMatinee then
	-- 	tbLoginMatinee:StopMatinee()
	-- end
	-- MatineeSystem:Clear()

	local ShowLogin = function()
		-- close splash ui
		local GameInstance = GameplayStatics.GetGameInstance(GWorld)
		if GameInstance and GameInstance.SplashUI then
			GameInstance.SplashUI:RemoveFromParent()
			GameInstance.SplashUI = nil
		end
		-- BGMHelper:PlayWildWorldBGM(LOGIN_MAP_ID)
		local nBGMId = SceneDataTable:GetTemplate(GlobalVariableSystem.LOGIN_MAP_ID).nBGMId
		local CurrentBackgroundMusic = SoundManager.CurrentBackgroundMusic
		if not CurrentBackgroundMusic or CurrentBackgroundMusic.nID ~= nBGMId then
			SoundManager:PlayBackgroundMusic(nBGMId)
		end
		-- CheckPerformanceLevel(self)
		--UIManager:PushState(UIStateDef.StateName.UI_LOGIN_STATE, nil, true)
		ClearRequestMaskTimer(self)
		self.tbRequestMaskTimer = DelayTimer:DelayRun( function()
			self.tbRequestMaskTimer = nil
			log("Procedure_Login:RequestMaskTimer time up")
			TryCloseRequestInfoMask(self)
		end, REQUEST_MASK_MIN_TIME)
		UIManager:OpenWnd(UIDef.UI_LOGIN_REQUEST_INFO_MASK)
		UIManager:OpenWnd(UIDef.UI_LOGIN)
		
		self.tbSdkDelayTimer = DelayTimer:DelayRun( function()
			ClearSdkTimer(self)
			log("pChannelSdkManager:LoginSdk()")
			local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
			pChannelSdkManager:LoginSdk()
		end, 0.5)

		EventManager:OnFireEvent(ClientEventDef.EV_SHOW_LOGIN)
	end

	-- MatineeSystem:PlayMatinee(GlobalVariableSystem.LOGIN_MATINEE_ID, true)
	-- 关闭update ui
	local GameInstance = GameplayStatics.GetGameInstance(GWorld)
	local bShow = false
	if(GameInstance) then
		ResourceManager:GC()
		local UpdateUI = GameInstance.UpdateUI
		if(UpdateUI) then
			UpdateUI:SetMockProgressInfo(100)
			bShow = true
			self.DelayTimer = DelayTimer:DelayRun(function()
				ClearTimer(self)

				log("Procedure_Login remove update ui")
				UpdateUI:RemoveFromParent()
				GameInstance.UpdateUI = nil
				ShowLogin()
			end, 1)
		end
	end
	-- 关闭loading
	UIManager:CloseWnd(UIDef.UI_LOADING)

	if not bShow then
		ShowLogin()
	end


	local PC = GameplayStatics.GetPlayerController(GWorld, 0)
	PC.bShowMouseCursor = true

	ResourceCacheSystem:OnEnterLogin()
end

function Procedure_Login:HideUI()
	--UIManager:CloseWnd(UIDef.UI_LOGIN)
	local Wnd = UIManager:GetWnd(UIDef.UI_LOGIN)
	if Wnd then
        Wnd:PlayExitAnim()
	end
end

local function CheckLoginNameIllegal(szUserName)
	-- luacheck: push ignore 542
	local nNameLen = string.len(szUserName)
	for i = 1, nNameLen do
		local curByte = string.byte(szUserName, i)
		if curByte >= 65 and curByte <= 90 then  -- A -- Z
		elseif curByte >= 97 and curByte <= 122 then  -- a -- z
		elseif curByte >= 48 and curByte <= 57 then  -- 0 -- 9
		else
			return true
		end
	end
	-- luacheck: pop
	return false
end

function Procedure_Login:OnUILogin(tbServerData, nLoginMode, szUsername, szPassword)
	log("[UI] Procedure_Login OnUILogin nLoginMode = " .. tostring(nLoginMode))
	GamePlatformMiscLibrary.LogDebug("[UI] Procedure_Login OnUILogin nLoginMode = " .. tostring(nLoginMode))
	-- if self.bSendLogin then
	--     return
	-- end
	if nLoginMode == UILogin.LOGIN_WITH_ACCOUNT then
		local nUserNameLen = string.len(szUsername)
		if nUserNameLen == 0 then
			UIUtils.ShowToast(UITextDef.ACCOUNT_EMPTY)
			return
		elseif nUserNameLen < 3 or nUserNameLen > 20 then
			UIUtils.ShowToast(UITextDef.ACCOUNT_LEN_ERROR)
			return
		elseif CheckLoginNameIllegal(szUsername) then
			UIUtils.ShowToast(UITextDef.ACCOUNT_ILLEGAL)
			return
		end
		if string.len(szPassword) == 0 then
			UIUtils.ShowToast(UITextDef.PASSWQRLD_EMPTY)
			return
		end
	end

	local szHydraServerUrl = tbServerData.hydra
	GamePlatformMiscLibrary.LogDebug("[UI] Procedure_Login OnUILogin szHydraServerUrl = " .. tostring(szHydraServerUrl))
	if szHydraServerUrl == nil or szHydraServerUrl == "" then
		log("Hydra url is empty, use mock mode.")
		local szHubServerUrl = tbServerData.hub
		GamePlatformMiscLibrary.LogDebug("Hydra url is empty, use mock mode. szHubServerUrl = " .. tostring(szHubServerUrl))
		if(szHubServerUrl == nil or szHubServerUrl == "") then
			local tbDungeonServerData = tbServerData.dungeon
			if(tbDungeonServerData ~= nil) then
				ProcedureTool:EnterMock({
					szServerAddr = tbDungeonServerData.url,
					nDungeonId = tbDungeonServerData.dungeon_id,
					szPlayerName = szUsername
				}, true)
			else
				logerror("Cannot find dungeon server data.")
				GamePlatformMiscLibrary.LogDebug("Cannot find dungeon server data.")
			end
		else
			log("Mock loginsuccessful.");
			GamePlatformMiscLibrary.LogDebug("Mock loginsuccessful.")
			self.HydraClient:MockLoginSuccessful()  -- offline mode, don't need login.'
		end
	else
		GamePlatformMiscLibrary.LogDebug("Hydra is not empty!")
		--UIUtils.ShowLoadingDialogWithKey("LOGINING_WAIT")
		UIUtils.ShowLoadingDialog(L10N.NullString)
		self.HydraClient.ServerURL = szHydraServerUrl
		if nLoginMode == UILogin.LOGIN_WITH_ACCOUNT then
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
			GamePlatformMiscLibrary.LogDebug("LoginWithDeviceId")
			self:LoginWithDeviceId()
		end
	end
	self.bSendLogin = true
end

function Procedure_Login:OnLoginError()
	self.bSendLogin = false
end

function Procedure_Login:OnPostMapLoad()
	self.bMapLoaded = true
	self:ShowUI()
	self:OpenSubLevel()
end

return Procedure_Login
