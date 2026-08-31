local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpForCoreArea = luaclass("MapOpForCoreArea", MapOpBase)
local UIResourceDef = require("UIResourceDef")
local ParachutingNewIni = require("ParachutingNewIni")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local DungeonDataTable = require("DungeonDataTable")
local UIMapResDataTable = require("UIMapResDataTable")
local MapObjType = require("MapObjType")


MapOpForCoreArea.nRadius = nil
MapOpForCoreArea.pbContentObj = nil

local function CreateCoreArea(self)
    self.pbContentObj = self:GetOneObj(MapObjType.BORN_POINT)
    local ObjWidget = self.pbContentObj.pWidgetRef
    local ObjWidgetSlot = ObjWidget.Slot
    ObjWidgetSlot:SetAutoSize(false)
    local tbData = {szIcon = UIResourceDef.CORE_AREA_POINT}--, Dimension = pSize, bMatchSize = false}   
    local nUIPosX, nUIPosY = self:CalculateUIMapLocation({X=0, Y=0}) 
    local nDungeonId = BattleGameModeSystem.nDungeonId
    local tbDungeonTemplate = DungeonDataTable:GetTemplate(nDungeonId)
    local tbMapResData = UIMapResDataTable:GetTemplate(tbDungeonTemplate.nUIMapId)
    local nUISizeX, nUISizeY = self:CalculateUISize(tbMapResData.nCoreAreaSizeX, tbMapResData.nCoreAreaSizeY)
    tbData.UILocation = {X = nUIPosX, Y = nUIPosY}
    tbData.UISize = {X = nUISizeX, Y = nUISizeY}
    self.pbContentObj:ShowContent(tbData)  
    self.nPointId = self.MapOpObj:AddContentPointWithSize(ObjWidget, Vector{X = 0, Y = 0, Z = 0}, ObjWidget.txtObjName, 0, 
    ObjWidget.imgIcon, Vector2D{X = tbMapResData.nCoreAreaSizeX, Y = tbMapResData.nCoreAreaSizeY})
 
end

function MapOpForCoreArea:Init(Parent)
    MapOpForCoreArea.super.Init(self, Parent)
    local MapOpObj = self:GetOpObj(UIMapOpPoint)
    MapOpObj:InitParam(self.pWidgetRef, 0, 0, 0)
    MapOpObj:SetEnable(false)
    self.pWidgetRef:RegisterOperation(MapOpObj)
    self:InitCoreArea()
end

function MapOpForCoreArea:Uninit()
    if self.pbContentObj ~= nil then
        self.pbContentObj:Clear(self.MapOpObj)
        self.pbContentObj = nil
    end
    MapOpForCoreArea.super.Uninit(self)
end

function MapOpForCoreArea:InitCoreArea()
    self.nRadius = ParachutingNewIni.tbReadyArea.nCoreAreaRadius
    CreateCoreArea(self)
    --RefreshCoreArea(self)    
end

function MapOpForCoreArea:Refresh()
    -- if self.nRadius ~= nil then
    --     RefreshCoreArea(self)
    -- end
end

return MapOpForCoreArea