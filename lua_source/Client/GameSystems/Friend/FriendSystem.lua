local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UITextDef = require("UITextDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local SelfEventHelper = require("SelfEventHelper")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local SaveGameDef = require("SaveGameDef")
local StringUtil = require("StringUtil")
local FriendIni = require("FriendIni")
local PlayerInfoSystem = require("PlayerInfoSystem")
local UIManager = require("UIManager")
local TimeUtil = require("TimeUtil")
local UIDef = require("UIDef")
local RankDataTable = require("RankDataTable")
local BaseUtil = require("BaseUtil")

local FriendSystem = {}
FriendSystem.tbRecentlyTeam = nil
FriendSystem.bInit = nil
FriendSystem.bInLobby = nil
FriendSystem.tbReservationIds = nil
FriendSystem.tbCacheBattleLevelUpInfo = nil
FriendSystem.tbSendCoinIds = nil

local ReservationState = Proto.FriendReservation_FriendReservationState

local Return_Code = {
    [Proto.ReturnCode.APPLY_FRIEND_LIMIT] = UITextDef.APPLY_FRIEND_LIMIT,
    [Proto.ReturnCode.FRIEND_COUNT_LIMIT] = UITextDef.FRIEND_ADD_SELF_FULL,
    [Proto.ReturnCode.OTHER_APPLY_FRIEND_LIMIT] = UITextDef.OTHER_APPLY_FRIEND_LIMIT,
    [Proto.ReturnCode.OTHER_FRIEND_COUNT_LIMIT] = UITextDef.OTHER_FRIEND_COUNT_LIMIT,
    [Proto.ReturnCode.PLAYER_NOT_FOUND] = UITextDef.FRIEND_NOT_FOUND,
    [Proto.ReturnCode.CANNOT_ADD_SELF] = UITextDef.FRIEND_CANNOT_ADD_SELF,
    [Proto.ReturnCode.ALREADY_IN_APPLY_FRIEND] = UITextDef.ALREADY_IN_APPLY_FRIEND,
    [Proto.ReturnCode.ALREADY_IN_FRIEND] = UITextDef.ALREADY_IN_FRIEND,
    [Proto.ReturnCode.OTHER_NOT_IN_APPLY_LIST] = UITextDef.OTHER_NOT_IN_APPLY_LIST,
    [Proto.ReturnCode.APPLY_FRIEND_MSG_EMPTY] = UITextDef.APPLY_FRIEND_MSG_EMPTY,
    [Proto.ReturnCode.FRIEND_LIST_EMPTY] = UITextDef.FRIEND_LIST_EMPTY,
    [Proto.ReturnCode.APPLY_FRIEND_LIST_EMPTY] = UITextDef.APPLY_FRIEND_LIST_EMPTY,
    [Proto.ReturnCode.OTHER_NOT_FRIEND] = UITextDef.OTHER_NOT_FRIEND,
    [Proto.ReturnCode.FRIEND_DB_ERROR] = UITextDef.FRIEND_DB_ERROR
}

local function ShowErrorCode(nReturnCode)
    local l10nErrorCode = Return_Code[nReturnCode]
    if l10nErrorCode ~= nil then
        UIUtils.ShowToast(l10nErrorCode)
    else
        logerror("FriendSystem invalid return code:", nReturnCode)
    end
end

local function OnRecvPlayerSummaries(self, tbSummaries)
    local Component = self:GetComponent()
    if Component ~= nil then
        for i, v in ipairs(tbSummaries) do
            Component:SetFriendSummary(v)
            Component:SetApplyFriendSummary(v)
        end
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_RECENT_TEAM_STATE, tbSummaries)

end

local function RequestFriendsSummaries(self, tbPlayerIdList)
    local tbCachedPlayerIds, tbNoCachedPlayerIds = PlayerInfoSystem:HasPlayerSummaries(tbPlayerIdList)
    PlayerInfoSystem:RequestPlayerSummariesFromServer(tbNoCachedPlayerIds)

    local tbSummaries = PlayerInfoSystem:GetPlayerSummariesFromLocal(tbCachedPlayerIds)
    local tbSummariesArray = {}
    for k, v in pairs(tbSummaries) do
        table.insert(tbSummariesArray, v)
    end
    OnRecvPlayerSummaries(self, tbSummariesArray)
end

