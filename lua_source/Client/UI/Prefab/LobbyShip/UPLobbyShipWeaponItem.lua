-----------------------------------------------------
--File Name    : UPLobbyShipWeaponItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-23
--Description  : 船战备舰船武器分页每行中具体武器Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipWeaponItem = luaclass("UPLobbyShipWeaponItem", PrefabBase)

local UISetUtils = require("UISetUtils")
local BattleItemDataTable = require("BattleItemDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

UPLobbyShipWeaponItem.tbTemplate = nil

local function GetPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function OnClickedBtnItem(self, bClicked)
    if self.fnOnClickedItemCallback then
        self.fnOnClickedItemCallback(bClicked ~= false)
    end
end

function UPLobbyShipWeaponItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClickedBtnItem)
end

function UPLobbyShipWeaponItem:SetWeaponTemplate(tbTemplate)
    self.tbTemplate = tbTemplate
    self.pWidgetRef.txtName:SetText(tbTemplate.l10nName)

    local nBattleItemId = tbTemplate.nBattleItemId
    local tbBattleResTemplate = BattleItemDataTable:GetResTemplate(nBattleItemId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgWeapon, tbBattleResTemplate.szEquipmentDisplayPath:load())

    local nWeaponId = tbTemplate.nId
    local nActiveWeaponId = GetPreparationComponent():GetActiveWeaponId(tbTemplate.nSubCategory)
    self.pWidgetRef.bdrActive:SetVisibility((nActiveWeaponId == nWeaponId) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)

    local bUnlocked = GetPreparationComponent():IsItemUnlocked(nWeaponId)
    self.pWidgetRef.bdrLocked:SetVisibility((not bUnlocked) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
end

function UPLobbyShipWeaponItem:GetWeaponTemplate()
    return self.tbTemplate
end

function UPLobbyShipWeaponItem:GetWeaponId()
    return self.tbTemplate and self.tbTemplate.nId
end

function UPLobbyShipWeaponItem:SetOnClickedItemCallback(fnOnClickedItemCallback)
    self.fnOnClickedItemCallback = fnOnClickedItemCallback
end

function UPLobbyShipWeaponItem:SelectItem()
    self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.HitTestInvisible)
end

function UPLobbyShipWeaponItem:UnselectItem()
    self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Collapsed)
end

function UPLobbyShipWeaponItem:TriggerSelectItem()
    OnClickedBtnItem(self, false)
end

function UPLobbyShipWeaponItem:Activate()
    self:PlayAnimationWithUserWidget(self.pWidgetRef.pbFx, "animActiveFx", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

return UPLobbyShipWeaponItem