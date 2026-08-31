-----------------------------------------------------
--File Name    : UPBuildingMaterials.lua
--Author       : zhiyuan
--Create Time  : 2018-09-29
--Description  : 当前拥有的建造材料的up
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPBuildingMaterials = luaclass("UPBuildingMaterials", PrefabBase)
local UIDef = require("UIDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemRoomDef = require("BattleItemRoomDef")
local MaterialItemHelper = require("MaterialItemHelper")
local ClientEventDef = require("ClientEventDef")
local FFAItemIni = require("FFAItemIni")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")

UPBuildingMaterials.tbPbMaterials = nil

local function GetItemCount(tbItems, nIndex)
    if not tbItems then
        return 0
    end
    local nTemplateId = MaterialItemHelper:GetMaterialTemplateId(nIndex)
    for _, v in pairs(tbItems) do
        if v:GetTemplateId() == nTemplateId then
            return v:GetStackCount()
        end
    end
    return 0
end

local function RefreshAllCount(self)
    local tbItems = BattleItemSystemClient:GetUnEquippedItems(BattleItemRoomDef.MATERIAL_ROOM)

    for i, v in ipairs(self.tbPbMaterials) do
        local nItemCount = GetItemCount(tbItems, i)
        v:Refresh(i, nItemCount)
    end
end

function UPBuildingMaterials:OnLoad()
    local pWidgetRef =self.pWidgetRef
    self.tbPbMaterials = {}
    local tbPbMaterials = self.tbPbMaterials
    for i = 1, FFAItemIni.tbMaterial.nMaxMaterialType do
        local pbMaterial = self.PrefabHelper:BindPrefab(pWidgetRef["pbBuildMaterial0"..i], UIDef.UP_BUILDING_MATERIAL)
        tbPbMaterials[i] = pbMaterial
    end
end

function UPBuildingMaterials:OnShow()
    self:Refresh()
end

local function RefreshItemCount(self, tbTemplate)
    local nIndex = tbTemplate.nIndex
    local nCount = BattleItemSystemClient:GetItemCount(tbTemplate.nId)
    self.tbPbMaterials[nIndex]:RefreshCount(nCount)
end

local function OnItemAdd(self, NewItem)
    if NewItem:GetCategory() ~= BattleItemCategoryDef.MATERIAL then
        return
    end
    local tbTemplate = NewItem:GetTemplate()
    RefreshItemCount(self, tbTemplate)
end

local function OnItemRemove(self, _, nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbTemplate.nCategory ~= BattleItemCategoryDef.MATERIAL then
        return
    end
    RefreshItemCount(self, tbTemplate)
end

local function OnItemChangeStackCount(self, Item)
    if Item:GetCategory() ~= BattleItemCategoryDef.MATERIAL then
        return
    end
    local tbTemplate = Item:GetTemplate()
    RefreshItemCount(self, tbTemplate)
end

local function OnResetAllItem(self)
    RefreshAllCount(self)
end

function UPBuildingMaterials:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT                , self, OnItemAdd)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT             , self, OnItemRemove)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT  , self, OnItemChangeStackCount)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RESET_BATTLE_ITEM                  , self, OnResetAllItem)
end

function UPBuildingMaterials:Refresh()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)

    RefreshAllCount(self)
end

return UPBuildingMaterials
