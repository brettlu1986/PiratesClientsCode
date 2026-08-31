-----------------------------------------------------
--File Name    : UPBuildShipTips.lua
--Author       : zhiyuan
--Create Time  : 2019-09-17
--Description  : 造船的tips
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBuildShipTips = luaclass("UPBuildShipTips", PrefabBase)
local BattleItemSystemClient = require("BattleItemSystemClient")
local BuildShipTipsContentHelper = require("BuildShipTipsContentHelper")
local LuaDelegateClass = require("LuaDelegate")
local UIDef = require("UIDef")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ItemBuildingVerificationFailureDef = require("ItemBuildingVerificationFailureDef")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local ClientEventDef = require("ClientEventDef")
local L10N = require("L10N")
local UIToolTipHelper = require("UIToolTipHelper")
local SkillDataTable = require("SkillDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ShipItemHelper = require("ShipItemHelper")

local SKILL_COUNT_MAX = 4
local RECOMMENDED_WEAPON_MAX = 3

UPBuildShipTips.uLShipDetailContent = nil

UPBuildShipTips.tbPbBuildShipSkills = nil

UPBuildShipTips.OnSkillButtonPressedDelegate = nil
UPBuildShipTips.OnSkillButtonReleasedDelegate = nil

UPBuildShipTips.OnItemButtonPressedDelegate = nil
UPBuildShipTips.OnItemButtonReleasedDelegate = nil

UPBuildShipTips.nChoosenItemTemplateId = nil
UPBuildShipTips.bReserved = nil
UPBuildShipTips.nKeyItemId = nil
UPBuildShipTips.tbRecommendedWeapons = nil
UPBuildShipTips.bNotShowPrice = nil

local function OnCloseBtnClicked(self)
    self:Collapsed()
end

local function HiddenTips(self)
    UIToolTipHelper:HideTip()
end

local function ShowSkillTips(self, nSkillId, pPressedWidgetRef)
    local tbSkillResTemplate = SkillDataTable:GetResTemplate(nSkillId)

    local tbTipData = {
        szTitle = tbSkillResTemplate.l10nName,
        szDetail = tbSkillResTemplate.l10nDesc,
    }
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.TEXT_TIP, tbTipData, pPressedWidgetRef)
end

local function ShowItemTips(self, nItemTemplateId, pPressedWidgetRef)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local tbTipData = {
        szTitle = tbTemplate.l10nName,
        szDetail = tbTemplate.l10nDetailedDesc,
    }
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.TEXT_TIP, tbTipData, pPressedWidgetRef)
end

local function OnSkillButtonPressed(self, nSkillId, pPressedWidgetRef)
    ShowSkillTips(self, nSkillId, pPressedWidgetRef)
end

local function OnSkillButtonReleased(self, nSkillId)
    HiddenTips(self)
end

local function OnItemButtonPressed(self, nItemTemplateId, pPressedWidgetRef)
    ShowItemTips(self, nItemTemplateId, pPressedWidgetRef)
end

local function OnItemButtonReleased(self)
    HiddenTips(self)
end

local function OnBuildBtnClicked(self)
    BattleItemSystemClient:RequestBuildItem(self.nChoosenItemTemplateId)
end

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

local function OnReserveBtnClicked(self)
    if self.bReserved then
        BattleItemSystemClient:CancelReserveItemBuild(self.nChoosenItemTemplateId)
    else
        BattleItemSystemClient:ReserveItemBuild(self.nChoosenItemTemplateId)
    end
end

local function OnKeyItemButtonPressed(self)
    self.OnItemButtonPressedDelegate:Fire(self.nKeyItemId, self.pWidgetRef.kmButtonKeyItem)
end

local function OnKeyItemButtonReleased(self)
    self.OnItemButtonReleasedDelegate:Fire()
end


local function OnWeaponPressed(self, nIndex, pWidgetRef)
    local nItemTemplateId = self.tbRecommendedWeapons[nIndex]
    self.OnItemButtonPressedDelegate:Fire(nItemTemplateId, pWidgetRef)
end

local function OnWeaponReleased(self, nIndex)
    self.OnItemButtonReleasedDelegate:Fire()
end

local function RefreshCurrent(self)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nCurrentShipTemplateId = ShipItemHelper.GetCurrentShipItemTemplateId(nCharacterInstanceId, true)
    local kmtxtCurrent = self.pWidgetRef.kmtxtCurrent
    if nCurrentShipTemplateId == self.nChoosenItemTemplateId then
        kmtxtCurrent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        return true
    else
        kmtxtCurrent:SetVisibility(ESlateVisibility.Collapsed)
        return false
    end
