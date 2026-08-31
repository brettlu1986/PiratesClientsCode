-----------------------------------------------------
--File Name    : ULMaterialPackage.lua
--Author       : zhiyuan
--Create Time  : 2019-03-28
--Description  : 材料背包的UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULMaterialPackage = luaclass("ULMaterialPackage", UILogicBase)
local UITextDef = require("UITextDef")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIDef = require("UIDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemRoomDef = require("BattleItemRoomDef")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

ULMaterialPackage.ListHelper = nil
ULMaterialPackage.bEnable = false

local function fnSort(tbItem1, tbItem2)
    return tbItem1:GetTemplateId() < tbItem2:GetTemplateId()
end

local function RefreshList(self)
    self.Owner.pbItemDetail:HideDetail()
    local tbItems = BattleItemSystemClient:GetUnEquippedItems(BattleItemRoomDef.MATERIAL_ROOM)
    table.sort(tbItems, fnSort)
    local tbListDatas = {}
    local nUsedWeight = 0
    for _, tbItem in ipairs(tbItems) do
        local tbData = {}
        tbData.tbItem = tbItem
        tbData.pbDetail = self.Owner.pbItemDetail
        tbData.pbDiscardPart = self.Owner.pbDiscardPart
        table.insert(tbListDatas, tbData)
        nUsedWeight = nUsedWeight + tbItem:GetWeight()
    end
    self.ListHelper:SetData(tbListDatas)
    self.ListHelper:UnselectCurrentItem()

    local nCapacity = BattleItemSystemClient:GetInventoryCapacity(BattleItemRoomDef.MATERIAL_ROOM)
    local szPackageState = string.format("%s/%s", tostring(math.ceil(nUsedWeight)), tostring(nCapacity))
    self.pWidgetRef.txtPackageSize:SetText(szPackageState)
end

local function RefreshCheckBox(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.chEquipRoom:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.txtEquipRoom:SetText(UITextDef.UI_STATIC_FFA_BACKPACK_MATERIAL)
    -- pWidgetRef.chClothRoom:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnShipBuildGradeChanged(self, tbPlayer, _)
    if GamePlayerSelfHelper:GetServerInstanceId() == tbPlayer:GetServerInstanceId() then
        RefreshList(self)
    end
end

local function RegisterEvent(self)
    if self.bEnable and not self.bLazyEventBinded then
        self.EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_BUILD_GRADE_CHANGED_CLIENT, self, OnShipBuildGradeChanged)
        self.bLazyEventBinded = true
    end
end

local function UnregisterEvent(self)
    self.EventHelper:UnregisterAll()
    self.bLazyEventBinded = false
end

function ULMaterialPackage:OnItemAdd()
    RefreshList(self)
end

function ULMaterialPackage:OnItemRemove()
    RefreshList(self)
end

function ULMaterialPackage:OnItemPosChanged()
    RefreshList(self)
end

function ULMaterialPackage:OnItemStackCountChanged(nItemInstanceId, nStackCount)
    RefreshList(self)
end

function ULMaterialPackage:OnLoad()
    --logdebug("ULMaterialPackage:OnLoad1")
    -- self.ListHelper = SelfVerticalListHelper()
    -- self.ListHelper:Init(self, self.pWidgetRef.listItems2, {}, UIDef.UP_MATERIAL_ITEM_IN_PACKAGE_LIST)
    -- self.ListHelper:SetAutoScrollEnabled(false)
    --logdebug("ULMaterialPackage:OnLoad2")
end

function ULMaterialPackage:OnDestroy()
    if self.ListHelper then
        self.ListHelper:Uninit()
    end
end

function ULMaterialPackage:OnExit()
    self.bLazyEventBinded = false
end

-- function ULMaterialPackage:OnBindEvent(EventHelper)
--     EventHelper:RegisterEvent(ClientEventDef.EV_SHIP_BUILD_GRADE_CHANGED_CLIENT, self, OnShipBuildGradeChanged)
-- end

local function SetContentEnable(self, bEnable)
    if self.ListHelper then
        --self.ListHelper:SetData()
        self.ListHelper:SetEnable(bEnable)
    end
    if bEnable then
        RegisterEvent(self)
    else
        UnregisterEvent(self)
    end
end

function ULMaterialPackage:SetEnable(bEnable)
    self.bEnable = bEnable
    --logdebug("ULMaterialPackage:SetEnable",bEnable)
    SetContentEnable(self, bEnable)
    if self.bEnable == false then
        return
    end
    self.pWidgetRef.vbxWeapon:SetVisibility(ESlateVisibility_Collapsed)
    self.pWidgetRef.humanSideList:SetVisibility(ESlateVisibility_Collapsed)
    if not self.ListHelper then
        self.ListHelper = SelfVerticalListHelper()
        self.ListHelper:Init(self, self.pWidgetRef.listItems2, {}, UIDef.UP_MATERIAL_ITEM_IN_PACKAGE_LIST)
        self.ListHelper:SetAutoScrollEnabled(false)
    end
    --self.ListHelper:SetEnable(bEnable)
    RefreshCheckBox(self)
    RefreshList(self)
    --logdebug("ULMaterialPackage:SetEnable end")
end

return ULMaterialPackage