local luaclass = require("luaclass")
local HumanVehicleComponent = require("HumanVehicleComponent") 
local HumanVehicleComponent_C = luaclass("HumanVehicleComponent_C", HumanVehicleComponent)

local HumanWeaponStateDef = require("HumanWeaponStateDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local ClientEventDef = require("ClientEventDef")
-- local VehicleDataTable = require("VehicleDataTable")
local HumanMovementStateType = require("HumanMovementStateType")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")

local HumanVehicleHelper = require("HumanVehicleHelper")
local SelfAnimationHelper = require("SelfAnimationHelper")
local Timer = require("Timer")
local CameraGameHelper = require("CameraGameHelper")
local AnimDef = require("AnimDef")

local VEHICLE_TIMER = "VehicleTimer_C"

-- luacheck: push ignore

local tbENetRoleToString = {
    [ENetRole.ROLE_AutonomousProxy] = "ROLE_AutonomousProxy",
    [ENetRole.ROLE_SimulatedProxy] = "ROLE_SimulatedProxy",
    [ENetRole.ROLE_None] = "ROLE_None",
}

local function LOG_VEHICLE_STATE(self, ...)
    local nState = self:GetVehicleState()
    log("[Vehicle] [HumanVehicleComponent_C] OnVehicleState", nState, ...)
end

-- luacheck: pop

local function RequestVehicleState(self, nState, vehicle_id, end_pos)
    local GamePlayer = self.Owner
    if GamePlayer.ObjectType ~= GameObjectTypeDef.PlayerSelf then  
        return 
    end 
    HumanVehicleHelper.RequestVehicleState(nState, vehicle_id, end_pos)
end

local function ResetUseGesture(self, bAttach, GamePlayer)
    local tbSettingOperationMode = SettingSystemNew:GetInstance(SettingClassType.Setting_OperationMode)
    local nOperationMode = tbSettingOperationMode:GetVehicleOperationMode()
    if nOperationMode ~= tbSettingOperationMode.ModeDef.WithJoystick and GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf and GamePlayer.pUEActor then 
        local PlayerInputComponent = GamePlayer.pUEActor.PlayerInputComponent
        PlayerInputComponent.UseGesture = not bAttach
        PlayerInputComponent:ResetMoveDelta()
    end
end

-- 播rootmotion时该关的关
local function SetDuringRootmotion(self, GamePlayer, pUEActor, bStartRootmotion)
    pUEActor.Mesh.bPauseAnims = false
    if bStartRootmotion then
        if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
            pUEActor.PlayerInputComponent:SetMoveEnabled(false)
        end
        --[[
            Role_Autonomous的客户端播放RootMotion时会同步时间戳, 用当前时间减去最后一个SavedMoves中的时间戳作为DeltaTime. 
            关掉同步后ClientData不再更新, 会一直用当前时间减去关掉同步之前的时间作为DeltaTime, 导致DeltaTime越来越大, RootMotion播放速度出错. 
        ]]
        pUEActor.CharacterMovement:ClearAllSavedMoves()
        pUEActor.CharacterMovement:SetMovementMode(EMovementMode.MOVE_Flying, 0)
    else
        if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
            pUEActor.PlayerInputComponent:SetMoveEnabled(true)
        end
        pUEActor.CharacterMovement:SetMovementMode(EMovementMode.MOVE_Walking, 0)
        pUEActor:StopAnimMontage(nil)
        pUEActor.CharacterMovement.bWasSimulatingRootMotion = false
    end
end

---------------------------------------------------------------------

function HumanVehicleComponent_C:OnPreAttach(tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    local bSuccess = HumanVehicleComponent_C.super.OnPreAttach(self, tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    if not bSuccess then
        return false
    end

    --必须放在这里， 执行到下面 playHumanAnimation的时候会影响镜头朝向的获取
    HumanVehicleHelper.ChangeVehicleCamera(GamePlayer, nVehicleInstanceId, true)
    SetDuringRootmotion(self, GamePlayer, pUEActor, true)
    pUEActor.CapsuleComponent:SetCollisionEnabled(ECollisionEnabled.NoCollision)

    -- 设置上马位置
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    local location = tbVehicle.pUEActor:GetAttachLocation(tbVehicleState.vehicle_trigger_type)
    pUEActor:K2_SetActorLocation(location, true, true)
    LOG_VEHICLE_STATE(self, "Human SetActorLocation", location.X, location.Y, location.Z)
    destroyUserData(location)

    -- 设置上马转向
    local rotation = tbVehicle.pUEActor:K2_GetActorRotation()
    local pMeshRot = tbVehicle.pUEActor.Mesh:K2_GetComponentRotation()
    rotation.Pitch = pMeshRot.Pitch
    pUEActor:K2_SetActorRotation(rotation)
    pUEActor:ResetMeshRotationAndLocation()
    destroyUserData(rotation)
    destroyUserData(pMeshRot)

    -- 播放上马动画
    pUEActor:StopAnimMontage(nil)
    local szAnimKey = tbVehicleState.vehicle_trigger_type == 1 and SelfAnimationHelper.AnimDef.IN_VEHICLE_LEFT or SelfAnimationHelper.AnimDef.IN_VEHICLE_RIGHT
    local nMountCoefficient = GamePlayer.HumanBattlePropertyComponent:GetMountCoefficient()
    local _bRet, nTimer, _pMontage = SelfAnimationHelper:PlayHumanAnimation(GamePlayer, szAnimKey, nMountCoefficient)
    Timer.StartOwnerTimer(self, VEHICLE_TIMER, function() 
        if self:GetVehicleState() ~= HumanVehicleStateDef.PreAttachToVehicle then
            return
        end
        pUEActor.Mesh.bPauseAnims = true
        pUEActor.CharacterMovement:SetComponentTickEnabled(false)
    end, nTimer)
    return true
end

function HumanVehicleComponent_C:OnAttach(tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    SetDuringRootmotion(self, GamePlayer, pUEActor, false)
    pUEActor.CapsuleComponent:SetCollisionEnabled(ECollisionEnabled.QueryAndPhysics)
    pUEActor.Mesh.bPauseAnims = false

    local bSuccess = HumanVehicleComponent_C.super.OnAttach(self, tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    if not bSuccess then
        return false
    end

    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)

    if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        ResetUseGesture(self, true, GamePlayer)
        tbVehicle.pUEActor.CharacterMovement:ResetNetworkSmoothingComplete()
        HumanVehicleHelper.ChangeVehicleCamera(GamePlayer, nVehicleInstanceId ,true)
        CameraGameHelper.NotifyAutoRot()
    end

    local ActorLocation = pUEActor:K2_GetActorLocation()
    local MeshLocation = pUEActor.Mesh:K2_GetComponentLocation()
    local VehicleLocation = tbVehicle:GetLocation()
    LOG_VEHICLE_STATE(self, "ActorLocation (", ActorLocation.X, ActorLocation.Y, ActorLocation.Z, 
                    "), MeshLocation (", MeshLocation.X, MeshLocation.Y, MeshLocation.Z, 
                    "), VehicleLocation (", VehicleLocation.X, VehicleLocation.Y, VehicleLocation.Z, ").")
    return true
end

function HumanVehicleComponent_C:OnPreDetach(tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    pUEActor.Mesh.bPauseAnims = false
    local bSuccess = HumanVehicleComponent_C.super.OnPreDetach(self, tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    if not bSuccess then
        return false
    end

    SetDuringRootmotion(self, GamePlayer, pUEActor, true)
    local CharacterMovement = pUEActor.CharacterMovement
    --[[
        上马后会关掉人的Tick, 如果此时人的Role已经是ROLE_Simulated, bNetworkSmoothingComplete可能还为false. 
        下马时, 人的Tick打开，如果此时人的Role还是ROLE_Simulated, 会在Tick时继续走上马前未完成的SmoothClientPosition, 导致下马过程中位置/方向出错
    ]]
    CharacterMovement:ResetNetworkSmoothingComplete()

    --[[
        上马时人从ROLE_Autonomous切换成ROLE_Simulated时, 会变更仅ROLE_Simulated用的ReplicatedMovementMode. 
        将同步打开后, ACharacter::PostNetReceive()中会检测到ReplicatedMovementMode的变化, 并将bNetworkMovementModeChanged设置为true, 以标记在之后的UCharacterMovementComponent::SimulatedTick中进行处理.
        此时关掉人的Tick, SimulatedTick不会对ReplicatedMovementMode的变化进行处理, 导致这个值一直是true.
        下马时, 人的Tick打开, SimulatedTick判断MovementMode刚刚发生变化, 会根据ReplicatedMovementMode进行Physics计算. 
        此时客户端将MovementMode设置为MOVE_Flying, 但是服务器一直是MOVE_Walking, ReplicatedMovementMode也是MOVE_Walking, 会计算一帧物理下落, 导致下马动画位置出错.
        这里强制将bNetworkMovementModeChanged设置为false, 以解决这个问题.
    ]]
    CharacterMovement:ResetNetworkMovementModeChanged()
    CharacterMovement:DiscardPendingMove()

    local nMountCoefficient = GamePlayer.HumanBattlePropertyComponent:GetMountCoefficient()
    SelfAnimationHelper:PlayHumanAnimation(GamePlayer, AnimDef.LEAVE_VEHICLE, nMountCoefficient)

    local ActorLocation = pUEActor:K2_GetActorLocation()
    local MeshLocation = pUEActor.Mesh:K2_GetComponentLocation()
    LOG_VEHICLE_STATE(self, "ActorLocation (", ActorLocation.X, ActorLocation.Y, ActorLocation.Z, 
                    "), MeshLocation (", MeshLocation.X, MeshLocation.Y, MeshLocation.Z, ").")

    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    if tbVehicle then
        local VehicleLocation = tbVehicle:GetLocation()
        LOG_VEHICLE_STATE(self, "VehicleLocation (", VehicleLocation.X, VehicleLocation.Y, VehicleLocation.Z, ")")
    end

    return true
end

function HumanVehicleComponent_C:OnNone(tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    SetDuringRootmotion(self, GamePlayer, pUEActor, false)
    pUEActor.CapsuleComponent:SetCollisionEnabled(ECollisionEnabled.QueryAndPhysics)
    pUEActor:StopAnimMontage(nil)

    local bSuccess = HumanVehicleComponent_C.super.OnNone(self, tbVehicleState, bForce, GamePlayer, pUEActor, nVehicleInstanceId)
    if not bSuccess then
        return false
    end
    
    if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        --禁止 载具上自动回正
        HumanVehicleHelper.DisableOnVehicleAutoRot(GamePlayer)
        HumanVehicleHelper.ChangeVehicleCamera(GamePlayer, nVehicleInstanceId, false)
        ResetUseGesture(self, false, GamePlayer)
    end

    if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        local pRole = pUEActor.Role
        if pRole and pRole ~= ENetRole.ROLE_AutonomousProxy then
            LOG_VEHICLE_STATE(self, "Human local role is", tbENetRoleToString[pRole])
            pUEActor.CharacterMovement:VerifyLocalRole()
        end
        
        local ActorLocation = pUEActor:K2_GetActorLocation()
        local MeshLocation = pUEActor.Mesh:K2_GetComponentLocation()
        LOG_VEHICLE_STATE(self, "ActorLocation (", ActorLocation.X, ActorLocation.Y, ActorLocation.Z, 
                        "), MeshLocation (", MeshLocation.X, MeshLocation.Y, MeshLocation.Z, ").")

        if GamePlayer.HumanMovementStateComponent and GamePlayer.HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.UpRight_State then
            local SaveWeapon = BattleHumanWeaponSystemNew:GetSavedCurrentWeaponFromOwner(GamePlayer)
            if SaveWeapon ~= 0 then 
                -- 切一下状态以拿出武器
                BattleHumanWeaponSystemNew:GetComponent(GamePlayer):ChangeState(HumanWeaponStateDef.UNHOLDED, true)
            end
        end
    end

    return true
end

function HumanVehicleComponent_C:SetVehicleState(nState, vehicle_id, nVehicleTriggerType)
    if GlobalVariableSystem:IsServerLogic() then
        -- 单机本
        HumanVehicleComponent_C.super.SetVehicleState(self, nState, vehicle_id, nVehicleTriggerType)
    else
        RequestVehicleState(self, nState, vehicle_id)
    end
end

function HumanVehicleComponent_C:OnRequestVehicleFailed(nReason)
    self.EventHelper:FireEvent(ClientEventDef.EV_ON_REQUEST_VEHICLE_FAILED)
end


return HumanVehicleComponent_C