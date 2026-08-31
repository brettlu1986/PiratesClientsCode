local GameObjectSystem = dynamic_require("GameObjectSystem")
local FFAItemIni = require("FFAItemIni")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SceneItemActorDef = require("SceneItemActorDef")
local GameTriggerType        = require("GameTriggerType")
--local HumanMovementStateType = require("HumanMovementStateType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleTemplateActorSystem = dynamic_require("BattleTemplateActorSystem")

local SceneItemHelper = {}

local SCENEITEM_TEMPLATEID = 23
local AIRDROPITEM_TEMPLATEID = 24
local ECollisionType_ONLYCLIENT = 1
local ECollisionType_ALLNO = 3
-- local HUMAN_RADIUS = 200
-- local SHIP_RADIUS = 4000
-- local OCEAN_NETCULLDISTANCE = 50000
-- local LAND_NETCULLDISTANCE = 5000

local PORT_TO_LAND_MINDISTANCE = 2500 

local GRID_TYPE_OCEAN = EPiratesGridRegionType.Ocean
local GRID_TYPE_PORT = EPiratesGridRegionType.Port
local GRID_TYPE_SHORE = EPiratesGridRegionType.Shore
local GRID_TYPE_LAKE = EPiratesGridRegionType.Lake
local FLOOR_Z_MAX_OFFSET = 50
local FLOOR_Z_MIN_OFFSET = -10000
local DEFAULT_RADIUS = 32
local bEnableAdjustLocation = true

function SceneItemHelper:GetFloorZMinOffset()
    return FLOOR_Z_MIN_OFFSET, FLOOR_Z_MAX_OFFSET
end

function SceneItemHelper:GetIsOcean(tbTransform)
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRegionType = GridTypeManager:GetRegionType(tbTransform.X, tbTransform.Y)
    local bIsOcean = nRegionType == GRID_TYPE_OCEAN
    
    if nRegionType == GRID_TYPE_PORT then
        local bRet, NewLoction = GridTypeManager:GetClosestPositionOfRegionType(tbTransform.X, tbTransform.Y, GRID_TYPE_SHORE)
        assert(bRet)
        if bRet then
            local fnDistance = function(v1, v2)
                local dx = v1.X - v2.X
                local dy = v1.Y - v2.Y
                return math.sqrt(dx * dx + dy * dy)
            end
            bIsOcean = fnDistance(tbTransform, NewLoction) > PORT_TO_LAND_MINDISTANCE
        else
            bIsOcean = true 
        end        
    end

    return bIsOcean, nRegionType
end

function SceneItemHelper:NeedAdjustZ(tbTransform)
    local bIsOcean, nRegionType = self:GetIsOcean(tbTransform)
    return not bIsOcean and nRegionType ~= GRID_TYPE_PORT 
end

local function GetTriggerRadius(self, bIsOcean)
    return DEFAULT_RADIUS
end

function SceneItemHelper:SetScale(tbTrigger, bIsOcean)
    if tbTrigger == nil or tbTrigger.pUEActor == nil then
        return
    end

    local tbSceneItemIni  = FFAItemIni.tbSceneItem
    local nScale = bIsOcean and tbSceneItemIni.nOceanMeshScale or tbSceneItemIni.nLandMeshScale
    tbTrigger.pUEActor:SetScale(nScale)
end

local function GetLocationOnFloor(self, bIsOcean, tbTransform, nHumanMovementStateType, nRegionType)
    if bIsOcean or nRegionType == GRID_TYPE_PORT or nRegionType == GRID_TYPE_LAKE then
        tbTransform.Z = 0--math.min(tbTransform.Z, 0)
        return tbTransform
    end

    local pLocation = Vector{X = tbTransform.X, Y = tbTransform.Y, Z = tbTransform.Z}
    -- local tempZ = tbTransform.Z
    -- if nHumanMovementStateType ~= nil then
    --     -- 一些在洞里的检测，会比原来位置高，tbTransform.Z是人的位置，人的位置减1米是地的位置
    --     if nHumanMovementStateType == HumanMovementStateType.Crawl_State then
    --         tempZ = tbTransform.Z - 10
    --     elseif nHumanMovementStateType == HumanMovementStateType.Crouch_State then
    --         tempZ = tbTransform.Z - 40
    --     else
    --         tempZ = tbTransform.Z - 80
    --     end
    --     pLocation.Z = tempZ
    -- end

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

local function VerifyRotation(nYaw)
    return nYaw == nil and math.random(0, 360) or nYaw
end

-- local function SetNetCullDistance(self, tbTrigger, bIsOcean)
--     if tbTrigger == nil or tbTrigger.pUEActor == nil or bIsOcean then
--         return
--     end
--     if not GlobalVariableSystem:IsStandaloneServer() then
--         logerror("Sceneitem SetNetCullDistance ", debug.traceback(  ))
--         tbTrigger.pUEActor:SetNetCullDistance(LAND_NETCULLDISTANCE)
--     end
-- end

function SceneItemHelper:GetDefaultResId(nItemActorType)
    return nItemActorType == SceneItemActorDef.AIR_DROP_BOX and
        AIRDROPITEM_TEMPLATEID or SCENEITEM_TEMPLATEID
end

function SceneItemHelper.IsAirDrop(nInstanceId)
    local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
    -- 判断是否为空投
    if not tbGameObject or tbGameObject:GetObjectType() ~= GameObjectTypeDef.Trigger
        or tbGameObject.nType ~= GameTriggerType.SceneItem
        or tbGameObject.nResId ~= AIRDROPITEM_TEMPLATEID then
        return false
    end

    return true
end

function SceneItemHelper:SetEnableAutoAdjustLocation(bEnabled)
    bEnableAdjustLocation = bEnabled
end

function SceneItemHelper:GetCreateParam(nItemActorType, tbTransform, nHumanMovementStateType)
    local bIsAirDropItem = nItemActorType == SceneItemActorDef.AIR_DROP_BOX
    local bIsOcean, nRegionType = SceneItemHelper:GetIsOcean(tbTransform)
    local pLocation = bEnableAdjustLocation and GetLocationOnFloor(self, bIsOcean, tbTransform, nHumanMovementStateType, nRegionType) or tbTransform
    local nRadius = GetTriggerRadius(self, bIsOcean)
    local nResId = self:GetDefaultResId(nItemActorType)
    local nCollisionType = (not bIsAirDropItem and GlobalVariableSystem:IsStandalone()) and ECollisionType_ONLYCLIENT or ECollisionType_ALLNO 
    return bIsAirDropItem, bIsOcean, pLocation, nRadius, nResId, nCollisionType
end

-- create
function SceneItemHelper:Create(tbParam, tbTransform, nYaw)
    local bIsAirDropItem, bIsOcean, pLocation, nRadius, nResId, nCollisionType =
        self:GetCreateParam(tbParam.nItemActorType, tbTransform, tbParam.nHumanMovementStateType)

    local tbJsonData = {
        Transform = {
            X = pLocation.X,
            Y = pLocation.Y,
            Z = pLocation.Z,
            Yaw = VerifyRotation(nYaw),
        },
        ResId = nResId,
        TriggerId = -1,
        Shape = {
            Type = 0,
            -- 等引擎提供函数判断是陆地还是海洋
            Radius = nRadius,
        },
        CollisionType = nCollisionType
    }
    local tbData = {}
    tbData.tbJsonData = tbJsonData
    tbData.tbCustomData = {
        scene_item_info =
            {
                instance_id = tbParam.nItemInstanceId,
                type = tbParam.nItemActorType,
                template_id = tbParam.nItemTemplateId,
            }
    }
    local tbTrigger = GameObjectSystem:CreateTriggerInGameMode(tbData)

    if not bIsAirDropItem then
        self:SetScale(tbTrigger, bIsOcean)
        -- SetNetCullDistance(self, tbTrigger, bIsOcean)
    end
    -- SetMesh(self, tbTrigger, tbParam.nResId)
    return tbTrigger
end

function SceneItemHelper:SetPickOut(nItemInstanceId, tbTrigger)
    if(not tbTrigger) then
        return false
    end

    if(GlobalVariableSystem.bEnableTemplateActor and GlobalVariableSystem:IsServerLogic()) then
        BattleTemplateActorSystem:SetPickuped(nItemInstanceId)
    else
        local pUEActor = tbTrigger.pUEActor
        if(pUEActor == nil) then
            return false
        end
        pUEActor:SetPickOut()
    end
    return true
end

function SceneItemHelper:Destroy(nServerInstanceId)
    GameObjectSystem:DestroyTriggerInGameModeByInstanceId(nServerInstanceId)
end

return SceneItemHelper