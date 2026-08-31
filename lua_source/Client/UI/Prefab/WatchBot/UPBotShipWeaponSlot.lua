--待完善
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBotShipWeaponSlot = luaclass("UPBotShipWeaponSlot", PrefabBase)

local UITextDef = require("UITextDef")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local BattleItemDataTable = require("BattleItemDataTable")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")

UPBotShipWeaponSlot.nSlot = ShipWeaponSlotDef.HEAD
UPBotShipWeaponSlot.bActive = false

local RENDER_OPACITY_SELECTED = 1
local RENDER_OPACITY_UNSELECTED = 0.6

function UPBotShipWeaponSlot:Init(nSlot)
    self.nSlot = nSlot
    self.pWidgetRef.txtSlotName:SetText(UITextDef.SHIP_WEAPON_SLOT_NAME[nSlot])
end

function UPBotShipWeaponSlot:SetActive(bActive)
    self.bActive = bActive
    self.pWidgetRef.cvsSlot:SetRenderOpacity(bActive and RENDER_OPACITY_SELECTED or RENDER_OPACITY_UNSELECTED)
    self.pWidgetRef.chkSlot:SetIsChecked(bActive)
end

function UPBotShipWeaponSlot:RefreshWeaponIcon(nWeaponTemplateId, nActiveWeaponSlot)
    local pWidgetRef = self.pWidgetRef

    if nWeaponTemplateId == 0 then
        pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.Collapsed)
    else
        local tbResTemplate = BattleItemDataTable:GetResTemplate(nWeaponTemplateId)
        if tbResTemplate and tbResTemplate.szSilhouettePath then
            pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.HitTestInvisible)
            --local pRes = tbResTemplate.szSilhouettePath:load()
            --UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, pRes)
            UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgIcon, tbResTemplate.szSilhouettePath, nil)
        else
            pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.Collapsed)
        end
    end

    if self.nSlot == nActiveWeaponSlot then   
        pWidgetRef.chkSlot:SetCheckedState(ECheckBoxState.Checked)
        pWidgetRef.imgLight:SetVisibility(ESlateVisibility.HitTestInvisible)
    else  
        pWidgetRef.chkSlot:SetCheckedState(ECheckBoxState.Unchecked)
        pWidgetRef.imgLight:SetVisibility(ESlateVisibility.Collapsed)
    end

end

function UPBotShipWeaponSlot:RefreshWeaponBullet(nWeaponTemplateId, nCurrentBullet)
    local pWidgetRef = self.pWidgetRef
    local pSlateColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
    if nWeaponTemplateId == 0 then
        pWidgetRef.txtBulletCount:SetColorAndOpacity(pSlateColor)
        pWidgetRef.txtBulletCount:SetVisibility(ESlateVisibility.Collapsed)
    else 
        pWidgetRef.txtBulletCount:SetVisibility(ESlateVisibility.HitTestInvisible)
        -- local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponTemplateId)
        pWidgetRef.txtBulletCount:SetText(nCurrentBullet .. "/Max")
    end
end

return UPBotShipWeaponSlot