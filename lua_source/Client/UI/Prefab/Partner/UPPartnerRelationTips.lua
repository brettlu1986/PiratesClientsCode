-----------------------------------------------------
--File Name    : UPPartnerRelationTips.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-12
--Description  : 伙伴羁绊Tips
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPPartnerRelationTips = luaclass("UPPartnerRelationTips", ListItemBase)

local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local PartnerRelationDataTable = require("PartnerRelationDataTable")

local function AddTextBlock(self, l10nText)
    local pTextBlock = self.WidgetHelper:CreateWidget(TextBlock)
    self.pWidgetRef.vboxContainer:AddChild(pTextBlock)
    pTextBlock:SetText(l10nText)
    pTextBlock:SetColorAndOpacity(UIResourceDef.COLOR.GREEN1.SLATE_COLOR)
    UISetUtils.SetTextblockFont(pTextBlock, UIResourceDef.FFA_FONT_RES_PINGFANG:load())
    UISetUtils.SetTextblockFontSize(pTextBlock, 20)
end

function UPPartnerRelationTips:SetRelationIds(tbRelationIds)
    for i, nId in ipairs(tbRelationIds) do
        local tbTemplate = PartnerRelationDataTable:GetTemplate(nId)
        AddTextBlock(self, tbTemplate.l10nDesc)
    end
end

return UPPartnerRelationTips