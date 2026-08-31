-----------------------------------------------------
--File Name    : UPLobbyChatFriendItem.lua
--Author       : Edward J
--Create Time  : 2018-04-16
--Description  : UPLobbyChatFriendItem
-----------------------------------------------------
local luaclass                  = require("luaclass")
local ListItemBase              = require("ListItemBase")
local UPLobbyChatFriendItem     = luaclass("UPLobbyChatFriendItem", ListItemBase)

local Proto                 = require("ClientProtoNames")
local TeamSystem            = require("TeamSystem")
--local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local HumanDataTable        = require("HumanDataTable")
local GenderTypeDefine      = require("GenderTypeDefine")
local UIResourceDef         = require("UIResourceDef")
local UISetUtils            = require("UISetUtils")
local L10N                  = require("L10N")
local ClientEventDef        = require("ClientEventDef")
local EventManager          = require("EventManager")
local RankDataTable         = require("RankDataTable")
local SeasonHelper          = require("SeasonHelper")
-----------------------------------------------------
-- local Visible                   = ESlateVisibility.Visible
local Collapsed                 = ESlateVisibility.Collapsed
local HitTestInvisible          = ESlateVisibility.HitTestInvisible
local IDLE                      = Proto.PlayerStatus.IDLE
local BATTLING                  = Proto.PlayerStatus.BATTLING
local MATCHMAKING               = Proto.PlayerStatus.MATCHMAKING
local OFFLINE                   = Proto.PlayerStatus.OFFLINE
local RANK_SUB_MAX              = 5

UPLobbyChatFriendItem.pbPlayerHead  = nil
UPLobbyChatFriendItem.nPlayerId     = nil
UPLobbyChatFriendItem.szName        = nil
UPLobbyChatFriendItem.bCliecked     = false
-----------------------------------------------------

local function TransformationSubRank(nSubRank)
    if nSubRank == 0 then
        return nSubRank
    else
        return RANK_SUB_MAX - nSubRank + 1
    end
end

local function RefreshRnakInfo(self, nRank)
    local pWidgetRef = self.pWidgetRef
    local nSubRank = math.fmod(nRank, 10)
    nSubRank = TransformationSubRank(nSubRank)
    local tbRankData = RankDataTable:GetTemplate(nRank)
    if not tbRankData then
        return
    end
    if nSubRank == 0 then--最高段位
        pWidgetRef.ktxtRank:SetText(tbRankData.l10nName)
    else
        nSubRank = math.min(nSubRank, RANK_SUB_MAX)
        local szRankName = L10N:ToString(tbRankData.l10nName)..tbRankData.szRankLevelName
        pWidgetRef.ktxtRank:SetText(szRankName)
    end
    local szRankImg, szRankNumImg = SeasonHelper.GetIcon(nRank)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRank, szRankImg:load())
    if szRankNumImg ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgRankNumber, szRankNumImg:load())
    else
        pWidgetRef.imgRankNumber:SetVisibility(ESlateVisibility_Collapsed)
    end
end

local function SetOfflineAppearance(self, bOffline)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgSex:SetIsEnabled(not bOffline)
    pWidgetRef.imgRank:SetIsEnabled(not bOffline)
    pWidgetRef.txtStatus:SetIsEnabled(not bOffline)
    self.pbPlayerHead:SetOfflineAppearance(bOffline)
end

