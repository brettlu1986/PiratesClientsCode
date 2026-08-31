-----------------------------------------------------
--File Name    : ULHomeShipWeaponResearchChoose.lua
--Author       : zhiyuan
--Create Time  : 2019-05-21
--Description  : 船武器研发的UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULHomeShipWeaponResearchChoose = luaclass("ULHomeShipWeaponResearchChoose", UILogicBase)

local UITextDef = require("UITextDef")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local HomelandSystem = require("HomelandSystem")
local ItemResearchDataTable = require("ItemResearchDataTable")
local ItemSystem = require("ItemSystem")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local CurrencySystem = require("CurrencySystem")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local UIResourceDef = require("UIResourceDef")
local UIDef = require("UIDef")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local UIUtils = require("UIUtils")
local BuildShipWeaponTipsContentHelper = require("BuildShipWeaponTipsContentHelper")
local TimeUtil = require("TimeUtil")
local L10N = require("L10N")
local ItemDataTable = require("ItemDataTable")

local DEFAULT_CHOOSE_INDEX = 1

local STATUS_CLICK_OPEN = 1
local STATUS_CLICK_CLOSE = 2

local SLOT_MAX = 3

local ANIM_NAME = "animSelect"

local WEAPON_PREFAB_OFFSET  = Margin{Left=0, Top=0, Right=0, Bottom=4}

ULHomeShipWeaponResearchChoose.nCurrentStatus = nil
ULHomeShipWeaponResearchChoose.nCurrentSlot = nil
ULHomeShipWeaponResearchChoose.tbSelectedWeaponIds = nil

ULHomeShipWeaponResearchChoose.ListHelper = nil

ULHomeShipWeaponResearchChoose.tbWeaponItemPool = nil

local function GetHomelandItemSystem()
    return HomelandSystem:GetSubSystem("HomelandItemSystem")
end

