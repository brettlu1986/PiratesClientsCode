local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UISettingLayout = luaclass("UISettingLayout", WndBase)

local UIDef = require("UIDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local SettingLayoutFromDef = require("SettingLayoutFromDef")
local SettingIni = require("SettingIni")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local ClientEventDef = require("ClientEventDef")
local UITextDef = require("UITextDef")
local DelayTimer = require("DelayTimer")

local DRAW_TYPE_BOX = ESlateBrushDrawType.Box
local DRAW_TYPE_NONE = ESlateBrushDrawType.NoDrawType
local POS_DELTA = 10
local JoystickSizeY = 300
local JoystickPosY = -77
local ContinuousScaledOffset = 0
local CONTINUOUS_LOCAL_IDs = {
    1120,
    1212,
}
local JOYSTICK_LOCAL_IDs = {
    1116,
    1211,
    1304
}


local SUB_PREFAB_NAME =
{
    [SettingLayoutFromDef.HUMAN] = UIDef.UP_LAYOUT_HUMAN,
    [SettingLayoutFromDef.SHIP] = UIDef.UP_LAYOUT_SHIP,
    [SettingLayoutFromDef.VEHICLE] = UIDef.UP_LAYOUT_VEHICLE,
}

local LAYOUT_SAVE_TITLE = UISetUtils.GetL10NTextByKey("SETTING_LAYOUT_SAVE_TITLE")
local LAYOUT_SAVE_BUTTON = UISetUtils.GetL10NTextByKey("SETTING_LAYOUT_SAVE_BUTTON")
local LAYOUT_NOT_SAVE_BUTTON = UISetUtils.GetL10NTextByKey("SETTING_LAYOUT_NOT_SAVE_BUTTON")
local LAYOUT_EXIT_TIP = UISetUtils.GetL10NTextByKey("SETTING_LAYOUT_EXIT_TIP")
local LAYOUT_SAVE_TIP = UISetUtils.GetL10NTextByKey("SETTING_LAYOUT_SAVE_TIP")

local SUB_ANCHOR = Anchors{Minimum=Vector2D{X = 0, Y = 0}, Maximum=Vector2D{X = 1, Y = 1}}
local SUB_OFFSET = Margin{Left = 0, Top = 0, Right = 0, Bottom = 0}

UISettingLayout.tbLastPos = {}
UISettingLayout.tbTargetWidgetMap = {}
UISettingLayout.nTargetUniqueId = nil
UISettingLayout.pListenerWidget = nil
UISettingLayout.pWidgetOffset = nil
UISettingLayout.tbWidgetOffset = {}
UISettingLayout.bModified = false
UISettingLayout.bCollapsed = false
UISettingLayout.bEnableMouseMove = true
UISettingLayout.tbSubSetPrefab = nil

local function IsJoystickTarget(nTargetUniqueID)
    for _, v in pairs(JOYSTICK_LOCAL_IDs) do
        if nTargetUniqueID == v then
            return true
        end
    end
    return false
end

local function IsContinuousTarget(nTargetUniqueID)
    for _, v in pairs(CONTINUOUS_LOCAL_IDs) do
        if nTargetUniqueID == v then
            return true
        end
    end
    return false
end

local function ChangeTargetPos(self, nX, nY)
    local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
    if not tbTargetData then
        return
    end
    --logdebug("tbTargetData.nScale=",tbTargetData.nScale)
    local pWidgetLocalSize = SlateBlueprintLibrary.GetLocalSize(tbTargetData.pMovableWidget:GetCachedGeometry())
    local nLocalSizeX = pWidgetLocalSize.X
    local nLocalSizeY = pWidgetLocalSize.Y
    local nScale = tbTargetData.pScaleWidget.UserSpecifiedScale
    if not nScale then
        nScale = tbTargetData.nScale
        nLocalSizeX = nLocalSizeX * nScale
        if not IsJoystickTarget(self.nTargetUniqueId) then
            nLocalSizeY = nLocalSizeY * nScale
        end
    end
    local pAlignment = tbTargetData.pWidgetAlignment
    local pAnchor = tbTargetData.pWidgetAnchor.Minimum

    if IsContinuousTarget(self.nTargetUniqueId) then
        nY = math.min(nY, - JoystickSizeY)
        nY = math.max(nY, - self.pRealViewPortSize.Y - JoystickPosY + pAlignment.Y * nLocalSizeY)
        ContinuousScaledOffset = pWidgetLocalSize.Y * (1 - nScale)
    else
        nY = math.min( (1 - pAnchor.Y) * self.pRealViewPortSize.Y - (1 - pAlignment.Y) * nLocalSizeY, nY)
        if IsJoystickTarget(self.nTargetUniqueId) then
            nX = math.max( 0 + pAlignment.X * nLocalSizeX - pAnchor.X * self.pRealViewPortSize.X  + (nLocalSizeX - pWidgetLocalSize.X)/2, nX)
            nX = math.min( (1 - pAnchor.X) * self.pRealViewPortSize.X - (1 - pAlignment.X) * nLocalSizeX  + (nLocalSizeX - pWidgetLocalSize.X)/2, nX)
            nY = math.max( 0 + pAlignment.Y * nLocalSizeY - pAnchor.Y * self.pRealViewPortSize.Y - ContinuousScaledOffset, nY)
            JoystickPosY = nY
        else
            nX = math.max( 0 + pAlignment.X * nLocalSizeX - pAnchor.X * self.pRealViewPortSize.X, nX)
            nX = math.min( (1 - pAnchor.X) * self.pRealViewPortSize.X - (1 - pAlignment.X) * nLocalSizeX, nX)
            nY = math.max( 0 + pAlignment.Y * nLocalSizeY - pAnchor.Y * self.pRealViewPortSize.Y, nY)
        end
    end

    tbTargetData.pMovableWidget.Slot:SetPosition(Vector2D{X = nX, Y = nY})
    self.SettingLayout:SetPosition(self.nOpenFrom, tbTargetData.nRemoteId, nX, nY)
    --logdebug("self.nTargetUniqueId=", self.nTargetUniqueId,LocalPos.X, LocalPos.Y,self.pWidgetOffset.X,self.pWidgetOffset.Y)
    self.bModified = true
end

local function RefreshAlpha(self, nAlpha)
    local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
    if not tbTargetData then
        return
    end
    local szValue = tostring(math.floor(nAlpha / SettingIni.tbLayout.nAlphaDefault * 100)).."%"
    self.pWidgetRef.txtAlpha:SetText(szValue)
    tbTargetData.pAlphaWidget:SetRenderOpacity(nAlpha)

    local nTotalAlpha = SettingIni.tbLayout.nAlphaMax - SettingIni.tbLayout.nAlphaMin
    local nAlphaRatio = (nAlpha - SettingIni.tbLayout.nAlphaMin) / nTotalAlpha
    --logdebug("nAlphaRatio=",nAlphaRatio)
    self.pWidgetRef.sldAlpha:SetValue(nAlphaRatio)
    self.pWidgetRef.pgbAlpha:SetPercent(nAlphaRatio)
end

local function RefreshScale(self, nScale)
    local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
    if not tbTargetData then
        return
    end
    local szValue = tostring(math.floor(nScale / SettingIni.tbLayout.nScaleDefault * 100)).."%"
    self.pWidgetRef.txtScale:SetText(szValue)
    local SetUserSpecifiedScaleFunc = tbTargetData.pScaleWidget.SetUserSpecifiedScale
    if SetUserSpecifiedScaleFunc then
        SetUserSpecifiedScaleFunc(tbTargetData.pScaleWidget, nScale)
    else
        tbTargetData.pScaleWidget:SetRenderScale(Vector2D{X = nScale, Y = nScale})
    end


    local nTotalScale = SettingIni.tbLayout.nScaleMax - SettingIni.tbLayout.nScaleMin
    local nScaleRatio = (nScale - SettingIni.tbLayout.nScaleMin) / nTotalScale
    --logdebug("nScaleRatio=",nScaleRatio)
    self.pWidgetRef.sldScale:SetValue(nScaleRatio)
    self.pWidgetRef.pgbScale:SetPercent(nScaleRatio)
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    --logdebug("OnMouseMove")
    if not self.nTargetUniqueId or not self.bEnableMouseMove then
        return WidgetBlueprintLibrary.Unhandled()
    end
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
    if not self.tbLastPos[nTouchIndex] then
        return WidgetBlueprintLibrary.Unhandled()
    end
    local curPos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
    self.tbLastPos[nTouchIndex] = curPos
    if not curPos then
        return WidgetBlueprintLibrary.Unhandled()
    else
        local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]

        if tbTargetData then

            local LocalPos = SlateBlueprintLibrary.AbsoluteToLocal(tbTargetData.pRoot:GetCachedGeometry(), curPos)
            local pAnchor = tbTargetData.pWidgetAnchor
            local nX, nY = LocalPos.X, LocalPos.Y
            nX = nX - pAnchor.Minimum.X * self.pRealViewPortSize.X
            nY = nY - pAnchor.Minimum.Y * self.pRealViewPortSize.Y
            local pAlignment = tbTargetData.pWidgetAlignment
            local pWidgetLocalSize = SlateBlueprintLibrary.GetLocalSize(tbTargetData.pMovableWidget:GetCachedGeometry())
            local nScale = tbTargetData.nScale
            local nLocalSizeX = pWidgetLocalSize.X
            local nLocalSizeY = pWidgetLocalSize.Y
            if tbTargetData.pMovableWidget == tbTargetData.pScaleWidget then
                nLocalSizeX = nLocalSizeX * nScale
                nLocalSizeY = nLocalSizeY * nScale
            end
            nX = nX + pAlignment.X * nLocalSizeX - self.tbWidgetOffset.X
            nY = nY + pAlignment.Y * nLocalSizeY - self.tbWidgetOffset.Y
            if IsContinuousTarget(self.nTargetUniqueId) then
                nX = 0
                nY = nY - JoystickPosY
            end
            ChangeTargetPos(self, nX, nY)
        end
    end
    return WidgetBlueprintLibrary.Unhandled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    -- printScreen("OnMouseButtonUp nOldDragState:" .. nOldDragState)
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
    if not self.tbLastPos[nTouchIndex] then
        return WidgetBlueprintLibrary.Unhandled()
    end
    self.tbLastPos[nTouchIndex] = nil
    self.pListenerWidget:SetVisibility(ESlateVisibility.Collapsed)
    if self.nTargetUniqueId then
        local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
        if tbTargetData then
            tbTargetData.pWidget:SetVisibility(ESlateVisibility.Visible)
        end
    end
    return WidgetBlueprintLibrary.Unhandled()
