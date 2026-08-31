-----------------------------------------------------
--File Name    : UPLobbyChatBubble.lua
--Author       : Edward J
--Create Time  : 2018-08-12
--Description  : UPLobbyChatBubble
-----------------------------------------------------
local luaclass              = require("luaclass")
local UPFFABase             = require("UPFFABase")
local UPLobbyChatBubble     = luaclass("UPLobbyChatBubble", UPFFABase)
-----------------------------------------------------
local Visible               = ESlateVisibility.Visible
local Collapsed             = ESlateVisibility.Collapsed
local TIME_INTERVAL         = 5

UPLobbyChatBubble.bInUse = nil
-----------------------------------------------------
function UPLobbyChatBubble:Activate()
    self.bInUse = true
    self.pWidgetRef:SetVisibility(Visible)
end

function UPLobbyChatBubble:Deactivate()
    self.bInUse = false
    self.pWidgetRef:SetVisibility(Collapsed)
end

function UPLobbyChatBubble:OnLoad()
    self.bInUse = false
end

function UPLobbyChatBubble:OnUnload()
    self.TimerHelper:ClearAllTimer()
end

function UPLobbyChatBubble:IsInUse()
    return self.bInUse
end

function UPLobbyChatBubble:SetText(szText)
    szText = szText == nil and "" or szText
    self.pWidgetRef.ktxtMsg:SetText(szText)
    self.TimerHelper:ClearAllTimer()
    self:Activate()
    self.TimerHelper:NewTimerMethod(self, self.Deactivate, TIME_INTERVAL, false)
end

return UPLobbyChatBubble