local function OnRelationShipChanged(self, tbRelationChangeInfo)
    if tbRelationChangeInfo == nil then  return end
    local tbReason = tbRelationChangeInfo.reason 
    if tbReason == nil then return end 
    local nPlayerSelfId = GamePlayerSelfHelper:Get():GetPlayerId()

    local bCreateRelationChange = tbReason.change_reason and tbReason.change_reason == Proto.RelationshipChangeReason_ChangeReason.CREATE 
        and nPlayerSelfId == tbReason.cause_player_id 
    local bSendGiftRelationChange = tbReason.change_reason and tbReason.change_reason == Proto.RelationshipChangeReason_ChangeReason.SEND_GIFT 
        and nPlayerSelfId == tbReason.cause_player_id 
    local bSendCoinRelationChange = tbReason.change_reason and tbReason.change_reason == Proto.RelationshipChangeReason_ChangeReason.USE_FRIENDSHIP_CARD 
        and nPlayerSelfId == tbReason.cause_player_id 

    if bCreateRelationChange or bSendGiftRelationChange or bSendCoinRelationChange then 
        UIManager:OpenWnd(UIDef.UI_FRIEND_RELATION_LEVELUP, {tbRelationChangeInfo = tbRelationChangeInfo})
    end
end

local function CheckToCacheMatchLevelUp(self, tbRelationChangeInfo)
    if tbRelationChangeInfo == nil then  return end
    local tbReason = tbRelationChangeInfo.reason 
    if tbReason == nil then return end 
    if tbReason.change_reason and tbReason.change_reason == Proto.RelationshipChangeReason_ChangeReason.TEAM_UP_BATTLE then  
        self.tbCacheBattleLevelUpInfo = tbRelationChangeInfo
    end
end

local function CheckToShowMatchLevelUp(self)
    if self.tbCacheBattleLevelUpInfo and self.tbCacheBattleLevelUpInfo.reason then  
        UIManager:OpenWnd(UIDef.UI_FRIEND_RELATION_LEVELUP, {tbRelationChangeInfo = self.tbCacheBattleLevelUpInfo})
    end
end

function FriendSystem:ClearCacheMatchLevelUp()
    self.tbCacheBattleLevelUpInfo = nil
end

local function OnEnterLobby(self)
    self.bInLobby = true
    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem enter lobyy get component invalid component")
        return
    end
    local tbFriends = Component:GetFriends() or {}
    local tbSummaries = Component:GetFriendSummaries()
    if #tbFriends ~= #tbSummaries then
        local tbPlayerIdList = {}
        for i, v in ipairs(tbFriends) do
            table.insert(tbPlayerIdList, v.player_id)
        end
        RequestFriendsSummaries(self, tbPlayerIdList)        
    end
    if self.bInit and GlobalVariableSystem_C.bNewReconnect then
        return
    end
    -- self:RequestGetFriends()
    -- self:RequestGetApplyFriendCount()
    self:RequestRefreshReservationList()
    CheckToShowMatchLevelUp(self)
end

local function OnLeaveLobby(self)
    self.bInLobby = false
end

--==============================--
--desc: 最近组队
--==============================--
local function UncodeRecentlyTeam()
    local str = ClientShell.GetClient(GWorld):GetSaveGameManager():GetStringData(SaveGameDef.RECENTLY_TEAM)
    local tbRet = {}
    local tbTeams = StringUtil.Split(str, "|")
    local strTeamInfo = ""
    local strData = ""
    for i, v in ipairs(tbTeams) do
        strTeamInfo = strTeamInfo .. v
        local tbMember = {}
        local tbDatas = StringUtil.Split(strTeamInfo, ";")
        if #tbDatas >= 2 then 
            strTeamInfo = ""
            strData = ""
            for _, value in ipairs(tbDatas) do
                strData = strData .. value
                local tbData = StringUtil.Split(strData, ":")
                if #tbData >= 2 then 
                    local nValue = tonumber(tbData[2])
                    tbMember[tbData[1]] = nValue or tbData[2]
                end
            end
            table.insert(tbRet, tbMember)
        end
    end
    return tbRet
end

