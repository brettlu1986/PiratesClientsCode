-----------------------------------------------------
--File Name    : UPHomeResearchShipWeaponItem.lua
--Author       : zhiyuan
--Create Time  : 2019-05-23
--Description  : 船武器研发的单行Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPHomeResearchShipWeaponItem = luaclass("UPHomeResearchShipWeaponItem", ListItemBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local WEAPON_ITEM_PADDING = Margin{Left=20, Top=0, Right=0, Bottom=0}
UPHomeResearchShipWeaponItem.tbWeaponItems = nil

local function AllocWeaponItems(self, nCount)
    local tbExtraDatas = self.ListHelper.tbExtraDatas
    local tbWeaponItems = self.tbWeaponItems
    local nCurrentCount = #tbWeaponItems
    if nCurrentCount > nCount then
        for i = nCurrentCount, nCount + 1, -1 do
            local pbWeaponItem = tbWeaponItems[i]
            self.pWidgetRef.scrItems:RemoveChild(pbWeaponItem.pWidgetRef)
            tbExtraDatas.fnRecycleWeaponItem(pbWeaponItem)
            table.remove(tbWeaponItems, i)
        end
    elseif nCurrentCount < nCount then
        for i = nCurrentCount + 1, nCount do
            local pbWeaponItem = tbExtraDatas.fnAllocWeaponItem()
            local pSlot = self.pWidgetRef.scrItems:AddChild(pbWeaponItem.pWidgetRef)
            pSlot:SetPadding(WEAPON_ITEM_PADDING)
            table.insert(tbWeaponItems, pbWeaponItem)
        end
    end
end

function UPHomeResearchShipWeaponItem:OnLoad()
    self.tbWeaponItems = {}
end

function UPHomeResearchShipWeaponItem:OnRefresh(tbData)
    self.pWidgetRef.txtName:SetText(tbData.l10nName)

    local tbTemplates = GamePlayerSelfHelper:Get().ShipPreparationComponent:GetWeaponTemplatesByCategory(tbData.nCategory)
    AllocWeaponItems(self, #tbTemplates)
    for i, tbTemplate in ipairs(tbTemplates) do
        self.tbWeaponItems[i]:SetWeaponTemplate(tbTemplate)
        if self.ListHelper.tbExtraDatas.nSelectedItemId == tbTemplate.nId then
            self.tbWeaponItems[i]:TriggerSelectItem()
        end
    end

    if self.nIndex == 1 then
        local tbWeaponItem = self.tbWeaponItems[1]
        tbWeaponItem:SetSelectItem()
    end
end

return UPHomeResearchShipWeaponItem