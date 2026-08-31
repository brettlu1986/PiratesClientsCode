-----------------------------------------------------
--File Name    : UIHomelandState.lua
--Author       : ranjie
--Create Time  : 2019-04-12
--Description  : UIHomelandState
-----------------------------------------------------

local luaclass = require("luaclass")
local UINormalState = require("UINormalState")
local UIHomelandState = luaclass("UIHomelandState",UINormalState)

-- import require
local UIDef = require("UIDef")

function UIHomelandState:Init(szUIStateName)
    UIHomelandState.super.Init(self, szUIStateName)
    self.tbOpenWnd = 
    {
        UIDef.UI_HOME_MAIN,
    }
end

function UIHomelandState:Enter(tbParam)
    UIHomelandState.super.Enter(self, tbParam)
end

return UIHomelandState