local function EncodeRecentlyTeam(tbDatas)
    local str
    for i, v in ipairs(tbDatas) do
        local temp
        for key, value in pairs(v) do
            if type(value) ~= "table" then
                if temp == nil then
                    temp = string.format("%s:%s", key, tostring(value))
                else
                    temp = string.format("%s;%s:%s", temp, key, tostring(value))
                end
            end
        end
        if str == nil then
            str = temp
        else
            str = string.format("%s|%s", str, temp)
        end
    end
    if str ~= nil then
        ClientShell.GetClient(GWorld):GetSaveGameManager():AddStringData(SaveGameDef.RECENTLY_TEAM, str)
    end
end

-- 用历史战绩和好友列表晒选出最近组队
local function OnRecvHistoryStats(self, tbPacket, nCount)
    local nSelfId = GamePlayerSelfHelper:Get().nPlayerId
    if tbPacket.player_id ~= nSelfId then
        return
    end
    if nCount == 0 then 
        return
    end
    local Component = self:GetComponent()
    local tbNearTeam = {}
    local nMaxCount = FriendIni.tbTeam.nMaxApplyFriend
    
    local tbNearTeamKey = {}
    for i = 1, #tbPacket.stats do
        local tbTeam = tbPacket.stats[i]
        for index, member in ipairs(tbTeam.teamMembers) do
            local tbSummary = member.summary
            if tbSummary.id ~= nSelfId and not Component:GetFriend(tbSummary.id) then
                if tbNearTeamKey[tbSummary.id] == nil then
                    local tbTeamMember = {}
                    for k, v in pairs(tbSummary) do
                        tbTeamMember[k] = v
                    end
                    for k, v in pairs(member) do
                        if k == "rank" then --战斗排名与playersummary中的段位重名
                            tbTeamMember.battle_rank = v
                        elseif k ~= "summary" then
                            tbTeamMember[k] = v
                        end
                    end
                    tbTeamMember.mode = tbTeam.team_mode
                    tbTeamMember.battle_time = tbTeam.battle_time
                    tbTeamMember.player_count = tbTeam.player_count

                    if RankDataTable:GetTemplate(tbTeamMember.rank) == nil then
                        logerror("recently team member invalid rank ", i, index, tbTeamMember.rank)
                        BaseUtil:PrintTable(tbTeamMember, 1)
                    else
                        table.insert(tbNearTeam, tbTeamMember)
                        tbNearTeamKey[tbSummary.id] = tbTeamMember
                        if #tbNearTeam >= nMaxCount then
                            break
                        end
                    end
                end
            end
        end
    end

    local nCurCount = #tbNearTeam
    if nCurCount >= nMaxCount then
        EncodeRecentlyTeam(tbNearTeam)
    else
        local tbSavedTeam = UncodeRecentlyTeam()
        local nOldCount = #tbSavedTeam
        if nOldCount > 0 then
            for i = nCurCount + 1, nOldCount do
                local nId = tbSavedTeam[i - nCurCount].id
                if tbNearTeamKey[nId] == nil and Component:GetFriend(nId) == nil then
                    if RankDataTable:GetTemplate(tbSavedTeam[i - nCurCount].rank) == nil then
                        log("saved recently team member invalid rank ", tbSavedTeam[i - nCurCount].rank)
                        -- BaseUtil:PrintTable(tbSavedTeam[i - nCurCount], 1)
                    else
                        table.insert(tbNearTeam, tbSavedTeam[i - nCurCount])
                        tbNearTeamKey[nId] = tbSavedTeam[i - nCurCount]
                        if #tbNearTeam > nMaxCount then
                            break
                        end
                    end 
                end
            end 
        end
        EncodeRecentlyTeam(tbNearTeam)
    end
    self.tbRecentlyTeam = tbNearTeam
    -- EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_RECENT_TEAM, tbNearTeam) 
end

local function RemoveFriendFromRecentlyTeam(self, nPlayerId)
    if self.tbRecentlyTeam == nil then
        return
    end
    for i, v in ipairs(self.tbRecentlyTeam) do
        if v.id == nPlayerId then
            table.remove( self.tbRecentlyTeam, i )
            EncodeRecentlyTeam(self.tbRecentlyTeam)
            break
        end
    end
end

--==============================--
--desc: 训练营的申请列表是否被查看
--==============================--
local function UncodeSavedApplies(self)
    local str = ClientShell.GetClient(GWorld):GetSaveGameManager():GetStringData(SaveGameDef.DUNGEON_APPLY_FRIENDS)
    
    local tbRet = {}
    local tbIds = StringUtil.Split(str, ";")
    for _, v in ipairs(tbIds) do
        tbRet[tonumber(v)] = true
    end

    return tbRet
