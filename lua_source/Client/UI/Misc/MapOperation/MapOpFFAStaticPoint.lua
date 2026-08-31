-----------------------------------------------------
--File Name    : MapOpFFAStaticPoint.lua
--Author       : Ran Jie
--Description  : ffa岛等静态点在地图上的显示
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpStaticPoint = require("MapOpStaticPoint")
local MapOpFFAStaticPoint = luaclass("MapOpFFAStaticPoint",MapOpStaticPoint)


--local DungeonDataTable = require("DungeonDataTable")
local FFAMapPointDataTable = require("FFAMapPointDataTable")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local L10N = require("L10N")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local FFAMapPointJsonTable = require("FFAMapPointJsonTable")


local function OnSymbolVisibleChanged(self, nCategory, bVisible)
    for k, v in pairs(self.tbStaticObj) do
        if v.tbData.nCategory == nCategory or nCategory == nil then
            v:ShowSmallIcon(bVisible)
        end
    end
end

function MapOpFFAStaticPoint:Init(Parent)
    MapOpFFAStaticPoint.super.Init(self, Parent)
    --self:ReLoadStaticObj()
end


function MapOpFFAStaticPoint:Open()
    MapOpFFAStaticPoint.super.Open(self)
    self:ReLoadStaticObj()
end

function MapOpFFAStaticPoint:MakeAllPointData()
    local tbAllPointData = {}
    local nDungeonId = BattleGameModeSystem.nDungeonId
    local tbAllPoint = FFAMapPointDataTable:GetDungeonAllPoint(nDungeonId)
    --local tbDungeonDescriptor = DungeonDataTable:GetDescriptor(nDungeonId)
    local tbPointPos = FFAMapPointJsonTable[nDungeonId]
    if not tbAllPoint or not tbPointPos then
        return tbAllPointData
    end
    for k, v in pairs(tbAllPoint) do
        --logdebug("ReLoadStaticObj", k)
        if not v.bHide then
            local tbPosData = tbPointPos[v.szPointKey]
            if tbPosData then
                local tbData = {}
                tbData.szName               = L10N:ToString(v.l10nDisplayName)
                tbData.nCategory            = v.nCategoryId
                tbData.szIcon               = v.szIconResPath
                tbData.tbWorldPos           = tbPosData
                tbData.nDefaultFontSize     = v.nFontSize
                tbData.nFontSize            = v.nFontSize
                tbData.szPointKey           = v.szPointKey
                local UIPosX, UIPosY        = self:CalculateUIMapLocation(tbPosData)
                tbData.UILocation           = {X = UIPosX, Y = UIPosY}
                tbData.UISize = {X = v.nIconSizeX, Y = v.nIconSizeY}
                tbData.SlateColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
                table.insert(tbAllPointData, tbData)
                --logdebug("ReLoadStaticObj,self.bMMap,tbData.nFontSize=",self.bMMap,tbData.nFontSize)
            end
        end
    end
    return tbAllPointData
end

function MapOpFFAStaticPoint:BindEvent()
    MapOpFFAStaticPoint.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_MAP_SYMBOL_VISIBLE_CHANGED, self, OnSymbolVisibleChanged)
end

return MapOpFFAStaticPoint