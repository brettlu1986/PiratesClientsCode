-----------------------------------------------------
--File Name    : UILogin.lua
--Author       : Song Fuhao
--Create Time  : 2016-06-15
--Description  : 游戏登录界面UI
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILogin = luaclass("UILogin", WndBase)

-- import require
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local SelfVerticalListHelperClass = require("SelfVerticalListHelper")
local LuaDelegateClass = require("LuaDelegate")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local UIUtils = require("UIUtils")
local UIDef = require("UIDef")
local SaveGameDef = require("SaveGameDef")
local HttpHelper = require("HttpHelper")
local UITextDef = require("UITextDef")
local UIManager = require("UIManager")
local L10N = require("L10N")
local WidgetAnimationHandle = require("WidgetAnimationHandle")
local ChannelSDKSystem = require("ChannelSDKSystem")
local TutorialDungeonIni = require("TutorialDungeonIni")
local LoginSdkBtnDataTable = require("LoginSdkBtnDataTable")
local NetworkManager       = dynamic_require("NetworkManager")
local TransformEventDef = require("TransformEventDef")


UILogin.LOGIN_WITH_ACCOUNT      = 0
UILogin.LOGIN_WITH_DEVICE_ID    = 1
UILogin.LOGIN_WITH_THIRD_PARTY_ACCOUNT = 2

-- member variable
UILogin.tbListHelper = nil
UILogin.OnCheckedDelegate = nil
UILogin.tbChosenServerData = nil
UILogin.bIsOpen = false
UILogin.tbSDKBtn = nil
UILogin.pGuideUIModeEvent = nil

local RefreshServerList = nil
local szHeaderName = "If-None-Match"
local szResponseName = "ETag"
local Visible = ESlateVisibility.Visible
local Hidden = ESlateVisibility.Hidden
local HitTestInvisible = ESlateVisibility.HitTestInvisible
local Collapsed = ESlateVisibility.Collapsed


local function SetUseDefaultSaveId(bValue)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:SetUseDefaultUserId(bValue)
end

function UILogin:OnCreate()
    self.tbListHelper = SelfVerticalListHelperClass()
    self.OnCheckedDelegate = LuaDelegateClass()
end

local function OnServerListItemChecked(self, tbServerData)
    self.tbChosenServerData = tbServerData
    if self.tbChosenServerData then
        self.pWidgetRef.txtCurrentServer:SetText(self.tbChosenServerData.name)
    end
    RefreshServerList(self)
end

local function ResetGlobalVariable()
    GlobalVariableSystem.bShowedCheckIn = false
end

local function InitSDKBtnTable(self, szKeyName, pBtnWidget)
    self.tbSDKBtn[szKeyName] = pBtnWidget
end

local function ShowSDKBtn(self)
    local tbSDKBtn = self.tbSDKBtn
    for __, pBtnWidget in pairs(tbSDKBtn) do
        pBtnWidget:SetVisibility(Collapsed)
    end
    if ChannelSDKSystem:IsValidSdk() then
        local szChannleName = ChannelSDKSystem:GetChannelName()
        local tbTemplate = LoginSdkBtnDataTable:GetTemplateByName(szChannleName)
        if not tbTemplate then
            return
        end
        for szKeyName, pWidget in pairs(tbSDKBtn) do
            pWidget:SetVisibility(tbTemplate["b" .. szKeyName] and Visible or Collapsed)
        end
    else
        tbSDKBtn["Helper"]:SetVisibility(Visible)
    end
end