end

local function EncodeSavedApplies(self, nTime)
    local str
    local Component = self:GetComponent()
    local tbDatas = Component:GetApplyFriends()
    for i, v in ipairs(tbDatas) do
        if v.bWatched then
            if str == nil then
                str = v.player_id
            else
                str = string.format("%s;%s", str, v.player_id) 
            end
        end
    end

    if str ~= nil then
        ClientShell.GetClient(GWorld):GetSaveGameManager():AddStringData(SaveGameDef.DUNGEON_APPLY_FRIENDS, str)
    end    
end

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    Socket:SendPacket(szProto, tbPacket)    
end

local function RequestTeamRelation(self, tbPlayerIds)
    local c2s_GetFriendRelationshipsByList = {
        player_ids = tbPlayerIds
    }
    SendPacket(Proto.c2s_GetFriendRelationshipsByList, c2s_GetFriendRelationshipsByList)
end

local function OnRecCheckReservationOk(self)
end

local function OnNotifyFriendSummaryChanged(self, tbSummary)
    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnNotifyFriendSummaryChanged component is nil")
        return
    end    
    log("FriendSystem:OnNotifyFriendSummaryChanged1")
    if Component:RefreshFriend(tbSummary) then
        log("FriendSystem:OnNotifyFriendSummaryChanged2")
        EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS)    
    end
    log("FriendSystem:OnNotifyFriendSummaryChanged3")
end



function FriendSystem:Init()
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    self.tbReservationIds = {}
    if GlobalVariableSystem_C.bNewReconnect then
        EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnEnterLobby)
    else
        EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY, self, OnEnterLobby)
    end
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLeaveLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_HISTORY_STATS, self, OnRecvHistoryStats)
    EventHelper:RegisterEvent(ClientEventDef.EV_UPDATE_TEAMMATE_RELATION, self, RequestTeamRelation)
    
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SUMMARIES_RECEIVED, self, OnRecvPlayerSummaries)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SUMMARY_CHANGE_NOTIFIED, self, OnNotifyFriendSummaryChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEND_CHECK_RESERVATIO_LIST_OK, self, OnRecCheckReservationOk)
    EventHelper:RegisterEvent(ClientEventDef.EV_RELATION_SHIP_CHANGED, self, OnRelationShipChanged)
    return true
end

function FriendSystem:Uninit()
    self.tbRecentlyTeam = nil
    self.bInit = nil
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    self.bInLobby = nil
    self.tbReservationIds = nil
end

function FriendSystem:GetComponent()
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf ~= nil then
        return tbPlayerSelf.FriendComponent
    end
end

-- function FriendSystem:RequestGetFriends()
--     SendPacket(Proto.c2s_GetFriends)
-- end

function FriendSystem:RequestSendCoin(nId)
    local c2s_SendFriendGift = {
        player_id = nId
    }
    SendPacket(Proto.c2s_SendFriendGift, c2s_SendFriendGift)
end

function FriendSystem:RequestDeleteFriend(nId)
    local c2s_DeleteFriend = {
        player_id = nId
    }
    SendPacket(Proto.c2s_DeleteFriend, c2s_DeleteFriend)
end

function FriendSystem:RequestPreciseSearch(szInput)
    local c2s_PreciseSearch = {
        user_input = szInput
    }
    SendPacket(Proto.c2s_PreciseSearch, c2s_PreciseSearch)
end

function FriendSystem:RequestApplyFriend(nId, szMsg, nSource)
    local c2s_ApplyFriend = {
        player_id = nId,
        apply_msg = szMsg,
        source = nSource
    }
    SendPacket(Proto.c2s_ApplyFriend, c2s_ApplyFriend)
end

function FriendSystem:RequestGetApplyFriends()
    SendPacket(Proto.c2s_GetApplyFriends)
end

function FriendSystem:RequestAddFriend(nId)
    local c2s_AddFriend = {
        player_id = nId
    }
    SendPacket(Proto.c2s_AddFriend, c2s_AddFriend)
end

function FriendSystem:RequestDeleteApplyFriend(nId)
    local c2s_DeleteApplyFriend = {
        player_id = nId
    }
    SendPacket(Proto.c2s_DeleteApplyFriend, c2s_DeleteApplyFriend)
end

function FriendSystem:RequestAddAllApplyFriend()
    SendPacket(Proto.c2s_AddAllApplyFriend)
