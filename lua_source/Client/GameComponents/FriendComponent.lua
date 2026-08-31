local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local FriendComponent = luaclass("FriendComponent", GameComponentBase)
local Proto = require("ClientProtoNames")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local FriendRelationShipDataTable = require("FriendRelationShipDataTable")
local FriendRelationShipLevelDataTable = require("FriendRelationShipLevelDataTable")
local Util = require("BaseUtil")

FriendComponent.tbFriends = nil
FriendComponent.tbApplyFriends = nil
FriendComponent.nApplyCount = 0
FriendComponent.tbRelationFriends = nil
FriendComponent.tbRelationCount = nil
FriendComponent.nPriorityFriendId = 0
FriendComponent.tbTeamRelations = nil

local MIN_RELATION_TYPE = 1
local MAX_RELATION_TYPE = 4

local function SortFriends(self)
    local fnSort = function(a, b)
        local fnSortSameStatus = function()
            if a.player_summary.status_time < b.player_summary.status_time then
                return false
            elseif b.player_summary.status_time < a.player_summary.status_time then
                return true
            else
                return a.player_summary.id < b.player_summary.id
            end                    
        end
        local fnSortStatus = function()
            if a.player_summary.status < b.player_summary.status then
                return true
            elseif b.player_summary.status < a.player_summary.status then
                return false
            else
                return fnSortSameStatus()
            end
        end
        local fnSortTeam = function()
            if a.player_summary.team_size > b.player_summary.team_size then
                return true
            elseif b.player_summary.team_size > a.player_summary.team_size then
                return false
            else
                return fnSortStatus()
            end
        end
        -- 都在线
        if a.player_summary.status ~= Proto.PlayerStatus.OFFLINE and b.player_summary.status ~= Proto.PlayerStatus.OFFLINE then
            -- 都空闲
            if a.player_summary.status == Proto.PlayerStatus.IDLE and b.player_summary.status == Proto.PlayerStatus.IDLE then  
                if a.player_summary.team_size < b.player_summary.team_size then
                    return true
                elseif b.player_summary.team_size < a.player_summary.team_size then
                    return false
                else
                    return fnSortStatus()
                end
            -- 都不空闲
            elseif a.player_summary.status ~= Proto.PlayerStatus.IDLE and b.player_summary.status ~= Proto.PlayerStatus.IDLE then
                return fnSortTeam()
            -- 一个空闲一个不空闲
            else
                return fnSortStatus()
            end
        -- 都不在线
        elseif a.player_summary.status == Proto.PlayerStatus.OFFLINE and b.player_summary.status == Proto.PlayerStatus.OFFLINE then
            return fnSortSameStatus()
        else
        -- 一个在线，一个不在线
            return a.player_summary.status > b.player_summary.status
        end
    end

    -- 判断player_summary是否都收到了
    for i, v in ipairs(self.tbFriends) do
        if v.player_summary == nil then
            return
        end
    end

    table.sort(self.tbFriends, fnSort)
end

local function RefreshRelationCount(self)
    self.tbRelationCount = {}
    for type = MIN_RELATION_TYPE, MAX_RELATION_TYPE do  
        local nCount = 0 
        for _, friendInfo in ipairs(self.tbRelationFriends) do
            local tbRelation = friendInfo.relationship 
            local bHasRelation = tbRelation and tbRelation.relationship_id > 0
            local nState = tbRelation.state or 0
            if bHasRelation then   
                if type == tbRelation.relationship_id and nState == Proto.RelationshipState.ESTABLISHED then  
                    nCount = nCount + 1
                end
            end
        end
        self.tbRelationCount[type] = nCount
    end
end

local function ChangeRedDot(self)
    EventManager:OnFireEvent(ClientEventDef.EV_RELATION_NOT_PROCESS_REDDOT)
end