--由于config参数从服务器下发下来的时间与登录界面加载的时间顺序是不能保证的
--所有使用此方法保证任何顺序下，都能正确读到config参数进行开关显示
local function RefreshGuideCustomCtr(self)
    log("RefreshGuideCustomCtr")
    local bSkipCtrl = GlobalVariableSystem:IsGuideSkipCtrl()
    local EventHelper = self.EventHelper
    if bSkipCtrl == nil then
        if not self.pGuideUIModeEvent then
            self.pGuideUIModeEvent = EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_UI_MODE, self, RefreshGuideCustomCtr)
        end
        return
    end
    local bEnable = true
    local pchkSingleDungeon = self.pWidgetRef.chkSingleDungeon
    local pchkOpenGuide = self.pWidgetRef.chkOpenGuide
    local bDevMode = GlobalVariableSystem:IsDevMode()
    if not bDevMode then
        bEnable = false
    else
        bEnable = bSkipCtrl
    end
    log("bDevMode = " .. tostring(bDevMode) .. " bSkipCtrl = " .. tostring(bSkipCtrl) .. " bEnable = " .. tostring(bEnable))
    pchkSingleDungeon:SetCheckedState(bEnable and ECheckBoxState.Unchecked or ECheckBoxState.Checked)
    pchkOpenGuide:SetCheckedState(bEnable and ECheckBoxState.Unchecked or ECheckBoxState.Checked)
    pchkSingleDungeon:SetVisibility(bEnable and Visible or Collapsed)
    pchkOpenGuide:SetVisibility(bEnable and Visible or Collapsed)
    EventHelper:UnregisterEvent(ClientEventDef.EV_GUIDE_UI_MODE, self, RefreshGuideCustomCtr)
    self.pGuideUIModeEvent = nil
end

-- public function
function UILogin:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.PrefabHelper:BindPrefab(pWidgetRef.pbCutoutScreenAdapter)
    self.tbListHelper:Init(self, pWidgetRef.listServerList)
    self.OnCheckedDelegate:Bind(OnServerListItemChecked, self)
    self.tbSDKBtn = {}
    InitSDKBtnTable(self, "Account", pWidgetRef.btnAccount)
    InitSDKBtnTable(self, "Annoce", pWidgetRef.btnAnnouncement)
    InitSDKBtnTable(self, "Fb", pWidgetRef.btnFaceBook)
    InitSDKBtnTable(self, "CustomerService", pWidgetRef.btnCustomerService)
    InitSDKBtnTable(self, "Helper", pWidgetRef.btnHelper)
    ShowSDKBtn(self)
    ResetGlobalVariable()
    self:UpdateVersionCode()
end

function UILogin:OnDestroy()
    self.tbListHelper:Uninit()
end

RefreshServerList = function (self)
    local tbServerList = GlobalVariableSystem.tbServerList
    local nDefaultServerIdx = 1
    for i, tbServerData in ipairs(tbServerList) do
        tbServerData.OnCheckedDelegate = self.OnCheckedDelegate
        tbServerData.nChosen = false
        if tbServerData.default then
            nDefaultServerIdx = i
            local szlog = string.format("[Selected Server Info] id:%s name:%s hydra:%s hub:%s", tostring(tbServerData.id), tbServerData.name, tbServerData.hydra, tbServerData.hub)
            if tbServerData.dungeon then
                szlog = szlog .. string.format(" dungeon_url:%s", tbServerData.dungeon.url)
            end
            log(szlog)
            GamePlatformMiscLibrary.LogDebug(szlog)
        end
    end
    if self.tbChosenServerData == nil then
        self.tbChosenServerData = tbServerList[nDefaultServerIdx]
        local tbServerData = self.tbChosenServerData
        local szlog = string.format("[Set Default Server Info] id:%s name:%s hydra:%s hub:%s", tostring(tbServerData.id), tbServerData.name, tbServerData.hydra, tbServerData.hub)
        GamePlatformMiscLibrary.LogDebug(szlog)
    end

    if self.tbChosenServerData ~= nil then
        self.tbChosenServerData.nChosen = true
    end
    self.tbListHelper:SetData(tbServerList)
end

local function LoadLastChosenServerData(self)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local szChosenServerId = pSaveGameMgr:GetStringData(SaveGameDef.CHOSEN_SERVER_ID)
    if szChosenServerId ~= nil and szChosenServerId ~= "" then
        local tbServerList = GlobalVariableSystem.tbServerList
        for i, tbServerData in ipairs(tbServerList) do
            if tbServerData.id == szChosenServerId then
                self.tbChosenServerData = tbServerData
                break
            end
        end
    end
