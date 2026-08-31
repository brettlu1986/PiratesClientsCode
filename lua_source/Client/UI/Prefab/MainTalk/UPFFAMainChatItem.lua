-----------------------------------------------------
--File Name    : UPFFAMainChatItem.lua
--Author       : Edward J
--Create Time  : 2018-03-12
--Description  : UPFFAMainChatItem
-----------------------------------------------------
local luaclass          = require("luaclass")
local ListItemBase      = require("ListItemBase")
local UPFFAMainChatItem = luaclass("UPFFAMainChatItem", ListItemBase)

local ClientEventDef    = require("ClientEventDef")
local EventManager      = require("EventManager")
local UIDef             = require("UIDef")
local BattleChatSystem  = require("BattleChatSystem_C")
local StringUtil        = require("StringUtil")
-----------------------------------------------------
local SELF_FRIEND_CHAT_NAME     = "我"

UPFFAMainChatItem.szMsg         = nil
UPFFAMainChatItem.pOnClicked    = nil
UPFFAMainChatItem.nSoundId      = nil
UPFFAMainChatItem.nId           = nil
-----------------------------------------------------
local function OnClicked(self)
    local pMainChat = self.ListHelper.Owner
    local eCurrentType = pMainChat:GetCurrentViewType()
    local EChatType = UIDef.CHAT_TAB_TYPE
    if eCurrentType == EChatType.ETabQuickMsg then
        EventManager:OnFireEvent(ClientEventDef.EV_CLICK_QUICK_CHAT, self.szMsg, self.nSoundId, self.nId)
    elseif eCurrentType == EChatType.ETabHistory then
        EventManager:OnFireEvent(ClientEventDef.EV_SELECT_HISTORY, self.nIndex)
    end
end

function UPFFAMainChatItem:OnRefresh(szMsg)
    local pMainChat = self.ListHelper.Owner
    local eCurrentType = pMainChat:GetCurrentViewType()
    local szTemp = szMsg
    self.nId = szMsg.nId
    if eCurrentType == UIDef.CHAT_TAB_TYPE.ETabQuickMsg then
        self.nSoundId = szMsg.nSoundId
        szTemp = szMsg.szMsg
    end
    if eCurrentType == UIDef.CHAT_TAB_TYPE.ETabFriendsMsg then
        local szName = pMainChat:GetCurrentFirendName()
        local tbMsgData = StringUtil.Split(szMsg, BattleChatSystem.FRIEND_HISTORY_TAG)
        szName = (tonumber(tbMsgData[1]) == BattleChatSystem.EFriendHistory_Mine) and SELF_FRIEND_CHAT_NAME or szName
        szTemp = string.format("%s : %s",szName, tbMsgData[3])
    end
    self.szMsg = szTemp
    self.pWidgetRef.krtxtContent:SetText(szTemp)
end

function UPFFAMainChatItem:OnBindEvent(EventHelper)
    if self.pOnClicked ~= nil then
        EventHelper:UnregisterCppDelegate(self.pOnClicked)
        self.pOnClicked = nil
    end
    self.pOnClicked = EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClick.OnClicked, self, OnClicked)
end

function UPFFAMainChatItem:OnUnbindEvent(EventHelper)
    EventHelper:UnregisterAll()
end

return UPFFAMainChatItem