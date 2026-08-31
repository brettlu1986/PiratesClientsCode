local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSailorEquipping = luaclass("UPSailorEquipping", PrefabBase)

local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local ClientEventDef = require("ClientEventDef")
local SailorCategoryDef = require("SailorCategoryDef")
local PropertyComboSystem = require("PropertyComboSystem")
local SailorSlotDataTable = require("SailorSlotDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

-- 左侧Tab页索引
local TAB_LEFT_PANEL_DEFAULT = 0
local TAB_LEFT_PANEL_REPLACE = 1

-- 右侧侧Tab页索引
local TAB_RIGHT_PANEL_TOTAL_INFO = 0
local TAB_RIGHT_PANEL_SINGLE_INFO = 1
local TAB_RIGHT_PANEL_MINI_BAG = 2

local MAX_SAILOR_GRADE = 4
local INVALID_ID = -1
local MAX_SLOT_COUNT_PER_TYPE = 10
local SAILOR_SLOT_WIDGET_NAME = "pbSailorSlot_%d_%d"

UPSailorEquipping.nTotalGrade = 0
UPSailorEquipping.tbSailorSlots = nil
UPSailorEquipping.pbSelectedSailorSlot = nil

UPSailorEquipping.pbSailorDetailItem = nil
UPSailorEquipping.pbSailorReplaceItemLeft = nil
UPSailorEquipping.pbSailorReplaceItemRight = nil
UPSailorEquipping.bTopGradeDisabled = false

UPSailorEquipping.tbOneKeyEquipWaitList = nil
UPSailorEquipping.nRemainOneKeyEquipCount = 0
UPSailorEquipping.tbOneKeyEquipDelayTimer = nil

local function LOG(...)
    log("[UPSailorEquipping]", ...)
end

local function GetSailorComponent()
    local tbPlayer = GamePlayerSelfHelper:Get()
    return tbPlayer and tbPlayer.SailorComponent
end

local function UpdateTotalInfo(self)
    local nTotalCount = 0
    local nTotalGrade = 0
    local tbComboIdWithCountMap = {}
    local tbSailorEquippedData = GetSailorComponent():GetSailorEquippedData()
    for nSailorId, nCount in pairs(tbSailorEquippedData) do
        if nCount > 0 then
            local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
            nTotalCount = nTotalCount + nCount
            nTotalGrade = nTotalGrade + (tbTemplate.nGrade + 1) * nCount
            local nCurrentCount = tbComboIdWithCountMap[tbTemplate.nPropertyComboId] or 0
            tbComboIdWithCountMap[tbTemplate.nPropertyComboId] = nCurrentCount + nCount
        end
    end
    self.pWidgetRef.txtTotalGrade:SetText(nTotalGrade)
    if nTotalGrade > 0 then
        local tbPropertiesData = PropertyComboSystem:GetMultiPropertyComboDisplayInfoList(tbComboIdWithCountMap)
        self.tbTotalPropertyListHelper:SetData(tbPropertiesData)

        self.pWidgetRef.txtEmptyTips:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.bdrProperties:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.pWidgetRef.btnUnequipAll:SetIsEnabled(true)
        self.pWidgetRef.btnUpLevelAll:SetIsEnabled(true)
        if nTotalGrade > 0 and nTotalCount * 5 == nTotalGrade then
            self.pWidgetRef.txtUpLevelAll:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_TOP"))
            self.pWidgetRef.btnUpLevelAll:SetIsEnabled(false)
            self.bTopGradeDisabled = true
        else
            self.pWidgetRef.txtUpLevelAll:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_ALL"))
        end
    else
        self.pWidgetRef.txtEmptyTips:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.bdrProperties:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.btnUnequipAll:SetIsEnabled(false)
        self.pWidgetRef.btnUpLevelAll:SetIsEnabled(false)
        self.pWidgetRef.txtUpLevelAll:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_ALL"))
        self.bTopGradeDisabled = false
    end
    self.nTotalGrade = nTotalGrade
end

-- 刷新各槽位解锁信息
local function UpdateSlotUnlockInfo(self)
    local tbUnlockIndexList = {}
    local tbUnlockGradeList = {}
    local nMinUnlcokGrade = 999
    -- 首先需要获取到每个类型槽位下一个可解锁位置
    local tbSlotInfos = GetSailorComponent():GetSailorSlotInfo()
    for nSailorType, v in ipairs(tbSlotInfos) do
        for i,tbSlotInfo in pairs(v) do
            if tbSlotInfo.bUnlocked ~= true then
                local nUnlockGrade = SailorSlotDataTable:GetSlotUnlockGrade(nSailorType, i)
                nMinUnlcokGrade = math.min(nMinUnlcokGrade, nUnlockGrade)
                tbUnlockIndexList[nSailorType] = i
                tbUnlockGradeList[nSailorType] = nUnlockGrade
                break
            end
        end
    end
    for nSailorType,nNextUnlockIndex in pairs(tbUnlockIndexList) do
        local nUnlockGrade = tbUnlockGradeList[nSailorType]
        if nUnlockGrade == nMinUnlcokGrade then
            self.tbSailorSlots[nSailorType][nNextUnlockIndex]:SetUnlockTipsByGrade(nUnlockGrade)
        else
            self.tbSailorSlots[nSailorType][nNextUnlockIndex]:SetUnlockTipsByCoin(nUnlockGrade)
        end
    end
end

local function UpdateSlotInfo(self)
    local tbSailorSlots = self.tbSailorSlots
    local tbSlotInfos = GetSailorComponent():GetSailorSlotInfo()
    for nSailorType,v in pairs(tbSlotInfos) do
        for i,tbEquippedData in ipairs(v) do
            tbSailorSlots[nSailorType][i]:SetEquippingData(tbEquippedData)
        end
    end
    UpdateTotalInfo(self)
end

-- 显示右侧水手详情
local function ShowSailorDetail(self, nSailorId)
    self.pWidgetRef.wsDetail:SetActiveWidgetIndex(TAB_RIGHT_PANEL_SINGLE_INFO)
    self.pbSailorDetailItem:SetSailorId(nSailorId)
    local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
    if tbTemplate.nGrade >= MAX_SAILOR_GRADE then
        self.pWidgetRef.btnUpLevelSingleInfo:SetIsEnabled(false)
        self.pWidgetRef.txtUpLevelSingleInfo:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_TOP"))
    else
        self.pWidgetRef.btnUpLevelSingleInfo:SetIsEnabled(true)
        self.pWidgetRef.txtUpLevelSingleInfo:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_SINGLE"))
    end
end

-- 显示右侧背包列表
local function ShowSailorMiniBag(self, nSailorId)
    self.pWidgetRef.wsDetail:SetActiveWidgetIndex(TAB_RIGHT_PANEL_MINI_BAG)
    local nSailorType = self.pbSelectedSailorSlot:GetSailorCategory()
    local tbBagListData = GetSailorComponent():GetFreeSailorListByType(nSailorType, nSailorId)
    if #tbBagListData > 0 then
        self.tbBagListHelper:SetData(tbBagListData)
        self.pWidgetRef.vboxEmpty:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.listMiniBag:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.vboxEmpty:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.listMiniBag:SetVisibility(ESlateVisibility.Collapsed)
    end

    -- 判断选中格是否已装备，已装备时才显示替换按钮进行二次确认
    if nSailorId then
        self.pWidgetRef.btnReturnMiniBag.Slot:SetPosition(Vector2D{X=0, Y=-20})
        self.pWidgetRef.btnReturnMiniBag:SetVisibility(ESlateVisibility.Visible)
        self.pWidgetRef.btnReplaceMiniBag:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.txtReplaceTips:SetVisibility(ESlateVisibility.HitTestInvisible)
        self:PlayAnimation("animReplaceTips", 0, 0, EUMGSequencePlayMode.PingPong, 1)
    else
        self.pWidgetRef.btnReturnMiniBag:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.btnReplaceMiniBag:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function UnselecteSlotItem(self)
    log("[UPSailorEquipping] UnselecteSlotItem")
    self.tbBagListHelper:UnselectCurrentItem()
    if self.pbSelectedSailorSlot then
        self.pbSelectedSailorSlot:Unselect()
        self.pbSelectedSailorSlot = nil
    end
end

local function OnSailorSlotSelected(self, pbSailorSlot)
    log("[UPSailorEquipping] OnSailorSlotSelected")
    UnselecteSlotItem(self)
    self.pbSelectedSailorSlot = pbSailorSlot
    local nSailorId = pbSailorSlot:GetSailorId()
    if nSailorId then
        ShowSailorDetail(self, nSailorId)
    else
        ShowSailorMiniBag(self)
    end
end

-- 返回默认的水手详细界面
local function ReturnTotalInfoTab(self)
    log("[UPSailorEquipping] ReturnTotalInfoTab")
    self.pWidgetRef.wsDetail:SetActiveWidgetIndex(TAB_RIGHT_PANEL_TOTAL_INFO)
    self.pWidgetRef.wsLeftPanel:SetActiveWidgetIndex(TAB_LEFT_PANEL_DEFAULT)
    self.pWidgetRef.pbSailorReplaceItemRight:SetVisibility(ESlateVisibility.Collapsed)
    UnselecteSlotItem(self)
end

-- 尝试自动选中下一个空槽
local function TryToSelectNextEmptySlot(self, nCurrentSailorCategory)
    -- 取消当前选择
    self.tbBagListHelper:UnselectCurrentItem()

    -- 优先选择同类型槽位
    local nFreeSailorCount = #GetSailorComponent():GetFreeSailorListByType(nCurrentSailorCategory)
    if nFreeSailorCount > 0 then
        for _,pbSailorSlot in ipairs(self.tbSailorSlots[nCurrentSailorCategory]) do
            if pbSailorSlot:IsEmptyUnlockedSlot() then
                pbSailorSlot:Select()
                return
            end
        end
    end

    -- 没有同类型的查找不同类型槽位
    for nSailorCategory=1,SailorCategoryDef.MAX_COUNT do
        nFreeSailorCount = #GetSailorComponent():GetFreeSailorListByType(nSailorCategory)
        if (nSailorCategory ~= nCurrentSailorCategory) and (nFreeSailorCount > 0) then
            for i,pbSailorSlot in ipairs(self.tbSailorSlots[nSailorCategory]) do
                if pbSailorSlot:IsEmptyUnlockedSlot() then
                    pbSailorSlot:Select()
                    return
                end
            end
        end
    end

    -- 没有下一个可装备槽位，返回默认Tab
    ReturnTotalInfoTab(self)
end

-- 请求装备/替换水手
local function RequestSailorEquip(self, nSailorId)
    local nSailorCategory = self.pbSelectedSailorSlot:GetSailorCategory()
    local nSailorSlot = self.pbSelectedSailorSlot:GetSlotIndex()
    GetSailorComponent():RequestSailorEquip(nSailorCategory, nSailorSlot, nSailorId)
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
        UpdateTotalInfo(self)
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

local function IsInEquipOneKey(self)
    return self.nRemainOneKeyEquipCount > 0
end

-- 展示下一个一键装备的水手
local function DisplayNextOneKeyEquipSailor(self)
    LOG("display next one key equip sailor")
    self.tbOneKeyEquipDelayTimer = nil
    if #self.tbOneKeyEquipWaitList > 0 then
        local tbSailorComponent = GetSailorComponent()
        local tbOneKeyEquipInfo = self.tbOneKeyEquipWaitList[1]
        self.tbSailorSlots[tbOneKeyEquipInfo.nSailorType][tbOneKeyEquipInfo.nSlotIndex]:SetSailorId(tbOneKeyEquipInfo.nEquippedSailorId, tbSailorComponent.bOneKeyEquipWithAnim)
        table.remove(self.tbOneKeyEquipWaitList, 1)
        OnceOneKeyEquipSucceeded(self)
        if IsInEquipOneKey(self) then
            if tbSailorComponent.nOneKeyEquipDelayTime > 0 then
                self.tbOneKeyEquipDelayTimer = self.TimerHelper:NewDelayRunTimerMethod(self, DisplayNextOneKeyEquipSailor, tbSailorComponent.nOneKeyEquipDelayTime)
            else
                DisplayNextOneKeyEquipSailor(self)
            end
        end
    end
end

-- 水手背包列表选中状态
local function OnMiniBagSelectedChanged(self, nIndex)
    local tbSelectedData = self.tbBagListHelper:GetSelectedData()
    if tbSelectedData then
        if not self.pbSelectedSailorSlot then
            logerror("cannot find pbSelectedSailorSlot?", nIndex, t2s(tbSelectedData))
            ReturnTotalInfoTab(self)
            return
        end
        if self.pbSelectedSailorSlot:IsEmptyUnlockedSlot() then
            -- 直接装备水手
            RequestSailorEquip(self, tbSelectedData.nSailorId)
        else
            -- 进入替换逻辑
            self.pbSailorReplaceItemRight:SetSailorId(tbSelectedData.nSailorId)
            self.pWidgetRef.btnReplaceMiniBag:SetVisibility(ESlateVisibility.Visible)
            self.pWidgetRef.btnReplaceMiniBag.Slot:SetPosition(Vector2D{X=110, Y=-20})
            self.pWidgetRef.btnReturnMiniBag.Slot:SetPosition(Vector2D{X=-110, Y=-20})
            self.pWidgetRef.pbSailorReplaceItemRight:SetVisibility(ESlateVisibility.HitTestInvisible)
            self.pbSailorReplaceItemRight:PlayEnterAnim()
            self:StopAnimation("animReplaceTips")
            self.pWidgetRef.txtReplaceTips:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

local function OnClickedBtnUnequipAll(self)
    GetSailorComponent():RequestSailorUnequipAll()
end

local function OnClickedBtnUpLevelAll(self)
    local pbSailorUpLevelAll = self.PrefabHelper:CreatePrefab(UIDef.UP_SAILOR_UP_LEVEL_ALL)
    local Dialog = UIUtils.CreateDialog(UISetUtils.GetL10NTextByKey("SAILOR_UPGRADE_DIALOG_TITLE"))
    Dialog:SetView(pbSailorUpLevelAll.pWidgetRef)
    Dialog:SetPositiveButtonVisible(false)
    Dialog:SetNegativeButtonVisible(false)
    pbSailorUpLevelAll:SetDialogFrame(Dialog)
    Dialog:ShowDialog()
end

local function OnClickedBtnReplaceSingleInfo(self)
    local nSailorId = self.pbSelectedSailorSlot:GetSailorId()
    ShowSailorMiniBag(self, nSailorId)
    self.pbSailorReplaceItemLeft:SetSailorId(nSailorId)
    self.pWidgetRef.wsLeftPanel:SetActiveWidgetIndex(TAB_LEFT_PANEL_REPLACE)
    self.pbSailorReplaceItemLeft:PlayEnterAnim()
end

local function OnClickedBtnUpLevelSingleInfo(self)
    local nSailorId = self.pbSelectedSailorSlot:GetSailorId()
    local nSailorCategory = self.pbSelectedSailorSlot:GetSailorCategory()
    local nSlotIndex = self.pbSelectedSailorSlot:GetSlotIndex()

    local Dialog = UIUtils.CreateDialog(UISetUtils.GetL10NTextByKey("SAILOR_UPGRADE_DIALOG_TITLE"))
    local pbSailorUpLevelSingle = self.PrefabHelper:CreatePrefab(UIDef.UP_SAILOR_UP_LEVEL_SINGLE)
    pbSailorUpLevelSingle:EnableEquippedMode(nSailorCategory, nSlotIndex)
    pbSailorUpLevelSingle:SetSailorId(nSailorId)
    pbSailorUpLevelSingle:SetDialogFrame(Dialog)
    Dialog:SetView(pbSailorUpLevelSingle.pWidgetRef)
    Dialog:SetPositiveButtonVisible(false)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:ShowDialog()
end

local function OnClickedBtnReplaceMiniBag(self)
    local nSailorId = self.pbSailorReplaceItemRight:GetSailorId()
    RequestSailorEquip(self, nSailorId)
end

local function OnClickedEquipSuit(self, nSuitId)
    GetSailorComponent():RequestSailorEquipOneKey(nSuitId)
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

local function OnDisableClickedBtnUpLevelSingleInfo(self)
    UIUtils.ShowToastWithKey("SAILOR_TOP_GRADE")
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
        self.tbSailorSlots[nSailorType][nSlotIndex]:SetSailorId(nEquippedSailorId, true)
        UpdateTotalInfo(self)
        if nUnequippedSailorId == INVALID_ID then
            TryToSelectNextEmptySlot(self, nSailorType)
        else
            ReturnTotalInfoTab(self)
        end
    end
end

local function OnReceiveSailorUnequipAllResult(self)
    for _,v in pairs(self.tbSailorSlots) do
        for _,pbSailorSlot in ipairs(v) do
            pbSailorSlot:SetSailorId(nil)
        end
    end
    if IsInEquipOneKey(self) and (GetSailorComponent().nOneKeyEquipDelayTime == 0) then
        return
    end
    UpdateTotalInfo(self)
end

local function OnReceiveUnlockSailorSlotResult(self, bResult, nSailorType, nSlotIndex)
    if bResult then
        self.tbSailorSlots[nSailorType][nSlotIndex]:Unlock()
        UpdateSlotUnlockInfo(self)
    else
        UIUtils.ShowToastWithKey("SAILOR_SLOT_UNLOCK_FAILED")
    end
end

local function OnReceiveUpgradeEquippedSailorResult(self, tbUpgradedSailorInfos, bOneKeyUpgrade)
    if bOneKeyUpgrade then
        local tbOpenArgs = {}
        tbOpenArgs.nLastTotalGrade = self.nTotalGrade
        UpdateSlotInfo(self)
        tbOpenArgs.nCurrentTotalGrade = self.nTotalGrade
        UIManager:OpenWnd(UIDef.UI_SAILOR_LEVEL_UP_RESULT, tbOpenArgs)
    else
        local tbUpgradedInfo = tbUpgradedSailorInfos[1]
        if self.pbSelectedSailorSlot and (tbUpgradedInfo.nSailorId  == self.pbSelectedSailorSlot:GetSailorId()) then
            self.pbSailorDetailItem:SetSailorId(tbUpgradedInfo.nUpgradeTo)
        end
        UpdateSlotInfo(self)
    end
end

local function InitSailorSlots(self)
    self.tbSailorSlots = {}
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    for nSailorType=1,SailorCategoryDef.MAX_COUNT do
        self.tbSailorSlots[nSailorType] = {}
        for i=1, MAX_SLOT_COUNT_PER_TYPE do
            local pbSailorSlot = PrefabHelper:BindPrefab(pWidgetRef[string.format(SAILOR_SLOT_WIDGET_NAME, nSailorType, i)])
            pbSailorSlot:SetSlotInfo(nSailorType, i)
            pbSailorSlot.OnItemSelected:Bind(OnSailorSlotSelected, self)
            self.tbSailorSlots[nSailorType][i] = pbSailorSlot
        end
    end
end

function UPSailorEquipping:OnLoad()
    InitSailorSlots(self)

    self.pbSailorDetailItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbSailorDetailItem)
    self.pbSailorReplaceItemLeft = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbSailorReplaceItemLeft)
    self.pbSailorReplaceItemRight = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbSailorReplaceItemRight)

    self.tbBagListHelper = SelfVerticalListHelper()
    self.tbBagListHelper:Init(self, self.pWidgetRef.listMiniBag)
    self.tbBagListHelper.OnSelectedChangedDelegate:Bind(OnMiniBagSelectedChanged, self)
    self.tbBagListHelper:SetAutoScrollEnabled(false)

    self.tbTotalPropertyListHelper = SelfVerticalListHelper()
    self.tbTotalPropertyListHelper:Init(self, self.pWidgetRef.listTotalProperties)
