local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingBasic = luaclass("UPSettingBasic", PrefabBase)
local SettingClassType = require("SettingClassType")
local SettingSystemNew = require("SettingSystemNew")
local SettingKeyDef = require("SettingKeyDef")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local UIDialogQuitDungeonHelper = require("UIDialogQuitDungeonHelper")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ChannelSDKSystem  = require("ChannelSDKSystem")
local ProtoDC = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
-- local ProcedureTool = require("ProcedureTool")
local TutorialDungeonIni = require("TutorialDungeonIni")
local SettingIni = require("SettingIni")
local GPerfSystem = require("GPerfSystem")

local LocalKeys = SettingKeyDef.LocalKeys
local RemoteKeys= SettingKeyDef.RemoteKeys

local MAX_FIRE_COUNT = 3
local MAX_HISTORY_COUNT = 2
local MAX_RELATION_COUNT = 2
local MAX_SEASON_COUNT = 2

local HUMAN_GYRO_COUNT = 3
local SHIP_GYRO_COUNT = 3
local AIM_ASSIST_COUNT = 3
local RECOMMEND_MEDICINE_COUNT = 2
local CHANGE_DISPLAY_COUNT = 2
local AUTO_FOLLOW_COUNT = 2
local AUTO_OPEN_DOOR_COUNT = 2
local UPLOAD_LOG_ENABLE_COUNT = 10
local UPLOAD_LOG_TIME_DELTA = 300
local UPLOAD_LOG_TEXT_DISABLED_OPACITY = 0.3
local UPLOAD_LOG_TEXT_ENABLED_OPACITY = 1

local CHECKED, UNCHECKED = ECheckBoxState.Checked, ECheckBoxState.Unchecked
local Collapsed = ESlateVisibility.Collapsed

UPSettingBasic.tbInstance = nil
UPSettingBasic.bSailOpacityChanged = nil
UPSettingBasic.pbNormalSailOpacity = nil
UPSettingBasic.pbFiringSailOpacity = nil
UPSettingBasic.nUploadLogClickedCount = 0

local function RefreshKey(self, nKey, szWidgetName, nMaxIndex)
    local pWidgetRef = self.pWidgetRef
    
    local nValue = self.tbInstance:Get(nKey)
    for i = 0, nMaxIndex do
        pWidgetRef[szWidgetName..i]:SetCheckedState(nValue == i and CHECKED or UNCHECKED)
    end
end

local function RefreshFire(self)
    RefreshKey(self, LocalKeys.FIRE_BY_LEFT_HAND, "cbFire", MAX_FIRE_COUNT - 1)
end

local function RefreshHistory(self)
    RefreshKey(self, RemoteKeys.ALLOW_WATCH_HISTORY_STATS, "cbHistory", MAX_HISTORY_COUNT - 1)
end
    
local function RefreshSeason(self)
    RefreshKey(self, RemoteKeys.ALLOW_WATCH_SEASON_STATS, "cbSeason", MAX_SEASON_COUNT - 1)
end

local function RefreshHumanGyro(self)
    RefreshKey(self, LocalKeys.HUMAN_GYRO, "cbHumanGyro", HUMAN_GYRO_COUNT - 1)
end

local function RefreshShipGyro(self)
    RefreshKey(self, LocalKeys.SHIP_GYRO, "cbShipGyro", SHIP_GYRO_COUNT - 1)
end

local function RefreshAimAssist(self)
    RefreshKey(self, LocalKeys.AIM_ASSIST, "cbAimAssist", AIM_ASSIST_COUNT - 1)
end

local function RefreshRecommendMedicine(self)
    RefreshKey(self, LocalKeys.MEDICINE_RECOMMEND, "cbRecommendMedicine", RECOMMEND_MEDICINE_COUNT - 1)
end

local function RefreshChangeDiaplay(self)
    RefreshKey(self, LocalKeys.CHANGE_DISPLAY, "cbChangeDisplay", CHANGE_DISPLAY_COUNT - 1)
end

local function RefreshAutoRot(self)
    RefreshKey(self, LocalKeys.AUTO_ROT, "cbCameraFollow", AUTO_FOLLOW_COUNT - 1)
end

local function RefreshAutoOpenDoor(self)
    RefreshKey(self, LocalKeys.AUTO_OPEN_DOOR, "cbAutoOpenDoor", AUTO_OPEN_DOOR_COUNT - 1)
end

