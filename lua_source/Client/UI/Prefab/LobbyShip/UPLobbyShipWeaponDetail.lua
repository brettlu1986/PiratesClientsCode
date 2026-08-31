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
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ShipWeaponCharacteristicDataTable = require("ShipWeaponCharacteristicDataTable")

local MAX_CHARACTERISTIC_COUNT = 4
local MAX_INDEX = 3
local HIDE_INDEX = -1

local INDEX_MARK_RES = UIResourceDef.LOBBY_COMMON.TIPS

UPLobbyShipWeaponDetail.OwnerSub = nil
UPLobbyShipWeaponDetail.ListHelper = nil
UPLobbyShipWeaponDetail.tbCharacteristicItems = {}
UPLobbyShipWeaponDetail.tbIndexMarks = {}
UPLobbyShipWeaponDetail.fnOnUpdateWeaponDisplay = nil

UPLobbyShipWeaponDetail.tbTemplate = nil
UPLobbyShipWeaponDetail.nActiveIndex = 1
UPLobbyShipWeaponDetail.nMaxIndex = MAX_INDEX

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
        else
            tbCharacteristicItem:SetVisibility(ESlateVisibility.Hidden)
        end
    end
end

local function SetActiveIndex(self, nActiveIndex, nWeaponCount)
    if nActiveIndex == HIDE_INDEX or nWeaponCount == HIDE_INDEX then
        self.pWidgetRef.hBoxIndex:SetVisibility(ESlateVisibility.Hidden)
    end
    if not nWeaponCount then
        nWeaponCount = MAX_INDEX
    end
    for i = 1, MAX_INDEX do
        local pImgIndex = self.tbIndexMarks[i]
        if i > nWeaponCount then
            pImgIndex:SetVisibility(ESlateVisibility.Collapsed)
        else
            pImgIndex:SetVisibility(ESlateVisibility.Visible)
            local szImg = i == nActiveIndex and INDEX_MARK_RES.Pressed or INDEX_MARK_RES.Normal
            UISetUtils.SetImageBrushRes(pImgIndex, szImg:load())
        end
    end
    self.nActiveIndex = nActiveIndex
end

------------------------------ 事件们 --------------------------------------------

local function OnBtnSwitchClicked(self)
    if self.fnOnUpdateWeaponDisplay then
        self.fnOnUpdateWeaponDisplay(self)
    end
end

---------------------------- override -----------------------------------------

function UPLobbyShipWeaponDetail:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
    local pWidgetRef = self.pWidgetRef

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.KMVerticalList_0)

    for i = 1, MAX_CHARACTERISTIC_COUNT do
        local tbCharacteristicItem = self.PrefabHelper:BindPrefab(pWidgetRef["pbCharacteristic" .. i])
        tbCharacteristicItem:SetColorByIndex(i)
        self.tbCharacteristicItems[i] = tbCharacteristicItem
    end

    for i = 1, MAX_INDEX do
        self.tbIndexMarks[i] = pWidgetRef["imgIndex" .. i]
    end
end

function UPLobbyShipWeaponDetail:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UPLobbyShipWeaponDetail:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSwitch.OnClicked, self, OnBtnSwitchClicked)
end

---------------------- 接口 -----------------------------------------------------

function UPLobbyShipWeaponDetail:SetData(tbData)
    local tbTemplate = tbData.tbTemplate
    local nActiveIndex = tbData.nActiveIndex
    local nWeaponCount = tbData.nWeaponCount
    local bUnlocked = tbData.bUnlocked

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

    SetActiveIndex(self, nActiveIndex, nWeaponCount)

    local pVisibility = bUnlocked and ESlateVisibility.Collapsed or ESlateVisibility.Visible
    self.pWidgetRef.imgLocked:SetVisibility(pVisibility)

    self.tbTemplate = tbTemplate
    self.nActiveIndex = nActiveIndex
    self.nMaxIndex = nWeaponCount
end

function UPLobbyShipWeaponDetail:BindOnUpdateWeaponDisplay(fnOnUpdateWeaponDisplay)
    self.fnOnUpdateWeaponDisplay = fnOnUpdateWeaponDisplay
end

function UPLobbyShipWeaponDetail:GetDisplayWeaponIndex()
    return self.nActiveIndex
end

function UPLobbyShipWeaponDetail:GetDisplayWeaponId()
    return self.tbTemplate.nId
end

function UPLobbyShipWeaponDetail:GetPreviousDisplayWeaponIndex()
    local CurrentIndex = self.nActiveIndex
    CurrentIndex = CurrentIndex - 1
    if CurrentIndex < 1 then
        CurrentIndex = self.nMaxIndex
    end
    return CurrentIndex
end

function UPLobbyShipWeaponDetail:GetNextDisplayWeaponIndex()
    local CurrentIndex = self.nActiveIndex
    CurrentIndex = CurrentIndex + 1
    if CurrentIndex > self.nMaxIndex then
        CurrentIndex = 1
    end
    return CurrentIndex
end

function UPLobbyShipWeaponDetail:GetMaxIndex()
    return self.nMaxIndex
end

function UPLobbyShipWeaponDetail:GetWeaponTemplate()
    return self.tbTemplate
end

function UPLobbyShipWeaponDetail:SetSwitchBtnVisible(bVisible)
    self.pWidgetRef.btnSwitch:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Hidden)
end

return  UPLobbyShipWeaponDetail