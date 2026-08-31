local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpForSelfBornPoint = luaclass("MapOpForSelfBornPoint", MapOpBase)
--local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local UIResourceDef = require("UIResourceDef")
local MapObjType = require("MapObjType")
local ParachutionSystem_C = require("ParachutionSystem_C")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local POINT_SIZEX, POINT_SIZEY = 20, 35

MapOpForSelfBornPoint.Prefab = nil
MapOpForSelfBornPoint.nPointId = nil

local function GetTeamMemberIndex(self)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local BattleTeamComponent = tbPlayerSelf.BattleTeamComponent
    local nId = tbPlayerSelf:GetServerInstanceId()
    local tbMemberIdList = BattleTeamComponent.tbBattleTeamInfo and BattleTeamComponent.tbBattleTeamInfo.TeamInfos or {}

    for i, v in ipairs(tbMemberIdList) do
        if nId == v.nInstanceId then
            return v.nIndex
        end
    end
    return 1 
end

local function OnSelectPoint(self)
    local tbSelectedPoint = ParachutionSystem_C:GetSelectedPoint()
    if tbSelectedPoint == nil then
        return
    end
    
    if self.Prefab == nil then
        self.Prefab = self:GetOneObj(MapObjType.BORN_POINT)
        local ObjWidget = self.Prefab.pWidgetRef
        local ObjWidgetSlot = ObjWidget.Slot
        ObjWidgetSlot:SetAlignment(Vector2D{X = 0.5, Y = 1})
        ObjWidgetSlot:SetAutoSize(false)        
    end
    local nTeamMemberIndex = GetTeamMemberIndex(self)
    local tbData = {szIcon = UIResourceDef.BORN_POINT, SlateColor = UIResourceDef.TEAM_INDEX_SLATECOLOR[nTeamMemberIndex], Dimension = Vector2D{X=POINT_SIZEX, Y=POINT_SIZEY}, bMatchSize = false}    
    
    local nX, nY = self:CalculateUIMapLocation({X=tbSelectedPoint.nX, Y=tbSelectedPoint.nY})
    tbData.UILocation = {X = nX, Y = nY}
    tbData.UISize = {X = 20, Y = 35}
    self.Prefab:ShowContent(tbData)
    if self.nPointId then
        self.MapOpObj:RemoveContentPoint(self.nPointId)
    end
    self.nPointId = self.MapOpObj:AddContentPoint(self.Prefab.pWidgetRef, Vector{X = tbSelectedPoint.nX, Y = tbSelectedPoint.nY, Z = 0})
end

function MapOpForSelfBornPoint:Init(Parent)
    MapOpForSelfBornPoint.super.Init(self, Parent)
    local MapOpFlagPointObj = self:GetOpObj(UIMapOpPoint)
    MapOpFlagPointObj:InitParam(self.pWidgetRef, 0, 0, 0)
    MapOpFlagPointObj:SetEnable(false)
    self.pWidgetRef:RegisterOperation(MapOpFlagPointObj)

    self:ResetObjPool(MapObjType.BORN_POINT)
    OnSelectPoint(self)
    -- local EventHelper = SelfEventHelper()
    -- EventHelper:RegisterEvent(ClientEventDef.EV_FFA_SELECT_POINT_TRANSPORTER, self, OnSelectPoint)
    -- self.EventHelper = EventHelper
end

function MapOpForSelfBornPoint:Uninit()
    if self.nPointId then
        self.MapOpObj:RemoveContentPoint(self.nPointId)
    end
    MapOpForSelfBornPoint.super.Uninit(self)
end

function MapOpForSelfBornPoint:Refresh()
    OnSelectPoint(self)
end

function MapOpForSelfBornPoint:BindEvent()
    MapOpForSelfBornPoint.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_SELECT_POINT_TRANSPORTER, self, OnSelectPoint)
end

return MapOpForSelfBornPoint