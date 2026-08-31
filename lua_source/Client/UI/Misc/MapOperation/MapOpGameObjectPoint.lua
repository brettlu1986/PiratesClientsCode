-----------------------------------------------------
--File Name    : MapOpGameObjectPoint.lua
--Author       : Ran Jie
--Create Time  : 2017-8-1
--Description  : MapOpGameObjectPoint
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpGameObjectPoint = luaclass("MapOpGameObjectPoint",MapOpBase)

local MapObjType = require("MapObjType")
local MapGameObjectPointDataTable = require("MapGameObjectPointDataTable")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local CommonEventDef = require("CommonEventDef")

--------------------------------------------------------

local function TryAddGameObject(self, tbGameObj)
    if not tbGameObj then
        return
    end
    local tbPointTemplate = MapGameObjectPointDataTable:GetTemplate(tbGameObj:GetObjectType(), tbGameObj:GetTemplateId())
    if not tbPointTemplate then
        return
    end
    local Obj = self:GetOneObj(MapObjType.GAME_OBJECT_POINT)
    local tbData = {}
    tbData.szIcon = tbPointTemplate.szIconResPath
    if tbPointTemplate.nIconSizeX ~= -1 and tbPointTemplate.nIconSizeY ~= -1 then
        tbData.UISize = {X = tbPointTemplate.nIconSizeX, Y = tbPointTemplate.nIconSizeY}
    end
    Obj:ShowContent(tbData)
    self.MapOpObj:AddContentPoint(tbGameObj.pUEActor, Obj.pWidgetRef, false)
end


local function Refresh(self)
    local tbAllObjects = GameObjectSystem:GetAllGameObjects()
    for k, v in pairs(tbAllObjects) do
        TryAddGameObject(self, v)
    end
end

local function OnActorCreated(self, tbGameObj)
    TryAddGameObject(self, tbGameObj)
end

function MapOpGameObjectPoint:Init(Parent)
    MapOpGameObjectPoint.super.Init(self, Parent)
    local MapOpObj = self:GetOpObj(UIMapOpPointWithActor)
    local pWidgetRef = self.pWidgetRef
    MapOpObj:InitParam(self.pWidgetRef, 1)
    pWidgetRef:RegisterOperation(MapOpObj)
    Refresh(self)
end

function MapOpGameObjectPoint:Uninit()
    MapOpGameObjectPoint.super.Uninit(self)

end

function MapOpGameObjectPoint:Reinit()
    MapOpGameObjectPoint.super.Reinit(self)
end


function MapOpGameObjectPoint:BindEvent()
    MapOpGameObjectPoint.super.BindEvent(self)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnActorCreated)
end

return MapOpGameObjectPoint