end

local function SetExpandWidget(self, tbTargetData, pMousePos)
    self.pWidgetOffset = SlateBlueprintLibrary.AbsoluteToLocal(tbTargetData.pMovableWidget:GetCachedGeometry(), pMousePos)
    local nX, nY = self.pWidgetOffset.X, self.pWidgetOffset.Y
    if tbTargetData.pMovableWidget == tbTargetData.pScaleWidget then
        self.tbWidgetOffset.X = nX * tbTargetData.nScale
        self.tbWidgetOffset.Y = nY * tbTargetData.nScale
    else
        self.tbWidgetOffset.X = nX
        self.tbWidgetOffset.Y = nY
    end
end

local function OnTargetMouseDown(self, nTargetUniqueId, pGeometry, pMouseEvent)
    if next(self.tbLastPos) then
        return WidgetBlueprintLibrary.Unhandled()
    end
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
    if nTouchIndex == 10 then
        return WidgetBlueprintLibrary.Unhandled()
    end
    local pos = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent)
    self.tbLastPos[nTouchIndex] = pos
    self:SetTarget(nTargetUniqueId)
    --self.pListenerWidget:SetVisibility(ESlateVisibility_Visible)
    local tbTargetData = self.tbTargetWidgetMap[nTargetUniqueId]
    if tbTargetData then
        tbTargetData.pWidget:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        if tbTargetData.pExpandWidget then
            self.bEnableMouseMove = false
            if self.tbDelayHandle then
                DelayTimer:ClearTimer(self.tbDelayHandle)
                self.tbDelayHandle = nil
            end
            self.tbDelayHandle = DelayTimer:DelayRun(function()
                SetExpandWidget(self, tbTargetData, pos)
                self.tbDelayHandle = nil
                self.bEnableMouseMove = true
            end, 0.1)
        else
            SetExpandWidget(self, tbTargetData, pos)
            self.bEnableMouseMove = true
        end
    end
    --logdebug("OnTargetMouseDown,nTargetUniqueId=",nTargetUniqueId,nTouchIndex,self.pWidgetOffset.X,self.pWidgetOffset.Y)
    return WidgetBlueprintLibrary.Unhandled()
