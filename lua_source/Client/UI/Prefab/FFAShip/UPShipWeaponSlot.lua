local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPShipWeaponSlot = luaclass("UPShipWeaponSlot", PrefabBase)

local L10N = require("L10N")
local MathUtil = require("MathUtil")
local UITextDef = require("UITextDef")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local BattleItemDataTable = require("BattleItemDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

UPShipWeaponSlot.nSlot = ShipWeaponSlotDef.HEAD
UPShipWeaponSlot.bActive = false
UPShipWeaponSlot.WeaponItem = nil
UPShipWeaponSlot.tbCdRefreshTimer = nil
UPShipWeaponSlot.nCdStartTime = 0
UPShipWeaponSlot.nCdDuration = 0

local RENDER_OPACITY_SELECTED = 1
local RENDER_OPACITY_UNSELECTED = 0.6
local CD_REFRESH_INTERVAL = 0.03

local function OnCdFinish(self)
    self.pWidgetRef.pgbWeaponCD:SetVisibility(ESlateVisibility.Collapsed)
    self.TimerHelper:ClearTimer(self.tbCdRefreshTimer)
    self.tbCdRefreshTimer = nil
end

local function OnCdTick(self)
    local nPercent = 1 - MathUtil.Clamp((getseconds() - self.nCdStartTime) / self.nCdDuration, 0, 1)
    self.pWidgetRef.pgbWeaponCD:SetPercent(nPercent)
    if nPercent <= 0 then
        OnCdFinish(self)
    end
end

local function OnCdStart(self, nDuration, nStartTime)
    self.nCdStartTime = nStartTime
    self.nCdDuration = nDuration
    if not self.tbCdRefreshTimer then
        self.tbCdRefreshTimer = self.TimerHelper:NewTimerMethod(self, OnCdTick, CD_REFRESH_INTERVAL, true)
    end
    self.pWidgetRef.pgbWeaponCD:SetPercent(1)
    self.pWidgetRef.pgbWeaponCD:SetVisibility(ESlateVisibility.HitTestInvisible)
end

local function UpdateBulletCount(self)
    local pSlateColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
    local nBulletItemTemplateId = self.WeaponItem:GetBulletItemTemplateId()
    if nBulletItemTemplateId > 0 then
        local nLoadedCount = self.WeaponItem:GetBulletLoadedCount(true)
        if self.WeaponItem:IsInfiniteBullet() then
            local nMaxLoadedCount = self.WeaponItem:GetBulletMaxLoadingCount()
            self.pWidgetRef.txtBulletCount:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("UI_BULLET_COUNT"), nLoadedCount, nMaxLoadedCount))
            self.EventHelper:FireEvent(ClientEventDef.EV_SHIP_WEAPON_BULLET_COUNT, nLoadedCount)
        else
            local nUnloadedCount = self.WeaponItem:GetBulletUnloadedCount(true)
            self.pWidgetRef.txtBulletCount:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("UI_BULLET_COUNT"), nLoadedCount, nUnloadedCount))
            if (nLoadedCount == 0) and (nUnloadedCount == 0) then
                pSlateColor = UIResourceDef.COLOR.RED.SLATE_COLOR
            end
        end
        self.pWidgetRef.txtBulletCount:SetColorAndOpacity(pSlateColor)
    else
        self.pWidgetRef.txtBulletCount:SetVisibility(ESlateVisibility.Collapsed)
    end
    UISetUtils.SetImageBrushTint(self.pWidgetRef.imgIcon, pSlateColor)
    self.pWidgetRef.txtSlotName:SetColorAndOpacity(pSlateColor)
    -- self.pWidgetRef.txtWeaponName:SetColorAndOpacity(pSlateColor)
end

local function OnCheckStateChanged(self, bChecked)
    self.pWidgetRef.chkSlot:SetIsChecked(not bChecked)
    if self.WeaponItem then
        BattleShipWeaponSystem:RequestActivateWeaponItem(bChecked and self.WeaponItem)
    end
end

local function StartCD(self, WeaponItem, nDuration, nStartTime)
    if (not WeaponItem) or (self.nSlot ~= WeaponItem:GetWeaponSlot()) then
        return
    end
    if (nDuration > 0) then
        OnCdStart(self, nDuration, nStartTime)
    else
        OnCdFinish(self)
    end
end

local function OnBattleItemChanged(self, nItemTemplateId)
    if self.WeaponItem and (self.WeaponItem:GetBulletItemTemplateId() == nItemTemplateId) then
        UpdateBulletCount(self)
    end
end

local function OnBattleItemChangedWithItem(self, Item)
    if Item then
        OnBattleItemChanged(self, Item:GetTemplateId())
    end
end

