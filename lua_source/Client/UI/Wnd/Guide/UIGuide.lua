-----------------------------------------------------
--File Name    : UIGuide.lua
--Author       : Ran Jie
--Create Time  : 2017-06-7
--Description  : 新手指引界面
--Param        : 空
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIGuide = luaclass("UIGuide",WndBase)


-- import require
local ClientEventDef        = require("ClientEventDef")
local DelayTimer            = require("DelayTimer")
local UISetUtils            = require("UISetUtils")
local GuideDebug            = require("GuideDebug")
local EventManager          = require("EventManager")
local UIDef                 = require("UIDef")
local UIManager             = require("UIManager")
local WidgetAnimationHandle = require("WidgetAnimationHandle")
local L10N                  = require("L10N")

--local variable
local DRAG_DIRECTION = 
{
    LEFT = 0,
    RIGHT = 1,
    UP = 2,
    DOWN = 3,
    RHORIZONTAL = 4,
    DEFAULT = 5,
}
local GUIDE_POS =
{
    FOLLOW = 0,
    LEFT = 1,
    RIGHT = 2,
    BOTTOM = 3,
    TOP = 4,
    BOTTOM_TOP = 5,
    TIP_LEFT = 10,
    TIP_CENTER1 = 11,
	TIP_CENTER2 = 14,
    TIP_RIGHT1 = 12,
    TIP_RIGHT2 = 13
}
local MULTIPLE                                  = 2
local CLICK_EFFECT_OFFSET                       = {X = 0, Y = 0}
local BLACK_SCREEN                              = LinearColor{R = 0, G = 0, B = 0, A = 1.0}
local TRANSPARENT_SCREEN                        = LinearColor{R = 0, G = 0, B = 0, A = 0}
local TRANSPARENT_COLOR                         = LinearColor{R = 1, G = 1, B = 1, A = 0}
local WHITE_COLOR                               = LinearColor{R = 1.0, G = 1.0, B = 1.0, A = 1.0}
local GUIDE_TEXT_OFFSET_X                       = 2
local GUIDE_TEXT_BOTTOM_OFFSET_Y                = 100
local GUIDE_TEXT_OFFSET_Y                       = 180
local GUIDE_TEXT_BOTTOM_TOP_OFFSET_Y            = 530
local PIC_GUIDE_DELAY                           = 2
local MODAL_CLICK_UNLOCK                        = 3
local nDelayClickTickCount                      = 0
local nDelayResponseTickCount                   = 0
local GUIDE_TIP_LEFT_OFFSET_LEFT                = 150
local GUIDE_TIP_LEFT_OFFSET_BOTTOM              = 220
local GUIDE_TIP_CENTER_OFFSET_BOTTOM1           = 190
local GUIDE_TIP_CENTER_OFFSET_BOTTOM2           = 650
local GUIDE_TIP_RIGHT_OFFSET_RIGHT1             = 220
local GUIDE_TIP_RIGHT_OFFSET_RIGHT2             = 120
local GUIDE_TIP_RIGHT_OFFSET_BOTTOM1            = 120
local GUIDE_TIP_RIGHT_OFFSET_BOTTOM2            = 120

--member variable
UIGuide.bClickAnywhere              = false
UIGuide.DelayTimerHandle            = nil
UIGuide.pDelayResponseHandler       = nil
UIGuide.DragOnlyDelayTimerHandle    = nil
UIGuide.bModal                      = false
UIGuide.nGuideTextPos               = GUIDE_POS.LEFT
UIGuide.bDown                       = false
UIGuide.nClickCount                 = 0
UIGuide.GuideActionRef              = nil
UIGuide.bActivate                   = true
UIGuide.tbCircleClick               = nil
UIGuide.bEffectAnima                = true
UIGuide.pDelayClickHandler          = nil
UIGuide.BlackTimer                  = nil
UIGuide.tbClickEffects              = nil
UIGuide.tbTips                      = nil
--local function
local function ClearGuideText(self)
    self:DebugLog("ClearGuideText")
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrTextBg:SetContentColorAndOpacity(TRANSPARENT_COLOR)
    pWidgetRef.bdrTextBg:SetBrushColor(TRANSPARENT_COLOR)
end

--防止在已经销毁的状态下 再次销毁
local function CloseSelf(self)
    self:DebugLog("CloseSelf")
    local Wnd = UIManager:GetWnd(UIDef.UI_GUIDE)
    if Wnd then
        self:CloseSelf()
    end
end

local function HideAll(self)
    self:DebugLog("HideAll")
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvsTask:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.Select:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.Click:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.bdrTextBg.Slot:SetPosition(Vector2D{X = -100, Y = -100})
    pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.cvsDrag:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgHeadLeft:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgHeadRight:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgHandL:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgHead:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgEffect:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.bdrBlackScreen:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtClickAnyWhere:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgShipHelp:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.vboxCentralGuide:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtCentralGuide:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.resAreaMask:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.img_clickTip1:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.img_clickTip2:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.sbMediaPlayer:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgMediaBG:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ovlShipWeaponText:SetVisibility(ESlateVisibility.Collapsed)
    ClearGuideText(self)
    self:ClearBlackTimerHandler()
    self:ResetCircleClickTable()
    self:ResetClickEffects()
    self:ResetTips()
    self.nClickCount = 0
    self.bEffectAnima = true
    self:StopAnimation("animSelect")
    self:StopAnimation("animHead")
    self:StopAnimation("animHeadRight")
    self:StopAnimation("animHeadLeft")
    self:StopAnimation("animInSelect")
    self:StopAnimation("animInClick")
    self:StopAnimation("animText")
    self:StopAnimation("animEffect")
	self:StopAnimation("animHandLeft")
    self:StopAnimation("animHandRight")
    self:StopAnimation("animHandUp")
    self:StopAnimation("animPageDown01")
    self:StopAnimation("animPageDown02")
end

local function IsNormalGuideTextPosType(self, nGuideTextPos)
    return nGuideTextPos < GUIDE_POS.TIP_LEFT
end

local function SetModalState(self, bIsModal, BoxSize, BoxPos, bAnimaMode)
    local pWidgetRef = self.pWidgetRef
    if bIsModal then
        local pGeometry = pWidgetRef.cvsRoot:GetCachedGeometry()
        local RootSize = SlateBlueprintLibrary.GetLocalSize(pGeometry)
        local U = (BoxPos.X / RootSize.X) * 2
        local V = (BoxPos.Y / RootSize.Y) * 2
        local UOffset = ((BoxSize.X / 2) / RootSize.X) * 2
        local VOffset = ((BoxSize.Y / 2) / RootSize.Y) * 2
        local CenterOffsetX = U - 1
        local CenterOffsetY = V - 1
        if(CenterOffsetX > 0)then
            U = - CenterOffsetX - UOffset
        else
            U = - CenterOffsetX - UOffset
        end
        if(CenterOffsetY > 0)then
            V = - CenterOffsetY - VOffset
        else
            V = - CenterOffsetY - VOffset
        end
        local DynMaterial = pWidgetRef.imgEffect:GetDynamicMaterial()
        if(BoxSize.X == 0 and BoxSize.Y == 0)then
            DynMaterial:SetScalarParameterValue("Location_U", 2)
            DynMaterial:SetScalarParameterValue("Location_V", 2)
        else
            DynMaterial:SetScalarParameterValue("Location_U", U)
            DynMaterial:SetScalarParameterValue("Location_V", V)
        end
        
        DynMaterial:SetScalarParameterValue("BorderWidth", 0.6)
    else
        BoxSize = {X = 0, Y = 0}
        BoxPos = {X = 0, Y = 0}
        pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgEffect:SetVisibility(ESlateVisibility.Collapsed)
    end
    if bAnimaMode then
        BoxSize = {X = 0, Y = 0}
    end
    self:DebugLog("SetModalState BoxSize x = " .. BoxSize.X .. " Y = " .. BoxSize.Y .. " BoxPos.X = " .. BoxPos.X .. " Y = " .. BoxPos.Y .. " bIsModal = " .. tostring(bIsModal))
    self.pbMaskButton:SetMaskInfo(BoxPos, BoxSize)
end

