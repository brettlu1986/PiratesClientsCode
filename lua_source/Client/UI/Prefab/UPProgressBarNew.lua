local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPProgressBarNew = luaclass("UPProgressBarNew", PrefabBase)
local ProgressBarTableNew = require("ProgressBarTableNew")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemSystemClient = require("BattleItemSystemClient")
local CommonEventDef = require("CommonEventDef")
local Timer = require("Timer")
local L10N = require("L10N")
local BattleItemDataTable = require("BattleItemDataTable")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local UIDef = require("UIDef")

UPProgressBarNew.TickTimer = nil
local UPDATE_INTERVAL = 0.1

local ACTION_BUILD = 1

function UPProgressBarNew:OnLoad()
    self.EventHelper:RegisterCppDelegate(self.pWidgetRef.KMCircleProgressBar.OnAnimationFinished, self, self.OnEndProgressBar)
end

function UPProgressBarNew:OnEnter()
    -- self:ShowHelpIcon()
end

local function DestroyTimer(self)
    if self.TickTimer ~= nil then
        self.TickTimer:Clear()
        self.TickTimer = nil
    end
end

local function SetTimeText(self, nShowTime)
    -- 0.2 -> 0.099998, Todo需要写小数计时控件
    self.pWidgetRef.txtTime:SetText(string.format("%.1f", nShowTime))
end

local function GetActionFormatParam(nTextType)
    if nTextType == ACTION_BUILD then  
        local nBuildingItemTemplateId = BattleItemSystemClient:GetLastRequestBuildItemTemplateId()
        if nBuildingItemTemplateId ~= nil then
            local tbBuildingItemTemplate = BattleItemDataTable:GetTemplate(nBuildingItemTemplateId)
            local nGrade = tbBuildingItemTemplate.nGrade or 0
            local l10nStr = nil
            if nGrade > 0 then 
                l10nStr = L10N:Format(UISetUtils.GetL10NTextByKey("UI_BATTLE_BUILD_PROGRESS_WITHLV"), nGrade, tbBuildingItemTemplate.l10nName)
            else  
                l10nStr = L10N:Format(UISetUtils.GetL10NTextByKey("UI_BATTLE_BUILD_PROGRESS"), tbBuildingItemTemplate.l10nName)
            end
            return l10nStr
        end
    end
    return nil
end

function UPProgressBarNew:OnProgressBarChanged(nInstanceId, bStart, nProgressBarId, nProgressBarTime)
    local SelfPlayer = PlayerSelfHelper:Get()
    if SelfPlayer:GetServerInstanceId() ~= nInstanceId then 
        return 
    end
    if not bStart then  
        self:OnEndProgressBar()
        return 
    end  
    local tbProgressBarTable = ProgressBarTableNew:GetTemplate(nProgressBarId)
    if tbProgressBarTable == nil then
        logerror("UPProgressBarNew:OnStartProgressBar GetTemplate Error. nProgressBarId:", nProgressBarId)
        return
    end

    local bIgnoreAbortByMove = tbProgressBarTable.bIgnoreAbortByMove
    

    local ProgressBarComponent = SelfPlayer.ProgressBarComponent
    local HumanMovementStateComponent = SelfPlayer.HumanMovementStateComponent
    if ProgressBarComponent and HumanMovementStateComponent then
        bIgnoreAbortByMove = not ProgressBarComponent:CheckNeedAbortByMove(tbProgressBarTable, HumanMovementStateComponent:GetCurrentState())
    end

    if not bIgnoreAbortByMove then
        self.EventHelper:FireEvent(CommonEventDef.EV_INTERRUPT_CONTINUOUS_RUN)
    end

    local nTime = nProgressBarTime > 0 and nProgressBarTime or tbProgressBarTable.nTime
    local l10nText = tbProgressBarTable.l10nText
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.Image_0:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtAction:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.btnHelp:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ProgressBarPanel:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.KMCircleProgressBar:SetPercent(0)
    pWidgetRef.KMCircleProgressBar.AnimDuration = nTime
    pWidgetRef.KMCircleProgressBar:SetPercent(1, true)

    local nShowTime = nTime
    local Update = function()
        nShowTime = nShowTime - UPDATE_INTERVAL
        if nShowTime > 0 then
            SetTimeText(self, nShowTime)
        else
            DestroyTimer(self)
        end
    end
    SetTimeText(self, nShowTime)
    DestroyTimer(self)
    self.TickTimer = Timer.NewTimerMethod(self, Update, UPDATE_INTERVAL, true)

    if l10nText ~= nil then
        pWidgetRef.txtAction:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local l10Str = GetActionFormatParam(tbProgressBarTable.nTextType)
        if l10Str then 
            pWidgetRef.txtAction:SetText(l10Str)
        else
            pWidgetRef.txtAction:SetText(l10nText)
        end
    end
end

function UPProgressBarNew:OnEndProgressBar()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    DestroyTimer(self)
    -- -- 方便测试
    -- pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    -- self:ShowHelpIcon()
    UIManager:CloseWnd(UIDef.UI_PROGRESS_BAR)
end

function UPProgressBarNew:ShowHelpIcon()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.ProgressBarPanel:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.btnHelp:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.txtAction:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    -- pWidgetRef.txtAction:SetText("救助队友")
end

local function OnHelpClicked(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnHelp:SetVisibility(ESlateVisibility.Collapsed)

    local SelfPlayer = PlayerSelfHelper:Get()
    if SelfPlayer.ProgressBarComponent then
        SelfPlayer.ProgressBarComponent:Start(1)
    end
end

local function OnCancelClicked(self)
    local SelfPlayer = PlayerSelfHelper:Get()
    if SelfPlayer.ProgressBarComponent then
        SelfPlayer.ProgressBarComponent:Abort()
    end
end

function UPProgressBarNew:OnDestroy()
    DestroyTimer(self)
end


function UPProgressBarNew:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnHelp.OnClicked, self, OnHelpClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCancel.OnClicked, self, OnCancelClicked)
    EventHelper:RegisterEvent(CommonEventDef.EV_PROGRESS_CHANGED, self, self.OnProgressBarChanged)

end

return UPProgressBarNew
