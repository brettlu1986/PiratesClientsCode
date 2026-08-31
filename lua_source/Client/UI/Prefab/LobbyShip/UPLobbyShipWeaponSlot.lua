-----------------------------------------------------
--File Name    : UPLobbyShipWeaponSlot.lua
--Author       : chenyixin
--Description  : 舰船武器界面选中位置所有武器类型UP
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipWeaponSlot = luaclass("UPLobbyShipWeaponSlot", PrefabBase)

local UIDef = require("UIDef")
local ItemDataTable = require("ItemDataTable")

local MAX_ITEM_COUNT = 4

UPLobbyShipWeaponSlot.OwnerSub = nil
UPLobbyShipWeaponSlot.tbWeaponCategoryItems = {}
UPLobbyShipWeaponSlot.nSelectedIndex = nil
UPLobbyShipWeaponSlot.tbSlotTemplates = nil

--[[
    CategoryItem记录的Data，选中Slot时更新
    tbData = {
        nCategory,      -- 武器类别
        tbAllWeapons,   -- 武器类别下所有武器
    }
]]
local function GetCategoryItemData(nCategory, tbAllWeapons, nActiveIndex)
    return {
        nCategory = nCategory,
        tbAllWeapons = tbAllWeapons,
        nActiveIndex = nActiveIndex
    }
end

-- CategoryItem的显示数据，每次更换武器更新，tbDisplayData格式见UPLobbyShipCommonItem
local function GetCategoryItemDisplayData(tbActiveWeapon, bNew)
    local tbDisplayData = {}
    local nTemplateId = tbActiveWeapon.nId
    local tbItemResTemplate = ItemDataTable:GetResTemplate(nTemplateId)
    tbDisplayData.szBtnImg = tbItemResTemplate.szIconPath
    tbDisplayData.bEnableBtn = true
    tbDisplayData.bNew = bNew
    tbDisplayData.bShowBox = true

    return tbDisplayData
end

local function GetCategoryItemWeaponInfo(self, nCategory)
    local pShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    local tbAllWeapons = pShipPreparationComponent:GetWeaponTemplatesByCategory(nCategory)

    local nActiveWeaponId = pShipPreparationComponent:GetActiveWeaponId(nCategory)
    local nActiveIndex = nil
    for nIndex, tbWeapon in pairs(tbAllWeapons) do
        if tbWeapon.nId == nActiveWeaponId then
            nActiveIndex = nIndex
        end
    end

    return GetCategoryItemData(nCategory, tbAllWeapons, nActiveIndex)
end

local function GetSelectedItem(self)
    if not self.nSelectedIndex then
        self:SetSelectedItemIndex(1)
    end

    return self.tbWeaponCategoryItems[self.nSelectedIndex]
end

-------------------------------- widget设置 -------------------------------------

local function UpdateItemDisplay(self, pbCategoryItem)
    local tbData = pbCategoryItem:GetItemData()
    if not tbData then
        pbCategoryItem:SetVisibility(ESlateVisibility.Hidden)
        return
    else
        pbCategoryItem:SetVisibility(ESlateVisibility.Visible)
    end

    local tbItemData = pbCategoryItem:GetItemData()
    local tbAllWeapons = tbItemData.tbAllWeapons
    local bNew = false
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    for _, tbWeapon in pairs(tbAllWeapons) do
        if ShipPreparationComponent:IsNewShipItem(tbWeapon.nId) then
            bNew = true
            break
        end
    end
    local nActiveIndex = tbItemData.nActiveIndex
    local tbActiveWeapon = tbAllWeapons[nActiveIndex]
    local tbDisplayData = GetCategoryItemDisplayData(tbActiveWeapon, bNew)
    pbCategoryItem:SetItemDisplayData(tbDisplayData)
end

------------------------------ 事件们 --------------------------------------------

local function OnWeaponCategoryItemSelected(self, nIndex)
    self:SetSelectedItemIndex(nIndex)
end

---------------------------- override -----------------------------------------

function UPLobbyShipWeaponSlot:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
    local pWidgetRef = self.pWidgetRef
    for i = 1, MAX_ITEM_COUNT do
        local tbWeaponItem = self.PrefabHelper:BindPrefab(pWidgetRef["UP_WeaponItem" .. i], UIDef.UP_LOBBY_SHIP_COMMON_ITEM)
        tbWeaponItem:BindOnSelected(function()
            OnWeaponCategoryItemSelected(self, i)
        end)
        self.tbWeaponCategoryItems[i] = tbWeaponItem
    end
end

function UPLobbyShipWeaponSlot:OnShow()
end

function UPLobbyShipWeaponSlot:OnBindEvent(EventHelper)
    -- local pWidgetRef = self.pWidgetRef
end

---------------------- 接口 -----------------------------------------------------