local function CorrectTextPos(self, nGuidePos, EffectSize, EffectPos)
    self:DebugLog("CorrectTextPos")
    local pWidgetRef = self.pWidgetRef
    local pGeometry = pWidgetRef.cvsRoot:GetCachedGeometry()
    local RootSize = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local TextPos = {X = 0, Y = 0}
    local TextGeometry = pWidgetRef.bdrTextBg:GetCachedGeometry()
    local TextSize = SlateBlueprintLibrary.GetLocalSize(TextGeometry)
    if nGuidePos == GUIDE_POS.LEFT then
        TextPos.X = GUIDE_TEXT_OFFSET_X
        TextPos.Y = RootSize.Y / 2 - GUIDE_TEXT_OFFSET_Y
    elseif nGuidePos == GUIDE_POS.RIGHT then
        TextPos.X = RootSize.X - GUIDE_TEXT_OFFSET_X - TextSize.X
        TextPos.Y = RootSize.Y / 2 - GUIDE_TEXT_OFFSET_Y 
    elseif nGuidePos == GUIDE_POS.BOTTOM then
        TextPos.X = RootSize.X / 2 - TextSize.X / 2
        TextPos.Y = RootSize.Y - TextSize.Y - GUIDE_TEXT_BOTTOM_OFFSET_Y
    elseif nGuidePos == GUIDE_POS.TOP then
        TextPos.X = RootSize.X / 2 - TextSize.X / 2
        TextPos.Y = RootSize.Y / 2 - GUIDE_TEXT_OFFSET_Y
    elseif nGuidePos == GUIDE_POS.BOTTOM_TOP then
        TextPos.X = RootSize.X / 2 - TextSize.X / 2
        TextPos.Y = RootSize.Y - GUIDE_TEXT_BOTTOM_TOP_OFFSET_Y
    elseif nGuidePos == GUIDE_POS.TIP_LEFT then
        TextPos.X = GUIDE_TIP_LEFT_OFFSET_LEFT
        TextPos.Y = RootSize.Y / 2 + GUIDE_TIP_LEFT_OFFSET_BOTTOM
    elseif nGuidePos == GUIDE_POS.TIP_RIGHT1 then
        TextPos.X = RootSize.X - TextSize.X - GUIDE_TIP_RIGHT_OFFSET_RIGHT1
        TextPos.Y = RootSize.Y / 2 + GUIDE_TIP_RIGHT_OFFSET_BOTTOM1
    elseif nGuidePos == GUIDE_POS.TIP_CENTER1 then
        TextPos.X = RootSize.X / 2 - TextSize.X / 2
        TextPos.Y = RootSize.Y - TextSize.Y - GUIDE_TIP_CENTER_OFFSET_BOTTOM1
	elseif nGuidePos == GUIDE_POS.TIP_CENTER2 then
        TextPos.X = RootSize.X / 2 - TextSize.X / 2
        TextPos.Y = RootSize.Y - TextSize.Y - GUIDE_TIP_CENTER_OFFSET_BOTTOM2
    elseif nGuidePos == GUIDE_POS.TIP_RIGHT2 then
        TextPos.X = RootSize.X - TextSize.X - GUIDE_TIP_RIGHT_OFFSET_RIGHT2
        TextPos.Y = RootSize.Y / 2 + GUIDE_TIP_RIGHT_OFFSET_BOTTOM2
    else
        if EffectPos and EffectSize then
            local CenterPos = {X = RootSize.X / 2, Y = RootSize.Y / 2}
            TextPos = {X = EffectPos.X, Y = EffectPos.Y}
            if(TextPos.X < CenterPos.X and TextPos.Y < CenterPos.Y)then
                --左上
                TextPos.X = TextPos.X + EffectSize.X
                TextPos.Y = TextPos.Y + EffectSize.Y / 2
            elseif(TextPos.X > CenterPos.X and TextPos.Y < CenterPos.Y)then
                --右上
                TextPos.X = TextPos.X - TextSize.X
                TextPos.Y = TextPos.Y + EffectSize.Y
            elseif(TextPos.X < CenterPos.X and TextPos.Y > CenterPos.Y)then
                --左下
                TextPos.X = TextPos.X + EffectSize.X
                TextPos.Y = TextPos.Y - TextSize.Y
            elseif(TextPos.X > CenterPos.X and TextPos.Y > CenterPos.Y)then
                --右下
                TextPos.X = TextPos.X - TextSize.X
                TextPos.Y = TextPos.Y - TextSize.Y
            end
        end
    end
    self:DebugLog("CorrectTextPos x = " .. TextPos.X .. " Y = " .. TextPos.Y .. " rootsize x = " .. RootSize.X .. " Y = " .. RootSize.Y)
    pWidgetRef.bdrTextBg.Slot:SetPosition(Vector2D{X = TextPos.X, Y = TextPos.Y})
end

local function DelayPictureGuide(self)
    self:DebugLog("DelayPictureGuide")
    self.bClickAnywhere = true
    self.DelayTimerHandle = nil
end

local function AddClickEffect(self, tbEffects, pEffectWidget, szEffectType)
    self:DebugLog("AddClickEffect szEffectType = " .. tostring(szEffectType))
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.csvClickEffect:AddChildToCanvas(pEffectWidget.pWidgetRef)
    local tbTemp = {}
    tbTemp.InUse = true
    tbTemp.pWidgetRef = pEffectWidget
    pEffectWidget:SetVisble(szEffectType, false)
    table.insert(tbEffects, tbTemp)
end

local function GetOneClickEffect(self, tbEffects, szEffectType)
    self:DebugLog("GetOneClickEffect szEffectType = " .. tostring(szEffectType))
    local pSelectWidget = nil
    for i, v in ipairs(tbEffects) do
        if not v.InUse then
            pSelectWidget = v.pWidgetRef
            v.InUse = true
            break
        end
    end
    return pSelectWidget
end

local function CreateOneClickEffect(self, tbEffects, szEffectType)
    self:DebugLog("CreateOneClickEffect szEffectType = " .. tostring(szEffectType))
    local pEffect = nil
    local PrefabHelper = self.PrefabHelper
    if szEffectType == "circleClick" then
        pEffect = PrefabHelper:CreatePrefab(UIDef.UP_CIRCLE_CLICK_EFFECT)
    elseif szEffectType == "squareClick" then
        pEffect = PrefabHelper:CreatePrefab(UIDef.UP_SQUARE_CLICK_EFFECT)
    elseif szEffectType == "radarMapClick" then 
        pEffect = PrefabHelper:CreatePrefab(UIDef.UP_RADAR_CLICK_EFFECT)
    elseif szEffectType == "shipTurnEffect" then 
        pEffect = PrefabHelper:CreatePrefab(UIDef.UP_GUIDE_SHIPTURN_EFFECT)
    end
    AddClickEffect(self, tbEffects, pEffect, szEffectType)
    return pEffect
end

local function GetOrCreateClickEffect(self, szEffectType)
    self:DebugLog("GetOrCreateClickEffect szEffectType = " .. tostring(szEffectType))
    local tbClickEffects = self.tbClickEffects
    local pWidgetRef = self.pWidgetRef
    local pSelectWidget = nil
    if not szEffectType  or szEffectType == "" then
        return pSelectWidget
    end
    if szEffectType == "Click" then
        pSelectWidget = pWidgetRef[szEffectType]
        return pSelectWidget
    end
    if szEffectType == "Box" then
        return nil
    end
    local tbEffects = tbClickEffects[szEffectType]
    if not tbEffects then
        tbEffects = {}
        tbClickEffects[szEffectType] = tbEffects
        pSelectWidget = CreateOneClickEffect(self, tbEffects, szEffectType)
        return pSelectWidget
    end
    pSelectWidget = GetOneClickEffect(self, tbEffects)
    if not pSelectWidget then
        pSelectWidget = CreateOneClickEffect(self, tbEffects, szEffectType)
    end
    return pSelectWidget
end

local function OnUserWidgetTouchEnded(self, pGeometry, pMouseEvent)
    self.EventHelper:FireEvent(ClientEventDef.EV_USER_WIDGET_TOUCH_END, UIDef.UI_GUIDE, pGeometry, pMouseEvent)
end

