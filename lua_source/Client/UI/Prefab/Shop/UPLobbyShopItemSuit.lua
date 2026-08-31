-----------------------------------------------------
--File Name    : UPLobbyShopItemSuit.lua
-----------------------------------------------------
local luaclass          = require ("luaclass")
local PrefabBase        = require("PrefabBase")
local UPLobbyShopItemSuit    = luaclass("UPLobbyShopItemSuit", PrefabBase)
local UIDef = require("UIDef")


local MAX_ITEM_COUNT = 4
UPLobbyShopItemSuit.tbPbItems = nil

function UPLobbyShopItemSuit:Display(tbData)
    local pWidgetRef = self.pWidgetRef
    tbData.l10nTitle = tbData.l10nTitle
    local tbItemTemplateIds = tbData.tbItemTemplateIds
    for nIdx = 1, MAX_ITEM_COUNT do
        local nItemTemplateId = tbItemTemplateIds[nIdx]
        if nItemTemplateId then
            self.tbPbItems[nIdx].pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            self.tbPbItems[nIdx]:OnRefresh({nItemTemplateId = nItemTemplateId})
        else
            self.tbPbItems[nIdx].pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
        end
    end
    pWidgetRef.txtTitle:SetText(tbData.l10nTitle)

end

function UPLobbyShopItemSuit:OnLoad()
    self.tbPbItems = {}
    for nIdx = 1, MAX_ITEM_COUNT do
        local tbPb = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbItem".. nIdx], UIDef.UP_LOBBY_ITEM_SUB)
        table.insert(self.tbPbItems, tbPb)
    end
end

return UPLobbyShopItemSuit
