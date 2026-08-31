-----------------------------------------------------
--File Name    : MapOpOrientation.lua
--Author       : Ran Jie
--Create Time  : 2017-8-1
--Description  : MapOpOrientation
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpOrientation = luaclass("MapOpOrientation",MapOpBase)


local GameObjectSystem = require("GameObjectSystem_C")
local GameObjectTypeDef = require("GameObjectTypeDef")
local ShipDataTable = require("ShipDataTable")
local NPCDataTable = require("NPCDataTable")
local MapObjType = require("MapObjType")
local CommonEventDef = require("CommonEventDef")
local WorldMapUtil = require("WorldMapUtil")
local SelfEventHelper = require("SelfEventHelper")
local CampSystem = require("CampSystem")
-- local ShipAIUtility = require("ShipAIUtility")
local TemplateTypeDef = require("TemplateTypeDef")


MapOpOrientation.tbMapObjList = {}
MapOpOrientation.tbActorMapList = {}

local function FindEnemy(self, tbGameObj)
    local ActorShip = tbGameObj:GetModelActor()
    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(ActorShip)

    local pNpcData = NPCDataTable:GetTemplate(tbGameObj.nTemplateId)

    local tbData = {}
    tbData.nUniqueID = nUniqueID
    tbData.Location = ActorShip:K2_GetActorLocation()
    tbData.Yaw = ActorShip:K2_GetActorRotation().Yaw
    -- tbData.szName = pNpcData.szName
    tbData.bBoss = true

    -- tbData.bAlerted = ShipAIUtility.GetIsAIAlerted(tbGameObj)

    local tbRelation = WorldMapUtil.tbRelation
    if CampSystem:IsFriendRelation(self.SelfObj, tbGameObj) then
        tbData.RelationFlag = tbRelation.Friend
    else
        tbData.RelationFlag = tbRelation.Enemy
    end

    tbData.bNpc = true
    if pNpcData.nType == TemplateTypeDef.SHIP then
        tbData.nShipTypeID = ShipDataTable:GetShipCategoryData(pNpcData.nTypeID)
    else
        error("The pNpcData nType must be SHIP, nTemplateId: ", tbGameObj.nTemplateId)
    end

    local MapObj = self:GetOneObj(MapObjType.AI_NPC, true)
    local EventHelper = self.EventHelper
    EventHelper:RegisterLuaDelegate(tbGameObj.DelegateComponent.OnAIAlertedWhenPatrolling, function() if MapObj then MapObj:SetImageBrushTint(true) end end, self)
    EventHelper:RegisterLuaDelegate(tbGameObj.DelegateComponent.OnAIAlertedWhenPatrollingEnds, function() if MapObj then MapObj:SetImageBrushTint(false) end end, self)
    MapObj:ShowContent(tbData)
    self.tbMapObjList[nUniqueID] = MapObj
    self.MapOpObj:AddOrientationPoint(ActorShip, MapObj.pWidgetRef, false)
end

--事件通知
-- local function OnClientStealthStateChanged(self, nUniqueID, _StealthState)
--     local PlayerOrNpcObj = self.tbActorMapList[nUniqueID]
--     if(PlayerOrNpcObj == nil or PlayerOrNpcObj:IsDead())then
--         return
--     end
--     local ActorShip = PlayerOrNpcObj:GetModelActor()
--     local StealthState = ActorShip.ShipStealthClientComponent.StealthState

--     local tbMapObjList = self.tbMapObjList
--     local ActorWidgetObj = tbMapObjList[nUniqueID]
--     if(ActorWidgetObj == nil and StealthState == Enum_StealthState.Unfound)then
--         return
--     end

--     if(ActorWidgetObj ~= nil)then
--         if(StealthState == Enum_StealthState.Unfound)then
--             ActorWidgetObj:HideContent()
--             tbMapObjList[nUniqueID] = nil
--             self.MapOpObj:RemoveOrientationPoint(nUniqueID)
--         else
--             local tbData = ActorWidgetObj.tbData
--              tbData.bAlerted = ShipAIUtility.GetIsAIAlerted(PlayerOrNpcObj)
--             ActorWidgetObj:ShowContent(tbData)
--         end
--     else
--         FindEnemy(self, PlayerOrNpcObj)
--     end
-- end

