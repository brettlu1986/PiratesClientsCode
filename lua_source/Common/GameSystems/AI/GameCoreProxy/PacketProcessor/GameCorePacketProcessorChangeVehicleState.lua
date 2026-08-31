local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorChangeVehicleState = luaclass("GameCorePacketProcessorChangeVehicleState", GameCorePacketProcessorAction)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")

local GameCoreActionActorType = require("GameCoreActionActorType")

GameCorePacketProcessorChangeVehicleState.ActorType = GameCoreActionActorType.All

local SQUARED_DISTANCE = 22500 -- 150 * 150

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorChangeVehicleState:", ...)
end
-- luacheck: pop

local function GetSquaredDistance(nX1, nY1, nX2, nY2)
    return (nX1 - nX2)^2 + (nY1 - nY2)^2
end

local function GetIsLeft(tbAgent, tbVehicle)
    local pVehicleUEActor = tbVehicle:GetModelActor()
    local nX, nY, _ = tbAgent:GetLocationXYZ()
    local nLeftLocationX, nLeftLocationY, _ = pVehicleUEActor:GetLeftPointXYZ()
    local nLeftSquaredDistance = GetSquaredDistance(nX, nY, nLeftLocationX, nLeftLocationY)
    local nRightLocationX, nRightLocationY, _ = pVehicleUEActor:GetRightPointXYZ()
    local nRightSquaredDistance = GetSquaredDistance(nX, nY, nRightLocationX, nRightLocationY)
    if nLeftSquaredDistance <= nRightSquaredDistance then
        return true
    else
        return false
    end
end

local function CheckDistance(tbAgent, tbVehicle)
    local nVehicleId = tbVehicle:GetServerInstanceId()

    local nX, nY, nZ = tbAgent:GetLocationXYZ()
    local nVehicleX, nVehicleY, nVehicleZ = tbVehicle:GetLocationXYZ()

    local nDistance = GetSquaredDistance(nX, nY, nVehicleX, nVehicleY)
    if nDistance > SQUARED_DISTANCE then
        logerror("GameCoreBotAgent-> change vehicle failed! distance not valid", tbAgent:GetServerInstanceId(), nVehicleId, nX, nY, nZ, nVehicleX, nVehicleY, nVehicleZ, nDistance, SQUARED_DISTANCE)
        return false
    end
    return true
end

function GameCorePacketProcessorChangeVehicleState:DoAction(tbPacket)
    local tbAgent = self.tbAgent:GetGameObject()
    local GameVehicleComponent = tbAgent.GameVehicleComponent

    local bGetOn = tbPacket.get_on
    local nVehicleId = tbPacket.vehicle_id

    local bResult = false
    if bGetOn then
        local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleId)
        if not tbVehicle or not tbVehicle:IsAlive() or not tbVehicle:GetModelActor() then
            logerror("GameCoreBotAgent-> change vehicle failed! cannot find vehicle", tbAgent:GetServerInstanceId(), nVehicleId)
            return false
        end

        if tbVehicle:GetObjectType() ~= GameObjectTypeDef.Horse then
            logerror("GameCoreBotAgent-> change vehicle failed! object type not valid", tbAgent:GetServerInstanceId(), nVehicleId, tbVehicle:GetObjectType())
            return false
        end

        if not CheckDistance(tbAgent, tbVehicle) then
            return
        end
        local bIsLeft = GetIsLeft(tbAgent, tbVehicle)
        bResult = GameVehicleComponent:AIRequestGetInVehicle(nVehicleId, bIsLeft)
    else
        bResult = GameVehicleComponent:AIRequestGetOffVehicle()
    end
    if bResult then
        LOG("change vehicle:", tbAgent:GetServerInstanceId(), bGetOn, nVehicleId)
    else
        log("GameCoreBotAgent-> change vehicle failed!", tbAgent:GetServerInstanceId(), bGetOn, nVehicleId)
    end
end


return GameCorePacketProcessorChangeVehicleState