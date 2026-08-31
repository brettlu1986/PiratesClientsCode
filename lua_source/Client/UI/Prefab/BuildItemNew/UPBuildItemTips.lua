local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPBuildItemTips = luaclass("UPBuildItemTips", PrefabBase)
local BattleItemDataTable = require("BattleItemDataTable")
local UIDef = require("UIDef")
local L10N = require("L10N")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local UISetUtils = require("UISetUtils")
local BuildShipPartTipsContentHelper = require("BuildShipPartTipsContentHelper")
local BuildShipWeaponTipsContentHelper = require("BuildShipWeaponTipsContentHelper")
local BuildHumanArmorTipsContentHelper = require("BuildHumanArmorTipsContentHelper")
local BuildHumanWeaponTipsContentHelper = require("BuildHumanWeaponTipsContentHelper")
local UIResourceDef = require("UIResourceDef")
local UITextDef = require("UITextDef")
local ClientEventDef = require("ClientEventDef")
local LuaDelegateClass = require("LuaDelegate")
local UIToolTipHelper = require("UIToolTipHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CheckCanBuildItemHelper = require("CheckCanBuildItemHelper")

UPBuildItemTips.nChoosenItemTemplateId = nil
UPBuildItemTips.bReserved = nil
UPBuildItemTips.pbBuildingCostMaterials = nil

UPBuildItemTips.OnItemButtonPressedDelegate = nil
UPBuildItemTips.OnItemButtonReleasedDelegate = nil

UPBuildItemTips.tbGridPanelChilden = nil
UPBuildItemTips.nKeyItemId = nil
UPBuildItemTips.bNotShowPrice = nil
UPBuildItemTips.bIsCurrent = nil

local WEAPON_PREFAB_OFFSET  = Margin{Left=0, Top=0, Right=0, Bottom=4}
local DESC_NEED_LOW_LEVEL_TITLE          = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_NEED_LOW_LEVEL_TITLE")            -- 需要先拥有{0}（等级{1}）

local function GetEquippedItem(nItemTemplateId, nSlotIndex)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    return CheckCanBuildItemHelper.GetSameSlotEquippedItem(nCharacterInstanceId, nItemTemplateId, nSlotIndex, true)
end

local function HiddenTips(self)
    UIToolTipHelper:HideTip()
end

local function ShowItemTips(self, nItemTemplateId, pPressedWidgetRef)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local tbTipData = {
        szTitle = tbTemplate.l10nName,
        szDetail = tbTemplate.l10nDetailedDesc,
    }
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.TEXT_TIP, tbTipData, pPressedWidgetRef)
end

local function OnItemButtonPressed(self, nItemTemplateId, pPressedWidgetRef)
    ShowItemTips(self, nItemTemplateId, pPressedWidgetRef)
end

local function OnItemButtonReleased(self)
    HiddenTips(self)
end

local function OnKeyItemButtonPressed(self)
    self.OnItemButtonPressedDelegate:Fire(self.nKeyItemId, self.pWidgetRef.kmButtonKeyItem)
end

local function OnKeyItemButtonReleased(self)
    self.OnItemButtonReleasedDelegate:Fire()
end

local function RefreshMaterialCosts(self, tbBuildTemplate)
    self.pbBuildingCostMaterials:Refresh(tbBuildTemplate)
end

local function RefreshBuildKeyItem(self, tbBuildTemplate)
    local pWidgetRef = self.pWidgetRef
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

local function OnCloseBtnClicked(self)
    self:Collapsed()
end

local function OnBuildBtnClicked(self)
    BattleItemSystemClient:RequestBuildItem(self.nChoosenItemTemplateId, self.nSlotIndex)
end

local function OnReserveBtnClicked(self)
    if self.bReserved then
        BattleItemSystemClient:CancelReserveItemBuild(self.nChoosenItemTemplateId)
    else
        BattleItemSystemClient:ReserveItemBuild(self.nChoosenItemTemplateId)
    end
end

local function RefreshItemName(self, szTitle)
    self.pWidgetRef.txtItemName:SetText(szTitle)
end

local function RefreshDesc(self, szDesc)
    self.pWidgetRef.ktxtDesc:SetText(szDesc)
end

