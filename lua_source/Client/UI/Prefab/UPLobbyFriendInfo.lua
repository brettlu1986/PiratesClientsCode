local luaclass           = require("luaclass")
local ListItemBase       = require("ListItemBase")
local UPLobbyFriendInfo  = luaclass("UPLobbyFriendInfo", ListItemBase)
local UISetUtils         = require("UISetUtils")
local UIResourceDef      = require("UIResourceDef")
local GenderTypeDefine   = require("GenderTypeDefine")
local FriendSystem       = require("FriendSystem")
local UIUtils            = require("UIUtils")
local UIDef              = require("UIDef")
local UIManager          = require("UIManager")
local L10N               = require("L10N")
local UITextDef          = require("UITextDef")
local AvatarDataTable    = require("AvatarDataTable")
local HumanDataTable     = require("HumanDataTable")
local Proto              = require("ClientProtoNames")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
-- local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local ClientEventDef     = require("ClientEventDef")
local EventManager       = require("EventManager")
local RankDataTable      = require("RankDataTable")
local FriendRelationShipLevelDataTable = require("FriendRelationShipLevelDataTable")
local LobbyChatSystem    = require("LobbyChatSystem")
local SeasonHelper       = require("SeasonHelper")

local TYPE_FRIEND = 1 -- 好友
local TYPE_TEAM   = 2 -- 最近组队
local TYPE_NEAR   = 3 -- 附近的人
local TYPE_ADDFRIEND = 4 -- 添加好友

-- local UI_STATIC_BATTLE_GOOPEN = UISetUtils.GetL10NTextByKey("UI_STATIC_BATTLE_GOOPEN")

local ONE_MINITE = 60
local ONE_HOUR = ONE_MINITE*60
local ONE_DAY = ONE_HOUR*24
local MAX_TEAM_TIME = 30 * ONE_DAY
local DEFAULT_RANK = 11

local TIME_TABLE = {
    {nTime = ONE_DAY,   l10nTime = UITextDef.SELFTIMECALCULATEHELPER_L10N_DAY},
    {nTime = ONE_HOUR,  l10nTime = UITextDef.SELFTIMECALCULATEHELPER_L10N_HOUR},
    {nTime = ONE_MINITE,l10nTime = UITextDef.SELFTIMECALCULATEHELPER_L10N_MIN}
}

local BATTLE_MODE = {
    [1] = UITextDef.BATTLE_MODE_ONE,
    [2] = UITextDef.BATTLE_MODE_TWO,
    [4] = UITextDef.BATTLE_MODE_FOUR
}

UPLobbyFriendInfo.tbData = nil
UPLobbyFriendInfo.tbFriendInfo = nil
UPLobbyFriendInfo.pbHead = nil

local function ResetUI(self, nType)
    local pWidgetRef = self.pWidgetRef
    local Visible, Collapsed = ESlateVisibility.Visible, ESlateVisibility.Collapsed

    pWidgetRef.hboxRange:SetVisibility(Collapsed)
    pWidgetRef.txtState:SetText("")
    pWidgetRef.hboxTeam:SetVisibility(nType == TYPE_TEAM and Visible or Collapsed)
    pWidgetRef.hboxFriend:SetVisibility(nType == TYPE_FRIEND and Visible or Collapsed)
    pWidgetRef.btn04:SetVisibility((nType == TYPE_ADDFRIEND or nType == TYPE_TEAM) and Visible or Collapsed)
end

local function GetGenderRes(nAvatarId)
    local tbAvatarData = AvatarDataTable:GetTemplate(nAvatarId)
    if tbAvatarData == nil then 
        return UIResourceDef.GENDER_MALE
    end 
    local tbHumanData = HumanDataTable:GetTemplate(tbAvatarData.nHumanId)
    if tbHumanData == nil then
        return UIResourceDef.GENDER_MALE
    end
    return tbHumanData.nGender == GenderTypeDefine.MALE and UIResourceDef.GENDER_MALE or UIResourceDef.GENDER_FEMALE
end

