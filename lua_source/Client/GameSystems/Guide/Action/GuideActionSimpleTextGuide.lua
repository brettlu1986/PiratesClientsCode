-----------------------------------------------------
--File Name    : GuideActionSimpleTextGuide.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFunctional         = require("GuideActionFunctional")
local GuideActionSimpleTextGuide    = luaclass("GuideActionSimpleTextGuide",GuideActionFunctional)

local L10N              = require("L10N")
----------------------------------------------------------
GuideActionSimpleTextGuide.szRelatedWidgetName = nil
----------------------------------------------------------

function GuideActionSimpleTextGuide:DoAction(tbTemplate)
    GuideActionSimpleTextGuide.super.DoAction(self, tbTemplate)
    local tbTemp = {X = 0, Y = 0}
    self:CallSetSimpleSelectInfo(tbTemp, tbTemp, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
        tbTemplate.szGuidePicPath, tbTemplate.nGuidePos, self, nil)
end

return GuideActionSimpleTextGuide
