-----------------------------------------------------
--File Name    : GuideActionSetDragMode.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionSetDragMode    = luaclass("GuideActionSetDragMode", GuideActionFunctional)

--import
local L10N          = require("L10N")

--local 

function GuideActionSetDragMode:DoAction(tbTemplate)
    GuideActionSetDragMode.super.DoAction(self, tbTemplate)
    self:CallSetDragOnly(L10N:ToString(tbTemplate.l10nGuideText), tbTemplate.szGuidePicPath, tbTemplate.nGuidePos)
end

return GuideActionSetDragMode
