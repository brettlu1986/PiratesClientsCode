-----------------------------------------------------
--File Name    : MapOpForSpecialGO.lua
--Author       : WuJizhou
--Create Time  : 2018-8-13 10:51:23
--Description  : MapOpForSpecialGO
-----------------------------------------------------
local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpForSpecialGO = luaclass("MapOpForSpecialGO", MapOpBase)
local MapOpDataSystem = require("MapOpDataSystem")
local ClientEventDef = require("ClientEventDef")
--local SelfEventHelper = require("SelfEventHelper")
local GameObjectSystem = require("GameObjectSystem_C")
local MapObjType = require("MapObjType")

MapOpForSpecialGO.tbSpecialGO = nil

local function AddToMap(self, nInstanceId, szIcon)
    if self.tbSpecialGO[nInstanceId] == nil then
        local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
        local pActor = tbGameObject:GetModelActor()
        local UPObj = self:GetOneObj(MapObjType.SPECIAL_GO)
        self.tbSpecialGO[nInstanceId] = UPObj
        UPObj:ShowContent({szRes = szIcon})
        self.MapOpObj:AddContentPoint(pActor, UPObj.pWidgetRef, true)
    end
end

local function RemoveFromMap(self, nInstanceId)
    for k, v in pairs(self.tbSpecialGO) do
        if k == nInstanceId then
            self.tbSpecialGO[nInstanceId]:HideContent()
            self.tbSpecialGO[nInstanceId] = nil
            break
        end
    end
end

local function Refresh(self)
    for k, v in pairs(MapOpDataSystem:GetAllSpecialGameObject()) do
        AddToMap(self, k, v)
    end
end

function MapOpForSpecialGO:Init(Parent)
    MapOpForSpecialGO.super.Init(self, Parent)
    self.tbSpecialGO = {}
    local UIMapOpPointWithActorObj = self:GetOpObj(UIMapOpPointWithActor)
    UIMapOpPointWithActorObj:InitParam(self.pWidgetRef, 1)
    self:TryMirrorMap()
    self.pWidgetRef:RegisterOperation(UIMapOpPointWithActorObj)
    -- self.SelfEventHelper = SelfEventHelper();
    -- self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_OP_ADD_SPECIAL_GO, self, AddToMap)
    -- self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_OP_REMOVE_SPECIAL_GO, self, RemoveFromMap)
    Refresh(self)
end

function MapOpForSpecialGO:Uninit()
    --self.SelfEventHelper:UnregisterAll()
    self.tbSpecialGO = nil
    MapOpForSpecialGO.super.Uninit(self)
end

function MapOpForSpecialGO:Reinit()
    MapOpForSpecialGO.super.Reinit(self)
    self:TryMirrorMap()
end

function MapOpForSpecialGO:BindEvent()
    MapOpForSpecialGO.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_OP_ADD_SPECIAL_GO, self, AddToMap)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_OP_REMOVE_SPECIAL_GO, self, RemoveFromMap)
end


return MapOpForSpecialGO