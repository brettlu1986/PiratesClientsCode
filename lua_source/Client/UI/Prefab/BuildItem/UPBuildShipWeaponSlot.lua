local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPShipWeaponSlot = luaclass("UPShipWeaponSlot", PrefabBase)
local BattleItemDataTable = require("BattleItemDataTable")
local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local UIResourceDef = require("UIResourceDef")
local UITextDef = require("UITextDef")
local ClientEventDef = require("ClientEventDef")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPShipWeaponSlot.nChoosenItemTemplateId = nil
UPShipWeaponSlot.nSlotIndex = nil
UPShipWeaponSlot.OnShipWeaponSlotPressedDelegate = nil
UPShipWeaponSlot.OnShipWeaponSlotRefreshDelegate = nil

local ANIM_NAME = "animCanBuild"

local function PlayCanBuildPromptAnim(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgCanBuild:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if not self.bIsPlayingCanBuildAnim then
        self.bIsPlayingCanBuildAnim = true
        self:PlayAnimation(ANIM_NAME, 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
end

local function StopCanBuildPromptAnim(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgCanBuild:SetVisibility(ESlateVisibility.Collapsed)
    if self.bIsPlayingCanBuildAnim then
        self.bIsPlayingCanBuildAnim = false
        self:StopAnimation(ANIM_NAME)
    end
end

local function ShowCanBuildPrompt(self)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    if CheckCanBuildItemHelper.CanBuildShipWeaponOnSlot(nCharacterInstanceId, self.nSlotIndex, true) then
        PlayCanBuildPromptAnim(self)
    else
        StopCanBuildPromptAnim(self)
    end
end

local function Refresh(self, EquippedItem)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

    local tbItemTemplate = EquippedItem:GetTemplate()
    local nItemTemplateId = tbItemTemplate.nId

    local tbItemResTemplate = BattleItemDataTable:GetResTemplate(nItemTemplateId)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, szIconPath:load(), true)

    pWidgetRef.imgColour:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

    pWidgetRef.txtName:SetVisibility(ESlateVisibility.Collapsed)
    StopCanBuildPromptAnim(self)
end

local function SetEmpty(self, EquippedItem)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local szIconPath = UIResourceDef.SHIP_WEAPON_SLOT_ICON[self.nSlotIndex]
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, szIconPath:load(), true)

    pWidgetRef.imgColour:SetVisibility(ESlateVisibility.Collapsed)

    pWidgetRef.txtName:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local l10nSlotName = UITextDef.SHIP_WEAPON_SLOT_NAME[self.nSlotIndex]
    pWidgetRef.txtName:SetText(l10nSlotName)
    ShowCanBuildPrompt(self)
end

local function IsChecked(self)
    local chkBg = self.pWidgetRef.chkBg
    return chkBg:IsChecked()
end

local function SetIsChecked(self, bChecked)
    local chkBg = self.pWidgetRef.chkBg
    if chkBg:IsChecked() ~= bChecked then
        chkBg:SetIsChecked(bChecked)
    end
end

local function OnCheckStateChanged(self, bChecked)
    SetIsChecked(self, true)
    if self.OnShipWeaponSlotPressedDelegate then
        self.OnShipWeaponSlotPressedDelegate:Fire(self.nSlotIndex)
    end
end

local function GetEquippedShipWeapon(nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    return BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, nSlotIndex)
end

local function OnItemChanged(self)
    if self.pWidgetRef:IsVisible() then
        self:Refresh(IsChecked(self))
    end
end

local function OnBuildItemFinish(self)
    if self.pWidgetRef:IsVisible() and IsChecked(self) and self.OnShipWeaponSlotRefreshDelegate then
        self.OnShipWeaponSlotRefreshDelegate:Fire(self.nSlotIndex)
    end
end

function UPShipWeaponSlot:OnLoad()

end

function UPShipWeaponSlot:SetSlotIndex(nSlotIndex)
    self.nSlotIndex = nSlotIndex
end

function UPShipWeaponSlot:SetOnShipWeaponSlotPressedDelegate(OnShipWeaponSlotPressedDelegate)
    self.OnShipWeaponSlotPressedDelegate = OnShipWeaponSlotPressedDelegate
end

function UPShipWeaponSlot:SetOnShipWeaponSlotRefreshDelegate(OnShipWeaponSlotRefreshDelegate)
    self.OnShipWeaponSlotRefreshDelegate = OnShipWeaponSlotRefreshDelegate
end

function UPShipWeaponSlot:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.chkBg.OnCheckStateChanged, self, OnCheckStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_BUILD_FINISH_CLIENT, self, OnBuildItemFinish)
end

function UPShipWeaponSlot:Collapsed()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPShipWeaponSlot:Refresh(bSelect)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)

    local EquippedItem = GetEquippedShipWeapon(self.nSlotIndex)
    if EquippedItem then
        Refresh(self, EquippedItem)
    else
        SetEmpty(self)
    end
    SetIsChecked(self, bSelect)
end

function UPShipWeaponSlot:UnSelect()
    SetIsChecked(self, false)
end

return UPShipWeaponSlot