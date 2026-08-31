-----------------------------------------------------
-----------------------------------------------------
--File Name    : GVoiceSDKSystem.lua
--Author       : Edward J
--Create Time  : 2020-01-02
--Description  :
-----------------------------------------------------
local GVoiceSDKSystem           = {}
local SelfEventHelper           = require("SelfEventHelper")
local ClientEventDef            = require("ClientEventDef")
local DelayTimer                = require("DelayTimer")
local EventManager              = require("EventManager")
local SelfTimerHelperClass      = require("SelfTimerHelper")
local GVoiceDebug               = require("GVoiceDebug")
local TeamWatchClientHelper     = require("TeamWatchClientHelper")
local BattleGameModeSystem      = dynamic_require("BattleGameModeSystem")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
-- local NetworkManager            = dynamic_require("NetworkManager")
-- local ProtoD                    = require("DungeonCommonProtoNames")
local UIUtils                   = require("UIUtils")
local UISetUtils                = require("UISetUtils")
local L10N                      = require("L10N")
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")
local TutorialDungeonIni        = require("TutorialDungeonIni")
local Proto                     = require("ClientProtoNames")
local GVoiceOpCtrlHelper        = require("GVoiceOpCtrlHelper")
local TeamSystem                = require("TeamSystem")
local CppDelegate               = require("CppDelegate")
--member veriable

local GCLOUD_VOICE_REALTIME_STATE_ERR   = 8193 --未加入房间
local GCLOUD_VOICE_JOINT_ROOM_SUCC      = 8193 --join room success
local GCLOUD_VOICE_ROOM_NAME_NOT_SAME   = 8195 --the room name is not same as you join
local GCLOUD_VOICE_QUIT_ROOM_SUCC       = 8198 --quitroom room success
local GCLOUD_VOICE_ALREADY_IN_ROOM      = 8200 --all ready in room
local TEAM_ROOM_TYPE                    = 1
local ALL_ROOM_TYPE                     = 2
local TEAM_LOBBY_TYPE                   = 3
local JOIN_ROOM_TIME_OUT                = 11
-- local SYNC_MEMBER_ID_INTERVAL           = 10
local CHECK_SELF_SPEAKING               = 0.5
local MAX_RECONNECT_COUNT               = 5
local DELAY_CALL_REJOINT                = 1

GVoiceSDKSystem.pGVoiceSdkManager           = nil
GVoiceSDKSystem.PollTimerHandle             = nil
GVoiceSDKSystem.szLobbyTeamRoomName         = nil
GVoiceSDKSystem.szTeamRoomName              = nil
GVoiceSDKSystem.szAllRoomName               = nil
GVoiceSDKSystem.TimerHelper                 = nil
GVoiceSDKSystem.szTeamChangeEvent           = nil
GVoiceSDKSystem.tbMemberIdToPlayerId        = nil
GVoiceSDKSystem.bJoinTeamRoomSucess         = false
GVoiceSDKSystem.bJoinAllRoomSucess          = false
GVoiceSDKSystem.bJoinLobbyTeamRoomSucess    = false
GVoiceSDKSystem.bInRetraveling              = nil
GVoiceSDKSystem.bInDungeon                  = false
GVoiceSDKSystem.bInJoinTeam                 = false
GVoiceSDKSystem.bInJoinAll                  = false
GVoiceSDKSystem.bInJoinLobbyTeam            = false
GVoiceSDKSystem.pJoinLobbyTeamTimeOut       = nil
GVoiceSDKSystem.pJoinTeamDelayTimer         = nil
GVoiceSDKSystem.pJoinAllDelayTimer          = nil
GVoiceSDKSystem.pJoinLobbyTeamDelayTimer    = nil
GVoiceSDKSystem.nMemberId                   = nil
GVoiceSDKSystem.SyncMemberIdTimerHandle     = nil
GVoiceSDKSystem.nLobbyTeamReconnectCount    = 0
GVoiceSDKSystem.nTeamReconnectCount         = 0
GVoiceSDKSystem.nAllReconnectCount          = 0
GVoiceSDKSystem.bMicEnable                  = false
GVoiceSDKSystem.TeamInfoChangeEvent         = nil
GVoiceSDKSystem.TeamInfoSyncEvent           = nil
GVoiceSDKSystem.CheckSelfMicTimerHandle     = nil
GVoiceSDKSystem.GetMemberInfoDelegate       = nil
GVoiceSDKSystem.tbTeamMemberIds             = nil
GVoiceSDKSystem.pRejoinTimerHandle          = nil
-----------------------------------------------------
--begin*************************************************
--MISC

local function IsSameTableValue(t1, t2)
    if not t1 or not t2 or type(t1) ~= "table" or type(t2) ~= "table" then
        return false
    end
    if #t1 ~= #t2 then
        return false
    end
    for k1, val1 in ipairs(t1) do
        local bInclude = false
        for k2, val2 in ipairs(t2) do
            if val1 == val2 then
                bInclude = true
            end
        end
        if not bInclude then
            return false
        end
    end
    return true
end

local function ClearRejoinTimer(self)
    if self.pRejoinTimerHandle then
        DelayTimer:ClearTimer(self.pRejoinTimerHandle)
        self.pRejoinTimerHandle = nil
    end
end

local function ClearJoinLobbyTeamTimer(self)
    if self.pJoinLobbyTeamTimeOut then
        DelayTimer:ClearTimer(self.pJoinLobbyTeamTimeOut)
        self.pJoinLobbyTeamTimeOut = nil
    end
end

local function ClearJoinTeamTimer(self)
    if self.pJoinTeamDelayTimer then
        DelayTimer:ClearTimer(self.pJoinTeamDelayTimer)
        self.pJoinTeamDelayTimer = nil
    end
end

local function ClearJoinAllTimer(self)
    if self.pJoinAllDelayTimer then
        DelayTimer:ClearTimer(self.pJoinAllDelayTimer)
        self.pJoinAllDelayTimer = nil
    end
end

local function SetLobbyTeamRoomName(self, szId)
    local szName = "LOBBYTEAMROOMNAME_" .. tostring(szId)
    self.szLobbyTeamRoomName = szName
    self.bInJoinLobbyTeam = true
    ClearJoinLobbyTeamTimer(self)
    self.pJoinLobbyTeamTimeOut = DelayTimer:DelayRun(function() GVoiceDebug:DebugLog("Join Lobby Team Room Time Out!") self.bInJoinLobbyTeam = false  end, JOIN_ROOM_TIME_OUT)
    return szName
end