local function PlayEquipAttachmentAnim(self, nItemTemplateId)
    local pWidgetRef = self.pWidgetRef
    local tbItemResTemplate = BattleItemDataTable:GetResTemplate(nItemTemplateId)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgAttachment, szIconPath:load(), true)
    self:PlayAnimation("animEquip", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

local function CheckEquipAnim(self, Item)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer:IsShip() then
        local nCategory = Item:GetCategory()
        if nCategory == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT then
            local _, nOwnerInstanceId, _ = Item:SplitAndGetStorageLocation()
            local tbOwnerItem = BattleItemSystemClient:GetItem(nOwnerInstanceId)
            local _, _, nSlotIndex = tbOwnerItem:SplitAndGetStorageLocation()
            if self.nSlot == nSlotIndex then
                PlayEquipAttachmentAnim(self, Item:GetTemplateId())
            end
        end
    end
end

local function OnBattleItemEquiped(self, Item)
    OnBattleItemChangedWithItem(self, Item)
    CheckEquipAnim(self, Item)
end

local function OnBattleItemUnequiped(self, _, _, nItemTemplateId)
    OnBattleItemChanged(self, nItemTemplateId)
end

local function OnBattleItemAdd(self, Item)
    OnBattleItemChangedWithItem(self, Item)
end

local function OnBattleItemRemove(self, _, nItemTemplateId)
    OnBattleItemChanged(self, nItemTemplateId)
end

local function OnBattleItemChangeStackCount(self, Item)
    OnBattleItemChangedWithItem(self, Item)
end

local function RegisterWeaponEvent(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRING_CD_BEGAN_CLIENT   , self, StartCD)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_EQUIPED_CLIENT              , self, OnBattleItemEquiped)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_UNEQUIPED_CLIENT            , self, OnBattleItemUnequiped)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT                  , self, OnBattleItemAdd)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT               , self, OnBattleItemRemove)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT    , self, OnBattleItemChangeStackCount)
end

local function UnregisterWeaponEvent(self)
    local EventHelper = self.EventHelper
    EventHelper:UnregisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRING_CD_BEGAN_CLIENT)
    EventHelper:UnregisterEvent(ClientEventDef.EV_BATTLE_ITEM_EQUIPED_CLIENT)
    EventHelper:UnregisterEvent(ClientEventDef.EV_BATTLE_ITEM_UNEQUIPED_CLIENT)
    EventHelper:UnregisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT)
    EventHelper:UnregisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT)
    EventHelper:UnregisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT)
end

function UPShipWeaponSlot:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.chkSlot.OnCheckStateChanged, self, OnCheckStateChanged)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.cpgbReloadCD.OnAnimationFinished, self, self.OnShipWeaponBulletLoadEnded)
end

function UPShipWeaponSlot:Init(nSlot)
    self.nSlot = nSlot
    self.pWidgetRef.txtSlotName:SetText(UITextDef.SHIP_WEAPON_SLOT_NAME[nSlot])
end

function UPShipWeaponSlot:SetActive(bActive)
    self.bActive = bActive
    self.pWidgetRef.cvsSlot:SetRenderOpacity(bActive and RENDER_OPACITY_SELECTED or RENDER_OPACITY_UNSELECTED)
    self.pWidgetRef.chkSlot:SetIsChecked(bActive)
end

function UPShipWeaponSlot:SetWeaponItem(WeaponItem)
    UnregisterWeaponEvent(self)
    self.WeaponItem = WeaponItem
    local pWidgetRef = self.pWidgetRef
    if WeaponItem then
        local tbResTemplate = BattleItemDataTable:GetResTemplate(WeaponItem:GetTemplateId())
        if tbResTemplate and tbResTemplate.szSilhouettePath then
            --UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, tbResTemplate.szSilhouettePath:load())
            UISetUtils.SetAsyncImageBrushFromSprite(pWidgetRef.imgIcon, tbResTemplate.szSilhouettePath, nil, true)
        end
        pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtBulletCount:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.cpgbReloadCD:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtSlotName:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.chkSlot:SetIsEnabled(true)
        -- pWidgetRef.txtWeaponName:SetText(WeaponItem:GetTemplate().l10nName)
        -- pWidgetRef.txtWeaponName:SetVisibility(pHitTestInvisible)
        UpdateBulletCount(self)
        RegisterWeaponEvent(self)
    else
        OnCdFinish(self)
        pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtBulletCount:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.cpgbReloadCD:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtSlotName:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtSlotName:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        pWidgetRef.chkSlot:SetIsEnabled(false)
        -- pWidgetRef.txtWeaponName:SetVisibility(pCollapsed)
    end
end

function UPShipWeaponSlot:GetWeaponInstanceId()
    if self.WeaponItem then
        return self.WeaponItem:GetInstanceId()
    end
    return -1
end

function UPShipWeaponSlot:OnShipWeaponBulletLoadEnded()
    self.pWidgetRef.cpgbReloadCD:StopAnimation()
    self.pWidgetRef.cpgbReloadCD:SetVisibility(ESlateVisibility.Collapsed)
end

function UPShipWeaponSlot:OnShipWeaponBulletLoadBegan(nLoadingTime, nStartTime)
    if nLoadingTime <= 0 then
        self:OnShipWeaponBulletLoadEnded()
        return
    end

    local nRemainLoadingTime = MathUtil.Clamp(nStartTime + nLoadingTime - getseconds(), 0, nLoadingTime)
    local nRemainPercent = 1 - MathUtil.Clamp(nRemainLoadingTime / nLoadingTime, 0, 1)
    self.pWidgetRef.cpgbReloadCD:StartAnimation(nRemainPercent, 1, nRemainLoadingTime)
    self.pWidgetRef.cpgbReloadCD:SetVisibility(ESlateVisibility.HitTestInvisible)
end

return UPShipWeaponSlot