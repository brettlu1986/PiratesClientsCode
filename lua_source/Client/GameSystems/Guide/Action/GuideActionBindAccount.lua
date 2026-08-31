-----------------------------------------------------
--File Name    : GuideActionBindAccount.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = luaclass("GuideActionFunctional")
local GuideActionBindAccount    = require("GuideActionBindAccount", GuideActionFunctional)

local ChannelSDKSystem          = require("ChannelSDKSystem")
-----------------------------------------------------

-----------------------------------------------------

function GuideActionBindAccount:Begin()
    GuideActionBindAccount.super.Begin(self)
end

function GuideActionBindAccount:DoAction(tbTemplate)
    GuideActionBindAccount.super.DoAction(self, tbTemplate)
    ChannelSDKSystem:ShowBindTipsView()
end

return GuideActionBindAccount
