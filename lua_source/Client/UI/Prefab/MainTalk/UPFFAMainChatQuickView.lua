-----------------------------------------------------
--File Name    : UPFFAMainChatQuickView.lua
--Author       : Edward J
--Create Time  : 2018-03-12
--Description  : UPFFAMainChatQuickView
-----------------------------------------------------
local luaclass               = require ("luaclass")
local UPFFABase              = require("UPFFABase")
local UPFFAMainChatQuickView = luaclass("UPFFAMainChatQuickView", UPFFABase)

local SelfVerticalListHelper = require("SelfVerticalListHelper") 
local BattleChatSystem       = dynamic_require("BattleChatSystem")
local CommonEventDef         = require("CommonEventDef")
local UIDef                  = require("UIDef")
-----------------------------------------------------
local AUTO_DEACTIVATE_INTERVAL = 10

UPFFAMainChatQuickView.ListHelper         = nil
UPFFAMainChatQuickView.tbTimerHandler     = nil
UPFFAMainChatQuickView.nCountDown         = 0
UPFFAMainChatQuickView.OnScrolledDelegate = nil
-----------------------------------------------------
local function ClearCountDownTimer(self)
    local tbTimer = self.tbTimerHandler
    if tbTimer == nil then
        return
    end
    self.TimerHelper:ClearTimer(tbTimer)
    self.tbTimerHandler = nil
end
local function AutoDeactivateCountDown(self)
    local nCountDown = self.nCountDown
    nCountDown = nCountDown + 1
    self.nCountDown = nCountDown
    if nCountDown >= AUTO_DEACTIVATE_INTERVAL then
        self.nCountDown = 0
        ClearCountDownTimer(self)
        self:Deactivate()
    end
end

function UPFFAMainChatQuickView:GetCurrentViewType()
    return UIDef.CHAT_TAB_TYPE.ETabQuickView
end

function UPFFAMainChatQuickView:Refresh()
    local tbTeamHistory = BattleChatSystem:GetTeamHistory()
    self.ListHelper:SetData(tbTeamHistory)
    self.ListHelper:ScrollToBottom(false)
    self:Activate()
    self:AutoDeactivate()
end

function UPFFAMainChatQuickView:AutoDeactivate()
    if self.tbTimerHandler ~= nil then
        self.nCountDown = 0
        return
    end
    ClearCountDownTimer(self)
    self.tbTimerHandler = self.TimerHelper:NewTimerMethod(self, AutoDeactivateCountDown, 1, true)
end

function UPFFAMainChatQuickView:Activate(tbParam)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end

function UPFFAMainChatQuickView:Deactivate()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    ClearCountDownTimer(self)
end

function UPFFAMainChatQuickView:OnListViewScrolled(nOffset)
    self.nCountDown = 0
end

function UPFFAMainChatQuickView:OnLoad()
    self.super.OnLoad(self)
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.listQuickView)
    self:Deactivate()
end

function UPFFAMainChatQuickView:OnUnload()
    self.super.OnUnload(self)
    self.ListHelper:Uninit()
end

function UPFFAMainChatQuickView:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_BATTLECHAT_TEAM_NEW_MSG, self, self.Refresh)
    self.OnScrolledDelegate = EventHelper:RegisterCppDelegate(self.pWidgetRef.listQuickView.OnListViewScrolled, self, self.OnListViewScrolled)
end

return UPFFAMainChatQuickView