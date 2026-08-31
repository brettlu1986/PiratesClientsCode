local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIScheduleRoulette = luaclass("UIScheduleRoulette", WndBase)
local ScheduleSystem = require("ScheduleSystem")
local ScheduleTypeDef = require("ScheduleTypeDef")
local AwardDataTable = require("AwardDataTable")
local ClientEventDef = require("ClientEventDef")
local UISetUtils = require("UISetUtils")
-- local UIResourceDef = require("UIResourceDef")
local UIUtils = require("UIUtils")
local AwardSystem = require("AwardSystem")
local AwardSessionType = require("AwardSessionType")
local DelayTimer = require("DelayTimer")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local UIDef = require("UIDef")
local UIManager = require("UIManager")

UIScheduleRoulette.tbInstance = nil
UIScheduleRoulette.pbItems = nil

UIScheduleRoulette.nCurIndex = nil
UIScheduleRoulette.nTargetIndex = nil
UIScheduleRoulette.tbDelayTimer = nil


-- local TASK_STATUS_STR = {
--     UISetUtils.GetL10NTextByKey("TASK_STAUTS_UNCOMPLETE"),
--     UISetUtils.GetL10NTextByKey("TASK_STATUS_COMPLETE"),    
--     UISetUtils.GetL10NTextByKey("TASK_STATUS_COMPLETE")    
-- }

-- local TASK_STATUS_COLOR = {
--     UIResourceDef.COLOR.GREY.SLATE_COLOR,
--     UIResourceDef.COLOR.WHITE.SLATE_COLOR,
--     UIResourceDef.COLOR.WHITE.SLATE_COLOR    
-- }

local DELAY_TIME = 0.7
local UNCHECKED, CHECKED = ECheckBoxState.Unchecked, ECheckBoxState.Checked

local function RefreshCount(self)
    local nCount = self.tbInstance:GetKeyCount()
    self.pWidgetRef.txtKeyCount:SetText(nCount)

    return nCount
end

local function OnRefreshCount(self)
    local nCount = RefreshCount(self)
    if nCount > 0 then
        self:PlayAnimation("animGetRewarFxOn_Loop", 0, 0, EUMGSequencePlayMode.Forward)
    else
        self:StopAnimation("animGetRewarFxOn_Loop")
        self:PlayAnimation("animGetRewarFxOff", 0, 1, EUMGSequencePlayMode.Forward)
    end
end

local function RefreshReward(self)
    local tbInstance = self.tbInstance
    local tbTemp = tbInstance.tbTemplate

    local tbRewards = tbTemp.tbScheduleData and tbTemp.tbScheduleData.tbRewards
    if tbRewards ~= nil then
        for i, v in ipairs(tbRewards) do
            local tbItems = AwardDataTable:GetAwardItem(v)
            self.pbItems[i]:SetDisplayItemData(tbItems[1].nItemId, tbItems[1].nCount)
        end
    else
        logerror("UIScheduleRoulette reward is empty")
    end

    local tbData = tbInstance:GetData()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtTime:SetText(tbInstance:GetTimeStr())
    RefreshCount(self)
    if tbData ~= nil then
        pWidgetRef.txtLuckyValue:SetText(tbData.lucky_value)
    else
        logwarning("schedule roulette data is nil")
        pWidgetRef.txtLuckyValue:SetText("0")
    end
end

local function RefreshTask(self, nIndex, tbTaskProgress)
    local pWidgetRef = self.pWidgetRef

    pWidgetRef["txtTaskDesc"..nIndex]:SetText(tbTaskProgress.l10nDesc or "")
    -- pWidgetRef["txtTaskProgress"..nIndex]:SetText(string.format("%d/%d", tbTaskProgress.nCurProgress, tbTaskProgress.nMaxProgress))
    pWidgetRef["txtTaskProgress"..nIndex]:SetText("+1")
    -- pWidgetRef["txtTaskStatus"..nIndex]:SetColorAndOpacity(TASK_STATUS_COLOR[tbTaskProgress.nStatus])
    -- pWidgetRef["txtTaskStatus"..nIndex]:SetText(TASK_STATUS_STR[tbTaskProgress.nStatus])
    pWidgetRef["txtTaskStatus"..nIndex]:SetText(string.format("%d/%d", tbTaskProgress.nCurProgress, tbTaskProgress.nMaxProgress))
end

local function RefreshTasks(self)
    local tbTaskProgress = self.tbInstance:GetTaskProgress()
    for i, v in ipairs(tbTaskProgress) do
        RefreshTask(self, i, v)
    end