end

function FriendSystem:RequestDeleteAllApplyFriend()
    SendPacket(Proto.c2s_DeleteAllApplyFriend)
end

-- function FriendSystem:RequestGetApplyFriendCount()
--     SendPacket(Proto.c2s_GetApplyFriendCount)
-- end

function FriendSystem:RequestPlayerSummarier(tbPlayerIds)
    local c2s_PlayerSummaries = {
        player_ids = tbPlayerIds
    }
    SendPacket(Proto.c2s_PlayerSummaries, c2s_PlayerSummaries)
end

function FriendSystem:RequestCreateRelation(nPlayerId, nRelationType)
    local c2s_ApplyCreateRelationship = {
        player_id = nPlayerId,
        relationship_id = nRelationType,
    }
    SendPacket(Proto.c2s_ApplyCreateRelationship, c2s_ApplyCreateRelationship)
end

function FriendSystem:RequestApplyRelation(nPlayerId, bAccept)
    local c2s_HandleCreateRelationshipApply = {
        player_id = nPlayerId,
        accepted = bAccept,
    }
    SendPacket(Proto.c2s_HandleCreateRelationshipApply, c2s_HandleCreateRelationshipApply)
end

function FriendSystem:RequestShowFirst(nPlayerId)
    local c2s_SetRelationshipPriority = {
        player_id = nPlayerId,
    }
    SendPacket(Proto.c2s_SetRelationshipPriority, c2s_SetRelationshipPriority)
end

function FriendSystem:RequestCancelRelation(nPlayerId)
    local c2s_ApplyCancelRelationship = {
        player_id = nPlayerId,
    }
    SendPacket(Proto.c2s_ApplyCancelRelationship, c2s_ApplyCancelRelationship)
end

function FriendSystem:RequestApplyCancelRelation(nPlayerId, bAccept)
    local c2s_HandleCancelRelationshipApply = {
        player_id = nPlayerId,
        accepted = bAccept
    }
    SendPacket(Proto.c2s_HandleCancelRelationshipApply, c2s_HandleCancelRelationshipApply)
end

function FriendSystem:RequestSendFriendReservation(nPlayerId)
    local c2s_SendFriendReservation = {
        player_id = nPlayerId,
    }
    SendPacket(Proto.c2s_SendFriendReservation, c2s_SendFriendReservation)
end

function FriendSystem:RequestGetRelationShipsByList(tbPlayerIds)
    local c2s_GetFriendRelationshipsByList = {
        player_ids = tbPlayerIds
    }
    SendPacket(Proto.c2s_GetFriendRelationshipsByList, c2s_GetFriendRelationshipsByList)
end

function FriendSystem:RequestAcceptFriendReservation(nPlayerId)
    local c2s_AcceptFriendReservation = {
        player_id = nPlayerId
    }
    SendPacket(Proto.c2s_AcceptFriendReservation, c2s_AcceptFriendReservation)
end

function FriendSystem:RequestGetFriendRelations(nPlayerId)
    local c2s_GetFriendRelationships = {
        player_id = nPlayerId
    }
    SendPacket(Proto.c2s_GetFriendRelationships, c2s_GetFriendRelationships)
end

function FriendSystem:OnRecvGetFriends(tbPacket)
    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvGetFriends component is nil")
        return
    end
    self.bInit = true
    -- 临时
    for i, v in ipairs(tbPacket.friend_info) do
        v.player_summary = nil
    end
    -- 

    Component:SetFriends(tbPacket.friend_info)
    Component:SetPriorityPlayer(tbPacket.priority_player_id)
    
    local tbPlayerIdList = {}
    for i, v in ipairs(tbPacket.friend_info) do
        RemoveFriendFromRecentlyTeam(self, v.player_id)
        table.insert(tbPlayerIdList, v.player_id)
    end
    RequestFriendsSummaries(self, tbPlayerIdList)

    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS)
end

function FriendSystem:OnRecvDeleteFriend(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end

    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvDeleteFriend component is nil")
        return
    end
    local szName = Component:DeleteFriend(tbPacket.player_id)
    if szName then
        UIUtils.ShowToast(L10N:Format(UISetUtils.GetL10NTextByKey("FRIEND_DELETE_SUCCESS"), szName))
        EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS)
    end
end

