local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbySailorEquipping = luaclass("UILobbySailorEquipping", WndBase)
local ClientEventDef = require("ClientEventDef")
local UILobbySailorDef = require("UILobbySailorDef")
local SailorCategoryDef = require("SailorCategoryDef")
local PropertyComboSystem = require("PropertyComboSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local SailorSlotDataTable = require("SailorSlotDataTable")
local PropertyComboDataTable = require("PropertyComboDataTable")
local SelfTabBarHelper = require("SelfTabBarHelper")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local Timer = require("Timer")
local UIUtils = require("UIUtils")
local UIDef = require("UIDef")
local CostCurrencyHelper = require("CostCurrencyHelper")

local EQUIP_DEFAULT = 1
local DEFAULT_INDEX = 1
local INVALID_ID = -1
local tbTabAnim = {"animCanon","animDeck", "animLogistics"}
local tbCvsWidget = {"cvsCanon", "cvsDeck", "cvsLogistics"}
local DELAY_IN_TOTAL_INFO = "DelayInTime2"
local SHOW_HIDE_TOUCH = "HideTouchTimer"

local szAnimTotalIn = "anim_TotalInfoIn"
local szAnimCanon = "animCanon"
local szAnimSailorEquippingIn = "anim_LobbySailorEquippingIn"
local szLevelUp5Loop = "anim_LevelUp05Loop"
local szLevelUp5In = "anim_LevelUp05In"
local szLevelUp01In = "anim_LevelUp01In"
local szEquipBoxIn = "anim_SailorEquipBoxIn"

UILobbySailorEquipping.tbULLogic = nil
UILobbySailorEquipping.nTotalGrade = 0
UILobbySailorEquipping.bTopGradeDisabled = false
UILobbySailorEquipping.nRemainOneKeyEquipCount = 0
UILobbySailorEquipping.tbOneKeyEquipWaitList = nil
UILobbySailorEquipping.tbOneKeyEquipDelayTimer = nil
UILobbySailorEquipping.pbSelectedSailorSlot = nil
UILobbySailorEquipping.ulEquipLevelUp = nil
UILobbySailorEquipping.nSelectCategory = -1
UILobbySailorEquipping.bShowTotal = false
UILobbySailorEquipping.tbTabBarHelper = nil
UILobbySailorEquipping.pbWindowFrame = nil
UILobbySailorEquipping.bLevelUp = false

local function LOG(...)
    log("[UILObbySailorEquipping]", ...)
end

local function GetSailorComponent()
    local tbPlayer = GamePlayerSelfHelper:Get()
    return tbPlayer and tbPlayer.SailorComponent
end



local function InitLogic(self)
    local UILogicHelper = self.UILogicHelper

    self.tbULLogic = {}
    for i = 1, SailorCategoryDef.MAX_COUNT do
        self.tbULLogic[i] = UILogicHelper:CreateUILogic(UILobbySailorDef.EquippingLogic[i])
        self.tbULLogic[i]:InitSlots()
    end
    self.ulEquipLevelUp = UILogicHelper:CreateUILogic("ULSailorEquippingLevelUp")
end

local function SetTotalInfoVisible(self, bShow)
    if self.bShowTotal ~= bShow then
        self.bShowTotal = bShow
        self.pWidgetRef.bdrTotalInfo:SetVisibility(bShow and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
        self.pWidgetRef.hbSailorEquipBox:SetVisibility( ESlateVisibility.SelfHitTestInvisible)
        if bShow then
            self:PlayAnimation(szEquipBoxIn, 0, 1, EUMGSequencePlayMode.Reverse, 1)
        else
            self:PlayAnimation(szEquipBoxIn, 0, 1, EUMGSequencePlayMode.Forward, 1)
        end
    end
end

local function InitSlotsUnlockInfo(self, nSelectCategory)
    -- for i = 1, SailorCategoryDef.MAX_COUNT do
        self.tbULLogic[nSelectCategory]:InitSlotsUnlockInfo()
    --end
    self:UpdateTotalInfo()
end

local function InitSlotsLockInfo(self, nSelectCategory)
    -- for i = 1, SailorCategoryDef.MAX_COUNT do
        self.tbULLogic[nSelectCategory]:InitSlotsLockInfo()
    -- end
end

local function UnselecteSlotItem(self)
    LOG(" UnselecteSlotItem")
    if self.pbSelectedSailorSlot then
        self.pbSelectedSailorSlot:Unselect()
        self.pbSelectedSailorSlot = nil
    end
end

-- 返回默认的水手详细界面
local function ReturnTotalInfoTab(self)
    LOG(" ReturnTotalInfoTab")
    SetTotalInfoVisible(self, true)
    self:UpdateTotalInfo()
    self.tbBagListHelper:UnselectCurrentItem()
    self.tbBagListHelper:ScrollToTop()
    UnselecteSlotItem(self)
end

local function OnSelectEquipTab(self, nIndex)
    if self.nSelectCategory == nIndex then
        return
    end
    local pWidgetRef = self.pWidgetRef
    for i = 1, SailorCategoryDef.MAX_COUNT do
        if nIndex == i then
            self.nSelectCategory = nIndex
            --pWidgetRef[tbEquipTabName[i]]:SetCheckedState(ECheckBoxState.Checked)
            pWidgetRef[tbCvsWidget[i]]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            self.tbULLogic[i]:Activate()
        else
            --pWidgetRef[tbEquipTabName[i]]:SetCheckedState(ECheckBoxState.Unchecked)
            pWidgetRef[tbCvsWidget[i]]:SetVisibility(ESlateVisibility.Collapsed)
            self.tbULLogic[i]:Deactivate()
        end
    end
    self.pWidgetRef.hbSailorEquipBox:SetVisibility( ESlateVisibility.Collapsed )
    self:PlayAnimation(tbTabAnim[self.nSelectCategory], 0, 1, EUMGSequencePlayMode.Forward, 1)
    InitSlotsUnlockInfo(self, self.nSelectCategory)
    InitSlotsLockInfo(self, self.nSelectCategory)
    ReturnTotalInfoTab(self)
    -- self:UpdateTotalInfo()
end

local function SetRedDotVisible(self, nIndex, bRedVisible)
    self.tbTabBarHelper:SetTipIconVisible(nIndex, bRedVisible)
end

local function RefreshRedDotVisible(self)
    local SailorComponent = GamePlayerSelfHelper:Get().SailorComponent
    local tbSlotInfos = SailorComponent:GetSailorSlotInfo()
    for nCategory, tbSlotInfoList in ipairs(tbSlotInfos) do
        local bVisible = false
        for nIndex, tbSlotInfo in pairs(tbSlotInfoList) do
            if tbSlotInfo.bUnlocked and (tbSlotInfo.nSailorId == nil) then
                bVisible = true
                break
            end
        end
        SetRedDotVisible(self, nCategory, bVisible)
    end
end

local function OnRedDotVisibleChanged(self)
    RefreshRedDotVisible(self)
end

local function OnClickedEquipSuit(self, nSuitId)
    GetSailorComponent():RequestSailorEquipOneKey(nSuitId)
end

local function IsInEquipOneKey(self)
    return self.nRemainOneKeyEquipCount > 0
end

local function OnReceiveSailorUnequipAllResult(self)
    for i = 1, SailorCategoryDef.MAX_COUNT do
        self.tbULLogic[i]:EmptySailorItem()
    end

    if IsInEquipOneKey(self) and (GetSailorComponent().nOneKeyEquipDelayTime == 0) then
        return
    end
    SetTotalInfoVisible(self, true)
    self:UpdateTotalInfo()
    RefreshRedDotVisible(self)
end

local function OnReceiveSailorUnequipPartResult(self, nSubCategory)
    if nSubCategory == self.nSelectCategory then
        self.tbULLogic[self.nSelectCategory]:EmptySailorItem()
    end

    if IsInEquipOneKey(self) and (GetSailorComponent().nOneKeyEquipDelayTime == 0) then
        return
    end
    SetTotalInfoVisible(self, true)
    self:UpdateTotalInfo()
    RefreshRedDotVisible(self)
end
-- 请求装备/替换水手
local function RequestSailorEquip(self, nCategory, nSlotIndex, nSailorId)
    GetSailorComponent():RequestSailorEquip(nCategory, nSlotIndex, nSailorId)
end

local function OneKeyEquipSailorStarted(self)
    local nUnlockedSailorSlotCount = 0
    local tbSlotInfos = GetSailorComponent():GetSailorSlotInfo()
    for nCategory, tbSlotInfoList in ipairs(tbSlotInfos) do
        for nIndex, tbSlotInfo in pairs(tbSlotInfoList) do
            if tbSlotInfo.bUnlocked then
                nUnlockedSailorSlotCount = nUnlockedSailorSlotCount + 1
            end
        end
    end
    LOG("one key equip started, count =", nUnlockedSailorSlotCount)
    self.nRemainOneKeyEquipCount = nUnlockedSailorSlotCount
    self.tbOneKeyEquipWaitList = {}
    UIManager:OpenWnd(UIDef.UI_FULLSCREEN_MASK)
end

local function OneKeyEquipSailorEnded(self, bExit)
    LOG("one key equip ended")
    self.nRemainOneKeyEquipCount = 0
    self.tbOneKeyEquipWaitList = nil
    self.TimerHelper:ClearTimer(self.tbOneKeyEquipDelayTimer)
    self.tbOneKeyEquipDelayTimer = nil
    if not bExit then
        SetTotalInfoVisible(self, true)
        self:UpdateTotalInfo()
    end
    UIManager:CloseWnd(UIDef.UI_FULLSCREEN_MASK)
end

local function OnceOneKeyEquipSucceeded(self)
    self.nRemainOneKeyEquipCount = self.nRemainOneKeyEquipCount - 1
    LOG("once one key equip, remain:", self.nRemainOneKeyEquipCount)
    if self.nRemainOneKeyEquipCount <= 0 then
        OneKeyEquipSailorEnded(self)
    end
end

-- 展示下一个一键装备的水手
local function DisplayNextOneKeyEquipSailor(self)
    LOG("display next one key equip sailor")
    self.tbOneKeyEquipDelayTimer = nil
    if #self.tbOneKeyEquipWaitList > 0 then
        local tbSailorComponent = GetSailorComponent()
        local tbOneKeyEquipInfo = self.tbOneKeyEquipWaitList[1]
        self.tbULLogic[tbOneKeyEquipInfo.nSailorType]:SetSailorId(tbOneKeyEquipInfo.nSailorType, tbOneKeyEquipInfo.nSlotIndex,
            tbOneKeyEquipInfo.nEquippedSailorId, tbSailorComponent.bOneKeyEquipWithAnim)

        if self.nSelectCategory == tbOneKeyEquipInfo.nSailorType then
            self.tbULLogic[tbOneKeyEquipInfo.nSailorType]:PlayAddItemAnim(tbOneKeyEquipInfo.nSailorType, tbOneKeyEquipInfo.nSlotIndex)
        end
        table.remove(self.tbOneKeyEquipWaitList, 1)
        OnceOneKeyEquipSucceeded(self)
        if IsInEquipOneKey(self) then
            if tbSailorComponent.nOneKeyEquipDelayTime > 0 then
                self.tbOneKeyEquipDelayTimer = self.TimerHelper:NewDelayRunTimerMethod(self, DisplayNextOneKeyEquipSailor, tbSailorComponent.nOneKeyEquipDelayTime)
            else
                DisplayNextOneKeyEquipSailor(self)
            end
        end
        RefreshRedDotVisible(self)
    end
end

-- 显示右侧背包列表
local function ShowSailorMiniBag(self, nSailorId)
    if not self.pbSelectedSailorSlot then  
        return
    end
    SetTotalInfoVisible(self, false)
    local nSailorType = self.pbSelectedSailorSlot:GetSailorCategory()
    local tbBagListData = GetSailorComponent():GetSailorListByType(nSailorType, nSailorId)
    if nSailorId ~= nil then
        local nRemoveIndex = -1
        for i, v in ipairs(tbBagListData) do
            if nSailorId == v.nSailorId then
                nRemoveIndex = i
                break
            end
        end
        if nRemoveIndex ~= -1 then
            local tbReLocItem = table.remove(tbBagListData, nRemoveIndex)
            if tbReLocItem.tbTemplate.nGrade ~= UILobbySailorDef.MAX_GRADE then
                tbReLocItem.bCanLevelUp = true
            else 
                tbReLocItem.bCanReset = true
            end
            table.insert(tbBagListData, 1, tbReLocItem)
        end
    end
    self.tbBagListHelper:SetData(tbBagListData)
    if nSailorId ~= nil then
        self.tbBagListHelper:SetSelectedIndex(DEFAULT_INDEX)
        self.tbBagListHelper:ScrollToTop()
    else
        self.tbBagListHelper:UnselectCurrentItem()
    end
end

local function OnSailorSlotSelected(self, pbSailorSlot)
    LOG("[UPSailorEquipping] OnSailorSlotSelected")
    UnselecteSlotItem(self)
    self.pbSelectedSailorSlot = pbSailorSlot
    self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_CLICK_BORDER) --引导专用，由于mousebtuuondowneven不支持多个代理，所以只能在此FireEvent以达到通知引导此bdr被点击的目的
    local nSailorId = pbSailorSlot:GetSailorId()
    if nSailorId then
        --显示列表，显示选中在第一个
        ShowSailorMiniBag(self, nSailorId)
    else
        --显示所有列表
        ShowSailorMiniBag(self)
    end
end

-- 水手背包列表选中状态
local function OnMiniBagSelectedChanged(self, nIndex)
    local tbSelectedData = self.tbBagListHelper:GetSelectedData()
    if tbSelectedData then
        if not self.pbSelectedSailorSlot then
            -- logerror("cannot find pbSelectedSailorSlot?", nIndex, t2s(tbSelectedData))
            ReturnTotalInfoTab(self)
            return
        end

        if self.pbSelectedSailorSlot:GetSailorId() == tbSelectedData.nSailorId then
            return
        end
        --1.空槽可装备 2.不是空槽那么直接请求替换 selectedSailorSlot
        local nSailorCategory = self.pbSelectedSailorSlot:GetSailorCategory()
        local nSailorSlot = self.pbSelectedSailorSlot:GetSlotIndex()
        RequestSailorEquip(self,nSailorCategory, nSailorSlot, tbSelectedData.nSailorId)
    end
end

-- 尝试自动选中下一个空槽
local function TryToSelectNextEmptySlot(self, nCurrentSailorCategory)
    -- 取消当前选择
    self.tbBagListHelper:UnselectCurrentItem()
    -- 优先选择同类型槽位
    local nFreeSailorCount = #GetSailorComponent():GetFreeSailorListByType(nCurrentSailorCategory)
    if nFreeSailorCount > 0 then
        local pSailorSlot = self.tbULLogic[nCurrentSailorCategory]:GetEmptyUnlockSlot()
        if pSailorSlot then
            pSailorSlot:Select()
            return true
        end
    end
    return false
end

-- 处理装备/替换水手逻辑
local function OnReceiveSailorEquipResult(self, nSailorType, nSlotIndex, nEquippedSailorId, nUnequippedSailorId)
    LOG("OnReceiveSailorEquipResult", IsInEquipOneKey(self))
    if IsInEquipOneKey(self) then
        table.insert(self.tbOneKeyEquipWaitList, {
            nSailorType = nSailorType,
            nSlotIndex = nSlotIndex,
            nEquippedSailorId = nEquippedSailorId
        })
        LOG("inert data to tbOneKeyEquipWaitList")
        if not self.tbOneKeyEquipDelayTimer then
            DisplayNextOneKeyEquipSailor(self)
        end
    else
        self.tbULLogic[nSailorType]:SetSailorId(nSailorType, nSlotIndex, nEquippedSailorId, true)
        if nUnequippedSailorId == INVALID_ID then
            local bSelectNewEmpty = TryToSelectNextEmptySlot(self, nSailorType)
            if not bSelectNewEmpty then
                --不管是 替换还是空的直接镶嵌 ，结束之后都直接显示所有
                ReturnTotalInfoTab(self)
                -- ShowSailorMiniBag(self, nEquippedSailorId)
            end
        else
            ReturnTotalInfoTab(self)
            -- ShowSailorMiniBag(self, nEquippedSailorId)
        end
        self.tbULLogic[nSailorType]:PlayAddItemAnim(nSailorType, nSlotIndex)
        RefreshRedDotVisible(self)
    end
end

local function OnReceiveUnlockSailorSlotResult(self, bResult, nSailorType, nSlotIndex)
    if bResult then
        self.tbULLogic[nSailorType]:Unlock(nSlotIndex)
        InitSlotsUnlockInfo(self, self.nSelectCategory)
        InitSlotsLockInfo(self, self.nSelectCategory)
        RefreshRedDotVisible(self)
    else
        UIUtils.ShowToastWithKey("SAILOR_SLOT_UNLOCK_FAILED")
    end
end

local function OnClickedBtnUnequipAll(self)
    GetSailorComponent():RequestSailorUnequipCategory(self.nSelectCategory)
end

local function HideTouchInSeconds(self, nSec, bForward)
    local pWidgetRef = self.pWidgetRef
    if pWidgetRef then
        pWidgetRef.bdrForbiddenTouch:SetVisibility(ESlateVisibility.Visible)
        if not bForward then
            pWidgetRef[tbCvsWidget[self.nSelectCategory]]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    end
    Timer.StartOwnerTimer(self, SHOW_HIDE_TOUCH, function()
        if self.pWidgetRef then
            self.pWidgetRef.bdrForbiddenTouch:SetVisibility(ESlateVisibility.Collapsed)
            if bForward then
                for i = 1, SailorCategoryDef.MAX_COUNT do
                    self.pWidgetRef[tbCvsWidget[i]]:SetVisibility(ESlateVisibility.Collapsed)
                end
            end
        end
    end, nSec, false)
end

local function OnLevelUpToMain(self)
    self.bLevelUp = false
    self:ShowEquipMain()
    self.pbWindowFrame:SetBackIsCloseSelf(false)
end

local function OnClickedBtnUpLevelAll(self)
    self.bLevelUp = true
    self.ulEquipLevelUp:SetSailorCategory(self.nSelectCategory)
    self.ulEquipLevelUp:ShowOneKeyLevelUp()
    self.pWidgetRef.vbTotalInfo:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(szLevelUp5Loop, 0, 0, EUMGSequencePlayMode.Forward, 1)
    self:PlayAnimation(szLevelUp5In, 0, 1, EUMGSequencePlayMode.Forward, 1)
    HideTouchInSeconds(self, 1, true)
end

local function OnClickedBtnUpLevelSingleInfo(self, tbData)
    if self.pbSelectedSailorSlot then 
        self.bLevelUp = true
        local nSailorId = self.pbSelectedSailorSlot:GetSailorId()
        local nSailorCategory = self.pbSelectedSailorSlot:GetSailorCategory()
        local nSlotIndex = self.pbSelectedSailorSlot:GetSlotIndex()

        self.ulEquipLevelUp:SetSailorCategory(nSailorCategory)
        self.ulEquipLevelUp:SetSlotIndex(nSlotIndex)
        self.ulEquipLevelUp:SetSailorId(nSailorId)
        self.ulEquipLevelUp:ShowLevelUpOneSailor()
        self.pWidgetRef.vbSingleInfo:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.pWidgetRef.bdrTotalInfo:SetVisibility(ESlateVisibility.Collapsed)
        self:PlayAnimation(szLevelUp01In, 0, 1, EUMGSequencePlayMode.Forward, 1)
        HideTouchInSeconds(self, 1, true)
    end
end

local function BackToPre(self)
    if self.bLevelUp then
        OnLevelUpToMain(self)
    else
        self.EventHelper:FireEvent(ClientEventDef.EV_LOBBYSAILOR_TO_PRE)
        self.pbWindowFrame:SetBackIsCloseSelf(true)
    end
end

local function OnReceiveUpgradeEquippedSailorResult(self, tbUpgradedSailorInfos, bOneKeyUpgrade)
    --一键升级
    if bOneKeyUpgrade then
        SetTotalInfoVisible(self, true)
        InitSlotsUnlockInfo(self, self.nSelectCategory)
        UnselecteSlotItem(self)
    else
        local tbUpgradedInfo = tbUpgradedSailorInfos[1]
        --init slots之后，以为已经刷成 升级之后的slot的了，所以 pbSelectedSailorSlot是升级之后的
        InitSlotsUnlockInfo(self, self.nSelectCategory)
        if self.pbSelectedSailorSlot and (tbUpgradedInfo.nUpgradeTo == self.pbSelectedSailorSlot:GetSailorId()) then
            ShowSailorMiniBag(self, tbUpgradedInfo.nUpgradeTo)
        end
    end
end

local function OnReceiveSailorDegradeResult(self, nSailorId, nDegradedSailorId)
    --init slots之后，以为已经刷成 升级之后的slot的了，所以 pbSelectedSailorSlot是升级之后的
    InitSlotsUnlockInfo(self, self.nSelectCategory)
    if self.pbSelectedSailorSlot and (nDegradedSailorId == self.pbSelectedSailorSlot:GetSailorId()) then
        ShowSailorMiniBag(self, nDegradedSailorId)
    end
end

local function OnDisableClickedBtnUnequipAll(self)
    UIUtils.ShowToastWithKey("SAILOR_UNEQUIP_ALL_DISABLED")
end

local function OnDisableClickedBtnUpLevelAll(self)
    if self.bTopGradeDisabled then
        UIUtils.ShowToastWithKey("SAILOR_TOP_GRADE")
    else
        UIUtils.ShowToastWithKey("SAILOR_UP_LEVEL_ALL_DISABLED")
    end
end

local function RefreshTotalComboStrColorForCurrentCategory(self, tbPropertiesData)
    local tbEquippedSailors = GetSailorComponent():GetSailorEquippedData()
    local tbComboKeys = {}
    for nSailorId, nCount in pairs(tbEquippedSailors) do
        if nCount > 0 then
            local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
            if tbTemplate.nSubCategory == self.nSelectCategory then
                local nComboId = tbTemplate.nPropertyComboId
                local tbComboTemplate = PropertyComboDataTable:GetTemplate(nComboId)
                if tbComboTemplate then
                    for szKey, tbProperty in pairs(tbComboTemplate.tbProperties) do
                        table.insert(tbComboKeys, szKey)
                    end
                end
            end
        end
    end
    for _, v in ipairs(tbPropertiesData) do
        local szCurKey = v.szKey
        v.bHasColor = false
        for _, szKey in ipairs(tbComboKeys) do
            if szCurKey == szKey then
                v.bHasColor = true
                break
            end
        end
    end
end

function UILobbySailorEquipping:ShowEquipMain()
    local pWidgetRef = self.pWidgetRef
    if pWidgetRef then
        self:StopAnimation("animLevelUpLoop")
        pWidgetRef.cpEquipMain:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.UpgradeBox:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hbLevelUpTo5:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hbREset:SetVisibility(ESlateVisibility.Collapsed)
        if self.ulEquipLevelUp.bOneKeyLevelUp then  
            pWidgetRef.vbTotalInfo:SetVisibility(ESlateVisibility.Collapsed)
            self:PlayAnimation(szLevelUp5In, 0, 1, EUMGSequencePlayMode.Reverse, 1)
        else
            pWidgetRef.vbSingleInfo:SetVisibility(ESlateVisibility.Collapsed)
            self:PlayAnimation(szLevelUp01In, 0, 1, EUMGSequencePlayMode.Reverse, 1)
        end
        HideTouchInSeconds(self, 1, false)
    end
end

function UILobbySailorEquipping:UpdateTotalInfo()

    local nTotalCount = 0
    local nTotalGrade = 0
    local nTotalCountCurCategory = 0
    local nTotalGradeCurCategory = 0
    local tbComboIdWithCountMap = {}
    local tbSailorEquippedData = GetSailorComponent():GetSailorEquippedData()
    for nSailorId, nCount in pairs(tbSailorEquippedData) do
        if nCount > 0 then
            local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
            if tbTemplate.nSubCategory == self.nSelectCategory then
                nTotalGradeCurCategory = nTotalGradeCurCategory + (tbTemplate.nGrade + 1) * nCount
                nTotalCountCurCategory = nTotalCountCurCategory + nCount
            end
            nTotalCount = nTotalCount + nCount
            nTotalGrade = nTotalGrade + (tbTemplate.nGrade + 1) * nCount
            local nCurrentCount = tbComboIdWithCountMap[tbTemplate.nPropertyComboId] or 0
            tbComboIdWithCountMap[tbTemplate.nPropertyComboId] = nCurrentCount + nCount
        end
    end
    self.pWidgetRef.txtTotalGrade:SetText(nTotalGrade)
    if nTotalGrade > 0 then
        local tbPropertiesData = PropertyComboSystem:GetMultiPropertyComboDisplayInfoList(tbComboIdWithCountMap)
        RefreshTotalComboStrColorForCurrentCategory(self, tbPropertiesData)
        self.tbTotalPropertyListHelper:SetData(tbPropertiesData)
        self.pWidgetRef.txtEmptyTips:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.listTotalProperties:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.txtEmptyTips:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.listTotalProperties:SetVisibility(ESlateVisibility.Collapsed)
    end

    if nTotalGradeCurCategory > 0  then
        self.pWidgetRef.btnUnequipAll:SetIsEnabled(true)
        self.pWidgetRef.btnUpLevelAll:SetIsEnabled(true)
        if nTotalGradeCurCategory > 0 and nTotalCountCurCategory * 5 == nTotalGradeCurCategory then
            self.pWidgetRef.txtUpLevelAll:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_TOP"))
            self.pWidgetRef.btnUpLevelAll:SetIsEnabled(false)
            self.bTopGradeDisabled = true
        else
            self.pWidgetRef.txtUpLevelAll:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_ALL"))
        end
    else
        self.pWidgetRef.btnUnequipAll:SetIsEnabled(false)
        self.pWidgetRef.btnUpLevelAll:SetIsEnabled(false)
        self.pWidgetRef.txtUpLevelAll:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_ALL"))
        self.bTopGradeDisabled = false
    end

    self.nTotalGrade = nTotalGrade
end

function UILobbySailorEquipping:OnLoad()
    UILobbySailorEquipping.super.OnLoad(self)

    self.bShowTotal = false
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(BackToPre, self)

    self.tbBagListHelper = SelfVerticalListHelper()
    self.tbBagListHelper:Init(self, self.pWidgetRef.listMiniBag)
    self.tbBagListHelper.OnSelectedChangedDelegate:Bind(OnMiniBagSelectedChanged, self)
    self.tbBagListHelper:SetAutoScrollEnabled(false)

    self.tbTotalPropertyListHelper = SelfVerticalListHelper()
    self.tbTotalPropertyListHelper:Init(self, self.pWidgetRef.listTotalProperties)

    --self.pCurrencyBar = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyCurrencyBar)
    self.pbWindowFrame:SetSpecialCurrency(UILobbySailorDef.CURRENCY_ID)

    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.vboxTab, EQUIP_DEFAULT)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnSelectEquipTab, self)
    InitLogic(self)
    OnSelectEquipTab(self, EQUIP_DEFAULT)
