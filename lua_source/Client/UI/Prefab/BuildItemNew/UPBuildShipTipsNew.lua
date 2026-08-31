-----------------------------------------------------
--File Name    : UPBuildShipTipsNew.lua
--Author       : chenyixin
--Description  : 新版造船的tips
-----------------------------------------------------
local luaclass = require("luaclass")
local UPBuilItemTipsBase = require("UPBuilItemTipsBase")
local UPBuildShipTipsNew = luaclass("UPBuildShipTipsNew", UPBuilItemTipsBase)
local BattleItemSystemClient = require("BattleItemSystemClient")
local BuildShipTipsContentHelper = require("BuildShipTipsContentHelper")
local BattleItemDataTable = require("BattleItemDataTable")
local UISetUtils = require("UISetUtils")
local ItemBuildingVerificationFailureDef = require("ItemBuildingVerificationFailureDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ShipItemHelper = require("ShipItemHelper")

local RECOMMENDED_WEAPON_MAX = 3

UPBuildShipTipsNew.uLShipDetailContent = nil

UPBuildShipTipsNew.tbRecommendedWeapons = nil

local function OnBuildBtnDisableClicked(self)
    local nItemTemplateId = self.nChoosenItemTemplateId
    local bVerificationResult, tbFailures = BattleItemSystemClient:VerifyItemBuilding(nItemTemplateId)
    if not bVerificationResult then
        for _, tbFailure in ipairs(tbFailures) do
            local nFailureType = tbFailure.nType
            if nFailureType == ItemBuildingVerificationFailureDef.INACCEPTABLE_PLAYER_SHIP_BUILDING_LEVEL then
                local nTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
                local nGrade = nTemplate.nGrade
                local nNeedGrade = nGrade - 1
                local l10nToast = L10N:Format(UITextDef.FFA_SHIP_BUILDING_NEED_LOW_LEVEL, nNeedGrade)
                UIUtils.ShowToast(l10nToast)
            end
        end
    end
end

local function OnWeaponPressed(self, nIndex, pWidgetRef)
    local nItemTemplateId = self.tbRecommendedWeapons[nIndex]
    self.OnItemButtonPressedDelegate:Fire(nItemTemplateId, pWidgetRef)
end

local function OnWeaponReleased(self, nIndex)
    self.OnItemButtonReleasedDelegate:Fire()
end

local function RefreshRecommendedWeapons(self, tbRecommendedWeapons)
    self.tbRecommendedWeapons = tbRecommendedWeapons
    local nRecommendedWeaponCount = 0
    local pWidgetRef = self.pWidgetRef
    if tbRecommendedWeapons then
        nRecommendedWeaponCount = #tbRecommendedWeapons
    end
    if nRecommendedWeaponCount == 0 then
        pWidgetRef.hboxCommendedWeapons:SetVisibility(ESlateVisibility.Collapsed)
        return
    end
    pWidgetRef.hboxCommendedWeapons:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    for i = 1, RECOMMENDED_WEAPON_MAX do
        local cvsWeaponWidget = pWidgetRef["cvsWeapon"..i]
        if i > nRecommendedWeaponCount then
            cvsWeaponWidget:SetVisibility(ESlateVisibility.Collapsed)
        else
            cvsWeaponWidget:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            local nWeaponTemplateId = tbRecommendedWeapons[i]
            local tbResTemplate = BattleItemDataTable:GetResTemplate(nWeaponTemplateId)
            local szIconPath = tbResTemplate.szIconPath --szSilhouettePath szIconPath
            UISetUtils.SetButtonBrushRes(pWidgetRef["btnWeapon"..i], szIconPath:load())
        end
    end
end

local function Refresh(self, nItemTemplateId, bShowDetailBtn)
    local pWidgetRef = self.pWidgetRef


    local tbShipTipsDatas = BuildShipTipsContentHelper.GetShipTipsDatas(nItemTemplateId)
    pWidgetRef.ktxtTitle:SetText(tbShipTipsDatas.szTitle)

    -- 刷新战斗数值
    self.uLShipDetailContent:SetShipTemplateId(nItemTemplateId)
    self.uLShipDetailContent:SetShowDetailedInfo(false)

    RefreshRecommendedWeapons(self, tbShipTipsDatas.tbRecommendedWeapons)

    local pVisibility = (self.bIsCurrent and not bShowDetailBtn) and ESlateVisibility.Collapsed or ESlateVisibility.Visible
    pWidgetRef.KMButton_0:SetVisibility(pVisibility)
end

function UPBuildShipTipsNew:OnLoad()
    self.super.OnLoad(self)
    log("[DEBUG_UI] UPBuildShipTipsNew:OnLoad")
    local pWidgetRef = self.pWidgetRef
    local UILogicHelper = self.UILogicHelper

    self.uLShipDetailContent = UILogicHelper:CreateUILogic("ULLobbyShipDetailContent")
    self.uLShipDetailContent.bBuild = true

    self:BindPbBuildingCostMaterials(pWidgetRef.pbBuildingCostMaterials, pWidgetRef.hboxCost)
end

function UPBuildShipTipsNew:OnShow()
    self.super.OnShow(self)
    log("[DEBUG_UI] UPBuildShipTipsNew:OnShow")
end

function UPBuildShipTipsNew:OnUnload()
    self.super.OnUnload(self)
end

function UPBuildShipTipsNew:OnBindEvent(EventHelper)
    self.super.OnBindEvent(self, EventHelper)

    log("[DEBUG_UI] UPBuildShipTipsNew:OnBindEvent begin")
    local pWidgetRef =self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnBuild.OnDisableClicked, self, OnBuildBtnDisableClicked)

    for i = 1, RECOMMENDED_WEAPON_MAX do
        local kmBtnWeaponWidget = pWidgetRef["btnWeapon"..i]
        EventHelper:RegisterCppDelegate(kmBtnWeaponWidget.OnPressed, self, function() OnWeaponPressed(self, i, kmBtnWeaponWidget) end)
        EventHelper:RegisterCppDelegate(kmBtnWeaponWidget.OnReleased, self, function() OnWeaponReleased(self, i) end)
    end

    self:BindTxtCurrent(pWidgetRef.kmtxtCurrent)
    self:BindKeyItem(pWidgetRef.kmButtonKeyItem, pWidgetRef.imgBuildKeyItem, pWidgetRef.txtBuildKeyItemCostCount)
    self:BindBuildAndReserve(pWidgetRef.kmbtnBuild, pWidgetRef.kmbtnReserve, pWidgetRef.txtReserve)

    log("[DEBUG_UI] UPBuildShipTipsNew:OnBindEvent end")
end

function UPBuilItemTipsBase:GetCurrentItemTemplateId()
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nCurrentShipTemplateId = ShipItemHelper.GetCurrentShipItemTemplateId(nCharacterInstanceId, true)
    return nCurrentShipTemplateId
end

function UPBuildShipTipsNew:Refresh(nItemTemplateId, bNotShowPrice, bShowDetailBtn)
    self.super.Refresh(self, nItemTemplateId, bNotShowPrice)
    Refresh(self, nItemTemplateId, bShowDetailBtn)
end

function UPBuildShipTipsNew:BindOnBtnDetailClicked(fnOnBtnDetailClicked)
    self.uLShipDetailContent:BindOnBtnDetailClicked(fnOnBtnDetailClicked)
end

function UPBuildShipTipsNew:ToggleShowDetailedInfo()
    self.uLShipDetailContent:ToggleShowDetailedInfo()
end

return UPBuildShipTipsNew