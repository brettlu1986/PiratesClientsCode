-----------------------------------------------------
--File Name    : GuideActionModal.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFullUIControl      = require("GuideActionFullUIControl")
local GuideActionModal              = luaclass("GuideActionModal", GuideActionFullUIControl)

-----------------------------------------------------
function GuideActionModal:Begin()
   GuideActionModal.super.Begin(self)
   self:CallShowSpaceScreen(true)
end

function GuideActionModal:OnTimerFunc()
    self:CallShowSpaceScreen(false)
    self:EndAction()
end

return GuideActionModal