-----------------------------------------------------
--File Name    : UPPlayerBasicInfo.lua
--Author       : WuJizhou
--Create Time  : 3/21/2019, 8:36:50 PM
--Description  : UPPlayerBasicInfo
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPPlayerBasicInfo = luaclass("UPPlayerBasicInfo", PrefabBase)
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UITextDef = require("UITextDef")
local UIUtils = require("UIUtils")
local PlayerLevelDataTable = require("PlayerLevelDataTable")
local RankDataTable = require("RankDataTable")
local L10N = require("L10N")
-- local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local SeasonSystem = require("SeasonSystem")
local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local FriendSystem = require("FriendSystem")
local SeasonIni = require("SeasonIni")


UPPlayerBasicInfo.ulPlayerInfo = nil
UPPlayerBasicInfo.pbPlayHead = nil
UPPlayerBasicInfo.pbModeRank = nil
UPPlayerBasicInfo.pbBestRank = nil

local tbMode = {
    SINGLE_MODE = 1,
    COUPLE_MODE = 2,
    TEAM_MODE = 4,
}

local SEASON_WARRIOR_IMG = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_LobbySeason07.Spr_LobbySeason07'"
local SEASON_HERO_IMG = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_LobbySeason07High.Spr_LobbySeason07High'"
local SEASON_WARRIOR_BG_IMG = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_LobbySeason07Bg.Spr_LobbySeason07Bg'"
local SEASON_HERO_BG_IMG = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_LobbySeason07HighBg.Spr_LobbySeason07HighBg'"


local function RefreshPointRanking(self, nSeasonPointRanking, nSeasonParticipants)
    local nPlayerId = self.ulPlayerInfo:GetTargetPlayerId()
    local tbBasicInfo = self.ulPlayerInfo:GetPlayerBasicInfo(nPlayerId)
    if tbBasicInfo ~= nil then
        local txtRank = self.pWidgetRef.txtRank
        local nSeasonRanking = SeasonIni.tbRanking.nSeasonRanking
        local nRanking = nSeasonPointRanking or 0
        local nCount = nSeasonParticipants or 1
        if nRanking == 0 then
            txtRank:SetText("99%")
        elseif nRanking <= nSeasonRanking then
            txtRank:SetText(nRanking)
        else
            local szRanking = math.floor(nRanking * 100 / nCount).."%"
            txtRank:SetText(szRanking)
        end
    else
        log("RefreshPointRanking basic info is nil ", nPlayerId)
    end
end

local function OnBasicInfoReceived(self, tbBasicInfo)
    if self.ulPlayerInfo:GetTargetPlayerId() == tbBasicInfo.nPlayerId then
        local nAvatarId = tbBasicInfo.nAvatarId
        self.pbPlayHead:SetPlayerHead(nAvatarId)
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.ktxtPlayerName:SetText(tbBasicInfo.szName)
        pWidgetRef.ktxtPlayLevel:SetText(L10N:Format(UITextDef.UI_BASIC_LEVEL, tbBasicInfo.nLevel))
        pWidgetRef.ktxtPlayerId:SetText(tbBasicInfo.nPlayerId)
        local nExp = tbBasicInfo.nExp
        local nCurLevelMaxExp = PlayerLevelDataTable:GetTemplate(tbBasicInfo.nLevel).nExp
        pWidgetRef.txtExp:SetText(string.format("%d/%d", nExp, nCurLevelMaxExp))
        pWidgetRef.pgbExp:SetPercent(nExp / nCurLevelMaxExp)


    end
end


