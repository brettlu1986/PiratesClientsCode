local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPShipWeaponCannon = luaclass("UPShipWeaponCannon", PrefabBase)

local MathUtil = require("MathUtil")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local function LOG(...)
    log("[UPShipWeaponCannon]", ...)
end

local function OnCpgbLoadAnimationFinished(self)
    LOG("OnCpgbLoadAnimationFinished")
    self.pWidgetRef.imgCrosshairs:SetVisibility(ESlateVisibility.HitTestInvisible)
    self.pWidgetRef.ovlReload:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.cpgbReload:StopAnimation()
end

local function OnCpgbLoadAnimationStart(self, nLoadingTime, nLoadingStartTime)
    LOG("OnCpgbLoadAnimationStart")
    local nRemainLoadingTime = MathUtil.Clamp(nLoadingStartTime + nLoadingTime - getseconds(), 0, nLoadingTime)
    if (nLoadingTime > 0) and (nRemainLoadingTime > 0) then
        local nRemainPercent = 1 - MathUtil.Clamp(nRemainLoadingTime / nLoadingTime, 0, 1)
        self.pWidgetRef.imgCrosshairs:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.ovlReload:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.cpgbReload:StartAnimation(nRemainPercent, 1, nRemainLoadingTime)
    else
        OnCpgbLoadAnimationFinished(self)
    end
end

local function IsActiveWeaponItem(WeaponItem)
    return BattleShipWeaponSystem:GetActiveWeaponItem_C() == WeaponItem
end

local function OnShipWeaponBulletLoadEnded(self, tbCharacter, WeaponItem)
    if GamePlayerSelfHelper:IsPlayerSelf(tbCharacter) and IsActiveWeaponItem(WeaponItem) then
        OnCpgbLoadAnimationFinished(self)
    end
end

local function OnShipWeaponBulletLoadBegan(self, tbCharacter, WeaponItem, nLoadingTime, nLoadingStartTime)
    if GamePlayerSelfHelper:IsPlayerSelf(tbCharacter) and IsActiveWeaponItem(WeaponItem) then
        OnCpgbLoadAnimationStart(self, nLoadingTime, nLoadingStartTime)
    end
end

local function OnShipActiveWeaponItemChanged(self, tbCharacter, NewActiveWeaponItem, OldActiveWeaponItem)
    if GamePlayerSelfHelper:IsNotPlayerSelf(tbCharacter) then
        return
    end
    if NewActiveWeaponItem and (NewActiveWeaponItem:GetCategory() == BattleItemCategoryDef.SHIP_WEAPON) then
        self:UpdateCrosshairsImageRes(NewActiveWeaponItem:GetSubCategory())

        if NewActiveWeaponItem:IsInBulletLoading() then
            local nLoadingTime = NewActiveWeaponItem:GetBulletLoadingTime()
            local nLoadingStartTime = NewActiveWeaponItem:GetBulletLoadingStartTime()
            OnCpgbLoadAnimationStart(self, nLoadingTime, nLoadingStartTime)
        else
            OnCpgbLoadAnimationFinished(self)
        end
    else
        OnCpgbLoadAnimationFinished(self)
    end
end

function UPShipWeaponCannon:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_ACTIVE_WEAPON_ITEM_CHANGED     , self, OnShipActiveWeaponItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_BEGAN_CLIENT, self, OnShipWeaponBulletLoadBegan)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_ENDED_CLIENT, self, OnShipWeaponBulletLoadEnded)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.cpgbReload.OnAnimationFinished     , self, OnCpgbLoadAnimationFinished)
end

function UPShipWeaponCannon:OnShow()
    local tbPlayer = GamePlayerSelfHelper:Get()
    local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem_C()
    OnShipActiveWeaponItemChanged(self, tbPlayer, ActiveWeaponItem)
end

function UPShipWeaponCannon:SetVisible(bVisible)
    self.pWidgetRef:SetVisibility(bVisible and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
end

function UPShipWeaponCannon:UpdateCrosshairsImageRes(nSubCategory)
    local szCrosshairsPath = ShipWeaponCategoryDataTable:GetCrosshairsRes(nSubCategory)
    if szCrosshairsPath then
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgCrosshairs, szCrosshairsPath:load(), true)
        self.pWidgetRef.ovlCrosshairs:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.pWidgetRef.ovlCrosshairs:SetVisibility(ESlateVisibility.Collapsed)
    end
end

return UPShipWeaponCannon