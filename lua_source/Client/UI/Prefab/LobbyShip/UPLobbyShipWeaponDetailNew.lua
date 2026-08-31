-----------------------------------------------------
--File Name    : UPLobbyShipWeaponDetail.lua
--Author       : chenyixin
--Description  : 舰船武器界面详情UP
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipWeaponDetail = luaclass("UPLobbyShipWeaponDetail", PrefabBase)

local SelfVerticalListHelper = require("SelfVerticalListHelper")
local BuildShipWeaponTipsContentHelper = require("BuildShipWeaponTipsContentHelper")
-- local UISetUtils = require("UISetUtils")
-- local UIResourceDef = require("UIResourceDef")
local ShipWeaponCharacteristicDataTable = require("ShipWeaponCharacteristicDataTable")

local MAX_CHARACTERISTIC_COUNT = 4

UPLobbyShipWeaponDetail.OwnerSub = nil
UPLobbyShipWeaponDetail.ListHelper = nil
UPLobbyShipWeaponDetail.tbCharacteristicItems = {}
UPLobbyShipWeaponDetail.fnOnUpdateWeaponDisplay = nil

UPLobbyShipWeaponDetail.tbTemplate = nil

local function GetWeaponProperties(nBattleItemId)
    local tbTipsData = BuildShipWeaponTipsContentHelper.GetTipsData(nBattleItemId)
    return tbTipsData.tbDatas, tbTipsData.tbCharacteristics
end

-------------------------------- widget设置 -------------------------------------

local function SetCharacteristics(self, tbCharacteristics)
    for i = 1, MAX_CHARACTERISTIC_COUNT do
        local tbCharacteristicItem = self.tbCharacteristicItems[i]
        if tbCharacteristics[i] then
            tbCharacteristicItem:SetVisibility(ESlateVisibility.Visible)
            tbCharacteristicItem:SetText(tbCharacteristics[i].l10nName)
            tbCharacteristicItem:SetColorByName(tbCharacteristics[i].szColor)
        else
            tbCharacteristicItem:SetVisibility(ESlateVisibility.Hidden)
        end
    end
end

------------------------------ 事件们 --------------------------------------------


---------------------------- override -----------------------------------------

function UPLobbyShipWeaponDetail:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
    local pWidgetRef = self.pWidgetRef

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.KMVerticalList_0)

    for i = 1, MAX_CHARACTERISTIC_COUNT do
        local tbCharacteristicItem = self.PrefabHelper:BindPrefab(pWidgetRef["pbCharacteristic" .. i])
        -- tbCharacteristicItem:SetColorByIndex(i)
        self.tbCharacteristicItems[i] = tbCharacteristicItem
    end
end

function UPLobbyShipWeaponDetail:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UPLobbyShipWeaponDetail:OnBindEvent(EventHelper)
    -- local pWidgetRef = self.pWidgetRef
end

---------------------- 接口 -----------------------------------------------------

function UPLobbyShipWeaponDetail:SetData(tbData)
    local tbTemplate = tbData.tbTemplate
    -- local bUnlocked = tbData.bUnlocked

    if not tbTemplate then
        log("[LobbyShip] UPLobbyShipWeaponDetail:SetData, weapon tbTemplate is nil.")
        return
    end

    self.pWidgetRef.ktxtTitle:SetText(tbTemplate.l10nName)
    
    local tbProperties, tbCharacteristicIds = GetWeaponProperties(tbTemplate.nBattleItemId)
    local tbItemData = {}
    for _, tbProperty in pairs(tbProperties) do
        local tbPropertyData = {
            l10nPropName = tbProperty.szTitle, 
            l10nPropValue = tbProperty.szDesc
        }
        table.insert(tbItemData, tbPropertyData)
    end
    self.ListHelper:SetData(tbItemData) 

    local tbCharacteristics = {}
    for i = 1, MAX_CHARACTERISTIC_COUNT do
        if not tbCharacteristicIds[i] then
            break
        end
        tbCharacteristics[i] = ShipWeaponCharacteristicDataTable:GetTemplate(tbCharacteristicIds[i])
    end
    SetCharacteristics(self, tbCharacteristics)

    -- local pVisibility = bUnlocked and ESlateVisibility.Collapsed or ESlateVisibility.Visible
    -- self.pWidgetRef.imgLocked:SetVisibility(pVisibility)

    self.tbTemplate = tbTemplate
end

function UPLobbyShipWeaponDetail:BindOnUpdateWeaponDisplay(fnOnUpdateWeaponDisplay)
    self.fnOnUpdateWeaponDisplay = fnOnUpdateWeaponDisplay
end

function UPLobbyShipWeaponDetail:GetDisplayWeaponId()
    return self.tbTemplate.nId
end

function UPLobbyShipWeaponDetail:GetWeaponTemplate()
    return self.tbTemplate
end

return  UPLobbyShipWeaponDetail