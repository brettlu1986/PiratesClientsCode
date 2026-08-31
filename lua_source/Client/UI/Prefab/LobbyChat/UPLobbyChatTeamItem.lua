-----------------------------------------------------
--File Name    : UPLobbyChatTeamItem.lua
--Author       : Edward J
--Create Time  : 2019-04-04
--Description  : lobby Chat Team Quick Msg List Item
-----------------------------------------------------
local luaclass              = require("luaclass")
local ListItemBase          = require("ListItemBase")
local UPLobbyChatTeamItem  = luaclass("UPLobbyChatTeamItem", ListItemBase)

local EventManager          = require("EventManager")
local ClientEventDef        = require("ClientEventDef")
local UIResourceDef         = require("UIResourceDef")
-----------------------------------------------------
local Visible   = ESlateVisibility.HitTestInvisible
local Collapsed = ESlateVisibility.Collapsed

UPLobbyChatTeamItem.szMsg = nil
-----------------------------------------------------

local function OnClicked(self)
    EventManager:OnFireEvent(ClientEventDef.EV_CLICK_TEAM_CHAT, self.szMsg)
end

local function OnPressed(self)

end

local function OnReleased(self)
    self.pWidgetRef.txtContent:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    self.pWidgetRef.imgSelected:SetVisibility(Collapsed)
end

local function OnLongPressed(self)
    self.pWidgetRef.txtContent:SetColorAndOpacity(UIResourceDef.COLOR.BLACK.SLATE_COLOR)
    self.pWidgetRef.imgSelected:SetVisibility(Visible)
end

function UPLobbyChatTeamItem:OnLoad()
    self.pWidgetRef.imgSelected:SetVisibility(Collapsed)
end

function UPLobbyChatTeamItem:OnRefresh(szMsg)
    self.szMsg = szMsg
    self.pWidgetRef.txtContent:SetText(szMsg)
end

function UPLobbyChatTeamItem:OnBindEvent(EventHelper)
    if self.pOnClicked ~= nil then
        EventHelper:UnregisterCppDelegate(self.pOnClicked)
        self.pOnClicked = nil
    end
    self.pOnClicked = EventHelper:RegisterCppDelegate(self.pWidgetRef.kmBtnClick.OnClicked, self, OnClicked)
    self.pOnClicked = EventHelper:RegisterCppDelegate(self.pWidgetRef.kmBtnClick.OnPressed, self, OnPressed)
    self.pOnClicked = EventHelper:RegisterCppDelegate(self.pWidgetRef.kmBtnClick.OnReleased, self, OnReleased)
    self.pOnClicked = EventHelper:RegisterCppDelegate(self.pWidgetRef.kmBtnClick.OnLongPressed, self, OnLongPressed)
end

return UPLobbyChatTeamItem