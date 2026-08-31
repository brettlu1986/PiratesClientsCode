-----------------------------------------------------
--File Name    : UPHomeShipWeaponItem.lua
--Author       : zhiyuan
--Create Time  : 2019-05-25
--Description  : 武器研发每行中具体武器Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPHomeShipWeaponItem = luaclass("UPHomeShipWeaponItem", PrefabBase)

local UISetUtils = require("UISetUtils")
local BattleItemDataTable = require("BattleItemDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ItemResearchDataTable = require("ItemResearchDataTable")
local HomelandSystem = require("HomelandSystem")
local ClientEventDef = require("ClientEventDef")

UPHomeShipWeaponItem.tbTemplate = nil

local function GetPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function Refresh(self)
    local tbTemplate = self.tbTemplate
    self.pWidgetRef.txtName:SetText(tbTemplate.l10nName)

    local nTemplateId = tbTemplate.nId
    local nBattleItemId = tbTemplate.nBattleItemId
    local tbBattleResTemplate = BattleItemDataTable:GetResTemplate(nBattleItemId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgWeapon, tbBattleResTemplate.szEquipmentDisplayPath:load())

    local nWeaponId = tbTemplate.nId
    -- 家园里不显示激活
    self.pWidgetRef.bdrActive:SetVisibility(ESlateVisibility.Collapsed)

    local bUnlocked = GetPreparationComponent():IsItemUnlocked(nWeaponId)
    if bUnlocked then
        self.pWidgetRef.bdrLocked:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.pWidgetRef.bdrLocked:SetVisibility(ESlateVisibility.HitTestInvisible)
        local tbItemResearchTemplate = ItemResearchDataTable:GetTemplate(nTemplateId)
        local nUnlockLandmarkType = tbItemResearchTemplate.nUnlockLandmarkType
        local nUnlockLandmarkGrade = tbItemResearchTemplate.nUnlockLandmarkGrade
        local nCurrentGrade = HomelandSystem:GetLandmarkGrade(nUnlockLandmarkType)
        if nCurrentGrade < nUnlockLandmarkGrade then
            self.pWidgetRef.imgLocked:SetVisibility(ESlateVisibility.HitTestInvisible)
        else
            self.pWidgetRef.imgLocked:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

local function OnClickedBtnItem(self, bClicked)
    if self.fnOnClickedItemCallback then
        self.fnOnClickedItemCallback(bClicked ~= false)
    end
end

local function OnHomeItemResearchComplete(self, nTemplateId)
    if self.tbTemplate.nId == nTemplateId then
        Refresh(self)
    end
end

function UPHomeShipWeaponItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClickedBtnItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOME_ITEM_RESEARCH_COMPLETE, self, OnHomeItemResearchComplete)
end

function UPHomeShipWeaponItem:SetWeaponTemplate(tbTemplate)
    self.tbTemplate = tbTemplate
    Refresh(self)
end

function UPHomeShipWeaponItem:GetWeaponTemplate()
    return self.tbTemplate
end

function UPHomeShipWeaponItem:GetWeaponId()
    return self.tbTemplate and self.tbTemplate.nId
end

function UPHomeShipWeaponItem:SetOnClickedItemCallback(fnOnClickedItemCallback)
    self.fnOnClickedItemCallback = fnOnClickedItemCallback
end

function UPHomeShipWeaponItem:SelectItem()
    self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.HitTestInvisible)
end

function UPHomeShipWeaponItem:UnselectItem()
    self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Collapsed)
end

function UPHomeShipWeaponItem:TriggerSelectItem()
    OnClickedBtnItem(self, false)
end

function UPHomeShipWeaponItem:Activate()
    self:PlayAnimationWithUserWidget(self.pWidgetRef.pbFx, "animActiveFx", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPHomeShipWeaponItem:SetSelectItem()
    OnClickedBtnItem(self, true)
end

return UPHomeShipWeaponItem