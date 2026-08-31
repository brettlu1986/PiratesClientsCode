local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPShipPartSlot = luaclass("UPShipPartSlot", PrefabBase)

local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemResDataTable = require("BattleItemResDataTable")
local UISetUtils = require("UISetUtils")
local UIFFABackpackHelper = require("UIFFABackpackHelper")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPShipPartSlot.nSlot = -1
UPShipPartSlot.nShipPartInstanceId = -1

function UPShipPartSlot:Init(nSlot)
    self.nSlot = nSlot
    local l10nName = BattleItemDataTable:GetSubCategoryName(BattleItemCategoryDef.SHIP_PART, nSlot)
    self.pWidgetRef.txtName:SetText(l10nName)
end


function UPShipPartSlot:SetShipPartInstanceId(nShipPartInstanceId)
    local pWidgetRef = self.pWidgetRef
    self.nShipPartInstanceId = nShipPartInstanceId
    local tbShipPartItem = BattleItemSystemClient:GetItem(self.nShipPartInstanceId)
    if tbShipPartItem then
        local tbItemTemplate = tbShipPartItem.tbTemplate
        pWidgetRef.imgLevel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        UIFFABackpackHelper.SetPartLevel(pWidgetRef.imgLevel, tbItemTemplate.nGrade)
        pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local nPercent = 1 - tbShipPartItem.nDurability / tbItemTemplate.nDurability
        pWidgetRef.pgbDurability:SetPercent(nPercent)
        local tbRes = BattleItemResDataTable:GetTemplate(tbItemTemplate.nResId)
        if tbRes then
            local szItemIconPath = tbRes.szIconPath
            local pIconObj = szItemIconPath:load()
            if pIconObj then
                pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
                UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, pIconObj, true)
            end

            pWidgetRef.imgColour:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            local nItemTemplateId = tbShipPartItem:GetTemplateId()
            local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
            UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())
        end
    else
        pWidgetRef.imgLevel:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgColour:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.pgbDurability:SetPercent(0)
        pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.Collapsed)
    end
end

return UPShipPartSlot