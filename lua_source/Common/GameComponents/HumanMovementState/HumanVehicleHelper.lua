---author ken
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local EventManager = require("EventManager")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local VehicleDataTable = require("VehicleDataTable")
local CommonEventDef = require("CommonEventDef")
-- local TeamWatchServerHelper = require("TeamWatchServerHelper")

local AIHelper = require("AIHelper")

local HumanVehicleHelper = {}

local GameCameraModeGroupDef = nil
local ClientEventDef = nil
local GameCameraSystem = nil

function HumanVehicleHelper.EnableClientAdjustment(pUEActor, bEnable)
    -- 开关服务器矫正客户端位置
    pUEActor.CharacterMovement.bIgnoreClientMovementErrorChecksAndCorrection = not bEnable
    pUEActor.CharacterMovement.bEnableClientAdjustPosition = bEnable
    pUEActor.CharacterMovement.bEnableAdjustRotationMatchSlope = bEnable

    -- 避免下马的时候被加上Z轴速度
    pUEActor.CharacterMovement.bImpartBaseVelocityZ = bEnable
end

function HumanVehicleHelper.RequestVehicleState( nState, vehicle_id, end_pos, nVehicleTriggerType)
    local c2d_RequestVehicleState =
    {
        vehicle_state = nState,
        vehicle_id = vehicle_id,
        end_pos = end_pos,
        vehicle_trigger_type = nVehicleTriggerType
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_RequestVehicleState, c2d_RequestVehicleState)
end

function HumanVehicleHelper.RequestVehicleFailed(GamePlayer, reason_id)
    local d2c_RequestVehicleFailed =
    {
        failed_reason_id = reason_id,
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(GamePlayer:GetUEControllerUniqueId(), ProtoDC.d2c_RequestVehicleFailed, d2c_RequestVehicleFailed)
end

local function DisableOnVehicleAutoRot(GamePlayer)
    if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf and GlobalVariableSystem:IsClient() then
        local CameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        CameraManager:EnableAutoRot(false)
    end
end

function HumanVehicleHelper.ClearVehicle(GamePlayer, bDestroyActor, bForceDetach)
    local VehicleComponent = GamePlayer.GameVehicleComponent
    -- local pUEActor = GamePlayer.pUEActor
    local nVehicleInstanceId = VehicleComponent:GetVehicleInstanceId(true)
    local nVehicleState = VehicleComponent:GetVehicleState()
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    log("[VehicleDebugLog] HumanVehicleHelper.ClearVehicle using new vehicle component, bDestroyActor, nVehicleState=", bDestroyActor, nVehicleState)
    if bDestroyActor then
        if tbVehicle and nVehicleState ~= HumanVehicleStateDef.None then
            tbVehicle:SetDriver(GamePlayer, false)
            EventManager:OnFireEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, GamePlayer, HumanVehicleStateDef.None, nVehicleInstanceId)
        end
    else
        if GlobalVariableSystem:IsServerLogic() then
            HumanVehicleHelper.SetVehicleState(VehicleComponent, HumanVehicleStateDef.None, VehicleComponent:GetVehicleInstanceId())
        end
    end
end

function HumanVehicleHelper.SetVehicleState(GameVehicleComponent, nVehicleState, nVehicleId, nVehicleTriggerType)
    if not GameVehicleComponent then
        return
    end
    GameVehicleComponent:SetVehicleState(nVehicleState, nVehicleId, nVehicleTriggerType)
end


function HumanVehicleHelper.ChangeVehicleCamera(GamePlayer, nVehicleId ,bActive)
    if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then

        if GlobalVariableSystem:IsClient() then

            local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleId)
            if not tbVehicle then
                return
            end

            if not GameCameraModeGroupDef then
                GameCameraModeGroupDef = require("GameCameraModeGroupDef")
                ClientEventDef = require("ClientEventDef")
                GameCameraSystem = require("GameCameraSystem")
            end

            if GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.VehicleView) and bActive then
                return
            end

            --不要 deactive 多次
            if not GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.VehicleView) and
                not GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.HumanFreeView) and
                    not bActive then
                return
            end

            local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
            if bActive then
                GameCameraManager:EnableCameraMoveCollisionCheck(true, false)
                EventManager:OnFireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.VehicleView, { pTarget = tbVehicle.pUEActor})
            else
                GameCameraManager:EnableCameraMoveCollisionCheck(false, false)
                EventManager:OnFireEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.VehicleView)
            end
        end
     end