local function OnBasicSeasonInfoReceived(self, tbBasicInfo)
    if self.ulPlayerInfo:GetTargetPlayerId() == tbBasicInfo.nPlayerId then
        local pWidgetRef = self.pWidgetRef

        local nBestRank = tbBasicInfo.tbBestRank.nRank
        local tbTemplate = RankDataTable:GetTemplate(nBestRank)
        if not tbTemplate then
            return
        end

        local nBestRankCount = tbBasicInfo.nBestRankCount
        pWidgetRef.ktxtBestRankCount:SetText(L10N:Format(UITextDef.PLAYER_INFO_BEST_RANK_COUNT, tbTemplate.l10nName, nBestRankCount))
        pWidgetRef.ktxtSeasonPoint:SetText(tbBasicInfo.nSeasonPoint)

        RefreshPointRanking(self, tbBasicInfo.nPointRanking, tbBasicInfo.nParticipants)

        local tbCurrentRank = tbBasicInfo.tbCurrentRank
        for nMode, tbRank in pairs(tbCurrentRank) do
            local tbData = {}
            tbData.mode = tbRank.nMode
            tbData.rank = tbRank.nRank
            tbData.rank_point = tbRank.nRankPoint
            self.pbModeRank[nMode]:OnRefresh(tbData)
        end
        local tbBestData = {}
        tbBestData.rank = tbBasicInfo.tbBestRank.nRank
        tbBestData.rank_point = tbBasicInfo.tbBestRank.nRankPoint
        self.pbBestRank:OnRefresh(tbBestData)
        -- local szImage = UIResourceDef.NEW_SEASON_PASS_IMAGE
        if tbBasicInfo.bBattlePassActive then
            UISetUtils.SetBorderBrushRes(pWidgetRef.bdrRank, SEASON_HERO_IMG:load())
            UISetUtils.SetBorderBrushRes(pWidgetRef.bdrSeason, SEASON_HERO_BG_IMG:load())
            -- UISetUtils.SetBorderBrushColor(pWidgetRef.bdrRank, UIResourceDef.COLOR.YELLOW1)
            pWidgetRef.txtBattlePass:SetText(UISetUtils.GetL10NTextByKey("SEASON_BATTLE_HERO"))
        else
            UISetUtils.SetBorderBrushRes(pWidgetRef.bdrRank, SEASON_WARRIOR_IMG:load())
            UISetUtils.SetBorderBrushRes(pWidgetRef.bdrSeason, SEASON_WARRIOR_BG_IMG:load())
            -- UISetUtils.SetBorderBrushColor(pWidgetRef.bdrRank, UIResourceDef.COLOR.WHITE)
            pWidgetRef.txtBattlePass:SetText(UISetUtils.GetL10NTextByKey("SEASON_BATTLE_NORMAL"))
        end
        pWidgetRef.ktxtRankLevel:SetText(tbBasicInfo.nBattleTier)
        pWidgetRef.ktxtRankLevel2:SetText(tbBasicInfo.nBattleTier)
    end
end

local function RefreshMiscView(self, nPlayerId)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local FriendComponent = FriendSystem:GetComponent()
    if tbPlayer:GetPlayerId() == nPlayerId then
        self.pWidgetRef.bdrAddFriend:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.btnAddFriend:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.btnChangePhotoFrame:SetVisibility(ESlateVisibility.Collapsed)
    else
        if FriendComponent:GetFriend(nPlayerId) then
            self.pWidgetRef.bdrAddFriend:SetVisibility(ESlateVisibility.Collapsed)
            self.pWidgetRef.btnAddFriend:SetVisibility(ESlateVisibility.Collapsed)
        else
            self.pWidgetRef.bdrAddFriend:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            self.pWidgetRef.btnAddFriend:SetVisibility(ESlateVisibility.Visible)
        end
        self.pWidgetRef.btnChangePhotoFrame:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function RefreshBasicInfoView(self, nPlayerId)
    local tbBasicInfo = self.ulPlayerInfo:GetPlayerBasicInfo(nPlayerId)
    if tbBasicInfo then
        OnBasicInfoReceived(self, tbBasicInfo)
    end
end


local function RefreshSeasonBasicInfoView(self, nPlayerId)
    local tbBasicInfo = self.ulPlayerInfo:GetPlayerSeasonBasicInfo(nPlayerId)
    if tbBasicInfo then
        OnBasicSeasonInfoReceived(self, tbBasicInfo)
    end
end


local function OnRefreshSeasonRank(self, nMode)
    local Component = SeasonSystem:GetComponent()
    local tbCurRank = Component:GetCurRank()
    local tbModes = MatchmakingTeamModeDataTable:GetAllMode()
    for i, v in ipairs(tbModes) do
        if v.nId == nMode then
            self.pbModeRank[nMode]:OnRefresh(tbCurRank.rank[i])
            break
        end
    end
end

local function OnPlayerIdCopied(self)
    ExtendBlueprintFunctions.ClipboardCopy(tostring(self.ulPlayerInfo:GetTargetPlayerId()))
    UIUtils.ShowToast(UITextDef.COPY_SUCCEED)
end

local function AddFriend(self)
    local nPlayerId = self.ulPlayerInfo:GetTargetPlayerId()
    local szApplyMsg = L10N:ToString(UISetUtils.GetL10NTextByKey("FFA_APPLYFRIEND_MESSAGE"))
    self.ulPlayerInfo:RequestToAddFriend(nPlayerId, szApplyMsg)
end

