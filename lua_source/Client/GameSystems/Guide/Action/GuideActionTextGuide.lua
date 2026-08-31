-----------------------------------------------------
--File Name    : GuideActionTextGuide.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFullUIControl      = require("GuideActionFullUIControl")
local GuideActionTextGuide          = luaclass("GuideActionTextGuide",GuideActionFullUIControl)

local L10N              = require("L10N")
----------------------------------------------------------
GuideActionTextGuide.szRelatedWidgetName = nil
----------------------------------------------------------

function GuideActionTextGuide:DoAction(tbTemplate)
    GuideActionTextGuide.super.DoAction(self, tbTemplate)
    local tbTemp = {X = 0, Y = 0}
    self:CallSetSelectInfo(tbTemp, tbTemp, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
        tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self, nil, nil, tbTemplate.bMaskEffect)
end

return GuideActionTextGuide
