-----------------------------------------------------
--File Name    : UPFloatNum.lua
--Author       : lzheng
--Create Time  : 2019-09-25
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPFFABase = require("UPFFABase")
local UPFloatNum = luaclass("UPFloatNum", UPFFABase)
local UISetUtils = require("UISetUtils")
local WidgetAnimationHandle = require("WidgetAnimationHandle")

local function OnAnimationFinished( self )
    self.Owner:OnFloatAnimationFinished(self)
end

function UPFloatNum:OnCreate()
end

function UPFloatNum:OnDestroy()
end

function UPFloatNum:OnLoad()
end

function UPFloatNum:SetFloatNumAndStartLoc( nNum, location )
    nNum = math.ceil(nNum)
    self.pWidgetRef:SetFloatNumAndStartLoc(string.format("%d", nNum), location)
end

function UPFloatNum:SetFloatNumColor(szColor)
    local pColor = KMUMGLibrary.GetSlateColorFromHex(szColor)
    self.pWidgetRef.txtNumber:SetColorAndOpacity(pColor)
end

function UPFloatNum:SetFontSize(nSize)
    UISetUtils.SetTextblockFontSize(self.pWidgetRef.txtNumber, nSize)
end

function UPFloatNum:OnBindEvent( EventHelper )
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animFade, OnAnimationFinished, self))
end

return UPFloatNum
