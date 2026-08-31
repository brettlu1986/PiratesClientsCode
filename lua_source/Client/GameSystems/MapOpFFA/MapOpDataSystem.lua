-----------------------------------------------------
--File Name    : MapOpDataSystem.lua
--Author       : WuJizhou
--Create Time  : 2018-8-13 16:06:45
--Description  : 用于管理map op中一些特殊数据
-----------------------------------------------------
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local UIResourceDef = require("UIResourceDef")
local GameObjectSystem = require("GameObjectSystem_C")
local MapOpDataSystem = {}

MapOpDataSystem.EventHelper = nil
MapOpDataSystem.tbSpecialGameObjects = nil
MapOpDataSystem.tbPathInfo = nil
MapOpDataSystem.tbAirDropList = nil
local function IsNil(nInstanceId, szCallFuncName)
    if nInstanceId == nil then
        szCallFuncName = szCallFuncName == nil and "" or szCallFuncName
        logerror(szCallFuncName, "nInstanceId should not be nil!")
        return true
    end

    return false
end

function MapOpDataSystem:AddSpecialGameObject(nInstanceId, szIcon)
    if IsNil(nInstanceId, "MapOpDataSystem:AddSpecialGameObject") then
        return false
    end

    if not self.tbSpecialGameObjects[nInstanceId] then
        self.tbSpecialGameObjects[nInstanceId] = szIcon
        self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_OP_ADD_SPECIAL_GO, nInstanceId, szIcon)
        return true
    else
        logerror("MapOpDataSystem:AddSpecialGameObject", "Game object has been added, nInstanceId : ", nInstanceId)
        return false
    end
end

function MapOpDataSystem:RemoveSpecialGameObject(nInstanceId)
    if IsNil(nInstanceId, "MapOpDataSystem:RemoveSpecialGameObject") then
        return false
    end
    if not self.tbSpecialGameObjects[nInstanceId] then
        logerror("MapOpDataSystem:RemoveSpecialGameObject", "Game object does not exist, nInstanceId : ", nInstanceId)
        return false
    else
        self.tbSpecialGameObjects[nInstanceId] = nil
        self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_OP_REMOVE_SPECIAL_GO, nInstanceId)
        return true
    end
end

function MapOpDataSystem:GetAllSpecialGameObject()
    if not self.tbSpecialGameObjects then
        self.tbSpecialGameObjects = {}
    end
    return self.tbSpecialGameObjects
end


function MapOpDataSystem:AddPathInfo(nInstanceId, tbPathInfo)
    if IsNil(nInstanceId, "MapOpDataSystem:AddPathInfo") then
        return false
    end
    if not self.tbPathInfo[nInstanceId] then
        self.tbPathInfo[nInstanceId] = tbPathInfo
        self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_OP_ADD_PATH, tbPathInfo)
        return true
    else
        logerror("MapOpDataSystem:AddSpecialGameObject", "Game object has been added, nInstanceId : ", nInstanceId)
        return false
    end
end

function MapOpDataSystem:RemovePathInfo(nInstanceId)
    if IsNil(nInstanceId, "MapOpDataSystem:RemovePathInfo") then
        return false
    end
    if not self.tbPathInfo[nInstanceId] then
        logerror("MapOpDataSystem:RemovePathInfo", "Path info does not exist, nInstanceId : ", nInstanceId)
        return false
    else
        self.tbPathInfo[nInstanceId] = nil
        self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_OP_REMOVE_PATH, nInstanceId)
        return true
    end
end

function MapOpDataSystem:GetAllPathInfo()
    if self.tbPathInfo == nil then
        self.tbPathInfo = {}
    end
    return self.tbPathInfo
end

function MapOpDataSystem:AddAirDrop(nServerInstanceId)
    table.insert(self.tbAirDropList, nServerInstanceId)
end

function MapOpDataSystem:GetAirDropList()

    return self.tbAirDropList
end

local function OnReceivedFFATransportInfo(self, tbTransportInfo)
    local fnProcessFFATransportInfo = function(tbGameObject)
        local nInstanceId = tbGameObject:GetServerInstanceId()
        -- Add special go data
        self:AddSpecialGameObject(nInstanceId, UIResourceDef.FFA_TRANSPORT_PLANE_ICON)

        -- Add static go path data
        local tbPathInfo = {}
        tbPathInfo.nStartPosX = tbTransportInfo.nStartPosX
        tbPathInfo.nStartPosY = tbTransportInfo.nStartPosY
        tbPathInfo.nEndPosX = tbTransportInfo.nEndPosX
        tbPathInfo.nEndPosY = tbTransportInfo.nEndPosY
        tbPathInfo.nInstanceId = nInstanceId

        self:AddPathInfo(nInstanceId, tbPathInfo)
    end

    local OnFFATransportCreate = function(tbGameObject)
        log("OnReceivedFFATransportInfo", "OnFFATransportCreate.")
        self.EventHelper:UnregisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE)
        fnProcessFFATransportInfo(tbGameObject)
    end

    local nInstanceId = tbTransportInfo.nInstanceId
    local TransportGO = GameObjectSystem:FindByInstanceId(nInstanceId)
    if TransportGO == nil then
        log("OnReceivedFFATransportInfo", "Game obj is nil, listen actor create.")
        self.EventHelper:RegisterEventFunc(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, OnFFATransportCreate)
    else
        fnProcessFFATransportInfo(TransportGO)
    end
end

local function OnReceivedActorDestory(self, tbGameObject)
    local nInstanceId = tbGameObject:GetServerInstanceId()
    -- local nUniqueID = ExtendBlueprintFunctions.GetObjectUniqueID(ActorPlane)
    for k, v in pairs(self.tbSpecialGameObjects) do
        if k == nInstanceId then
            self:RemoveSpecialGameObject(nInstanceId)
            break
        end
    end

    for k, v in pairs(self.tbPathInfo) do
        if nInstanceId == k then
            self:RemovePathInfo(k)
            break
        end
    end
end

local function OnAirDropEnd(self, tbGameObject)
    local nInstanceId = tbGameObject:GetServerInstanceId()
    self:AddAirDrop(nInstanceId)
    local Location = tbGameObject:GetLocation()
    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_OP_REFRESH_AIR_DROP, Location)
end

--must exist
function MapOpDataSystem:Init()
    self.tbSpecialGameObjects = {}
    self.tbPathInfo = {}
    self.tbAirDropList = {}
    self.EventHelper = SelfEventHelper()
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_INFO, self, OnReceivedFFATransportInfo)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnReceivedActorDestory)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_FFA_AIRDROP_END, self, OnAirDropEnd)
    return true
end

--must exist
function MapOpDataSystem:Uninit()
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    self.tbSpecialGameObjects = nil
    self.tbPathInfo = nil
    self.tbAirDropList = nil
end

return MapOpDataSystem