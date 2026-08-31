local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBuildShipWeaponItem = luaclass("UPBuildShipWeaponItem", PrefabBase)
local BattleItemDataTable = require("BattleItemDataTable")
local UISetUtils = require("UISetUtils")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPBuildShipWeaponItem.nItemTemplateId = nil
UPBuildShipWeaponItem.bCanBuild = nil

UPBuildShipWeaponItem.nChoosenItemSlotIndex = nil

UPBuildShipWeaponItem.OnBuildShipWeaponPressedDelegate = nil

UPBuildShipWeaponItem.bIsPlayingCanBuildAnim = nil

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

local function OnCheckStateChanged(self, bChecked)
    if self.OnBuildShipWeaponPressedDelegate then
        self.OnBuildShipWeaponPressedDelegate:Fire(self.nItemTemplateId, self.nChoosenItemSlotIndex, self.bCanBuild, bChecked)
    end
end

local function UnSelect(self)
    local chkBg = self.pWidgetRef.chkBg
    if chkBg:IsChecked() then
        chkBg:SetIsChecked(false)
    end
end

function UPBuildShipWeaponItem:IsChecked()
    local chkBg = self.pWidgetRef.chkBg
    return chkBg:IsChecked()
end

function UPBuildShipWeaponItem:OnLoad()
end

function UPBuildShipWeaponItem:SetOnBuildShipWeaponPressedDelegate(OnBuildShipWeaponPressedDelegate)
    self.OnBuildShipWeaponPressedDelegate = OnBuildShipWeaponPressedDelegate
end

function UPBuildShipWeaponItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.chkBg.OnCheckStateChanged, self, OnCheckStateChanged)
end

function UPBuildShipWeaponItem:Collapsed()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPBuildShipWeaponItem:Refresh(nItemTemplateId, nChoosenItemSlotIndex, bCanBuild)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    self.nItemTemplateId = nItemTemplateId
    self.bCanBuild = bCanBuild
    self.nChoosenItemSlotIndex = nChoosenItemSlotIndex
    UnSelect(self)

    local tbItemResTemplate = BattleItemDataTable:GetResTemplate(nItemTemplateId)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, szIconPath:load(), true)

    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

    if bCanBuild then
        PlayCanBuildPromptAnim(self)
    else
        StopCanBuildPromptAnim(self)
    end
end

function UPBuildShipWeaponItem:UnSelect()
    UnSelect(self)
end

return UPBuildShipWeaponItem