local function RefreshAllowCheckRelation(self)
    RefreshKey(self, RemoteKeys.ALLOW_WATCH_OTHER_RELATION, "cbAllowRelation", MAX_RELATION_COUNT - 1)
    RefreshKey(self, RemoteKeys.ALOOW_WATCH_TEAM_RELATION, "cbAllowRelation", MAX_RELATION_COUNT - 1)
end

local function RefreshTeleport(self)
    local pWidgetRef = self.pWidgetRef
    if GlobalVariableSystem:IsInDungeon() then
        pWidgetRef.btnTeleport:SetVisibility(ESlateVisibility.Visible)
    end
end

local function RefreshQuit(self)
    if GlobalVariableSystem:IsInDungeon() then
        self.pWidgetRef.txtQuit:SetText(UISetUtils.GetL10NTextByKey("UI_SETTING_RETURN_LOBBY"))        
    else
        self.pWidgetRef.txtQuit:SetText(UISetUtils.GetL10NTextByKey("UI_SETTING_RETURN_LOGIN"))
    end
end

local function RefreshSDKBtn(self)
    local pWidgetRef = self.pWidgetRef
    if not ChannelSDKSystem:IsValidSdk() then
        pWidgetRef.btnAssocia:SetVisibility(Collapsed)
        pWidgetRef.btnFacebook:SetVisibility(Collapsed)
        pWidgetRef.btnUCenter:SetVisibility(Collapsed)
    else
        if ChannelSDKSystem:IsBindAccount() then
            pWidgetRef.btnAssocia:SetVisibility(Collapsed)
        end
        if not ChannelSDKSystem:FBBtnCanShow() then
            pWidgetRef.btnFacebook:SetVisibility(Collapsed)
        end
    end
    -- 2020.3.19 临时修改按钮显示样式，以后执行替换方案
    pWidgetRef.btnAssocia:SetVisibility(Collapsed)
    pWidgetRef.btnFacebook:SetVisibility(Collapsed)
    pWidgetRef.btnUCenter:SetVisibility(Collapsed)
end

local function RefreshUI(self)
    RefreshFire(self)
    RefreshHistory(self)
    RefreshSeason(self)
    RefreshQuit(self)
    RefreshSDKBtn(self)
    RefreshHumanGyro(self)
    RefreshShipGyro(self)
    RefreshTeleport(self)
    RefreshAimAssist(self)
    RefreshRecommendMedicine(self)
    RefreshChangeDiaplay(self)
    RefreshAutoRot(self)
    RefreshAutoOpenDoor(self)
    RefreshAllowCheckRelation(self)
end

local function ChangeValue(self, nKey, szWidgetName, nIndex, bActivate)
    local nCurValue = self.tbInstance:Get(nKey)
    if nCurValue == nIndex then
        if not bActivate then
            self.pWidgetRef[szWidgetName..nIndex]:SetCheckedState(CHECKED)
        end
        return false
    else
        self.tbInstance:Set(nKey, nIndex)
        SettingSystemNew:SaveLocalData()
        return true
    end    
end

local function OnClickedFire(self, nIndex, bActivate)
    if ChangeValue(self, LocalKeys.FIRE_BY_LEFT_HAND, "cbFire", nIndex, bActivate) then
        RefreshFire(self)
    end
end

local function OnClickedHistory(self, nIndex, bActivate)
    if ChangeValue(self, RemoteKeys.ALLOW_WATCH_HISTORY_STATS, "cbHistory", nIndex, bActivate) then
        RefreshHistory(self)
    end
end

local function OnClickedSeason(self, nIndex, bActivate)
    if ChangeValue(self, RemoteKeys.ALLOW_WATCH_SEASON_STATS, "cbSeason", nIndex, bActivate) then
        RefreshSeason(self)
    end
end

local function OnClickHumanGyro(self, nIndex, bActivate)
    if ChangeValue(self, LocalKeys.HUMAN_GYRO, "cbHumanGyro", nIndex, bActivate) then
        RefreshHumanGyro(self)
        EventManager:OnFireEvent(ClientEventDef.EV_SETTING_HUMAN_GYRO, nIndex)
    end
end

local function OnClickShipGyro(self, nIndex, bActivate)
    if ChangeValue(self, LocalKeys.SHIP_GYRO, "cbShipGyro", nIndex, bActivate) then
        RefreshShipGyro(self)
        EventManager:OnFireEvent(ClientEventDef.EV_SETTING_SHIP_GYRO, nIndex)
    end
