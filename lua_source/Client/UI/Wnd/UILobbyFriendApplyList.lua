local luaclass              = require("luaclass")
local WndBase               = require("WndBase")
local UILobbyFriendApplyList= luaclass("UILobbyFriendApplyList", WndBase)
local FriendSystem          = require("FriendSystem")
local ClientEventDef        = require("ClientEventDef")
local SelfVerticalListHelper= require("SelfVerticalListHelper")

UILobbyFriendApplyList.pbDialogFrame = nil
UILobbyFriendApplyList.tbListHelper  = nil

local function OnRefresh(self)
    local Visible, Collapsed = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    
    local tbDatas = FriendSystem:GetComponent():GetApplyFriends()
    pWidgetRef.vbBlank:SetVisibility((tbDatas == nil or #tbDatas == 0) and Visible or Collapsed)
    self.tbListHelper:SetData(tbDatas)
end

local function OnRefreshApplyFriendList(self)
    OnRefresh(self)
end

local function OnClickAllAgree()
    local tbDatas = FriendSystem:GetComponent():GetApplyFriends()
    if tbDatas == nil or #tbDatas == 0 then
        return
    end
    FriendSystem:RequestAddAllApplyFriend()
end

local function OnClickAllIgnore()
    local tbDatas = FriendSystem:GetComponent():GetApplyFriends()
    if tbDatas == nil or #tbDatas == 0 then
        return
    end
    FriendSystem:RequestDeleteAllApplyFriend()
end

local function OnClickClose(self)
    self:CloseSelf()
end

function UILobbyFriendApplyList:OnLoad()    
    local pWidgetRef = self.pWidgetRef

    self.pbDialogFrame = self.PrefabHelper:BindPrefab(pWidgetRef.pbDialogFrame)
    self.pbDialogFrame:SetPositiveButtonCallback(OnClickAllAgree)
    self.pbDialogFrame:SetNegativeButtonCallback(OnClickAllIgnore)
    self.pbDialogFrame:SetDialogClosedCallback(OnClickClose, self)

    self.tbListHelper:Init(self, pWidgetRef.klistItem)
end

function UILobbyFriendApplyList:OnCreate()
    self.tbListHelper = SelfVerticalListHelper()
end

function UILobbyFriendApplyList:OnShow()
    OnRefresh(self)
    self.pbDialogFrame:ShowDialog()
end

function UILobbyFriendApplyList:OnDestroy()
    self.pbDialogFrame = nil
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
end

function UILobbyFriendApplyList:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_APPLY_FRIENDS, self, OnRefreshApplyFriendList)
end

return UILobbyFriendApplyList
