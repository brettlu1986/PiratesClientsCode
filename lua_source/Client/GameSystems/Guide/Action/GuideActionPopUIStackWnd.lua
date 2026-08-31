-----------------------------------------------------
--File Name    : GuideActionPopUIStackWnd.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionPopUIStackWnd  = luaclass("GuideActionPopUIStackWnd",GuideActionFunctional)

--import
local UIWndStackHelper      = require("UIWndStackHelper")

function GuideActionPopUIStackWnd:DoAction(tbTemplate)
    GuideActionPopUIStackWnd.super.DoAction(self, tbTemplate)
    local szUIName = tbTemplate.szUIName
    if not szUIName or szUIName == "" then
        return
    end
    UIWndStackHelper:Pop(szUIName)
end

return GuideActionPopUIStackWnd
