-----------------------------------------------------
--File Name    : UPGuideEffect.lua
--Author       : Edward J
--Create Time  : 2019-09-27
--Description  : UPGuideEffect
-----------------------------------------------------

local luaclass      = require("luaclass")
local PrefabBase    = require("PrefabBase")
local UPGuideEffect = luaclass("UPGuideEffect", PrefabBase)

local function GetWidget(self, szEffectType)
    local pImgWidget = nil
    if szEffectType == "circleClick" then
        pImgWidget = self.pWidgetRef.imgCycleGlow
    elseif szEffectType == "squareClick" then
        pImgWidget = self.pWidgetRef.imgFxRadarMapGlow
    elseif szEffectType == "radarMapClick" then
        pImgWidget = self.pWidgetRef.imgFxRadarMapGlow
    elseif szEffectType == "shipTurnEffect" then
        pImgWidget = self.pWidgetRef.imgRight01
    end
    return pImgWidget
end

function UPGuideEffect:SetVisble(szEffectType, bEnable)
    local eVisble = bEnable and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed
    local pImgWidget = GetWidget(self, szEffectType)
    pImgWidget:SetVisibility(eVisble)
end

function UPGuideEffect:SetSize(szEffectType, tbSize)
    local pImgWidget = GetWidget(self, szEffectType)
    pImgWidget.Slot:SetSize(tbSize)
end

function UPGuideEffect:SetPosition(szEffectType, tbPos)
    local pImgWidget = GetWidget(self, szEffectType)
    pImgWidget.Slot:SetPosition(tbPos)
end

return UPGuideEffect
