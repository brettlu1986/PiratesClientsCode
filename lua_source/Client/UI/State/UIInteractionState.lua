-----------------------------------------------------
--File Name    : UIInteractionState.lua
--Author       : Ran Jie
--Create Time  : 2017-03-07
--Description  : UIInteractionState
-----------------------------------------------------

local luaclass = require("luaclass")
local UICinematicState = require("UICinematicState")
local UIInteractionState = luaclass("UIInteractionState",UICinematicState)

local UIDef = require("UIDef")


function UIInteractionState:Init(szUIStateName)
    UIInteractionState.super.Init(self, szUIStateName)
    self:AddActiveWnd(UIDef.UI_FFA_MAIN)
end


return UIInteractionState