end

function UPSailorEquipping:OnUnload()
    self.tbBagListHelper:Uninit()
    self.tbBagListHelper = nil

    self.tbTotalPropertyListHelper:Uninit()
    self.tbTotalPropertyListHelper = nil
end

function UPSailorEquipping:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCloseSingleInfo.OnClicked, self, ReturnTotalInfoTab)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCloseMiniBag.OnClicked, self, ReturnTotalInfoTab)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReturnMiniBag.OnClicked, self, ReturnTotalInfoTab)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUnequipAll.OnClicked, self, OnClickedBtnUnequipAll)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUpLevelAll.OnClicked, self, OnClickedBtnUpLevelAll)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReplaceSingleInfo.OnClicked, self, OnClickedBtnReplaceSingleInfo)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUpLevelSingleInfo.OnClicked, self, OnClickedBtnUpLevelSingleInfo)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReplaceMiniBag.OnClicked, self, OnClickedBtnReplaceMiniBag)

    for nSuitId=1, SailorSlotDataTable.RECOMMENDED_SAILOR_SUIT_COUNT do
        EventHelper:RegisterCppDelegateFunc(pWidgetRef["btnEquipSuit"..nSuitId].OnClicked, function()
            OnClickedEquipSuit(self, nSuitId)
        end)
    end

    EventHelper:RegisterCppDelegate(pWidgetRef.btnUnequipAll.OnDisableClicked, self, OnDisableClickedBtnUnequipAll)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUpLevelAll.OnDisableClicked, self, OnDisableClickedBtnUpLevelAll)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUpLevelSingleInfo.OnDisableClicked, self, OnDisableClickedBtnUpLevelSingleInfo)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_EQUIP_RESULT, self, OnReceiveSailorEquipResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UNEQUIP_ALL_RESULT, self, OnReceiveSailorUnequipAllResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UNLOCK_SAILOR_SLOT_RESULT, self, OnReceiveUnlockSailorSlotResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UPGRADE_RESULT, self, UpdateSlotInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_DEGRADE_RESULT, self, UpdateSlotInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UPGRADE_EQUIPPED_SAILOR_RESULT, self, OnReceiveUpgradeEquippedSailorResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_ONE_KEY_EQUIP_SAILOR_STARTED, self, OneKeyEquipSailorStarted)
end

function UPSailorEquipping:OnEnter()
    UpdateSlotInfo(self)
    UpdateSlotUnlockInfo(self)
end

function UPSailorEquipping:OnExit()
    OneKeyEquipSailorEnded(self, true)
end

function UPSailorEquipping:Deactivate()
    ReturnTotalInfoTab(self)
end

return UPSailorEquipping