function UPLobbyShipWeaponSlot:SetData(tbSlotTemplates)
    self.tbSlotTemplates = tbSlotTemplates

    for i = 1, MAX_ITEM_COUNT do
        local pbWeaponCategoryItem = self.tbWeaponCategoryItems[i]
        local tbData = nil
        if tbSlotTemplates[i] then
            local nCategory = tbSlotTemplates[i].nCategory
            tbData = GetCategoryItemWeaponInfo(self, nCategory)
        end
        pbWeaponCategoryItem:SetItemData(tbData)
    end
end

function UPLobbyShipWeaponSlot:SetSelectedItemIndex(nIndex)
    local pbWeaponCategoryItem = nil
    
    if self.nSelectedIndex then
        pbWeaponCategoryItem = self.tbWeaponCategoryItems[self.nSelectedIndex]
        if pbWeaponCategoryItem then
            pbWeaponCategoryItem:SetSelected(false)
        end
    end
    
    self.nSelectedIndex = nIndex
    pbWeaponCategoryItem = self.tbWeaponCategoryItems[nIndex]
    if pbWeaponCategoryItem then
        pbWeaponCategoryItem:SetSelected(true)
    end

    if self.fnOnWeaponCategoryItemSelected then
        self.fnOnWeaponCategoryItemSelected(self)
    end
end

function UPLobbyShipWeaponSlot:GetSelectedItemIndex()
    if not self.nSelectedIndex then
        self:SetSelectedItemIndex(1)
    end
    return self.nSelectedIndex
end

function UPLobbyShipWeaponSlot:GetPreviousItemIndex()
    local nCurrentIndex = self:GetSelectedItemIndex()
    local nIndex = nCurrentIndex - 1
    if nIndex < 1 then
        nIndex = 1
    end
    return nIndex
end

function UPLobbyShipWeaponSlot:GetNextItemIndex()
    local nCurrentIndex = self:GetSelectedItemIndex()
    local nIndex = nCurrentIndex + 1
    local nMaxIndex = self:GetMaxItemIndex()
    if nIndex > nMaxIndex then
        nIndex = nMaxIndex
    end
    return nIndex
end

function UPLobbyShipWeaponSlot:GetMaxItemIndex()
    return #self.tbSlotTemplates
end

-- 更新选中Item
function UPLobbyShipWeaponSlot:UpdateSelectedItem()
    local pbCategoryItem = GetSelectedItem(self)
    if not pbCategoryItem then
        logerror("[LobbyShip] UPLobbyShipWeaponSlot:UpdateSelectedItem, cannot find selected item, nIndex =", self.nSelectedIndex)
        return
    end
    local nCategory = pbCategoryItem:GetItemData().nCategory
    local tbData = GetCategoryItemWeaponInfo(self, nCategory)
    pbCategoryItem:SetItemData(tbData)
    
    UpdateItemDisplay(self, pbCategoryItem)
end

-- 更新所有Item显示
function UPLobbyShipWeaponSlot:UpdateItemsDisplay()
    for i = 1, MAX_ITEM_COUNT do
        local pbWeaponCategoryItem = self.tbWeaponCategoryItems[i]
        UpdateItemDisplay(self, pbWeaponCategoryItem)
    end
end

-- 武器启用时
function UPLobbyShipWeaponSlot:OnWeaponItemActive()
    self:UpdateSelectedItem()
    local pbCategoryItem = GetSelectedItem(self)
    pbCategoryItem:PlayAnimActive()
end

-- 返回当前选中武器类型
function UPLobbyShipWeaponSlot:GetCurrentSelectedCategory()
    if not self.nSelectedIndex then
        self:SetSelectedItemIndex(1)
    end

    local pbWeaponCategoryItem = self.tbWeaponCategoryItems[self.nSelectedIndex]
    return pbWeaponCategoryItem:GetItemData().nCategory
end

-- 返回当前选中武器类型的所有武器
function UPLobbyShipWeaponSlot:GetAllSelectedCategoryWeapon()
    if not self.nSelectedIndex then
        self:SetSelectedItemIndex(1)
    end

    local pbWeaponCategoryItem = self.tbWeaponCategoryItems[self.nSelectedIndex]
    return pbWeaponCategoryItem:GetItemData().tbAllWeapons
end

-- 返回当前选中武器类型的启用武器和武器Index
function UPLobbyShipWeaponSlot:GetSelectedCategoryActiveWeapon()
    if not self.nSelectedIndex then
        self:SetSelectedItemIndex(1)
    end
    local pbWeaponCategoryItem = self.tbWeaponCategoryItems[self.nSelectedIndex]
    local tbItemData = pbWeaponCategoryItem:GetItemData()
    local nIndex = tbItemData.nActiveIndex
    local tbWeapon = tbItemData.tbAllWeapons[nIndex]
    return tbWeapon, nIndex
end

function UPLobbyShipWeaponSlot:BindOnWeaponCategoryItemSelected(fnOnWeaponCategoryItemSelected)
    self.fnOnWeaponCategoryItemSelected = fnOnWeaponCategoryItemSelected
end

return  UPLobbyShipWeaponSlot