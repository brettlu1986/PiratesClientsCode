-----------------------------------------------------
--File Name    : ULMapPointSymbol.lua
--Description  : 地图上点的图例说明
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULMapPointSymbol = luaclass("ULMapPointSymbol", UILogicBase)


local FFAMapPointCategoryDataTable = require("FFAMapPointCategoryDataTable")
local MiniMapSystem = require("MiniMapSystem")

local DirImageScale = Vector2D{X = 1, Y = 1}

ULMapPointSymbol.bSymbolOpen = nil


local function RefreshSymbolVisible(self)
    local pWidgetRef = self.pWidgetRef
    local tbAllCategory = FFAMapPointCategoryDataTable:GetAllCategory()
    local bAllShow = true
    local bShow = true
    local pCheckState = ECheckBoxState.Checked
    for k, v in ipairs(tbAllCategory) do
        pWidgetRef["txtSymbol0"..k]:SetText(v.l10nDisplayName)
        bShow = MiniMapSystem:GetMapSymbolVisible(v.nId)
        bAllShow = bAllShow and bShow
        pCheckState = bShow and ECheckBoxState.Checked or ECheckBoxState.Unchecked 
        pWidgetRef["chk0"..k]:SetCheckedState(pCheckState)
    end
    pCheckState = bAllShow and ECheckBoxState.Checked or ECheckBoxState.Unchecked
    pWidgetRef.chkAll:SetCheckedState(pCheckState)
end

local function OnShowSymbolChanged(self, nCategory, bCheck)
    if nCategory then
        MiniMapSystem:SetMapSymbolVisible(nCategory, bCheck)
    else
        local tbAllCategory = FFAMapPointCategoryDataTable:GetAllCategory()
        for k, v in ipairs(tbAllCategory) do
            MiniMapSystem:SetMapSymbolVisible(v.nId, bCheck)
        end
    end
    RefreshSymbolVisible(self)
end

local function OnSymbolClick(self)
    local SequenceMode = self.bSymbolOpen and EUMGSequencePlayMode.Reverse or EUMGSequencePlayMode.Forward
    self.pWidgetRef.bdrSymbol:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    self.Owner:PlayAnimation("animPa", 0, 1, SequenceMode, 1)
    self.bSymbolOpen = not self.bSymbolOpen
    --self.pWidgetRef.imgSymbolDir:SetRenderTransformAngle(nAngle)
end

function ULMapPointSymbol:OnShow()
    self.pWidgetRef.bdrSymbol:SetVisibility(ESlateVisibility_Collapsed)
    --self.pWidgetRef.imgSymbolDir:SetRenderTransformAngle(180)
    self.pWidgetRef.imgSymbolDir:SetRenderScale(DirImageScale)
    self.bSymbolOpen = false
    RefreshSymbolVisible(self)
end

function ULMapPointSymbol:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    local tbAllCategory = FFAMapPointCategoryDataTable:GetAllCategory()
    for k, v in ipairs(tbAllCategory) do
        EventHelper:RegisterCppDelegateFunc(pWidgetRef["chk0"..k].OnCheckStateChanged, function(bCheck) OnShowSymbolChanged(self, v.nId, bCheck) end)
    end
    EventHelper:RegisterCppDelegateFunc(pWidgetRef.chkAll.OnCheckStateChanged, function(bCheck) OnShowSymbolChanged(self, nil, bCheck) end)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSymbol.OnClicked, self, OnSymbolClick)
end


return ULMapPointSymbol