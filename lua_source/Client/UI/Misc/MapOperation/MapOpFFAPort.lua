-----------------------------------------------------
--File Name    : MapOpFFAPort.lua
--Author       : Ran Jie
--Description  : 最近出海/登陆的港口显示
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpFFAPort = luaclass("MapOpFFAPort",MapOpBase)


local MapObjType = require("MapObjType")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local MiniMapSystem = require("MiniMapSystem")
local ControlModeDef = require("ControlModeDef")
local ControlModeSystem = require("ControlModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local GRID_TYPE_LAND = EPiratesGridRegionType.Land
local GRID_TYPE_SHORE = EPiratesGridRegionType.Shore
local GRID_TYPE_PORT = EPiratesGridRegionType.Port
--local GRID_TYPE_OCEAN = EPiratesGridRegionType.Ocean
local MAKE_VECTOR_FUNC = KismetMathLibrary.MakeVector
local DelayTimer = require("DelayTimer")
local UIMapIni = require("UIMapIni")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")

local NAV_AGENT_RADIUS = 2500
local UI_PORT_OFFSET = 64
local UI_VIEW_RADIUS = 150

local EndLocation = Vector()

MapOpFFAPort.nPortUniqueId = nil
MapOpFFAPort.tbMapObj = nil
MapOpFFAPort.tbImageCache = {}
MapOpFFAPort.nImageIndex = 1

--Debug
local function ShowShoreMark(self, tbMarkPosList, pSlateColor)
    for k, v in pairs(self.tbImageCache) do
        v:SetVisibility(ESlateVisibility_Collapsed)
    end
    for k, v in pairs(tbMarkPosList) do
        local pWidget = self.tbImageCache[self.nImageIndex]
        if not pWidget then
            pWidget = self.WidgetHelper:CreateWidget(Image)
            self.pWidgetRef.cvsMapContent:AddChildToCanvas(pWidget)
            table.insert(self.tbImageCache, pWidget)
        end
        pWidget:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        local nX, nY = self:CalculateUIMapLocation(v)
        pWidget.Slot:SetPosition(Vector2D{X = nX, Y = nY})
        pWidget.Slot:SetSize(Vector2D{X = 10, Y = 10})
        UISetUtils.SetImageBrushTint(pWidget, pSlateColor)
        self.nImageIndex = self.nImageIndex + 1
    end
end
--

local function GetDistanceBetween(nSourceX, nSourceY, nTargetX, nTargetY)
    return math.sqrt((nTargetX - nSourceX) ^ 2 + (nTargetY - nSourceY) ^ 2)
end

local function GetClosestLocationInLand(SourceLocation, tbMarkPosition)
    local nShortestDist = math.maxinteger
    local nX = 0
    local nY = 0
    for k, v in pairs(tbMarkPosition) do
        local nDist = GetDistanceBetween(SourceLocation.X, SourceLocation.Y, v.X, v.Y)
        if nDist < nShortestDist then
            nShortestDist = nDist
            nX = v.X
            nY = v.Y
        end
    end
    return MAKE_VECTOR_FUNC(nX, nY, 0)
end

local function GetClosestLocationInOcean(SourceLocation, tbMarkPosition)
    local OceanNavGridManager = CommonShell.GetCommon(GWorld):GetOceanNavGridManager()
    local nShortestDist = math.maxinteger
    local nX = 0
    local nY = 0
    --local select = nil
    for k, v in ipairs(tbMarkPosition) do
        EndLocation.X = v.X
        EndLocation.Y = v.Y
        
        local nDist = OceanNavGridManager:GetNavDistInOcean(NAV_AGENT_RADIUS, SourceLocation, EndLocation)
        --logdebug("k,", k, SourceLocation.X, SourceLocation.Y, v.X, v.Y,nDist,nShortestDist)
        if nDist < nShortestDist then
            nShortestDist = nDist
            nX = v.X
            nY = v.Y
        end
    end
    --logdebug("select=",select)
    return MAKE_VECTOR_FUNC(nX, nY, 0)
end

local function CheckLocationInView(self, TargetLocation, SelfLocation, nOffset)
    local UIViewSize = {X = UI_VIEW_RADIUS - UI_PORT_OFFSET, Y = UI_VIEW_RADIUS - UI_PORT_OFFSET }
    local nRangeK = UIViewSize.Y / UIViewSize.X;
    local UITargetX, UITargetY = self:CalculateUIMapLocation(TargetLocation)
    local UISelfX, UISelfY = self:CalculateUIMapLocation(SelfLocation)
    local Diff = {X = UITargetX - UISelfX, Y = UITargetY - UISelfY}
    local nDiffSize = math.sqrt(Diff.X ^ 2 + Diff.Y ^ 2)
    local nPointK = math.abs(Diff.Y / Diff.X);
	if nPointK >= nRangeK then
        local nPointSize = math.abs(nDiffSize / Diff.Y * UIViewSize.Y)
        if nDiffSize > nPointSize then
            return false
        end
	else
        local nPointSize = math.abs(nDiffSize / Diff.X * UIViewSize.X)
        if nDiffSize > nPointSize then
            return false
        end
    end	
	return true
end

local function GetDistance(SourceLocation, TargetLocation)
    return math.sqrt((TargetLocation.X - SourceLocation.X) ^ 2 + (TargetLocation.Y - SourceLocation.Y) ^ 2)
end

local function GetScope(self)
    local tbMapResData = self.Parent.tbMapResData
    local nScope = tbMapResData.nScope
    local nCurrentControlMode = ControlModeSystem:GetCurrentModeType()
    if nCurrentControlMode == ControlModeDef.HUMAN then
        nScope = tbMapResData.nLandScope
    end
    return nScope
end

local function ShowMapObj(self)
    local tbObj = self.tbMapObj
    local tbData = nil
    if tbObj then
        tbData = tbObj.tbData
    else
        tbObj = self:GetOneObj(MapObjType.PORT_MARK, false)
        self.tbMapObj = tbObj
    end
    if not tbData then
        tbData = {}
        --tbData.bMatchSize = true
        tbData.UISize = {X = 64, Y = 64}
        --tbData.szIcon = UIResourceDef.LAST_USED_VEHICLE
    end
    tbObj:ShowContent(tbData)
    return tbObj, tbData
end

local function HideMapObj(self)
    local tbObj = self.tbMapObj
    if tbObj and tbObj.tbData then
        tbObj:HideContent()
    end
    if self.nPortUniqueId then
        self.MapOpObj:RemoveContentPoint(self.nPortUniqueId)
        self.nPortUniqueId = nil
    end
end

local function ShowPort(self)
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local pSelfLocation = PlayerSelf:GetLocation()
    local pLocation = nil
    local bResult = false
    local tbMarkPosition = nil
    local SelfLandType = GridTypeManager:GetRegionType(pSelfLocation.X, pSelfLocation.Y)
    if SelfLandType == GRID_TYPE_PORT then
        return
    end
    if PlayerSelf:IsHuman() then
        if SelfLandType == GRID_TYPE_LAND or SelfLandType == GRID_TYPE_SHORE then
            local nLandId = GridTypeManager:GetLandID(pSelfLocation.X, pSelfLocation.Y)
            if nLandId and nLandId > 0 then
                bResult, tbMarkPosition = GridTypeManager:GetMarkPositions(nLandId, GRID_TYPE_SHORE)
            end
        else
            local bResult1, pLandLocation = GridTypeManager:GetClosestPositionOfRegionType(pSelfLocation.X, pSelfLocation.Y, GRID_TYPE_SHORE)
            if bResult1 and pLandLocation then
                local nLandId = GridTypeManager:GetLandID(pLandLocation.X, pLandLocation.Y)
                if nLandId and nLandId > 0 then
                    bResult, tbMarkPosition = GridTypeManager:GetMarkPositions(nLandId, GRID_TYPE_SHORE)
                end
            else
                logwarning("MapOpFFAPort:ShowPort, human mode, GetClosestPositionOfRegionType failed")
            end
        end
        if bResult and tbMarkPosition then
            pLocation = GetClosestLocationInLand(pSelfLocation, tbMarkPosition)
        else
            log("MapOpFFAPort:ShowPort, human mode, GetMarkPositions failed, SelfLandType=",SelfLandType)
        end
    else
        local bResult1, pLandLocation = GridTypeManager:GetClosestPositionOfRegionType(pSelfLocation.X, pSelfLocation.Y, GRID_TYPE_SHORE)
        if bResult1 and pLandLocation then
            local nLandId = GridTypeManager:GetLandID(pLandLocation.X, pLandLocation.Y)
            if nLandId and nLandId > 0 then
                bResult, tbMarkPosition = GridTypeManager:GetMarkPositions(nLandId, GRID_TYPE_PORT)
                if bResult and tbMarkPosition then
                    --Debug
                    if GlobalVariableSystem.bDebugMapPath then
                        ShowShoreMark(self, tbMarkPosition, UIResourceDef.COLOR.RED.SLATE_COLOR)
                    end
                    --
                    pLocation = GetClosestLocationInOcean(pSelfLocation, tbMarkPosition)
                else
                    logwarning("MapOpFFAPort:ShowPort, ship mode, GetMarkPositions failed")
                end
            else
                logwarning("nLandId=",nLandId,pLandLocation.X, pLandLocation.Y,pSelfLocation.X, pSelfLocation.Y)
            end
        end
    end
    if bResult and pLocation then
        local tbObj, tbData = ShowMapObj(self)
        if tbData.nLocationX == pLocation.X and tbData.nLocationY == pLocation.Y and self.tbScopeChangeTimerHandle then
            return
        end
        tbData.nLocationX = pLocation.X
        tbData.nLocationY = pLocation.Y
        if self.nPortUniqueId then
            self.MapOpObj:RemoveContentPoint(self.nPortUniqueId)
        end
        self.nPortUniqueId = self.MapOpObj:AddContentPoint(tbObj.pWidgetRef, pLocation)
        if not self.bMMap then
            self.pWidgetRef.rtnImage:SetRenderingPhase(0, 1)
            local nDistance = GetDistance(pSelfLocation, pLocation)
            if not CheckLocationInView(self, pLocation, pSelfLocation) then
                local nSceneSizeX, _ = self:CalculateSceneSize(UI_PORT_OFFSET, UI_PORT_OFFSET)
                local nScope = GetScope(self)
                local nFixedScope = nScope + (nDistance + nSceneSizeX - nScope / 2) * 2
                if self.tbScopeChangeTimerHandle then
                    DelayTimer:ClearTimer(self.tbScopeChangeTimerHandle)
                    self.tbScopeChangeTimerHandle = nil
                end
                self.tbScopeChangeTimerHandle = DelayTimer:DelayRun(function()
                    self.tbScopeChangeTimerHandle = nil
                    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_SCOPE_CHANGE, nil, GetScope(self))
                end, UIMapIni.tbMMap.nPortMarkScopeChangeTime)
                self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_SCOPE_CHANGE, nil, nFixedScope)
            end
            -- if nDistance > (self.Parent.nCurrentScope / 2 - nOffset) then
            --     local nFixedScope = tbMapResData.nScope + (nDistance + nOffset - tbMapResData.nScope / 2) * 2
            --     self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_SCOPE_CHANGE, nil, nFixedScope)
            -- end
        end
    else
        log("MapOpFFAPort:ShowPort, location is nil")
    end
    