local function RefreshBaseInfo(self)
    local pWidgetRef = self.pWidgetRef
    local tbData = self.tbData
    local nId = tbData.id or tbData.nId

    local nAvatarId = tbData.avatar_id or tbData.nAvatarId
    local szName = tbData.name or tbData.szName
    local nLevel = tbData.level or 1
    -- 头像，等级
    self.pbHead:SetPlayerHead(nAvatarId, nLevel)
    self.pbHead:SetPlayerId(nId)
    -- 性别
    local szGender = GetGenderRes(nAvatarId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGender:load(), true)
    -- 名字
    pWidgetRef.txtName:SetText(szName)
    -- 段位
    local tbRankTemp = RankDataTable:GetTemplate(tbData.rank)
    if tbRankTemp == nil then
        tbRankTemp = RankDataTable:GetTemplate(DEFAULT_RANK)
    end
    local szRankImg, szSubRankImg = SeasonHelper.GetIcon(tbRankTemp.nRank)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRank, szRankImg:load())
    if szSubRankImg ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgRankNumber, szSubRankImg:load())
        local szRankName = L10N:ToString(tbRankTemp.l10nName)..tbRankTemp.szRankLevelName
        pWidgetRef.ktxtRank:SetText(szRankName)
    else
        pWidgetRef.imgRankNumber:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.ktxtRank:SetText(tbRankTemp.l10nName)
    end
end

local function GetTimeStr(nTime, bShowBefore, nMaxTime)
    local nOverTime = math.max(GlobalVariableSystem_C:GetServerTimeUtc() - nTime, ONE_MINITE)
    if nMaxTime and nOverTime > nMaxTime then
        nOverTime = nMaxTime
    end 
    for _, v in ipairs(TIME_TABLE) do
        if nOverTime >= v.nTime then
            local nT = math.floor(nOverTime / v.nTime)
            local l10nT = L10N:Format(v.l10nTime, nT)
            if bShowBefore then
                return L10N:Format(UITextDef.FFA_OVERTIMER, l10nT)
            else
                return l10nT
            end
        end
    end
end

local function HasRelation(self)
    local tbRelationShip = self.tbFriendInfo.relationship
    local nState = tbRelationShip.state
    local nLevel = tbRelationShip.relationship_level
    if nState > Proto.RelationshipState.APPLYING and nLevel ~= nil then  
        return true
    end
    return false
end

