-----------------------------------------------------
--File Name    : UILoading.lua
--Author       : Song Fuhao
--Create Time  : 2016-08-11
--Description  : Loading UI
-----------------------------------------------------

local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILoading = luaclass("UILoading", WndBase)

-- require
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local DungeonDataTable = require("DungeonDataTable")
local LoadingBgDataTable = require("LoadingBgDataTable")
local LoadingTipsDataTable = require("LoadingTipsDataTable")
local UILoadingWndIni = require("UILoadingWndIni")
local PersistentTimerHelper = require("PersistentTimerHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local DelayTimer = require("DelayTimer")

-- const variable
local TICK_TIME         = 1 / 24
local LOADING_ADD_RATIO = 0.05
local MIN_LOADING_TIME = UILoadingWndIni.tbLoadingWnd.nLoadingTime
local TIP_DURATION = UILoadingWndIni.tbLoadingWnd.nDefaultTipDuration

local nCurTipIndex      = 0

-- member variable
UILoading.nPercent          = 0
UILoading.nTargetPercent    = 0
UILoading.pbTopUI           = nil
UILoading.TickTimer         = nil
UILoading.TipsTimer         = nil
UILoading.CanCloseTimer     = nil
UILoading.tbTipsList        = nil
UILoading.bNeedClose        = false
UILoading.nPlayerLevel      = nil
UILoading.PersistentTimerHelper = nil
UILoading.nExpectedStopTime = -1
UILoading.DelayTimerHandle = nil
UILoading.pDialogMessage    = nil

local function Clamp( nValue, nMin, nMax )
    if nValue < nMin then
        return nMin
    elseif nValue > nMax then
        return nMax
    end
    return nValue
end

local function ShuffleInplace(tbArray)
    for i = #tbArray, 1, -1 do
        local j = math.random(i)
        tbArray[i], tbArray[j] = tbArray[j], tbArray[i]
    end
    return tbArray
end

local function ClearTipsTimer(self)
    if self.TipsTimer then
        self.PersistentTimerHelper:ClearTimer(self.TipsTimer)
        self.TipsTimer = nil
    end
end

local function ClearCloseTimer(self)
    if self.CanCloseTimer then
        self.PersistentTimerHelper:ClearTimer(self.CanCloseTimer)
        self.CanCloseTimer = nil
    end
end

local function ClearDelayTimer(self)
    if self.DelayTimerHandle then
        DelayTimer:ClearTimer(self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
end

local function TryCloseWndAtTimerEnd(self)
    ClearCloseTimer(self)
    if self.bNeedClose then
        log("[UILoading] Close self at can close timer end.")
        self:CloseSelf()
    end
end

local function UpdateTips(self)
    ClearTipsTimer(self)
    local nCurTime = GlobalVariableSystem:GetLocalTime()
    local nDuration = self.nExpectedStopTime - nCurTime
    if nDuration <= 0 then
        nCurTipIndex = nCurTipIndex % #self.tbTipsList + 1
        local tbTip = self.tbTipsList[nCurTipIndex]
        self.pWidgetRef.txtContent:SetText(tbTip.l10nTip)
        nDuration = TIP_DURATION
        if tbTip.nDuration and tbTip.nDuration > 0 then
            nDuration = tbTip.nDuration
        end
        self.nExpectedStopTime = GlobalVariableSystem:GetLocalTime() + nDuration
    end
    self.TipsTimer = self.PersistentTimerHelper:NewTimer(function() UpdateTips(self) end, nDuration, false)
end

local function TryLoadTipsList(self)
    nCurTipIndex = 0
    self.nPlayerLevel = nil
    if not self.tbOpenArgs.nPlayerLevel then
        self.pWidgetRef.txtContent:SetVisibility(ESlateVisibility_Collapsed)
        self.pWidgetRef.txtLoadingTip:SetVisibility(ESlateVisibility_Visible)
        return
    end
    self.nPlayerLevel = self.tbOpenArgs.nPlayerLevel
    local tbTipsList = LoadingTipsDataTable:GetTemplateByPlayerLevel(self.nPlayerLevel)
    if tbTipsList and #tbTipsList > 0 then
        self.tbTipsList = ShuffleInplace(tbTipsList)
    end
end

-- 加载叠加UI
local function LoadTopUI( self )
    local nDungeonId = self.tbOpenArgs.nDungeonId
    if nDungeonId then
        local tbDungeonTemplate = DungeonDataTable:GetTemplate(nDungeonId)
        if tbDungeonTemplate and tbDungeonTemplate.szLoadingTopUI then
            self.pbTopUI = self.PrefabHelper:CreatePrefab(tbDungeonTemplate.szLoadingTopUI)
            self.pbTopUI:InitParam(self.tbOpenArgs)
            local TopUIWidgetRef = self.pbTopUI.pWidgetRef
            self.pWidgetRef.ovlContent:AddChildToOverlay(TopUIWidgetRef)
            local OvlSlot = TopUIWidgetRef.Slot
            OvlSlot:SetHorizontalAlignment(EHorizontalAlignment.HAlign_Fill)
            OvlSlot:SetVerticalAlignment(EVerticalAlignment.VAlign_Fill)
        end
    end
end

-- 卸载叠加UI
-- local function UnloadTopUI( self )
--     local pbTopUI = self.pbTopUI
--     if pbTopUI then
--         pbTopUI.pWidgetRef:RemoveFromViewport()
--         self.PrefabHelper:UnbindPrefab(pbTopUI)
--         self.pbTopUI = nil
--     end
-- end

-- 设置Loading背景
local function LoadLoadingBg(self)
    local tbBgContainer = LoadingBgDataTable:GetContainer()
    local nDungeonId = self.tbOpenArgs.nDungeonId
    local nSceneId = self.tbOpenArgs.nSceneId
    local tbLoadingInfo = self.tbOpenArgs.tbLoadingInfo
    local pVisibleOthers = tbLoadingInfo == nil and ESlateVisibility_Visible or ESlateVisibility_Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgProgressBg:SetVisibility(pVisibleOthers)
    pWidgetRef.cvsProgress:SetVisibility(pVisibleOthers)
    pWidgetRef.imgLogo:SetVisibility(pVisibleOthers)
    pWidgetRef.txtLoadingTip:SetVisibility(pVisibleOthers)
    pWidgetRef.imgBG:SetVisibility(pVisibleOthers)
    pWidgetRef.imgShot:SetVisibility(tbLoadingInfo ~= nil and ESlateVisibility_Visible or ESlateVisibility_Collapsed)

    if tbLoadingInfo ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgShot, tbLoadingInfo.pTexture)
    elseif nDungeonId ~= nil then
        local szPath = tbBgContainer[nDungeonId]
        if szPath == nil or szPath == "" then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgBG, UIResourceDef.LOADING_BG_DUNGEN:load())
        else
            UISetUtils.SetImageBrushRes(pWidgetRef.imgBG, szPath:load())
        end
    elseif nSceneId ~= nil then
        local szPath = tbBgContainer[nSceneId]
        if szPath == nil or szPath == "" then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgBG, UIResourceDef.LOADING_BG_BIG_WORLD:load())
        else
            UISetUtils.SetImageBrushRes(pWidgetRef.imgBG, szPath:load())
        end
    else
        local szHomelandBg = self.tbOpenArgs.szHomelandBg
        if szHomelandBg and szHomelandBg ~= "" then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgBG, szHomelandBg:load())
        else
            UISetUtils.SetImageBrushRes(pWidgetRef.imgBG, UIResourceDef.LOADING_BG_BIG_WORLD:load())
        end
    end