local function SetAllRoomName(self, szId)
    local szName = "ALLROOMNAME_" .. tostring(szId)
    self.szAllRoomName = szName
    self.bInJoinAll = true
    ClearJoinAllTimer(self)
    self.pJoinAllDelayTimer = DelayTimer:DelayRun(function() GVoiceDebug:DebugLog("Join All Room Time Out!") self.bInJoinAll = false end, JOIN_ROOM_TIME_OUT)
    return szName
end

local function SetTeamRoomName(self, szDungeonId ,szTeamId)
    local szName = "TEAMROOMNAME_" .. tostring(szDungeonId) .. "_" .. tostring(szTeamId)
    self.bInJoinTeam = true
    self.szTeamRoomName = szName
    ClearJoinTeamTimer(self)
    self.pJoinTeamDelayTimer = DelayTimer:DelayRun(function() GVoiceDebug:DebugLog("Join Team Room Time Out!") self.bInJoinTeam = false end, JOIN_ROOM_TIME_OUT)
    return szName
end

local function CheckValidDungeon(self)
    local nDungeonId = BattleGameModeSystem:GetCurrentDungeonId()
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        GVoiceDebug:DebugLog("Guide Singel dungeon invalid!")
        return false
    else
        GVoiceDebug:DebugLog("Guide Singel dungeon Valid!")
        return true
    end
end

local function CheckSdkManagerValid(self)
    if self.pGVoiceSdkManager then
        return true
    end
    GVoiceDebug:DebugLog("GVoiceSdkManager is invalid!")
    return false
end

-- local function SendMemberIdToTeam(self, nMemberId)
--     local nPlayerId =  GlobalVariableSystem.nSelfLobbyPlayerId
--     GVoiceDebug:DebugLog("Player self nPlayerId id is " .. tostring(nPlayerId) .. " type = " .. type(nPlayerId) .. " nMemberId = " .. tostring(nMemberId) .. " type = " .. type(nMemberId))
--     local tbPacket = {
--         instance_id = nPlayerId,
--         member_Id = nMemberId
--     }
--     GVoiceDebug:DebugLog("SendToServer(ProtoD.c2d_ChatRoomMemberId, tbPacket)")
--     NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoD.c2d_ChatRoomMemberId, tbPacket)
-- end

local function ClearSyncMemberIdTimer(self)
    if self.SyncMemberIdTimerHandle then
        self.TimerHelper:ClearTimer(self.SyncMemberIdTimerHandle)
    end
    self.SyncMemberIdTimerHandle = nil
end

-- local function SyncMemberId(self)
--     local nMemberId = self.nMemberId
--     if not nMemberId then
--         return
--     end
--     GVoiceDebug:DebugLog("SyncMemberId")
--     ClearSyncMemberIdTimer(self)
--     self.SyncMemberIdTimerHandle = self.TimerHelper:NewTimerMethod(self, function() SendMemberIdToTeam(self, nMemberId) end, SYNC_MEMBER_ID_INTERVAL, true)
-- end

local function ClearCheckSelfMicTimer(self)
    if self.CheckSelfMicTimerHandle then
        self.TimerHelper:ClearTimer(self.CheckSelfMicTimerHandle)
        self.CheckSelfMicTimerHandle = nil
    end
end

local function CheckSelfMic(self)
    GVoiceDebug:DebugLog("CheckSelfMicLevel")
    ClearCheckSelfMicTimer(self)
    self.CheckSelfMicTimerHandle = self.TimerHelper:NewTimerMethod(self, function() self:CheckIsSpeaking() end, CHECK_SELF_SPEAKING, true)
end

function GVoiceSDKSystem:CheckMicEnable()
    local bEnable = self.bMicEnable
    if not bEnable then
        bEnable = self:TestMic()
        self.bMicEnable = bEnable
    end
    return bEnable
end

function GVoiceSDKSystem.GetAllSortedPlayerIds()
    local tbPlayer = GamePlayerSelfHelper:Get()
    if not tbPlayer then
        return nil
    end  
    local BattleTeamComponent = tbPlayer.BattleTeamComponent
    if not BattleTeamComponent then 
        return nil
    end
    local tbPlayerIds = BattleTeamComponent:GetAllSortedPlayerIds()
    if not tbPlayerIds then
        return nil
    end
    return tbPlayerIds
end

function GVoiceSDKSystem.GetTeamPlayerIds()
    local bInDungeon = GlobalVariableSystem:IsInDungeon()
    if bInDungeon then
        local tbPlayerIds = GVoiceSDKSystem.GetAllSortedPlayerIds()
        return tbPlayerIds
    else
        return TeamSystem:GetTeamMemberIds()
    end
end

function GVoiceSDKSystem.GetTeamPlayerCount()
    local bInDungeon = GlobalVariableSystem:IsInDungeon()
    if bInDungeon then
        local tbPlayerIds = GVoiceSDKSystem.GetAllSortedPlayerIds()
        if not tbPlayerIds then
            return nil
        end
        return #tbPlayerIds
    else
        return #TeamSystem:GetTeamMemberIds()
    end
end

function GVoiceSDKSystem.IsSelfSinglePlayer()
    local nPlayerCount = GVoiceSDKSystem.GetTeamPlayerCount()
    nPlayerCount = not nPlayerCount and 1 or nPlayerCount
    local tbTeamPlayers = GVoiceSDKSystem.GetTeamPlayerIds()
    local nPlayerCountReal = not tbTeamPlayers and 1 or #tbTeamPlayers
    local nCurrentMaxTeamCount = math.max(nPlayerCount, nPlayerCountReal)
    return nCurrentMaxTeamCount == 1
end

local function OnFFATeamChanged(self)
    GVoiceDebug:DebugLog("OnFFATeamChanged")
    -- local nRealCount = #GVoiceSDKSystem.GetTeamPlayerIds()
    -- local nPlayerCount = GVoiceSDKSystem.GetTeamPlayerCount()
    -- GVoiceDebug:DebugLog("OnFFATeamChanged! nPlayerCount = " .. nPlayerCount .. " nRealCount = " .. nRealCount)
    -- if self.szTeamChangeEvent then
    --     self.EventHelper:UnregisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamChanged)
    --     self.szTeamChangeEvent = nil
    -- end
    if self.bInJoinTeam or self.bJoinTeamRoomSucess then
        return
    end
    local tbTeamPlayers = GVoiceSDKSystem.GetTeamPlayerIds()
    if not self.tbTeamMemberIds then
        self.tbTeamMemberIds = tbTeamPlayers
        self:JoinBattleTeamRoom()
        return
    end
    if not IsSameTableValue(self.tbTeamMemberIds, tbTeamPlayers) then
        self.tbTeamMemberIds = tbTeamPlayers
        self:JoinBattleTeamRoom()
    end
