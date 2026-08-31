local luaclass                  = require("luaclass")
local CPPDelegateProcessorBase  = require("CPPDelegateProcessorBase")
local SDKCppDelegateProcessor   = luaclass("SDKCppDelegateProcessor", CPPDelegateProcessorBase)

local EventManager      = require("EventManager")
local ClientEventDef    = require("ClientEventDef")
local UIManager         = require("UIManager")
local UIDef             = require("UIDef")
local GVoiceDebug       = require("GVoiceDebug")


local function OnNoChannelExitGame()
    UIManager:OpenWnd(UIDef.UI_EXIT_GAME_DIALOG)
end

local function OnExitGame()
    KismetSystemLibrary.QuitGame(GWorld, nil, EQuitPreference.Quit)
end

local function OnLogout()
    -- 2020.3.19 修改退出登录流程
    --EventManager:OnFireEvent(ClientEventDef.EV_UI_SELECT_ROLE_BACK)
end

local function OnBackToLogin()
    EventManager:OnFireEvent(ClientEventDef.EV_UI_SELECT_ROLE_BACK)
end

local function OnAccountBindSuccess()
    EventManager:OnFireEvent(ClientEventDef.EV_ON_BINDACCOUNT_SUCCESS)
end

local function OnPayResult(code)
    -- log("======OnPayResult code :" .. tostring(code))
    EventManager:OnFireEvent(ClientEventDef.EV_ON_PAY_RESULT, code)
end

local function OnJoinRoom(nCompleteCode, szRoomName, nMemberID)
    GVoiceDebug:DebugLog("==============OnJoinRoom=========== szRoomName : " .. tostring(szRoomName) .. " nMemberID: " .. tostring(nMemberID))
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_JOIN_ROOM, nCompleteCode, szRoomName, nMemberID)
end

local function OnStatusUpdate(szRoomName, nMemberID)
    GVoiceDebug:DebugLog("==============OnStatusUpdate=========== szRoomName : " .. tostring(szRoomName) .. " nMemberID: " .. tostring(nMemberID))
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_STATUS_UPDATE, szRoomName, nMemberID)
end

local function OnQuitRoom(nCompleteCode, szRoomName)
    GVoiceDebug:DebugLog("==============OnQuitRoom=========== szRoomName : " .. tostring(szRoomName))
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_QUIT_ROOM, nCompleteCode, szRoomName)
end

local function OnMemberVoice(szRoomName, nMemberID, nStatus)
    -- GVoiceDebug:DebugLog("==============OnMemberVoice=========== szRoomName : " .. tostring(szRoomName) .. " nMemberID: " .. tostring(nMemberID) .. " nStatus : " .. tostring(nStatus))
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE, szRoomName, nMemberID, nStatus)
end

local function OnMemberVoiceDetail(tbMemberVoiceInfo, nCount)
    -- GVoiceDebug:DebugLog("==============OnMemberVoiceDetail=========== nCount : " .. tostring(nCount) .. " tbMemberVoiceInfo: " .. tostring(tbMemberVoiceInfo))
    -- for k,v in pairs(tbMemberVoiceInfo) do
    --     GVoiceDebug:DebugLog("memberId: " .. tostring(k) .. " state: " .. tostring(v))
    -- end
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE_DETAIL, tbMemberVoiceInfo, nCount)
end
local function OnRoomMemberInfo(nCompleteCode, nMemberID, szRoomName, szOpenId)
    GVoiceDebug:DebugLog("==============OnRoomMemberInfo=========== nMemberID : " .. tostring(nMemberID) .. " szRoomName: " .. tostring(szRoomName) .. " szOpenId: " .. tostring(szOpenId))
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_ROOM_MEMBER_INFO, nMemberID, szRoomName, szOpenId)
end

local function OnRecording(nLength)
    GVoiceDebug:DebugLog("==============OnRecording=========== nLength : " .. nLength)
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_RECORDING, nLength)
end

local function OnEvent(nEventCode, szInfo)
    -- GVoiceDebug:DebugLog("==============OnEvent=========== nEventCode : " .. tostring(nEventCode))
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_VOICE_EVENT, nEventCode, szInfo)
end

local function OnGetMemberInfo(nErrorCode, tbMemberIds, tbMemberOpenIds)
    GVoiceDebug:DebugLog("==============OnGetMemberInfo===========")
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_VOICE_GET_MEMBERINFO, nErrorCode, tbMemberIds, tbMemberOpenIds)
end

function SDKCppDelegateProcessor:Init()
    SDKCppDelegateProcessor.super.Init(self)

    -- Register Gameplay Delegate
    local DelegateMgr = ClientShell.GetClient(GWorld):GetClientDelegateManager()

    local pSdkDelegate = DelegateMgr.SdkDelegate
    self:Register(pSdkDelegate.OnExit, OnExitGame)
    self:Register(pSdkDelegate.OnNoChannelExit, OnNoChannelExitGame)
    self:Register(pSdkDelegate.OnLogout, OnLogout)
    self:Register(pSdkDelegate.OnBindAccountSuccess, OnAccountBindSuccess)
    self:Register(pSdkDelegate.OnPayResult, OnPayResult)
    self:Register(pSdkDelegate.OnBackToLogin, OnBackToLogin)

    local pGVoiceSdkDelegate = DelegateMgr.GVoiceSdkNotifyDelegate
    self:Register(pGVoiceSdkDelegate.OnJoinRoom, OnJoinRoom)
    self:Register(pGVoiceSdkDelegate.OnStatusUpdate, OnStatusUpdate)
    self:Register(pGVoiceSdkDelegate.OnQuitRoom, OnQuitRoom)
    self:Register(pGVoiceSdkDelegate.OnMemberVoice, OnMemberVoice)
    self:Register(pGVoiceSdkDelegate.OnMemberVoiceDetail, OnMemberVoiceDetail)
    self:Register(pGVoiceSdkDelegate.OnRecording, OnRecording)
    self:Register(pGVoiceSdkDelegate.OnRoomMemberInfo, OnRoomMemberInfo)
    self:Register(pGVoiceSdkDelegate.OnEvent, OnEvent)
    self:Register(pGVoiceSdkDelegate.GetMemberInfo, OnGetMemberInfo)
    return true
end

return SDKCppDelegateProcessor
