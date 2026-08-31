-----------------------------------------------------
--File Name    : MapOpMapMove.lua
--Author       : Ran Jie
--Create Time  : 2017-8-1
--Description  : MapOpPlayer
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpMapMove = luaclass("MapOpMapMove",MapOpBase)

local WorldMapResDataTable = require("WorldMapResDataTable")
local ClientEventDef = require("ClientEventDef")
local UISetUtils = require("UISetUtils")

local szMapArray = "PaperSprite'/Game/UI/Textures/UI_WorldMap/Frames/Spr_Oneself.Spr_Oneself'"

-- local function OnShipDie(self)
--     self.MapOpObj:SetEnable(false)
-- end

-- local function OnShipRespawn(self)
--     --logdebug("OnShipRespawn:self="..tostring(self))
--     self.MapOpObj:SetEnable(true)
-- end

local function RefreshPlayerDynamicFlag(self, tbGameObj)
    if tbGameObj == self.SelfObj then
        local szIcon
        local nDynamicResID = tbGameObj:GetDynamicFlagId()
        if nDynamicResID and nDynamicResID > 0 then
            szIcon = WorldMapResDataTable:GetMapRes(nDynamicResID)
        else
            szIcon = szMapArray
        end

        UISetUtils.SetImageBrushRes(self.pWidgetRef.ovlArrow, szIcon:load(), true)
    end
end

local function OnExitLoading(self)
    --self.MapOpObj:SetInterSpeed(5, 0)
end


function MapOpMapMove:Init(Parent)
    MapOpMapMove.super.Init(self, Parent)
    
    local pViewerActor = self:GetCurrentViewerActor()
    if not pViewerActor then
        logerror("MapOpMapMove:Init,ViewerActor is nil")
        return
    end
    local MapMoveObj = self:GetOpObj(UIMapMove)
    MapMoveObj:InitParam(self.pWidgetRef, pViewerActor, self.pWidgetRef.cvsMapPos, self.pWidgetRef.ovlArrow, self.pWidgetRef.cvsMapContent, self.pWidgetRef.radarMap)
    self:TryMirrorMap()
    MapMoveObj:SetInterSpeed(0, 0)
    self.pWidgetRef:RegisterOperation(MapMoveObj)
    --self.pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    --self.MyselfEventHelper = SelfEventHelper()
    --BindEvent(self)
end

function MapOpMapMove:Uninit()
    MapOpMapMove.super.Uninit(self)
    --UnBindEvent(self)
end

function MapOpMapMove:Reinit()
    MapOpMapMove.super.Reinit(self)
    if self.MapOpObj then
        local pViewerActor = self:GetCurrentViewerActor()
        if not pViewerActor then
            logerror("MapOpMapMove:Reinit,ViewerActor is nil")
            return
        end
        self.MapOpObj:InitParam(self.pWidgetRef, pViewerActor, self.pWidgetRef.cvsMapPos, self.pWidgetRef.ovlArrow, self.pWidgetRef.cvsMapContent, self.pWidgetRef.radarMap)
        self:TryMirrorMap()
    end
end

function MapOpMapMove:BindEvent()
    MapOpMapMove.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_MAP_REFRESH_DYNAMIC_FLAG, self, RefreshPlayerDynamicFlag)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, OnExitLoading)
end

return MapOpMapMove