local function ChangePhotoFrame(self)
    UIUtils.ShowToast(UITextDef.IN_DEVELOPMENT)
end

local function RefreshExpAndLevel(self)
    local pWidgetRef = self.pWidgetRef
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local LobbyPropertyComponent = PlayerSelf.LobbyPropertyComponent
    local nPlayerLevel = LobbyPropertyComponent:GetPlayerLevel()
    pWidgetRef.ktxtPlayLevel:SetText(nPlayerLevel)
    local nCurLevelMaxExp = PlayerLevelDataTable:GetTemplate(nPlayerLevel).nExp
    local nExp = LobbyPropertyComponent:GetPlayerExp()
    local szExp = string.format("%d/%d", nExp, nCurLevelMaxExp)
    pWidgetRef.txtExp:SetText(szExp)
    pWidgetRef.pgbExp:SetPercent(nExp/nCurLevelMaxExp)
end

local function IsPlayerSelf(self)
    local nPlayerId = self.ulPlayerInfo:GetTargetPlayerId()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if nPlayerId == PlayerSelf:GetPlayerId() then
        return true
    end
    return false
end

local function OnLevelUp(self)
    if IsPlayerSelf(self) then
        RefreshExpAndLevel(self)
    end
end

local function OnExpSynced(self)
    if IsPlayerSelf(self) then
        RefreshExpAndLevel(self)
    end
end

local function OnRefreshSeasonPass(self)
    if IsPlayerSelf(self) then
        local Component = SeasonSystem:GetComponent()
        local nTier = Component:GetBattlePass().battle_tier
        self.pWidgetRef.ktxtRankLevel:SetText(nTier)
        self.pWidgetRef.ktxtRankLevel2:SetText(nTier)
    end
end

local function OnRefreshCurSeasonPointRanking(self, nSeasonPointRanking, nSeasonParticipants)
    if IsPlayerSelf(self) then
        RefreshPointRanking(self, nSeasonPointRanking, nSeasonParticipants)
    end
end


function UPPlayerBasicInfo:Activate()
    local nPlayerId = self.ulPlayerInfo:GetTargetPlayerId()
    self.pbPlayHead:SetPlayerId(nPlayerId)
    RefreshBasicInfoView(self, nPlayerId)
    RefreshSeasonBasicInfoView(self, nPlayerId)
    RefreshMiscView(self, nPlayerId)
end

function UPPlayerBasicInfo:Deactivate()
    self.pbPlayHead:SetPlayerId(nil)
end


----------life cycle----------
-- function UPPlayerBasicInfo:OnCreate()
-- end

-- function UPPlayerBasicInfo:OnDestroy()
-- end

function UPPlayerBasicInfo:OnLoad()
    local ulPlayerInfo = self.Owner.ulPlayerInfo
    ulPlayerInfo:SetBasicInfoDataReceivedCallback(function(tbBasicInfo) OnBasicInfoReceived(self, tbBasicInfo) end)
    self.ulPlayerInfo = ulPlayerInfo
    self.pbPlayHead = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayHead)
    self.pbPlayHead:EnableClickHeadDefaultAction(false)
    local pbModeRank = {}
    for _, nMode in pairs(tbMode) do
        pbModeRank[nMode] = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbPlayerSystemSub_"..nMode])
    end
    self.pbModeRank = pbModeRank
    self.pbBestRank = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerSystemSubHigh)
end

function UPPlayerBasicInfo:OnUnload()
    self.nPlayerId = nil
    self.ulPlayerInfo = nil
end

-- function UPPlayerBasicInfo:OnEnter()
-- end

-- function UPPlayerBasicInfo:OnShow()
-- end

-- function UPPlayerBasicInfo:OnHide()
-- end

-- function UPPlayerBasicInfo:OnExit()
-- end

function UPPlayerBasicInfo:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnCopyPlayerId.OnClicked, self, OnPlayerIdCopied)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAddFriend.OnClicked, self, AddFriend)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnChangePhotoFrame.OnClicked, self, ChangePhotoFrame)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK, self, OnRefreshSeasonRank)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_PASS, self, OnRefreshSeasonPass)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_LEVEL_UP_NEW, self, OnLevelUp)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_EXP_SYNC_NEW, self, OnExpSynced)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEASON_POINT_RANKING, self, OnRefreshCurSeasonPointRanking)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SEASON_BASIC_INFO_RECEIVED, self, OnBasicSeasonInfoReceived)
end

-- function UPPlayerBasicInfo:OnUnbindEvent( EventHelper )
-- end

return UPPlayerBasicInfo