end

local function SetPercent( self, nPercent )
    self.nPercent = nPercent
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        return
    end
    pWidgetRef.sldrLoading:SetValue(nPercent)
    pWidgetRef.pgbLoading:SetPercent(nPercent)
    pWidgetRef.txtLoading:SetText(tostring(math.floor(nPercent * 100)) .. '%')
end

-- local function Reset( self )
--     UnloadTopUI(self)
--     SetPercent(self, 0)
-- end

local function OnTick( self )
    local nPercent = self.nPercent + (self.nTargetPercent - self.nPercent) * LOADING_ADD_RATIO
    SetPercent(self, nPercent)
end

function UILoading:OnEnter()
    LoadTopUI(self)
    LoadLoadingBg(self)
    SetPercent(self, 0)
    TryLoadTipsList(self)
end


local function ClearTickTimer(self)
    if self.TickTimer then
        self.TimerHelper:ClearTimer(self.TickTimer)
        self.TickTimer = nil
    end
end


function UILoading:OnBindEvent()
    self.TickTimer = self.TimerHelper:NewTimerMethod(self, OnTick, TICK_TIME, true)
    if self.nPlayerLevel and MIN_LOADING_TIME > 0 then
        self.CanCloseTimer = self.PersistentTimerHelper:NewTimer(function() TryCloseWndAtTimerEnd(self) end, MIN_LOADING_TIME , false)
    end
    self.pDialogMessage = self.PrefabHelper:BindPrefab(self.pWidgetRef.pDialogMessage)