local function RefreshRelationFriends(self)
    self.tbRelationFriends = {}
    local bHasRelation, bCanHaveRelation = false, false
    for i, friendInfo in ipairs(self.tbFriends) do
        local tbRelation = friendInfo.relationship 
        bHasRelation = tbRelation and tbRelation.relationship_id > 0
        bCanHaveRelation = FriendRelationShipLevelDataTable:CanHaveRelation(friendInfo.player_intimacy.intimacy_total)
        if bHasRelation or bCanHaveRelation then  
            table.insert(self.tbRelationFriends, friendInfo)
        end
    end
    RefreshRelationCount(self)
    ChangeRedDot(self)
    EventManager:OnFireEvent(ClientEventDef.EV_REFRESH_RELATION_FRIENDS)
end

function FriendComponent:HasRedDotRelation()
    local bShowRedDot = false
    local nPlayerId = self.Owner:GetPlayerId()
    for i , friendInfo in ipairs(self.tbRelationFriends) do  
        local tbRelation = friendInfo.relationship 
        if tbRelation and tbRelation.state  then
            local bProcessing = tbRelation.state == Proto.RelationshipState.APPLYING or
                tbRelation.state == Proto.RelationshipState.CANCELING 
            local bReciver = nPlayerId ~= tbRelation.applicant_id
            bShowRedDot = bReciver and bProcessing
            if bShowRedDot == true then  
                break
            end
        end
    end
    return bShowRedDot
end

function FriendComponent:GetRelationLimit(nRelationType)
    local tbTemplate = FriendRelationShipDataTable:GetTemplate(nRelationType)
    return tbTemplate.nCountLimit
end

function FriendComponent:GetRelationCount(nRelationType)
    return self.tbRelationCount[nRelationType] or 0
end

function FriendComponent:GetRelationFriends()
    return self.tbRelationFriends
end

function FriendComponent:GetHasRelationFriends()
    local tbRelationFriends = {}
    for i , friendInfo in ipairs(self.tbRelationFriends) do  
        local tbRelation = friendInfo.relationship 
        if tbRelation and tbRelation.state and 
            tbRelation.state == Proto.RelationshipState.ESTABLISHED then
            local tbFriendInfo = Util:LightCopyTable(friendInfo)  
            tbFriendInfo.bOnlyShowInfo = true
            table.insert(tbRelationFriends, tbFriendInfo)
        end
    end
    return tbRelationFriends
end

function FriendComponent:OnCreate(...)
    log("FriendComponent:OnCreate")
    FriendComponent.super.OnCreate(self, ...)
    self.tbFriends = {}
    self.tbApplyFriends = {}
    self.tbRelationFriends = {}
    self.tbRelationCount = {}
    return true
end

function FriendComponent:OnDestroy()
    log("FriendComponent:OnDestroy")
    -- self.tbFriends = nil
    -- self.tbApplyFriends = nil
end

function FriendComponent:SetFriends(tbFriends)
    self.tbFriends = tbFriends
    SortFriends(self)
    RefreshRelationFriends(self)
end

function FriendComponent:SetPriorityPlayer(nPriorityId)
    self.nPriorityFriendId = nPriorityId
    EventManager:OnFireEvent(ClientEventDef.EV_REFRESH_RELATION_FRIENDS)
end

function FriendComponent:GetPriorityPlayer()
    return self.nPriorityFriendId
end

function FriendComponent:SetFriendSummary(tbSummary)
    local tbFriendInfo = self:GetFriend(tbSummary.id)
    if tbFriendInfo ~= nil then
        tbFriendInfo.player_summary = tbSummary
        SortFriends(self)
        return true
    end
end

function FriendComponent:GetFriends()
    return self.tbFriends
end


function FriendComponent:GetFriendSummaries()
    local tbSummaries = {}
    if self.tbFriends ~= nil then
        for i, v in ipairs(self.tbFriends) do
            if v.player_summary ~= nil then
                table.insert(tbSummaries, v.player_summary)
            end
        end
    end
    return tbSummaries
end

function FriendComponent:GetFriend(nId)
    for i, v in ipairs(self.tbFriends) do
        if v.player_id == nId then
            return v, i
        end
    end
end

