-----------------------------------------------------
--File Name    : UPLobbyShipWeapon.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-23
--Description  : 船战备舰船武器页面
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipWeapon = luaclass("UPLobbyShipWeapon", PrefabBase)

local UIDef = require("UIDef")
local ItemSystem = require("ItemSystem")
local ItemDataTable = require("ItemDataTable")
local ClientEventDef = require("ClientEventDef")
local ItemCategoryDef = require("ItemCategoryDef")
local SelfTabBarHelper = require("SelfTabBarHelper")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local BattleItemDataTable = require("BattleItemDataTable")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")

UPLobbyShipWeapon.ulLobbyShipWeaponDetail = nil
UPLobbyShipWeapon.tbWeaponItemPool = nil
UPLobbyShipWeapon.TabBarHelper = nil
UPLobbyShipWeapon.ListHelper = nil
UPLobbyShipWeapon.tbSelectedWeaponIds = nil

----------------------------------------------------------------------------
-- Event Logic
----------------------------------------------------------------------------
-- 选中的武器发生变化
local function OnSelectedWeaponItemChanged(self, pbWeaponItem, bClicked)
    -- 先取消选中之前选中项
    local pbSelectedItem = self.ListHelper.tbExtraDatas.pbSelectedItem
    if pbSelectedItem then
        pbSelectedItem:UnselectItem()
    end
    -- 如果本次选择的就是之前的项则取消选中
    if bClicked and (pbWeaponItem == pbSelectedItem) then
        pbSelectedItem = nil
    else
        pbSelectedItem = pbWeaponItem
    end
    -- 选中当前项
    if pbSelectedItem then
        pbSelectedItem:SelectItem()
        self.ulLobbyShipWeaponDetail:SetWeaponTemplate(pbSelectedItem:GetWeaponTemplate())
    else
        self.ulLobbyShipWeaponDetail:SetWeaponTemplate(nil)
    end
    self.ListHelper.tbExtraDatas.pbSelectedItem = pbSelectedItem

    -- 记录当前选中的ID
    local nWeaponSlot = self.TabBarHelper:GetCurrentIdx()
    local nSelectedItemId = pbSelectedItem and pbSelectedItem:GetWeaponId()
    self.tbSelectedWeaponIds[nWeaponSlot] = nSelectedItemId
    self.ListHelper.tbExtraDatas.nSelectedItemId = nSelectedItemId
end

-- 武器位置分页变化
local function OnTabBarSelectedChanged(self, nWeaponSlot)
    -- 记录当前选中Id
    -- local nSelectedItemId = self.tbSelectedWeaponIds[nWeaponSlot]
    -- 取消选中的Item
    OnSelectedWeaponItemChanged(self, nil)
    -- 设置当前选中的Id
    -- self.ListHelper.tbExtraDatas.nSelectedItemId = nSelectedItemId
    -- 刷新列表
    self.ListHelper:SetData(self.tbTemplateData[nWeaponSlot], true)
end

-- 收到武器启用结果
local function OnReceiveActivateWeaponResult(self, nPartCategory, nTemplateId)
    local pbSelectedItem = self.ListHelper.tbExtraDatas.pbSelectedItem
    if pbSelectedItem then
        local tbTemplate = pbSelectedItem:GetWeaponTemplate()
        if tbTemplate.nSubCategory == nPartCategory then
            self.ListHelper:RefreshItemInView()
            self.ulLobbyShipWeaponDetail:RefreshActivateState()
            pbSelectedItem:Activate()
        end
    end
end

-- 新增道具
local function OnAddItem(self, Item)
    local nItemTemplateId = Item:GetTemplateId()
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    if nCategory == ItemCategoryDef.SHIP_WEAPON then
        local pbSelectedItem = self.ListHelper.tbExtraDatas.pbSelectedItem
        if pbSelectedItem then
            local tbSelectedTemplate = pbSelectedItem:GetWeaponTemplate()
            if tbSelectedTemplate.nSubCategory == tbItemTemplate.nSubCategory then
                self.ListHelper:RefreshItemInView()
                self.ulLobbyShipWeaponDetail:RefreshActivateState()
            end
        end
    end
end