--public interface
function UIGuide:ResetClickEffects()
    self:DebugLog("ResetClickEffects")
    for szEffectType, tbEffects in pairs(self.tbClickEffects) do
        for i, tbEffect in ipairs(tbEffects) do
            if i == 1 then
                tbEffect.InUse = false
                tbEffect.pWidgetRef:SetVisble(szEffectType, false)
            else
                self.PrefabHelper:UnbindPrefab(tbEffect.pWidgetRef)
                tbEffects[i] = nil
            end
        end
    end
end

function UIGuide:ResetTips()
    self:DebugLog("ResetTips")
    for i, tbTip in ipairs(self.tbTips) do
        if i == 1 then
            tbTip.InUse = false
            tbTip.pWidgetRef:SetVisble(false)
        else
            self.PrefabHelper:UnbindPrefab(tbTip.pWidgetRef)
            tbTip[i] = nil
        end
    end
end

function UIGuide:AddCircleClick(pWidgetRef)
    self:DebugLog("AddCircleClick")
    local tbTemp = {}
    tbTemp.InUse = false
    tbTemp.pWidgetRef = pWidgetRef
    pWidgetRef.imgCycleGlow:SetVisibility(ESlateVisibility.Collapsed)
    table.insert(self.tbCircleClick, tbTemp)
end

function UIGuide:GetCircleClick()
    self:DebugLog("GetCircleClick")
    local pWidgetRef = nil
    for i, v in ipairs(self.tbCircleClick) do
        if not v.InUse then
            pWidgetRef = v.pWidgetRef
            v.InUse = true
            break
        end
    end
    return pWidgetRef
end

function UIGuide:ResetCircleClickTable()
    self:DebugLog("ResetCircleClickTable")
    for i, v in ipairs(self.tbCircleClick) do
        v.pWidgetRef.imgCycleGlow:SetVisibility(ESlateVisibility.Collapsed)
        v.InUse = false
    end
end

function UIGuide:GetSelectEffect(szSelectImgWidget)
    self:DebugLog("GetSelectEffect")
    local pWidgetRef = self.pWidgetRef
    local SelectWidget = nil
    if szSelectImgWidget == "Click" then
        SelectWidget = pWidgetRef[szSelectImgWidget]
    elseif szSelectImgWidget == "circleClick" then
        local upCircleClick = self:GetCircleClick()
        if upCircleClick then
            SelectWidget = upCircleClick.imgCycleGlow
        end
    elseif szSelectImgWidget == "circleClickAnim" then
        SelectWidget = pWidgetRef[szSelectImgWidget].imgCycleGlow
    elseif szSelectImgWidget == "squareClick" then
        SelectWidget = pWidgetRef[szSelectImgWidget].imgFxRadarMapGlow
    elseif szSelectImgWidget == "radarMapClick" then    
        SelectWidget = pWidgetRef[szSelectImgWidget].imgFxRadarMapGlow
    else
        SelectWidget = pWidgetRef[szSelectImgWidget]
    end
    return SelectWidget
end

--设置选中多个控件的指引和文字说明
function UIGuide:SetSelectMultipleDelay(Pos, Size, szSelectImgWidget, szGuideText, bModal, bClickAnywhere, nGuidePos, tbRotation)
    self:DebugLog("SetSelectMultipleDelay")
    local count = 0
    for i, pPos in ipairs(Pos) do
        local pSize = Size[i]
        local bRotation = tbRotation[i]
        self:SetSelectDelay(pPos, pSize, szSelectImgWidget, szGuideText, bModal, bClickAnywhere, nGuidePos, bRotation)
        count = count + 1
    end
end

