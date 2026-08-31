-----------------------------------------------------
--File Name    : LobbyCaptainDecoration.lua
--Author       : WuJizhou
--Create Time  : 5/9/2020, 10:54:54 AM
--Description  : LobbyCaptainDecoration
-----------------------------------------------------
local LobbyCaptainDecoration = {}

local SelfEventHelper = require("SelfEventHelper")
local UIManager = require("UIManager")
local UIDef = require("UIDef")

LobbyCaptainDecoration.tbOwnerSystem = nil

local tbAllUI = {
    UIDef.UI_LOBBY_CAPTAIN_DECORATION,
}

local function ShowUI(self)
    UIManager:OpenWnd(UIDef.UI_LOBBY_CAPTAIN_DECORATION)
end

local function CloseUI(self)
    for _, szUI in ipairs(tbAllUI) do
        UIManager:CloseWnd(szUI)
    end
end

local function ShowScene(self)
    self.tbOwnerSystem:SetShouldBeVisible(UIDef.UI_LOBBY_CAPTAIN_DECORATION, true)
    self.tbOwnerSystem:SetCamera(UIDef.UI_LOBBY_CAPTAIN_DECORATION, 1)
end

local function CloseScene(self)
    self.tbOwnerSystem:SetShouldBeVisible(UIDef.UI_LOBBY_CAPTAIN_DECORATION, false)
end

function LobbyCaptainDecoration:Init()
    self.EventHelper = SelfEventHelper()
end

function LobbyCaptainDecoration:Uninit()
    self.EventHelper = nil
end

function LobbyCaptainDecoration:Activate(tbOwnerSystem, tbParam)
    self.tbOwnerSystem = tbOwnerSystem
    ShowScene(self)
    ShowUI(self)
end

function LobbyCaptainDecoration:Deactivate()
    CloseScene(self)
    CloseUI(self)
end

function LobbyCaptainDecoration:MakeContext(tbOutContext)
end

function LobbyCaptainDecoration:ParseContext(tbContext, tbOutParam)
end


return LobbyCaptainDecoration