-----------------------------------------------------
--File Name    : GuideActionFormatTextGuide.lua
--Author       : zhiyuan
--Create Time  : 2020-02-26
--Description  : 需要匹配文本的提示
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionFullUIControl          = require("GuideActionFullUIControl")
local GuideActionFormatTextGuide        = luaclass("GuideActionFormatTextGuide", GuideActionFullUIControl)

local L10N              = require("L10N")
local GuideSharedInfoKeyDef = require("GuideSharedInfoKeyDef")
----------------------------------------------------------

function GuideActionFormatTextGuide:OnClickAnywhere()
    if not self.tbTemplate.bDoubleClick then
        self:DebugLog(" GuideActionFormatTextGuide:OnClickAnywhere")
        self:EndAction()   
    end   
end

function GuideActionFormatTextGuide:DoAction(tbTemplate)
    GuideActionFormatTextGuide.super.DoAction(self, tbTemplate)
    local tbTemp = {X = 0, Y = 0}
    local tbFormatStrings = self:GetSharedInfo(GuideSharedInfoKeyDef.FORMAT_STRINGS)
    local l10nText = L10N:FormatFromTable(tbTemplate.l10nGuideText, tbFormatStrings)
    self:CallSetSelectInfo(tbTemp, tbTemp, tbTemplate.szSelectWidgetName, L10N:ToString(l10nText),
        tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self, nil, nil, tbTemplate.bMaskEffect)
end

return GuideActionFormatTextGuide
