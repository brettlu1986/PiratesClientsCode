-----------------------------------------------------
--File Name    : UPBotHumanWeaponSlotInMain.lua
--Author       : lzheng
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPBotHumanWeaponSlotInMain = luaclass("UPBotHumanWeaponSlotInMain", PrefabBase)
local UISetUtils = require("UISetUtils")
local HumanWeaponDef = require("HumanWeaponDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local HumanWeaponSlotDef = require("HumanWeaponSlotDef")

local OPACITY_ON_SELECTED = 1
local OPACITY_ON_UNSELECTED = 0.6

UPBotHumanWeaponSlotInMain.nSlotIndex = -1

function UPBotHumanWeaponSlotInMain:SetSlotIndex(nIdx)
    self.nSlotIndex = nIdx
    local pWidgetRef = self.pWidgetRef
    if HumanWeaponSlotDef.Slots[nIdx] == HumanWeaponDef.WeaponSlotCategory.Melee then
        pWidgetRef.txtSlotCategory:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_MELEE_WEAPON"))
    elseif HumanWeaponSlotDef.Slots[nIdx] == HumanWeaponDef.WeaponSlotCategory.Ranged then
        pWidgetRef.txtSlotCategory:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_RANGED_WEAPON"))
    else
        pWidgetRef.txtSlotCategory:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPBotHumanWeaponSlotInMain:RefreshWeaponIcon(nWeaponTemplateId, nActiveWeaponSlot)
    local pWidgetRef = self.pWidgetRef
    if nWeaponTemplateId == 0 then  --empty hand
        pWidgetRef.img:SetVisibility(ESlateVisibility.Collapsed)
    else
        local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
        pWidgetRef.img:SetVisibility(ESlateVisibility.HitTestInvisible)
        local szRes = nil
        local tbResTemplate = BattleItemDataTable:GetResTemplate(nWeaponTemplateId)
        if tbTemplate.nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM then
            szRes = tbResTemplate.szIconPath
        else
            if tbTemplate.nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee then
                szRes = tbResTemplate.szSilhouettePath
            else
                szRes = tbResTemplate.szSilhouettePath
            end
        end
        --UISetUtils.SetImageBrushRes(pWidgetRef.img, pRes)
        if szRes and szRes ~= "" then
            UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.img, szRes, nil)
        end
        if self.nSlotIndex == nActiveWeaponSlot then   
            pWidgetRef.chkSlot:SetCheckedState(ECheckBoxState.Checked)
            pWidgetRef:SetRenderOpacity(OPACITY_ON_SELECTED)
        else  
            pWidgetRef.chkSlot:SetCheckedState(ECheckBoxState.Unchecked)
            pWidgetRef:SetRenderOpacity(OPACITY_ON_UNSELECTED)
        end
    end

end

function UPBotHumanWeaponSlotInMain:RefreshWeaponBullet(nWeaponTemplateId, nCurrentBullet)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnFireType:SetVisibility(ESlateVisibility.Collapsed)
    if nWeaponTemplateId == 0 then
        pWidgetRef.hboxBulletInfo:SetVisibility(ESlateVisibility.Collapsed)
    else 
        pWidgetRef.hboxBulletInfo:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtLoadingBulletCount:SetText(nCurrentBullet)
        local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
        pWidgetRef.txtSplit:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtUnloadingBulletCount:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtUnloadingBulletCount:SetText(tbTemplate.nBulletMax)
    end
end

function UPBotHumanWeaponSlotInMain:OnLoad()
    self.pWidgetRef.btnFireType:SetVisibility(ESlateVisibility.Hidden)
end

function UPBotHumanWeaponSlotInMain:OnBindEvent( EventHelper )
end


return UPBotHumanWeaponSlotInMain