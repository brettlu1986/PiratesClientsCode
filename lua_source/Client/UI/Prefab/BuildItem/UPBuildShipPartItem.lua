local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBuildShipPartItem = luaclass("UPBuildShipPartItem", PrefabBase)
local BattleItemDataTable = require("BattleItemDataTable")
local UISetUtils = require("UISetUtils")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPBuildShipPartItem.nItemTemplateId = nil
UPBuildShipPartItem.bCanBuild = nil
UPBuildShipPartItem.bLock = nil

UPBuildShipPartItem.nChoosenItemSlotIndex = nil

UPBuildShipPartItem.OnBuildPartPressedDelegate = nil

UPBuildShipPartItem.bIsPlayingCanBuildAnim = nil

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
    if self.OnBuildPartPressedDelegate then
        self.OnBuildPartPressedDelegate:Fire(self.nItemTemplateId, self.nChoosenItemSlotIndex,  self.bCanBuild, self.bLock, bChecked)
    end
end

local function UnSelect(self)
    local chkBg = self.pWidgetRef.chkBg
    if chkBg:IsChecked() then
        chkBg:SetIsChecked(false)
    end
end

function UPBuildShipPartItem:IsChecked()
    local chkBg = self.pWidgetRef.chkBg
    return chkBg:IsChecked()
end

function UPBuildShipPartItem:OnLoad()

end

function UPBuildShipPartItem:SetOnBuildPartPressedDelegate(OnBuildPartPressedDelegate)
    self.OnBuildPartPressedDelegate = OnBuildPartPressedDelegate
end

function UPBuildShipPartItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.chkBg.OnCheckStateChanged, self, OnCheckStateChanged)
end

function UPBuildShipPartItem:Collapsed()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPBuildShipPartItem:Refresh(nItemTemplateId, nChoosenItemSlotIndex, bCanBuild, bLock)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    self.nItemTemplateId = nItemTemplateId
    self.bCanBuild = bCanBuild
    self.bLock = bLock
    self.nChoosenItemSlotIndex = nChoosenItemSlotIndex
    UnSelect(self)

    local tbItemResTemplate = BattleItemDataTable:GetResTemplate(nItemTemplateId)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, szIconPath:load(), true)

    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

    if bCanBuild then
        PlayCanBuildPromptAnim(self)
        pWidgetRef.imgLock:SetVisibility(ESlateVisibility.Collapsed)
    else
        StopCanBuildPromptAnim(self)
        if bLock then
            pWidgetRef.imgLock:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else
            pWidgetRef.imgLock:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

function UPBuildShipPartItem:UnSelect()
    UnSelect(self)
end

return UPBuildShipPartItem