end

local function OnClickAimAsisst(self, nIndex, bActivate)
    if ChangeValue(self, LocalKeys.AIM_ASSIST, "cbAimAssist", nIndex, bActivate) then
        RefreshAimAssist(self)
        EventManager:OnFireEvent(ClientEventDef.EV_SETTING_AIM_ASSIST, nIndex)
    end
end

local function OnClickRecommendMedicine(self, nIndex, bActivate)
    if ChangeValue(self, LocalKeys.MEDICINE_RECOMMEND, "cbRecommendMedicine", nIndex, bActivate) then
        RefreshRecommendMedicine(self)
        EventManager:OnFireEvent(ClientEventDef.EV_RECOMMEND_MEDICINE_CHANGED, nIndex)
    end
end

local function OnClickChangeDisplay(self, nIndex, bActivate)
    if ChangeValue(self, LocalKeys.CHANGE_DISPLAY, "cbChangeDisplay", nIndex, bActivate) then
        RefreshChangeDiaplay(self)
        EventManager:OnFireEvent(ClientEventDef.EV_SETTING_CHANGE_DISPLAY)
    end
end

local function OnClickChangeAutoRot(self, nIndex, bActivate)
    if ChangeValue(self, LocalKeys.AUTO_ROT, "cbCameraFollow", nIndex, bActivate) then
        RefreshAutoRot(self)
        EventManager:OnFireEvent(ClientEventDef.EV_SETTING_AUTO_ROT, nIndex)
    end
end

local function OnClickChangeAutoOpenDoor(self, nIndex, bActivate)
    if ChangeValue(self, LocalKeys.AUTO_OPEN_DOOR, "cbAutoOpenDoor", nIndex, bActivate) then
        RefreshAutoOpenDoor(self)
    end
end

local function OnClickChangeAllowRelation(self, nIndex, bActivate)
    if ChangeValue(self, RemoteKeys.ALLOW_WATCH_OTHER_RELATION, "cbAllowRelation", nIndex, bActivate) and 
        ChangeValue(self, RemoteKeys.ALOOW_WATCH_TEAM_RELATION, "cbAllowRelation", nIndex, bActivate) then
        RefreshAllowCheckRelation(self)
    end
end

local function IsTutorialDungeon()
    local nDungeonId = BattleGameModeSystem.nDungeonId
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return true
    end
    return false
end

local function OnClickedQuit(self)
    if GlobalVariableSystem:IsInDungeon() then
        local tbGameState = BattleGameModeSystem:GetGameState()
        local nQuitDungeonDialogType = tbGameState.rGameStateBaseInfo.nQuitDungeonType
        local bCanQuit = tbGameState.rGameStateBaseInfo.bCanQuit

        if bCanQuit then
            local szTitle = UIDialogQuitDungeonHelper:GetDungeonQuitDialogTitle(nQuitDungeonDialogType)
            local szMessage = UIDialogQuitDungeonHelper:GetDungeonQuitDialogMessage(nQuitDungeonDialogType)
            if szTitle ~= nil and szMessage ~= nil then
                local funQuit = function()
                    if IsTutorialDungeon() then
                        NetworkManager:GetHubServerProxy():Disconnect()
                        -- ProcedureTool:ReturnToLogin()
                    else
                        BattleGameModeSystem:RequestQuitDungeon(BattleGameModeSystem.QUIT_REASON.QUIT_BUTTON)
                    end
                end
                local funCancel = function()
                    UIManager:CloseWnd(UIDef.UI_DIALOG_BOARD)
                end
                UIUtils.ShowChoiceDialog(szTitle, szMessage, funQuit, funCancel)

            else
                logwarning("UIBattleSettings:OnClickedBtnExitDungeon failed. nQuitDungeonDialogType:", nQuitDungeonDialogType, ". szTitle:", szTitle, "; szMessage:", szMessage, ". Please override BattleGameMode:GetQuitDungeonDialogType function")
            end
        else
            local szLimitMessage = UIDialogQuitDungeonHelper:GetDungeonQuitDialogLimitMessage(nQuitDungeonDialogType)
            if szLimitMessage then
                UIUtils.ShowToast(szLimitMessage)
            else
                logwarning("UIBattleSettings:OnClickedBtnExitDungeon Cannot quit. But missing limit message. nQuitDungeonDialogType", nQuitDungeonDialogType)
            end
        end
    else
        -- 2020.3.19 修改退出登录流程
        -- if GlobalVariableSystem.nLoginMode == GlobalVariableSystem.LOGIN_WITH_THIRD_PARTY_ACCOUNT then
        --     ChannelSDKSystem:Logout()
        -- else
            UIUtils.ShowChoiceDialog(UISetUtils.GetL10NTextByKey("UPMAINPLAYERINFO_MESSAGE_TITLE"), 
            UISetUtils.GetL10NTextByKey("COMMON_RETURN_LOGIN"), 
            function()
                --用于数据上报
                EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_RETURN_TO_START_GAME)
                EventManager:OnFireEvent(ClientEventDef.EV_UI_SELECT_ROLE_BACK)
            end)
        -- end
    end
