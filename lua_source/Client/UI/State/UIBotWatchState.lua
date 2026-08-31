-----------------------------------------------------
--File Name    : UIBotWatchState.lua
--Author       : zheng
--Create Time  : 2019-04-25
--Description  : UIBotWatchState
-----------------------------------------------------

local luaclass = require("luaclass")
local UICinematicState = require("UICinematicState")
local UIBotWatchState = luaclass("UIBotWatchState",UICinematicState)

-- import require
local UIDef = require("UIDef")

function UIBotWatchState:Init(szUIStateName)
    UIBotWatchState.super.Init(self, szUIStateName)
    self.tbOpenWnd = 
    {
        UIDef.UI_BOT_WATCH,
    }
    self:AddActiveWnd(UIDef.UI_CROSSHAIRS_DEBUG)
    self:AddActiveWnd(UIDef.UI_FFA_MAIN)
end

function UIBotWatchState:Enter(tbParam)
    local tbWndParams = {}
    tbWndParams[UIDef.UI_BOT_WATCH] = tbParam
    UIBotWatchState.super.Enter(self, tbWndParams)
end

function UIBotWatchState:VerifyWndVisibility(Wnd)
    return true
end 

return UIBotWatchState