--设置选中指引和文字说明
function UIGuide:SetSelectDelay(Pos, Size, szSelectImgWidget, szGuideText, bModal, bClickAnywhere, nGuidePos, bRotation)
    self:DebugLog("SetSelectDelay")
    local pWidgetRef = self.pWidgetRef
    local pGeometry = pWidgetRef.cvsRoot:GetCachedGeometry()
    self:DebugLog("pos x = "..Pos.X.." y = "..Pos.Y.." size x = "..Size.X.." y = "..Size.Y .. " bRotation = " .. tostring(bRotation) .. " bModal = " .. tostring(bModal))
    local LocalPos = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, Vector2D{X = Pos.X, Y = Pos.Y})
    local SelectWidget = GetOrCreateClickEffect(self, szSelectImgWidget)
    local tbLocalPos = {X = LocalPos.X, Y = LocalPos.Y}
    if type(bRotation) == "number" then
        if bRotation == -90 then
            tbLocalPos.X = tbLocalPos.X
            tbLocalPos.Y = tbLocalPos.Y - Size.Y
            local nTemp = Size.Y
            Size.Y = Size.X
            Size.X = nTemp
        elseif bRotation == 90 then
            tbLocalPos.X = tbLocalPos.X - Size.X
            tbLocalPos.Y = tbLocalPos.Y
            local nTemp = Size.Y
            Size.Y = Size.X
            Size.X = nTemp
        elseif bRotation == 180 then
            tbLocalPos.X = tbLocalPos.X - Size.X
            tbLocalPos.Y = tbLocalPos.Y - Size.Y
        end
    else
        if bRotation then
            tbLocalPos.X = tbLocalPos.X - Size.X
            tbLocalPos.Y = tbLocalPos.Y - Size.Y
        end
    end
    self:DebugLog("LocalPos x = "..LocalPos.X.." y = "..LocalPos.Y.." size x = "..Size.X.." y = "..Size.Y)
    local EffectSize = {X = 0, Y = 0}
    local EffectPos = {X = 0, Y = 0}
    local BoxPos = {X = 0, Y = 0}
    local bAnimaMode = nil
    if SelectWidget ~= nil then
        local OffsetSize = {X = 0, Y = 0}
        if szSelectImgWidget == "Click" then
            local nSize = math.min(Size.X * MULTIPLE, Size.Y * MULTIPLE)
            EffectSize.X = nSize
            EffectSize.Y = nSize
            OffsetSize.X = (EffectSize.X - Size.X) / 2
            OffsetSize.Y = (EffectSize.Y - Size.Y) / 2
            EffectPos.X = tbLocalPos.X + EffectSize.X / 2 - OffsetSize.X + CLICK_EFFECT_OFFSET.X
            EffectPos.Y = tbLocalPos.Y + EffectSize.Y / 2 - OffsetSize.Y + CLICK_EFFECT_OFFSET.Y
            BoxPos.X = tbLocalPos.X
            BoxPos.Y = tbLocalPos.Y
        elseif szSelectImgWidget == "circleClick" then
            local nSize = math.min(Size.X * MULTIPLE, Size.Y * MULTIPLE)
            EffectSize.X = nSize
            EffectSize.Y = nSize
            OffsetSize.X = (EffectSize.X - Size.X) / 2
            OffsetSize.Y = (EffectSize.Y - Size.Y) / 2
            EffectPos.X = tbLocalPos.X + EffectSize.X / 2 - OffsetSize.X + CLICK_EFFECT_OFFSET.X
            EffectPos.Y = tbLocalPos.Y + EffectSize.Y / 2 - OffsetSize.Y + CLICK_EFFECT_OFFSET.Y
            BoxPos.X = tbLocalPos.X
            BoxPos.Y = tbLocalPos.Y
        elseif szSelectImgWidget == "circleClickAnim" then
            local nSize = math.min(Size.X * MULTIPLE, Size.Y * MULTIPLE)
            EffectSize.X = nSize
            EffectSize.Y = nSize
            OffsetSize.X = (EffectSize.X - Size.X) / 2
            OffsetSize.Y = (EffectSize.Y - Size.Y) / 2
            EffectPos.X = tbLocalPos.X + EffectSize.X / 2 - OffsetSize.X + CLICK_EFFECT_OFFSET.X
            EffectPos.Y = tbLocalPos.Y + EffectSize.Y / 2 - OffsetSize.Y + CLICK_EFFECT_OFFSET.Y
            BoxPos.X = tbLocalPos.X
            BoxPos.Y = tbLocalPos.Y
            bAnimaMode = true
            local pbCircle = pWidgetRef[szSelectImgWidget]
            local pAnimRef = pbCircle["animCycleClickGlow"]
            pbCircle:PlayAnimation(pAnimRef, 0, 1, EUMGSequencePlayMode.Forward, 1)
            self:OnClickBg()
        elseif szSelectImgWidget == "squareClick" then
            EffectSize.X = Size.X * MULTIPLE
            EffectSize.Y = Size.Y * MULTIPLE
            OffsetSize.X = (EffectSize.X - Size.X) / 2
            OffsetSize.Y = (EffectSize.Y - Size.Y) / 2
            EffectPos.X = LocalPos.X + EffectSize.X / 2 - OffsetSize.X + CLICK_EFFECT_OFFSET.X
            EffectPos.Y = LocalPos.Y + EffectSize.Y / 2 - OffsetSize.Y + CLICK_EFFECT_OFFSET.Y
            BoxPos.X = tbLocalPos.X
            BoxPos.Y = tbLocalPos.Y
        elseif szSelectImgWidget == "radarMapClick" then
            EffectSize.X = Size.X
            EffectSize.Y = Size.Y
            OffsetSize.X = (EffectSize.X - Size.X) / 2
            OffsetSize.Y = (EffectSize.Y - Size.Y) / 2
            EffectPos.X = LocalPos.X + EffectSize.X / 2 - OffsetSize.X + CLICK_EFFECT_OFFSET.X
            EffectPos.Y = LocalPos.Y + EffectSize.Y / 2 - OffsetSize.Y + CLICK_EFFECT_OFFSET.Y
            BoxPos.X = tbLocalPos.X
            BoxPos.Y = tbLocalPos.Y
        elseif szSelectImgWidget == "shipTurnEffect" then
            local nSize = math.min(Size.X * MULTIPLE, Size.Y * MULTIPLE)
            EffectSize.X = nSize
            EffectSize.Y = nSize
            OffsetSize.X = (EffectSize.X - Size.X) / 2
            OffsetSize.Y = (EffectSize.Y - Size.Y) / 2
            EffectPos.X = LocalPos.X + 35
            EffectPos.Y = LocalPos.Y + 135
            BoxPos.X = tbLocalPos.X
            BoxPos.Y = tbLocalPos.Y
        else
            EffectSize.X = Size.X * 1.1
            EffectSize.Y = Size.Y * 1.5
            OffsetSize.X = (EffectSize.X - Size.X) / 2
            OffsetSize.Y = (EffectSize.Y - Size.Y) / 2
            EffectPos.X = LocalPos.X - OffsetSize.X + CLICK_EFFECT_OFFSET.X
            EffectPos.Y = LocalPos.Y - OffsetSize.Y + CLICK_EFFECT_OFFSET.Y
            BoxPos.X = LocalPos.X + CLICK_EFFECT_OFFSET.X
            BoxPos.Y = LocalPos.Y + CLICK_EFFECT_OFFSET.Y
        end
        if bModal ~= nil then
            SetModalState(self, bModal, Size, BoxPos, bAnimaMode)
        end
        if szSelectImgWidget == "Click" then --历史遗留问题
            SelectWidget.slot:SetSize(Vector2D{X = EffectSize.X, Y = EffectSize.Y})
            SelectWidget.slot:SetPosition(Vector2D{X = EffectPos.X, Y = EffectPos.Y})
            SelectWidget:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        elseif szSelectImgWidget == "shipTurnEffect" then
            -- SelectWidget:SetSize(szSelectImgWidget, Vector2D{X = EffectSize.X, Y = EffectSize.Y})
            SelectWidget:SetPosition(szSelectImgWidget, Vector2D{X = EffectPos.X, Y = EffectPos.Y})
            SelectWidget:SetVisble(szSelectImgWidget, true)
        else
            SelectWidget:SetSize(szSelectImgWidget, Vector2D{X = EffectSize.X, Y = EffectSize.Y})
            SelectWidget:SetPosition(szSelectImgWidget, Vector2D{X = EffectPos.X, Y = EffectPos.Y})
            SelectWidget:SetVisble(szSelectImgWidget, true)
        end
        self:DebugLog("SetSelectDelay ClickEffect, pos x = " .. EffectPos.X .. " y = " .. EffectPos.Y .. " size x = " .. EffectSize.X .. " y = " .. EffectSize.Y)
        --显示指引和动画
        local InAnim = pWidgetRef["animIn"..szSelectImgWidget]
        if InAnim then
            self:PlayAnimation("animIn"..szSelectImgWidget, 0, 1, EUMGSequencePlayMode.Forward, 1)
        end
        local SelectAnim = pWidgetRef["anim"..szSelectImgWidget]
        if SelectAnim then
            self:PlayAnimation("anim"..szSelectImgWidget, 0, 0, EUMGSequencePlayMode.Forward, 1)
        end
    elseif szSelectImgWidget == "Box" then
        BoxPos = {X = LocalPos.X, Y = LocalPos.Y}
        EffectSize.X = Size.X
        EffectSize.Y = Size.Y
        if bModal ~= nil then
            SetModalState(self, bModal, Size, BoxPos)
        end
    else
        EffectSize.X = Size.X
        EffectSize.Y = Size.Y
        EffectPos.X = LocalPos.X
        EffectPos.Y = LocalPos.Y
        if bModal ~= nil then
            SetModalState(self, bModal, {X = 0, Y = 0}, {X = 0, Y = 0})
        end
    end
    self:DebugLog(" UIGuide:SetSelectDelay PlayAnimation")
    if bClickAnywhere ~= nil then
        self.bClickAnywhere = bClickAnywhere
    end
    if szGuideText and szGuideText ~= "" then
        CorrectTextPos(self, nGuidePos, Size, BoxPos)
        self:PlayAnimation("animText", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
end

function UIGuide:SetBornSelectArea(tbParams)
    self:DebugLog("SetBornSelectArea")
    local Pos, Size, ClickPos, ClickSize, szGuideText, szGuideIcon, nGuidePos, GuideActionRef, bRotation = 
    tbParams.Pos, tbParams.Size, tbParams.ClickPos, tbParams.ClickSize, tbParams.szGuideText, tbParams.szGuideIcon, tbParams.nGuidePos, tbParams.GuideActionRef, tbParams.bRotation
    local pWidgetRef = self.pWidgetRef
    self.bModal = false
    self.bEffectAnima = false
    pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.pbMaskButton.btnFullScreen:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.ovlTipContent:SetVisibility(ESlateVisibility.Collapsed)
    self.GuideActionRef = GuideActionRef
    if szGuideIcon ~= nil and szGuideIcon ~= "" then
        pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
        if szGuideText ~= nil and szGuideText ~= "" then
            pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtIconContent:SetText(szGuideText)
            local pGuideIcon = szGuideIcon:load()
            UISetUtils.SetImageBrushRes(pWidgetRef.imgGuideIcon, pGuideIcon, false)
        end
    else
        pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.Collapsed)
        if szGuideText ~= nil and szGuideText ~= "" then
            pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtContent:SetText(szGuideText)
        else
            pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
    self.nGuideTextPos = nGuidePos
    -- --延迟计算显示位置
    if self.DelayTimerHandle ~= nil then
        DelayTimer:ClearTimer(self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
    self:DebugLog(" UIGuide Pos Type = " .. type(Pos) .. " Size Type = " .. type(Size))
    self.DelayTimerHandle = DelayTimer:DelayRun(function()
        self:BornSelectAreaDelay(Pos, Size, ClickPos, ClickSize, nGuidePos, bRotation)
    end, 0.2)
end

function UIGuide:BornSelectAreaDelay(tbPos, tbSize,  ClickPos, ClickSize, nGuidePos, bRotation)
    self:DebugLog("BornSelectAreaDelay ClickPos.X = " .. ClickPos.X .. "ClickPos.Y = " .. ClickPos.Y .." ClickSize.X = " .. ClickSize.X .." ClickSize.Y = " .. ClickSize.Y)
    local pWidgetRef = self.pWidgetRef
    local pGeometry = pWidgetRef.cvsRoot:GetCachedGeometry()
    local pLocalPos = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, Vector2D{X = ClickPos.X, Y = ClickPos.Y})
    self.pbMaskButton:SetMaskInfo(pLocalPos, ClickSize)
    self:PlayAnimation("animText", 0, 1, EUMGSequencePlayMode.Forward, 1)
    CorrectTextPos(self, nGuidePos)
    self:SetBornArealMask(tbPos, tbSize)
    pWidgetRef.resAreaMask:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.DelayTimerHandle = nil
