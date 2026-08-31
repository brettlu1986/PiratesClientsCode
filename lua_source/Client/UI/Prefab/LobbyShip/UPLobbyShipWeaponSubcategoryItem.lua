-----------------------------------------------------
--File Name    : UPLobbyShipWeaponSubcategoryItem.lua
--Author       : chenyixin
--Description  : 船战备舰船武器分页单行Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyShipWeaponSubcategoryItem = luaclass("UPLobbyShipWeaponSubcategoryItem", ListItemBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

-- local WEAPON_ITEM_PADDING = Margin{Left=20, Top=0, Right=0, Bottom=0}
local MAX_WEAPON_COUNT = 3
local WEAPON_ITEM_NAME = "pbWeapon"
UPLobbyShipWeaponSubcategoryItem.tbWeaponItems = {}
UPLobbyShipWeaponSubcategoryItem.tbTemplates = {}
UPLobbyShipWeaponSubcategoryItem.ListHelper = nil

local function AllocWeaponItems(self)
    local tbTemplates = self.tbTemplates

    for i = 1, MAX_WEAPON_COUNT do
        local tbTemplate = tbTemplates[i]
        local pVisibility = tbTemplate ~= nil and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed
        self.pWidgetRef[WEAPON_ITEM_NAME .. i]:SetVisibility(pVisibility)
    end
end

function UPLobbyShipWeaponSubcategoryItem:OnLoad()
    self.ListHelper = self.Owner.ListHelper
    for i = 1, MAX_WEAPON_COUNT do
        local tbWeaponItem = self.PrefabHelper:BindPrefab(self.pWidgetRef[WEAPON_ITEM_NAME .. i])
        self.tbWeaponItems[i] = tbWeaponItem
    end
end

function UPLobbyShipWeaponSubcategoryItem:OnBindEvent(EventHelper)
    local fnClickCallback = self.ListHelper.tbExtraDatas.fnOnWeaponClicked
    local fnSelectCallback = self.ListHelper.tbExtraDatas.fnOnWeaponSelectedChanged
    for i = 1, MAX_WEAPON_COUNT do
        self.tbWeaponItems[i]:SetCallback(fnClickCallback, fnSelectCallback)
    end
end

function UPLobbyShipWeaponSubcategoryItem:OnRefresh(tbData)
    self.pWidgetRef.txtName:SetText(tbData.l10nName)

    self.tbTemplates = GamePlayerSelfHelper:Get().ShipPreparationComponent:GetWeaponTemplatesByCategory(tbData.nCategory)
    AllocWeaponItems(self)
    for i, tbTemplate in ipairs(self.tbTemplates) do
        self.tbWeaponItems[i]:SetWeaponTemplate(tbTemplate)
        if self.ListHelper.tbExtraDatas.nSelectedItemId == tbTemplate.nId then
            self.tbWeaponItems[i]:TriggerSelectItem()
        end
    end
end

function UPLobbyShipWeaponSubcategoryItem:SelectItemByIndex(nIndex)
    for i, tbWeaponItem in pairs(self.tbWeaponItems) do
        if i == nIndex then
            tbWeaponItem:SelectItem()
        else
            tbWeaponItem:UnselectItem()
        end
    end
end

function UPLobbyShipWeaponSubcategoryItem:SelectItemById(nId)
    for nIndex, tbTemplate in pairs(self.tbTemplates) do
        if tbTemplate.nId == nId then
            self:SelectItemByIndex(nIndex)
            return
        end
    end
end

return UPLobbyShipWeaponSubcategoryItem