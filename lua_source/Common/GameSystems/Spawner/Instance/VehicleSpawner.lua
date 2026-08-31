-----------------------------------------------------
--File Name    : NPCSpawner.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-13
--Description  : NPCSpawner
-----------------------------------------------------
local luaclass = require("luaclass")
local NPCSpawnerBaseClass = require("NPCSpawnerBase")
local VehicleSpawner = luaclass("VehicleSpawner", NPCSpawnerBaseClass)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GOCreateDataHelper = dynamic_require("GOCreateDataHelper")
local GameVehicle = dynamic_require("GameVehicle")
local SpawnerDef = require("SpawnerDef")
local VehicleDropTable = require("VehicleDropTable")
local VehicleDropGroupTable = require("VehicleDropGroupTable")
local MathUtil = require("MathUtil")
local BattleTransformPointHelper = require("BattleTransformPointHelper")
local AsyncHelperSystem = require("AsyncHelperSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local FLOOR_Z_MAX_OFFSET = 50
local FLOOR_Z_MIN_OFFSET = -10000
local HORSE_MESH_OFFSET = -85

local TypeToGameObject = {
    GameObjectTypeDef.Horse
}

VehicleSpawner.nObjectUniqueId = nil

local function RandomVehicle(tbVehicleGroupData, nWeightSum)
    local nWorkCount = #tbVehicleGroupData
	if nWeightSum > 0 then 
		local fRandom = MathUtil.RandomFloat(0, nWeightSum);
		for i,v in ipairs(tbVehicleGroupData) do
			fRandom = fRandom - v.nWeight;
			if (fRandom <= 0) then 
				return v
			end 
		end 
	else 
		local nIndex = math.random( 1, nWorkCount)
		return tbVehicleGroupData[nIndex]
	end 
    return nil
end

local function DropVehicle(nDropId)
    local tbDropData = VehicleDropTable:GetTemplate(nDropId)
    if not tbDropData then  
        logerror("DropVehicle can't find vehicle " , nDropId)
        return nil 
    end 
    local tbVehicleGroupData = VehicleDropGroupTable:GetTemplate(tbDropData.nVehicleGroupId)
    local nCount = math.random(tbDropData.nMinCount, tbDropData.nMaxCount)
    -- logdebug("DropVehicle nCount", nCount, "tbDropData.nMinCount", tbDropData.nMinCount, tbDropData.nMaxCount, "tbDropData.nMaxCount")
    local nWeightSum = 0
    for i,v in ipairs(tbVehicleGroupData) do
        nWeightSum = nWeightSum + v.nWeight
    end
    local tbVehicleDatas = {}
    for i=1,nCount do
        local tbVechile = RandomVehicle(tbVehicleGroupData, nWeightSum)
        if tbVechile then  
            table.insert(tbVehicleDatas, tbVechile)
        end 
    end
    return tbVehicleDatas, nCount
end 

function VehicleSpawner:OnCreate(tbParams)
    self.tbSceneItemDataMap = {}
    self.nType = SpawnerDef.SpawnerType.VEHICLE
    self.nSpawnerId = tbParams.SpawnerId
    self.nDropGroupId = tbParams.DropGroupId
    -- self.bAutoSpawn = tbParams.AutoSpawn
    self.bAutoSpawn = false
    self.tbGroup = tbParams.Group
    
    -- self.tbItemData, self.nBoxTemplateId = BattleItemDropSystem:DropItems(self.nDropGroupId)
    self.tbVehicleGroupData, self.nVehicleCount = DropVehicle(tbParams.DropGroupId)
    return true
end

local function RandomTable(tbTable)
    if tbTable == nil or #tbTable <= 0 then
        return nil
    end
    local tbTemp = {}
    for _, v in ipairs(tbTable) do
        table.insert(tbTemp, v)
    end
    local taRandom = {}
    local index = 1
    while #tbTemp ~= 0 do
        local nRand = math.random(0, #tbTemp)
        if tbTemp[nRand] ~= nil then
            taRandom[index] = tbTemp[nRand]
            table.remove(tbTemp, nRand)
            index = index + 1
        end
    end
    return taRandom
end

local function GetLocationOnFloor(tbTransform)
    local pLocation = Vector{X = tbTransform.X, Y = tbTransform.Y, Z = tbTransform.Z}
	local tbIngoreActor = {}
	local tbObjects = GameObjectSystem:GetAllGameObjects()
	for _, v in pairs(tbObjects) do
		if v.pUEActor ~= nil then
			table.insert(tbIngoreActor, v.pUEActor)
		end
	end
    local nZ = EngineExtActorShell.GetLocationZOnFloor(GWorld, pLocation, tbIngoreActor, FLOOR_Z_MAX_OFFSET, FLOOR_Z_MIN_OFFSET)
    pLocation.Z = nZ
    return pLocation
end

function VehicleSpawner:Spawn()
    -- log("VehicleSpawner:Spawn", self.nSpawnerId, self.nTemplateId,
    --     self.nX, self.nY, self.nZ, self.nYaw,
    --     self.nGroupIndex)
    -- logdebug("VehicleSpawner Spawn")
    local nCurrent = 1
    local nCountTransform = #self.tbGroup
    if nCountTransform <=0 then  
        return 
    end
    local tbRandomTransform = {}
    for i,v in ipairs(self.tbVehicleGroupData) do
        nCurrent = nCurrent % nCountTransform
        if nCurrent == 0 then
            nCurrent = nCountTransform
        end

        -- 每次循环随机一下点组
        if nCurrent == 1 then
            tbRandomTransform = RandomTable(self.tbGroup)
        end
        local nTransformId = tbRandomTransform[nCurrent]
        -- logdebug("VehicleSpawner nTransformId", nTransformId, "v.nVehicleGroupId", v.nVehicleGroupId)
        local tbTransform = BattleTransformPointHelper:Find(nTransformId)
        if tbTransform then
            -- self.tbJsonData = self.tbCreateParams
            -- logdebug("X", tbTransform.X, "Y", tbTransform.Y)
            AsyncHelperSystem:AddToAsyncList({nVehicleId = v.nVehicleId, tbTransform = tbTransform}, function(tbParam) 
                local tbVehicleTransform = tbParam.tbTransform 
                tbVehicleTransform.Z = tbVehicleTransform.Z + 100
                local pLocation = GetLocationOnFloor(tbVehicleTransform)
                tbVehicleTransform.Z = pLocation.Z - HORSE_MESH_OFFSET
                local VehicleType = TypeToGameObject[v.nVehicleType]
                GameObjectSystem:CreateVehicleInGameMode(tbParam.nVehicleId, VehicleType, tbVehicleTransform)    -- self拥有spawninfo用到的所有参数
            end )
            -- if(tbRet) then
            --     self.nObjectUniqueId = tbRet:GetUEActorUniqueId()
            -- end
            nCurrent = nCurrent + 1
        end     
    end
    AsyncHelperSystem:ReadyForAsync()
    -- local tbRet = GameObjectSystem:CreateNpcInGameMode(self.nTemplateId, 
    --     self.nX, self.nY, self.nZ, self.nYaw,
    --     self.nGroupIndex, self.szTag, self.tbCreateParams)

    return true
end

function VehicleSpawner:CollectResource(tbInOutResources)
    -- logdebug("VehicleSpawner:CollectResource")
    self.tbJsonData = self.tbCreateParams
    -- local tbCreateData = GOCreateDataHelper:ParseNpcGameModeData(-1, self.nTemplateId, 
    --     self.nX, self.nY, self.nZ, self.nYaw,
    --     self.nGroupIndex, self.szTag, self.tbCreateParams)
    local tbCreateData = GOCreateDataHelper:ParseVehicleGameModeData(-1, self)    
    local szRes = GameVehicle.StaticCollectResources(tbCreateData, nil)
    if(szRes) then
        table.insert(tbInOutResources, szRes)
    end
end


return VehicleSpawner