end

function UIGuide:SetBornArealMask(tbPos, tbSize)
    self:DebugLog("SetBornArealMask")
    local pWidgetRef = self.pWidgetRef
    local pGeometry = pWidgetRef.cvsRoot:GetCachedGeometry()
    local RootSize = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local RootSizeX = RootSize.X
    local RootSizeY = RootSize.Y
    local DynMaterial = pWidgetRef.resAreaMask:GetDynamicMaterial()
    DynMaterial:SetScalarParameterValue("SizeX", RootSizeX)
    DynMaterial:SetScalarParameterValue("SizeY", RootSizeY)
    for i,  Pos in ipairs(tbPos) do
        local Size = tbSize[i]
        local LocalPos = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, Vector2D{X = Pos.X, Y = Pos.Y})
        local U = (LocalPos.X / RootSizeX) * 2
        local V = (LocalPos.Y / RootSizeY) * 2
        U = 1 - U
        V = 1 - V
        local UOffset = 0--((Size.X / 2) / RootSizeX) 
        local VOffset = 0--((Size.Y / 2) / RootSizeY)
        U = U + UOffset
        V = V + VOffset
        local nScale = Size.Y/4000 --7120这是遮罩材质中，1radius对应的像素
        if(Size.X == 0 and Size.Y == 0)then
            DynMaterial:SetScalarParameterValue("Location_U"..i, 2)
            DynMaterial:SetScalarParameterValue("Location_V"..i, 2)
            DynMaterial:SetScalarParameterValue("Radius"..i, nScale)
        else
            DynMaterial:SetScalarParameterValue("Location_U"..i, U)
            DynMaterial:SetScalarParameterValue("Location_V"..i, V)
            DynMaterial:SetScalarParameterValue("Radius"..i, nScale)
        end
    end
end

function UIGuide:HideTextGuide()
    self:DebugLog("HideTextGuide")
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.Collapsed)
end

--SetSelectInfo的功能型模式，此模式不会是action具备任何响应行为
--用于跟完全型action做配合使用
--例：显示多个不同父级高亮效果
function UIGuide:SetSimpleSelectInfo(tbParams)
    self:DebugLog("SetSimpleSelectInfo")
    local Pos, Size, szSelectImgWidget, szGuideText, szGuideIcon, nGuidePos, GuideActionRef, bRotation = 
    tbParams.Pos, tbParams.Size, tbParams.szSelectImgWidget, tbParams.szGuideText, tbParams.szGuideIcon, tbParams.nGuidePos, tbParams.GuideActionRef, tbParams.bRotation
    local tbSize = {X = Size.X, Y = Size.Y}
    if tbSize.X == 0 and tbSize.Y == 0 and szSelectImgWidget and szSelectImgWidget ~= "" then
        GuideDebug:LogError(" SetSimpleSelectInfo UIGuide:SetSimpleSelectInfo,select widget size is wrong")
        CloseSelf(self)
        return false
    end
    self.bDown = false
    self.GuideActionRef = GuideActionRef
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.ovlTipContent:SetVisibility(ESlateVisibility.Collapsed)
    if szGuideIcon ~= nil and szGuideIcon ~= "" then
        pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
        if szGuideText ~= nil and szGuideText ~= "" then
            pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtIconContent:SetText(szGuideText)
            local pGuideIcon = szGuideIcon:load()
            UISetUtils.SetImageBrushRes(pWidgetRef.imgGuideIcon, pGuideIcon, false)
        end
    else
        pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.Collapsed)
        if szGuideText ~= nil and szGuideText ~= "" then
            pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtContent:SetText(szGuideText)
        else
            pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
    self.nGuideTextPos = nGuidePos
    --延迟计算显示位置
    self.TimerHelper:NewTimerMethod(self, function()
        self:SetSelectDelay(Pos, Size, szSelectImgWidget, szGuideText, nil, nil, nGuidePos, bRotation)
    end, 0.2, false)
    return true
end

function UIGuide:SetSelectInfo(tbParams)
    self:DebugLog("SetSelectInfo")
    local Pos, Size, szSelectImgWidget, szGuideText, szGuideIcon, bModal, bClickAnywhere, nGuidePos, GuideActionRef, bRotation, bMultiple, bEffectAnima = 
    tbParams.Pos, tbParams.Size, tbParams.szSelectImgWidget, tbParams.szGuideText, tbParams.szGuideIcon, tbParams.bModal, tbParams.bClickAnywhere, tbParams.nGuidePos, tbParams.GuideActionRef, tbParams.bRotation, tbParams.bMultiple, tbParams.bEffectAnima
    if not bMultiple then 
        local tbSize = {X = Size.X, Y = Size.Y}
        if tbSize.X == 0 and tbSize.Y == 0 and szSelectImgWidget and szSelectImgWidget ~= "" then
            GuideDebug:LogError("UIGuide:SetSelectDelay,select widget size is wrong")
            CloseSelf(self)
            return false
        end
    else
        for i, pPos in ipairs(Pos) do
            local pSize = Size[i]
            if not pSize or (pSize.X == 0 and pSize.Y == 0 and szSelectImgWidget and szSelectImgWidget ~= "") then
                GuideDebug:LogError("UIGuide:SetSelectDelay,select widget size is wrong")
                CloseSelf(self)
                return false
            end
        end
    end
    self.bDown = false
    self.bEffectAnima = bEffectAnima == nil and true or bEffectAnima
    self.GuideActionRef = GuideActionRef
    local pWidgetRef = self.pWidgetRef
    self:DebugLog("UIGuide:SetSelectInfo,bModal = "..tostring(bModal) .. " clickAnywhere = " .. tostring(bClickAnywhere))
    if bClickAnywhere then
        pWidgetRef.bdrBlackScreen:SetBrushColor(TRANSPARENT_SCREEN)
        pWidgetRef.bdrBlackScreen:SetVisibility(ESlateVisibility.Visible)
        self:DebugLog("UIGuide:SetSelectInfo Show (bdrBlackScreen)")
        pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.img_clickTip1:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.img_clickTip2:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    elseif bModal then
        pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.pbMaskButton.btnFullScreen:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.Collapsed)
    end
    self.bModal = bModal
    --指引半身像和文字
    self:DebugLog("szGuideIcon="..tostring(szGuideIcon).." szGuideText="..tostring(szGuideText))
    if not IsNormalGuideTextPosType(self, nGuidePos) then
        pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
        if szGuideText ~= nil and szGuideText ~= "" then
            pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.ovlTipContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtTipContent:SetText(szGuideText)
        end
    else
        if szGuideIcon ~= nil and szGuideIcon ~= "" then
            pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.ovlTipContent:SetVisibility(ESlateVisibility.Collapsed)
            if szGuideText ~= nil and szGuideText ~= "" then
                pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
                pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
                pWidgetRef.txtIconContent:SetText(szGuideText)
                local pGuideIcon = szGuideIcon:load()
                UISetUtils.SetImageBrushRes(pWidgetRef.imgGuideIcon, pGuideIcon, false)
                self:PlayAnimation("animPageDown02", 0, 0, EUMGSequencePlayMode.Forward, 1)
            end
        else
            pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.ovlTipContent:SetVisibility(ESlateVisibility.Collapsed)
            if szGuideText ~= nil and szGuideText ~= "" then
                pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
                pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
                pWidgetRef.txtContent:SetText(szGuideText)
                self:PlayAnimation("animPageDown01", 0, 0, EUMGSequencePlayMode.Forward, 1)
            else
                pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
            end
        end
    end
    self.nGuideTextPos = nGuidePos
    --延迟计算显示位置
    if self.DelayTimerHandle ~= nil then
        DelayTimer:ClearTimer(self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
    self:DebugLog("Pos Type = " .. type(Pos) .. " Size Type = " .. type(Size) .. " bMultiple = " .. tostring(bMultiple))
    self.DelayTimerHandle = DelayTimer:DelayRun(function()
        if bMultiple then
            self:SetSelectMultipleDelay(Pos, Size, szSelectImgWidget, szGuideText, bModal, bClickAnywhere, nGuidePos, bRotation)
        else
            self:SetSelectDelay(Pos, Size, szSelectImgWidget, szGuideText, bModal, bClickAnywhere, nGuidePos, bRotation) 
        end
        self.DelayTimerHandle = nil
    end, 0.2)
    return true
end

function UIGuide:ClearDelayClickHandler()
    if self.pDelayClickHandler then
        self:DebugLog(" ClearDelayClickHandler")
        self.TimerHelper:ClearTimer(self.pDelayClickHandler)
        self.pDelayClickHandler = nil
    end
end

function UIGuide:ClearDelayResponseHandler()
    if self.pDelayResponseHandler then
        self:DebugLog(" ClearDelayResponseHandler")
        self.TimerHelper:ClearTimer(self.pDelayResponseHandler)
        self.pDelayResponseHandler = nil
    end
end

function UIGuide:DelayResponse(nDelayTime)
    self:DebugLog("DelayResponse nDelayTime = " .. nDelayTime)
    local pWidgetRef = self.pWidgetRef
    self:ClearDelayResponseHandler()
    pWidgetRef.btnModalScreen:SetVisibility(ESlateVisibility.Visible)
    nDelayResponseTickCount = 0
    self.pDelayResponseHandler = self.TimerHelper:NewTimerMethod(self, function() self:OnDelayResponseTimerFunc(nDelayTime) end, 1, true)
end

function UIGuide:OnDelayResponseTimerFunc(nDelayTime)
    self:DebugLog("OnDelayResponseTimerFunc")
    local pWidgetRef = self.pWidgetRef
    nDelayResponseTickCount = nDelayResponseTickCount + 1
    if nDelayResponseTickCount >= nDelayTime then
        self:ClearDelayResponseHandler()
        nDelayResponseTickCount = 0
        pWidgetRef.btnModalScreen:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UIGuide:DelayClickAnyWhere(nDelayTime)
    self:DebugLog("DelayClickAnyWhere nDelayTime = " .. nDelayTime)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtClickAnyWhere:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("GUIDE_DELAY_CLICK_COUNT_DOWN"), nDelayTime)) -- 渐变动画还需要1s中，所以填写delaytime时请多填1s
    self:ClearDelayClickHandler()
    nDelayClickTickCount = 0
    self.pDelayClickHandler = self.TimerHelper:NewTimerMethod(self, function() self:OnDelayClickTimerFunc(nDelayTime) end, 1, true)
