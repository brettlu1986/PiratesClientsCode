-----------------------------------------------------
--File Name    : UPHumanWeaponSlot.lua
--Author       : WuJizhou
--Create Time  : 9/4/2018, 4:42:22 PM
--Description  : UPHumanWeaponSlot
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPHumanWeaponSlot = luaclass("UPHumanWeaponSlot", PrefabBase)
local UIDef = require("UIDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemResDataTable = require("BattleItemResDataTable")
local UISetUtils = require("UISetUtils")
local HumanWeaponDef = require("HumanWeaponDef")
local L10N = require("L10N")
local BattleItemDataTable = require("BattleItemDataTable")
local HumanWeaponSlotDef = require("HumanWeaponSlotDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local PackageDragCategoryDef = require("PackageDragCategoryDef")
local HumanWeaponAttachmentSlotDef = require("HumanWeaponAttachmentSlotDef")
local UIDragDropUtils = require("UIDragDropUtils")
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew_C")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")
local UIResourceDef = require("UIResourceDef")
local BattleItemUIHelper = require("BattleItemUIHelper")
-- local GlobalVariableSystem = require("GlobalVariableSystem_C")

UPHumanWeaponSlot.tbAttachmentSlots = nil
UPHumanWeaponSlot.nSlotIndex = -1
UPHumanWeaponSlot.bLazyDragEventBinded = false
UPHumanWeaponSlot.bLazyDropEventBinded = false
UPHumanWeaponSlot.bEnabled = false

local tbUIWidgetToSlotIndex = {
    "pbPackItem01",
    "pbPackItem05",
    "pbPackItem02",
    "pbPackItem03",
    "pbPackItem04"
}


-- local function Unequip(self)

--     if not self.tbWeaponItem then
--         return
--     end
--     BattleItemSystemClient:RequestUnEquipItem(self.tbWeaponItem:GetInstanceId())
-- end


local function OnAcceptWeaponItemDropped(self, tbItem)
    if self.tbWeaponItem and tbItem:GetInstanceId() == self.tbWeaponItem:GetInstanceId() then
        return
    end
    local nSlotIndex = self.nSlotIndex
    local nPlayerInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local tbCurItem = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON, nPlayerInstanceId, nSlotIndex)
    local nItemInstanceId = tbItem:GetInstanceId()
    if tbCurItem == nil then
        BattleItemSystemClient:TryToRequestEquipItem(nPlayerInstanceId, nSlotIndex, tbItem)
    else
        local nCurInstanceId = tbCurItem:GetInstanceId()
        if BattleItemSystemClient:CanExchangeStorageLocation(nCurInstanceId, nItemInstanceId) then
            BattleItemSystemClient:RequestExchangeStorageLocation(nCurInstanceId, nItemInstanceId)
        end
    end
end

local function OnAcceptAttachmentItemDropped(self, tbItem, nDragSourceCategory)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local nSlotIndex = self.nSlotIndex
    local tbMoveToEquip = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nSlotIndex)
    if not tbMoveToEquip then
        return
    end
    local nMoveToEquipInstanceId = tbMoveToEquip:GetInstanceId()
    local nAttachmentSlotIndex = HumanWeaponAttachmentSlotDef:GetSlotIndex(tbItem:GetAttachmentCategory())
    local bMatchTarget = BattleItemSystemClient:CheckItemSlotCompatibility(nMoveToEquipInstanceId, nAttachmentSlotIndex, tbItem)
    if not bMatchTarget then -- 不匹配目标位
        return
    end
    local nHoveredAttachmentInstanceId = tbItem:GetInstanceId()
    if nDragSourceCategory == PackageDragCategoryDef.HUMAN_PACKAGE_ITEM then -- 从背包拖出
        BattleItemSystemClient:TryToRequestEquipItem(nMoveToEquipInstanceId, nAttachmentSlotIndex, tbItem)
        return
    end

    if nDragSourceCategory ~= PackageDragCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        return
    end

    --从别的武器上拖出
    --移动的目的地上的配件
    local tbMoveToAttachment = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nMoveToEquipInstanceId, nAttachmentSlotIndex)
    if not tbMoveToAttachment then
        BattleItemSystemClient:TryToRequestEquipItem(nMoveToEquipInstanceId, nAttachmentSlotIndex, tbItem)
        return
    end

    local nMoveToAttachmentInstanceId = tbMoveToAttachment:GetInstanceId()
    if nMoveToAttachmentInstanceId == nHoveredAttachmentInstanceId then
        return
    end
    -- 检验目的地的配件是否可以装备到来源地
    local nMoveFromEquipInstanceId = tbItem:GetStorageLocation().nOwnerInstanceId
    local bAvailable = BattleItemSystemClient:CheckItemSlotCompatibility(nMoveFromEquipInstanceId, nAttachmentSlotIndex, tbMoveToAttachment)
    if bAvailable then
        BattleItemSystemClient:RequestExchangeStorageLocation(nHoveredAttachmentInstanceId, nMoveToAttachmentInstanceId)
    else
        BattleItemSystemClient:TryToRequestEquipItem(nMoveToEquipInstanceId, nAttachmentSlotIndex, tbItem)
    end