end

local function OnClickAssocia(self)
    log("=======OnClickAssocia=======")
    if not ChannelSDKSystem:IsBindAccount() then
        ChannelSDKSystem:AssociaAccount()
    else
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SDK_ASSOCIA_ALREADY_BIND"), 0.2)
    end
end

local function OnClickHelper(self)
    log("=======OnClickHelper=======")
    ChannelSDKSystem:OnCustomerService()
end

local function OnClickFacebook(self)
    log("=======OnClickFacebook=======")
    ChannelSDKSystem:ShowFacebookWeb()
end

local function OnClickUCenter(self)
    log("=======OnClickUCenter=======")
    ChannelSDKSystem:OpenUCenter()
end

local function OnClickTeleport(self)
    log("=======OnClickTeleport=======")
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_TeleportToSafeLocation)
    self.Owner:CloseSelf()
end

local function ResetBtnUploadLog(self)
    if GPerfSystem:IsManualUploadingMode() then
        self.pWidgetRef.btnUploadLog:SetVisibility(ESlateVisibility.Visible)
        self.pWidgetRef.btnUploadLog:SetIsEnabled(false)
        self.pWidgetRef.txtUploadLog:SetRenderOpacity(UPLOAD_LOG_TEXT_DISABLED_OPACITY)
        self.nUploadLogClickedCount = 0
    else
        self.pWidgetRef.btnUploadLog:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function OnClickUploadLog(self)
    local nCurrentTime = getseconds()
    if nCurrentTime - GlobalVariableSystem.nLastUploadLogTime > UPLOAD_LOG_TIME_DELTA then
        GlobalVariableSystem.nLastUploadLogTime = nCurrentTime
        GPerfSystem:ManualUploadLog()
        UIUtils.ShowToastWithKey("UPLOAD_LOG_SUCCESS")
    else
        UIUtils.ShowToastWithKey("UPLOAD_LOG_VERY_FREQUENT")
    end
end

local function OOnDisableClickedkUploadLog(self)
    self.nUploadLogClickedCount = self.nUploadLogClickedCount + 1
    if self.nUploadLogClickedCount == 1 then   
        UIUtils.ShowToastWithKey("FFA_FUNCTION_NOT_OPEN")
    elseif self.nUploadLogClickedCount == UPLOAD_LOG_ENABLE_COUNT then
        self.pWidgetRef.btnUploadLog:SetIsEnabled(true)
        self.pWidgetRef.txtUploadLog:SetRenderOpacity(UPLOAD_LOG_TEXT_ENABLED_OPACITY)
    end
end

local function OnBindAccountSuccess(self)
    self.pWidgetRef.btnAssocia:SetVisibility(Collapsed)
end

local function OnNormalSailOpacityChanged(self, nValue)
    self.tbInstance:Set(LocalKeys.NORMAL_SAIL_OPACITY, math.floor(nValue))
    SettingSystemNew:SaveLocalData()
    self.bSailOpacityChanged = true
end

local function OnFiringSailOpacityChanged(self, nValue)
    self.tbInstance:Set(LocalKeys.FIRING_SAIL_OPACITY, math.floor(nValue))
    SettingSystemNew:SaveLocalData()
    self.bSailOpacityChanged = true
end