local function RefreshOnlyTextContent(self, szDesc)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.ktxtContent:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.vboxContent:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ktxtContent:SetText(szDesc)
end

local function ClearGridPanels(self)
    if self.tbGridPanelChilden ~= nil and #self.tbGridPanelChilden > 0 then
        for _, v in ipairs(self.tbGridPanelChilden) do
            v:RemoveFromParent()
        end
    end
end

local function CreateTextBlock(self, nRow, nColumn, szText, nHorizontalAlignment, nTextJustify)
    local WidgetHelper = self.WidgetHelper
    local pWidgetRef = self.pWidgetRef
    local pTextBlock = WidgetHelper:CreateWidget(TextBlock)
    local pGridSlot = pWidgetRef.gridPanelContent:AddChildToGrid(pTextBlock, 0, 0)
    pGridSlot:SetRow(nRow)
    pGridSlot:SetColumn(nColumn)
    pGridSlot:SetHorizontalAlignment(nHorizontalAlignment)
    pGridSlot:SetPadding(WEAPON_PREFAB_OFFSET)
    pTextBlock:SetText(szText)
    UISetUtils.SetTextblockFont(pTextBlock, UIResourceDef.FFA_FONT_RES_PINGFANG:load(), "Bold")
    UISetUtils.SetTextblockFontSize(pTextBlock, 20)
    pTextBlock:SetJustification(nTextJustify)
    if self.tbGridPanelChilden == nil then
        self.tbGridPanelChilden = {}
    end
    table.insert(self.tbGridPanelChilden, pTextBlock)
end

local function FillGridPanels(self, tbDatas)
    for i, v in ipairs(tbDatas) do
        local szTitle = v.szTitle
        local szDesc = v.szDesc
        CreateTextBlock(self, i-1, 0, szTitle, EHorizontalAlignment.HAlign_Left, ETextJustify.Left)

        if szDesc ~= nil then
            CreateTextBlock(self, i-1, 1, szDesc, EHorizontalAlignment.HAlign_Right, ETextJustify.Right)
        end
    end
end

local function RefreshgridPanelContent(self, tbDatas)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.ktxtContent:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.vboxContent:SetVisibility(ESlateVisibility.HitTestInvisible)

    ClearGridPanels(self)
    FillGridPanels(self, tbDatas)
end

local function RefreshDamage(self, nDamage)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtAttack:SetText(nDamage)
end

local function GetLockDesc(nChoosenItemTemplateId, bLock)
    if bLock then
        local tbBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nChoosenItemTemplateId)
        if tbBuildTemplate == nil then
            return nil
        else
            local nPrerequisiteId = tbBuildTemplate.nPrerequisiteId
            if nPrerequisiteId ~= nil and nPrerequisiteId > 0 then
                local tbPrerequisiteItemTemplate = BattleItemDataTable:GetTemplate(nPrerequisiteId)
                local l10nNeedLowLevel = L10N:Format(DESC_NEED_LOW_LEVEL_TITLE, tbPrerequisiteItemTemplate.l10nName, tbPrerequisiteItemTemplate.nGrade)
                return l10nNeedLowLevel
            end
        end
    else
        return nil
    end
end


local function RefreshLockData(self, nChoosenItemTemplateId, bLock)
    local ktxtLockDesc = self.pWidgetRef.ktxtLockDesc
    if not self.bIsCurrent and bLock then
        local szLock = GetLockDesc(nChoosenItemTemplateId, bLock)
        ktxtLockDesc:SetVisibility(ESlateVisibility.HitTestInvisible)
        ktxtLockDesc:SetText(szLock)
    else
        ktxtLockDesc:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function RefreshShipPart(self, nChoosenItemTemplateId, bLock)
    local tbTipsData = BuildShipPartTipsContentHelper.GetTipsData(nChoosenItemTemplateId, bLock)
    RefreshItemName(self, tbTipsData.szTitle)
    RefreshOnlyTextContent(self, tbTipsData.szDesc)
    RefreshLockData(self, nChoosenItemTemplateId, bLock)
end

local function RefreshShipWeapon(self, nChoosenItemTemplateId)
    local tbTipsData = BuildShipWeaponTipsContentHelper.GetTipsData(nChoosenItemTemplateId)
    RefreshItemName(self, tbTipsData.szTitle)
    RefreshDamage(self, tbTipsData.nDamage)
    RefreshDesc(self, tbTipsData.szDesc)
    RefreshgridPanelContent(self, tbTipsData.tbDatas)
    RefreshLockData(self)