end

local function OnAcceptDrop(self, nDragSourceCategory, nDragSourceId)
    local tbItem = BattleItemSystemClient:GetItem(nDragSourceId)
    if not tbItem then
        logerror("OnAcceptDrop failed", nDragSourceCategory, nDragSourceId)
        return
    end
    local nCategory = tbItem:GetCategory()
    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        OnAcceptWeaponItemDropped(self, tbItem)
    elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        OnAcceptAttachmentItemDropped(self, tbItem, nDragSourceCategory)
    end
end

local function OnCreateVisual(self, pVisualWidget)
    local tbWeaponItem = self.tbWeaponItem
    if tbWeaponItem then
        local tbWeaponTemplate = tbWeaponItem:GetTemplate()
        local nResId = tbWeaponTemplate.nResId
        local tbRes = BattleItemResDataTable:GetTemplate(nResId)
        if not tbRes then
            logerror("UPHumanWeaponSlot OnCreateVisual: invalid res id ", nResId)
            return
        end
        local szItemIconPath = BattleItemUIHelper.GetWeaponIcon(tbWeaponTemplate)
        if szItemIconPath ~= nil then
            local IconObj = szItemIconPath:load()
            if(IconObj == nil)then
                logwarning("UPHumanWeaponSlot OnCreateVisual: icon is not found, path="..tostring(szItemIconPath))
                return
            end
            local pWidgetRef = self.pWidgetRef
            UISetUtils.SetImageBrushRes(pVisualWidget.imgContent, IconObj, false, true, pWidgetRef.DragSizeX, pWidgetRef.DragSizeY)
        else
            logwarning("UPHumanWeaponSlot OnCreateVisual: icon does not have path config, res id :", nResId)
        end
    end
end
-----------public------------

function UPHumanWeaponSlot:SetSlotIndex(nIdx)
    self.nSlotIndex = nIdx
    for k, v in pairs(self.tbAttachmentSlots) do
        v:SetOwnerWeaponSlotIndex(nIdx)
    end
end