end

local function QuitAllRooms(self)
    self:EnableMic(false)
    self:EnableSpeaker(false)
    
    if self.szTeamRoomName then
        self:EnableRoomMicrophone(self.szTeamRoomName, false)
        self:EnableRoomSpeaker(self.szTeamRoomName, false)
        self:QuitRoom(self.szTeamRoomName)
    end

    if self.szAllRoomName then
        self:EnableRoomMicrophone(self.szAllRoomName, false)
        self:EnableRoomSpeaker(self.szAllRoomName, false)
        self:QuitRoom(self.szAllRoomName)
    end
end

local function ResetLobbyTeamRoomData(self)
    self.bInJoinLobbyTeam = false
    self.bJoinLobbyTeamRoomSucess = false
    self.szLobbyTeamRoomName = nil
    self.nLobbyTeamReconnectCount = 0
    self.tbMemberIdToPlayerId = {}
end

local function OnTeamInfoSync(self, tbPacket)
    GVoiceDebug:DebugLog("OnTeamInfoSync")
    if self.bInJoinLobbyTeam or self.bJoinLobbyTeamRoomSucess then
        return
    end
    self:JoinLobbyTeamRoom()
end

local function OnTeamInfoChange(self, tbPacket)
    GVoiceDebug:DebugLog("OnTeamInfoChange")
    local nPlayerId =  GlobalVariableSystem.nSelfLobbyPlayerId
    if  tbPacket.change_type == Proto.ChangeType.LEAVE_TEAM then
        if tbPacket.player_id == nPlayerId then
            self:QuitLobbyTeamRoom()
            ResetLobbyTeamRoomData(self)
        end
    elseif tbPacket.change_type == Proto.ChangeType.KICK_OUT_TEAM then
        if tbPacket.player_id == nPlayerId then
            self:QuitLobbyTeamRoom()
            ResetLobbyTeamRoomData(self)
        end
    elseif tbPacket.change_type == Proto.ChangeType.DISMISS then
        self:QuitLobbyTeamRoom()
        ResetLobbyTeamRoomData(self)
    end
end

local function BindTeamInfoEvent(self)
    GVoiceDebug:DebugLog("BindTeamInfoEvent")
    local EventHelper = self.EventHelper
    self.TeamInfoChangeEvent = EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED, self,  OnTeamInfoChange)
    self.TeamInfoSyncEvent = EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_SYNC, self, OnTeamInfoSync)
end

local function UnBindTeamInfoEvent(self)
    GVoiceDebug:DebugLog("UnBindTeamInfoEvent")
    local EventHelper = self.EventHelper
    if self.TeamInfoChangeEvent then
        EventHelper:UnregisterEvent(ClientEventDef.EV_TEAM_CHANGED, self,  OnTeamInfoChange)
        self.TeamInfoChangeEvent = nil
    end
    if self.TeamInfoSyncEvent then
        EventHelper:UnregisterEvent(ClientEventDef.EV_TEAM_SYNC, self, OnTeamInfoSync)
        self.TeamInfoSyncEvent = nil
    end
end

local function GetTeamComponent(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local TeamComponent = PlayerSelf.TeamComponent
    return TeamComponent
end

local function ShowErrorReasonToast(szDesKey, nErrorCode)
    if nErrorCode ~= 0 then
        local strErrorCode = L10N:Format(UISetUtils.GetL10NTextByKey("VOICE_ERROR_CODE"), nErrorCode)
        local strReason
        if szDesKey == nil or szDesKey == "" then
            strReason = strErrorCode
        else
            strReason = L10N:Format(UISetUtils.GetL10NTextByKey(szDesKey), strErrorCode)
        end
        GVoiceDebug:DebugLog(L10N:ToString(strReason))
        --UIUtils.ShowToast(strReason)
    end
end

local function TransformToPlatformMicVol(nVol)
    local nPlatformVol = nVol*150 -- -150 ~ 150
    nPlatformVol = math.modf(nPlatformVol)
    GVoiceDebug:DebugLog("TransformToPlatformMicVol nVol = " .. nVol .. " nPlatformVol = " .. nPlatformVol)
    return nPlatformVol
end

local function TransformToPlatformSpeakerVol(nVol)
    local nPlatformVol = nVol*150 -- 0 ~ 150
    nPlatformVol = math.modf(nPlatformVol)
    GVoiceDebug:DebugLog("TransformToPlatformSpeakerVol nVol = " .. nVol .. " nPlatformVol = " .. nPlatformVol)
    return nPlatformVol
end

local function IsInJoinRoom(self, szRoomName)
    if self.szAllRoomName == szRoomName then
        return self.bInJoinAll, ALL_ROOM_TYPE
    elseif self.szTeamRoomName == szRoomName then
        return self.bInJoinTeam, TEAM_ROOM_TYPE
    elseif self.szLobbyTeamRoomName == szRoomName then
        return self.bInJoinLobbyTeam, TEAM_LOBBY_TYPE
    end
end

local function JoinRoomType(self, szRoomName)
    if self.szAllRoomName == szRoomName then
        return ALL_ROOM_TYPE
    elseif self.szTeamRoomName == szRoomName then
        return TEAM_ROOM_TYPE
    elseif self.szLobbyTeamRoomName == szRoomName then
        return TEAM_LOBBY_TYPE
    end
end

--end*************************************************
--MISC

--begin*************************************************
--切场景自动加入房间操作

local function OnEnterBattle(self, bRetraveling)
    GVoiceDebug:DebugLog("OnEnterBattle bRetraveling = " .. tostring(bRetraveling))
    if not CheckValidDungeon(self) then
        return
    end
    if not bRetraveling then
        self:EnableMultiRoom(true)
    end
    self.bInRetraveling = bRetraveling
    self.bInDungeon = true
end

local function OnEnterDungeon(self)
    GVoiceDebug:DebugLog("OnEnterDungeon")
    if not CheckValidDungeon(self) then
        return
    end
    if self.bInRetraveling then
        GVoiceDebug:DebugLog("enter dungeon bRetraveling pass! ")
        return
    end
    self:StartPoll()
    local bResult = self:JoinBattleAllRoom()
    if bResult then
        GVoiceDebug:DebugLog("JoinRoom Success!")
    else
        GVoiceDebug:DebugLog("JoinRoom Failed!")
    end
    if not self.szTeamChangeEvent then
        self.szTeamChangeEvent = self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamChanged)
    end
end

