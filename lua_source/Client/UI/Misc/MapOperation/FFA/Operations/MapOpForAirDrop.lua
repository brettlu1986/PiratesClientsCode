-----------------------------------------------------
--File Name    : MapOpForAirDrop.lua
--Author       : WuJizhou
--Create Time  : 3/5/2019, 4:21:36 PM
--Description  : 空投图标
-----------------------------------------------------
local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
--local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local MapObjType = require("MapObjType")
local UIResourceDef = require("UIResourceDef")
local MapOpDataSystem = require("MapOpDataSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleHumanDecorationSystem = require("BattleHumanDecorationSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local MapOpForAirDrop = luaclass("MapOpForAirDrop", MapOpBase)

MapOpForAirDrop.EventHelper = nil

local function AddToMap(self, Location)
    local Obj = self:GetOneObj(MapObjType.AIR_DROP)
    local tbData = {}
    tbData.szIcon = UIResourceDef.UI_MAP_OBJ_AIR_DROP_ICON
    local nX, nY = self:CalculateUIMapLocation(Location)
    tbData.UILocation = {X = nX, Y = nY}
    tbData.UISize = {X = 32, Y = 32}
    tbData.SlateColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
    Obj:ShowContent(tbData)
    self.MapOpObj:AddContentPoint(Obj.pWidgetRef, Vector{X = Location.X, Y = Location.Y, Z = 0})
end

local function RefreshAll(self)
    if not BattleHumanDecorationSystem.GetAirDropVisibleOnMap(GamePlayerSelfHelper:Get()) then
        return
    end
    self:ResetObjPool(MapObjType.AIR_DROP)
    local tbList = MapOpDataSystem:GetAirDropList()
    for _, nInstanceId in ipairs(tbList) do
        local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
        local Location = tbGameObject:GetLocation()
        AddToMap(self, Location)
    end
end

local function OnAirDropRefresh(self, Location)
    if not BattleHumanDecorationSystem.GetAirDropVisibleOnMap(GamePlayerSelfHelper:Get()) then
        return
    end
    AddToMap(self, Location)
end

function MapOpForAirDrop:Init(Parent)
    MapOpForAirDrop.super.Init(self, Parent)
    local MapOpAirDropObj = self:GetOpObj(UIMapOpPoint)
    MapOpAirDropObj:InitParam(self.pWidgetRef, 0, 0, 0)
    MapOpAirDropObj:SetEnable(false)
    self.pWidgetRef:RegisterOperation(MapOpAirDropObj)
    RefreshAll(self)
end

function MapOpForAirDrop:Uninit()
    if self.MapOpObj then
        for k, Obj in pairs(self.tbObjPool)do
            if Obj.tbData then
                local nPointId = Obj.tbData.nPointId
                if nPointId then
                    self.MapOpObj:RemoveContentPoint(nPointId)
                end
            end
        end
    end
    --self:ResetObjPool(MapObjType.AIR_DROP)
    --self.EventHelper:UnregisterAll()
    MapOpForAirDrop.super.Uninit(self)
end

function MapOpForAirDrop:BindEvent()
    MapOpForAirDrop.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_OP_REFRESH_AIR_DROP, self, OnAirDropRefresh)
end

function MapOpForAirDrop:Open()
    MapOpForAirDrop.super.Open(self)
    RefreshAll(self)
end


return MapOpForAirDrop