-----------------------------------------------------
--File Name    : UPMaskButton.lua
--Author       : Song Fuhao
--Create Time  : 2017-06-29
--Description  : MaskButton
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPMaskButton = luaclass("UPMaskButton", PrefabBase)

local LuaDelegateClass = require("LuaDelegate")

UPMaskButton.OnClicked = nil

local function OnClickedButton( self )
    self.OnClicked:Fire()
end

function UPMaskButton:OnLoad()
    self.OnClicked = LuaDelegateClass()
end

function UPMaskButton:OnBindEvent( EventHelper )
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnLeft.OnClicked   , self, OnClickedButton)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnRight.OnClicked  , self, OnClickedButton)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnTop.OnClicked    , self, OnClickedButton)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnBottom.OnClicked , self, OnClickedButton)
end

function UPMaskButton:SetMaskInfo( pPosition, pSize )
    local pLocalSize = SlateBlueprintLibrary.GetLocalSize(self.pWidgetRef:GetCachedGeometry())
    local nLeftSize = pPosition.X
    local nRightSize = pLocalSize.X - pSize.X - nLeftSize
    local nTopSize = pPosition.Y
    local nBottomSize = pLocalSize.Y - pSize.Y - nTopSize
    self.pWidgetRef.btnLeft.Slot:SetSize(KismetMathLibrary.MakeVector2D(nLeftSize, 0))
    self.pWidgetRef.btnRight.Slot:SetSize(KismetMathLibrary.MakeVector2D(nRightSize, 0))
    self.pWidgetRef.btnTop.Slot:SetSize(KismetMathLibrary.MakeVector2D(0, nTopSize))
    self.pWidgetRef.btnBottom.Slot:SetSize(KismetMathLibrary.MakeVector2D(0, nBottomSize))
    self.pWidgetRef.btnFullScreen:SetVisibility(ESlateVisibility.Collapsed)
end

return UPMaskButton
