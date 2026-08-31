-----------------------------------------------------
--File Name    : UPLobbyShopItemCaptain.lua
-----------------------------------------------------
local luaclass          = require ("luaclass")
local PrefabBase        = require("PrefabBase")
local UPLobbyShopItemCaptain    = luaclass("UPLobbyShopItemCaptain", PrefabBase)
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")

function UPLobbyShopItemCaptain:Display(tbData)
    local pWidgetRef = self.pWidgetRef
    if not tbData then
        self.pWidgetRef.olBg:SetVisibility(ESlateVisibility.Hidden)
    else
        self.pWidgetRef.olBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        -- Display icon
        UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, tbData.szIcon:load())
        pWidgetRef.imgItem:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtFirstNameNew:SetText(tbData.l10nFirstName)
        pWidgetRef.txtSecondName:SetText(tbData.l10nSecondName)
        pWidgetRef.txtLastName:SetText(tbData.l10nLastName)

        local szGradeIcon = UIResourceDef.ITEM_INFO_GRADE_BG_V[tbData.nGrade]
        UISetUtils.SetImageBrushRes(pWidgetRef.imgBg, szGradeIcon:load())
    end
end

return UPLobbyShopItemCaptain
