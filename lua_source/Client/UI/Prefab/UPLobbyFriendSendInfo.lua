local luaclass           = require("luaclass")
local ListItemBase       = require("ListItemBase")
local UPLobbyFriendSendInfo = luaclass("UPLobbyFriendSendInfo", ListItemBase)
local UISetUtils         = require("UISetUtils")
local UIResourceDef      = require("UIResourceDef")
local GenderTypeDefine   = require("GenderTypeDefine")
local AvatarDataTable    = require("AvatarDataTable")
local HumanDataTable     = require("HumanDataTable")
local UIManager          = require("UIManager")
local UIDef              = require("UIDef")

UPLobbyFriendSendInfo.tbData = nil
UPLobbyFriendSendInfo.pbHead = nil

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
    if tbData == nil then return end
    -- 头像，等级
    self.pbHead:SetPlayerHead(tbData.avatar_id, tbData.level)
    -- 性别
    local szGender = GetGenderRes(tbData.avatar_id)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGender:load(), true)
    -- 名字
    pWidgetRef.txtName:SetText(tbData.name)
end

local function OnClickSend(self)
    local tbItem = self.Owner.tbItem
    local nFriendId = self.tbData.id
    local szName = self.tbData.name
    -- logdebug("send click :",nFriendId, nName )
    self.Owner:CloseSelf()
    UIManager:OpenWnd(UIDef.UI_USE_ROSE, { tbItem = tbItem, nFriendId = nFriendId, szName = szName })
end

function UPLobbyFriendSendInfo:OnCreate()
    
end

function UPLobbyFriendSendInfo:OnDestroy()
    self.pbHead = nil
end

function UPLobbyFriendSendInfo:OnLoad()
    local PrefabHelper = self.PrefabHelper
    self.pbHead = PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerHead)
end

function UPLobbyFriendSendInfo:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPositive.OnClicked, self, OnClickSend)
end

function UPLobbyFriendSendInfo:OnRefresh(tbData)
    self.tbData = tbData.player_summary
    RefreshInfo(self)
end

return UPLobbyFriendSendInfo
