-----------------------------------------------------
--File Name    : GuideActionCentralGuide.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFullUIControl  = require("GuideActionFullUIControl")
local GuideActionCentralGuide   = luaclass("GuideActionCentralGuide",GuideActionFullUIControl)

local L10N              = require("L10N")

----------------------------------------------------------

function GuideActionCentralGuide:DoAction(tbTemplate)
    GuideActionCentralGuide.super.DoAction(self, tbTemplate)
    self:CallSetCentralGuide(L10N:ToString(tbTemplate.l10nGuideText), self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, self)
end

return GuideActionCentralGuide