local function OnLevelBattle(self, bRetraveling)
    GVoiceDebug:DebugLog("OnLevelBattle! bRetraveling = " .. tostring(bRetraveling))
    self.bInRetraveling = bRetraveling
    if bRetraveling then
        GVoiceDebug:DebugLog("leavel in retraveling pass!")
        return
    end
    if not CheckValidDungeon(self) then
        return
    end
    self.bInDungeon = false
    QuitAllRooms(self)
    if self.szTeamChangeEvent then
        GVoiceDebug:DebugLog("UnregisterEvent EV_FFA_TEAM_INFO_CHANGED")
        self.EventHelper:UnregisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamChanged)
        self.szTeamChangeEvent = nil
    end
    self.szTeamRoomName = nil
    self.szAllRoomName = nil
    self.bInRetraveling = nil
    self.bInJoinTeam = false
    self.bInJoinAll = false
    self.bJoinAllRoomSucess = false
    self.bJoinTeamRoomSucess = false
    self.nMemberId = nil
    self.nTeamReconnectCount = 0
    self.nAllReconnectCount = 0
    self.tbTeamMemberIds = nil
    ClearRejoinTimer(self)
    ClearJoinAllTimer(self)
    ClearJoinTeamTimer(self)
    ClearSyncMemberIdTimer(self)
    ClearCheckSelfMicTimer(self)
    self:ClearPollTimer()
    self.tbMemberIdToPlayerId = {}
end

local function OnLevelLobby(self)
    GVoiceDebug:DebugLog("OnLevelLobby")
    self:QuitLobbyTeamRoom()
    UnBindTeamInfoEvent(self)
    ResetLobbyTeamRoomData(self)
    self:ClearPollTimer()
end

local function OnEnterLobby(self)
    GVoiceDebug:DebugLog("OnEnterLobby")
    ResetLobbyTeamRoomData(self)
    BindTeamInfoEvent(self)
    self:StartPoll()
    self:EnableMultiRoom(false)
    self:JoinLobbyTeamRoom()
end

--end*************************************************
--切场景自动加入房间操作

--begin*************************************************
--GVoice接口暴露
function GVoiceSDKSystem:InitWithPlayerID(szOpenId)
    if not CheckSdkManagerValid(self) then
        return false
    end
    local szAppID = "217221021"
    local szAppKey = "824871adb3277c4e9747c56395bf6276"
    self:InitWithAppInfo(szAppID, szAppKey, szOpenId)
end

function GVoiceSDKSystem:InitWithAppInfo(szAppID, szAppKey, szOpenId)
    GVoiceDebug:DebugLog("InitWithAppInfo!")
    if not self:SetAppInfo(szAppID, szAppKey, szOpenId) then
        GVoiceDebug:DebugLog("SetAppInfo faild!")
        return false
    end
    if not self:InitEngine() then
        GVoiceDebug:DebugLog("InitEngine faild!")
        return false
    end
    if not self:SetMode(GVoiceViceMode.GVRealTime) then
        GVoiceDebug:DebugLog("SetMode faild!")
        return false
    end
    if not self:SetNotify() then
        GVoiceDebug:DebugLog("SetNotify faild!")
        return false
    end
    -- self:TestMic()
    self:StartPoll()
end

function GVoiceSDKSystem:InitEngine()
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pGVoiceSdkManager:InitEngine()
end

function GVoiceSDKSystem:SetAppInfo(szAppID, szAppKey, szOpenId)
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pGVoiceSdkManager:SetAppInfo(szAppID, szAppKey, szOpenId)
end

function GVoiceSDKSystem:SetMode(VoiceMode)
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pGVoiceSdkManager:SetMode(VoiceMode)
end

function GVoiceSDKSystem:SetNotify()
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pGVoiceSdkManager:SetNotify()
end

