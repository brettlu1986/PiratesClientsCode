local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPWatchMateProgressBarNew = luaclass("UPWatchMateProgressBarNew", PrefabBase)
local ProgressBarTableNew = require("ProgressBarTableNew")
-- local PlayerSelfHelper = require("GamePlayerSelfHelper")
-- local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local Timer = require("Timer")

UPWatchMateProgressBarNew.TickTimer = nil
local UPDATE_INTERVAL = 0.1

function UPWatchMateProgressBarNew:OnLoad()
    self.EventHelper:RegisterCppDelegate(self.pWidgetRef.KMCircleProgressBar.OnAnimationFinished, self, self.OnEndProgressBar)
end

function UPWatchMateProgressBarNew:OnEnter()
    -- self:ShowHelpIcon()
    self.pWidgetRef.btnHelp:SetVisibility(ESlateVisibility.HitTestInvisible)
    self.pWidgetRef.btnCancel:SetVisibility(ESlateVisibility.HitTestInvisible)
end

local function DestroyTimer(self)
    if self.TickTimer ~= nil then
        self.TickTimer:Clear()
        self.TickTimer = nil
    end
end

function UPWatchMateProgressBarNew:SetVisible(VisibleState)
    self.pWidgetRef:SetVisibility(VisibleState)
end

function UPWatchMateProgressBarNew:OnProgressBarChanged(nInstanceId, bStart, nProgressBarId, nProgressBarTime) 
    local tbProgressBarTable = ProgressBarTableNew:GetTemplate(nProgressBarId)
    if tbProgressBarTable == nil then 
        logerror("UPWatchMateProgressBarNew:OnStartProgressBar GetTemplate Error. nProgressBarId:", nProgressBarId)
        return
    end
    self.EventHelper:FireEvent(CommonEventDef.EV_INTERRUPT_CONTINUOUS_RUN)
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
            -- 0.2 -> 0.099998, Todo需要写小数计时控件
            pWidgetRef.txtTime:SetText(string.format("%.1f", nShowTime))
        else
            DestroyTimer(self)
        end
    end
    pWidgetRef.txtTime:SetText(string.format("%.1f", nShowTime))
    DestroyTimer(self)
    self.TickTimer = Timer.NewTimerMethod(self, Update, UPDATE_INTERVAL, true)

    if l10nText ~= nil then
        pWidgetRef.txtAction:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtAction:SetText(l10nText)
    end
end 

function UPWatchMateProgressBarNew:OnEndProgressBar()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    DestroyTimer(self)
    -- -- 方便测试
    -- pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    -- self:ShowHelpIcon()

end

function UPWatchMateProgressBarNew:ShowHelpIcon()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.ProgressBarPanel:SetVisibility(ESlateVisibility.Collapsed)
    
    --不能点击
    --pWidgetRef.btnHelp:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.btnHelp:SetVisibility(ESlateVisibility.HitTestInvisible)
    
    pWidgetRef.txtAction:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    -- pWidgetRef.txtAction:SetText("救助队友")
end

-- local function OnHelpClicked(self)
--     local pWidgetRef = self.pWidgetRef
--     pWidgetRef.btnHelp:SetVisibility(ESlateVisibility.Collapsed)

--     local SelfPlayer = PlayerSelfHelper:Get()
--     if SelfPlayer.ProgressBarComponent then
--         SelfPlayer.ProgressBarComponent:Start(1)
--     end
-- end

-- local function OnCancelClicked(self)
--     local SelfPlayer = PlayerSelfHelper:Get()
--     if SelfPlayer.ProgressBarComponent then
--         SelfPlayer.ProgressBarComponent:Abort()
--     end
-- end

function UPWatchMateProgressBarNew:OnDestroy()
    DestroyTimer(self)
end


function UPWatchMateProgressBarNew:OnBindEvent(EventHelper)
    --local pWidgetRef = self.pWidgetRef
    --EventHelper:RegisterCppDelegate(pWidgetRef.btnHelp.OnClicked, self, OnHelpClicked)
    --主动调用，不接收事件
    --EventHelper:RegisterCppDelegate(pWidgetRef.btnCancel.OnClicked, self, OnCancelClicked)
end

return UPWatchMateProgressBarNew