end

local function SaveChosenServerData(self)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local szChosenServerId = ""
    if self.tbChosenServerData then
        GlobalVariableSystem.tbCurrentServerData = self.tbChosenServerData
        szChosenServerId = self.tbChosenServerData.id
    end
    pSaveGameMgr:AddStringData(SaveGameDef.CHOSEN_SERVER_ID, szChosenServerId)
    pSaveGameMgr:Save()
end

local function LoadLastUserName(self)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local szUsername = pSaveGameMgr:GetStringData(SaveGameDef.USER_NAME)
    if szUsername ~= nil and szUsername ~= "" then
        self.pWidgetRef.txtUserName:SetText(szUsername)
    else
        self.pWidgetRef.txtUsername:SetText("")
    end
end

local function EncryptPassword(self, szPassword)
    return szPassword
end

local function SaveLastUserName(self)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local szUsername = L10N:ToString(self.pWidgetRef.txtUsername:GetText())
    if szUsername ~= nil and szUsername ~= "" then
        GlobalVariableSystem.szUserName = szUsername
        pSaveGameMgr:AddStringData(SaveGameDef.USER_NAME, szUsername)
        pSaveGameMgr:Save()
    end

    local szPassword = L10N:ToString(self.pWidgetRef.txtPassword:GetText())
    if szPassword ~= nil then
        GlobalVariableSystem.szUserPassword = EncryptPassword(self, szPassword)
    end
end

local function OnTextChanged(self, l10nText)
    local szTemp = string.gsub(L10N:ToString(l10nText), '\n', '')
    self.pWidgetRef.txtUserName:SetText(szTemp)
end

