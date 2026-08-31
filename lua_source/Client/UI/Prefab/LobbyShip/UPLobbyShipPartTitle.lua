-----------------------------------------------------
--File Name    : UPLobbyShipPartTitle.lua
--Author       : chenyixin
--Description  : 舰船武器界面武器名称up
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyShipPartTitle = luaclass("UPLobbyShipPartTitle", PrefabBase)

local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
-- local UITextDef = require("UITextDef")
local UIResourceDef = require("UIResourceDef")
local ItemSourceDataTable = require("ItemSourceDataTable")

UPLobbyShipPartTitle.fnOnSelected = nil
UPLobbyShipPartTitle.bSelected = false
UPLobbyShipPartTitle.tbData = nil

-- local LOBBY_COMMON_TIPS_RES = UIResourceDef.LOBBY_COMMON.TIPS
local TILTE_BG_COLOR = {
    ["White"] = {
        LINEAR_COLOR = KMUMGLibrary.GetLinearColor(1.0, 1.0, 1.0, 0.6),
        SLATE_COLOR = KMUMGLibrary.GetSlateColor(1.0, 1.0, 1.0, 0.6),
    },
    ["Black"] =     {
        LINEAR_COLOR = KMUMGLibrary.GetLinearColor(0.0, 0.0, 0.0, 0.6),
        SLATE_COLOR = KMUMGLibrary.GetSlateColor(0.0, 0.0, 0.0, 0.6),
    },
}

local function OnBtnSelectClicked(self)
    if self.fnOnSelected then
        self.fnOnSelected()
    end
end

function UPLobbyShipPartTitle:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
end

function UPLobbyShipPartTitle:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSelect.OnClicked, self, OnBtnSelectClicked)
end


function UPLobbyShipPartTitle:SetData(tbData)
    self.tbData = tbData
    local pWidgetRef = self.pWidgetRef
    local ShipPreparationComponent = self.OwnerSub:GetShipPreparationComponent()
    pWidgetRef.txtPartName:SetText(tbData.l10nName)
    pWidgetRef.txtDescribe:SetText(tbData.l10nIntro)
    
    -- 等级
    local l10nGradeTextFormat = UISetUtils.GetL10NTextByKey("SHIP_PART_GRADE_TEXT_FORMAT")
    local l10nGradeText = UISetUtils.GetL10NTextByKey("SHIP_PART_GRADE_TEXT_" .. tbData.nGrade)
    local nShipDesc = L10N:Format(l10nGradeTextFormat, l10nGradeText)
    pWidgetRef.txtPartGrades:SetText(nShipDesc)

    -- 解锁状态
    if ShipPreparationComponent:IsItemUnlocked(tbData.nId) then
        pWidgetRef.btnLock:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtSource:SetVisibility(ESlateVisibility.Collapsed)
    else
        local szSourceDesc = ItemSourceDataTable:GetSourceDesc(tbData.nSourceType)
        pWidgetRef.txtSource:SetText(szSourceDesc)
        pWidgetRef.txtSource:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.btnLock:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end

    if ShipPreparationComponent:IsNewShipItem(tbData.nId) then
        pWidgetRef.imgNew:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.imgNew:SetVisibility(ESlateVisibility.Collapsed)
    end

    -- 启用状态
    local nActivePartId = ShipPreparationComponent:GetActivePartId(tbData.nSubCategory)
    self:SetSelected(tbData.nId == nActivePartId)
end

function UPLobbyShipPartTitle:BindCallbacks(fnOnSelected)
    self.fnOnSelected = fnOnSelected
end

function UPLobbyShipPartTitle:SetSelected(bSelected)
    self.bSelected = bSelected
    local pWidgetRef = self.pWidgetRef
    if bSelected then
        UISetUtils.SetBorderBrushTint(pWidgetRef.bdrTitle, TILTE_BG_COLOR.White.SLATE_COLOR)
        pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtPartName:SetColorAndOpacity(UIResourceDef.COLOR.BLACK.SLATE_COLOR)
        pWidgetRef.txtPartGrades:SetColorAndOpacity(UIResourceDef.COLOR.BLACK.SLATE_COLOR)
        pWidgetRef.txtDescribe:SetColorAndOpacity(UIResourceDef.COLOR.BLACK.LINEAR_COLOR)
        pWidgetRef.imgSelectedDot:SetVisibility(ESlateVisibility.Visible)
        -- UISetUtils.SetImageBrushRes(pWidgetRef.imgSelect, LOBBY_COMMON_TIPS_RES.Pressed:load())
    else
        UISetUtils.SetBorderBrushTint(pWidgetRef.bdrTitle, TILTE_BG_COLOR.Black.SLATE_COLOR)
        pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Hidden)
        pWidgetRef.txtPartName:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        pWidgetRef.txtPartGrades:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        pWidgetRef.txtDescribe:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
        pWidgetRef.imgSelectedDot:SetVisibility(ESlateVisibility.Collapsed)
        -- UISetUtils.SetImageBrushRes(pWidgetRef.imgSelect, LOBBY_COMMON_TIPS_RES.Normal:load())
    end
end

function UPLobbyShipPartTitle:IsSelected()
    return self.bSelected
end

function UPLobbyShipPartTitle:OnActive()
    self:SetSelected(true)
    self:PlayAnimation("anim_ShipActivation", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPLobbyShipPartTitle:Refresh()
    self:SetData(self.tbData)
end

return UPLobbyShipPartTitle