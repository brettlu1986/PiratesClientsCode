-----------------------------------------------------
--File Name    : LobbyBackpack.lua
--Author       : RanJie
--Create Time  : 2020-05-21
--Description  : LobbyBackpack
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbySubBase = require("LobbySubBase")
local LobbyBackpack = luaclass("LobbyBackpack", LobbySubBase)

local UIManager = require("UIManager")
local UIDef = require("UIDef")




function LobbyBackpack:Activate(tbParam)
    LobbyBackpack.super.Activate(self)
    UIManager:OpenWnd(UIDef.UI_LOBBY_BACKPACK)
end

function LobbyBackpack:Deactivate()
    LobbyBackpack.super.Deactivate(self)
    UIManager:CloseWnd(UIDef.UI_LOBBY_BACKPACK)
end






return LobbyBackpack