local function ShowCommitDialog(self, nItemTemplateId)
    local Dialog = UIUtils.CreateDialog(L10N.NullString)
    local l10nFormat = UISetUtils.GetL10NTextByKey("HOMELAND_RESEARCH_COMMIT_FORMAT")
    local tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    Dialog:SetMessage(L10N:Format(l10nFormat, tbTemplate.l10nName))
    Dialog:SetPositiveButtonVisible(true)
    --Dialog:SetPositiveText(UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAMING_TITLE"))
    local HomelandItemSystem = GetHomelandItemSystem()

    Dialog:SetPositiveButtonCallback(function() HomelandItemSystem:RequestResearchItem(nItemTemplateId) end, self)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:ShowDialog()
end


local function OnClickResearch(self)
    local HomelandItemSystem = GetHomelandItemSystem()
    local nItemTemplateId = self.ListHelper.tbExtraDatas.nSelectedItemId
    if HomelandItemSystem:HasSameCategoryItemResearching(nItemTemplateId) then
        UIUtils.ShowToastWithKey("HOME_RESEARCH_FAILED_SHIP_WEAPON_RESEARCHING")
    else
        ShowCommitDialog(self, nItemTemplateId)
    end
end

local function ShowLockState(self, nGrade)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnYes:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.hboxTotalTime:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxMoney:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxNeedLv:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.ktxtNeed:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxTime:SetVisibility(ESlateVisibility.Collapsed)

    pWidgetRef.kmtxtNeedGrade:SetText("Lv."..nGrade)
    pWidgetRef.btnYes:SetIsEnabled(false)
end

local function ShowAlreadyOwned(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnYes:SetVisibility(ESlateVisibility.Hidden)
    pWidgetRef.hboxTotalTime:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxMoney:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxNeedLv:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ktxtNeed:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.hboxTime:SetVisibility(ESlateVisibility.Collapsed)
end

local function ShowTimer(self, nRemainSeconds)
    local PRECISION = 2
    local pWidget = self.pWidgetRef
    pWidget.kmtimerCountDown.MinTimeUnit = EMinTimeUnit.Second
    pWidget.kmtimerCountDown:SetPrecision(PRECISION)
    local DELAY_TIME = 1
    local TIMEFORMAT = {
        L10N:ToString(UITextDef.UI_LANDMARK_UPGRADE_COUNT_DOWN_MINUTE),
        L10N:ToString(UITextDef.UI_LANDMARK_UPGRADE_COUNT_DOWN_SECOND),
    }
    pWidget.kmtimerCountDown:StartTimer(nRemainSeconds, DELAY_TIME, TIMEFORMAT, EMinTimeUnit.Second)
end

local function ShowIsResearching(self, nCompleteTime)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnYes:SetVisibility(ESlateVisibility.Hidden)
    pWidgetRef.hboxTotalTime:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxMoney:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxNeedLv:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ktxtNeed:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxTime:SetVisibility(ESlateVisibility.HitTestInvisible)

    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nRemainSeconds = nCompleteTime - now
    ShowTimer(self, nRemainSeconds)
end

local function ShowCanResearch(self, tbItemResearchTemplate)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnYes:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.hboxTotalTime:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.hboxMoney:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.hboxNeedLv:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ktxtNeed:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxTime:SetVisibility(ESlateVisibility.Collapsed)

    local nCurrencyId = tbItemResearchTemplate.nCurrencyId
    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgCurrency, szCurrencySmallIcon:load())
    local nCurrencyCost = tbItemResearchTemplate.nCurrencyCost
    pWidgetRef.txtCurrency:SetText(nCurrencyCost)
    local nCurrentCount = CurrencySystem:GetCurrencyCount(nCurrencyId)
    if nCurrentCount >= nCurrencyCost then
        pWidgetRef.txtCurrency:SetColorAndOpacity(UIResourceDef.COLOR.YELLOW.SLATE_COLOR)
        pWidgetRef.btnYes:SetIsEnabled(true)
    else
        pWidgetRef.txtCurrency:SetColorAndOpacity(UIResourceDef.COLOR.RED.SLATE_COLOR)
        pWidgetRef.btnYes:SetIsEnabled(false)
    end
    local nTimeCost = tbItemResearchTemplate.nTimeCost
    if nTimeCost > 0 then
        local szTime = TimeUtil.GetTimeString(nTimeCost)
        pWidgetRef.kmtxtTotalTime:SetText(szTime)
    else
        pWidgetRef.hboxTotalTime:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function RefreshBtnActivateState(self, tbTemplate)
    local nTemplateId = tbTemplate.nId
    local tbItemResearchTemplate = ItemResearchDataTable:GetTemplate(nTemplateId)
    local nUnlockLandmarkType = tbItemResearchTemplate.nUnlockLandmarkType
    local nUnlockLandmarkGrade = tbItemResearchTemplate.nUnlockLandmarkGrade
    local nCurrentGrade = HomelandSystem:GetLandmarkGrade(nUnlockLandmarkType)
    if ItemSystem:GetItemCount(nTemplateId) > 0 then
        ShowAlreadyOwned(self)
    else
        if nCurrentGrade < nUnlockLandmarkGrade then
            ShowLockState(self, nUnlockLandmarkGrade)
        else
            local HomelandItemSystem = GetHomelandItemSystem()
            local tbResearchingItemData = HomelandItemSystem:GetResearchingItemData(nTemplateId)
            if tbResearchingItemData ~= nil then
                ShowIsResearching(self, tbResearchingItemData.nCompleteTime)
            else
                ShowCanResearch(self, tbItemResearchTemplate)
            end
        end
    end
end

local function RefreshItemName(self, szTitle)
    self.pWidgetRef.txtItemName:SetText(szTitle)
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
    local pGridSlot = pWidgetRef.gridPanelShipWeapon:AddChildToGrid(pTextBlock, 0, 0)
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

local function RefreshgridPanelShipWeapon(self, tbDatas)
    ClearGridPanels(self)
    FillGridPanels(self, tbDatas)
end

local function RefreshDamage(self, nDamage)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtAttack:SetText(nDamage)
end

local function RefreshShipWeaponDesc(self, szDesc)
    self.pWidgetRef.ktxtShipWeaponContent:SetText(szDesc)
end

local function ShowWeaponDetail(self, tbTemplate)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.vboxShipWeaponContent:SetVisibility(ESlateVisibility.HitTestInvisible)

    local tbTipsData = BuildShipWeaponTipsContentHelper.GetTipsData(tbTemplate.nBattleItemId)
    RefreshItemName(self, tbTipsData.szTitle)
    RefreshDamage(self, tbTipsData.nDamage)
    RefreshShipWeaponDesc(self, tbTipsData.szDesc)
    RefreshgridPanelShipWeapon(self, tbTipsData.tbDatas)

    RefreshBtnActivateState(self, tbTemplate)
end

local function SetChooseData(self, nSlot)
    local nCurrentStatus = self.nCurrentStatus
    if nCurrentStatus == STATUS_CLICK_OPEN then
        self.pWidgetRef["kmtxtState"..nSlot]:SetText(UITextDef.UI_HOMELAND_RESEARCH_OPEN)
        self.pWidgetRef["btnWeaponSlot"..nSlot]:SetVisibility(ESlateVisibility.Visible)
    elseif nCurrentStatus == STATUS_CLICK_CLOSE then
        if self.nCurrentSlot ~= nSlot then
            self.pWidgetRef["btnWeaponSlot"..nSlot]:SetVisibility(ESlateVisibility.Collapsed)
        else
            self.pWidgetRef["kmtxtState"..nSlot]:SetText(UITextDef.UI_HOMELAND_RESEARCH_CLOSE)
            self.pWidgetRef["btnWeaponSlot"..nSlot]:SetVisibility(ESlateVisibility.Visible)
        end
    end
end

local function CollapsedDetail(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrAtt:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.listWeapon:SetVisibility(ESlateVisibility.Collapsed)
end

local function ShowDetail(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrAtt:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.listWeapon:SetVisibility(ESlateVisibility.Visible)

    self.ListHelper:SetData(self.tbTemplateData[self.nCurrentSlot])
    self.ListHelper:SetSelectedIndex(DEFAULT_CHOOSE_INDEX)
end

local function RefreshChooseDatas(self)
    for i = 1, SLOT_MAX do
        SetChooseData(self, i)
    end
    local nCurrentStatus = self.nCurrentStatus

    if nCurrentStatus == STATUS_CLICK_OPEN then
        CollapsedDetail(self)
    elseif nCurrentStatus == STATUS_CLICK_CLOSE then
        ShowDetail(self)
    end
end

local function ChangeStatus(self, nStatus, nSlot)
    self.nCurrentStatus = nStatus
    self.nCurrentSlot = nSlot
end

local function PlayOpenAnimation(self)
    self.Owner:PlayAnimation(ANIM_NAME, 0, 1, EUMGSequencePlayMode.Forward, 1)
end

local function PlayCloseAnimation(self)
    self.Owner:PlayAnimation(ANIM_NAME, 0, 1, EUMGSequencePlayMode.Reverse, 1)
end

local function OnClickButton(self, nSlot)
    local nCurrentStatus = self.nCurrentStatus
    if nCurrentStatus == STATUS_CLICK_OPEN then
        ChangeStatus(self, STATUS_CLICK_CLOSE, nSlot)
        PlayOpenAnimation(self)
    elseif nCurrentStatus == STATUS_CLICK_CLOSE then
        ChangeStatus(self, STATUS_CLICK_OPEN)
        PlayCloseAnimation(self)
    end

    RefreshChooseDatas(self)
end

-- 选中的武器发生变化
local function OnSelectedWeaponItemChanged(self, pbWeaponItem, _)
    -- 先取消选中之前选中项
    local pbSelectedItem = self.ListHelper.tbExtraDatas.pbSelectedItem
    if pbSelectedItem == pbWeaponItem then
        return
    end
    if pbSelectedItem then
        pbSelectedItem:UnselectItem()
    end

    pbSelectedItem = pbWeaponItem
    -- 选中当前项
    pbSelectedItem:SelectItem()
    ShowWeaponDetail(self, pbSelectedItem:GetWeaponTemplate())

    self.ListHelper.tbExtraDatas.pbSelectedItem = pbSelectedItem

    -- 记录当前选中的ID
    local nSelectedItemId = pbSelectedItem and pbSelectedItem:GetWeaponId()
    self.tbSelectedWeaponIds[self.nCurrentSlot] = nSelectedItemId
    self.ListHelper.tbExtraDatas.nSelectedItemId = nSelectedItemId
end

local function OnHomeItemResearchBegin(self, nTemplateId)
    local nCurrentStatus = self.nCurrentStatus
    if nCurrentStatus == STATUS_CLICK_CLOSE then
        if self.ListHelper.tbExtraDatas.nSelectedItemId == nTemplateId then
            local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
            RefreshBtnActivateState(self, tbTemplate)
        end
    end
end

local function OnHomeItemResearchComplete(self, nTemplateId)
    local nCurrentStatus = self.nCurrentStatus
    if nCurrentStatus == STATUS_CLICK_CLOSE then
        if self.ListHelper.tbExtraDatas.nSelectedItemId == nTemplateId then
            local tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
            RefreshBtnActivateState(self, tbTemplate)
        end
    end
end

-- 初始化武器分类相关数据
local function InitWeaponData(self)
    local tbTemplateData = {}
    for _, tbTemplate in pairs(ShipWeaponCategoryDataTable:GetTemplates()) do
        local nWeaponSlot = tbTemplate.nWeaponSlot
        tbTemplateData[nWeaponSlot] = tbTemplateData[nWeaponSlot] or {}
        if tbTemplate.bDisplayOnLobby then
            table.insert(tbTemplateData[nWeaponSlot], tbTemplate)
        end
    end
    for i, v in ipairs(tbTemplateData) do
        table.sort(v, function(A, B) return A.nCategory < B.nCategory end)
    end
    self.tbTemplateData = tbTemplateData
end

----------------------------------------------------------------------------
-- Weapon Item Pool Logic
----------------------------------------------------------------------------
-- 分配一个武器PrefabItem
local function AllocWeaponItem(self)
    local tbWeaponItemPool = self.tbWeaponItemPool
    local nLength = #tbWeaponItemPool
    local pbWeaponItem = tbWeaponItemPool[nLength]
    if pbWeaponItem then
        table.remove(tbWeaponItemPool, nLength)
    else
        pbWeaponItem = self.PrefabHelper:CreatePrefab(UIDef.UP_HOME_SHIP_WEAPON_ITEM)
        pbWeaponItem:SetOnClickedItemCallback(function(bClicked) OnSelectedWeaponItemChanged(self, pbWeaponItem, bClicked) end)
    end
    return pbWeaponItem
end

-- 回收一个武器PrefabItem
local function RecycleWeaponItem(self, pbWeaponItem)
    table.insert(self.tbWeaponItemPool, pbWeaponItem)
end

----------------------------------------------------------------------------
-- Lifecyle Logic
----------------------------------------------------------------------------

function ULHomeShipWeaponResearchChoose:OnShow()
    self.nCurrentStatus = STATUS_CLICK_OPEN
    RefreshChooseDatas(self)
    PlayCloseAnimation(self)
end

function ULHomeShipWeaponResearchChoose:OnLoad()
    InitWeaponData(self)
    self.tbWeaponItemPool = {}
    self.tbSelectedWeaponIds = {}

    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.listWeapon)
    self.ListHelper.tbExtraDatas.nSelectedItemId = nil
    self.ListHelper.tbExtraDatas.pbSelectedItem = nil
    self.ListHelper.tbExtraDatas.fnAllocWeaponItem = function()
        return AllocWeaponItem(self)
    end
    self.ListHelper.tbExtraDatas.fnRecycleWeaponItem = function(pbWeaponItem)
        return RecycleWeaponItem(self, pbWeaponItem)
    end
end

function ULHomeShipWeaponResearchChoose:OnBindEvent(EventHelper)
    for i = 1, SLOT_MAX do
        EventHelper:RegisterCppDelegate(self.pWidgetRef["btnWeaponSlot"..i].OnClicked, self, function() OnClickButton(self, i) end)
    end
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnYes.OnClicked, self, OnClickResearch)

    EventHelper:RegisterEvent(ClientEventDef.EV_HOME_ITEM_RESEARCH_BEGIN, self, OnHomeItemResearchBegin)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOME_ITEM_RESEARCH_COMPLETE, self, OnHomeItemResearchComplete)
end

function ULHomeShipWeaponResearchChoose:OnUnload()
    self.ListHelper:Uninit()
end

return ULHomeShipWeaponResearchChoose