local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULLobbyItemHint = luaclass("ULLobbyItemHint", UILogicBase)

local ShopSystem            = require("ShopSystem")
local ItemDataTable         = require("ItemDataTable")
local ItemSourceDataTable   = require("ItemSourceDataTable")
local ClientEventDef        = require("ClientEventDef")


ULLobbyItemHint.nItemTemplateId = nil

local function OnBtnBuyClicked(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_CAPTAIN_BUY_ITEM, self.nItemTemplateId)
    ShopSystem:OnBuyButtonClickByTemplateId(self.nItemTemplateId)
end


function ULLobbyItemHint:Display(nItemTemplateId, bOwned)
    local pWidgetRef = self.pWidgetRef
    if bOwned then
        pWidgetRef.bdrUnlock:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.kmtxtUnlockDesc:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnBuy:SetVisibility(ESlateVisibility.Collapsed)
    else
        local tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
        local nSourceType = tbTemplate.nSourceType
        if ItemSourceDataTable:IfShowBuyButton(nSourceType) then
            pWidgetRef.bdrUnlock:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.kmtxtUnlockDesc:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.btnBuy:SetVisibility(ESlateVisibility.Visible)
        else
            pWidgetRef.bdrUnlock:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.kmtxtUnlockDesc:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.btnBuy:SetVisibility(ESlateVisibility.Collapsed)
            local l10nToastDesc = ItemSourceDataTable:GetSourceDesc(nSourceType)
            pWidgetRef.kmtxtUnlockDesc:SetText(l10nToastDesc)
        end
    end
    self.nItemTemplateId = nItemTemplateId
end


function ULLobbyItemHint:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnBuy.OnClicked, self, OnBtnBuyClicked)
end


return ULLobbyItemHint