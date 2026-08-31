-----------------------------------------------------
--File Name    : UIEmptyState.lua
--Author       : zheng
--Create Time  : 2019-06-20
--Description  : UILoginState
-----------------------------------------------------

local luaclass = require("luaclass")
local UINormalState = require("UINormalState")
local UIEmptyState = luaclass("UIEmptyState",UINormalState)

function UIEmptyState:Init(szUIStateName)
    UIEmptyState.super.Init(self, szUIStateName)
end

return UIEmptyState