end

local function RefreshBuildKeyItem(self, tbBuildTemplate)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.hboxCost:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local tbKeyItemIds = tbBuildTemplate.tbKeyItemIds
    if tbKeyItemIds == nil or #tbKeyItemIds == 0 then
        pWidgetRef.bdrBuildKeyItem:SetVisibility(ESlateVisibility.Collapsed)
        self.nKeyItemId = nil
    else
        pWidgetRef.bdrBuildKeyItem:SetVisibility(ESlateVisibility.Visible)
        local nKeyItemId = tbKeyItemIds[1] -- 这里的假设是只有一种关键材料，且只需要一个
        self.nKeyItemId = nKeyItemId
        local nNeedCount = 1
        local tbBuildKeyItemTemplate = BattleItemDataTable:GetTemplate(nKeyItemId)
        local szCostIconPath = tbBuildKeyItemTemplate.szCostIconPath
        UISetUtils.SetImageBrushRes(pWidgetRef.imgBuildKeyItem, szCostIconPath:load(), true)
        local txtBuildKeyItemCostCount = pWidgetRef.txtBuildKeyItemCostCount
        txtBuildKeyItemCostCount:SetText(nNeedCount)
        local nKeyItemCount = BattleItemSystemClient:GetUnequippedItemCount(nKeyItemId)
        if nKeyItemCount >= nNeedCount then
            txtBuildKeyItemCostCount:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        else
            txtBuildKeyItemCostCount:SetColorAndOpacity(UIResourceDef.COLOR.RED.SLATE_COLOR)
        end
    end
end

local function RefreshMaterialCosts(self, nItemTemplateId)
    local tbBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateId)
    self.pbBuildingCostMaterials:Refresh(tbBuildTemplate)
end

local function RefreshSkills(self, tbSkillIds)
    local pWidgetRef = self.pWidgetRef
    if tbSkillIds == nil or #tbSkillIds == 0 then
        pWidgetRef.txtSkills:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hboxSkills:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.txtSkills:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.hboxSkills:SetVisibility(ESlateVisibility.Visible)
        for i = 1, SKILL_COUNT_MAX do
            local pbBuildShipSkill = self.tbPbBuildShipSkills[i]
            if #tbSkillIds >= i then
                pbBuildShipSkill:Refresh(tbSkillIds[i])
            else
                pbBuildShipSkill:Collapsed()
            end
        end
    end
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

local function RefreshReserveButton(self)
    local pWidgetRef = self.pWidgetRef
    local nReservedItemTemplateId = BattleItemSystemClient:GetReservedItemTemplateId()
    pWidgetRef.kmbtnReserve:SetVisibility(ESlateVisibility.Visible)
    if nReservedItemTemplateId == nil or nReservedItemTemplateId ~= self.nChoosenItemTemplateId then
        pWidgetRef.txtReserve:SetText(UITextDef.UI_STATIC_FFA_RESERVE_ITEM_BUILD)
        self.bReserved = false
    else
        pWidgetRef.txtReserve:SetText(UITextDef.UI_STATIC_FFA_CANCEL_RESERVE_ITEM_BUILD)
        self.bReserved = true
    end
end

local function RefreshBuildButton(self, nItemTemplateId)
    local bVerificationResult, _ = BattleItemSystemClient:VerifyItemBuilding(nItemTemplateId)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.kmbtnBuild:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.kmbtnBuild:SetIsEnabled(bVerificationResult)
end

local function OnReserveItemBuild(self, nReservedItemInstanceId)
    if nReservedItemInstanceId == self.nChoosenItemTemplateId then
        RefreshReserveButton(self)
    end
end

local function OnCancelReserveItemBuild(self, nCancelReservedItemInstanceId)
    if nCancelReservedItemInstanceId == self.nChoosenItemTemplateId then
        RefreshReserveButton(self)
    end
end

local function Refresh(self, nItemTemplateId)
    self.nChoosenItemTemplateId = nItemTemplateId
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

    HiddenTips(self)

    local tbShipTipsDatas = BuildShipTipsContentHelper.GetShipTipsDatas(nItemTemplateId)
    pWidgetRef.txtTitle:SetText(tbShipTipsDatas.szTitle)

    local bIsCurrent = RefreshCurrent(self)

    -- 刷新战斗数值
    self.uLShipDetailContent:SetShipTemplateId(nItemTemplateId)
    self.uLShipDetailContent:CollapseAllCategory()
    self.uLShipDetailContent:UpdateShipProperties()

    RefreshSkills(self, tbShipTipsDatas.tbSkillIds)
    RefreshRecommendedWeapons(self, tbShipTipsDatas.tbRecommendedWeapons)
    RefreshMaterialCosts(self, nItemTemplateId)

    local tbBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateId)
    if tbBuildTemplate == nil or self.bNotShowPrice or bIsCurrent then
        pWidgetRef.hboxCost:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.kmbtnBuild:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.kmbtnReserve:SetVisibility(ESlateVisibility.Collapsed)
    else
        RefreshBuildKeyItem(self, tbBuildTemplate)
        RefreshBuildButton(self, nItemTemplateId)
        RefreshReserveButton(self)
    end
