local luaclass           = require("luaclass")
local ListItemBase       = require("ListItemBase")
local UPLobbyFriendBlackInfo = luaclass("UPLobbyFriendBlackInfo", ListItemBase)
local UISetUtils         = require("UISetUtils")
local UIResourceDef      = require("UIResourceDef")
local GenderTypeDefine   = require("GenderTypeDefine")
local AvatarDataTable    = require("AvatarDataTable")
local HumanDataTable     = require("HumanDataTable")

UPLobbyFriendBlackInfo.tbData = nil
UPLobbyFriendBlackInfo.pbHead = nil

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

local function RefreshInfo(self)
    local pWidgetRef = self.pWidgetRef
    local tbData = self.tbData
    local tbPlayerInfo = tbData.player_summary
    if tbPlayerInfo == nil then
        return
    end
    -- 头像，等级
    self.pbHead:SetPlayerHead(tbPlayerInfo.avatar_id, tbPlayerInfo.level)
    -- 性别
    local szGender = GetGenderRes(tbPlayerInfo.avatar_id)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGender:load(), true)
    -- 名字
    pWidgetRef.txtName:SetText(tbPlayerInfo.name)
end

local function OnClickDelete(self)
-- to do 解除黑名单
end

function UPLobbyFriendBlackInfo:OnCreate()
    
end

function UPLobbyFriendBlackInfo:OnDestroy()
    self.pbHead = nil
end

function UPLobbyFriendBlackInfo:OnLoad()
    local PrefabHelper = self.PrefabHelper
    self.pbHead = PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerHead)
end

function UPLobbyFriendBlackInfo:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPositive.OnClicked, self, OnClickDelete)
end

function UPLobbyFriendBlackInfo:OnRefresh(tbData)
    self.tbData = tbData
    RefreshInfo(self)
end

return UPLobbyFriendBlackInfo
