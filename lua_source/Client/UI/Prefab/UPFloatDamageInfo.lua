-----------------------------------------------------
--File Name    : UPFloatDamageInfo.lua
--Author       : lzheng
--Create Time  : 2020-08-19
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPFFABase = require("UPFFABase")
local UPFloatDamageInfo = luaclass("UPFloatDamageInfo", UPFFABase)
local UISetUtils = require("UISetUtils")
local WidgetAnimationHandle = require("WidgetAnimationHandle")
local DamageHurtDef = require("DamageHurtDef")

local function OnAnimationFinished( self )
    self.Owner:OnFloatAnimationFinished(self)
end

function UPFloatDamageInfo:OnCreate()
end

function UPFloatDamageInfo:OnDestroy()
end

function UPFloatDamageInfo:OnLoad()
end

function UPFloatDamageInfo:SetFloatNumAndStartLoc( nNum, location )
    nNum = math.ceil(nNum)
    self.pWidgetRef:SetFloatNumAndStartLoc(string.format("%d", nNum), location)
end

function UPFloatDamageInfo:SetFloatNumColor(szColor)
    local pColor = KMUMGLibrary.GetSlateColorFromHex(szColor)
    self.pWidgetRef.txtNumber:SetColorAndOpacity(pColor)
end

function UPFloatDamageInfo:SetFontSize(nSize)
    UISetUtils.SetTextblockFontSize(self.pWidgetRef.txtNumber, nSize)
end

function UPFloatDamageInfo:SetDamageTagIconVisible(nTag)
    local bHitCore, bLeak, bOnFire = DamageHurtDef.GetHurtFlagResult(nTag)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.ImgCore:SetVisibility(bHitCore and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    pWidgetRef.ImgLeak:SetVisibility(bLeak and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
    pWidgetRef.ImgFire:SetVisibility(bOnFire and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Collapsed)
end

function UPFloatDamageInfo:OnBindEvent( EventHelper )
    EventHelper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animFade, OnAnimationFinished, self))
end

return UPFloatDamageInfo