function FriendSystem:OnRecvNotifyDeleteFriend(tbPacket)
    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvNotifyDeleteFriend component is nil")
        return
    end

    if Component:DeleteFriend(tbPacket.player_id) ~= nil then
        EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS)
    end
end

function FriendSystem:OnRecvPreciseSearch(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        -- return
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_SEARCH_FRIEND, tbPacket)    
end

function FriendSystem:OnRecvApplyFriend(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end
    UIUtils.ShowToast(UITextDef.FRIEND_APPLY_SUCCESS)
end

function FriendSystem:OnRecvNotifyApplyFriend(tbPacket)
    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvNotifyApplyFriend component is nil")
        return
    end

    if self.bInLobby then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FRIEND_HAS_APPLY"))
    end
    -- 临时
    tbPacket.player_summary = nil
    -- 

    Component:AddApplyFriend(tbPacket.apply_friend)
    RequestFriendsSummaries(self, {tbPacket.player_id})

    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS)
    -- self:RequestGetApplyFriendCount()     
end

function FriendSystem:OnRecvGetApplyFriends(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end   
    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvGetApplyFriends component is nil")
        return
    end

    -- 临时
    for i, v in ipairs(tbPacket.apply_friends) do
        v.player_summary = nil
    end
    -- 

    Component:SetApplyFriends(tbPacket.apply_friends, UncodeSavedApplies())

    local tbPlayerIdList = {}
    for i, v in ipairs(tbPacket.apply_friends) do
        table.insert(tbPlayerIdList, v.player_id)
    end
    RequestFriendsSummaries(self, tbPlayerIdList)

    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS)
    -- self:RequestGetApplyFriendCount()     
end

function FriendSystem:OnRecvAddFriend(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end    
    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvAddFriend component is nil")
        return
    end
    
    local nPlayerId = tbPacket.friend_info.player_id
    Component:DeleteApplyFriend(nPlayerId)
    Component:AddFriend(tbPacket.friend_info)
    RemoveFriendFromRecentlyTeam(self, nPlayerId)
    RequestFriendsSummaries(self, {nPlayerId})

    local tbSummaries = PlayerInfoSystem:GetPlayerSummariesFromLocal({nPlayerId})
    if tbSummaries[nPlayerId] ~= nil then
        UIUtils.ShowToast(L10N:Format(UISetUtils.GetL10NTextByKey("FRIEND_ADD_SUCCESS"), tbSummaries[nPlayerId].name))
    end

    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS)   
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS) 
    -- self:RequestGetApplyFriendCount() 
end

function FriendSystem:OnRecvNotifyAddFriend(tbPacket)
    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvNotifyAddFriend component is nil")
        return
    end

    local nPlayerId = tbPacket.friend_info.player_id
    Component:DeleteApplyFriend(nPlayerId)
    Component:AddFriend(tbPacket.friend_info)
    RemoveFriendFromRecentlyTeam(self, nPlayerId)
    RequestFriendsSummaries(self, {nPlayerId})

    -- self:RequestGetApplyFriendCount() 
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS) 
end

function FriendSystem:OnRecvDeleteApplyFriend(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end    
    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvDeleteApplyFriend component is nil")
        return
    end

    Component:DeleteApplyFriend(tbPacket.player_id)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS)    
    -- self:RequestGetApplyFriendCount()             
end

function FriendSystem:OnRecvAddAllApplyFriend(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end 

    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvAddAllApplyFriend component is nil")
        return
    end


    local bSelfFull, bAddFriend, nPlayerId = false
    for _, v in ipairs(tbPacket.friend_result) do
        if v.return_code == Proto.ReturnCode.FRIEND_COUNT_LIMIT then
            bSelfFull = true
        elseif v.return_code ~= Proto.ReturnCode.OK then
            ShowErrorCode(v.return_code)
        else
            bAddFriend = true
            nPlayerId = v.friend_info.player_id
            Component:DeleteApplyFriend(nPlayerId)
            Component:AddFriend(v.friend_info)
            local tbPlayerSummaries = PlayerInfoSystem:GetPlayerSummariesFromLocal({nPlayerId})
            if tbPlayerSummaries[nPlayerId] ~= nil then
                UIUtils.ShowToast(L10N:Format(UISetUtils.GetL10NTextByKey("FRIEND_ADD_SUCCESS"), tbPlayerSummaries[nPlayerId].name))
            else
                log("FriendSystem:OnRecvAddAllApplyFriend added but no player summary ", nPlayerId)
            end
        end
    end
    if bSelfFull then
        UIUtils.ShowToast(UITextDef.FRIEND_ADD_SELF_FULL) 
    end
    if bAddFriend then
        EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS) 
        EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS)
        -- self:RequestGetApplyFriendCount()     
    end 
