-----------------------------------------------------
--File Name    : UITempHideState.lua
--Author       : Ran Jie
--Create Time  : 2018-02-27
--Description  : UITempHideState
-----------------------------------------------------

local luaclass = require("luaclass")
local UICinematicState = require("UICinematicState")
local UITempHideState = luaclass("UITempHideState", UICinematicState)

function UITempHideState:Init(szUIStateName)
    UITempHideState.super.Init(self, szUIStateName) 
    self.bOnlyHideWnd = true
    self.bForbitIgnoreCinematicMode = true
end


return UITempHideState
