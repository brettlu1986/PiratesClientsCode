-----------------------------------------------------
--File Name    : MapOpQuest.lua
--Author       : LiHui
--Create Time  : 
--Description  : 跟踪当前所有任务要求的Item或者NPC
-----------------------------------------------------
local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpQuest = luaclass("MapOpQuest",MapOpBase)
local SelfEventHelperClass = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local MapObjType = require("MapObjType")
--local UIResourceDef = require("UIResourceDef")
--local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectSystem = require("GameObjectSystem_C")
local GameObjectTypeDef = require("GameObjectTypeDef")
local FFAMapQuestDataTable = require("FFAMapQuestDataTable")

MapOpQuest.SelfEventHelper = nil

--存储所有监控的NPC templateids
MapOpQuest.tbMonitorNPCTemplateIds = {}

--存储所有监控的GameTrigger ids
MapOpQuest.tbMonitorTriggerIds = {}

MapOpQuest.tbNPCInstanceIdObjs = {}

MapOpQuest.tbTriggerInstanceIdObjs = {}

MapOpQuest.MapOpTriggerObj = nil

local function AddNPCToMap(self,tbGameObject,szIcon)
    local nInstanceId = tbGameObject:GetServerInstanceId()
    local pActor = tbGameObject:GetModelActor()
    local UPObj = self:GetOneObj(MapObjType.QUEST_NPC)
    self.tbNPCInstanceIdObjs[nInstanceId] = UPObj
    local tbData = {}
    tbData.szIcon = szIcon
    local pLocation = tbGameObject:GetLocation()
    local nX, nY = self:CalculateUIMapLocation(pLocation)
    tbData.UILocation = {X = nX, Y = nY}
    tbData.UISize = {X = 50 ,Y = 50}--Todo ranjie修改后需要移除
    UPObj:ShowContent(tbData)

    self.MapOpObj:AddContentPoint(pActor, UPObj.pWidgetRef, true)
end

local function AddTriggerToMap(self,tbGameObject,szIcon)
    local nInstanceId = tbGameObject:GetServerInstanceId()
    local UPObj = self:GetOneObj(MapObjType.QUEST_NPC)
    local tbData = {}
    tbData.szIcon = szIcon
    local pLocation = tbGameObject:GetLocation()
    local nX, nY = self:CalculateUIMapLocation(pLocation)
    tbData.UILocation = {X = nX, Y = nY}
    tbData.UISize = {X = 50 ,Y = 50}--Todo ranjie修改后需要移除
    UPObj:ShowContent(tbData)

    tbData.nPointId = self.MapOpTriggerObj:AddContentPoint(UPObj.pWidgetRef, Vector{X = pLocation.X, Y = pLocation.Y, Z = 0})

    local tbTempData = {}
    tbTempData.UPObj = UPObj
    tbTempData.tbData = tbData
    self.tbTriggerInstanceIdObjs[nInstanceId] = tbTempData
end

local function OnGameObjectCreated(self, tbGameObject)
    local nType = tbGameObject:GetObjectType()

    if nType == GameObjectTypeDef.Npc then
        if tbGameObject.pUEActor and not tbGameObject.pUEActor.bHidden then
            local nTemplateId = tbGameObject:GetTemplateId()
            
            local szIcon = self.tbMonitorNPCTemplateIds[nTemplateId]
            if szIcon then
                AddNPCToMap(self,tbGameObject,szIcon)
            end
        end
    end

    if tbGameObject:GetObjectType() == GameObjectTypeDef.Trigger and 
       tbGameObject.tbCustomProtoData.scene_item_info and 
       tbGameObject.tbCustomProtoData.scene_item_info.template_id then 
            local nTemplateId = tbGameObject.tbCustomProtoData.scene_item_info.template_id
            local szIcon = self.tbMonitorTriggerIds[nTemplateId]
            if szIcon then
                AddTriggerToMap(self,tbGameObject,szIcon)
            end
    end 
end