function GVoiceSDKSystem:TestMic()
    GVoiceDebug:DebugLog("TestMic.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nResultCode = self.pGVoiceSdkManager:TestMic()
    ShowErrorReasonToast("", nResultCode)
    return nResultCode == 0
end

function GVoiceSDKSystem:StartPoll()
    GVoiceDebug:DebugLog("StartPoll.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    self:ClearPollTimer()
    self.PollTimerHandle = self.TimerHelper:NewTimerMethod(self, function() self:PollTimerFunc() end, 0.5, true)
end

function GVoiceSDKSystem:ClearPollTimer()
    GVoiceDebug:DebugLog("ClearPollTimer.")
    if self.PollTimerHandle then
        self.TimerHelper:ClearTimer(self.PollTimerHandle)
        self.PollTimerHandle = nil
        
    end
end

function GVoiceSDKSystem:PollTimerFunc()
    if CheckSdkManagerValid(self) then
        self.pGVoiceSdkManager:Poll()
    end
end

function GVoiceSDKSystem:JoinTeamRoom(szRoomName)
    GVoiceDebug:DebugLog("JoinTeamRoom.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:JoinTeamRoom(szRoomName)
    ShowErrorReasonToast("VOICE_JOIN_TEAM_ROOM_ERROR", nErrorCode)
    return nErrorCode == 0 or nErrorCode == GCLOUD_VOICE_ALREADY_IN_ROOM
end

function GVoiceSDKSystem:JoinRangeRoom(szRoomName)
    GVoiceDebug:DebugLog("JoinRangeRoom.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:JoinRangeRoom(szRoomName)
    ShowErrorReasonToast("VOICE_JOIN_RANGE_ROOM_ERROR", nErrorCode)
    return nErrorCode == 0
end

function GVoiceSDKSystem:QuitRoom(szRoomName)
    if not CheckSdkManagerValid(self) then
        return false
    end
    GVoiceDebug:DebugLog("QuitRoom:" .. tostring(szRoomName))
    local nErrorCode = self.pGVoiceSdkManager:QuitRoom(szRoomName)
    ShowErrorReasonToast("VOICE_QUIT_ROOM_ERROR", nErrorCode)
    return nErrorCode == 0
end

function GVoiceSDKSystem:EnableMic(bEnable)
    GVoiceDebug:DebugLog("EnableMic.")
    if bEnable then
        return self:OpenMic()
    else
        return self:CloseMic()
    end
end

function GVoiceSDKSystem:OpenMic()
    GVoiceDebug:DebugLog("OpenMic.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:OpenMic()
    ShowErrorReasonToast("VOICE_OPEN_MIC_ERROR", nErrorCode)
    return nErrorCode == 0
end

function GVoiceSDKSystem:CloseMic()
    GVoiceDebug:DebugLog("CloseMic.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:CloseMic()
    ShowErrorReasonToast("VOICE_CLOSE_MIC_ERROR", nErrorCode)
    return nErrorCode == 0
end

function GVoiceSDKSystem:SetMicVolume(nVol)
    GVoiceDebug:DebugLog("SetMicVolume.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nTransformVol = TransformToPlatformMicVol(nVol)
    local nErrorCode = self.pGVoiceSdkManager:SetMicVolume(nTransformVol)
    ShowErrorReasonToast("", nErrorCode)
    return nErrorCode == 0
end

function GVoiceSDKSystem:SetSpeakerVolume(nVol)
    GVoiceDebug:DebugLog("SetSpeakerVolume.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nTransformVol = TransformToPlatformSpeakerVol(nVol)
    local nErrorCode = self.pGVoiceSdkManager:SetSpeakerVolume(nTransformVol)
    ShowErrorReasonToast("", nErrorCode)
    return nErrorCode == 0
end

function GVoiceSDKSystem:GetMicLevel()
    GVoiceDebug:DebugLog("GetMicLevel.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pGVoiceSdkManager:GetMicLevel()
end

function GVoiceSDKSystem:GetSpeakerLevel()
    GVoiceDebug:DebugLog("GetSpeakerLevel.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    return self.pGVoiceSdkManager:GetSpeakerLevel()
end

function GVoiceSDKSystem:EnableSpeaker(bEnable)
    GVoiceDebug:DebugLog("EnableSpeaker.")
    if bEnable then
        return self:OpenSpeaker()
    else
        return self:CloseSpeaker()
    end
end

function GVoiceSDKSystem:OpenSpeaker()
    GVoiceDebug:DebugLog("OpenSpeaker.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:OpenSpeaker()
    ShowErrorReasonToast("VOICE_OPEN_SPEAKER_ERROR", nErrorCode)
    return nErrorCode == 0
end

function GVoiceSDKSystem:CloseSpeaker()
    GVoiceDebug:DebugLog("CloseSpeaker.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:CloseSpeaker()
    ShowErrorReasonToast("VOICE_CLOSE_SPEAKER_ERROR", nErrorCode)
    return nErrorCode == 0
end

function GVoiceSDKSystem:ForbidMemberVoice(nMemberId, bEnable, szRoomName)
    GVoiceDebug:DebugLog("ForbidMemberVoice.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    if not nMemberId or not szRoomName then
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:ForbidMemberVoice(nMemberId, bEnable, szRoomName)
    ShowErrorReasonToast("VOICE_FORBID_MEMBER_ERROR", nErrorCode)
    return nErrorCode == 0
end

function GVoiceSDKSystem:EnableMultiRoom(bEnable)
    GVoiceDebug:DebugLog("EnableMultiRoom.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:EnableMultiRoom(bEnable)
    ShowErrorReasonToast("VOICE_MULTI_ROOM_ERROR", nErrorCode)
    return nErrorCode == 0
end

function GVoiceSDKSystem:EnableRoomMicrophone(szRoomName, bEnable)
    GVoiceDebug:DebugLog("EnableRoomMicrophone." .. tostring(bEnable))
    if not CheckSdkManagerValid(self) then
        return false
    end
    if GVoiceSDKSystem.IsSelfSinglePlayer() and szRoomName == self.szTeamRoomName then
        return true
    end
    local bInJoin, nRoomType = IsInJoinRoom(self, szRoomName)
    if bInJoin then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("VOICE_IN_JOIN"))
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:EnableRoomMicrophone(szRoomName, bEnable)
    if GCLOUD_VOICE_REALTIME_STATE_ERR == nErrorCode or GCLOUD_VOICE_ROOM_NAME_NOT_SAME == nErrorCode then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("VOICE_NOT_JOIN_ROOM"))
        self:ReJoinRoom(nRoomType)
    elseif 0 ~= nErrorCode then
        ShowErrorReasonToast("VOICE_OPEN_MIC_ERROR", nErrorCode)
        local nDungenUUId = BattleGameModeSystem:GetDungeonSessionId()
        GVoiceDebug:DebugLog("new dungenUUID = " .. tostring(nDungenUUId))
        local __, nTeamId = TeamWatchClientHelper.GetOriginalTeamInfo()
        GVoiceDebug:DebugLog("new team id = " .. tostring(nTeamId))
    end
    return nErrorCode == 0
end

function GVoiceSDKSystem:EnableRoomSpeaker(szRoomName, bEnable)
    GVoiceDebug:DebugLog("EnableRoomSpeaker." .. tostring(bEnable))
    if not CheckSdkManagerValid(self) then
        return false
    end
    if GVoiceSDKSystem.IsSelfSinglePlayer() and szRoomName == self.szTeamRoomName then
        return true
    end
    local bInJoin, nRoomType = IsInJoinRoom(self, szRoomName)
    if bInJoin then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("VOICE_IN_JOIN"))
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:EnableRoomSpeaker(szRoomName, bEnable)
    if GCLOUD_VOICE_REALTIME_STATE_ERR == nErrorCode or GCLOUD_VOICE_ROOM_NAME_NOT_SAME == nErrorCode then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("VOICE_NOT_JOIN_ROOM"))
        self:ReJoinRoom(nRoomType)
    elseif 0 ~= nErrorCode then
        ShowErrorReasonToast("VOICE_OPEN_SPEAKER_ERROR", nErrorCode)
        local nDungenUUId = BattleGameModeSystem:GetDungeonSessionId()
        GVoiceDebug:DebugLog("new dungenUUID = " .. tostring(nDungenUUId))
        local __, nTeamId = TeamWatchClientHelper.GetOriginalTeamInfo()
        GVoiceDebug:DebugLog("new team id = " .. tostring(nTeamId))
    end
    return nErrorCode == 0
end

function GVoiceSDKSystem:EnableCurrentAllRoomMicrophone(bEnable)
    GVoiceDebug:DebugLog("EnableCurrentAllRoomMicrophone. Room name = " .. tostring(self.szAllRoomName))
    return self:EnableRoomMicrophone(self.szAllRoomName, bEnable)
end

function GVoiceSDKSystem:EnableCurrentTeamRoomMicrophone(bEnable)
    GVoiceDebug:DebugLog("EnableCurrentTeamRoomMicrophone. Room name = " .. tostring(self.szTeamRoomName))
    return self:EnableRoomMicrophone(self.szTeamRoomName, bEnable)
end

function GVoiceSDKSystem:EnableCurrentAllRoomSpeaker(bEnable)
    GVoiceDebug:DebugLog("EnableCurrentAllRoomSpeaker. Room name = " .. tostring(self.szAllRoomName))
    return self:EnableRoomSpeaker(self.szAllRoomName, bEnable)
end

function GVoiceSDKSystem:EnableCurrentTeamRoomSpeaker(bEnable)
    GVoiceDebug:DebugLog("EnableCurrentTeamRoomSpeaker. Room name = " .. tostring(self.szTeamRoomName))
    return self:EnableRoomSpeaker(self.szTeamRoomName, bEnable)
end

local function CheckPlayerIdValid(value)
    if not value then
        return false
    end
    local nId = tonumber(value)
    if not nId then
        return false
    end
    return nId > 0
end

function GVoiceSDKSystem:SetVoiceMemberidToPlayerId(nMemberId, szPlayerId)
    GVoiceDebug:DebugLog("SetVoiceMemberidToPlayerId. " .. tostring(szPlayerId) .. " nMemberId = " .. tostring(nMemberId))
    if not CheckPlayerIdValid(szPlayerId) then
        return
    end
    if not szPlayerId or not self.tbMemberIdToPlayerId then
        return
    end
    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_VOICE_MEMBER_ID_CHANGE)
    self.tbMemberIdToPlayerId[szPlayerId] = nMemberId
end

function GVoiceSDKSystem:GetCurrentTeamRoomName()
    return self.szTeamRoomName
end

function GVoiceSDKSystem:GetCurrentAllRoomName()
    return self.szAllRoomName
end

function GVoiceSDKSystem:GetVoiceMemberId(szRoomName, szPlayerId)
    GVoiceDebug:DebugLog("GetVoiceMemberId. " .. tostring(szPlayerId))
    if not szPlayerId or not self.tbMemberIdToPlayerId then
        GVoiceDebug:DebugLog("GetVoiceMemberidToPlayerId. nil nil nil nil")
        return nil
    end
    local nMemberId = self.tbMemberIdToPlayerId[szPlayerId]
    if not nMemberId then
        self:GetRoomMembers(szRoomName)
    end
    return nMemberId
end

function GVoiceSDKSystem:GetMemberPlayerId(nMemberId)
    -- GVoiceDebug:DebugLog("GetMemberPlayerId. " .. tostring(nMemberId))
    if not nMemberId or not self.tbMemberIdToPlayerId then
        GVoiceDebug:DebugLog("GetMemberPlayerId. nil")
        return nil
    end
    for k,v in pairs(self.tbMemberIdToPlayerId) do
        if v == nMemberId then
            return k
        end
    end
    return nil
end

function GVoiceSDKSystem:CheckIsSpeaking()
    local ret = self:IsSpeaking()
    if ret then
        local nSelfPlayerId =  GlobalVariableSystem.nSelfLobbyPlayerId
        local tbPlayerIds = GVoiceSDKSystem.GetTeamPlayerIds()
        local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
        if bIsInDungeon then
            if not tbPlayerIds then
                return
            end
            for index, nPlayerId in ipairs(tbPlayerIds) do
                if nSelfPlayerId == nPlayerId then
                    EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE_STATE, index, 1)
                end
            end            
        else
            EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE_STATE, nil, 1, nSelfPlayerId)
        end
    end
end

function GVoiceSDKSystem:IsSpeaking()
    -- GVoiceDebug:DebugLog("IsSpeaking.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local ret = self.pGVoiceSdkManager:IsSpeaking()
    -- GVoiceDebug:DebugLog("ret = " .. tostring(ret))
    return ret
end

function GVoiceSDKSystem:GetMicLevel(bFadeOut)
    -- GVoiceDebug:DebugLog("GetMicLevel.")
    if not CheckSdkManagerValid(self) then
        return -1
    end
    local ret = self.pGVoiceSdkManager:GetMicLevel(true)
    -- GVoiceDebug:DebugLog("ret = " .. tostring(ret))
    return ret
end

local function RejoinRoomDelayCallFunc(self, nRoomType)
    GVoiceDebug:DebugLog("RejoinRoomDelayCallFunc nRoomType =  " .. nRoomType)
    if nRoomType == TEAM_ROOM_TYPE then
        local nTeamReconnectCount = self.nTeamReconnectCount
        if nTeamReconnectCount > MAX_RECONNECT_COUNT then
            self.nTeamReconnectCount = 0
        else
            self.nTeamReconnectCount = nTeamReconnectCount + 1
            self:JoinBattleTeamRoom()
        end
    elseif nRoomType == ALL_ROOM_TYPE then
        local nAllReconnectCount = self.nAllReconnectCount
        if nAllReconnectCount > MAX_RECONNECT_COUNT then
            self.nAllReconnectCount = 0
        else
            self.nAllReconnectCount = nAllReconnectCount + 1
            self:JoinBattleAllRoom()
        end
    elseif nRoomType == TEAM_LOBBY_TYPE then
        local nLobbyTeamReconnectCount = self.nLobbyTeamReconnectCount
        if nLobbyTeamReconnectCount > MAX_RECONNECT_COUNT then
            self.nLobbyTeamReconnectCount = 0
        else
            self.nLobbyTeamReconnectCount = nLobbyTeamReconnectCount + 1
            self:JoinLobbyTeamRoom()
        end
    end
end

function GVoiceSDKSystem:ReJoinRoom(nRoomType)
    GVoiceDebug:DebugLog("ReJoinRoom" .. nRoomType)
    ClearRejoinTimer(self)
    self.pRejoinTimerHandle = DelayTimer:DelayRun(function() RejoinRoomDelayCallFunc(self, nRoomType) end, DELAY_CALL_REJOINT)
end

function GVoiceSDKSystem:QuitLobbyTeamRoom()
    GVoiceDebug:DebugLog("QuitLobbyTeamRoom")
    self:QuitRoom(self.szLobbyTeamRoomName)
    self:EnableMic(false)
    self:EnableSpeaker(false)
    ClearJoinLobbyTeamTimer(self)
    ClearCheckSelfMicTimer(self)
end

function GVoiceSDKSystem:JoinLobbyTeamRoom()
    local TeamComponent = GetTeamComponent(self)
    if not TeamComponent then
        return
    end
    local nTeamId = TeamComponent.nTeamId
    if not nTeamId then
        return
    end
    if self.bInJoinLobbyTeam then
        return
    end
    local szRoomName = SetLobbyTeamRoomName(self, nTeamId)
    GVoiceDebug:DebugLog("szLobbyTeamRoomName ==  " .. tostring(szRoomName))
    local bResult = self:JoinTeamRoom(szRoomName)
    if not bResult then
        GVoiceDebug:DebugLog("JoinLobbyTeamRoom Failed!")
        ClearJoinLobbyTeamTimer(self)
        self.bInJoinLobbyTeam = false
        self:ReJoinRoom(TEAM_LOBBY_TYPE)
    end
    return bResult
end

function GVoiceSDKSystem:JoinBattleTeamRoom()
    local bSingle = GVoiceSDKSystem.IsSelfSinglePlayer()
    GVoiceDebug:DebugLog("OnFFATeamChanged! nTeamPlayerCount = " .. tostring(bSingle))
    if not bSingle then
        local tbTeamInfo, nTeamId = TeamWatchClientHelper.GetOriginalTeamInfo()
        GVoiceDebug:DebugLog("nTeamId ==  " .. tostring(nTeamId) .. "tbTeamInfo = " .. tostring(tbTeamInfo))
        if not tbTeamInfo or not nTeamId then
            return
        end
        local nDungenUUId = BattleGameModeSystem:GetDungeonSessionId()
        if not nDungenUUId then
            nDungenUUId = 0
        end
        if self.bInJoinTeam then
            return
        end
        local szRoomName = SetTeamRoomName(self, nDungenUUId, nTeamId)
        GVoiceDebug:DebugLog("szRoomName ==  " .. tostring(szRoomName))
        local bResult = self:JoinTeamRoom(szRoomName)
        if not bResult then
            GVoiceDebug:DebugLog("JoinRoom Failed!")
            ClearJoinTeamTimer(self)
            self.bInJoinTeam = false
            self:ReJoinRoom(TEAM_ROOM_TYPE)
        end
    else
        EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_VOICE_SINGLE_PLAYER)
    end
end

function GVoiceSDKSystem:JoinBattleAllRoom()
    GVoiceDebug:DebugLog("JoinBattleAllRoom!")
    local nDungenUUId = BattleGameModeSystem:GetDungeonSessionId()
    if not nDungenUUId then
        nDungenUUId = 0
    end
    if self.bInJoinAll then
        return
    end
    local szName = SetAllRoomName(self, nDungenUUId)
    GVoiceDebug:DebugLog("szAllRoomName ==  " .. szName)
    local bResult = self:JoinTeamRoom(szName)
    if not bResult then
        ClearJoinAllTimer(self)
        self.bInJoinAll = false
        self:ReJoinRoom(ALL_ROOM_TYPE)
    end
    return bResult
end

function GVoiceSDKSystem:GetRoomMembers(szRoomName)
    GVoiceDebug:DebugLog("GetRoomMembers.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:GetRoomMembers(szRoomName, 4)
    ShowErrorReasonToast("", nErrorCode)
end

function GVoiceSDKSystem:GetManager()
    return self.pGVoiceSdkManager
end

function GVoiceSDKSystem:SetBitRate(nRate)
    GVoiceDebug:DebugLog("SetBitRate.")
    if not CheckSdkManagerValid(self) then
        return false
    end
    local nErrorCode = self.pGVoiceSdkManager:SetBitRate(nRate)
    ShowErrorReasonToast("", nErrorCode)
end

--end*************************************************
--GVoice接口暴露

--begin*************************************************
--GVoice notify接口
local function SetVoiceDefaultOption(self)
    GVoiceDebug:DebugLog("Set Voice Default Option!")
    GVoiceOpCtrlHelper.SetMultiRoomMic(self)
    GVoiceOpCtrlHelper.SetMultiRoomSpeaker(self)
    GVoiceDebug:DebugLog("ready to open mic " .. tostring(GVoiceOpCtrlHelper.ReadyToOpenMic(self)))
    self:EnableSpeaker(GVoiceOpCtrlHelper.ReadyToOpenSpeaker(self))
    self:EnableMic(GVoiceOpCtrlHelper.ReadyToOpenMic(self))
end

local function OnJoinRoom(self, nCompleteCode, szRoomName, nMemberId)
    local nType = JoinRoomType(self, szRoomName)
    if nCompleteCode ~= GCLOUD_VOICE_JOINT_ROOM_SUCC then
        local strReason = ""
        local strErrorCode = L10N:Format(UISetUtils.GetL10NTextByKey("VOICE_ERROR_CODE"), nCompleteCode)
        if nType == TEAM_ROOM_TYPE then
            self.bJoinTeamRoomSucess = false
            self.bInJoinTeam = false
            strReason = L10N:Format(UISetUtils.GetL10NTextByKey("VOICE_TEAM_ROOM_ERROR"), strErrorCode)
        elseif nType == ALL_ROOM_TYPE then 
            self.bJoinAllRoomSucess = false
            self.bInJoinTeam = false
            strReason = L10N:Format(UISetUtils.GetL10NTextByKey("VOICE_ALL_ROOM_ERROR"), strErrorCode)
        elseif nType == TEAM_LOBBY_TYPE then
            self.bJoinLobbyTeamRoomSucess = false
            self.bInJoinLobbyTeam = false
        end
        self:ReJoinRoom(nType)
        UIUtils.ShowToast(strReason)
        return 
    end
    if nType == TEAM_ROOM_TYPE then
        self.bJoinTeamRoomSucess = true
        self.bInJoinTeam = false
        self.nMemberId = nMemberId
        self:GetRoomMembers(szRoomName)
        ClearJoinTeamTimer(self)
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("VOICE_JOIN_TEAM_ROOM_SUCCESS"))
    elseif nType == ALL_ROOM_TYPE then
        self.bInJoinAll = false
        self.bJoinAllRoomSucess = true
        ClearJoinAllTimer(self)
    elseif nType == TEAM_LOBBY_TYPE then
        self.bInJoinLobbyTeam = false
        self.bJoinLobbyTeamRoomSucess = true
        ClearJoinLobbyTeamTimer(self)
    end
    local bSingle = GVoiceSDKSystem.IsSelfSinglePlayer()
    if self.bJoinAllRoomSucess and bSingle then
        GVoiceDebug:DebugLog("Player is single player!")
        SetVoiceDefaultOption(self)
    end
    if self.bJoinAllRoomSucess and self.bJoinTeamRoomSucess then
        GVoiceDebug:DebugLog("Player is in team!")
        SetVoiceDefaultOption(self)
    end
    if self.bJoinLobbyTeamRoomSucess then
        self:EnableSpeaker(GVoiceOpCtrlHelper.ReadyToOpenSpeaker(self))
        self:EnableMic(GVoiceOpCtrlHelper.ReadyToOpenMic(self))
    end
    CheckSelfMic(self)
end

local function OnStatusUpdate(self, szRoomName, nMemberId)
    
end

local function OnQuitRoom(self, nCompleteCode, szRoomName)
    if nCompleteCode ~= GCLOUD_VOICE_QUIT_ROOM_SUCC then
        local strErrorCode = L10N:Format(UISetUtils.GetL10NTextByKey("VOICE_ERROR_CODE"), nCompleteCode)
        local strReason = L10N:Format(UISetUtils.GetL10NTextByKey("VOICE_QUIT_ROOM_ERROR"), strErrorCode)
        UIUtils.ShowToast(strReason)
        return
    end
end

local function OnRoomMemberInfo(self, nMemberId, szRoomName, szOpenId)
    GVoiceDebug:DebugLog(" ============ nPlayerId = " .. GlobalVariableSystem.nSelfLobbyPlayerId)
    if szRoomName == self.szTeamRoomName then
        self:SetVoiceMemberidToPlayerId(nMemberId, szOpenId)
    end
end

local function OnEvent(self, nEventCode, szInfo)

end

local function OnGetMemberInfo(self, nErrorCode, tbMemberIds, tbMemberOpenIds)
    GVoiceDebug:DebugLog(" ============ OnGetMemberInfo nErrorCode = " .. nErrorCode)
    for i, v in ipairs(tbMemberIds) do
        local nMemberId = v
        local szOpenId = tostring(tbMemberOpenIds[i])
        GVoiceDebug:DebugLog("nMemberId = " .. nMemberId .. " openid = " .. szOpenId)
        self:SetVoiceMemberidToPlayerId(nMemberId, szOpenId)
        EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_VOICE_ROOM_MEMBER_INFO, nMemberId, szOpenId)
    end
end

local function OnMemberVoiceStateChange(self, szRoomName, nMemberPlayerId, nStatus)
    -- GVoiceDebug:DebugLog("OnMemberVoiceStateChange szRoomName = " .. szRoomName  .. " nMemberPlayerId = " .. nMemberPlayerId .. " nStatus = " .. nStatus)
    if szRoomName == self.szTeamRoomName or szRoomName == self.szLobbyTeamRoomName then
        local tbPlayerIds = GVoiceSDKSystem.GetTeamPlayerIds()
        if not tbPlayerIds then
            GVoiceDebug:DebugLog("tbPlayerIds is nil!")
            return 
        end

        for index, nPlayerId in ipairs(tbPlayerIds) do
            -- GVoiceDebug:DebugLog("OnMemberVoiceDetail Find nPlayerId = " .. tostring(nPlayerId) .. " nMemberPlayer = " .. tostring(nMemberPlayerId))
            if nMemberPlayerId == nPlayerId then
                EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE_STATE, index, nStatus)
            end
        end
    end
end

local function OnMemberVoiceDetail(self, tbMemberVoiceInfo, nCount)
    for i = 1 , nCount , 2 do
        local nMemberId = tbMemberVoiceInfo[i]
        local szMemberPlayerId = self:GetMemberPlayerId(nMemberId)
        if not szMemberPlayerId then
            self:GetRoomMembers(self.szLobbyTeamRoomName) -- 只有非mutulRoom才会调用这个回调， 所以这里暂时将romename写死
            return
        end
        local nMemberPlayerId = tonumber(szMemberPlayerId)
        local nState = tbMemberVoiceInfo[i+1]
        EventManager:OnFireEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE_STATE, nil, nState, nMemberPlayerId)
    end
end

local function OnMemberVoice(self, szRoomName, nMemberId, nStatus)
    local szMemberPlayerId = self:GetMemberPlayerId(nMemberId)
    if not szMemberPlayerId then
        GVoiceDebug:DebugLog("szMemberPlayerId is nil!")
        return
    end
    OnMemberVoiceStateChange(self, szRoomName, tonumber(szMemberPlayerId), nStatus)
end

local function OnRecording(self, nLength)
    
end

--end*************************************************
--GVoice notify接口

function GVoiceSDKSystem:Init()
    local pGVoiceSdkManager = ClientShell.GetClient(GWorld):GetGVoiceSdkManager()
    if not pGVoiceSdkManager then
        GVoiceDebug:DebugLog("pChannelSdkManager is nil!")
        return
    end
    self.pGVoiceSdkManager = pGVoiceSdkManager
    self.TimerHelper = SelfTimerHelperClass()
    self.tbMemberIdToPlayerId = {}
    self.bMicEnable = false
    self:BindEvent()
end

function GVoiceSDKSystem:Uninit()
    if not CheckSdkManagerValid(self) then
        return
    end
    if self.bInDungeon then 
        QuitAllRooms(self)
    end
    self:QuitLobbyTeamRoom()
    self.pGVoiceSdkManager = nil
    self.tbMemberIdToPlayerId = nil
    self.bJoinAllRoomSucess = false
    self.bJoinTeamRoomSucess = false
    self.nMemberId = nil
    ClearRejoinTimer(self)
    ClearJoinAllTimer(self)
    ClearJoinTeamTimer(self)
    ClearSyncMemberIdTimer(self)
    self:ClearPollTimer()
    self:UnbindEvent()
    self.TimerHelper:ClearAllTimer()
end

function GVoiceSDKSystem:BindEvent()
    self.EventHelper = SelfEventHelper()
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_JOIN_ROOM, self, OnJoinRoom)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_STATUS_UPDATE, self, OnStatusUpdate)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_QUIT_ROOM, self, OnQuitRoom)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE, self, OnMemberVoice)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_RECORDING, self, OnRecording)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLevelBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_DUNGEON, self, OnEnterDungeon)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_VOICE_EVENT, self, OnEvent)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_VOICE_GET_MEMBERINFO, self, OnGetMemberInfo)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_GVOICE_MOCK_LEAVE_BATTLE, self, OnLevelBattle)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_GVOICE_MOCK_ENTER_BATTLE, self, OnEnterDungeon)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE_DETAIL, self, OnMemberVoiceDetail)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_ROOM_MEMBER_INFO, self, OnRoomMemberInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnEnterLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLevelLobby)
    self.GetMemberInfoDelegate = CppDelegate:BindMethod(self.pGVoiceSdkManager.OnGetMemberInfo, self, OnGetMemberInfo)
end

function GVoiceSDKSystem:UnbindEvent()
    local EventHelper = self.EventHelper
    if not EventHelper then
        return
    end
    EventHelper:UnregisterAll()
    if self.GetMemberInfoDelegate then
		self.GetMemberInfoDelegate:Unbind()
		self.GetMemberInfoDelegate = nil
	end
end

return GVoiceSDKSystem