end

function UILobbySailorEquipping:OnEnter()
    UILobbySailorEquipping.super.OnEnter(self)
end

function UILobbySailorEquipping:OnExit()
    self:StopAnimation(szLevelUp5Loop)
end

local function PlayerSailorEquippingInAnim(self)
    self:StopAnimation(szAnimCanon)
    self:PlayAnimation(szAnimSailorEquippingIn, 0, 1, EUMGSequencePlayMode.Forward, 1)
    Timer.StartOwnerTimer(self, DELAY_IN_TOTAL_INFO, function()
        self:PlayAnimation(szAnimTotalIn, 0, 1, EUMGSequencePlayMode.Forward, 1)
        self:PlayAnimation(szAnimCanon, 0, 1, EUMGSequencePlayMode.Forward, 1)
    end, 0.17, false)
end

local function OnShopNotEnoughCurrency(self, bAutoExchange)
    if not bAutoExchange then
        CostCurrencyHelper:FirstCostFailed()
    else
        CostCurrencyHelper:SecondCostFailed()
    end
end

function UILobbySailorEquipping:OnShow()
    UILobbySailorEquipping.super.OnShow(self)

    self.bLevelUp = false
    --这块临时先这么写了，直接用SetTotalInfoVisible 是用动画在切换，但是onshow的时候播这个动画看着比较奇怪 强设下吧先
    self.bShowTotal = true
    self.pWidgetRef.bdrTotalInfo:SetVisibility( ESlateVisibility.SelfHitTestInvisible )
    self.pWidgetRef.hbSailorEquipBox:SetVisibility( ESlateVisibility.Collapsed )
    -- SetTotalInfoVisible(self, true)

    InitSlotsUnlockInfo(self, self.nSelectCategory)
    InitSlotsLockInfo(self, self.nSelectCategory)
    RefreshRedDotVisible(self)
    PlayerSailorEquippingInAnim(self)
