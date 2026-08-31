-----------------------------------------------------
--File Name    : MapOpSizeScale.lua
--Author       : Ran Jie
--Create Time  : 2017-8-1
--Description  : MapOpSizeScale
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpSizeScale = luaclass("MapOpSizeScale",MapOpBase)

local ClientEventDef = require("ClientEventDef")


MapOpSizeScale.nSelfId = nil

--------------------------------------------------------

local function OnPinchChanged(self, tbTargetSize, bUpdateAlignment)
    --logdebug("OnPinchChanged............")
    --logdebug("OnPinchChanged,self=",self,self.MapOpObj)
    if self.MapOpObj then
        self.MapOpObj:SetPanelSize(tbTargetSize.X, tbTargetSize.Y)
        self.MapOpObj:SetPanelAlignment(bUpdateAlignment)
    end
end

function MapOpSizeScale:Init(Parent)
    MapOpSizeScale.super.Init(self, Parent)
    
    local pWidgetRef = self.pWidgetRef
    local pMinSize = Vector2D{X = self.Parent.ViewPortSize.X, Y = self.Parent.ViewPortSize.Y}
    local RootOwner = self.Parent.Owner
    local nMaxFactor = RootOwner:GetMaxZoomFactor()
    local ZoomHeight = self.Parent.ViewPortSize.Y * nMaxFactor
    local tbMapResData = self.Parent.tbMapResData
    local ZoomWidth = tbMapResData.nUIMapSizeX * ZoomHeight / tbMapResData.nUIMapSizeY
    local pMaxSize = Vector2D{X = ZoomWidth, Y = ZoomHeight}
    local pViewerActor = self:GetCurrentViewerActor()
    if not pViewerActor then
        log("MapOpSizeScale:Init,ViewerActor is nil")
        return
    end
    local MapOpObj = self:GetOpObj(UIMapScale)
    --logdebug("pMinSize=",pMinSize.X, pMinSize.Y)
    MapOpObj:InitParam(pViewerActor, pWidgetRef, pWidgetRef.cvsWorldMap, RootOwner.pWidgetRef.sldrZoom, pMinSize, pMaxSize, pWidgetRef.radarMap)
    MapOpObj:AddPanelWidget(pWidgetRef.cvsMapContent)
    pWidgetRef:RegisterOperation(MapOpObj)
    --self.EventHelper:RegisterEvent(ClientEventDef.EV_MAP_PINCH_CHANGED, self, OnPinchChanged)
end

function MapOpSizeScale:Uninit()
    MapOpSizeScale.super.Uninit(self)
end

function MapOpSizeScale:BindEvent()
    MapOpSizeScale.super.BindEvent(self)
    --logdebug("MapOpSizeScale:BindEvent",self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_MAP_PINCH_CHANGED, self, OnPinchChanged)
end

function MapOpSizeScale:Refresh()  
    
end

function MapOpSizeScale:Reinit()
    MapOpSizeScale.super.Reinit(self)
    if self.MapOpObj then
        local pWidgetRef = self.pWidgetRef
        local RootOwner = self.Parent.Owner
        local pMinSize = Vector2D{X = self.Parent.ViewPortSize.X, Y = self.Parent.ViewPortSize.Y}
        local nMaxFactor = RootOwner:GetMaxZoomFactor()
        local ZoomHeight = self.Parent.ViewPortSize.Y * nMaxFactor
        local tbMapResData = self.Parent.tbMapResData
        local ZoomWidth = tbMapResData.nUIMapSizeX * ZoomHeight / tbMapResData.nUIMapSizeY
        local pMaxSize = Vector2D{X = ZoomWidth, Y = ZoomHeight}
        local pViewerActor = self:GetCurrentViewerActor()
        if not pViewerActor then
            log("MapOpSizeScale:Reinit,ViewerActor is nil")
            return
        end
        self.MapOpObj:InitParam(pViewerActor, pWidgetRef, pWidgetRef.cvsWorldMap, RootOwner.pWidgetRef.sldrZoom, pMinSize, pMaxSize, pWidgetRef.radarMap)
        self.MapOpObj:AddPanelWidget(pWidgetRef.cvsMapContent)
    end
end


return MapOpSizeScale