end

local function ClearTarget(self)
    if self.nTargetUniqueId then
        local tbOldTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
        if tbOldTargetData then
            local pBackground = tbOldTargetData.pWidget.Background
            pBackground.DrawAs = DRAW_TYPE_NONE
            if tbOldTargetData.pExpandWidget then
                tbOldTargetData.pExpandWidget:SetVisibility(ESlateVisibility_Collapsed)
            end
        end
        self.nTargetUniqueId = nil
    end
end

local function AddTargetWidget(self, tbLayoutTemplate, nRemoteId, nScale, nAlpha)
    local pWidgetRef = self.pWidgetRef
    local tbTargetWidgetData = {}
    tbTargetWidgetData.pRoot = pWidgetRef.cvsRoot
    tbTargetWidgetData.pWidget = pWidgetRef[tbLayoutTemplate.szWidgetName]
    tbTargetWidgetData.pMovableWidget = pWidgetRef[tbLayoutTemplate.szMovableWidgetName]
    tbTargetWidgetData.pAlphaWidget = pWidgetRef[tbLayoutTemplate.szAlphaWidgetName]
    tbTargetWidgetData.pScaleWidget = pWidgetRef[tbLayoutTemplate.szScaleWidgetName]
    tbTargetWidgetData.pExpandWidget = pWidgetRef[tbLayoutTemplate.szExpandWidgetName]
    local pMovableWidgetSlot = tbTargetWidgetData.pMovableWidget.Slot
    tbTargetWidgetData.pWidgetAnchor = pMovableWidgetSlot:GetAnchors()
    tbTargetWidgetData.pWidgetAlignment = pMovableWidgetSlot:GetAlignment()
    tbTargetWidgetData.nRemoteId = nRemoteId
    tbTargetWidgetData.nFrom = SettingLayoutFromDef.COMMON
    tbTargetWidgetData.nScale = nScale
    tbTargetWidgetData.nAlpha = nAlpha
    self.tbTargetWidgetMap[nRemoteId] = tbTargetWidgetData