end

function UILobbySailorEquipping:OnUnload()
    self.tbBagListHelper:Uninit()
    self.tbBagListHelper = nil

    Timer.StopOwnerAllTimer(self, true)
    self.tbTotalPropertyListHelper:Uninit()
    self.tbTotalPropertyListHelper = nil

    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

function UILobbySailorEquipping:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_ONE_KEY_EQUIP_SAILOR_STARTED, self, OneKeyEquipSailorStarted)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UNEQUIP_ALL_RESULT, self, OnReceiveSailorUnequipAllResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UNEQUIP_PART_RESULT, self, OnReceiveSailorUnequipPartResult)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_EQUIP_RESULT, self, OnReceiveSailorEquipResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBYSAILOR_EQUIPITEM_SELECT, self, OnSailorSlotSelected)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UNLOCK_SAILOR_SLOT_RESULT, self, OnReceiveUnlockSailorSlotResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBYSAILOR_LEVELUP_SAILOR, self, OnClickedBtnUpLevelSingleInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UPGRADE_EQUIPPED_SAILOR_RESULT, self, OnReceiveUpgradeEquippedSailorResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_DEGRADE_RESULT, self, OnReceiveSailorDegradeResult)
    

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SAILOR_RED_DOT_VISIBLE_CHANGED, self, OnRedDotVisibleChanged)

    --EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, BackToPre)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnListSeeR.OnClicked, self, ReturnTotalInfoTab)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUnequipAll.OnClicked, self, OnClickedBtnUnequipAll)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUpLevelAll.OnClicked, self, OnClickedBtnUpLevelAll)

    EventHelper:RegisterCppDelegate(pWidgetRef.btnUnequipAll.OnDisableClicked, self, OnDisableClickedBtnUnequipAll)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUpLevelAll.OnDisableClicked, self, OnDisableClickedBtnUpLevelAll)

    -- for i, v in ipairs(tbEquipTabName) do
    --     EventHelper:RegisterCppDelegate(pWidgetRef[v].OnCheckStateChanged, self, function(bChecked)
    --         OnSelectEquipTab(self, i, bChecked)
    --     end)
    -- end
    for nSuitId=1, SailorSlotDataTable.RECOMMENDED_SAILOR_SUIT_COUNT do
        EventHelper:RegisterCppDelegateFunc(pWidgetRef["btnEquipSuit"..nSuitId].OnClicked, function()
            OnClickedEquipSuit(self, nSuitId)
        end)
    end

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UNLOCK_SAILOR_SLOT_NOT_ENOUGH_MONEY, self, OnShopNotEnoughCurrency)
  
end

return UILobbySailorEquipping