end

function UILoading:AddPercent( nPercent )
    local nTargetPercent = Clamp(self.nTargetPercent + nPercent, 0, 1)
    self.nTargetPercent = nTargetPercent
    if nTargetPercent >= 1 then
        ClearTickTimer(self)
        SetPercent(self, 1)
        --self.TimerHelper:NewTimerMethod(self, self.CloseSelf, 0.01)
    end
end

function UILoading:Reload(tbParam)
    self.tbOpenArgs = tbParam
    LoadLoadingBg(self)
    SetPercent(self, 0)
    self.TickTimer = self.TimerHelper:NewTimerMethod(self, OnTick, TICK_TIME, true)
    TryLoadTipsList(self)
    self.bNeedClose = false
    log("UILoading:Reload")
    self.pDialogMessage:HideMessageDialog()
end

function UILoading:TryCloseWnd()
    if self.CanCloseTimer then
        self.bNeedClose = true
    else
        log("[UILoading] Can close self.")
        self:CloseSelf()
    end
end

function UILoading:OnShow()
    if self.tbTipsList and #self.tbTipsList > 0 then
        self.pWidgetRef.txtContent:SetVisibility(ESlateVisibility_Visible)
        self.pWidgetRef.txtLoadingTip:SetVisibility(ESlateVisibility_Collapsed)
        UpdateTips(self)
    else
        self.pWidgetRef.txtContent:SetVisibility(ESlateVisibility_Collapsed)
        self.pWidgetRef.txtLoadingTip:SetVisibility(ESlateVisibility_Visible)
    end
    self.pDialogMessage:HideMessageDialog()
end

function UILoading:OnCreate()
    self.PersistentTimerHelper = PersistentTimerHelper()
end

-- function UILoading:OnUnload()
--     ClearTipsTimer(self)
--     ClearDelayTimer(self)
-- end

-- function UILoading:OnDestroy()
--     ClearTipsTimer(self)
--     ClearDelayTimer(self)
-- end

function UILoading:OnExit()
    self.tbTipsList = nil
    self.bNeedClose = false
    self.nPlayerLevel = nil
    ClearTickTimer(self)
    ClearTipsTimer(self)
    ClearCloseTimer(self)
    ClearDelayTimer(self)
end

function UILoading:CloseSelf()
    self.bNeedClose = false
    ClearTipsTimer(self)
    log("[UILoading] tips timer cleared")
    TryCloseWndAtTimerEnd(self)
    self.super.CloseSelf(self)
    -- -- 为保证Persistent timer清掉，等一帧再关UI
    -- ClearDelayTimer(self)
    -- self.DelayTimerHandle = DelayTimer:RunNextTick(function() 
    --     log("[UILoading] close self")
    --     self.DelayTimerHandle = nil
    --     self.super.CloseSelf(self)
    -- end)
end

function UILoading:ShowDialogMessage(tbParam)
    self.pDialogMessage:ShowMessageDialog(tbParam)
end

return UILoading
