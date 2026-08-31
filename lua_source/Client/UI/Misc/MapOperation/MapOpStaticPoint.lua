-----------------------------------------------------
--File Name    : MapOpStaticPoint.lua
--Author       : Ran Jie
--Description  : 静态点在地图上的显示
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpStaticPoint = luaclass("MapOpStaticPoint",MapOpBase)

local L10N = require("L10N")
local MapObjType = require("MapObjType")
local GameWorldSystem = require("GameWorldSystem")
local SceneMapPointDataTable = require("SceneMapPointDataTable")
local SceneDataTable = require("SceneDataTable")
local UIResourceDef = require("UIResourceDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local FFAMapPointDataTable = require("FFAMapPointDataTable")
local DungeonDataTable = require("DungeonDataTable")

local FONT_FACTOR_1 = 2
local FONT_FACTOR_2 = 0.5

MapOpStaticPoint.tbStaticObj = {}
MapOpStaticPoint.tbStaticData = nil

local function ClearObj(self)
    if not self.MapOpObj then
        return
    end
    for k, v in pairs(self.tbStaticObj) do
        self.MapOpObj:RemoveContentPoint(k)
        v:HideContent()
    end
    self.tbStaticObj = {}
    --self:ResetObjPool(MapObjType.STATIC)
end

function MapOpStaticPoint:Init(Parent)
    MapOpStaticPoint.super.Init(self, Parent)
    local MapOpObj = self:GetOpObj(UIMapOpPoint)
    local UIOriginSizeX = Parent.tbMapResData.nUIMapSizeX - Parent.tbMapResData.nUIMapOffsetX * 2
    MapOpObj:InitParam(self.pWidgetRef, FONT_FACTOR_1, FONT_FACTOR_2, UIOriginSizeX)
    MapOpObj:SetEnable(false)
    self.pWidgetRef:RegisterOperation(MapOpObj)
    self:ReLoadStaticObj()
end


function MapOpStaticPoint:Uninit()
    for k, v in pairs(self.tbStaticObj) do
        self.MapOpObj:RemoveContentPoint(k)
    end
    MapOpStaticPoint.super.Uninit(self)
end

function MapOpStaticPoint:ReLoadStaticObj()
    ClearObj(self)
    if not self.tbStaticData then
        self.tbStaticData = self:MakeAllPointData()
    end
    for k, v in ipairs(self.tbStaticData) do
        local Obj = self:GetOneObj(MapObjType.STATIC)
        Obj:ShowContent(v)
        local pObjWidgetRef = Obj.pWidgetRef
        local nIconSizeX = v.UISize.X
        local nIconSizeY = v.UISize.Y
        local pIconWidget = pObjWidgetRef.imgSmallIcon
        local nPointId = self.MapOpObj:AddContentPointWithSize(pObjWidgetRef, Vector{X = v.tbWorldPos.X, Y = v.tbWorldPos.Y, Z = 0}, 
        pObjWidgetRef.txtObjName, v.nFontSize, pIconWidget, Vector2D{X = nIconSizeX, Y = nIconSizeY})
        --table.insert(self.tbStaticObj, Obj)
        self.tbStaticObj[nPointId] = Obj
    end
end

function MapOpStaticPoint:SetPointData(tbAllPointData)
    self.tbStaticData = tbAllPointData
end

function MapOpStaticPoint:GetAllPointObjs()
    return self.tbStaticObj
end

function MapOpStaticPoint:MakeAllPointData()
    local tbAllPointData = {}
    local tbPointPos = nil
    local tbAllPoint = nil
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if bIsInDungeon then
        local nDungeonId = BattleGameModeSystem.nDungeonId
        tbAllPoint = FFAMapPointDataTable:GetDungeonAllPoint(nDungeonId)
        local tbDungeonDescriptor = DungeonDataTable:GetDescriptor(nDungeonId)
        tbPointPos = tbDungeonDescriptor.FFAMapPoint
    else
        local nSceneId = GameWorldSystem:GetWorld().nSceneId
        tbAllPoint = SceneMapPointDataTable:GetSceneAllPoint(nSceneId)
        local tbSceneDescriptor = SceneDataTable:GetDescriptor(nSceneId)
        tbPointPos = tbSceneDescriptor.MapPoint
    end
    if not tbAllPoint or not tbPointPos then
        return tbAllPointData
    end
    for k, v in pairs(tbAllPoint) do
        --logdebug("ReLoadStaticObj", k)
        local tbPosData = tbPointPos[v.szPointKey]
        if tbPosData then
            local tbData = {}
            tbData.szName               = L10N:ToString(v.l10nDisplayName)
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
    return tbAllPointData
end


return MapOpStaticPoint