end

function UIGuide:OnDelayClickTimerFunc(nDelayTime)
    self:DebugLog("OnDelayClickTimerFunc")
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtClickAnyWhere:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    nDelayClickTickCount = nDelayClickTickCount + 1
    if nDelayClickTickCount >= nDelayTime then
        self:ClearDelayClickHandler()
        nDelayClickTickCount = 0
        pWidgetRef.txtClickAnyWhere:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_GUIDE_CLICKAYWHERE"))
        pWidgetRef.bdrBlackScreen:SetBrushColor(TRANSPARENT_SCREEN)
        pWidgetRef.bdrBlackScreen:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.Collapsed)
        self.bClickAnywhere = true
    else
        pWidgetRef.txtClickAnyWhere:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("GUIDE_DELAY_CLICK_COUNT_DOWN"), (nDelayTime - nDelayClickTickCount)))
    end
end

--设置划动屏幕指引
function UIGuide:SetDragDelay(nDirection, nAngle, szGuideText, bIsModal, nGuidePos)
    self:DebugLog("SetDragDelay")
    local pWidgetRef = self.pWidgetRef
    if nDirection == DRAG_DIRECTION.LEFT then
        pWidgetRef.imgHeadLeft:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.imgHead:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation("animHeadLeft", 0, 0, EUMGSequencePlayMode.Forward, 1)
    elseif nDirection == DRAG_DIRECTION.RIGHT then
        pWidgetRef.imgHeadRight:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.imgHead:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation("animHeadRight", 0, 0, EUMGSequencePlayMode.Forward, 1)
    else
        pWidgetRef.imgHeadLeft:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.imgHeadRight:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.imgHead:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation("animHead", 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
    local pGeometry = pWidgetRef.cvsRoot:GetCachedGeometry()
    local pDragGeometry = pWidgetRef.bdrDrag:GetCachedGeometry()
    local Pos = SlateBlueprintLibrary.LocalToAbsolute(pDragGeometry, Vector2D{X = 0,Y = 0})
    local LocalPos = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, Pos)
    local Size = pWidgetRef.bdrDrag.Slot:GetSize()
    pWidgetRef.bdrTextBg.Slot:SetPosition(LocalPos)
    self:PlayAnimation("animText", 0, 1, EUMGSequencePlayMode.Forward, 1)
    local EffectPos = {X = LocalPos.X, Y = LocalPos.Y}
    local EffectSize = {X = Size.X, Y = Size.Y}
    SetModalState(self, bIsModal, EffectSize, EffectPos)
    CorrectTextPos(self, nGuidePos, EffectSize, EffectPos)
    self.DelayTimerHandle = nil
end

function UIGuide:SetDragDelayNew(nDirection, nAngle, szGuideText, bIsModal, nGuidePos)
    self:DebugLog("SetDragDelayNew")
    local pWidgetRef = self.pWidgetRef
    if nDirection == DRAG_DIRECTION.LEFT then
        pWidgetRef.imgHead:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation("animHeadLeft", 0, 0, EUMGSequencePlayMode.Forward, 1)
    elseif nDirection == DRAG_DIRECTION.RIGHT then
        pWidgetRef.imgHead:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation("animHeadRight", 0, 0, EUMGSequencePlayMode.Forward, 1)
    elseif nDirection == DRAG_DIRECTION.UP then
        pWidgetRef.imgHead:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation("animHandUP", 0, 0, EUMGSequencePlayMode.Forward, 1)
    elseif nDirection == DRAG_DIRECTION.RHORIZONTAL then
        pWidgetRef.imgHead:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation("animHandRHorizontal", 0, 0, EUMGSequencePlayMode.Forward, 1)
    elseif nDirection == DRAG_DIRECTION.DEFAULT then
        pWidgetRef.imgHead:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation("animHandRight", 0, 0, EUMGSequencePlayMode.Forward, 1)
    else
        pWidgetRef.imgHead:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self:PlayAnimation("animHead", 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
    local pGeometry = pWidgetRef.cvsRoot:GetCachedGeometry()
    local pDragGeometry = pWidgetRef.bdrDrag:GetCachedGeometry()
    local Pos = SlateBlueprintLibrary.LocalToAbsolute(pDragGeometry, Vector2D{X = 0,Y = 0})
    local LocalPos = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, Pos)
    local Size = pWidgetRef.bdrDrag.Slot:GetSize()
    pWidgetRef.bdrTextBg.Slot:SetPosition(LocalPos)
    self:PlayAnimation("animText", 0, 1, EUMGSequencePlayMode.Forward, 1)
    local EffectPos = {X = LocalPos.X, Y = LocalPos.Y}
    local EffectSize = {X = Size.X, Y = Size.Y}
    SetModalState(self, bIsModal, EffectSize, EffectPos)
    CorrectTextPos(self, nGuidePos, EffectSize, EffectPos)
    self.DelayTimerHandle = nil
end

function UIGuide:SetDragOnly(tbParams)
    self:DebugLog("SetDragOnly")
    local szGuideText, szGuideIcon, nGuidePos = tbParams.szGuideText, tbParams.szGuideIcon, tbParams.nGuidePos
    self.bModal = true
    local pWidgetRef = self.pWidgetRef
    self.bEffectAnima = false
    pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.Collapsed)
    if szGuideIcon ~= nil and szGuideIcon ~= "" then
        pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
        if szGuideText ~= nil and szGuideText ~= "" then
            pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtIconContent:SetText(szGuideText)
            local pGuideIcon = szGuideIcon:load()
            UISetUtils.SetImageBrushRes(pWidgetRef.imgGuideIcon, pGuideIcon, false)
        end
    else
        pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.Collapsed)
        if szGuideText ~= nil and szGuideText ~= "" then
            pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtContent:SetText(szGuideText)
        else
            pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
    
    self.nGuideTextPos = nGuidePos
    pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.pbMaskButton.btnFullScreen:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.cvsDrag:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if self.DragOnlyDelayTimerHandle ~= nil then
        DelayTimer:ClearTimer(self.DragOnlyDelayTimerHandle)
        self.DragOnlyDelayTimerHandle = nil
    end
    self.ragOnlyDelayTimerHandle = DelayTimer:RunNextTick(function()
        self:DragOnlyDealy()
        self.DragOnlyDelayTimerHandle = nil
    end)