local function RefreshIntimacyAndRelationInfo(self)
    if not self.tbFriendInfo then return end
    local tbFriendIntimacy = self.tbFriendInfo.player_intimacy or 0
    local nTotalIntimacy = 0
    if tbFriendIntimacy then 
        nTotalIntimacy = tbFriendIntimacy.intimacy_total
    end

    local bShowRelationInfo = HasRelation(self)
    local Visible, Collapsed = ESlateVisibility.HitTestInvisible, ESlateVisibility.Collapsed
    
    local tbData = self.tbData.player_summary or self.tbData
    local bSendToday = FriendSystem:IsSendCoinToday(tbData.id)
    log("[SendCoin] RefreshIntimacyAndRelationInfo ", tbData.id, bSendToday)
    self.pWidgetRef.bdrSendCoin:SetVisibility(bSendToday and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
    -- logdebug("bSendToday ::", bSendToday)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.hbIntimacy:SetVisibility(bShowRelationInfo and Collapsed or Visible)
    pWidgetRef.hbRelation:SetVisibility(bShowRelationInfo and Visible or Collapsed)
    if bShowRelationInfo then 
        local nRelationType = self.tbFriendInfo.relationship.relationship_id
        local nRelationLevel = self.tbFriendInfo.relationship.relationship_level
        local tbRelationLevelData = FriendRelationShipLevelDataTable:GetDataTemplate(nRelationType, nRelationLevel) 
        local nNextLevelTotalIntimacy = FriendRelationShipLevelDataTable:GetNextLevelIntimacy(nRelationType, nRelationLevel)
        pWidgetRef.txtRelationLv:SetText(tbRelationLevelData.nLevel)
        pWidgetRef.txtRelationName:SetText(tbRelationLevelData.l10nName)
        pWidgetRef.txtRelationName:SetColorAndOpacity(UIResourceDef.FRIEND_RELATION_TXT_COLOR[nRelationType])
        UISetUtils.SetBorderBrushRes(pWidgetRef.bdrRelation, UIResourceDef.FRIEND_RELATION_IMG[nRelationType]:load())
        pWidgetRef.txtIntimacyNum:SetText(string.format("%d/%d", nTotalIntimacy, nNextLevelTotalIntimacy))
    else  
        local bCanHaveRelation = FriendRelationShipLevelDataTable:CanHaveRelation(nTotalIntimacy)
        pWidgetRef.imgIntimacy:SetIsEnabled(bCanHaveRelation)
        pWidgetRef.txtIntimacyCount:SetText(nTotalIntimacy)
    end
end

local function RefreshFriendInfo(self)
    -- 状态（离线时间，空闲，副本。。。）
    -- 
    local tbData = self.tbData
    local nState = tbData.status
    local szState

    local pWidgetRef = self.pWidgetRef
    if nState == Proto.PlayerStatus.OFFLINE then    
        -- logerror("/////", tbData.status_time, GlobalVariableSystem_C:GetServerTimeUtc())
        local l10nTime = GetTimeStr(tbData.status_time, true)
        szState = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_FRIEND_STATE_OFFLINE_TIME"), l10nTime)
    elseif nState == Proto.PlayerStatus.IDLE then
        if tbData.team_size > 0 then
            szState = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_FRIEND_STATE_TEAMING"), tbData.team_size)
        else
            szState = UISetUtils.GetL10NTextByKey("FFA_FRIEND_STATE_IDLE")
        end
    elseif nState == Proto.PlayerStatus.MATCHMAKING then
        szState = UISetUtils.GetL10NTextByKey("FFA_FRIEND_STATE_MATCHMAKING")
    elseif nState == Proto.PlayerStatus.BATTLING then
        -- local tbMatchmakingTeamMode = MatchmakingTeamModeDataTable:GetTemplate(tbData.dungeon_team_mode > 0 and tbData.dungeon_team_mode or 1)
        local l10nTime = GetTimeStr(tbData.status_time, false)
        if GlobalVariableSystem_C:IsInTrainingCamp(tbData.dungeon_id) then
            szState = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_FRIEND_STATE_BATTLING"), UISetUtils.GetL10NTextByKey("LOBBY_TEAM_TRAINING_MODE"), l10nTime)
        else
            szState = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_FRIEND_STATE_BATTLING"), UISetUtils.GetL10NTextByKey("LOBBY_TEAM_MODE_CLASSIC"), l10nTime)
        end
    end
    pWidgetRef.txtState:SetText(szState)

    RefreshIntimacyAndRelationInfo(self)
end

local function OnSendSuccess(self, nPlayerId)
    if self.tbData then
        local tbData = self.tbData.player_summary or self.tbData
        if tbData and tbData.id == nPlayerId then
            local bSendToday = FriendSystem:IsSendCoinToday(nPlayerId)
            log("[SendCoin] OnSendSuccess ", nPlayerId, bSendToday)
            self.pWidgetRef.bdrSendCoin:SetVisibility(bSendToday and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
        end
    else  
        log("OnSendSuccess try to hide send coin btn, btn tbData is nil", nPlayerId)
    end
end

local function OnRefreshIntimacyChange(self, nPlayerId)
    if self.tbData then
        local tbData = self.tbData.player_summary or self.tbData
        if tbData and tbData.id == nPlayerId then
            RefreshIntimacyAndRelationInfo(self)
        end
    else  
        log("OnRefreshIntimacyChange try to hide send coin btn, btn tbData is nil", nPlayerId)
    end
end

local function GetDataType(self)
    if self.tbData.id and self.tbData.bSearch then
        return TYPE_ADDFRIEND
    elseif self.tbData.id and FriendSystem:GetComponent():GetFriend(self.tbData.id) ~= nil then
        return TYPE_FRIEND
    elseif self.tbData.rank and self.tbData.player_count then
        return TYPE_TEAM
    end
end

local function RefreshTeamInfo(self)
    local tbData = self.tbData
    local pWidgetRef = self.pWidgetRef
    -- 排名
    pWidgetRef.txtRank:SetText(tbData.rank.."/"..tbData.player_count)
    -- 淘汰
    pWidgetRef.txtKillCount:SetText(tbData.kill)
    -- 模式
    pWidgetRef.txtMode:SetText(BATTLE_MODE[tonumber(tbData.mode)])
    -- 时间
    local l10nTime = GetTimeStr(tbData.battle_time, true, MAX_TEAM_TIME)
    pWidgetRef.txtTime:SetText(l10nTime)
    pWidgetRef.hbIntimacy:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hbRelation:SetVisibility(ESlateVisibility.Collapsed)
end

local function RefreshNearInfo(self)
    self.pWidgetRef.hbIntimacy:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.hbRelation:SetVisibility(ESlateVisibility.Collapsed)
end

local function RefreshAddFriendInfo(self)
    self.pWidgetRef.hbIntimacy:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.hbRelation:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnClickAdd(self)
    local nId = self.tbData.id or self.tbData.nId
    if FriendSystem:GetComponent():GetFriend(nId) ~= nil then
        UIUtils.ShowToast(UITextDef.ALREADY_IN_FRIEND)
    else
        local nType = GetDataType(self) 
        if nType == TYPE_TEAM then
            self.tbData.szMsg = L10N:ToString(UISetUtils.GetL10NTextByKey("FFA_APPLYFRIEND_MESSAGE_BYTEAM"))
            self.tbData.nSource = Proto.FriendSource.FRIEND_RECENT
        else
            self.tbData.szMsg = L10N:ToString(UISetUtils.GetL10NTextByKey("FFA_APPLYFRIEND_MESSAGE"))
            self.tbData.nSource = Proto.FriendSource.PRECISE
        end
        UIManager:OpenWnd(UIDef.UI_LOBBY_FRIEND_ADD, self.tbData)
    end
end

local function OnClickDelete(self)
    local tbData = self.tbData
    local fnOk = function()
        FriendSystem:RequestDeleteFriend(tbData.id)
    end
    local l10nTitle = UISetUtils.GetL10NTextByKey("UIPLAYERTIPS_L10N_DELETEFRIEND")
    local szName = "<text color=\"#D47D00FF\">"..tbData.name.."</>"
    local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("UIPLAYERTIPS_L10N_DELETEFRIENDCONFIRM"), szName)
    UIUtils.ShowDialog(l10nTitle, l10nMessage, UITextDef.L10N_OK, fnOk, UITextDef.COMMAND_CANCEL)
end

local function OnClickChat(self)
    self.Owner:CloseSelf()
    local tbData = self.tbData
    local nPlayerId = tbData.id
    if GlobalVariableSystem_C.bEnterLobby3D then
        local tbArgs = {}
        tbArgs.eChannel = LobbyChatSystem.CHAT_FRIEND
        tbArgs.nFriendId = nPlayerId
        UIManager:OpenWnd(UIDef.UI_LOBBY_CHAT, tbArgs)
    else       
        EventManager:OnFireEvent(ClientEventDef.EV_OPEN_LOBBY_CHAT_FRIEND, nPlayerId)
    end
end

local function OnClickSendCoin(self)
    -- UIUtils.ShowToast(UI_STATIC_BATTLE_GOOPEN, 0.2)
    local tbData = self.tbData.player_summary or self.tbData
    log("[SendCoin] OnClickSendCoin click to send coin to ", tbData.id)
    FriendSystem:RequestSendCoin(tbData.id)
end

function UPLobbyFriendInfo:OnCreate()

end

function UPLobbyFriendInfo:OnDestroy()
    self.pbHead = nil
end

function UPLobbyFriendInfo:OnLoad()
    local PrefabHelper = self.PrefabHelper
    self.pbHead = PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerHead)
    self.pbHead:EnableClickHeadDefaultAction(true)
