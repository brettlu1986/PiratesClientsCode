-----------------------------------------------------
--File Name    : UILoginState.lua
--Author       : Ran Jie
--Create Time  : 2017-03-07
--Description  : UILoginState
-----------------------------------------------------

local luaclass = require("luaclass")
local UINormalState = require("UINormalState")
local UILoginState = luaclass("UILoginState",UINormalState)

-- import require
--local UIDef = require("UIDef")

function UILoginState:Init(szUIStateName)
    UILoginState.super.Init(self, szUIStateName)
    self.tbOpenWnd = 
    {
        --UIDef.UI_LOGIN,
    }
end

return UILoginState
