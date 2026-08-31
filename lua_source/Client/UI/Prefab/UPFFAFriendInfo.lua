local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPFFAFriendInfo = luaclass("UPFFAFriendInfo", ListItemBase)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local RankDataTable = require("RankDataTable")
local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local HumanDataTable = require("HumanDataTable")
local UIResourceDef = require("UIResourceDef")
local AvatarDataTable = require("AvatarDataTable")
local GenderTypeDefine   = require("GenderTypeDefine")
local FriendSystem = require("FriendSystem")
local Proto = require("ClientProtoNames")
local SeasonHelper = require("SeasonHelper")

local INFO_TYPE = {
    NEAR = 1,
    APPLY = 2,
}
local DEFAULT_RANK = 11

UPFFAFriendInfo.tbData = nil
UPFFAFriendInfo.pbHead = nil

local function RefreshRank(self, nRank, tbRankTemp)
    local pWidgetRef = self.pWidgetRef
    if tbRankTemp == nil and nRank ~= nil then
        tbRankTemp = RankDataTable:GetTemplate(nRank)
    end
    
    if tbRankTemp == nil then
        tbRankTemp = RankDataTable:GetTemplate(DEFAULT_RANK)
    end
    local szRankImg, szSubRankImg = SeasonHelper.GetIcon(tbRankTemp.nRank)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRankIcon, szRankImg:load())
    if szSubRankImg ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgRankNumber, szSubRankImg:load())
        local szRankName = L10N:ToString(tbRankTemp.l10nName)..tbRankTemp.szRankLevelName
        pWidgetRef.txtRank:SetText(szRankName)
    else
        pWidgetRef.imgRankNumber:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.txtRank:SetText(tbRankTemp.l10nName)
    end
end

local function GetGenderRes(nAvatarId, nHumanId)
    if nHumanId == nil then
        local tbAvatarData = AvatarDataTable:GetTemplate(nAvatarId)
        if tbAvatarData == nil then 
            return UIResourceDef.GENDER_MALE
        end 
        nHumanId = tbAvatarData.nHumanId
    end

    local tbHumanData = HumanDataTable:GetTemplate(nHumanId)
    if tbHumanData == nil then
        return UIResourceDef.GENDER_MALE
    end
    return tbHumanData.nGender == GenderTypeDefine.MALE and UIResourceDef.GENDER_MALE or UIResourceDef.GENDER_FEMALE
end


local function RefreshNearInfo(self)
    local tbData = self.tbData
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtStatus:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.btnOk:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.btnCancel:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.btnAdd:SetVisibility(ESlateVisibility_Visible)

    local tbGameObject = GameObjectSystem:FindPlayerByPlayerId(tbData.nId)
    if tbGameObject == nil then
        logerror("UPFFAFriendInfo refresh near info ", tbData.nId)
        return
    end

    local nHumanId = tbGameObject.nDungeonHumanId
    -- 性别
    UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, GetGenderRes(nil, nHumanId):load(), true)
    -- 名字
    pWidgetRef.txtName:SetText(tbGameObject.szName)
  
    local tbPlayerInfo = tbData.tbPlayerInfo
    if tbPlayerInfo ~= nil then
        -- 头像，等级
        self.pbHead:SetPlayerHead(tbPlayerInfo.nAvatarId, tbPlayerInfo.nLevel)
        self.pbHead:SetPlayerId(tbData.nId)

        -- 段位
        local tbRankTemp = RankDataTable:GetTemplateByRankLevel(tbPlayerInfo.nSeasonRank)
        RefreshRank(self, nil, tbRankTemp)
    end
end

local function RefreshApplyInfo(self)
    local tbData = self.tbData
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtStatus:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    pWidgetRef.btnOk:SetVisibility(ESlateVisibility_Visible)
    pWidgetRef.btnCancel:SetVisibility(ESlateVisibility_Visible)
    pWidgetRef.btnAdd:SetVisibility(ESlateVisibility_Collapsed)

    local nAvatarId = tbData.player_summary.avatar_id
    local nLevel = tbData.player_summary.level
    -- 性别
    UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, GetGenderRes(nAvatarId, nil):load(), true)
    -- 名字
    pWidgetRef.txtName:SetText(tbData.player_summary.name)
    -- 头像，等级
    self.pbHead:SetPlayerHead(nAvatarId, nLevel)
    self.pbHead:SetPlayerId(tbData.player_id)

    -- 段位
    RefreshRank(self, tbData.player_summary.rank)
end

local function GetInfoType(self)
    if self.tbData.nId and self.tbData.nSquareDis then
        return INFO_TYPE.NEAR
    else 
        return INFO_TYPE.APPLY
    end
end

local function OnClickOk(self)
    FriendSystem:RequestAddFriend(self.tbData.player_id)
end

local function OnClickCancel(self)
    FriendSystem:RequestDeleteApplyFriend(self.tbData.player_id)
end

local function OnClickAdd(self)
    local nId = self.tbData.nId
    FriendSystem:RequestApplyFriend(nId, L10N:ToString(UISetUtils.GetL10NTextByKey("FFA_APPLYFRIEND_MESSAGE_BYTRAINING_CAMP")), 
        Proto.FriendSource.TRAINING_CAMP)
end

function UPFFAFriendInfo:OnRefresh(tbData)
    self.tbData = tbData
    if GetInfoType(self) == INFO_TYPE.NEAR then
        RefreshNearInfo(self)
    else
        RefreshApplyInfo(self)
    end
end

function UPFFAFriendInfo:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnOk.OnClicked, self, OnClickOk)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCancel.OnClicked, self, OnClickCancel)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdd.OnClicked, self, OnClickAdd)
end

function UPFFAFriendInfo:OnLoad()
    local PrefabHelper = self.PrefabHelper
    self.pbHead = PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerHead)
    self.pbHead:EnableClickHeadDefaultAction(false)
end

function UPFFAFriendInfo:OnDestroy()
    self.pbHead = nil
end

return UPFFAFriendInfo
