-----------------------------------------------------
--File Name    : UPPartnerRelationItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-11
--Description  : 伙伴羁绊Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPPartnerRelationItem = luaclass("UPPartnerRelationItem", ListItemBase)

local L10N = require("L10N")
local UIDef = require("UIDef")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local MAX_PARTNER_COUNT = 3
local MAX_RELATION_COUNT = 6
UPPartnerRelationItem.tbPartnerItem = nil

local function GetPartnerComponent()
    return GamePlayerSelfHelper:Get().PartnerComponent
end

local function Reset(self)
    local pWidgetRef = self.pWidgetRef
    for i = 1, MAX_RELATION_COUNT do
        pWidgetRef["txtEffect_"..i]:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef["txtEffect_"..i]:SetColorAndOpacity(UIResourceDef.COLOR.GREY.LINEAR_COLOR)
    end
    for i = 1, MAX_PARTNER_COUNT do
        self.tbPartnerItem[i].pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPPartnerRelationItem:OnRefresh(tbData)
    if #tbData > 0 then
        Reset(self)
        -- 遍历羁绊中的Partner，获取最小Level
        local nMinLevel = 6
        local tbPartnerIds = tbData[1].tbPartnerIds
        for i, nPartnerId in ipairs(tbPartnerIds) do
            local bEquipped = GetPartnerComponent():IsEquippedPartner(nPartnerId)
            local tbPartnerInfo = GetPartnerComponent():GetPartnerInfo(nPartnerId)
            self.tbPartnerItem[i]:SetPartnerInfo(tbPartnerInfo, tbPartnerInfo.nLevel, not bEquipped)
            self.tbPartnerItem[i].pWidgetRef:SetVisibility(ESlateVisibility.HitTestInvisible)
            local nPartnerLevel = bEquipped and tbPartnerInfo.nLevel or -1
            nMinLevel = math.min(nMinLevel, nPartnerLevel)
        end
        local pWidgetRef = self.pWidgetRef
        for i, tbTemplate in ipairs(tbData) do
            pWidgetRef["txtEffect_"..i]:SetVisibility(ESlateVisibility.HitTestInvisible)
            if nMinLevel >= tbTemplate.nLevel then
                -- 设置激活颜色
                pWidgetRef["txtEffect_"..i]:SetColorAndOpacity(UIResourceDef.COLOR.GREEN.LINEAR_COLOR)
                pWidgetRef["txtEffect_"..i]:SetText(tbTemplate.l10nDesc)
            else
                pWidgetRef["txtEffect_"..i]:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("PARTNER_RELATION_FORMAT"), tbTemplate.l10nDesc, tbTemplate.nLevel))
            end
        end
    end
end

function UPPartnerRelationItem:OnLoad()
    self.tbPartnerItem = {}
    for i = 1, MAX_PARTNER_COUNT do
        self.tbPartnerItem[i] = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbPartnerItem_"..i], UIDef.UP_PARTNER_LEVEL_UP_ITEM)
    end
end

return UPPartnerRelationItem