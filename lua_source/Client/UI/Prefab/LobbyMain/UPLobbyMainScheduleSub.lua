-----------------------------------------------------
--File Name    : UPLobbyMainScheduleSub.lua
--Author       : Ran Jie
--Create Time  : 2020-04-20
-----------------------------------------------------
local luaclass       = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyMainScheduleSub  = luaclass("UPLobbyMainScheduleSub", ListItemBase)

local UISetUtils = require("UISetUtils")
local UIManager = require("UIManager")
local UIDef = require("UIDef")

UPLobbyMainScheduleSub.tbData = nil

local function OnSelectClicked(self)
    if self.tbData.szWndName ~= nil then
        UIManager:OpenWnd(self.tbData.szWndName, {szFrom = "LobbyMain"})
    else
        UIManager:OpenWnd(UIDef.UI_SCHEDULE, {nId = self.tbData.nId})
    end
end

function UPLobbyMainScheduleSub:OnRefresh(tbData)
    self.tbData = tbData
    UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnSelect, tbData.szLobbyImgPath:load()) 
end

function UPLobbyMainScheduleSub:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSelect.OnClicked, self, OnSelectClicked)
end

return UPLobbyMainScheduleSub