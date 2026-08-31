-----------------------------------------------------
--File Name    : UPBuildItemTipsNew.lua
--Author       : chenyixin
--Description  : 建造舰船武器tips
-----------------------------------------------------
local luaclass = require("luaclass")
local UPBuilItemTipsBase = require("UPBuilItemTipsBase")
local UPBuildItemTipsNew = luaclass("UPBuildItemTipsNew", UPBuilItemTipsBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")

local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipWeaponCharacteristicDataTable = require("ShipWeaponCharacteristicDataTable")
local BuildShipWeaponTipsContentHelper = require("BuildShipWeaponTipsContentHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local BuildHumanWeaponTipsContentHelper = require("BuildHumanWeaponTipsContentHelper")
local BuildHumanArmorTipsContentHelper  = require("BuildHumanArmorTipsContentHelper")

local MAX_CHARACTERISTIC_COUNT = 4

UPBuildItemTipsNew.ListHelper = nil
UPBuildItemTipsNew.tbCharacteristicItems = {}
UPBuildItemTipsNew.tbMaterialItems = {}
UPBuildItemTipsNew.pbBuildingCostMaterials = nil

UPBuildItemTipsNew.OnItemButtonReleasedDelegate = nil

local function GetCharacteristicInfos(tbCharacteristicIds)
    local tbCharacteristics = {}
    for i = 1, MAX_CHARACTERISTIC_COUNT do
        if not tbCharacteristicIds[i] then
            break
        end
        tbCharacteristics[i] = ShipWeaponCharacteristicDataTable:GetTemplate(tbCharacteristicIds[i])
    end
    return tbCharacteristics
end

local function GetTipsData(tbBattleItemTemplate)
    if tbBattleItemTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        return BuildShipWeaponTipsContentHelper.GetTipsData(tbBattleItemTemplate.nId)
    elseif tbBattleItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        return BuildHumanWeaponTipsContentHelper.GetTipsData(tbBattleItemTemplate.nId)
    elseif tbBattleItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        return BuildHumanArmorTipsContentHelper.GetTipsData(tbBattleItemTemplate.nId)
    end
end

-------------------
-- widget 设置
-------------------
local function SetCharacteristics(self, tbCharacteristics)
    for i = 1, MAX_CHARACTERISTIC_COUNT do
        local tbCharacteristicItem = self.tbCharacteristicItems[i]
        if tbCharacteristics[i] then
            tbCharacteristicItem:SetVisibility(ESlateVisibility.Visible)
            tbCharacteristicItem:SetText(tbCharacteristics[i].l10nName)
        else
            tbCharacteristicItem:SetVisibility(ESlateVisibility.Hidden)
        end
    end
end

-------------------
-- LifeCycle
-------------------
function UPBuildItemTipsNew:OnLoad()
    self.super.OnLoad(self)
    local pWidgetRef = self.pWidgetRef

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.KMVerticalList_0)

    for i = 1, MAX_CHARACTERISTIC_COUNT do
        local tbCharacteristicItem = self.PrefabHelper:BindPrefab(pWidgetRef["pbCharacteristic" .. i], "UP_LobbyShipWeaponCharacteristicItem")
        tbCharacteristicItem:SetColorByIndex(i)
        self.tbCharacteristicItems[i] = tbCharacteristicItem
    end
    -- 绑定建造消耗材料相关控件
    self:BindPbBuildingCostMaterials(pWidgetRef.pbBuildingCostMaterials, pWidgetRef.hboxCost)
end

function UPBuildItemTipsNew:OnUnload()
    self.super.OnUnload(self)
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UPBuildItemTipsNew:OnBindEvent(EventHelper)
    self.super.OnBindEvent(self, EventHelper)
    local pWidgetRef = self.pWidgetRef

    -- 绑定控件
    self:BindTxtCurrent(pWidgetRef.kmtxtCurrent)
    self:BindKeyItem(pWidgetRef.kmButtonKeyItem, pWidgetRef.imgBuildKeyItem, pWidgetRef.txtBuildKeyItemCostCount)
    self:BindBuildAndReserve(pWidgetRef.kmbtnBuild, pWidgetRef.kmbtnReserve, pWidgetRef.txtReserve)
end

-------------------
-- override
-------------------
function UPBuildItemTipsNew:GetCurrentItemTemplateId()
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nEquippedTemplateId = CheckCanBuildItemHelper.GetSameSlotEquippedItemTemplateId(nCharacterInstanceId, self.nChoosenItemTemplateId, self.nSlotIndex, true)
    return nEquippedTemplateId
end

function UPBuildItemTipsNew:Refresh(nChoosenItemTemplateId, bNotShowPrice, nSlotIndex)
    self.super.Refresh(self, nChoosenItemTemplateId, bNotShowPrice, nSlotIndex)

    local pWidgetRef = self.pWidgetRef

    local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(nChoosenItemTemplateId) 
    local tbTipsData = GetTipsData(tbBattleItemTemplate)

    -- 名字
    pWidgetRef.ktxtTitle:SetText(tbTipsData.szTitle)

    -- 特点
    local tbCharacteristics = GetCharacteristicInfos(tbTipsData.tbCharacteristics)
    SetCharacteristics(self, tbCharacteristics)

    -- 属性列表
    local tbProperties = tbTipsData.tbDatas
    local tbItemData = {}
    for _, tbProperty in pairs(tbProperties) do
        local tbPropertyData = {
            l10nPropName = tbProperty.szTitle, 
            l10nPropValue = tbProperty.szDesc
        }
        table.insert(tbItemData, tbPropertyData)
    end
    self.ListHelper:SetData(tbItemData)
end

return  UPBuildItemTipsNew