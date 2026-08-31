local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpForGOPathNew = luaclass("MapOpForGOPathNew", MapOpBase)
local UIDef = require("UIDef")
local UIResourceDef = require("UIResourceDef")
local MapObjType = require("MapObjType")
local ParachutionSystem_C = require("ParachutionSystem_C")

MapOpForGOPathNew.tbTransporters = nil
MapOpForGOPathNew.tbPrefabList = nil
MapOpForGOPathNew.nSelectTransporterId = nil

local POINT_SIZE = 20

local function Clear(self)
    for k, v in pairs(self.tbPrefabList) do
        for i, value in pairs(v) do
            value:Clear(self.MapOpObj)
        end
    end
end

function MapOpForGOPathNew:Init(Parent)
    MapOpForGOPathNew.super.Init(self, Parent)
    local MapOpObj = self:GetOpObj(UIMapOpPoint)
    MapOpObj:InitParam(self.pWidgetRef, 0, 0, 0)
    MapOpObj:SetEnable(false)
    self.pWidgetRef:RegisterOperation(MapOpObj)
    self.tbPrefabList = {}
    local tbInfos = ParachutionSystem_C:GetTransporterInfos()
    if tbInfos ~= nil then
        self:SetTransporterLines(tbInfos)
    end
end

function MapOpForGOPathNew:Uninit()
    Clear(self)
    self.tbPrefabList = nil
    MapOpForGOPathNew.super.Uninit(self)
end

local function GetUnitDistance(self)
    return 20000
end

local function GetNodesPos(self, nTransporterId, PathNodes, nUnitDistance)
    local tbPos = {}
    local nDistance, nCount = 0, #PathNodes
    local PrePointPos = {nX = PathNodes[1].nX, nY = PathNodes[1].nY}
    for i = 1, nCount do
        local PointPos = PathNodes[i]
        
        local nXDistance = PointPos.nX - PrePointPos.nX
        local nYDistance = PointPos.nY - PrePointPos.nY
        nDistance = math.sqrt(nXDistance ^ 2 + nYDistance ^ 2) 
        if( nDistance >= nUnitDistance)then
            local nFactor = math.floor(nDistance / nUnitDistance)
            for nCurrentFactor = 1, nFactor do
                local nVector = nCurrentFactor * nUnitDistance / nDistance
                local NewPointPos = {nX = PrePointPos.nX + nXDistance * nVector, nY = PrePointPos.nY + nYDistance * nVector}
                table.insert(tbPos, {nX = NewPointPos.nX, nY = NewPointPos.nY})
            end
            PrePointPos = tbPos[#tbPos]
        end
    end
    return tbPos, 1
end

local function RefreshNode(self, pbContentObj)
    if pbContentObj == nil then
        logwarning("MapOpForGOPathNew not find content obj")
        return
    end
    pbContentObj:Refresh(self.MapOpObj)
end

local function CreatePathNode(self, szUP, tbSize)
    local pbContentObj = self:GetOneObj(MapObjType.BORN_POINT)
    local ObjWidget = pbContentObj.pWidgetRef
    local ObjWidgetSlot = ObjWidget.Slot
    ObjWidgetSlot:SetAutoSize(false)
   
    return pbContentObj
end

local function AddTransporterNode(self, szUP, szRes, tbSize)
    local pbContentObj = CreatePathNode(self, szUP, tbSize)
    local tbData = {szIcon = szRes, Dimension = Vector2D{X=tbSize.X, Y=tbSize.Y}, UISize = {X=tbSize.X, Y=tbSize.Y}, bMatchSize = false}
    pbContentObj:ShowContent(tbData)       
    return pbContentObj
end

local function RefreshTransporterPathNodes(self, nTransporterId, tbNodes)
    local SelfHitTestInvisible, Collapsed = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    if self.tbPrefabList[nTransporterId] == nil then
        self.tbPrefabList[nTransporterId] = {} 
    end
    local tbTransporterPrefabList = self.tbPrefabList[nTransporterId]
    local tbNodesPos = GetNodesPos(self, nTransporterId, tbNodes, GetUnitDistance(self))
    local nNodeCount = #tbNodesPos
    local nOldNodeCount = #tbTransporterPrefabList
    local nTempCount = math.min(nNodeCount, nOldNodeCount)
    local pbContentObj 
    for i = 1, nTempCount do
        pbContentObj = tbTransporterPrefabList[i]
        pbContentObj:SetWorldPosition(tbNodesPos[i].nX, tbNodesPos[i].nY)
        RefreshNode(self, pbContentObj)
        pbContentObj.pWidgetRef:SetVisibility(SelfHitTestInvisible)
    end
    if nNodeCount > nOldNodeCount then
        for i = nOldNodeCount + 1, nNodeCount do
            pbContentObj = AddTransporterNode(self, 
                UIDef.UP_MAP_OBJ_FOR_BORN_POINT, 
                UIResourceDef.NEW_TRANSPORTER_LINE, 
                {X=POINT_SIZE, Y=POINT_SIZE})
            pbContentObj:SetWorldPosition(tbNodesPos[i].nX, tbNodesPos[i].nY)
            RefreshNode(self, pbContentObj)
            table.insert(tbTransporterPrefabList, pbContentObj)
        end
    elseif nOldNodeCount > nNodeCount then
        for i = nNodeCount + 1, nOldNodeCount do
            pbContentObj = tbTransporterPrefabList[i]
            pbContentObj.pWidgetRef:SetVisibility(Collapsed)
        end     
    end
end

local function RefreshSelectTransporterPathNodes(self, nTransporterId)
    local tbTransporterPrefabList = self.tbPrefabList and self.tbPrefabList[nTransporterId]
    if tbTransporterPrefabList == nil then
        return
    end
    local bSelected = self.nSelectTransporterId and self.nSelectTransporterId == nTransporterId
    local pColor = bSelected and UIResourceDef.COLOR.RED.SLATE_COLOR or UIResourceDef.COLOR.WHITE.SLATE_COLOR 
    log("set go path color:", nTransporterId, self.nSelectTransporterId, bSelected)
    for i, v in ipairs(tbTransporterPrefabList) do
        v:SetColor(pColor)
    end
end

function MapOpForGOPathNew:SetTransporterLines(tbTransporters)
    self.tbTransporters = tbTransporters
    for _, v in ipairs(self.tbTransporters) do
        RefreshTransporterPathNodes(self, v.nTransporterId, v.Node)
    end
end

function MapOpForGOPathNew:Refresh()
    -- if self.tbTransporters ~= nil then
    --     self:SetTransporterLines(self.tbTransporters)
    -- end
end

function MapOpForGOPathNew:SetSelfTransporterLine(nTransporterId)
    local nOld = self.nSelectTransporterId
    self.nSelectTransporterId = nTransporterId
    if nOld ~= nTransporterId then
        RefreshSelectTransporterPathNodes(self, nOld)
        RefreshSelectTransporterPathNodes(self, nTransporterId)
    end
end

function MapOpForGOPathNew:CancelSelfTransporterLine()
    local nOld = self.nSelectTransporterId
    self.nSelectTransporterId = nil
    RefreshSelectTransporterPathNodes(self, nOld)
end

return MapOpForGOPathNew