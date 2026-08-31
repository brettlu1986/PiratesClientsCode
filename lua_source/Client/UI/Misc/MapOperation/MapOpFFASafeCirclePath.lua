-----------------------------------------------------
--File Name    : MapOpFFASafeCirclePath.lua
--Author       : WuJizhou
--Create Time  : 2018-9-12
--Description  : MapOpFFASafeCirclePath
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpFFASafeCirclePath = luaclass("MapOpFFASafeCirclePath",MapOpBase)

local ClientEventDef = require("ClientEventDef")
local PoisonCircleSystem = require("PoisonCircleSystem")
local MapObjType = require("MapObjType")
local UIResourceDef = require("UIResourceDef")
local UIMapIni = require("UIMapIni")
local ControlModeSystem = require("ControlModeSystem")
local ControlModeDef = require("ControlModeDef")
local MiniMapSystem = require("MiniMapSystem")

local LAND_WEIGHT = UIMapIni.tbMMap.nLandWeight
local OCEAN_WEIGHT = UIMapIni.tbMMap.nOceanWeight

MapOpFFASafeCirclePath.tbSafeCircleCenterPos = nil
MapOpFFASafeCirclePath.nSafeCircleRadius = 0
MapOpFFASafeCirclePath.tbMapObj = nil

local function SetFlagLine(self)
    if not self.MapOpObj then
        return
    end
    if self.tbSafeCircleCenterPos then
        local tbObj = self.tbMapObj
        local tbData = nil
        if not tbObj then
            tbData = {}
            tbObj = self:GetOneObj(MapObjType.FFA_FLAG_INFO)
            tbObj.MapOpScript = self
            tbObj:SetMapOp(self.MapOpObj)
            tbData.Obj = tbObj
            tbData.pLinearColor = UIResourceDef.COLOR.WHITE.LINEAR_COLOR
            tbData.bShowLine = true
            tbData.bShowPoint = false
            self.tbMapObj = tbObj
        else
            tbData = tbObj.tbData
        end
        tbData.X = self.tbSafeCircleCenterPos.X
        tbData.Y = self.tbSafeCircleCenterPos.Y
        tbObj:ShowContent(tbData)
    end
    if self.nSafeCircleRadius then
        self.MapOpObj:SetLineVisibleDistance(self.nSafeCircleRadius)
    end
end

local function OnPoisonCircleUpdate(self, tbPacket)
    local nNextRadius = tbPacket.nNextRadius
    if nNextRadius == 0 then
        return
    end
    self.tbSafeCircleCenterPos = {X = tbPacket.nNextX, Y = tbPacket.nNextY}
    self.nSafeCircleRadius = nNextRadius
    SetFlagLine(self)
end

local function OnShowCoreArea(self)
    if self.MapOpObj then
        local nCurrentMode = ControlModeSystem:GetCurrentModeType()
        if nCurrentMode == ControlModeDef.TRANSPORTNEW then
            self.MapOpObj:SetTargetRegionVisible(false)
        else
            self.MapOpObj:SetTargetRegionVisible(true)
        end
    end
end

-- local function SetIsSwimming(self)
--     local HumanMovementStateComponent = GamePlayerSelfHelper:Get().HumanMovementStateComponent
--     if HumanMovementStateComponent ~= nil then
--         local nCurState = HumanMovementStateComponent:GetCurrentState()
--         if nCurState == HumanMovementStateType.Swimming then
--             self.MapOpObj:SetSelfIsSwimming(true)
--         else
--             self.MapOpObj:SetSelfIsSwimming(false)
--         end
--     end
-- end

-- local function OnHumanMovementStateChanged(self, tbPlayer, nLastState, nNewState)
--     if nLastState == nNewState then
--         return
--     end
--     if nNewState == HumanMovementStateType.Swimming then
--         self.MapOpObj:SetSelfIsSwimming(true)
--     else
--         self.MapOpObj:SetSelfIsSwimming(false)
--     end
-- end

function MapOpFFASafeCirclePath:Init(Parent)
    MapOpFFASafeCirclePath.super.Init(self, Parent)
    local pWidgetRef = self.pWidgetRef
    local pViewerActor = self:GetCurrentViewerActor()
    if not pViewerActor then
        logerror("MapOpFFASafeCirclePath:Init,ViewerActor is nil")
        return
    end
    local MapOpFFAObj = self:GetOpObj(UIMapOpFlagPointLine)
    MapOpFFAObj:InitParam(pWidgetRef, pViewerActor, LAND_WEIGHT, OCEAN_WEIGHT, self:GetCurrentViewerObj():IsHuman(), MiniMapSystem:GetLandId())
    MapOpFFAObj:SetTickInterval(2)
    local nCurrentMode = ControlModeSystem:GetCurrentModeType()
    if nCurrentMode == ControlModeDef.TRANSPORTNEW then
        MapOpFFAObj:SetTargetRegionVisible(false)
        self.MapOpObj:SetSelfRegionVisible(false)
    else
        MapOpFFAObj:SetTargetRegionVisible(true)
        MapOpFFAObj:SetSelfRegionVisible(true)
    end
    --SetIsSwimming(self)
    if  PoisonCircleSystem.nDestRadius > 0 then
        self.tbSafeCircleCenterPos = PoisonCircleSystem.pDestVector
        self.nSafeCircleRadius = PoisonCircleSystem.nDestRadius
    end
    self.pWidgetRef:RegisterOperation(MapOpFFAObj)
    SetFlagLine(self)
end


function MapOpFFASafeCirclePath:Uninit()
    self.tbSafeCircleCenterPos = nil
    MapOpFFASafeCirclePath.super.Uninit(self)
end

function MapOpFFASafeCirclePath:Reinit()
    MapOpFFASafeCirclePath.super.Reinit(self)
    if self.MapOpObj then
        local pViewerActor = self:GetCurrentViewerActor()
        if not pViewerActor then
            logerror("MapOpFFASafeCirclePath:Reinit,ViewerActor is nil")
            return
        end
        self.MapOpObj:InitParam(self.pWidgetRef, pViewerActor, LAND_WEIGHT, OCEAN_WEIGHT, self:GetCurrentViewerObj():IsHuman(), MiniMapSystem:GetLandId())
        local nCurrentMode = ControlModeSystem:GetCurrentModeType()
        if nCurrentMode == ControlModeDef.TRANSPORTNEW then
            self.MapOpObj:SetTargetRegionVisible(false)
            self.MapOpObj:SetSelfRegionVisible(false)
        else
            self.MapOpObj:SetTargetRegionVisible(true)
            self.MapOpObj:SetSelfRegionVisible(true)
        end
        --SetIsSwimming(self)
    end
    if  PoisonCircleSystem.nDestRadius > 0 then
        self.tbSafeCircleCenterPos = PoisonCircleSystem.pDestVector
        self.nSafeCircleRadius = PoisonCircleSystem.nDestRadius
    end
    if self.tbSafeCircleCenterPos then
        SetFlagLine(self)
    end
end


function MapOpFFASafeCirclePath:BindEvent()
    MapOpFFASafeCirclePath.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_POISONCIRCLE_UPDATE, self, OnPoisonCircleUpdate)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_CORE_AREA, self, OnShowCoreArea)
    --self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnHumanMovementStateChanged)
end

return MapOpFFASafeCirclePath
