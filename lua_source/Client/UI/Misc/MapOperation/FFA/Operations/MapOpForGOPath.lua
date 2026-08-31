-----------------------------------------------------
--File Name    : MapOpForGOPath.lua
--Author       : WuJizhou
--Create Time  : 2018-8-13 10:51:04
--Description  : MapOpForGOPath
-----------------------------------------------------

--local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local GameObjectSystem = require("GameObjectSystem_C")
local MapOpDataSystem = require("MapOpDataSystem")

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpForGOPath = luaclass("MapOpForGOPath", MapOpBase)
local MapObjType = require("MapObjType")

MapOpForGOPath.tbGOPath = nil

local function AddToMap(self, tbPathInfo)
    if self.tbGOPath[tbPathInfo.nInstanceId] == nil then
        local tbGameObject = GameObjectSystem:FindByInstanceId(tbPathInfo.nInstanceId)
        local pActor = tbGameObject:GetModelActor()
        local UPObj = self:GetOneObj(MapObjType.GO_PATH)
        self.tbGOPath[tbPathInfo.nInstanceId] = UPObj
        local tbData = {}
        tbData.tbPathInfo = tbPathInfo
        --Location
        local nCenterX = (tbPathInfo.nStartPosX + tbPathInfo.nEndPosX) / 2
        local nCenterY = (tbPathInfo.nStartPosY + tbPathInfo.nEndPosY) / 2
        local UIPosX, UIPosY = self:CalculateUIMapLocation({X = nCenterX, Y =  nCenterY})
        
        --Rotation
        local UIStartX, UIStartY = self:CalculateUIMapLocation({X = tbPathInfo.nStartPosX, Y = tbPathInfo.nStartPosY})
        local UIEndX, UIEndY = self:CalculateUIMapLocation({X = tbPathInfo.nEndPosX, Y = tbPathInfo.nEndPosY})
        local nDeltaX = UIStartX - UIEndX
        local nDeltaY = UIStartY - UIEndY
        local nAngle = math.atan( nDeltaY, nDeltaX ) * 180 / math.pi
        tbData.UIStartX = UIStartX
        tbData.UIStartY = UIStartY
        tbData.UIEndX = UIEndX
        tbData.UIEndY = UIEndY

        local bMirror = self:TryMirrorMap()
        if bMirror then
            tbData.UIRotation = 180 - nAngle
            local UIMapSizeX = self.Parent.UIMapValidSize.X + self.Parent.UIMapValidOffset.X * 2
            tbData.UILocation = {X = UIMapSizeX - UIPosX, Y = UIPosY}
        else
            tbData.UIRotation = nAngle
            tbData.UILocation = {X = UIPosX, Y = UIPosY}
        end
        UPObj:ShowContent(tbData)
        local StartVector = Vector2D{X = tbPathInfo.nStartPosX, Y =  tbPathInfo.nStartPosY}
        local EndVector = Vector2D{X = tbPathInfo.nEndPosX, Y =  tbPathInfo.nEndPosY}
        self.MapOpObj:AddPath(pActor, UPObj.pWidgetRef.pgbPath, StartVector, EndVector)
    end
end

local function RemoveFromMap(self, nInstanceId)
    if not self.MapOpObj then
        return
    end
    local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
    local pActor = tbGameObject:GetModelActor()
    local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(pActor)
    self.MapOpObj:RemovePath(nUniqueID)
    local UPMapObj = self.tbGOPath[nInstanceId]
    if UPMapObj then
        UPMapObj:HideContent()
    end
    self.tbGOPath[nInstanceId] = nil
    -- for k, v in pairs(self.tbGOPath) do
    --     logdebug("RemoveFromMap:k,nInstanceId=",k,nInstanceId)
    --     if k == nInstanceId then
    --         self.tbGOPath[nInstanceId]:HideContent()
    --         self.tbGOPath[nInstanceId] = nil
    --         break
    --     end
    -- end
end

local function RefreshInternal(self)
    for k, v in pairs(MapOpDataSystem:GetAllPathInfo()) do
        AddToMap(self, v)
    end
end

function MapOpForGOPath:Init(Parent)
    MapOpForGOPath.super.Init(self, Parent)
    self.tbGOPath = {}
    local MapObjInCpp = self:GetOpObj(UIMapOpStaticPath)
    self.pWidgetRef:RegisterOperation(MapObjInCpp)
    -- self.SelfEventHelper = SelfEventHelper();
    -- self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_OP_ADD_PATH, self, AddToMap)
    -- self.SelfEventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_OP_REMOVE_PATH, self, RemoveFromMap)
    self:Refresh()
end

function MapOpForGOPath:Uninit()
    self.tbGOPath = nil
    --self.SelfEventHelper:UnregisterAll()
    MapOpForGOPath.super.Uninit(self)
end

function MapOpForGOPath:Refresh()
    for k, v in pairs(MapOpDataSystem:GetAllPathInfo()) do
        RemoveFromMap(self, k)
    end
    RefreshInternal(self)
end

function MapOpForGOPath:Reinit()
    MapOpForGOPath.super.Reinit(self)
    for k, v in pairs(MapOpDataSystem:GetAllPathInfo()) do
        RemoveFromMap(self, k)
    end
    RefreshInternal(self)
end

function MapOpForGOPath:BindEvent()
    MapOpForGOPath.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_OP_ADD_PATH, self, AddToMap)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_MAP_OP_REMOVE_PATH, self, RemoveFromMap)
end

return MapOpForGOPath