end


function HumanVehicleHelper.SetVehicleActorRotSpeed(tbVehicle)
    local tbVehicleData = VehicleDataTable:GetTemplate(tbVehicle:GetTemplateId())
    local pVehicleActor = tbVehicle.pUEActor
    pVehicleActor:InitMoveRightValue(
        tbVehicleData.nForwardRotVel,
        tbVehicleData.nBackRotVel,
        tbVehicleData.nStandRotVel,
        tbVehicleData.nRotAccelaration,
        tbVehicleData.nRotDeceleration,
        tbVehicleData.nRotDecelerationMinVel
    )
end

function HumanVehicleHelper.AttachToVehicle(GamePlayer, nVehicleInstanceId, bForceAttach)
    local pUEActor = GamePlayer.pUEActor
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    if tbVehicle and not pUEActor.bInVehicle then
        local pHumanLoc = GamePlayer:GetLocation()
        log("[VehicleDebugLog]", GamePlayer:GetName(), "GameVehicleHelper.AttachToVehicle human loc after attachment", pHumanLoc.X, pHumanLoc.Y, pHumanLoc.Z)
        pUEActor:SetAttachVehicle(true, tbVehicle.pUEActor)
        pUEActor.CharacterMovement:SetMovementMode(EMovementMode.MOVE_Walking, 0)
        pUEActor.CharacterMovement:SetComponentTickEnabled(false)

        if GlobalVariableSystem:IsServerLogic() and AIHelper.IsAIControlled(GamePlayer) then
            tbVehicle.pUEActor.bUseControllerRotationYaw = false
            tbVehicle.pUEActor.bIsAIControlled = true
        else
            -- ai没关
            HumanVehicleHelper.EnableClientAdjustment(pUEActor, true)
            tbVehicle.pUEActor.bUseControllerRotationYaw = true
        end

        tbVehicle:AttachToVehicle(GamePlayer, true, bForceAttach)
        HumanVehicleHelper.ChangeVehicleCamera(GamePlayer, nVehicleInstanceId ,true)
        HumanVehicleHelper.SetVehicleActorRotSpeed(tbVehicle)
        -- if GlobalVariableSystem:IsServerLogic() then
        --     local AIVehicleManager = CommonShell.GetCommon(GWorld):GetAIVehicleManager()
        --     --上马后将马的信息从格子中移除，不需要被AI感知， AI会感知马上的人
        --     AIVehicleManager:RemoveVehicle(tbVehicle.nServerInstanceId)
        --     log("ai:remove vehicle ",tbVehicle.nServerInstanceId)
        -- end
    end
end

function HumanVehicleHelper.ForceDetachFromVehicle(GamePlayer)
    local VehicleComponent = GamePlayer.GameVehicleComponent
    if not VehicleComponent then
        log("[VehicleDebugLog] HumanVehicleHelper.ForceDetachFromVehicle, VehicleComponent is nil.")
        return
    end
    local tbVehicle = GameObjectSystem:FindByInstanceId(VehicleComponent:GetVehicleInstanceId())
    if tbVehicle and tbVehicle.pUEActor then
        local location = tbVehicle.pUEActor:GetAttachLocation(0)
        GamePlayer.pUEActor:K2_SetActorLocation(location)
    end
    HumanVehicleHelper.ClearVehicle(GamePlayer, false, true)
end

function HumanVehicleHelper.IsSwimmingVolume(nRegionType)
    if nRegionType ==EPiratesGridRegionType.Ocean or nRegionType ==EPiratesGridRegionType.Port or nRegionType ==EPiratesGridRegionType.Lake then
        return true
    end
    return false
end

function HumanVehicleHelper.DisableOnVehicleAutoRot(GamePlayer)
    DisableOnVehicleAutoRot(GamePlayer)
end

return HumanVehicleHelper