end

local function RefreshLuckyValue(self)
    local tbData = self.tbInstance:GetData()
    if tbData ~= nil then
        self.pWidgetRef.txtLuckyValue:SetText(tbData.lucky_value)
    end
end

local function RefreshKeyCount(self)
    self.pWidgetRef.txtKeyCount:SetText(self.tbInstance:GetKeyCount())   
end

local function Refresh(self)
    RefreshReward(self)
    RefreshTasks(self)
    RefreshLuckyValue(self)
    RefreshKeyCount(self)
end

local function SetCurIndex(self, nIndex, bPlayAnimation)
    self.nCurIndex = nIndex

    local pbItems = self.pbItems
    for i, v in ipairs(pbItems) do
        pbItems[i]:SetSelected(i == nIndex, bPlayAnimation)
    end
end

local function InitInterface(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.olTask:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.cbGetCount:SetCheckedState(UNCHECKED)
    pWidgetRef.txtTime:SetText(self.tbInstance:GetTimeStr())
    
    Refresh(self)

    SetCurIndex(self, 1)
end

local function StartRoulette(self, nTargetIndex)
    self.nTargetIndex = nTargetIndex
    log("UIScheduleRoulette roulette start ", nTargetIndex)
    self.pWidgetRef:Start(self.nCurIndex - 1, nTargetIndex - 1)
end

local function DestroyTimer(self)
    if self.tbDelayTimer ~= nil then
        DelayTimer:ClearTimer(self.tbDelayTimer)
        self.tbDelayTimer = nil
    end    
end

local function ShowAward()
    local ScheduleAwardSession = AwardSystem:GetAlivedSession(AwardSessionType.ScheduleRouletteAwardSession)
    if ScheduleAwardSession then
        AwardSystem:FinishSession(ScheduleAwardSession)
    else
        log("OnAwardSchedule not find roulette session")
    end
end

local function EndRoulette(self, nTargetIndex)
    log("UIScheduleRoulette roulette end ", nTargetIndex + 1)
    SetCurIndex(self, nTargetIndex + 1, true)
    self.nTargetIndex = nil

    self.tbDelayTimer = DelayTimer:DelayRun(function()
            DestroyTimer(self)
            self.bRotating = false
            ShowAward()
        end, DELAY_TIME)
end

local function OnEnterForeground(self)
    log("UIScheduleRoulette roulette enter forground ", self.nTargetIndex)
    if self.nTargetIndex ~= nil then
        SetCurIndex(self, self.nTargetIndex)
    end
end

local function OnUseItem(self, nId, bSuccess)
    if nId ~= self.tbInstance.tbTemplate.nId then
        return
    end
    if bSuccess then
        log("UIScheduleRoulette roulette success")
        RefreshLuckyValue(self)
        RefreshKeyCount(self)
    end
end

local function OnRouletteSuccess(self, tbItem)
    local tbRewards = self.tbInstance.tbTemplate.tbScheduleData and self.tbInstance.tbTemplate.tbScheduleData.tbRewards
    local tbIndex = {}
    for i, v in ipairs(tbRewards) do
        local tbItems = AwardDataTable:GetAwardItem(v)
        if tbItems[1].nItemId == tbItem.template_id and tbItems[1].nCount == tbItem.count then
            table.insert(tbIndex, i)
        end
    end

    if #tbIndex == 0 then
        self.bRotating = false
        logerror("UIScheduleRoulette roulette success but can't find award ", tbItem.template_id, tbItem.count)
        return
    end

    local nIndex = tbIndex[math.random(1, #tbIndex)]
    log("UIScheduleRoulette roulette success index: ", nIndex, #tbIndex)

    StartRoulette(self, nIndex)
end

local function OnRefreshTask(self, nId)
    if nId ~= self.tbInstance.tbTemplate.nId then
        return
    end
    RefreshTasks(self)
end

local function OnClickClose(self)
    self:CloseSelf()
    if self.tbOpenArgs.szFrom ~= nil and self.tbOpenArgs.szFrom ~= "LobbyMain" then
        UIManager:OpenWnd(self.tbOpenArgs.szFrom, {szFrom = UIDef.UI_SCHEDULE_ROULETTE, nId = self.tbOpenArgs.nId})
    end     
end

local function OnClickGetReward(self)
    local tbRewards = self.tbInstance.tbTemplate.tbScheduleData and self.tbInstance.tbTemplate.tbScheduleData.tbRewards
    if tbRewards == nil then
        return
    end

    if self.bRotating then
        return
    end

    if not self.tbInstance:IsOpen() then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_SCHEDULE_NO_OPEN"))
        return
    end

    if self.tbInstance:GetKeyCount() == 0 then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("LOBBY_SCHEDULE_ROULETTE_NO_KEY"))
        return
    end

    self.bRotating = true
    self.tbInstance:RequestGetReward()
end

local function OnMouseButtonDown(self)
    local pWidgetRef = self.pWidgetRef 
    pWidgetRef.olTask:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.cbGetCount:SetCheckedState(UNCHECKED)
    return WidgetBlueprintLibrary.Handled()
end

local function OnClickGetCount(self, bActivate)
    -- test
    -- self.tbInstance:RecvNotifyTask({id})
    -- test end
    local pWidgetRef = self.pWidgetRef
    local bVisible = pWidgetRef.olTask:IsVisible()
    pWidgetRef.olTask:SetVisibility(bVisible and ESlateVisibility_Collapsed or ESlateVisibility_HitTestInvisible)
    pWidgetRef.cbGetCount:SetCheckedState(bVisible and UNCHECKED or CHECKED)
end

function UIScheduleRoulette:OnLoad()
    local tbRewards = self.tbInstance.tbTemplate.tbScheduleData and self.tbInstance.tbTemplate.tbScheduleData.tbRewards
    if tbRewards == nil then
        logerror("UIScheduleRoulette reward is empty")
        return
    end    

    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    self.pbItems = {}
    for i, v in ipairs(tbRewards) do
        local pbItem = PrefabHelper:BindPrefab(pWidgetRef["upItem"..i])
        table.insert(self.pbItems, pbItem)
    end  
end

function UIScheduleRoulette:OnUnload()
end

function UIScheduleRoulette:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnClickClose)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGetReward.OnClicked, self, OnClickGetReward)
    EventHelper:RegisterCppDelegate(pWidgetRef.cbGetCount.OnCheckStateChanged,  self, function(_, bActivate)
        OnClickGetCount(self, bActivate)
    end)     
    EventHelper:RegisterCppDelegate(pWidgetRef.OnRouletteComplete, self, EndRoulette)
    EventHelper:RegisterCppDelegate(pWidgetRef.imgBg.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(pWidgetRef.imgBg2.OnMouseButtonDownEvent, self, OnMouseButtonDown)

    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_ITEM_UPDATE, self, OnRefreshCount)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_USE_ITEM, self, OnUseItem)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_ROULETTE_SUCCESS, self, OnRouletteSuccess)
    EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_TASK_REFRESH, self, OnRefreshTask)
    EventHelper:RegisterEvent(ClientEventDef.EV_APP_HAS_ENTERED_FOREGROUND, self, OnEnterForeground)
