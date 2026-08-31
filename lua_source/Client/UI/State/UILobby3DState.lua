-----------------------------------------------------
--File Name    : UILobby3DState.lua
--Author       : Ran Jie
--Create Time  : 2020-04-21
--Description  : UILobby3DState
-----------------------------------------------------

local luaclass = require("luaclass")
local UINormalState = require("UINormalState")
local UILobby3DState = luaclass("UILobby3DState",UINormalState)

-- import require
local UIDef = require("UIDef")

function UILobby3DState:Init(szUIStateName)
    UILobby3DState.super.Init(self, szUIStateName)
    self.tbOpenWnd = 
    {
        UIDef.UI_LOBBY_BOTTOM_MENU,
    }
    self:AddActiveWnd(UIDef.UI_LOBBY_TEAM_INVITE)
    self:AddActiveWnd(UIDef.UI_TOPMSGNOTIFACTION)
    self:AddActiveWnd(UIDef.UI_LOBBY_TEAM_ORDER)
end

function UILobby3DState:Enter(tbParam)
    UILobby3DState.super.Enter(self, tbParam)
end

return UILobby3DState