function UPHumanWeaponSlot:ShowWeapon(tbHumanWeaponItem)
    self.tbWeaponItem = tbHumanWeaponItem
    local pWidgetRef = self.pWidgetRef
    local Visible = ESlateVisibility.SelfHitTestInvisible
    local InVisible = ESlateVisibility.Collapsed
    --local pbDrag = pWidgetRef.pbDrag
    local pbDrag = pWidgetRef
    self:RegisterDropEvent()
    if tbHumanWeaponItem == nil then
        pbDrag.bEnableDrag = false
        pbDrag.bEnableDrop = true
        pWidgetRef.txtWeaponName:SetVisibility(Visible)
        if HumanWeaponSlotDef.Slots[self.nSlotIndex] == HumanWeaponDef.WeaponSlotCategory.Melee then
            pWidgetRef.txtWeaponName:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_MELEE_WEAPON"))
        elseif HumanWeaponSlotDef.Slots[self.nSlotIndex] == HumanWeaponDef.WeaponSlotCategory.Ranged then
            pWidgetRef.txtWeaponName:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_HUMAN_RANGED_WEAPON"))
        else
            pWidgetRef.txtWeaponName:SetVisibility(InVisible)
        end
        pWidgetRef.txtBulletName:SetVisibility(InVisible)
        pWidgetRef.imgIcon:SetVisibility(InVisible)
        pWidgetRef.imgColour:SetVisibility(InVisible)
        pWidgetRef.imgLevel:SetVisibility(InVisible)
        pWidgetRef.txtIsInUse:SetVisibility(InVisible)
        for _, v in pairs(self.tbAttachmentSlots) do
            v:SetVisibility(InVisible)
        end
    else
        self:RegisterDragEvent()
        pbDrag.bEnableDrag = true
        pbDrag.bEnableDrop = true
        pbDrag.DragId = tbHumanWeaponItem:GetInstanceId()
        pbDrag.DragCategory = PackageDragCategoryDef.HUMAN_WEAPON
        pWidgetRef.txtWeaponName:SetVisibility(Visible)
        pWidgetRef.txtBulletName:SetVisibility(Visible)
        pWidgetRef.imgIcon:SetVisibility(Visible)
        pWidgetRef.imgColour:SetVisibility(Visible)

        local tbTemplate = tbHumanWeaponItem:GetTemplate()
        pWidgetRef.txtWeaponName:SetText(tbTemplate.l10nName)
        -- 图标
        local szRes = BattleItemUIHelper.GetWeaponIcon(tbTemplate)
        if szRes then
            --local pRes = szRes:load()
            --UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, pRes, true)
            UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgIcon, szRes, nil, true)
        end
        -- 颜色图标
        local nItemTemplateId = tbTemplate.nId
        local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())
        -- 武器等级
        pWidgetRef.imgLevel:SetVisibility(Visible)
        local nGrade = BattleItemDataTable:GetGrade(nItemTemplateId)
        local szGradeIcon = UIResourceDef.HUMAN_WEAPON_GRADE_ICON[nGrade]
        UISetUtils.SetImageBrushRes(pWidgetRef.imgLevel, szGradeIcon:load())
        -- 子弹数量
        if tbTemplate.nPrimaryCategory == HumanWeaponDef.WeaponPrimaryCategory.Melee 
            or tbTemplate.nWeaponCategory == HumanWeaponDef.WeaponCategory.Wand then
            pWidgetRef.txtBulletName:SetVisibility(InVisible)
        else
            pWidgetRef.txtBulletName:SetVisibility(Visible)

            local nLoadedCount = tbHumanWeaponItem:GetCurrentAmmoCount(true)
            local szCountDesc = nil
            if tbHumanWeaponItem:IsBulletInfinite() then
                local nTotalCount = tbHumanWeaponItem.tbProperty[HumanWeaponDef.Property.BulletMax]
                szCountDesc = L10N:Format(UISetUtils.GetL10NTextByKey("UI_BULLET_COUNT"), nLoadedCount, nTotalCount)
                -- szCountDesc = L10N:Format(UISetUtils.GetL10NTextByKey("UI_BULLET_COUNT"), nLoadedCount, UISetUtils.GetL10NTextByKey("UI_INFINITE_BULLET"))
                pWidgetRef.txtBulletName:SetText(szCountDesc)
            else
                local szUnloadedCount = BattleItemSystemClient:GetUnequippedItemCount(tbTemplate.nBulletType)
                szCountDesc = L10N:Format(UISetUtils.GetL10NTextByKey("UI_BULLET_COUNT"), nLoadedCount, szUnloadedCount)
                pWidgetRef.txtBulletName:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("UI_AMMO_STATE"),
                BattleItemDataTable:GetTemplate(tbTemplate.nBulletType).l10nName, szCountDesc))
            end
        end

        --根据武器决定配件槽有几个
        for i, v in ipairs(tbTemplate.tbAttachmentSlots) do
            local tbAttachmentSlot = self.tbAttachmentSlots[i]
            if #v > 0 then
                tbAttachmentSlot:SetVisibility(Visible)
                -- 从装备上取slot上的配件
                local nWeaponInstanceId = tbHumanWeaponItem:GetInstanceId()
                local tbWeaponAttachment = BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT,nWeaponInstanceId, i)
                local szSlotName = tbTemplate.tbAttachmentSlotNames[i]
                tbAttachmentSlot:ShowAttachment(tbWeaponAttachment, szSlotName)
                tbAttachmentSlot:RegisterDropEvent()
            else
                tbAttachmentSlot:SetVisibility(InVisible)
            end
        end

        --根据是否为当前武器来判断
        local bCurrentWeapon = BattleHumanWeaponSystemNew:IsCurrentWeapon(tbHumanWeaponItem)

        if bCurrentWeapon then
            pWidgetRef.txtIsInUse:SetVisibility(Visible)
        else
            pWidgetRef.txtIsInUse:SetVisibility(InVisible)
        end
    end
