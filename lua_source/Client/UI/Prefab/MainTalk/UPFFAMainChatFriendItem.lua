-----------------------------------------------------
--File Name    : UPFFAMainChatFriendItem.lua
--Author       : Edward J
--Create Time  : 2018-03-12
--Description  : UPFFAMainChatItem
-----------------------------------------------------
local luaclass          = require("luaclass")
local ListItemBase      = require("ListItemBase")
local UPFFAMainChatFriendItem = luaclass("UPFFAMainChatFriendItem", ListItemBase)

local EventManager     = require("EventManager")
local BattleChatSystem = dynamic_require ("BattleChatSystem")
local ChatSystemHelper = require("ChatSystemHelper")
local UISetUtils       = require("UISetUtils")
local ClientEventDef   = require("ClientEventDef")
local FriendSystem     = require("FriendSystem")
-----------------------------------------------------
local Visible           = ESlateVisibility.Visible
local Collapsed         = ESlateVisibility.Collapsed

UPFFAMainChatFriendItem.nFriendId = nil
-----------------------------------------------------
local function RefreshItemAppearance(self, nFriendId, nTag)
    local pWidgetRef = self.pWidgetRef
    local szExtra = ""
    if nTag == ChatSystemHelper.MSG then
        pWidgetRef.ovlInvite:SetVisibility(Collapsed)
        pWidgetRef.btnClick:SetVisibility(Visible)
        szExtra = BattleChatSystem:GetFriendHistoryPreview(nFriendId)
    elseif nTag == ChatSystemHelper.INVITE then
        pWidgetRef.ovlInvite:SetVisibility(Visible)
        pWidgetRef.btnClick:SetVisibility(Collapsed)
        szExtra = UISetUtils.GetL10NTextByKey("UI_STATIC_APPOINTMENT_INVITE")
    end
    pWidgetRef.krtxtPreview:SetText(szExtra)
end

function UPFFAMainChatFriendItem:OnRefresh(tbData)
    self.szMsg = tbData
    local nTag = tbData.nTag
    local pWidgetRef = self.pWidgetRef
    local nNewCount = tbData.nNewCount
    local nFriendId = tbData.nFriendId
    local szName = tbData.szName
    self.nFriendId = nFriendId
    RefreshItemAppearance(self, nFriendId, nTag) 
    if nNewCount > 0 then
        pWidgetRef.txtCount:SetText(tostring(nNewCount))
        pWidgetRef.imgCountBG:SetVisibility(Visible)
    else 
        pWidgetRef.txtCount:SetText("")
        pWidgetRef.imgCountBG:SetVisibility(Collapsed)
    end
    pWidgetRef.krtxtName:SetText(szName)
end

local function OnClicked(self)
    EventManager:OnFireEvent(ClientEventDef.EV_SELECT_FRIEND_CHAT, self.nFriendId)
    BattleChatSystem:ReadFriendHistory(self.nFriendId)
end

local function OnIgnoreClicked(self)
    BattleChatSystem:RemoveInviteFromHistory(self.nFriendId)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLECHAT_FRIEND_NEW_MSG)
end

local function OnAgreeClicked(self)
    BattleChatSystem:RemoveInviteFromHistory(self.nFriendId)
    FriendSystem:RequestAcceptFriendReservation(self.nFriendId)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLECHAT_FRIEND_NEW_MSG)
end

local function OnAcceptReservationSuccess(self, nPlayerId)
end

function UPFFAMainChatFriendItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClick.OnClicked, self, OnClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnInviteIgnore.OnClicked, self, OnIgnoreClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnInviteAgree.OnClicked, self, OnAgreeClicked)

    EventHelper:RegisterEvent(ClientEventDef.EV_ACCEPT_RESERVATION_SUCCESS, self, OnAcceptReservationSuccess)
end

function UPFFAMainChatFriendItem:OnUnbindEvent(EventHelper)
    EventHelper:UnregisterAll()
end

return UPFFAMainChatFriendItem