end

local function RefreshHumanWeapon(self, nChoosenItemTemplateId, nSlotIndex, bLock)
    local tbTipsData = BuildHumanWeaponTipsContentHelper.GetTipsData(nChoosenItemTemplateId, bLock)
    RefreshItemName(self, tbTipsData.szTitle)
    RefreshDamage(self, tbTipsData.nDamage)
    RefreshDesc(self, tbTipsData.szDesc)
    RefreshgridPanelContent(self, tbTipsData.tbDatas)
    RefreshLockData(self, nChoosenItemTemplateId, bLock)
end

local function RefreshHumanArmor(self, nChoosenItemTemplateId, bLock)
    local tbTipsData = BuildHumanArmorTipsContentHelper.GetTipsData(nChoosenItemTemplateId, bLock)
    RefreshItemName(self, tbTipsData.szTitle)
    RefreshOnlyTextContent(self, tbTipsData.szDesc)
    RefreshLockData(self, nChoosenItemTemplateId, bLock)
end

local function RefreshCurrent(self)
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local nEquippedTemplateId = CheckCanBuildItemHelper.GetSameSlotEquippedItemTemplateId(nCharacterInstanceId, self.nChoosenItemTemplateId, self.nSlotIndex, true)

    local kmtxtCurrent = self.pWidgetRef.kmtxtCurrent
    if nEquippedTemplateId == self.nChoosenItemTemplateId then
        kmtxtCurrent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        return true
    else
        kmtxtCurrent:SetVisibility(ESlateVisibility.Collapsed)
        return false
    end
end

local function RefreshReserveButton(self)
    local pWidgetRef =self.pWidgetRef
    local nReservedItemTemplateId = BattleItemSystemClient:GetReservedItemTemplateId()

    if nReservedItemTemplateId == nil or nReservedItemTemplateId ~= self.nChoosenItemTemplateId then
        pWidgetRef.txtReserve:SetText(UITextDef.UI_STATIC_FFA_RESERVE_ITEM_BUILD)
        self.bReserved = false
    else
        pWidgetRef.txtReserve:SetText(UITextDef.UI_STATIC_FFA_CANCEL_RESERVE_ITEM_BUILD)
        self.bReserved = true
    end
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

local function GetShipPartCanBuildAndLock(self, tbItemTemplate)
    local nCanBuildGrade = 1
    local nItemTemplateId = tbItemTemplate.nId
    local EquippedItem = GetEquippedItem(nItemTemplateId)
    if EquippedItem then
        nCanBuildGrade = EquippedItem:GetGrade() + 1
    end
    local bCanBuild = false
    local bLock = false
    if tbItemTemplate.nGrade <= nCanBuildGrade then
        local bVerificationResult, _ = BattleItemSystemClient:VerifyItemBuilding(nItemTemplateId, self.nSlotIndex)
        bCanBuild = bVerificationResult
        bLock = false
    else
        bCanBuild = false
        bLock = true
    end
    return bCanBuild, bLock
end

local function GetShipWeaponCanBuild(self, nChoosenItemTemplateId)
    local bVerificationResult, _ = BattleItemSystemClient:VerifyItemBuilding(nChoosenItemTemplateId, self.nSlotIndex)
    return bVerificationResult
end

local function GetHumanItemCanBuildAndLock(self, tbItemTemplate, nSlotIndex)
    local nItemTemplateId = tbItemTemplate.nId
    local EquippedItem = GetEquippedItem(nItemTemplateId, nSlotIndex)
    local bCanBuild = false
    local bLock = false
    if EquippedItem then
        local nCanBuildGrade = EquippedItem:GetGrade() + 1
        if tbItemTemplate.nGrade == nCanBuildGrade then
            local bVerificationResult, _ = BattleItemSystemClient:VerifyItemBuilding(nItemTemplateId, self.nSlotIndex)
            bCanBuild = bVerificationResult
            bLock = false
        else
            bCanBuild = false
            bLock = true
        end
    end

    return bCanBuild, bLock
end