function FriendComponent:DeleteFriend(nId)
    local tbFriendInfo, nIndex = self:GetFriend(nId)
    local szName 
    if tbFriendInfo ~= nil then
        szName = tbFriendInfo.player_summary and tbFriendInfo.player_summary.name
        table.remove(self.tbFriends, nIndex)
        RefreshRelationFriends(self)
    end
    return szName
end

function FriendComponent:AddFriend(tbPlayerInfo)
    table.insert(self.tbFriends, tbPlayerInfo)
    SortFriends(self)
    RefreshRelationFriends(self)
end

function FriendComponent:RefreshFriend(tbPlayerSummary)
    local tbOld, nIndex = self:GetFriend(tbPlayerSummary.id)
    if tbOld ~= nil then
        self.tbFriends[nIndex].player_summary = tbPlayerSummary
        SortFriends(self)
        RefreshRelationFriends(self)
        return true
    end
    return false
end

function FriendComponent:RefreshFriendIntimacy(nId, tbIntimacyInfo)
    local tbOld, nIndex = self:GetFriend(nId)
    if tbOld ~= nil then
        self.tbFriends[nIndex].player_intimacy = tbIntimacyInfo
        -- SortFriends(self)
        RefreshRelationFriends(self)
    end
end

function FriendComponent:RefreshFriendRelation(nId, tbRelationInfo)
    local tbOld, nIndex = self:GetFriend(nId)
    if tbOld ~= nil then
        self.tbFriends[nIndex].relationship = tbRelationInfo
        SortFriends(self)
        RefreshRelationFriends(self)
    end
end

function FriendComponent:SetTeamRelations(tbTeamRelations, tbTeamPriority)
    self.tbTeamRelations = {}
    if tbTeamRelations and #tbTeamRelations ~= 0 then
        self.tbTeamRelations.tbRelations = tbTeamRelations
        table.sort(self.tbTeamRelations.tbRelations, function(A, B)
            return A.friend_intimacy.intimacy_total >= B.friend_intimacy.intimacy_total
        end)
    else 
        self.tbTeamRelations.tbRelations = {}
    end

    if tbTeamPriority and #tbTeamPriority ~= 0 then
        self.tbTeamRelations.tbPriority = tbTeamPriority
    else
        self.tbTeamRelations.tbPriority = {}
    end
    EventManager:OnFireEvent(ClientEventDef.EV_UPDATE_HEADRELATION)
end

local function MakeRelationItem(self, tbRefShowInfos, nPlayerId, nTargetPlayerId)
    if not tbRefShowInfos[nPlayerId] then 
        local tbTeamRelations = self.tbTeamRelations
        local tbRelations = tbTeamRelations.tbRelations
        for i, v in ipairs(tbRelations) do 
            if (nPlayerId == v.player_id_1 and nTargetPlayerId == v.player_id_2 ) or 
                    (nPlayerId == v.player_id_2 and nTargetPlayerId == v.player_id_1 ) then 
                tbRefShowInfos[nPlayerId] = 
                { 
                    nLevel = v.friend_relationship.relationship_level,
                    nType = v.friend_relationship.relationship_id,
                    nTargetPlayerId = nTargetPlayerId,
                }
            end
        end
    end
end