end

function UIGuide:DragOnlyDealy()
    self:DebugLog("DragOnlyDealy")
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local pGeometry = pWidgetRef.cvsRoot:GetCachedGeometry()
    local pDragGeometry = pWidgetRef.bdrDrag:GetCachedGeometry()
    local Pos = SlateBlueprintLibrary.LocalToAbsolute(pDragGeometry, Vector2D{X = 0,Y = 0})
    local LocalPos = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, Pos)
    local Size = pWidgetRef.bdrDrag.Slot:GetSize()
    local EffectPos = {X = LocalPos.X, Y = LocalPos.Y}
    local EffectSize = {X = Size.X, Y = Size.Y}
    pWidgetRef.bdrTextBg.Slot:SetPosition(LocalPos)
    self:PlayAnimation("animText", 0, 1, EUMGSequencePlayMode.Forward, 1)
    SetModalState(self, true, EffectSize, EffectPos)
    CorrectTextPos(self, self.nGuideTextPos, EffectSize, EffectPos)
end

function UIGuide:SetDragInfo(tbParams)
    self:DebugLog("SetDragInfo")
    local nDirection, nAngle, szGuideText, szGuideIcon, bIsModal, nGuidePos, GuideActionRef = tbParams.nDirection, tbParams.nAngle, tbParams.szGuideText, tbParams.szGuideIcon, tbParams.bIsModal, tbParams.nGuidePos, tbParams.GuideActionRef
    self.bDown = false
    self.bModal = true
    self.GuideActionRef = GuideActionRef
    local pWidgetRef = self.pWidgetRef
    self.bEffectAnima = false
    --指引半身像和文字
    self:DebugLog("szGuideIcon="..tostring(szGuideIcon).." szGuideText="..tostring(szGuideText).." nDirection="..tostring(nDirection))
    pWidgetRef.ovlTipContent:SetVisibility(ESlateVisibility.Collapsed)
    if szGuideIcon ~= nil and szGuideIcon ~= "" then
        pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
        if szGuideText ~= nil and szGuideText ~= "" then
            pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtIconContent:SetText(szGuideText)
            local pGuideIcon = szGuideIcon:load()
            UISetUtils.SetImageBrushRes(pWidgetRef.imgGuideIcon, pGuideIcon, false)
        end
    else
        pWidgetRef.ovlIconContent:SetVisibility(ESlateVisibility.Collapsed)
        if szGuideText ~= nil and szGuideText ~= "" then
            pWidgetRef.bdrTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtContent:SetText(szGuideText)
        else
            pWidgetRef.ovlContent:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
    
    self.nGuideTextPos = nGuidePos
    pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.cvsDrag:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if self.DelayTimerHandle ~= nil then
        DelayTimer:ClearTimer(self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
    self.DelayTimerHandle = DelayTimer:RunNextTick(function()
        self:SetDragDelayNew(nDirection, nAngle, szGuideText, bIsModal, nGuidePos) 
    end)
end

--显示黑屏
function UIGuide:ShowBlackScreen(bShow)
    self:DebugLog("ShowBlackScreen bShow = " .. tostring(bShow))
    self.bClickAnywhere = false
    local bdrBlackScreen = self.pWidgetRef.bdrBlackScreen
    if bShow then 
        bdrBlackScreen:SetVisibility(ESlateVisibility.Visible)
        bdrBlackScreen:SetBrushColor(BLACK_SCREEN)
    else
        bdrBlackScreen:SetVisibility(ESlateVisibility.Collapsed)
    end
end

--显示两步指引之间的间隙遮挡
function UIGuide:ShowSpaceScreen(bShow)
    self:DebugLog("ShowSpaceScreen bShow = " .. tostring(bShow))
    self.bClickAnywhere = false
    local bdrBlackScreen = self.pWidgetRef.bdrBlackScreen
    if bShow then 
        bdrBlackScreen:SetVisibility(ESlateVisibility.Visible)
        bdrBlackScreen:SetBrushColor(TRANSPARENT_SCREEN)
    else
        bdrBlackScreen:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UIGuide:ShowShipWeaponVideoText(tbParams)
    self:DebugLog("ShowShipWeaponVideoText")
    self.pWidgetRef.ovlShipWeaponText:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

function UIGuide:SetDelayClickAnyWhere()
    self:DebugLog("SetDelayClickAnyWhere")
    self.bClickAnywhere = false
    if self.DelayTimerHandle ~= nil then
        DelayTimer:ClearTimer(self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
    self.DelayTimerHandle = DelayTimer:DelayRun(function() DelayPictureGuide(self) end, PIC_GUIDE_DELAY)
end

--隱藏划动屏幕的指引
function UIGuide:HideDrag()
    self:DebugLog("HideDrag")
    self.pWidgetRef.cvsDrag:SetVisibility(ESlateVisibility.Collapsed)
end

--设置图片说明指引
function UIGuide:SetPicGuide(tbParams)
    self:DebugLog("SetPicGuide")
    local szPicPath, szGuideText, bClickAnywhere = tbParams.szPicPath, tbParams.szGuideText, tbParams.bClickAnywhere
    self.bDown = false
    self.bModal = false
    if bClickAnywhere then
        self:SetDelayClickAnyWhere()
    end
    local PicRes = szPicPath:load()
    local pWidgetRef = self.pWidgetRef
    if PicRes ~= nil then
        pWidgetRef.imgShipHelp:SetBrushFromTexture(PicRes)
    end
    local bdrBlackScreen = pWidgetRef.bdrBlackScreen
    bdrBlackScreen:SetVisibility(ESlateVisibility.Visible)
    self:DebugLog("UIGuide:SetPicGuide Show (bdrBlackScreen)")
    bdrBlackScreen:SetBrushColor(TRANSPARENT_SCREEN)
    pWidgetRef.txtClickAnyWhere:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.imgShipHelp:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtCentralGuide:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtCentralGuide:SetText(szGuideText)
    pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.imgMediaBG:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

--设置图片说明指引
function UIGuide:ShowMediaPlayer(tbParams)
    self:DebugLog("ShowMediaPlayer")
    local szGuideText, bClickAnywhere = tbParams.szGuideText, tbParams.bClickAnywhere
    self.bDown = false
    self.bModal = false
    if bClickAnywhere then
        self:SetDelayClickAnyWhere()
    end
    local pWidgetRef = self.pWidgetRef
    local bdrBlackScreen = pWidgetRef.bdrBlackScreen
    bdrBlackScreen:SetVisibility(ESlateVisibility.Visible)
    bdrBlackScreen:SetBrushColor(TRANSPARENT_SCREEN)
    pWidgetRef.txtClickAnyWhere:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtCentralGuide:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtCentralGuide:SetText(szGuideText)
    pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.sbMediaPlayer:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.imgMediaBG:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
end

--设置黑幕居中文字指引
function UIGuide:SetCentralGuide(tbParams)
    local szGuideText, bIsModal, bClickAnywhere, GuideActionRef = tbParams.szGuideText, tbParams.bIsModal, tbParams.bClickAnywhere, tbParams.GuideActionRef
    self:DebugLog("SetCentralGuide")
    self.bDown = false
    self.bModal = bIsModal
    self:DebugLog("bClickAnywhere = "..tostring(bClickAnywhere))
    self.bClickAnywhere = bClickAnywhere
    self.GuideActionRef = GuideActionRef
    local pWidgetRef = self.pWidgetRef
    local bdrBlackScreen = pWidgetRef.bdrBlackScreen
    bdrBlackScreen:SetVisibility(ESlateVisibility.Visible)
    bdrBlackScreen:SetBrushColor(TRANSPARENT_SCREEN)
    if bClickAnywhere then
        pWidgetRef.txtClickAnyWhere:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
    pWidgetRef.vboxCentralGuide:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtCentralGuide:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtCentralGuide:SetText(szGuideText)
end

--
function UIGuide:OnBlackButtonDown(pGeometry, pMouseEvent)
    self:DebugLog("OnBlackButtonDown")
    self.bDown = true
    return WidgetBlueprintLibrary.Handled()
end

function UIGuide:OnBlackButtonUp(pGeometry, pMouseEvent)
    self:DebugLog("OnBlackButtonUp bDown = " .. tostring(self.bDown))
    if not self.bDown then
        return WidgetBlueprintLibrary.Handled()
    end  
    local bDefensive = self.GuideActionRef ~= nil and self.GuideActionRef.tbGuideTemplate.bDefensive
    if self.bClickAnywhere then
        self:DebugLog("OnBlackButtonUp bClickAnywhere")
        HideAll(self)
        self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_CLICK_ANYWHERE)
    elseif bDefensive and self.nClickCount >= MODAL_CLICK_UNLOCK then
        self:DebugLog("OnBlackButtonUp bDefensive")
        HideAll(self)
        if self.GuideActionRef ~= nil then
            self.GuideActionRef.bIsModal = false
        end
    else
        self:DebugLog("OnBlackButtonUp else")
        self.nClickCount = self.nClickCount + 1
    end
    return WidgetBlueprintLibrary.Handled()
end

function UIGuide:OnClickBg()    
    self:DebugLog("OnClickBg ClickAnywhere = " .. tostring(self.bClickAnywhere) .. " modal = " .. tostring(self.bModal))
    local pWidgetRef = self.pWidgetRef
    if self.bClickAnywhere then
        self:ClearDelayClickHandler()
        nDelayClickTickCount = 0
        HideAll(self)
        self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_CLICK_ANYWHERE)
    elseif self.bModal then
        self.nClickCount = self.nClickCount + 1
        local bDefensive = self.GuideActionRef ~= nil and self.GuideActionRef.tbGuideTemplate.bDefensive
        self:DebugLog("OnClickBg bDefensive = " .. tostring(bDefensive))
        if(bDefensive and self.nClickCount >= MODAL_CLICK_UNLOCK)then
            pWidgetRef.pbMaskButton:SetVisibility(ESlateVisibility.Collapsed)
            if self.GuideActionRef ~= nil then
                self.GuideActionRef.bIsModal = false
            end
        elseif not pWidgetRef:IsAnimationPlaying(pWidgetRef.animEffect) and self.bEffectAnima then
            self:DebugLog("OnClickBg play animEffect")
            pWidgetRef.imgEffect:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            self:PlayAnimation("animEffect", 0, 1, EUMGSequencePlayMode.Forward, 1)
            self:ClearBlackTimerHandler()
            self.BlackTimer = self.TimerHelper:NewTimerMethod(self, self.OnBlackTimerFunc, 3, false)
        end
    end