end

function UIScheduleRoulette:OnCreate()
    self.tbInstance = ScheduleSystem:GetInstance(ScheduleTypeDef.ROULETTE)
end

function UIScheduleRoulette:OnDestroy()
    DestroyTimer(self)
    self.tbInstance = nil
end

function UIScheduleRoulette:OnShow()
    InitInterface(self)

    if self.tbInstance:GetKeyCount() > 0 then
        local fnOnComplete = function()
            self:PlayAnimation("animGetRewarFxOn_Loop", 0, 0, EUMGSequencePlayMode.Forward)
        end
        self:PlayAnimation("animButtomGetGlow", 0, 1, EUMGSequencePlayMode.Forward, 1, fnOnComplete)
    else
        self:PlayAnimation("animButtomGetGlow", 0, 1, EUMGSequencePlayMode.Forward)
        self:PlayAnimation("animGetRewarFxOff", 0, 1, EUMGSequencePlayMode.Forward)
    end
end

function UIScheduleRoulette:OnHide()
    ShowAward()
end

function UIScheduleRoulette:OnPause()
    local nSubSystem = LobbySystem:GetActiveSub()
    log("UIScheduleRoulette:OnPause:nSubSystem.nSubType=",nSubSystem.nSubType)
    if nSubSystem and (nSubSystem.nSubType == LobbySubTypeDef.AWARD) then
        self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    end
end

function UIScheduleRoulette:OnResume()
    log("UIScheduleRoulette:OnResume")
    if not self.pWidgetRef:IsVisible() then
        self.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        UIUtils.BottomMenuUnselectAll()
    end
end

return UIScheduleRoulette