function FriendComponent:GetTeamRelationInfo()
    local tbTeamRelations = self.tbTeamRelations
    local tbTeamShowInfos = {}
    if tbTeamRelations == nil then  
        return nil
    end

    local tbTeamPlayersInfo = self.Owner.BattleTeamComponent.tbTeamPlayersInfo
    if tbTeamPlayersInfo == nil or tbTeamPlayersInfo.tbPlayerIds == nil then  
        return nil
    end
    local tbTeamPlayerIds = tbTeamPlayersInfo.tbPlayerIds

    local nPriorLen = #tbTeamRelations.tbPriority
    if nPriorLen > 1 then  
        for i = 1, nPriorLen do  
            local nCompare = i + 1
            local tbBaseInfo = tbTeamRelations.tbPriority[i]
            if nCompare <= nPriorLen then 
                for j = nCompare, nPriorLen do 
                    local tbCompareInfo = tbTeamRelations.tbPriority[nCompare]
                    if tbBaseInfo.priority_show_player_id == tbCompareInfo.player_id and tbCompareInfo.priority_show_player_id == tbBaseInfo.player_id then  
                        MakeRelationItem(self, tbTeamShowInfos, tbBaseInfo.player_id, tbCompareInfo.player_id)
                        MakeRelationItem(self, tbTeamShowInfos, tbCompareInfo.player_id, tbBaseInfo.player_id)
                    end
                end
            else  
                break
            end
        end
    end

    local tbPlayerIdLeft = {}
    for _, v in ipairs(tbTeamPlayerIds) do 
        if tbTeamShowInfos[v] == nil then  
            table.insert(tbPlayerIdLeft, v)
        end
    end

    local tbRelations = tbTeamRelations.tbRelations
    for k, v in ipairs(tbRelations) do 
        local tbFoundIndex = {}
        for i , j in ipairs(tbPlayerIdLeft) do 
            if v.player_id_1 == j or v.player_id_2 == j then  
                table.insert(tbFoundIndex, i)
            end
        end

        if #tbFoundIndex > 1 then  
            MakeRelationItem(self, tbTeamShowInfos, v.player_id_1, v.player_id_2)
            MakeRelationItem(self, tbTeamShowInfos, v.player_id_2, v.player_id_1)
            for j = #tbFoundIndex, 1 , -1 do 
                table.remove(tbPlayerIdLeft, tbFoundIndex[j])
            end
        end
    end
    return tbTeamShowInfos
end

function FriendComponent:GetApplyFriend(nId)
    for i, v in ipairs(self.tbApplyFriends) do
        if v.player_id == nId then
            return v, i
        end
    end
end

function FriendComponent:AddApplyFriend(tbPacket)
    table.insert(self.tbApplyFriends, tbPacket)
end

function FriendComponent:DeleteApplyFriend(nId)
    local tbApplyFriend, nIndex = self:GetApplyFriend(nId)
    local szName
    if tbApplyFriend ~= nil then
        szName = tbApplyFriend.player_summary and tbApplyFriend.player_summary.name
        table.remove(self.tbApplyFriends, nIndex)
    end
    return szName
end

function FriendComponent:SetApplyFriendSummary(tbPlayerSummary)
    local tbApplyFriend = self:GetApplyFriend(tbPlayerSummary.id)
    if tbApplyFriend then
        tbApplyFriend.player_summary = tbPlayerSummary
        return true
    end
end

function FriendComponent:ClearApplyFriend()
    self.tbApplyFriends = {}
end

function FriendComponent:SetApplyFriends(tbApplyFriends, tbWatchedIds)
    self.tbApplyFriends = {}
    for i, v in ipairs(tbApplyFriends) do
        v.bWatched = tbWatchedIds[v.player_id]
        table.insert(self.tbApplyFriends, v)
    end
end

function FriendComponent:GetApplyFriends()
    return self.tbApplyFriends
end

function FriendComponent:GetDungeonApplyFriends(nTime)
    local tbResult = {}
    if self.tbApplyFriends == nil then
        return tbResult
    end
    for i, v in ipairs(self.tbApplyFriends) do
        if v.apply_time > nTime and v.source == Proto.FriendSource.TRAINING_CAMP 
            and v.player_summary ~= nil then
            table.insert(tbResult, v)
        end
    end

    return tbResult
end

-- function FriendComponent:SetApplyCount(nCount)
--     self.nApplyCount = nCount
-- end

function FriendComponent:HadApplies()
    for i, v in ipairs(self.tbApplyFriends) do
        if v.bWatched == nil then
            return true
        end
    end    
    return false
end

function FriendComponent:WatchApplyInfo(nTime)
    for i, v in ipairs(self.tbApplyFriends) do
        if v.apply_time > nTime and v.source == Proto.FriendSource.TRAINING_CAMP then
            v.bWatched = true
        end
    end
end

return FriendComponent