end

local function HidePort(self)
    if not self.bMMap then
        self.pWidgetRef.rtnImage:SetRenderingPhase(0, 6)
    end
    if self.tbScopeChangeTimerHandle then
        DelayTimer:ClearTimer(self.tbScopeChangeTimerHandle)
        self.tbScopeChangeTimerHandle = nil
    end
    if self.nPortUniqueId then
        HideMapObj(self)
        self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_SCOPE_CHANGE, nil, GetScope(self))
    end
end



local function OnControlModeDeactive(self, nControlMode)
    if nControlMode == ControlModeDef.HUMAN or nControlMode == ControlModeDef.SHIP then
        HidePort(self)
    end
end

local function OnShowPort(self, bShow)
    if bShow then
        ShowPort(self)
    else
        HidePort(self)
    end
end

function MapOpFFAPort:Init(Parent)
    MapOpFFAPort.super.Init(self, Parent)
    local MapOpObj = self:GetOpObj(UIMapOpPoint)
    self.MapOpObj:InitParam(self.pWidgetRef, 0, 0, 0)
    self.pWidgetRef:RegisterOperation(MapOpObj)
    if MiniMapSystem:IsShowPort() then
        ShowPort(self)
    else
        HidePort(self)
    end
end

function MapOpFFAPort:Uninit()
    MapOpFFAPort.super.Uninit(self)
    if self.tbScopeChangeTimerHandle then
        DelayTimer:ClearTimer(self.tbScopeChangeTimerHandle)
        self.tbScopeChangeTimerHandle = nil
    end
end

function MapOpFFAPort:Reinit()
    MapOpFFAPort.super.Reinit(self)
    --logdebug("MapOpFFAPort:Reinit")
    if MiniMapSystem:IsShowPort() then
        ShowPort(self)
    else
        HidePort(self)
    end
end

function MapOpFFAPort:BindEvent()
    MapOpFFAPort.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_HUMAN_SHIP_PORT, self, OnShowPort)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_DEACTIVATE, self, OnControlModeDeactive)
end

return MapOpFFAPort