-- OnPawnPreDestroy() 具有30秒的滞后性
function MapOpOrientation:OnPawnPreDestroy(tbDeadObject)
    if(tbDeadObject == nil)then
        return
    end

    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(tbDeadObject:GetModelActor())
    if tbDeadObject.ObjectType == GameObjectTypeDef.Npc then
        local ActorWidgetObj = self.tbMapObjList[nUniqueID]
        if ActorWidgetObj then
            self.tbActorMapList[nUniqueID] = nil
            self.tbMapObjList[nUniqueID] = nil
            ActorWidgetObj:HideContent()
            self.MapOpObj:RemoveOrientationPoint(nUniqueID)
        end
    end
end

function MapOpOrientation:OnPawnDead(tbDeadObject)
    self:OnPawnPreDestroy(tbDeadObject)
end

local function RefreshNpcInfo(self, tbGameObj)
    local bNpc = tbGameObj.ObjectType == GameObjectTypeDef.Npc
    if bNpc and not tbGameObj:IsDead() then
        local pNpcData = NPCDataTable:GetTemplate(tbGameObj.nTemplateId)
        if pNpcData.bIsBoos then
            local ActorShip = tbGameObj:GetModelActor()
            local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(ActorShip)
            if(self.tbActorMapList[nUniqueID] == nil)then
                -- EventHelper:RegisterLuaDelegate(tbGameObj.DelegateComponent.OnClientStealthStateChanged, function(StealthStateTemp) OnClientStealthStateChanged(self, nUniqueID, StealthStateTemp) end, self)
                -- local StealthState = ActorShip.ShipStealthClientComponent.StealthState
                -- if(StealthState ~= Enum_StealthState.Unfound )then
                    FindEnemy(self, tbGameObj)
                -- end
                self.tbActorMapList[nUniqueID] = tbGameObj
            end
        end
    end
end

local function RefreshInfo(self)
    local tbGameObjs = GameObjectSystem:GetAllGameObjects()
    for k,v in pairs(tbGameObjs) do
        RefreshNpcInfo(self, v)
    end
end

function MapOpOrientation:OnNewObjectCreate(tbGameObj)
    RefreshInfo(self, tbGameObj)  
end

function MapOpOrientation:Init(Parent)
    MapOpOrientation.super.Init(self, Parent)

    local MyselfEventHelper = SelfEventHelper()
    self.MyselfEventHelper = MyselfEventHelper
    MyselfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, self.OnPawnPreDestroy)
    MyselfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    MyselfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.OnNewObjectCreate)

    local pCurrentViewer = self:GetCurrentViewerActor()
    if not pCurrentViewer then
        logerror("MapOpOrientation:Init,ViewerActor is nil")
        return
    end
    local MapOrientationObj = self:GetOpObj(UIMapOpOrientationWithActor)

    MapOrientationObj:InitParam(self.pWidgetRef, pCurrentViewer, self.pWidgetRef.cvsPanel, self.pWidgetRef.cvsFlag, Vector2D{X = 175, Y = 145}, Vector2D{X = 0, Y = 0}, EMapShape.MAP_Square)
    self.pWidgetRef:RegisterOperation(MapOrientationObj)
    RefreshInfo(self)
end

function MapOpOrientation:Uninit()
    for k, v in pairs(self.tbActorMapList) do
        self.MapOpObj:RemoveOrientationPoint(k)
    end

    MapOpOrientation.super.Uninit(self)
    self.MyselfEventHelper:UnregisterAll()

    for k, v in pairs(self.tbMapObjList) do
        v:HideContent()
    end

    self.tbActorMapList = {}
    self.tbMapObjList = {}
end

function MapOpOrientation:Reinit()
    MapOpOrientation.super.Reinit(self)
    if self.MapOpObj then
        local pCurrentViewer = self:GetCurrentViewerActor()
        if not pCurrentViewer then
            logerror("MapOpOrientation:Reinit,ViewerActor is nil")
            return
        end
        self.MapOpObj:InitParam(self.pWidgetRef, pCurrentViewer, self.pWidgetRef.cvsPanel, self.pWidgetRef.cvsFlag, Vector2D{X = 175, Y = 145}, Vector2D{X = 0, Y = 0}, EMapShape.MAP_Square)
    end
end

return MapOpOrientation
