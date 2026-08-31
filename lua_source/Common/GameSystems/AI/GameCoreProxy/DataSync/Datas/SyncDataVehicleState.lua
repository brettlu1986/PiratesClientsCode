local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataVehicleState = luaclass("SyncDataVehicleState", SyncDataBase)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GameCoreAgentLuaPoolManager = require("GameCoreAgentLuaPoolManager")

SyncDataVehicleState.tbVehicleState = nil
SyncDataVehicleState.tbVisibleVehicleState = nil

local nMaxVisibleHorse = 5

local function FillVisibleVehicleState(tbGameObject, tbVehicleState)
    -- local pUEActor = tbGameObject:GetModelActor()
    tbVehicleState.id = tbGameObject:GetServerInstanceId()
    local x, y, z = tbGameObject:GetLocationXYZ()
    tbVehicleState.position = tbVehicleState.position or {}
    local position = tbVehicleState.position
    position.x = x
    position.y = y
    position.z = z
    -- tbVehicleState.left_point = tbVehicleState.left_point or {}
    -- tbVehicleState.right_point = tbVehicleState.right_point or {}
    -- local left_point = tbVehicleState.left_point
    -- local nLeftLocationX, nLeftLocationY, nLeftLocationZ = pUEActor:GetLeftPointXYZ()
    -- left_point.x = nLeftLocationX
    -- left_point.y = nLeftLocationY
    -- left_point.z = nLeftLocationZ
    -- local right_point = tbVehicleState.right_point
    -- local nRightLocationX, nRightLocationY, nRightLocationZ = pUEActor:GetRightPointXYZ()
    -- right_point.x = nRightLocationX
    -- right_point.y = nRightLocationY
    -- right_point.z = nRightLocationZ
end

function SyncDataVehicleState:OnSync(tbPack)
    local tbOwner = self.tbOwner
    if tbOwner:IsHuman() then
        local nVehicleId = tbOwner.HumanMovementStateComponent:GetVehicleInstanceId(false)
        self.tbVehicleState.current_vehicle_id = nVehicleId
        if nVehicleId > 0 then
            local tbHorse = GameObjectSystem:FindByInstanceId(nVehicleId)
            if tbHorse and tbHorse:GetObjectType() == GameObjectTypeDef.Horse then
                local pUEActor = tbHorse:GetModelActor()
                self.tbVehicleState.rot_speed = pUEActor.CurRotSpeed
            end
        end

        local pAIController = self.pAIController
        local nNumVehicle = pAIController:GetVisibleVehicleNum()
        if nNumVehicle > 0 then
            local visible_vehicles = self.tbVisibleVehicleState
            local nNumSyncVehicle = 1
            local nLuaPoolId = tbOwner:GetServerInstanceId()
            local LuaPool = GameCoreAgentLuaPoolManager:Get(nLuaPoolId, "VisibleVehicle")
            for i=1,nNumVehicle do
                local nGameObjectInstanceId = pAIController:GetVisibleVehicle(i)
                if nGameObjectInstanceId > 0 and nNumSyncVehicle <= nMaxVisibleHorse then
                    local tbGameObject = GameObjectSystem:FindByInstanceId(nGameObjectInstanceId)
                    if tbGameObject:GetObjectType() == GameObjectTypeDef.Horse then
                        -- 内存持续增加 考虑使用LuaPool
                        local tbVehicleState = LuaPool:Get()
                        visible_vehicles[nNumSyncVehicle] = tbVehicleState
                        FillVisibleVehicleState(tbGameObject, tbVehicleState)
                        nNumSyncVehicle = nNumSyncVehicle + 1
                    end
                end
            end
            for i=nNumSyncVehicle, #visible_vehicles do
                visible_vehicles[i] = nil
            end
            self.tbVehicleState.visible_vehicles = self.tbVisibleVehicleState
        else
            self.tbVehicleState.visible_vehicles = nil
        end
        tbPack.vehicle_state = self.tbVehicleState
    else
        tbPack.vehicle_state = nil
    end
end


function SyncDataVehicleState:OnStart()
    self.tbVehicleState = {}
    self.tbVehicleState.current_vehicle_id = 0
    self.tbVisibleVehicleState = {}
end


function SyncDataVehicleState:OnStop()

end

return SyncDataVehicleState