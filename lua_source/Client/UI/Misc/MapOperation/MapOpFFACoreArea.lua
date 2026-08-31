-----------------------------------------------------
--File Name    : MapOpFFACoreArea.lua
--Author       : Ran Jie
--Description  : ffa中心区域
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpFFACoreArea = luaclass("MapOpFFACoreArea",MapOpBase)


local ClientEventDef = require("ClientEventDef")
local MapObjType = require("MapObjType")
local BattleCoreAreaSystem = require("BattleCoreAreaSystem")
local UIResourceDef = require("UIResourceDef")

local CORE_AREA_LOCATION = {X = 0, Y = 0}
local CORE_AREA_SIZE_SCALE = 1.4

MapOpFFACoreArea.tbMemberObjs = {}
MapOpFFACoreArea.tbStaticData = {}
MapOpFFACoreArea.nPointId = nil

local function HideCoreAreaFog(self)
    if self.tbFogObj then
        self.tbFogObj:HideContent()
    end
end

local function OnShowCoreArea(self,tbPacket)
    -- local bShowDialog = tbPacket.bShowDialog
    -- if not self.bMMap and bShowDialog then
    --     self.EventHelper:FireEvent(ClientEventDef.EV_FFA_SHOWDIALOG, self.Parent.tbMapResData.nDialogId)
    -- end
    HideCoreAreaFog(self)
end

local function SetCoreAreaMask(self)
    if BattleCoreAreaSystem:IsShowCoreArea() then
        if self.tbFogObj then
            HideCoreAreaFog(self)
        end
        return
    elseif self.tbFogObj then
        return
    end
    --logdebug("is show core area,",BattleCoreAreaSystem:IsShowCoreArea())
    local tbFogObj = self.tbFogObj
    local pWidgetSlot = nil
    local nUIX, nUIY = self:CalculateUIMapLocation(CORE_AREA_LOCATION)
    local tbMapResData = self.Parent.tbMapResData
    local nUISizeX, nUISizeY = self:CalculateUISize(tbMapResData.nCoreAreaSizeX, tbMapResData.nCoreAreaSizeY)
    nUISizeX = nUISizeX * CORE_AREA_SIZE_SCALE
    nUISizeY = nUISizeY * CORE_AREA_SIZE_SCALE
    if not tbFogObj then
        tbFogObj = self:GetOneObj(MapObjType.CORE_AREA)
        pWidgetSlot = tbFogObj.pWidgetRef.Slot
        pWidgetSlot:SetAutoSize(true)
        self.tbFogObj = tbFogObj
        local pObjWidgetRef = tbFogObj.pWidgetRef
        self.nPointId = self.MapOpObj:AddContentPointWithSize(pObjWidgetRef, Vector{X = CORE_AREA_LOCATION.X, Y = CORE_AREA_LOCATION.Y, Z = 0}, pObjWidgetRef.txtObjName, 0, 
        pObjWidgetRef.imgIcon, Vector2D{X = tbMapResData.nCoreAreaSizeX * CORE_AREA_SIZE_SCALE, Y = tbMapResData.nCoreAreaSizeY * CORE_AREA_SIZE_SCALE})
    else
        pWidgetSlot = tbFogObj.pWidgetRef.Slot
    end
    local tbData = tbFogObj.tbData
    if not tbData then
        tbData = {}
        tbData.szIcon = UIResourceDef.FFA_CORE_AREA
        tbFogObj:PlayAnimation("animRotate", 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
    
    
    tbData.UILocation = {X = nUIX, Y = nUIY}
    tbData.UISize = {X = nUISizeX, Y = nUISizeY}
    tbFogObj:ShowContent(tbData)
end

function MapOpFFACoreArea:Refresh()
    --SetCoreAreaMask(self)
end

function MapOpFFACoreArea:Init(Parent)
    MapOpFFACoreArea.super.Init(self, Parent)
    local MapOpObj = self:GetOpObj(UIMapOpPoint)
    MapOpObj:InitParam(self.pWidgetRef, 0, 0, 0)
    MapOpObj:SetEnable(false)
    self.pWidgetRef:RegisterOperation(MapOpObj)
    SetCoreAreaMask(self)
    --self.EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_CORE_AREA, self, OnShowCoreArea)
end

function MapOpFFACoreArea:Uninit()
    if self.nPointId and self.MapOpObj then
        self.MapOpObj:RemoveContentPoint(self.nPointId)
    end
    MapOpFFACoreArea.super.Uninit(self)
end

function MapOpFFACoreArea:Reinit()
    MapOpFFACoreArea.super.Reinit(self)
    SetCoreAreaMask(self)
end

function MapOpFFACoreArea:BindEvent()
    MapOpFFACoreArea.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SHOW_CORE_AREA, self, OnShowCoreArea)
end

return MapOpFFACoreArea