end

local function LoadWidgetSettingData(self, tbLayoutData)
    local pMovableWidget = self.pWidgetRef[tbLayoutData.tbTemplate.szMovableWidgetName]
    local pAlphaWidget = self.pWidgetRef[tbLayoutData.tbTemplate.szAlphaWidgetName]
    local pScaleWidget = self.pWidgetRef[tbLayoutData.tbTemplate.szScaleWidgetName]
    if not pMovableWidget or not pAlphaWidget or not pScaleWidget then
        logerror("UISettingLayout:LoadWidgetSettingData,widget is nil,", tbLayoutData.tbTemplate.szMovableWidgetName,
        tbLayoutData.tbTemplate.szAlphaWidgetName, tbLayoutData.tbTemplate.szScaleWidgetName)
        return
    end
    --pos
    pMovableWidget.Slot:SetPosition(Vector2D{X = tbLayoutData.nX, Y = tbLayoutData.nY})
    --alpha
    pAlphaWidget:SetRenderOpacity(tbLayoutData.nAlpha)
    --scale
    local SetUserSpecifiedScaleFunc = pScaleWidget.SetUserSpecifiedScale
    if SetUserSpecifiedScaleFunc then
        SetUserSpecifiedScaleFunc(pScaleWidget, tbLayoutData.nScale)
    else
        pScaleWidget:SetRenderScale(Vector2D{X = tbLayoutData.nScale, Y = tbLayoutData.nScale})
    end
    --pScaleWidget:SetRenderScale(Vector2D{X = tbLayoutData.nScale, Y = tbLayoutData.nScale})

    --local tbWidgetData = self.tbTargetWidgetMap[tbLayoutData.nRemoteId]
    pScaleWidget:SetRenderTransformPivot(pScaleWidget.Slot:GetAlignment())

    --当前布局
    self.pWidgetRef.txtNegative:SetText(UITextDef.LAYOUT_NAME[self.SettingLayout:GetLayoutStyle(self.nOpenFrom)])
end

local function LoadSetting(self)
    local SettingLayout = self.SettingLayout
    local tbAllLayout = SettingLayout:GetCurrentLayoutFrom(self.nOpenFrom)
    for k, v in pairs(tbAllLayout)do
        if not self.nTargetUniqueId then
            self:SetTarget(v.nRemoteId)
        end
        if v.nFrom == SettingLayoutFromDef.COMMON then
            LoadWidgetSettingData(self, v)
        else
            --logdebug("v.szWidgetName=",v.tbTemplate.szWidgetName)
            self.pbSubSet:LoadWidgetSettingData(v)
        end
        if self.tbTargetWidgetMap[v.nRemoteId] then
            self.tbTargetWidgetMap[v.nRemoteId].nScale = v.nScale
        end
    end