-- 道具期限变化
local function OnItemChangeExpiredAt(self, nItemInstanceId, bPermanent)
    if not bPermanent then
        return
    end
    local Item = ItemSystem:GetItem(nItemInstanceId)
    OnAddItem(self, Item)
end

-- 初始化武器分类相关数据
local function InitWeaponData(self)
    local tbTemplateData = {}
    for _, tbTemplate in pairs(ShipWeaponCategoryDataTable:GetTemplates()) do
        local nWeaponSlot = tbTemplate.nWeaponSlot
        tbTemplateData[nWeaponSlot] = tbTemplateData[nWeaponSlot] or {}
        if tbTemplate.bDisplayOnLobby then
            table.insert(tbTemplateData[nWeaponSlot], tbTemplate)
        end
    end
    for i, v in ipairs(tbTemplateData) do
        table.sort(v, function(A, B) return A.nCategory < B.nCategory end)
    end
    self.tbTemplateData = tbTemplateData
end

----------------------------------------------------------------------------
-- Weapon Item Pool Logic
----------------------------------------------------------------------------
-- 分配一个武器PrefabItem
local function AllocWeaponItem(self)
    local tbWeaponItemPool = self.tbWeaponItemPool
    local nLength = #tbWeaponItemPool
    local pbWeaponItem = tbWeaponItemPool[nLength]
    if pbWeaponItem then
        table.remove(tbWeaponItemPool, nLength)
    else
        pbWeaponItem = self.PrefabHelper:CreatePrefab(UIDef.UP_LOBBY_SHIP_WEAPON_ITEM)
        pbWeaponItem:SetOnClickedItemCallback(function(bClicked) OnSelectedWeaponItemChanged(self, pbWeaponItem, bClicked) end)
    end
    return pbWeaponItem
end

-- 回收一个武器PrefabItem
local function RecycleWeaponItem(self, pbWeaponItem)
    table.insert(self.tbWeaponItemPool, pbWeaponItem)
end

----------------------------------------------------------------------------
-- Lifecyle Logic
----------------------------------------------------------------------------
function UPLobbyShipWeapon:OnLoad()
    InitWeaponData(self)

    self.ulLobbyShipWeaponDetail = self.UILogicHelper:CreateUILogic("ULLobbyShipWeaponDetail")
    self.tbWeaponItemPool = {}

    self.TabBarHelper = SelfTabBarHelper()
    self.TabBarHelper:Init(self, self.pWidgetRef.hboxTopBar)
    self.TabBarHelper.OnSelectedChangedDelegate:Bind(OnTabBarSelectedChanged, self)

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.listWeapon)
    self.ListHelper.tbExtraDatas.nSelectedItemId = nil
    self.ListHelper.tbExtraDatas.pbSelectedItem = nil
    self.ListHelper.tbExtraDatas.fnAllocWeaponItem = function()
        return AllocWeaponItem(self)
    end
    self.ListHelper.tbExtraDatas.fnRecycleWeaponItem = function(pbWeaponItem)
        return RecycleWeaponItem(self, pbWeaponItem)
    end
end

function UPLobbyShipWeapon:OnUnload()
    self.TabBarHelper:Uninit()
    self.TabBarHelper = nil

    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UPLobbyShipWeapon:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_ACTIVATE_SHIP_WEAPON_RESULT, self, OnReceiveActivateWeaponResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnAddItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_EXPIRED_AT, self, OnItemChangeExpiredAt)
end

function UPLobbyShipWeapon:Activate()
    self.tbSelectedWeaponIds = {}
    self.TabBarHelper:SelectByIndex(ShipWeaponSlotDef.HEAD, true)
end

function UPLobbyShipWeapon:SetSelectedItem(nItemTemplateId)
    local tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    if tbTemplate and (tbTemplate.nCategory == ItemCategoryDef.SHIP_WEAPON) then
        local tbBattleTemplate = BattleItemDataTable:GetTemplate(tbTemplate.nBattleItemId)
        local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(tbBattleTemplate.nSubCategory)
        self.TabBarHelper:SelectByIndex(nWeaponSlot, true)
        self.ListHelper.tbExtraDatas.nSelectedItemId = nItemTemplateId
    end
end

return UPLobbyShipWeapon