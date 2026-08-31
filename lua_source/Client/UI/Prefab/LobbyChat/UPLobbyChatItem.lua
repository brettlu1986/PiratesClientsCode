-----------------------------------------------------
--File Name    : UPLobbyChatItemBase.lua
--Author       : Edward J
--Create Time  : 2018-04-16
--Description  : UPLobbyChatItemBase
-----------------------------------------------------
local luaclass             = require("luaclass")
local ListItemBase         = require("ListItemBase")
local UPLobbyChatItem      = luaclass("UPLobbyChatItem", ListItemBase)

local LobbyChatSystem               = require("LobbyChatSystem")
-----------------------------------------------------
local CHAT_SYSTEM       = LobbyChatSystem.CHAT_SYSTEM 

UPLobbyChatItem.tbHBox                  = nil
UPLobbyChatItem.pbMsgItemLeft           = nil
UPLobbyChatItem.pbMsgItemRight          = nil
-----------------------------------------------------

local function CheckIsSystemItem(self, eChannel)
    local pWidgetRef = self.pWidgetRef
    local bResult = eChannel == CHAT_SYSTEM
    pWidgetRef.switcher:SetActiveWidget(pWidgetRef.hboxSystemChat)
    return bResult
end

local function SwitchMsgItem(self, bSelf)
    local pWidgetRef = self.pWidgetRef
    local pbShowWidget = bSelf and self.pbMsgItemRight or self.pbMsgItemLeft
    pWidgetRef.switcher:SetActiveWidget(pbShowWidget.pWidgetRef)
    return pbShowWidget
end

local function SetSystemMsg(self, tbData)
    local szContent = tbData.szContent
    local szMsg = LobbyChatSystem:GetSystemContentText(szContent)    
    self.pWidgetRef.txtSystemMsg:SetText(szMsg)
end

function UPLobbyChatItem:OnRefresh(tbData)
    if not tbData then
        return
    end
    local bSelf = tbData.bSelf
    local eChannel = tbData.eChannel  
    local bIsSystem = CheckIsSystemItem(self, eChannel)
    if not bIsSystem then
        local pItemScript = SwitchMsgItem(self, bSelf)
        pItemScript:SetData(tbData)
    else
        SetSystemMsg(self, tbData)
    end
end

function UPLobbyChatItem:OnLoad()
    self.tbHBox = {}
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    self.pbMsgItemLeft = PrefabHelper:BindPrefab(pWidgetRef.upChatSubLeft)   
    self.pbMsgItemRight = PrefabHelper:BindPrefab(pWidgetRef.upChatSubRight)   
end

return UPLobbyChatItem