end

local function OnLayoutExtendClicked(self)
    self.bCollapsed = not self.bCollapsed
    local pVisibility = self.bCollapsed and ESlateVisibility.Collapsed or ESlateVisibility.SelfHitTestInvisible
    self.pWidgetRef.cvsOperation:SetVisibility(pVisibility)
    if self.bCollapsed then
        self.pWidgetRef.btnUp:SetRenderTransformAngle(0)
    else
        self.pWidgetRef.btnUp:SetRenderTransformAngle(180)
    end

end

local function OnPosUpClicked(self)
    local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
    if not tbTargetData then
        return
    end
    local tbPos = tbTargetData.pMovableWidget.Slot:GetPosition()
    if tbPos then
        local nY = tbPos.Y - POS_DELTA
        ChangeTargetPos(self, tbPos.X, nY)
    end
end

local function OnPosDownClicked(self)
    local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
    if not tbTargetData then
        return
    end
    local tbPos = tbTargetData.pMovableWidget.Slot:GetPosition()
    if tbPos then
        local nY = tbPos.Y + POS_DELTA
        ChangeTargetPos(self, tbPos.X, nY)
    end
end

local function OnPosLeftClicked(self)
    local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
    if not tbTargetData then
        return
    end
    local tbPos = tbTargetData.pMovableWidget.Slot:GetPosition()
    if tbPos then
        local nX = tbPos.X - POS_DELTA
        ChangeTargetPos(self, nX, tbPos.Y)
    end
end

local function OnPosRightClicked(self)
    local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
    if not tbTargetData then
        return
    end
    local tbPos = tbTargetData.pMovableWidget.Slot:GetPosition()
    if tbPos then
        local nX = tbPos.X + POS_DELTA
        ChangeTargetPos(self, nX, tbPos.Y)
    end
end

local function OnScaleValueChanged(self, nValue)
    local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
    if not tbTargetData then
        return
    end
    local nTotal = SettingIni.tbLayout.nScaleMax - SettingIni.tbLayout.nScaleMin
    local nCurrentScale = nTotal * nValue + SettingIni.tbLayout.nScaleMin
    tbTargetData.nScale = nCurrentScale
    self.SettingLayout:SetSizeScale(self.nOpenFrom, tbTargetData.nRemoteId, nCurrentScale)
    self.bModified = true
    local pCurPos = tbTargetData.pMovableWidget.Slot:GetPosition()
    ChangeTargetPos(self, pCurPos.X, pCurPos.Y)
    if IsJoystickTarget(self.nTargetUniqueId) then
        JoystickSizeY = tbTargetData.pScaleWidget.Slot:GetSize().Y * nCurrentScale
    end

    RefreshScale(self, nCurrentScale)
end

local function OnAlphaValueChanged(self, nValue)
    local tbTargetData = self.tbTargetWidgetMap[self.nTargetUniqueId]
    if not tbTargetData then
        return
    end
    local nTotal = SettingIni.tbLayout.nAlphaMax - SettingIni.tbLayout.nAlphaMin
    local nCurrentAlpha = nTotal * nValue + SettingIni.tbLayout.nAlphaMin
    tbTargetData.nAlpha = nCurrentAlpha
    self.SettingLayout:SetAlpha(self.nOpenFrom, tbTargetData.nRemoteId, nCurrentAlpha)
    self.bModified = true

    RefreshAlpha(self, nCurrentAlpha)
end

local function OnExitClicked(self)
    if self.bModified then
        local pbLayoutSave = self.PrefabHelper:CreatePrefab(UIDef.UP_LAYOUT_SAVE_TIP)
        local tbData = {l10nText = LAYOUT_EXIT_TIP}
        pbLayoutSave:Init(tbData)
        local Dialog = UIUtils.CreateDialog(LAYOUT_SAVE_TITLE)
        Dialog:SetView(pbLayoutSave.pWidgetRef)
        --保存按钮
        Dialog:SetPositiveText(LAYOUT_SAVE_BUTTON)
        Dialog:SetPositiveButtonVisible(true)
        Dialog:SetPositiveButtonCallback(function()
            self.SettingLayout:SaveAll(self.nOpenFrom, pbLayoutSave.bSyncCommonLayout)
            self.PrefabHelper:UnbindPrefab(pbLayoutSave)
            self:CloseSelf()
        end)
        --不保存按钮
        Dialog:SetNegativeText(LAYOUT_NOT_SAVE_BUTTON)
        Dialog:SetNegativeButtonVisible(true)
        Dialog:SetNegativeButtonCallback(function()
            self.PrefabHelper:UnbindPrefab(pbLayoutSave)
            self:CloseSelf()
        end)
        Dialog:SetPositiveButtonVisible(true)
        Dialog:SetCloseButtonVisible(false)
        Dialog:ShowDialog()
    else
        self:CloseSelf()
    end

