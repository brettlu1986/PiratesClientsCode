-----------------------------------------------------
--File Name    : MapOpForDiamond.lua
--Author       : ZhangWei
--Create Time  : 2020-6-16
--Description  : 宝石图标
-----------------------------------------------------
local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapObjType = require("MapObjType")
local ClientEventDef = require("ClientEventDef")
local UIResourceDef = require("UIResourceDef")
local BattleHumanDecorationSystem = require("BattleHumanDecorationSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local MiniMapSystem = require("MiniMapSystem")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")

local MapOpForDiamond = luaclass("MapOpForDiamond", MapOpBase)

local MapObjTypeDiamond = MapObjType.AIR_DROP

MapOpForDiamond.nDiamondPointId = nil

local function AddToMap(self, Location)
    local Obj = self:GetOneObj(MapObjTypeDiamond)
    local tbData = {}
    tbData.szIcon = UIResourceDef.UI_MAP_OBJ_DIAMOND_ICON
    local nX, nY = self:CalculateUIMapLocation(Location)
    tbData.UILocation = {X = nX, Y = nY}
    tbData.UISize = {X = 32, Y = 32}
    tbData.SlateColor = UIResourceDef.COLOR.WHITE.SLATE_COLOR
    Obj:ShowContent(tbData)
    -- logdebug("**[Decoration-Chart]**: AddToMap: UILocation.X,Y = ", tbData.UILocation.X, tbData.UILocation.Y)
    
    Location.Z = 0

    self.nDiamondPointId = self.MapOpObj:AddContentPoint(Obj.pWidgetRef, Location)
    -- logdebug("**[Decoration-Chart]**: ++++++++++++++++++ self.nDiamondPointId = ", self.nDiamondPointId)
    -- logdebug("**[Decoration-Chart]**: AddToMap: Location.X,Y,Z = ", Location.X, Location.Y, Location.Z)
end

local function RefreshDiamondDisplay(self, bShowToast)
    self:ResetObjPool(MapObjTypeDiamond)
    if self.nDiamondPointId then
        -- logdebug("**[Decoration-Chart]**: ------------------ self.nDiamondPointId = ", self.nDiamondPointId)
        self.MapOpObj:RemoveContentPoint(self.nDiamondPointId)
    end
    
    local tbPlayer = GamePlayerSelfHelper:Get()
    if not BattleHumanDecorationSystem.GetDiamondVisibleOnMap(tbPlayer) then
        -- logdebug("**[Decoration-Chart]**: RefreshDiamondDisplay: GetDiamondVisibleOnMap = false")
        return
    end

    local bFound = MiniMapSystem:IsFoundNearbyDiamond()
    -- logdebug("**[Decoration-Chart]**: RefreshDiamondDisplay: bFound = ", bFound)
    if bFound then
        local Location = MiniMapSystem:GetNearbyDiamondLocation()
        -- logdebug("**[Decoration-Chart]**: RefreshDiamondDisplay: Location.X,Y,Z = ", Location.X, Location.Y, Location.Z)
        AddToMap(self, Location)
    end

    if bShowToast then
        if bFound then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("DIAMOND_POSITION_REFRESHED"))
        else
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("DIAMOND_NOT_FOUND"))
        end
    end
end

local function OnNearbyDiamondRefreshed(self)
    RefreshDiamondDisplay(self, true)
end

function MapOpForDiamond:Init(Parent)
    MapOpForDiamond.super.Init(self, Parent)
    local MapOpDiamondObj = self:GetOpObj(UIMapOpPoint)
    MapOpDiamondObj:InitParam(self.pWidgetRef, 0, 0, 0)
    MapOpDiamondObj:SetEnable(false)
    self.pWidgetRef:RegisterOperation(MapOpDiamondObj)
    RefreshDiamondDisplay(self, false)
end

function MapOpForDiamond:Uninit()
    if self.MapOpObj and self.nDiamondPointId then
        -- logdebug("**[Decoration-Chart]**: MapOpForDiamond:Uninit >>>>>>>>>>>>>>> self.nDiamondPointId = ", self.nDiamondPointId)
        self.MapOpObj:RemoveContentPoint(self.nDiamondPointId)
        self.nDiamondPointId = nil
    end
    --self:ResetObjPool(MapObjTypeDiamond)
    --self.EventHelper:UnregisterAll()
    MapOpForDiamond.super.Uninit(self)
end

function MapOpForDiamond:BindEvent()
    MapOpForDiamond.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_NEARBY_DIAMOND_REFRESHED, self, OnNearbyDiamondRefreshed)
end

function MapOpForDiamond:Open()
    MapOpForDiamond.super.Open(self)
    RefreshDiamondDisplay(self, false)
end


return MapOpForDiamond