end

function UPHumanWeaponSlot:Disable()
    local pWidgetRef = self.pWidgetRef
    local InVisible = ESlateVisibility.Collapsed
    pWidgetRef.bEnableDrag = false
    pWidgetRef.bEnableDrop = false
    pWidgetRef.txtWeaponName:SetVisibility(InVisible)
    pWidgetRef.txtBulletName:SetVisibility(InVisible)
    pWidgetRef.imgIcon:SetVisibility(InVisible)
    pWidgetRef.imgColour:SetVisibility(InVisible)

    pWidgetRef.txtIsInUse:SetVisibility(InVisible)
    for _, v in pairs(self.tbAttachmentSlots) do
        v:SetVisibility(InVisible)
    end
end


----------life cycle----------
function UPHumanWeaponSlot:OnCreate()
    self.tbAttachmentSlots = {}
end

-- function UPHumanWeaponSlot:OnDestroy()
-- end

function UPHumanWeaponSlot:OnLoad()
    for i, v in ipairs(tbUIWidgetToSlotIndex) do
        local tbAttachementSlot = self.PrefabHelper:BindPrefab(self.pWidgetRef[v], UIDef.UP_HUMAN_WEAPON_ATTACHMENT_SLOT)
        tbAttachementSlot:SetSlotIndex(i)
        table.insert(self.tbAttachmentSlots, tbAttachementSlot)
    end
    --self.pWidgetRef.pbDrag:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
end

-- function UPHumanWeaponSlot:OnUnload()
-- end

-- function UPHumanWeaponSlot:OnEnter()
-- end

-- function UPHumanWeaponSlot:OnShow()
-- end

function UPHumanWeaponSlot:OnExit()
    self.bLazyDragEventBinded = false
    self.bLazyDropEventBinded = false
end


function UPHumanWeaponSlot:OnBindEvent( EventHelper )

end

function UPHumanWeaponSlot:SetEnable(bEnabled)
    self.bEnabled = bEnabled
    for _,v in ipairs(self.tbAttachmentSlots) do
        v:SetEnable(bEnabled)
    end
    if not bEnabled then
        self.bLazyDropEventBinded = false
        self.bLazyDragEventBinded = false
        self.EventHelper:UnregisterAll()
    end
end



function UPHumanWeaponSlot:RegisterDragEvent()
    if not self.bLazyDragEventBinded and self.bEnabled and self.tbWeaponItem then
        local EventHelper = self.EventHelper
        local pWidgetRef = self.pWidgetRef
        --local pbDrag = pWidgetRef.pbDrag
        local pbDrag = pWidgetRef
        EventHelper:RegisterCppDelegate(pbDrag.OnCreateVisual,self,OnCreateVisual)
        UIDragDropUtils.FireEventWhenItemDragged(EventHelper, pbDrag)
        self.bLazyDragEventBinded = true
    end
end

function UPHumanWeaponSlot:RegisterDropEvent()
    if not self.bLazyDropEventBinded and self.bEnabled then
        local EventHelper = self.EventHelper
        local pWidgetRef = self.pWidgetRef
        -- local pbDrag = pWidgetRef.pbDrag
        local pbDrag = pWidgetRef
        EventHelper:RegisterCppDelegate(pbDrag.OnAcceptDrop, self, OnAcceptDrop)
        UIDragDropUtils.FireEventWhenItemDropped(EventHelper, pbDrag)
        self.bLazyDropEventBinded = true
    end
end

-- function UPHumanWeaponSlot:SetEnable(bEnable)
--     if bEnable then
--         self:RegisterDropEvent()
--         self:RegisterDragEvent()
--     else
--         self:UnbindEvent()
--     end
-- end

-- function UPHumanWeaponSlot:OnUnbindEvent( EventHelper )
-- end

return UPHumanWeaponSlot