end

local function OnResetClicked(self)
    self.SettingLayout:ResetToDefault(self.nOpenFrom)
    LoadSetting(self)
    self.bModified = true
    JoystickSizeY = 300
    JoystickPosY = -77
    ContinuousScaledOffset = 0
end

local function OnSaveClicked(self)
    local pbLayoutSave = self.PrefabHelper:CreatePrefab(UIDef.UP_LAYOUT_SAVE_TIP)
    local tbData = {l10nText = LAYOUT_SAVE_TIP}
    pbLayoutSave:Init(tbData)
    local Dialog = UIUtils.CreateDialog(LAYOUT_SAVE_TITLE)
    Dialog:SetView(pbLayoutSave.pWidgetRef)
    --保存按钮
    Dialog:SetPositiveText(LAYOUT_SAVE_BUTTON)
    Dialog:SetPositiveButtonVisible(true)
    Dialog:SetPositiveButtonCallback(function()
        self.SettingLayout:SaveAll(self.nOpenFrom, pbLayoutSave.bSyncCommonLayout)
        self.PrefabHelper:UnbindPrefab(pbLayoutSave)
        self.bModified = false
    end)
    --不保存按钮
    Dialog:SetNegativeText(LAYOUT_NOT_SAVE_BUTTON)
    Dialog:SetNegativeButtonVisible(true)
    Dialog:SetNegativeButtonCallback(function()
        self.PrefabHelper:UnbindPrefab(pbLayoutSave)
    end)
    Dialog:SetPositiveButtonVisible(true)
    Dialog:SetCloseButtonVisible(false)
    Dialog:ShowDialog()
end

local function OnChangeStyleClicked(self)
    local pbLayoutStyle = self.PrefabHelper:CreatePrefab(UIDef.UP_LAYOUT_STYLE_TIP)
    pbLayoutStyle:Init(self.nOpenFrom)
    local Dialog = UIUtils.CreateDialog(LAYOUT_SAVE_TITLE)
    Dialog:SetView(pbLayoutStyle.pWidgetRef)
    Dialog:SetPositiveButtonVisible(false)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:ShowDialog()
end

local function ReloadAllTargetWidgetData(self)
    local EventHelper = self.EventHelper
    self.bModified = false
    ClearTarget(self)
    if self.tbTargetWidgetMap then
        for k, v in pairs(self.tbTargetWidgetMap) do
            EventHelper:UnregisterCppDelegate(v.pMouseDownDelegate)
        end
    end
    self.tbTargetWidgetMap = {}
    self.tbTargetWidgetMap = self.pbSubSet:LoadTargetWidgets(self.tbTargetWidgetMap)
    local tbAllLayout = self.SettingLayout:GetCurrentLayoutFrom(self.nOpenFrom)
    --local pWidgetRef = self.pWidgetRef
    for k, v in ipairs(tbAllLayout) do
        local tbTemplate = v.tbTemplate
        if tbTemplate.nFrom == SettingLayoutFromDef.COMMON then
            AddTargetWidget(self, tbTemplate, v.nRemoteId, v.nScale, v.nAlpha)
        end
    end
    for k, v in pairs(self.tbTargetWidgetMap) do
        v.pMouseDownDelegate = EventHelper:RegisterCppDelegateFunc(v.pWidget.OnMouseButtonDownEvent, function(pGeometry, pMouseEvent) return OnTargetMouseDown(self, k, pGeometry, pMouseEvent) end)
    end
    LoadSetting(self)
end

local function OnLayoutStyleChanged(self, nFrom, nStyle)
    if nFrom == self.nOpenFrom then

        ReloadAllTargetWidgetData(self)
    end
end

