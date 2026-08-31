--File Name    : InteractionPortrait.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-08
--Description  : 有半身像UI
-----------------------------------------------------

local luaclass = require("luaclass")
local InteractionNoPortrait = require("InteractionNoPortrait")
local InteractionPortrait = luaclass("InteractionPortrait", InteractionNoPortrait)
local InteractionDef = require("InteractionDef")


InteractionPortrait.nInteractionType = InteractionDef.InteractionMode.UI_PORTRAIT
InteractionPortrait.pNPCRotation = nil
InteractionPortrait.bIsShowAvatar = true 

return InteractionPortrait