local function InitSailOpacityUI(self)
    local fnProgressDescGetter = function(_, nValue)
        return math.floor(nValue) .. "%"
    end
    local tbSailOpacity = SettingIni.tbSailOpacity
    local nNormalSailOpacity = self.tbInstance:Get(LocalKeys.NORMAL_SAIL_OPACITY, tbSailOpacity.nNormalDefault)
    local nFiringSailOpacity = self.tbInstance:Get(LocalKeys.FIRING_SAIL_OPACITY, tbSailOpacity.nFiringDefault)

    self.pbNormalSailOpacity = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbNormalSailOpacity)
    self.pbFiringSailOpacity = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbFiringSailOpacity)
    self.pbNormalSailOpacity:Custom(nNormalSailOpacity, tbSailOpacity.nNormalMin, tbSailOpacity.nNormalMax, tbSailOpacity.nStepSize, fnProgressDescGetter)
    self.pbFiringSailOpacity:Custom(nFiringSailOpacity, tbSailOpacity.nFiringMin, tbSailOpacity.nFiringMax, tbSailOpacity.nStepSize, fnProgressDescGetter)
end

function UPSettingBasic:OnLoad()
    InitSailOpacityUI(self)
end

function UPSettingBasic:OnShow()
    ResetBtnUploadLog(self)
    RefreshUI(self)
end

function UPSettingBasic:OnExit()
    if self.bSailOpacityChanged then
        self.bSailOpacityChanged = false
        EventManager:OnFireEvent(ClientEventDef.EV_SETTING_SHIP_SAIL_OPACITY_CHANGED, self.pbNormalSailOpacity:GetValue(), self.pbFiringSailOpacity:GetValue())
    end
end

function UPSettingBasic:OnCreate()
    self.tbInstance = SettingSystemNew:GetInstance(SettingClassType.Setting_Basic)
end

function UPSettingBasic:OnDestroy()
    self.tbInstance = nil
end

function UPSettingBasic:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    for i = 0, MAX_FIRE_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbFire"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickedFire(self, i, bActivate)
        end)        
    end
    for i = 0, MAX_HISTORY_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbHistory"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickedHistory(self, i, bActivate)
        end)        
    end
    for i = 0, MAX_SEASON_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbSeason"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickedSeason(self, i, bActivate)
        end)        
    end

    for i = 0, HUMAN_GYRO_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbHumanGyro"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickHumanGyro(self, i, bActivate)
        end)        
    end

    for i = 0, SHIP_GYRO_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbShipGyro"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickShipGyro(self, i, bActivate)
        end)        
    end

    for i = 0, AIM_ASSIST_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbAimAssist"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickAimAsisst(self, i, bActivate)
        end)        
    end

    for i = 0, RECOMMEND_MEDICINE_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbRecommendMedicine"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickRecommendMedicine(self, i, bActivate)
        end)        
    end

    for i = 0, CHANGE_DISPLAY_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbChangeDisplay"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickChangeDisplay(self, i, bActivate)
        end)        
    end    

    for i = 0, AUTO_FOLLOW_COUNT - 1 do  
        EventHelper:RegisterCppDelegate(pWidgetRef["cbCameraFollow"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickChangeAutoRot(self, i, bActivate)
        end)  
    end
    
    for i = 0, AUTO_OPEN_DOOR_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbAutoOpenDoor"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickChangeAutoOpenDoor(self, i, bActivate)
        end)  
    end

    for i = 0, MAX_RELATION_COUNT - 1 do
        EventHelper:RegisterCppDelegate(pWidgetRef["cbAllowRelation"..i].OnCheckStateChanged,  self, function(_, bActivate)
            OnClickChangeAllowRelation(self, i, bActivate)
        end)  
    end

    EventHelper:RegisterCppDelegate(pWidgetRef.btnQuit.OnClicked,               self, OnClickedQuit)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAssocia.OnClicked,            self, OnClickAssocia)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnHelper.OnClicked,             self, OnClickHelper)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFacebook.OnClicked,           self, OnClickFacebook)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUCenter.OnClicked,            self, OnClickUCenter)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnTeleport.OnClicked,           self, OnClickTeleport)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUploadLog.OnClicked,          self, OnClickUploadLog)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUploadLog.OnDisableClicked,   self, OOnDisableClickedkUploadLog)
        
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_BINDACCOUNT_SUCCESS,         self, OnBindAccountSuccess)

    EventHelper:RegisterLuaDelegate(self.pbNormalSailOpacity.OnValueChanged, OnNormalSailOpacityChanged, self)
    EventHelper:RegisterLuaDelegate(self.pbFiringSailOpacity.OnValueChanged, OnFiringSailOpacityChanged, self)
end

function UPSettingBasic:Activate()
end

return UPSettingBasic