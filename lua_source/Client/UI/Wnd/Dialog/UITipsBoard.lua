-----------------------------------------------------
--File Name    : UITipsBoard.lua
--Author       : Song Fuhao
--Create Time  : 2019-02-27
--Description  : 简单的文字提示Dialog
-----------------------------------------------------

local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UITipsBoard = luaclass("UITipsBoard", WndBase)

local VECTOR2D_ZERO = KismetMathLibrary.MakeVector2D(0, 0)

local function OnClickedBtnClose(self)
    self:CloseSelf()
end

function UITipsBoard:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, OnClickedBtnClose)
end

local function GetRootPosition(pRootWidgetRef, pContentWidgetRef)
    local pScreenPosition = SlateBlueprintLibrary.LocalToAbsolute(pRootWidgetRef:GetCachedGeometry(), VECTOR2D_ZERO)
    local _, pViewportPosition  = SlateBlueprintLibrary.AbsoluteToViewport(GWorld, pScreenPosition)
    local pViewPortSizeWithScale = ExtendBlueprintFunctions.GetViewportSizeWithScale(GWorld)
    local pRootSize = pRootWidgetRef:GetDesiredSize()
    local pContentSize = pContentWidgetRef:GetDesiredSize()
    if pViewportPosition.X + pContentSize.X > pViewPortSizeWithScale.X then
        pViewportPosition.X = pViewportPosition.X + pRootSize.X - pContentSize.X
    end
    if pViewportPosition.Y + pRootSize.Y + pContentSize.Y > pViewPortSizeWithScale.Y then
        pViewportPosition.Y = pViewportPosition.Y - pContentSize.Y
    else
        pViewportPosition.Y = pViewportPosition.Y + pRootSize.Y
    end
    return pViewportPosition
end

function UITipsBoard:CreateTips(szPrefabName, pRootWidgetRef)
    local pbContent = self.PrefabHelper:CreatePrefab(szPrefabName)
    local pSlot = self.pWidgetRef.cvsContent:AddChild(pbContent.pWidgetRef)
    pSlot:SetAutoSize(true)
    pbContent.pWidgetRef:SetRenderOpacity(0)
    self.TimerHelper:RunNextTick(function()
        pSlot:SetPosition(GetRootPosition(pRootWidgetRef, pbContent.pWidgetRef))
        pbContent.pWidgetRef:SetRenderOpacity(1)
    end)
    return pbContent
end

return UITipsBoard
