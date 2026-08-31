local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyFriendRelations = luaclass("ULLobbyFriendRelations", UILogicBase)

local SelfVerticalListHelper= require("SelfVerticalListHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local Proto = require("ClientProtoNames")
local ClientEventDef = require("ClientEventDef")
local FriendSystem = require("FriendSystem")
local PlayerInfoSystem = require("PlayerInfoSystem")
local Util = require("BaseUtil")

ULLobbyFriendRelations.pRelationList = nil
ULLobbyFriendRelations.bActivate = false
ULLobbyFriendRelations.tbRelationListHelper = nil
ULLobbyFriendRelations.bOnlyShowInfo = false
ULLobbyFriendRelations.nCurrentPlayerId = nil
ULLobbyFriendRelations.nSelfPlayerId = nil

ULLobbyFriendRelations.tbOtherRelationFriends = nil
ULLobbyFriendRelations.tbRegiserEvent = nil

local function LOG(...)
    log("[ULLobbyFriendRelations]:", ...)
end

local function OnRelationFriendsRefresh(self)
    if not self.bActivate or self.nSelfPlayerId ~= self.nCurrentPlayerId then  
        return 
    end
    local Component = FriendSystem:GetComponent()
    local tbRelationFriends = self.bOnlyShowInfo and  Component:GetHasRelationFriends() or Component:GetRelationFriends()
    
    self.tbRelationListHelper:SetData(tbRelationFriends)
end

local function RefreshOtherRelationSummaryAndShow(self, tbSummariesArray)
    LOG("RefreshOtherRelationSummaryAndShow tbSummariesArray", t2s(tbSummariesArray))
    LOG("RefreshOtherRelationSummaryAndShow tbOtherRelationFriends", t2s(self.tbOtherRelationFriends))
    for _, friendInfo in ipairs(self.tbOtherRelationFriends) do 
        for _, summary in ipairs(tbSummariesArray) do 
            if summary.id == friendInfo.player_id then  
                friendInfo.player_summary = summary
                break
            end
        end
    end
    local bAllSummaryReady = true
    for _, friendInfo in ipairs(self.tbOtherRelationFriends) do 
        if not friendInfo.player_summary or friendInfo.player_summary.id == 0 then  
            bAllSummaryReady = false 
            break
        end
    end

    if bAllSummaryReady then  
        LOG("all summary ready")
        self.tbRelationListHelper:SetData(self.tbOtherRelationFriends)
    end
end

local function OnOtherRelationFriendsRefresh(self, tbData)
    if tbData and tbData.friend_info and tbData.return_code == Proto.ReturnCode.OK then 
        self.tbOtherRelationFriends = {}
        local tbPlayerIds = {}
        for i, friendInfo in pairs(tbData.friend_info) do  
            local tbFriendInfo = Util:LightCopyTable(friendInfo)  
            tbFriendInfo.bOnlyShowInfo = true
            table.insert(self.tbOtherRelationFriends, tbFriendInfo)
            table.insert(tbPlayerIds, friendInfo.player_id)
        end
        LOG("the all other ids :", t2s(tbPlayerIds))
        local tbCachedPlayerIds, tbNoCachedPlayerIds = PlayerInfoSystem:HasPlayerSummaries(tbPlayerIds)
        LOG("the tbCachedPlayerIds :", t2s(tbCachedPlayerIds))
        LOG("the tbNoCachedPlayerIds :", t2s(tbNoCachedPlayerIds))
        PlayerInfoSystem:RequestPlayerSummariesFromServer(tbNoCachedPlayerIds)

        local tbSummaries = PlayerInfoSystem:GetPlayerSummariesFromLocal(tbCachedPlayerIds)
        local tbSummariesArray = {}
        for k, v in pairs(tbSummaries) do
            table.insert(tbSummariesArray, v)
        end
        RefreshOtherRelationSummaryAndShow(self, tbSummariesArray)
    end
    if tbData and tbData.return_code == Proto.ReturnCode.FORBID_VIEW_INTIMACY then 
        self.tbRelationListHelper:SetData({})
        LOG(" fobidden see friend relations")
    end
end

local function RegisterEvent(self, nEventId, func)
    if self.tbRegiserEvent[nEventId] == nil then  
        LOG("register event once =======================")
        self.EventHelper:RegisterEvent(nEventId, self, func)
        self.tbRegiserEvent[nEventId] = true
    end
end

function ULLobbyFriendRelations:OnCreate()
    self.tbRelationListHelper = SelfVerticalListHelper()
end

function ULLobbyFriendRelations:OnLoad()
    
end

function ULLobbyFriendRelations:OnUnload()
    self.tbRelationListHelper:Uninit()
    self.tbRelationListHelper = nil
end

function ULLobbyFriendRelations:OnBindEvent(EventHelper)
    ULLobbyFriendRelations.super.OnBindEvent(self, EventHelper)
end

function ULLobbyFriendRelations:UnbindEvent()
    ULLobbyFriendRelations.super.UnbindEvent(self)
end

function ULLobbyFriendRelations:Activate(pRelationsList, bOnlyShowInfo, nPlayerId)
    if self.tbRegiserEvent == nil then  self.tbRegiserEvent = {} end
    if bOnlyShowInfo then  
        LOG("register event for show info ")
        RegisterEvent(self, ClientEventDef.EV_GET_FRIEND_RELATIONS, OnOtherRelationFriendsRefresh)
        RegisterEvent(self, ClientEventDef.EV_PLAYER_SUMMARIES_RECEIVED, RefreshOtherRelationSummaryAndShow)
    else  
        LOG("register event for not show info ")
        RegisterEvent(self, ClientEventDef.EV_REFRESH_RELATION_FRIENDS, OnRelationFriendsRefresh)
    end

    self.nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    self.nCurrentPlayerId = nPlayerId
    self.bActivate = true
    self.bOnlyShowInfo = bOnlyShowInfo
    if self.pRelationList ~= pRelationsList then
        self.pRelationList = pRelationsList
        self.tbRelationListHelper:Init(self, pRelationsList)
    end

    LOG("the show info :", self.nSelfPlayerId, self.nCurrentPlayerId)
    if self.nSelfPlayerId and self.nCurrentPlayerId and self.nSelfPlayerId == self.nCurrentPlayerId then
        OnRelationFriendsRefresh(self)
    else  
        FriendSystem:RequestGetFriendRelations(self.nCurrentPlayerId)
    end
end

function ULLobbyFriendRelations:Deactivate()
    self.bActivate = false
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_GET_FRIEND_RELATIONS)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_PLAYER_SUMMARIES_RECEIVED)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_REFRESH_RELATION_FRIENDS)
    self.tbRegiserEvent = nil
end

return ULLobbyFriendRelations