end

function UIGuide:OnBlackTimerFunc()
    self:DebugLog("OnBlackTimerFunc")
    self.pWidgetRef.imgEffect:SetVisibility(ESlateVisibility.Collapsed)
    self:ClearBlackTimerHandler()
end

function UIGuide:ClearBlackTimerHandler()
    self:DebugLog("ClearBlackTimerHandler")
    if self.BlackTimer then 
        self.TimerHelper:ClearTimer(self.BlackTimer)
        self.BlackTimer = nil
    end
end

function UIGuide:OnAnimFinished()
    self:DebugLog("OnAnimFinished")
end

function UIGuide:ClearGuideSelfTimer()
    self:DebugLog("ClearGuideSelfTimer")
    self.TimerHelper:ClearAllTimer()
end

--override 
function UIGuide:OnLoad()
    self:DebugLog("OnLoad")
    local pWidgetRef = self.pWidgetRef
    self.pbMaskButton = self.PrefabHelper:BindPrefab(pWidgetRef.pbMaskButton)
    local DynMaterial = pWidgetRef.Click:GetDynamicMaterial()
    DynMaterial:SetVectorParameterValue("Color", WHITE_COLOR)
    self.tbClickEffects = {}
    self.tbCircleClick = {}
    self.tbTips = {}
end

function UIGuide:OnEnter()
    self:DebugLog("OnEnter")
    self.nZOrder = self.tbOpenArgs.nZOrder
end

function UIGuide:OnShow()
    self:DebugLog("OnShow")
    self.bActivate = true
    HideAll(self)
end

function UIGuide:OnUIActivate(bActivate)
    self:DebugLog("OnUIActivate")
    if bActivate then
        if not self.bActivate then
            self:Activate()
        end
    else
        self:Deactivate()
    end
end

function UIGuide:OnUIShow(bShow)
    self:DebugLog("OnUIShow")
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        return
    end
    if bShow then
        pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UIGuide:Activate()
    self:DebugLog("Activate")
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        return
    end
    pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.bActivate = true
    HideAll(self)
    EventManager:OnFireEvent(ClientEventDef.EV_UI_GUIDE_ACTIVATE, true)
end

function UIGuide:Deactivate()
    self:DebugLog("Deactivate")
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        return
    end
    pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    self.bActivate = false
    EventManager:OnFireEvent(ClientEventDef.EV_UI_GUIDE_ACTIVATE, false)
end

function UIGuide:OnDestroy()
    self:DebugLog("OnDestroy")
    if self.DelayTimerHandle then
        DelayTimer:ClearTimer(self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
end

function UIGuide:OnHide()
    self:DebugLog("OnHide")
    self.bActivate = false
    if self.tbTaskItem ~= nil then
        local pWidgetRef = self.pWidgetRef
        for k,v in pairs(self.tbTaskItem) do
            local nChildIndex = pWidgetRef.cvsTask:GetChildIndex(v)
            pWidgetRef.cvsTask:RemoveChildAt(nChildIndex)
            self.WidgetHelper:DestroyWidget(v)
        end
        self.tbTaskItem = {}
    end
    if self.DelayTimerHandle ~= nil then
        DelayTimer:ClearTimer(self.DelayTimerHandle)
        self.DelayTimerHandle = nil
    end
    self.TimerHelper:ClearAllTimer()
end

function UIGuide:CallFunc(szFuncName, tbParams)
    local tbFunc = self[szFuncName]
    if not tbFunc then
        return
    end
    tbFunc(self, tbParams)
end

function UIGuide:OnBindEvent(Helper)
    self:DebugLog("OnBindEvent")
    local pWidgetRef = self.pWidgetRef
    Helper:RegisterEvent(ClientEventDef.EV_GUIDE_SHOW_SPACE_SCREEN, self, self.ShowSpaceScreen)
    Helper:RegisterEvent(ClientEventDef.EV_GUIDE_CALL_FUNC, self, self.CallFunc)
    Helper:RegisterEvent(ClientEventDef.EV_GUIDE_UI_ACTIVATE, self, self.OnUIActivate)
    Helper:RegisterEvent(ClientEventDef.EV_GUIDE_UI_SHOW, self, self.OnUIShow)
    Helper:RegisterEvent(ClientEventDef.EV_GUIDE_DELAY_RESPONSE, self, self.DelayResponse)

    Helper:RegisterLuaDelegate(self.pbMaskButton.OnClicked, self.OnClickBg, self)
    Helper:RegisterCppDelegate(pWidgetRef.bdrBlackScreen.OnMouseButtonDownEvent,self,self.OnBlackButtonDown)
    Helper:RegisterCppDelegate(pWidgetRef.bdrBlackScreen.OnMouseButtonUpEvent,self,self.OnBlackButtonUp)
    Helper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(pWidgetRef, pWidgetRef.animText, self.OnAnimFinished, self))
    Helper:RegisterCppDelegate(pWidgetRef.OnTouchEndedEvent, self, OnUserWidgetTouchEnded)
end

function UIGuide:DebugLog(szMsg)
    szMsg = "[UIGuide] " .. szMsg
    GuideDebug:DebugLog(szMsg)
end

return UIGuide