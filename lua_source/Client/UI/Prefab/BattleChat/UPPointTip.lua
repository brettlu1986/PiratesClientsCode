-----------------------------------------------------
--File Name    : UPPointTip.lua
--Author       : Edward J
--Create Time  : 2020-06-28
--Description  : UPPointTip
-----------------------------------------------------
local luaclass          = require("luaclass")
local UPFFABase         = require("UPFFABase")
local UPPointTip        = luaclass("UPPointTip", UPFFABase)

local UISetUtils            = require("UISetUtils")
local UIResourceDef         = require("UIResourceDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local PointTipsHelper       = require("PointTipsHelper")
-----------------------------------------------------
local Collapsed             = ESlateVisibility.Collapsed
local SelfHitTestInvisible  = ESlateVisibility.SelfHitTestInvisible
local HIGHT_OFFSET          = 80
local WIGTH_OFFSET          = 25
local AdaptivePosition      = Vector2D()

UPPointTip.pWroldPos        = nil
UPPointTip.pParentRef       = nil
UPPointTip.tbPlayerSelf     = nil
UPPointTip.pUEController    = nil
UPPointTip.nOldDistance     = nil
-----------------------------------------------------

function UPPointTip:Activate(tbParam)
    self.pWidgetRef:SetVisibility(SelfHitTestInvisible)
end

function UPPointTip:Deactivate()
    self.pWidgetRef:SetVisibility(Collapsed)
end

function UPPointTip:OnLoad()
    self.super.OnLoad(self)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    self.tbPlayerSelf = tbPlayerSelf
    self.pUEController = tbPlayerSelf.pUEController
    self.pParentRef = self.Owner.pWidgetRef
    self.nOldDistance = 0
end

function UPPointTip:OnUnload()
    self.super.OnUnload()
end

function UPPointTip:OnBindEvent(EventHelper)
    
end

function UPPointTip:SetTipIcon(nIconType)
    local szTip = UIResourceDef.PointTip[nIconType]
    if not szTip then
        return
    end
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgGender, szTip:load(), true)
end

function UPPointTip:SetText(szText)
    self.pWidgetRef.txtInfo:SetText(szText .. "m")
end

function UPPointTip:SetWorldPosition(pPos)
    if not Vector then
        return
    end
    self.pWroldPos = pPos
end

function UPPointTip:RefreshScreenPos()
    local pWroldPos = self.pWroldPos
    if not pWroldPos then
        return nil
    end
    local pSelfLocation = self.tbPlayerSelf:GetLocation()
    local _, pScreenPosition = GameplayStatics.ProjectWorldToScreen(self.pUEController, pWroldPos, false)
    local pGeometry = self.pParentRef:GetCachedGeometry()
    local LocalPos = SlateBlueprintLibrary.ScreenToWidgetLocal(GWorld, pGeometry, pScreenPosition)
    local layoutSizeVector = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local nLX, nLY = LocalPos.X, LocalPos.Y
    nLX = math.min(nLX, layoutSizeVector.X - WIGTH_OFFSET)
    nLX = math.max(nLX, WIGTH_OFFSET)
    nLY = math.min(nLY, layoutSizeVector.Y)
    nLY = math.max(nLY, HIGHT_OFFSET)
    AdaptivePosition.X = nLX
    AdaptivePosition.Y = nLY Vector2D{X = nLX, Y = nLY}
    self.pWidgetRef.Slot:SetPosition(AdaptivePosition)
    local nDistance = PointTipsHelper.GetDistance(pSelfLocation, pWroldPos)
    if self.nOldDistance ~= nDistance then
        self:SetText(math.ceil(nDistance/100))
    end
end

return UPPointTip