end

function FriendSystem:OnRecvDeleteAllApplyFriend(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        self:RequestGetApplyFriends()
        return
    end 

    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvDeleteAllApplyFriend component is nil")
        return
    end

    Component:ClearApplyFriend()
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS)
    -- self:RequestGetApplyFriendCount() 
end

-- function FriendSystem:OnRecvGetApplyFriendCount(tbPacket)
--     if tbPacket.return_code ~= Proto.ReturnCode.OK then
--         ShowErrorCode(tbPacket.return_code)
--         return
--     end 
--     local Component = self:GetComponent()
--     if Component == nil then
--         log("FriendSystem:OnRecvDeleteAllApplyFriend component is nil")
--         return
--     end    
--     Component:SetApplyCount(tbPacket.apply_friend_count)
--     EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_APPLY_COUNT)
-- end

function FriendSystem:OnRecvPlayerIntimacyChanged(tbPacket)
    -- logdebug("[OnRecvPlayerIntimacyChanged] OnRecvPlayerIntimacyChanged  ", require("dkjson").encode(tbPacket) )
    local Component = self:GetComponent()
    if Component == nil then
        log("FriendSystem:OnRecvPlayerIntimacyChanged component is nil")
        return
    end   
    
    Component:RefreshFriendIntimacy(tbPacket.player_id, tbPacket.intimacy)
    -- EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS)   
    EventManager:OnFireEvent(ClientEventDef.EV_REFRESH_IMTIMACY_CHANGE, tbPacket.player_id)
end


function FriendSystem:OnRecvRelationshipChanged(tbPacket)
    -- logdebug("[OnRecvRelationshipChanged] OnRecvRelationshipChanged recever is ", GamePlayerSelfHelper:Get():GetPlayerId())
    -- logdebug("[OnRecvRelationshipChanged] relation ship changed", require("dkjson").encode(tbPacket) )

    local Component = self:GetComponent()
    if Component == nil then
        return
    end

    CheckToCacheMatchLevelUp(self, tbPacket)
    --在刷新新的 relation ship之前发这个事件，这样可以通过对比来看 是否弹亲密关系升级的ui
    EventManager:OnFireEvent(ClientEventDef.EV_RELATION_SHIP_CHANGED, tbPacket) 
    Component:RefreshFriendRelation(tbPacket.player_id, tbPacket.relationship)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_FRIENDS)   
end

function FriendSystem:OnRecRelationshipPriorityChanged(tbPacket)
    local Component = self:GetComponent()
    if Component == nil then
        return
    end
    Component:SetPriorityPlayer(tbPacket.player_id)
end

function FriendSystem:OnRecFriendRelationships(tbPacket)
    local Component = self:GetComponent()
    if Component == nil then
        return
    end
    Component:SetTeamRelations(tbPacket.summaries, tbPacket.priority_ids)
end

--预约组队存档
function FriendSystem:RequestRefreshReservationList()
    local tbReservationList = self:GetReservationIds()
    if next(tbReservationList) == nil then 
        return 
    end
    local tbPlayerIds = {}
    for id, nState in pairs(tbReservationList) do 
        table.insert(tbPlayerIds, id)
    end

    local c2s_SendReservationList = {
        player_id = tbPlayerIds
    }
    SendPacket(Proto.c2s_SendReservationList, c2s_SendReservationList)
    self:ClearReservationIds()
end

local function SaveReservationIds(self)
    local str = nil
    for id, state in pairs(self.tbReservationIds) do
        if str == nil then  
            str = string.format("%d:%d", id, state)
        else
            str = string.format("%s;%d:%d", str, id, state)
        end
    end

    local pSaveManager = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveManager:AddStringData(SaveGameDef.NEW_RESERVATION, str)
    pSaveManager:Save()
end

function FriendSystem:AddReservationId(nPlayerId, nState)
    if self.tbReservationIds == nil then  
        self.tbReservationIds = {}
    end
    self.tbReservationIds[nPlayerId] = nState
    SaveReservationIds(self)
end