end

local function OnItemChanged(self)
    if self.pWidgetRef:IsVisible() then
        Refresh(self, self.nChoosenItemTemplateId)
    end
end

local function BindShipSkillPrefabs(self)
    local pWidgetRef = self.pWidgetRef
    self.tbPbBuildShipSkills = {}
    local tbPbBuildShipSkills = self.tbPbBuildShipSkills
    for i = 1, SKILL_COUNT_MAX  do
        local pbShipSkill = self.PrefabHelper:BindPrefab(pWidgetRef["pbBuildShipSkill0"..i])
        pbShipSkill:SetOnSkillButtonPressedDelegate(self.OnSkillButtonPressedDelegate)
        pbShipSkill:SetOnSkillButtonReleasedDelegate(self.OnSkillButtonReleasedDelegate)
        tbPbBuildShipSkills[i] = pbShipSkill
    end
end

function UPBuildShipTips:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    local UILogicHelper = self.UILogicHelper

    self.uLShipDetailContent = UILogicHelper:CreateUILogic("ULShipDetailContent")
    self.uLShipDetailContent:InitListHelper(self.pWidgetRef.listShipContent)

    self.pbBuildingCostMaterials = PrefabHelper:BindPrefab(pWidgetRef.pbBuildingCostMaterials, UIDef.UP_BUILDING_COST_MATERIALS)
    self.OnSkillButtonPressedDelegate = LuaDelegateClass()
    self.OnSkillButtonReleasedDelegate = LuaDelegateClass()
    BindShipSkillPrefabs(self)
    self.OnItemButtonPressedDelegate = LuaDelegateClass()
    self.OnItemButtonReleasedDelegate = LuaDelegateClass()
    self.pbBuildingCostMaterials:SetOnItemButtonPressedDelegate(self.OnItemButtonPressedDelegate)
    self.pbBuildingCostMaterials:SetOnItemButtonReleasedDelegate(self.OnItemButtonReleasedDelegate)
end

function UPBuildShipTips:OnUnload()

end

function UPBuildShipTips:OnBindEvent(EventHelper)
    local pWidgetRef =self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnClose.OnClicked, self, OnCloseBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnBuild.OnClicked, self, OnBuildBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnBuild.OnDisableClicked, self, OnBuildBtnDisableClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnReserve.OnClicked, self, OnReserveBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmButtonKeyItem.OnPressed, self, OnKeyItemButtonPressed)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmButtonKeyItem.OnReleased, self, OnKeyItemButtonReleased)
    EventHelper:RegisterLuaDelegate(self.OnSkillButtonPressedDelegate, OnSkillButtonPressed, self)
    EventHelper:RegisterLuaDelegate(self.OnSkillButtonReleasedDelegate, OnSkillButtonReleased, self)
    EventHelper:RegisterLuaDelegate(self.OnItemButtonPressedDelegate, OnItemButtonPressed, self)
    EventHelper:RegisterLuaDelegate(self.OnItemButtonReleasedDelegate, OnItemButtonReleased, self)

    for i = 1, RECOMMENDED_WEAPON_MAX do
        local kmBtnWeaponWidget = pWidgetRef["btnWeapon"..i]
        EventHelper:RegisterCppDelegate(kmBtnWeaponWidget.OnPressed, self, function() OnWeaponPressed(self, i, kmBtnWeaponWidget) end)
        EventHelper:RegisterCppDelegate(kmBtnWeaponWidget.OnReleased, self, function() OnWeaponReleased(self, i) end)
    end

    EventHelper:RegisterEvent(ClientEventDef.EV_RESERVE_ITEM_BUILD, self, OnReserveItemBuild)
    EventHelper:RegisterEvent(ClientEventDef.EV_CANCEL_RESERVE_ITEM_BUILD, self, OnCancelReserveItemBuild)

    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemChanged)
end

function UPBuildShipTips:Collapsed()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPBuildShipTips:Refresh(nItemTemplateId, bNotShowPrice)
    self.bNotShowPrice = bNotShowPrice
    Refresh(self, nItemTemplateId)
end

return UPBuildShipTips