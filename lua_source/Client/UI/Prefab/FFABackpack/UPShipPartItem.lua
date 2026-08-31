local luaclass = require("luaclass")
local UPBattleItem = require("UPBattleItem")
local UPShipPartItem = luaclass("UPShipPartItem", UPBattleItem)
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local UIFFABackpackHelper = require("UIFFABackpackHelper")
local ClientEventDef = require("ClientEventDef")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local UISetUtils = require("UISetUtils")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPShipPartItem.nLimitItemCategory = BattleItemCategoryDef.SHIP_PART

function UPShipPartItem:OnLoad()
    UPShipPartItem.super.OnLoad(self)
end

function UPShipPartItem:OnEnter()
    UPShipPartItem.super.OnEnter(self)
    --local l10nName = BattleItemDataTable:GetSubCategoryName(BattleItemCategoryDef.SHIP_PART, self.nSlotIndex)
    --self.pWidgetRef.txtName:SetText(l10nName)
    --self.pWidgetRef.DragCategory = PackageDragCategoryDef.SHIP_PART
end

local function OnItemDurabilityChanged(self, nItemInstanceId)
    if nItemInstanceId == self.nItemInstanceId then
        self:SetItem(nItemInstanceId)
    end
end

function UPShipPartItem:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_DURABILITY_CLIENT, self, OnItemDurabilityChanged)
end

function UPShipPartItem:OnEquiped(tbItemObject)
    if tbItemObject then
        self.pWidgetRef.DragId = self.nItemInstanceId
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.DragCategory = PackageDragCategoryDef.SHIP_PART
        pWidgetRef:SetVisibility(ESlateVisibility_Visible)
        pWidgetRef.btnBlueprintItem:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.pgbDurability:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtName:SetVisibility(ESlateVisibility.Collapsed)

        local tbItemTemplate = tbItemObject:GetTemplate()
        local nItemTemplateId = tbItemObject:GetTemplateId()

        UIFFABackpackHelper.SetItemIcon(pWidgetRef.btnBlueprintItem, tbItemTemplate.nResId)

        pWidgetRef.imgColour:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

        pWidgetRef.imgLevel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        UIFFABackpackHelper.SetPartLevel(pWidgetRef.imgLevel, tbItemObject.tbTemplate.nGrade)
        local nDurability = tbItemObject:GetDurability()
        if nDurability >= 0 then
            local nPercent = 1 - nDurability / tbItemTemplate.nDurability
            pWidgetRef.pgbDurability:SetPercent(nPercent)
            pWidgetRef.cvsDuration:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtDuration:SetText(tbItemObject:GetDurabilityPercentageString())
        else
            pWidgetRef.txtDuration:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.pgbDurability:SetPercent(1)
        end
    end
end


function UPShipPartItem:OnUnequipped()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    pWidgetRef.btnBlueprintItem:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.imgColour:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.cvsDuration:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.pgbDurability:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.imgLevel:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.txtName:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    local l10nName = BattleItemDataTable:GetSubCategoryName(BattleItemCategoryDef.SHIP_PART, self.nSlotIndex)
    pWidgetRef.txtName:SetText(l10nName)
end

function UPShipPartItem:CanEquip(tbItemObject)
    if UPShipPartItem.super.CanEquip(self, tbItemObject) then
        return tbItemObject.tbTemplate.nSubCategory == self.nSlotIndex
    end
    return false
end

return UPShipPartItem