local function OnLoginServerInfoComplete(self)
    local tbServerList = GlobalVariableSystem.tbServerList
    if tbServerList then
        LoadLastChosenServerData(self)
        RefreshServerList(self)
    end
    self.pWidgetRef.bdrGM:SetVisibility(tbServerList and #tbServerList > 1 and Visible or Hidden)
    self:UpdateVersionCode()
    self:OnAnnouncement()
end

function UILogin:OnShow()
    local pWidgetRef = self.pWidgetRef
    LoadLastUserName(self)
    local tbServerList = GlobalVariableSystem.tbServerList
    if tbServerList then
        LoadLastChosenServerData(self)
        RefreshServerList(self)
    end
    pWidgetRef.bdrGM:SetVisibility(tbServerList and #tbServerList > 1 and Visible or Hidden)
    self:PlayAnimation("animComeIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
    self:PlayAnimation("animLOGO", 0, 0, EUMGSequencePlayMode.Forward, 1)
    if ChannelSDKSystem:IsValidSdk() then
        log("UILogin:OnShow sdk")
        self:PlayAnimation("animLeftBar", 0, 1, EUMGSequencePlayMode.Forward, 1)
        pWidgetRef.txtUserName:SetVisibility(Hidden)
        pWidgetRef.serverlist:SetVisibility(HitTestInvisible)
        pWidgetRef.ovlSwitchAccount:SetVisibility(Hidden)
        if self.tbChosenServerData then
            pWidgetRef.txtCurrentServer:SetText(self.tbChosenServerData.name)
        end
        --新的登录样式 2019.7.8
        pWidgetRef.ovlAccountInfo:SetVisibility(Hidden)
        pWidgetRef.btnDeviceLogin:SetVisibility(Hidden)
        if not ChannelSDKSystem:FBBtnCanShow() then
            pWidgetRef.btnFaceBook:SetVisibility(Collapsed)
        end
    else
        log("UILogin:OnShow no sdk")
        pWidgetRef.txtUserName:SetVisibility(Visible)
        pWidgetRef.serverlist:SetVisibility(Hidden)
        pWidgetRef.ovlSwitchAccount:SetVisibility(Hidden)
    end
    pWidgetRef.chkSingleDungeon:SetVisibility(Collapsed)
    pWidgetRef.chkOpenGuide:SetVisibility(Collapsed)
    -- local bIsDevMode = GlobalVariableSystem:IsDevMode()
    -- if not bIsDevMode then
        --pWidgetRef.chkSingleDungeon:SetVisibility(Collapsed)
    -- end
    self:OnAnnouncement()
    RefreshGuideCustomCtr(self)
    --GlobalVariableSystem:SetOpenLobby3D(false)
    EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_LOADING_TRANSFORM, TransformEventDef.TARGET_EVENT_NAME.ENTER_GAME_START)
end


function UILogin:OnHide()
    SaveChosenServerData(self)
    SaveLastUserName(self)
end

function UILogin:OnClickFaceBook()
    ChannelSDKSystem:ShowFacebookWeb()
end

function UILogin:OnBindEvent()
    local Helper = self.EventHelper
    local pWidgetRef = self.pWidgetRef
    Helper:RegisterCppDelegate(pWidgetRef.btnStart.OnClicked, self, self.OnClickedButtonStart)
    Helper:RegisterCppDelegate(pWidgetRef.btnAccount.OnClicked, self, self.OnAccount)
    Helper:RegisterCppDelegate(pWidgetRef.btnSwitchAccount.OnClicked, self, self.OnSwitchAccount)
    Helper:RegisterCppDelegate(pWidgetRef.btnCustomerService.OnClicked, self, self.OnCustomerService)
    Helper:RegisterCppDelegate(pWidgetRef.btnHelper.OnClicked, self, self.OnCustomerService)
    Helper:RegisterCppDelegate(pWidgetRef.btnAnnouncement.OnClicked, self, self.ReviewAnnouncement)
    Helper:RegisterCppDelegate(pWidgetRef.btnServerlist.OnClicked, self, self.OnChangeServer)
    Helper:RegisterCppDelegate(pWidgetRef.btnDeviceLogin.OnClicked, self, self.OnClickedButtonDeviceLogin)
    Helper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(pWidgetRef, pWidgetRef.animComeIn, self.OnAnimFinished, self))
    Helper:RegisterCppDelegate(pWidgetRef.txtUserName.OnTextChanged, self, OnTextChanged)
    Helper:RegisterCppDelegate(pWidgetRef.btnFaceBook.OnClicked, self, self.OnClickFaceBook)
    Helper:RegisterEvent(ClientEventDef.EV_LOGIN_SERVER_INFO_COMPLETED, self, OnLoginServerInfoComplete)
end

local function FireLoginEvent(self, nLoginMode, ...)
    if self.tbChosenServerData ~= nil then
        local Socket = NetworkManager:GetHubServerProxy()
        if Socket ~= nil and Socket:IsConnect() then
            log("click login but is connected")
            return
        else
            GamePlatformMiscLibrary.LogDebug("[UIGameLogin] FireLoginEvent tbChosenServerData is not nil~")
            SaveChosenServerData(self)
            SaveLastUserName(self)
            GlobalVariableSystem.nLoginMode = nLoginMode
            EventManager:OnFireEvent(ClientEventDef.EV_UI_LOGIN, self.tbChosenServerData, nLoginMode, ...)
        end
    else
        GamePlatformMiscLibrary.LogDebug("Please choose a server!")
        UIUtils.ShowToastWithKey("CHOOSE_SERVER_TIPS")
    end
end

local function showLoginNotice(szContent)
    local szTitle = UITextDef.ANNOUNCEMENT_LABEL
    UIManager:OpenWnd(UIDef.UI_ANNOUNCEMENT,{szTitle = szTitle, szContent = szContent})
end

function UILogin:StartAccountLogin()
    if ChannelSDKSystem:IsValidSdk() then
        FireLoginEvent(self, UILogin.LOGIN_WITH_THIRD_PARTY_ACCOUNT)
    else
        local szUsername = L10N:ToString(self.pWidgetRef.txtUsername:GetText())
        local szPassword = L10N:ToString(self.pWidgetRef.txtPassword:GetText())
        FireLoginEvent(self, UILogin.LOGIN_WITH_ACCOUNT, szUsername, szPassword)
    end
end

function UILogin:StartDeviceLogin()
    FireLoginEvent(self, UILogin.LOGIN_WITH_DEVICE_ID)
end

function UILogin:OnClickedButtonStart()
    local bSingelDungeon = self.pWidgetRef.chkSingleDungeon:IsChecked()
    TutorialDungeonIni.bEnabled = bSingelDungeon
    local bOpenGuide = self.pWidgetRef.chkOpenGuide:IsChecked()
    GlobalVariableSystem:SetOpenGuide(bOpenGuide)
    self:StartAccountLogin()
end

function UILogin:OnClickedButtonDeviceLogin(bSingelDungeon, bOpenGuide)
    if bSingelDungeon == nil then
        bSingelDungeon = self.pWidgetRef.chkSingleDungeon:IsChecked()
    end
    TutorialDungeonIni.bEnabled = bSingelDungeon
    if bOpenGuide == nil then
        bOpenGuide = self.pWidgetRef.chkOpenGuide:IsChecked()
    end
    GlobalVariableSystem:SetOpenGuide(bOpenGuide)
    self:StartDeviceLogin()
end

function UILogin:UpdateVersionCode()
    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    if not pGameInstance then
        return
    end
    local szVerson = GlobalVariableSystem:GetVersion()
    szVerson = szVerson and szVerson ~= "" and szVerson or 'Unknown'
    self.pWidgetRef.txtVersion:SetText(szVerson)

    BuglyCrashReportBPLibrary.SetBuglyAppVersion(szVerson)
    log("bugly set app version : ", szVerson)
end

function UILogin:PlayExitAnim()
    self:PlayAnimation("animComeIn", 0, 1, EUMGSequencePlayMode.Reverse, 1)
end

function UILogin:OnAnimFinished()
    if self.bIsOpen then
        self.bIsOpen = false
        UIManager:CloseWnd(UIDef.UI_LOGIN)
    else
        self.bIsOpen = true
    end
end

function UILogin:OnAccount()
    ChannelSDKSystem:SwitchAccount()
end

function UILogin:OnSwitchAccount()
    ChannelSDKSystem:SwitchAccount()
end

function UILogin:OnCustomerService()
    ChannelSDKSystem:OnCustomerService()
end

function UILogin:OnHelper()
    UIUtils.ShowCustomerHelper()
end

function UILogin:OnAnnouncement()
    local szAnnouncement = GlobalVariableSystem:GetAnnouncementUrl()
    if szAnnouncement and szAnnouncement ~= "" then
        SetUseDefaultSaveId(true)
        local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
        local szHeaderValue = pSaveGameMgr:GetStringData(SaveGameDef.LOGIN_ANNOUNCEMENT_ETAG)
        local _ = HttpHelper:SendGetRequestWithHeader(szAnnouncement, szHeaderName, szHeaderValue, szResponseName,
        function(nRetCode, szContent, szResponseHeaderValue)
            if nRetCode == HttpHelper.HttpResponseCodes.OK then
                pSaveGameMgr:AddStringData(SaveGameDef.LOGIN_ANNOUNCEMENT_ETAG, szResponseHeaderValue)
                pSaveGameMgr:AddStringData(SaveGameDef.LOGIN_ANNOUNCEMENT, szContent)
                pSaveGameMgr:Save()
                showLoginNotice(szContent)
            end
        end)
        SetUseDefaultSaveId(false)
    end
end

function UILogin:ReviewAnnouncement()
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local szContent = pSaveGameMgr:GetStringData(SaveGameDef.LOGIN_ANNOUNCEMENT)
    if szContent and szContent ~= "" then
        showLoginNotice(szContent)
    end
end

function UILogin:OnChangeServer()
    -- UIUtils.ShowToast("choose a server.")
end

return UILogin
