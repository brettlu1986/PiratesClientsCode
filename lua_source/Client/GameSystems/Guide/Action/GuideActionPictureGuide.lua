-----------------------------------------------------
--File Name    : GuideActionPictureGuide.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFullUIControl  = require("GuideActionFullUIControl")
local GuideActionPictureGuide   = luaclass("GuideActionPictureGuide",GuideActionFullUIControl)

local L10N              = require("L10N")

----------------------------------------------------------
function GuideActionPictureGuide:DoAction(tbTemplate)
    GuideActionPictureGuide.super.DoAction(self, tbTemplate)
    self:CallSetPicGuide(tbTemplate.szGuidePicPath, L10N:ToString(tbTemplate.l10nGuideText), tbTemplate.bClickAnywhere)
end

return GuideActionPictureGuide