function FriendSystem:GetReservationIds()
    if self.tbReservationIds == nil or next(self.tbReservationIds) == nil then 
        local pSaveManager = ClientShell.GetClient(GWorld):GetSaveGameManager()
        local str = pSaveManager:GetStringData(SaveGameDef.NEW_RESERVATION)
        local tbIds = StringUtil.Split(str, ';')
        self.tbReservationIds = {}
        for _, v in ipairs(tbIds) do 
            local tbOnePlayer = StringUtil.Split(v, ':')
            local nId = tonumber(tbOnePlayer[1])
            local nState = tonumber(tbOnePlayer[2])
            self.tbReservationIds[nId] = nState 
        end
    end
    return self.tbReservationIds
end

function FriendSystem:GetReservationState(nId)
    local tbIds = self:GetReservationIds()
    for id, state in pairs(tbIds) do 
        if id == nId then  
            return state
        end
    end
    return ReservationState.NONE
end

function FriendSystem:ClearReservationIds()
    self.tbReservationIds = {}
    local pSaveManager = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveManager:AddStringData(SaveGameDef.NEW_RESERVATION, "")
    pSaveManager:Save()
end

function FriendSystem:ClearReservationId(nClearId)
    local tbIds = self:GetReservationIds()
    if tbIds[nClearId] then  
        tbIds[nClearId] = nil
    end
    SaveReservationIds(self)
end

--已赠送玩家存储
local function CheckAndLoadSendCoinPlayers(self)
    log("[SendCoin] CheckAndLoadSendCoinPlayers 1", self.tbSendCoinIds)
    if self.tbSendCoinIds == nil or #self.tbSendCoinIds == 0 then  
        self.tbSendCoinIds = {}
        local pSaveManager = ClientShell.GetClient(GWorld):GetSaveGameManager()
        local str = pSaveManager:GetStringData(SaveGameDef.SENDCOIN_IDS)
        local tbIds = StringUtil.Split(str, ';')
        for _, v in ipairs(tbIds) do 
            local tbOnePlayer = StringUtil.Split(v, ':')
            local nId = tonumber(tbOnePlayer[1])
            local nTime = tonumber(tbOnePlayer[2])
            self.tbSendCoinIds[nId] = nTime
            log("[SendCoin] CheckAndLoadSendCoinPlayers2:", nId, nTime)
        end
        log("[SendCoin] CheckAndLoadSendCoinPlayers3:", str)
    end
end 

local function SaveSendCoinPlayers(self)
    if self.tbSendCoinIds == nil then return end
    local str = nil
    for id, time in pairs(self.tbSendCoinIds) do
        if str == nil then  
            str = string.format("%d:%d", id, time)
        else
            str = string.format("%s;%d:%d", str, id, time)
        end
    end
    local pSaveManager = ClientShell.GetClient(GWorld):GetSaveGameManager()
    log("[SendCoin] SaveSendCoinPlayers:", str)
    pSaveManager:AddStringData(SaveGameDef.SENDCOIN_IDS, str)
    pSaveManager:Save()
end

function FriendSystem:AddSendCoinPlayer(nPlayerId, nSendTime)
    CheckAndLoadSendCoinPlayers(self)
    -- logdebug("send time is :", nSendTime)
    log("[SendCoin] AddSendCoinPlayer1", nPlayerId, nSendTime)
    if self.tbSendCoinIds[nPlayerId] ~= nSendTime then 
        self.tbSendCoinIds[nPlayerId] = nSendTime
        log("[SendCoin] AddSendCoinPlayer2:", nPlayerId, nSendTime)
        SaveSendCoinPlayers(self)
    end
end

function FriendSystem:IsSendCoinToday(nPlayerId)
    CheckAndLoadSendCoinPlayers(self)
    local nLastSendTime = self.tbSendCoinIds[nPlayerId]
    log("[SendCoin] IsSendCoinToday", nLastSendTime)
    if nLastSendTime == nil or TimeUtil.GetDayOfYearOffset(nLastSendTime) >= 1 then 
        log("[SendCoin] IsSendCoinToday false")
        return false
    end
    return true
end

function FriendSystem:GetRecentlyTeam()
    return self.tbRecentlyTeam 
end

function FriendSystem:WatchApplyInfo(nTime)
    local Component = self:GetComponent()
    Component:WatchApplyInfo(nTime)
    EncodeSavedApplies(self, nTime)
end

return FriendSystem