local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPShipPartSlot = luaclass("UPShipPartSlot", PrefabBase)
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemDataTable = require("BattleItemDataTable")
local UISetUtils = require("UISetUtils")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")

UPShipPartSlot.nChoosenItemTemplateId = nil
UPShipPartSlot.nSlotIndex = nil
UPShipPartSlot.OnPartSlotPressedDelegate = nil
UPShipPartSlot.OnPartSlotRefreshDelegate = nil
UPShipPartSlot.bIsPlayingCanBuildAnim = nil

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
    if CheckCanBuildItemHelper.CanBuildShipPartOnSlot(nCharacterInstanceId, self.nSlotIndex, true) then
        PlayCanBuildPromptAnim(self)
    else
        StopCanBuildPromptAnim(self)
    end
end

local function Refresh(self, EquippedItem)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvsDuration:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.pgbDurability:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtName:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.imgColour:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

    local tbItemTemplate = EquippedItem:GetTemplate()
    local nItemTemplateId = tbItemTemplate.nId

    local tbItemResTemplate = BattleItemDataTable:GetResTemplate(nItemTemplateId)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, szIconPath:load(), true)

    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgColour, szColorGradeImg:load())

    local nDurabilityMax = tbItemTemplate.nDurability
    local nDurability = EquippedItem:GetDurability()
    self.pWidgetRef.pgbDurability:SetPercent(1 - nDurability/nDurabilityMax)

    pWidgetRef.txtDuration:SetText(EquippedItem:GetDurabilityPercentageString())
    ShowCanBuildPrompt(self)
end

local function SetEmpty(self, EquippedItem)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvsDuration:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.pgbDurability:SetVisibility(ESlateVisibility.Collapsed)

    pWidgetRef.txtName:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local l10nCategoryName = BattleItemDataTable:GetSubCategoryName(BattleItemCategoryDef.SHIP_PART, self.nSlotIndex)
    pWidgetRef.txtName:SetText(l10nCategoryName)

    pWidgetRef.imgIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local szIconPath = UIResourceDef.SHIP_PART_SLOT_ICON[self.nSlotIndex]
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, szIconPath:load(), true)

    pWidgetRef.imgColour:SetVisibility(ESlateVisibility.Collapsed)

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
    if self.OnPartSlotPressedDelegate then
        self.OnPartSlotPressedDelegate:Fire(self.nSlotIndex)
    end
end

local function GetEquippedPart(nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    return BattleItemSystemClient:GetEquippedItem(BattleItemCategoryDef.SHIP_PART, nCharacterInstanceId, nSlotIndex)
end

local function OnItemChanged(self)
    if self.pWidgetRef:IsVisible() then
        self:Refresh(IsChecked(self))
    end
end

local function OnBuildItemFinish(self)
    if self.pWidgetRef:IsVisible() and IsChecked(self) and self.OnPartSlotRefreshDelegate then
        self.OnPartSlotRefreshDelegate:Fire(self.nSlotIndex)
    end
end

function UPShipPartSlot:OnLoad()

end

function UPShipPartSlot:SetSlotIndex(nSlotIndex)
    self.nSlotIndex = nSlotIndex
end

function UPShipPartSlot:SetOnPartSlotPressedDelegate(OnPartSlotPressedDelegate)
    self.OnPartSlotPressedDelegate = OnPartSlotPressedDelegate
end

function UPShipPartSlot:SetOnPartSlotRefreshDelegate(OnPartSlotRefreshDelegate)
    self.OnPartSlotRefreshDelegate = OnPartSlotRefreshDelegate
end

function UPShipPartSlot:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.chkBg.OnCheckStateChanged, self, OnCheckStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_BUILD_FINISH_CLIENT, self, OnBuildItemFinish)
end

function UPShipPartSlot:Collapsed()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPShipPartSlot:Refresh(bChecked)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)

    local EquippedItem = GetEquippedPart(self.nSlotIndex)
    if EquippedItem then
        Refresh(self, EquippedItem)
    else
        SetEmpty(self)
    end
    SetIsChecked(self, bChecked)
end

function UPShipPartSlot:UnSelect()
    SetIsChecked(self, false)
end

return UPShipPartSlot