end

function UPLobbyFriendInfo:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btn04.OnClicked, self, OnClickAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.btn03.OnClicked, self, OnClickDelete)
    EventHelper:RegisterCppDelegate(pWidgetRef.btn02.OnClicked, self, OnClickChat)
    EventHelper:RegisterCppDelegate(pWidgetRef.btn01.OnClicked, self, OnClickSendCoin)

    EventHelper:RegisterEvent(ClientEventDef.EV_SEND_COIN_SUCCESS, self, OnSendSuccess)
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_IMTIMACY_CHANGE, self, OnRefreshIntimacyChange)
    
end

function UPLobbyFriendInfo:OnRefresh(tbData)
    self.tbData = tbData
    self.tbFriendInfo = FriendSystem:GetComponent():GetFriend(self.tbData.id)

    local nType = GetDataType(self) 
    ResetUI(self, nType)
    RefreshBaseInfo(self)
    if nType == TYPE_FRIEND then
        RefreshFriendInfo(self)
    elseif nType == TYPE_TEAM then
        RefreshTeamInfo(self)
        -- RefreshFriendInfo(self)
    elseif nType == TYPE_NEAR then
        RefreshNearInfo(self)
    elseif nType == TYPE_ADDFRIEND then
        RefreshAddFriendInfo(self)
    else
        logwarning("UPLobbyFriendInfo invalid type", nType)
    end
end

return UPLobbyFriendInfo
