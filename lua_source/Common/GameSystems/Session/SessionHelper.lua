-- local GameObjectSystem = dynamic_require("GameObjectSystem")
-- local GameObjectTypeDef= require("GameObjectTypeDef")
local GetActorLocationXYZ = EngineExtActorShell.GetActorLocationXYZ
local GetActorRotationYawPitchRoll = EngineExtActorShell.GetActorRotationYawPitchRoll
local GetLocationZOnFloor = EngineExtActorShell.GetLocationZOnFloor

local SessionHelper = {}

local TempVector1 = Vector()
local TempVector2 = Vector()
local ActorsToIgnore = {}

-- 单位：米
local OCEAN_EXTEND_DISTANCE = 100
local LAND_EXTEND_DISTANCE = 5

local RANDOM_COUNT = 5
-- local OFFSET_BORDER = 1000

local TYPE_SHORE = EPiratesGridRegionType.Shore
local TYPE_PORT = EPiratesGridRegionType.Port

local function SetVector(TempVector, X, Y, Z)
    TempVector.X = X
    TempVector.Y = Y
    TempVector.Z = Z
end

local function VerifyNeedRandomPoint(nNewX, nNewY, bShip)
    if bShip then
        return false
    else
        return true
    end
    -- if bShip then
    --     local tbAllObjs = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    --     for v, _ in pairs(tbAllObjs) do
    --         if v:IsShip() then
    --             local nX, nY = GetActorLocationXYZ(v.pUEActor)--v:GetLocation()
    --             local dx = nX - nNewX
    --             local dy = nY - nNewY
    --             if math.sqrt(dx * dx + dy * dy) <= OFFSET_BORDER then
    --                 return true
    --             end
    --         end            
    --     end
    --     return false
    --     -- local bHit = KismetSystemLibrary.SphereTraceSingleForObjects(GWorld, 
    --     --     Vector{X=pNewLocation.X, Y=pNewLocation.Y, Z=10000},
    --     --     Vector{X=pNewLocation.X, Y=pNewLocation.Y, Z=0},
    --     --     OFFSET_BORDER,
    --     --     {ECollisionChannel.ECC_EngineTraceChannel2, ECollisionChannel.ECC_EngineTraceChannel3, ECollisionChannel.ECC_EngineTraceChannel4, ECollisionChannel.ECC_EngineTraceChannel5},
    --     --     false, 
    --     --     {},
    --     --     EDrawDebugTrace.None,
    --     --     true,
    --     --     KMUMGLibrary.GetLinearColor(1.0, 1.0, 1.0, 1.0),
    --     --     KMUMGLibrary.GetLinearColor(1.0, 1.0, 1.0, 1.0),
    --     --     0)
    --     -- return bHit
    -- end

    -- return true
end

-- 延长线上随机取点，以免都出生在同一个点
local function GetRandomPoint(pGridTypeManager, pOriginLocation, pNewLocation, bShip)
    local pDirection = KismetMathLibrary.Subtract_VectorVector(pNewLocation, pOriginLocation)
    local pNormalDirection = KismetMathLibrary.Normal(pDirection, GDefaultTolerance)
    local nExtendDistance = 0
    if bShip then
        nExtendDistance = math.random()  * OCEAN_EXTEND_DISTANCE
    else
        nExtendDistance = math.random()  * LAND_EXTEND_DISTANCE
    end
    local nNegativeRandom = math.random() >= 0.5 and 1 or -1
    nExtendDistance = nExtendDistance * nNegativeRandom

    local pRandom = KismetMathLibrary.Multiply_VectorFloat(pNormalDirection, nExtendDistance * 100)
    local pVector = KismetMathLibrary.Add_VectorVector(pNewLocation, pRandom)

    local nRegionType = pGridTypeManager:GetRegionType(pVector.X, pVector.Y)
    if bShip then
        if nRegionType == TYPE_PORT then
            return pVector
        end
    else
        if nRegionType == TYPE_SHORE then
            return pVector
        end
    end
end

function SessionHelper.VerifyObjectNewTransform(tbGameObject, tbTransform)
    assert(tbGameObject)

    if tbTransform == nil then
        local nX, nY, nZ = GetActorLocationXYZ(tbGameObject.pUEActor)-- tbGameObject:GetLocation()
        local nYaw = GetActorRotationYawPitchRoll(tbGameObject.pUEActor)-- tbGameObject:GetRotation()
        tbTransform = {
            X = nX,
            Y = nY,
            Z = nZ,
            Yaw = nYaw
        }
    elseif(tbTransform.Yaw == nil) then
        local pUEActor = tbGameObject:GetModelActor()
        assert(pUEActor)
        local Location = tbGameObject:GetLocation()
        local pGridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
        if VerifyNeedRandomPoint(tbTransform.X, tbTransform.Y, not tbGameObject:IsShip()) then
            log("SessionHelper.VerifyObjectNewTransform ", tbTransform.X, tbTransform.Y, tbGameObject:IsShip())
            SetVector(TempVector1, tbTransform.X, tbTransform.Y, tbTransform.Z or 0)
            local nRandomCount = RANDOM_COUNT
            while nRandomCount > 0 do
                local pRandomVector = GetRandomPoint(pGridTypeManager, Location, TempVector1, not tbGameObject:IsShip())
                if pRandomVector ~= nil then
                    tbTransform.X = pRandomVector.X
                    tbTransform.Y = pRandomVector.Y
                    log("SessionHelper.VerifyObjectNewTransform Random pos: ", tbTransform.X, tbTransform.Y)
                    break
                end
                nRandomCount = nRandomCount - 1
            end
        end

        local nX = tbTransform.X
        local nY = tbTransform.Y
        SetVector(TempVector1, nX, nY, 5000)
        ActorsToIgnore[1] = pUEActor
        local nZ = tbGameObject:IsShip() and GetLocationZOnFloor(GWorld, TempVector1, ActorsToIgnore, 10000, -50000) or 0
        log("SessionHelper.VerifyObjectNewTransform x, y, z: ", nX, nY, nZ)
        SetVector(TempVector1, Location.X, Location.Y, 0)
        SetVector(TempVector2, nX, nY, 0)
        local NewDir = KismetMathLibrary.GetDirectionUnitVector(TempVector1, TempVector2)
        SetVector(TempVector1, 1, 0, 0)
        local nYaw = EngineExtActorShell.GetRotatorFromVectors(TempVector1, NewDir).Yaw

        local tbNewTrans = {
            X = nX,
            Y = nY,
            Z = nZ,
            Yaw = nYaw
        }
        tbTransform = tbNewTrans
    end
    return tbTransform
end

return SessionHelper