local function OnGameObjectDestoryed(self, tbGameObject)
    local nType = tbGameObject:GetObjectType()
    local nInstanceId = tbGameObject:GetServerInstanceId()

    if nType == GameObjectTypeDef.Npc then
        if self.tbNPCInstanceIdObjs[nInstanceId] then
            local UPObj = self.tbNPCInstanceIdObjs[nInstanceId]
            UPObj:HideContent()
            UPObj = nil
        end
    end

    if tbGameObject:GetObjectType() == GameObjectTypeDef.Trigger then 
        if self.tbTriggerInstanceIdObjs[nInstanceId] then
            local tbTempData = self.tbTriggerInstanceIdObjs[nInstanceId]
            if tbTempData.UPObj then
                tbTempData.UPObj:HideContent()
            end

            if tbTempData.tbData.nPointId then
                self.MapOpTriggerObj:RemoveContentPoint(tbTempData.tbData.nPointId)
            end

            tbTempData = nil
        end
    end 
end

--解析配置表提取出所有监控的NPC TemplateId和Item Id.
local function ReadDataTable(self)
    self.tbMonitorNPCTemplateIds = FFAMapQuestDataTable:GetNPCData()
    self.tbMonitorTriggerIds = FFAMapQuestDataTable:GetItemData()
    --[[
    --todo 假数据
    self.tbMonitorNPCTemplateIds = {[70001] = UIResourceDef.UI_MAP_OBJ_AIR_DROP_ICON,
                                    [70002] = UIResourceDef.UI_MAP_OBJ_AIR_DROP_ICON,
                                    [70003] = UIResourceDef.UI_MAP_OBJ_AIR_DROP_ICON}

    self.tbMonitorTriggerIds = {[30010001] = UIResourceDef.LOBBY_PLAYER_TEAM_APPLY}
    ]]                       
end

--获取当前已经创建好的Triggers进行初始化
local function InitTriggersInfo(self)
    local tbGameObjectList = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Trigger)
    for GameObject, _ in pairs(tbGameObjectList) do
        if GameObject.tbCustomProtoData.scene_item_info and 
           GameObject.tbCustomProtoData.scene_item_info.template_id then 
            local nTemplateId = GameObject.tbCustomProtoData.scene_item_info.template_id
            local szIcon = self.tbMonitorTriggerIds[nTemplateId]
            if szIcon then
                AddTriggerToMap(self,GameObject,szIcon)
            end
            
        end 
    end
end

--获取当前已经创建好的NPCs进行初始化
local function InitNPCsInfo(self)
    local tbGameObjectList = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Npc)
    for GameObject, _ in pairs(tbGameObjectList) do
        if GameObject.pUEActor and not GameObject.pUEActor.bHidden then 
            local nTemplateId = GameObject:GetTemplateId()
            local szIcon = self.tbMonitorNPCTemplateIds[nTemplateId]
            if szIcon then
                AddNPCToMap(self,GameObject,szIcon)
            end
        end 
    end
end

function MapOpQuest:Refresh()
    --RefreshTriggerInfos(self)
end

function MapOpQuest:Init(Parent)
    MapOpQuest.super.Init(self, Parent)
    local MapOpTriggerObj = ExtendBlueprintFunctions.CreateObject(UIMapOpPoint,GameplayStatics.GetGameInstance(GWorld))
    MapOpTriggerObj:InitParam(self.pWidgetRef, 0, 0, 0)
    MapOpTriggerObj:SetEnable(false)
    self.pWidgetRef:RegisterOperation(MapOpTriggerObj)
    self.MapOpTriggerObj = MapOpTriggerObj

    self:ResetObjPool(MapObjType.QUEST_NPC)
    self.tbNPCInstanceIdObjs = {}
    self.tbTriggerInstanceIdObjs = {}
    self.tbMonitorNPCTemplateIds = {}
    self.tbMonitorTriggerIds = {}

    local UIMapOpPointWithActorObj = self:GetOpObj(UIMapOpPointWithActor)
    UIMapOpPointWithActorObj:InitParam(self.pWidgetRef, 1)
    self.pWidgetRef:RegisterOperation(UIMapOpPointWithActorObj)

    local SelfEventHelper = SelfEventHelperClass()
    self.SelfEventHelper = SelfEventHelper
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnGameObjectCreated)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_DESTORY, self, OnGameObjectDestoryed)
    
    ReadDataTable(self)
    InitTriggersInfo(self)
    InitNPCsInfo(self)
end

function MapOpQuest:Uninit()
    MapOpQuest.super.Uninit(self)
    self.SelfEventHelper:UnregisterAll()
end

function MapOpQuest:Reinit()
    MapOpQuest.super.Reinit(self)
end

return MapOpQuest
