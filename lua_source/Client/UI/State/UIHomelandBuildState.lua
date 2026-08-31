-----------------------------------------------------
--File Name    : UIHomelandBuildState.lua
--Author       : zheng
--Create Time  : 2019-04-25
--Description  : UIHomelandBuildState
-----------------------------------------------------

local luaclass = require("luaclass")
local UICinematicState = require("UICinematicState")
local UIHomelandBuildState = luaclass("UIHomelandBuildState",UICinematicState)

-- import require
local UIDef = require("UIDef")

function UIHomelandBuildState:Init(szUIStateName)
    UIHomelandBuildState.super.Init(self, szUIStateName)
    self.tbOpenWnd = 
    {
        UIDef.UI_HOME_BUILD,
    }
    self:AddActiveWnd(UIDef.UI_HOME_MAIN)
end

function UIHomelandBuildState:Enter(tbParam)
    local tbWndParams = {}
    tbWndParams[UIDef.UI_HOME_BUILD] = tbParam
    UIHomelandBuildState.super.Enter(self, tbWndParams)
end

function UIHomelandBuildState:VerifyWndVisibility(Wnd)
    return true
end 

return UIHomelandBuildState
