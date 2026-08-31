local luaclass           = require("luaclass")
local ListItemBase       = require("ListItemBase")
local UPLobbyFriendApplyInfo = luaclass("UPLobbyFriendApplyInfo", ListItemBase)
local UISetUtils         = require("UISetUtils")
local UIResourceDef      = require("UIResourceDef")
local GenderTypeDefine   = require("GenderTypeDefine")
local FriendSystem       = require("FriendSystem")
local L10N               = require("L10N")
local UITextDef          = require("UITextDef")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local AvatarDataTable    = require("AvatarDataTable")
local HumanDataTable     = require("HumanDataTable")
local SeasonHelper       = require("SeasonHelper")
local RankDataTable      = require("RankDataTable")

local ONE_MINITE = 60
local ONE_HOUR = ONE_MINITE*60
local ONE_DAY = ONE_HOUR*24

local TIME_TABLE = {
    {nTime = ONE_DAY,   l10nTime = UITextDef.SELFTIMECALCULATEHELPER_L10N_DAY},
    {nTime = ONE_HOUR,  l10nTime = UITextDef.SELFTIMECALCULATEHELPER_L10N_HOUR},
    {nTime = ONE_MINITE,l10nTime = UITextDef.SELFTIMECALCULATEHELPER_L10N_MIN}
}

UPLobbyFriendApplyInfo.tbData = nil
UPLobbyFriendApplyInfo.pbHead = nil

local function GetTimeStr(nTime)
    local nOverTime = math.max(GlobalVariableSystem_C:GetServerTimeUtc() - nTime, ONE_MINITE)
    for _, v in ipairs(TIME_TABLE) do
        if nOverTime >= v.nTime then
            local nT = math.floor(nOverTime / v.nTime)
            local l10nT = L10N:Format(v.l10nTime, nT)
            return L10N:Format(UITextDef.FFA_OVERTIMER, l10nT)
        end
    end
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

local function RefreshRank(self, nRank)
    local pWidgetRef = self.pWidgetRef
    local tbRankTemp = RankDataTable:GetTemplate(nRank)

    local szRankImg, szSubRankImg = SeasonHelper.GetIcon(tbRankTemp.nRank)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRankIcon, szRankImg:load())
    if szSubRankImg ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgRankNumber, szSubRankImg:load())
        local szRankName = L10N:ToString(tbRankTemp.l10nName)..tbRankTemp.szRankLevelName
        pWidgetRef.ktxtRank:SetText(szRankName)
    else
        pWidgetRef.imgRankNumber:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.ktxtRank:SetText(tbRankTemp.l10nName)
    end
end

local function RefreshInfo(self)
    local pWidgetRef = self.pWidgetRef
    local tbData = self.tbData
    local tbPlayerInfo = tbData.player_summary
    if tbPlayerInfo == nil then
        log("UPLobbyFriendApplyInfo RefreshInfo Failed: player summary is nil ")
        return
    end
    -- 头像，等级
    self.pbHead:SetPlayerHead(tbPlayerInfo.avatar_id, tbPlayerInfo.level)
    -- 性别
    local szGender = GetGenderRes(tbPlayerInfo.avatar_id)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGender:load(), true)
    -- 名字
    pWidgetRef.txtName:SetText(tbPlayerInfo.name)
    -- 申请信息
    pWidgetRef.txtMsg:SetText(tbData.apply_msg)
    -- 申请时间 
    local l10nTime = GetTimeStr(tbData.apply_time)
    pWidgetRef.txtTime:SetText(l10nTime)

    RefreshRank(self, tbPlayerInfo.rank)
end

local function OnClickIgnore(self)
    FriendSystem:RequestDeleteApplyFriend(self.tbData.player_id)
end

local function OnClickAgree(self)
    FriendSystem:RequestAddFriend(self.tbData.player_id)
end

function UPLobbyFriendApplyInfo:OnCreate()
    
end

function UPLobbyFriendApplyInfo:OnDestroy()
    self.pbHead = nil
end

function UPLobbyFriendApplyInfo:OnLoad()
    local PrefabHelper = self.PrefabHelper
    self.pbHead = PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayHead)
end

function UPLobbyFriendApplyInfo:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnNegative.OnClicked, self, OnClickIgnore)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPositive.OnClicked, self, OnClickAgree)
end

function UPLobbyFriendApplyInfo:OnRefresh(tbData)
    self.tbData = tbData
    RefreshInfo(self)
end

return UPLobbyFriendApplyInfo