local function SwitchSubSetVisble(self, nOpenFrom, bVisible)
    local pbSubSet = self.tbSubSetPrefab[nOpenFrom]
    if not pbSubSet then
        pbSubSet = self.PrefabHelper:CreatePrefab(SUB_PREFAB_NAME[nOpenFrom])
        local pSubWidgetRef = pbSubSet.pWidgetRef
        self.pWidgetRef.cvsRoot:AddChildToCanvas(pSubWidgetRef)
        pSubWidgetRef.Slot:SetAnchors(SUB_ANCHOR)
        pSubWidgetRef.Slot:SetOffsets(SUB_OFFSET)
        self.tbSubSetPrefab[nOpenFrom] = pbSubSet
    end
    if bVisible then
        pbSubSet.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    else
        pbSubSet.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    end
    return pbSubSet
end

function UISettingLayout:OnLoad()
    self.tbSubSetPrefab = {}
    local pbCutoutScreenAdapter = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.nCutoutSpacerWidth = pbCutoutScreenAdapter:GetCutoutSpacerWidth()
    self.SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local nViewPortScale = WidgetLayoutLibrary.GetViewportScale(GWorld)
    local pViewportSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
    self.pRealViewPortSize = KismetMathLibrary.Divide_Vector2DFloat(pViewportSize, nViewPortScale)
    self.pRealViewPortSize.X = self.pRealViewPortSize.X - self.nCutoutSpacerWidth *2
    local pWidgetRef = self.pWidgetRef
    self.pListenerWidget = pWidgetRef.bdrListener
    self.pWidgetRef.bTopWindow = false
    self.ulFFAMainStaticLayout = self.UILogicHelper:CreateUILogic("ULFFAMainStaticLayout")
end

function UISettingLayout:OnEnter()
    self.nOpenFrom = self.tbOpenArgs.nOpenFrom
    self.pbSubSet = SwitchSubSetVisble(self, self.nOpenFrom, true)
    self.ulFFAMainStaticLayout:Init(function ()
        return self.pbSubSet.pWidgetRef
    end)
    ReloadAllTargetWidgetData(self)
end

function UISettingLayout:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.OnTouchEndedEvent, self, OnMouseButtonUp)
    EventHelper:RegisterCppDelegate(pWidgetRef.OnTouchMoveEvent, self, OnMouseMove)
    --EventHelper:RegisterCppDelegate(self.pListenerWidget.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    --EventHelper:RegisterCppDelegate(self.pListenerWidget.OnMouseMoveEvent, self, OnMouseMove)
    --EventHelper:RegisterCppDelegate(self.pListenerWidget.OnMouseButtonUpEvent, self, OnMouseButtonUp)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUp.OnClicked, self, OnLayoutExtendClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPosUP.OnClicked, self, OnPosUpClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPosDown.OnClicked, self, OnPosDownClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPosLeft.OnClicked, self, OnPosLeftClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPosRight.OnClicked, self, OnPosRightClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.sldScale.OnValueChanged, self, OnScaleValueChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.sldAlpha.OnValueChanged, self, OnAlphaValueChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnExit.OnClicked, self, OnExitClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReset.OnClicked, self, OnResetClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSave.OnClicked, self, OnSaveClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnChangeStyle.OnClicked, self, OnChangeStyleClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_LAYOUT_STYLE_CHANGED, self, OnLayoutStyleChanged)
end

function UISettingLayout:OnExit()
    if self.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
    SwitchSubSetVisble(self, self.nOpenFrom, false)
end

function UISettingLayout:SetTarget(nTargetUniqueId)
    local tbTargetData = self.tbTargetWidgetMap[nTargetUniqueId]
    if not tbTargetData then
        return
    end
    ClearTarget(self)
    log("SetTarget,nTargetUniqueId=",nTargetUniqueId,tbTargetData)
    if tbTargetData then
        self.nTargetUniqueId = nTargetUniqueId
        local pBackground = tbTargetData.pWidget.Background
        pBackground.DrawAs = DRAW_TYPE_BOX
        if tbTargetData.pExpandWidget then
            tbTargetData.pExpandWidget:SetVisibility(ESlateVisibility_HitTestInvisible)
        end
    end

    local tbLayoutData = self.SettingLayout:GetLayout(self.nOpenFrom, nTargetUniqueId)
    --alpha
    RefreshAlpha(self, tbLayoutData.nAlpha)

    --scale
    RefreshScale(self, tbLayoutData.nScale)
end

return UISettingLayout