local function GetCanBuildAndLock(self, nChoosenItemTemplateId, nSlotIndex)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nChoosenItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    if nCategory == BattleItemCategoryDef.SHIP_PART then
        return GetShipPartCanBuildAndLock(self, tbItemTemplate)
    elseif nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        return GetShipWeaponCanBuild(self, nChoosenItemTemplateId)
    elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        return GetHumanItemCanBuildAndLock(self, tbItemTemplate, nSlotIndex)
    elseif nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        return GetHumanItemCanBuildAndLock(self, tbItemTemplate)
    end
end

local function OnItemChanged(self)
    if self.pWidgetRef:IsVisible() then
        self:Refresh(self.nChoosenItemTemplateId, self.bNotShowPrice, self.nSlotIndex)
    end
end

function UPBuildItemTips:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    self.OnItemButtonPressedDelegate = LuaDelegateClass()
    self.OnItemButtonReleasedDelegate = LuaDelegateClass()
    self.pbBuildingCostMaterials = PrefabHelper:BindPrefab(pWidgetRef.pbBuildingCostMaterials, UIDef.UP_BUILDING_COST_MATERIALS)
    self.pbBuildingCostMaterials:SetOnItemButtonPressedDelegate(self.OnItemButtonPressedDelegate)
    self.pbBuildingCostMaterials:SetOnItemButtonReleasedDelegate(self.OnItemButtonReleasedDelegate)
end

function UPBuildItemTips:OnBindEvent(EventHelper)
    local pWidgetRef =self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnClose.OnClicked, self, OnCloseBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnBuild.OnClicked, self, OnBuildBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnReserve.OnClicked, self, OnReserveBtnClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmButtonKeyItem.OnPressed, self, OnKeyItemButtonPressed)
    EventHelper:RegisterCppDelegate(pWidgetRef.kmButtonKeyItem.OnReleased, self, OnKeyItemButtonReleased)

    EventHelper:RegisterLuaDelegate(self.OnItemButtonPressedDelegate, OnItemButtonPressed, self)
    EventHelper:RegisterLuaDelegate(self.OnItemButtonReleasedDelegate, OnItemButtonReleased, self)

    EventHelper:RegisterEvent(ClientEventDef.EV_RESERVE_ITEM_BUILD, self, OnReserveItemBuild)
    EventHelper:RegisterEvent(ClientEventDef.EV_CANCEL_RESERVE_ITEM_BUILD, self, OnCancelReserveItemBuild)

    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, self, OnItemChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, self, OnItemChanged)
end

function UPBuildItemTips:Collapsed()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPBuildItemTips:Refresh(nChoosenItemTemplateId, bNotShowPrice, nSlotIndex)
    self.bNotShowPrice = bNotShowPrice
    self.nChoosenItemTemplateId = nChoosenItemTemplateId
    self.nSlotIndex = nSlotIndex
    local bCanBuild, bLock = GetCanBuildAndLock(self, nChoosenItemTemplateId, nSlotIndex)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)

    self.bIsCurrent = RefreshCurrent(self)

    local tbItemTemplate = BattleItemDataTable:GetTemplate(nChoosenItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    if nCategory == BattleItemCategoryDef.SHIP_PART then
        RefreshShipPart(self, nChoosenItemTemplateId, bLock)
    elseif nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        RefreshShipWeapon(self, nChoosenItemTemplateId)
    elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        RefreshHumanWeapon(self, nChoosenItemTemplateId, nSlotIndex, bLock)
    elseif nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        RefreshHumanArmor(self, nChoosenItemTemplateId, bLock)
    end

    local tbBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nChoosenItemTemplateId)
    if tbBuildTemplate == nil or self.bNotShowPrice then
        pWidgetRef.hboxCost:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.kmbtnBuild:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.kmbtnReserve:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.hboxCost:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.kmbtnBuild:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.kmbtnReserve:SetVisibility(ESlateVisibility.Visible)
        RefreshMaterialCosts(self, tbBuildTemplate)
        RefreshBuildKeyItem(self, tbBuildTemplate)
        pWidgetRef.kmbtnBuild:SetIsEnabled(bCanBuild)
        RefreshReserveButton(self)
    end
    HiddenTips(self)
end

return UPBuildItemTips