local function RefreshPlayerStatus(self, nStatus, nStatusTime, nTeamSize)
    local pWidgetRef = self.pWidgetRef
    local szStatus = ""
    -- pWidgetRef.pbPlayerHead:SetIsEnabled(true)
    SetOfflineAppearance(self, false)
    local nTeamMemberCountLimit = TeamSystem:GetTeamMemberCountLimit()
    if nStatus == IDLE then
        szStatus = (nTeamSize > 0) and L10N:Format(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IN_TEAM"), nTeamSize, nTeamMemberCountLimit) or UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IDLE")
    elseif nStatus == BATTLING then
        --local nDiffSeconds = GlobalVariableSystem:GetServerTimeUtc() - nStatusTime
        --local nMinute = math.floor(nDiffSeconds / 60)
        szStatus = UISetUtils.GetL10NTextByKey("LOBBY_CHAT_TEAM_IN_BATTLE")
    elseif nStatus == MATCHMAKING then
        szStatus = UISetUtils.GetL10NTextByKey("UI_LOBBY_MATCHMAKING")
    elseif nStatus == OFFLINE then
        szStatus = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_OFFLINE")
        -- pWidgetRef.pbPlayerHead:SetIsEnabled(false)
        SetOfflineAppearance(self, true)
    end
    pWidgetRef.txtStatus:SetText(szStatus)
end

local function RefreshPlayerGenderIcon(self, nAvatarId)
    local pWidgetRef = self.pWidgetRef
    local tbHumanTemplate = HumanDataTable:GetTemplate(nAvatarId)
    if tbHumanTemplate then
        local nGenderType = tbHumanTemplate.nGender
        local szGenderIcon = (nGenderType == GenderTypeDefine.MALE) and UIResourceDef.GENDER_MALE or UIResourceDef.GENDER_FEMALE
        UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGenderIcon:load(), true)
    end
end

local function OnBtnClicked(self)
    if self.bCliecked then
        return
    end
    self.bCliecked = true
    EventManager:OnFireEvent(ClientEventDef.EV_CHAT_CLICK_FRIEND, self.nIndex, self.nPlayerId, self.szName)
    EventManager:OnFireEvent(ClientEventDef.EV_CHAT_RESET_FRIEND_UREAD_STATE,self.nPlayerId)
    self.pWidgetRef.ovlTipIcon:SetVisibility(Collapsed)
end

local function OnOtherItemClicked(self, nIndex, nPlayerId, szName)
    if nIndex == self.nIndex then
        return
    end
    self.bCliecked = false
end

function UPLobbyChatFriendItem:OnRefresh(tbData)
    if not tbData then
        return
    end
    local tbPlayerData = tbData
    local pWidgetRef = self.pWidgetRef
    local nPlayerId = tbPlayerData.id
    local szName = tbPlayerData.name
    self.nPlayerId = nPlayerId
    self.szName = szName
    local nStatus = tbPlayerData.status
    local nStatusTime = tbPlayerData.status_time
    local nTeamSize = tbPlayerData.team_size
    local nAvatarId = tbPlayerData.avatar_id
    local nLevel = tbPlayerData.level
    local nUnreadMsgCount = tbData.nUnreadMsgCount
    local nRank = tbPlayerData.rank

    pWidgetRef.imgSelected:SetVisibility(self:IsSelected() and HitTestInvisible or Collapsed)
    pWidgetRef.txtName:SetText(szName)
    RefreshPlayerGenderIcon(self, nAvatarId)
    self.pbPlayerHead:SetPlayerHead(nAvatarId, nLevel)
    RefreshPlayerStatus(self, nStatus, nStatusTime, nTeamSize)
    RefreshRnakInfo(self, nRank)
    if not self:IsSelected() then
        pWidgetRef.ovlTipIcon:SetVisibility(nUnreadMsgCount > 0 and HitTestInvisible or Collapsed)
    else
        EventManager:OnFireEvent(ClientEventDef.EV_CHAT_RESET_FRIEND_UREAD_STATE,self.nPlayerId)
    end
end

function UPLobbyChatFriendItem:OnLoad()
    self.tbHBox = {}
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    self.pbPlayerHead = PrefabHelper:BindPrefab(pWidgetRef.pbPlayerHead)      
end

function UPLobbyChatFriendItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterEvent(ClientEventDef.EV_CHAT_CLICK_FRIEND, self, OnOtherItemClicked)

    EventHelper:RegisterCppDelegate(pWidgetRef.btnClick.OnClicked, self, OnBtnClicked)
end

return UPLobbyChatFriendItem