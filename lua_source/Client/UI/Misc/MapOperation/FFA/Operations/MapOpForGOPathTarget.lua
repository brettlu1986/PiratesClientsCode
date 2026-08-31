local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpForGOPathTarget = luaclass("MapOpForGOPathTarget", MapOpBase)
local UIDef = require("UIDef")
local UIResourceDef = require("UIResourceDef")
local ParachutionSystem_C = require("ParachutionSystem_C")

MapOpForGOPathTarget.tbTransporters = nil
MapOpForGOPathTarget.tbTargetPrefabList = nil
MapOpForGOPathTarget.nSelectTransporterId = nil
local POINT_SIZEX, POINT_SIZEY = 51, 55

local function Clear(self)
    for i, v in ipairs(self.tbTargetPrefabList) do
        v:Clear(self.MapOpObj)
    end
end

function MapOpForGOPathTarget:Init(Parent)
    MapOpForGOPathTarget.super.Init(self, Parent)
    local MapOpObj = self:GetOpObj(UIMapOpPoint)
    MapOpObj:InitParam(self.pWidgetRef, 0, 0, 0)
    MapOpObj:SetEnable(false)
    self.pWidgetRef:RegisterOperation(MapOpObj)

    self.tbTargetPrefabList = {}
    local tbInfos = ParachutionSystem_C:GetTransporterInfos()
    if tbInfos ~= nil then
        self:SetTransporterLines(tbInfos)
    end
end

function MapOpForGOPathTarget:Uninit()
    Clear(self)
    self.tbTargetPrefabList = nil
    MapOpForGOPathTarget.super.Uninit(self)
end

local function RefreshNode(self, pbContentObj)
    if pbContentObj == nil then
        logwarning("MapOpForGOPathNew not find content obj")
        return
    end
    pbContentObj:Refresh(self.MapOpObj)
    -- local nUIPosX, nUIPosY = self:CalculateUIMapLocation(pbContentObj:GetWorldPosition())
    -- pbContentObj:RefreshPosition(nUIPosX, nUIPosY)
end

local function CreatePathNode(self, szUP)
    local pbContentObj = self.PrefabHelper:CreatePrefab(szUP)
    pbContentObj:SetOwner(self.Parent)
    local ObjWidget = pbContentObj.pWidgetRef
    self.pWidgetRef.cvsMapContent:AddChildToCanvas(ObjWidget)
    ObjWidget:SetVisibility(ESlateVisibility.HitTestInvisible)
    local ObjWidgetSlot = ObjWidget.Slot
    ObjWidgetSlot:SetAlignment(Vector2D{X = 0.5, Y = 0.5})
    ObjWidgetSlot:SetAutoSize(false)
    return pbContentObj
end

local function AddTransporterNode(self, szUP, szRes, tbPos)
    local pbContentObj = CreatePathNode(self, szUP)
    local tbData = {szIcon = szRes, Dimension = Vector2D{X=POINT_SIZEX, Y=POINT_SIZEY}, bMatchSize = false}
    pbContentObj:ShowContent(tbData)
    pbContentObj:SetWorldPosition(tbPos.nX, tbPos.nY)
    RefreshNode(self, pbContentObj)        
    return pbContentObj
end

local function AddTransporterTargetNode(self, nTransporterId, tbTargetNode)
    local pbContentObj = AddTransporterNode(self, 
        UIDef.UP_MAP_OBJ_FOR_BORN_POINT,
        UIResourceDef.NEW_TRANSPORTER_TARGET,
        tbTargetNode)
    pbContentObj.nTransporterId = nTransporterId
    table.insert(self.tbTargetPrefabList, pbContentObj)
end

local function RefreshSelectTransporterTarget(self, nTransporterId)
    if nTransporterId == nil then
        for i, v in ipairs(self.tbTargetPrefabList) do
            v:SetColor(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
        end
    
        return
    end
    local bSelected = self.nSelectTransporterId and self.nSelectTransporterId == nTransporterId
    local pColor = bSelected and UIResourceDef.COLOR.RED.SLATE_COLOR or UIResourceDef.COLOR.WHITE.SLATE_COLOR 
    log("set path target color:", nTransporterId, self.nSelectTransporterId, bSelected)
    for i, v in ipairs(self.tbTargetPrefabList) do
        if v.nTransporterId == nTransporterId then
            v:SetColor(pColor)
            break
        end
    end
end

function MapOpForGOPathTarget:SetTransporterLines(tbTransporters)
    self.tbTransporters = tbTransporters
    for _, v in ipairs(self.tbTransporters) do
        AddTransporterTargetNode(self, v.nTransporterId, v.Node[#v.Node])
    end
end

function MapOpForGOPathTarget:Refresh()
    -- for _, v in ipairs(self.tbTargetPrefabList) do
    --     RefreshNode(self, v)
    -- end
end

function MapOpForGOPathTarget:SetSelfTransporterLine(nTransporterId)
    local nOld = self.nSelectTransporterId
    self.nSelectTransporterId = nTransporterId
    if nOld ~= nTransporterId then
        RefreshSelectTransporterTarget(self, nOld)
        RefreshSelectTransporterTarget(self, nTransporterId)
    end    
end

function MapOpForGOPathTarget:CancelSelfTransporterLine()
    self.nSelectTransporterId = nil
    RefreshSelectTransporterTarget(self)
end

return MapOpForGOPathTarget