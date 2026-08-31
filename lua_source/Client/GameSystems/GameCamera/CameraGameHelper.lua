local CameraGameHelper = {}

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameCameraSystem = require("GameCameraSystem")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local GameCameraModeDef = require("GameCameraModeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CameraIni = require("CameraIni")
local HumanMovementStateType = require("HumanMovementStateType")

local StateType = HumanMovementStateType

local HomelandSystem
local HomelandCameraSystem

local TEMP_ROTATION = Rotator()

function CameraGameHelper.GetCameraSystem()
    if GlobalVariableSystem:IsInDungeon() then
        return GameCameraSystem
    end
    if not HomelandSystem then
        HomelandSystem = require("HomelandSystem")
        HomelandCameraSystem = require("HomeLandCameraSystem")
    end

    if HomelandSystem:IsInHomeland() then
        return HomelandCameraSystem
    end
    return nil
end

function CameraGameHelper.GetCameraManager()
    return GameplayStatics.GetPlayerCameraManager(GWorld, 0)
end

function CameraGameHelper.GetArm()
    local GameCameraManager = CameraGameHelper.GetCameraManager()
    local CameraActor = GameCameraManager:GetPlayerCameraActor()
    return CameraActor:GetSpringArm()
end

function CameraGameHelper.IsWatchBattleMode()
    local CMSystem = CameraGameHelper.GetCameraSystem()
    if CMSystem then 
        local nGroupDef = GameCameraModeGroupDef
        return CMSystem:IsCameraLogicActive(nGroupDef.ViewTeammateShip) 
                or CMSystem:IsCameraLogicActive(nGroupDef.ViewTeammateHuman)
    end
    return false
end

function CameraGameHelper.IsShipAiming()
    local CMSystem = CameraGameHelper.GetCameraSystem()
    if CMSystem then 
        local nGroupDef = GameCameraModeGroupDef
        return CMSystem:IsCameraLogicActive(nGroupDef.ShipAiming) 
    end
    return false
end

function CameraGameHelper.SetLockLeftScroll(bLock)
    local CameraManager = CameraGameHelper.GetCameraManager()
    if CameraManager then 
        CameraManager.LockLeft = bLock
    end
end

function CameraGameHelper.SetLockRightScroll(bLock)
    local CameraManager = CameraGameHelper.GetCameraManager()
    if CameraManager then 
        CameraManager.LockRight = bLock
    end
end

function CameraGameHelper.SetLockUpScroll(bLock)
    local CameraManager = CameraGameHelper.GetCameraManager()
    if CameraManager then 
        CameraManager.LockUp = bLock
    end
end

function CameraGameHelper.SetLockDownScroll(bLock)
    local CameraManager = CameraGameHelper.GetCameraManager()
    if CameraManager then 
        CameraManager.LockDown = bLock
    end
end

function CameraGameHelper.SetLockCameraScroll(bLock)
    local CameraManager = CameraGameHelper.GetCameraManager()
    if CameraManager then 
        CameraManager.LockMoveInput = bLock
    end
end

function CameraGameHelper.StopCameraShake()
    local CMSystem = CameraGameHelper.GetCameraSystem()
    CMSystem:DeactiveMode(GameCameraModeDef.ModeShake)
end


function CameraGameHelper.RotateToTarget(TargetLocation, nTime)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local CameraManager = CameraGameHelper.GetCameraManager()
    if CameraManager then 
        if PlayerSelf:IsHuman() then
            CameraManager:RotateToTarget(TargetLocation, nTime, false)
        else  
            CameraManager:RotateToTarget(TargetLocation, nTime, true)
        end
    end
end

function CameraGameHelper.ShiftToTarget( pTargetActor, nShiftToTime, nStayTime, nShiftBackTime)
    local CameraManager = CameraGameHelper.GetCameraManager()
    if CameraManager then 
        CameraManager:ShiftToTarget(pTargetActor, nShiftToTime, nStayTime, nShiftBackTime)
    end
end

--给胜利者添加转到正前方视角, 等后续抽到表里先这样
function CameraGameHelper.RotateToTargetFront(tbPlayer)
    local pArm = CameraGameHelper.GetArm()
    local tbWinCameraCfg = CameraIni.tbWinCameraConfig
    local CameraManager = CameraGameHelper.GetCameraManager()
    if tbPlayer:IsHuman() then  
        local pActorRot = tbPlayer.pUEActor:K2_GetActorRotation()
        local pForwardV = KismetMathLibrary.GetForwardVector(pActorRot)
        local pRightV = KismetMathLibrary.GetRightVector(pActorRot)
        --180:前 0：后 90：左 270：右
        local DirectionYaws = {180, 0, 90, 270}
        local DirectionVec = {
            pForwardV,
            KismetMathLibrary.Multiply_VectorFloat(pForwardV, -1),
            KismetMathLibrary.Multiply_VectorFloat(pRightV, -1),
            pRightV,
        }

        local bFindUnblockDirection = false
        for idx, v in ipairs(DirectionYaws) do  
            local pStart = tbPlayer.pUEActor:K2_GetActorLocation()
            local pEnd = KismetMathLibrary.Multiply_VectorFloat(DirectionVec[idx], tbWinCameraCfg.nHumanArmLen)
            pEnd = KismetMathLibrary.Add_VectorVector(pStart , pEnd)
            local bRet = CameraManager:IsBlockInDirection(pStart, pEnd)
            if not bRet then  
                pArm:K2_SetRelativeRotation(Rotator{Pitch = tbWinCameraCfg.nHumanArmPitch, Yaw = v, Roll = 0})
                bFindUnblockDirection = true
                break
            end
        end
        if not bFindUnblockDirection then  
            pArm:K2_SetRelativeRotation(Rotator{Pitch = tbWinCameraCfg.nHumanArmPitch, Yaw = tbWinCameraCfg.nHumanArmYaw, Roll = 0})
        end
        pArm.bDoCollisionTest = false
        pArm.TargetArmLength = tbWinCameraCfg.nHumanArmLen
    elseif tbPlayer:IsShip() then  
        
        local CameraActor = CameraManager:GetPlayerCameraActor()
        local nShipYaw = tbPlayer.pUEActor:K2_GetActorRotation().Yaw
        CameraActor:K2_SetActorRotation(Rotator{Pitch = 0,Yaw = nShipYaw, Roll = 0})
        pArm:K2_SetRelativeRotation(Rotator{Pitch = tbWinCameraCfg.nShipArmPitch, Yaw = tbWinCameraCfg.nShipArmYaw, Roll = 0})
        pArm.TargetArmLength = tbWinCameraCfg.nShipArmLen
        pArm.SocketOffset = Vector{X = 0, Y = 0, Z = 0}
    end
end

function CameraGameHelper.RotateToYaw(tbPlayer, nTargetYaw)
    local CameraManager = CameraGameHelper.GetCameraManager()
    local pArm = CameraGameHelper.GetArm()
    if tbPlayer:IsHuman() then  
        local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
        pPlayerController:SetControlRotation(Rotator{Pitch = 0, Yaw = nTargetYaw, Roll = 0})
    elseif tbPlayer:IsShip() then  
        -- local ActorYaw = tbPlayer.pUEActor:K2_GetActorRotation().Yaw
        -- logdebug("rot before :", ActorYaw, nTargetYaw)
        local CameraActor = CameraManager:GetPlayerCameraActor()
        CameraActor:K2_SetActorRotation(Rotator{Pitch = 0,Yaw = nTargetYaw, Roll = 0})
        pArm:K2_SetRelativeRotation(Rotator{Pitch = 0, Yaw = 0, Roll = 0})
    end
end

function CameraGameHelper.SetGyroEnable(bEnable)
    local CameraManager = CameraGameHelper.GetCameraManager()
    CameraManager.EnableGyro = bEnable
end

function CameraGameHelper.EnableCameraLocationLag(bEnable, nTime, nLagSpeed)
    local pArm = CameraGameHelper.GetArm()
    pArm:EnableCameraLocationLagWithTimeAndSpeed(bEnable, nTime, nLagSpeed)
end

function CameraGameHelper.SetOnVehicleAutoRotateFollowFlags( bEnableFollow)
    local CameraManager = CameraGameHelper.GetCameraManager()
    CameraManager:EnableAutoRot(bEnableFollow)
    if bEnableFollow then   
        CameraManager.AutoRotInterp = CameraIni.nFollowInterp
        CameraManager.AutoConditionStartSpeed = CameraIni.nFollowStartSpeed
        CameraManager.AutoEffectMinYaw = CameraIni.nActiveMinYaw
        CameraManager.AutoTriggerTime = CameraIni.nFollowTriggerTime
        CameraManager.AutoRotPich = 0
    end
end

function CameraGameHelper.NotifyAutoRot()
    local CameraManager = CameraGameHelper.GetCameraManager()
    CameraManager:NotifyAutoRot()
end

function CameraGameHelper.PlayCameraShake(szShakeClassPath)
    local pShakeClass = szShakeClassPath:load()
    if pShakeClass then
        local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
        if pCameraManager then
            pCameraManager:PlayCameraShakeInstance(pShakeClass, 1.0, ECameraAnimPlaySpace.CameraLocal, TEMP_ROTATION)
        end
    end
end

---------------------------------movement ---------------------------------
function CameraGameHelper.IsNeedMovementBlend(nLastMovementState, nCurrentMovementState)
    local bIsCurrentBlendState = nCurrentMovementState == StateType.Crouch_State or nCurrentMovementState == StateType.Crawl_State 
        or nCurrentMovementState == StateType.Dying_State
    local bIsRecoverFromBlendState = nLastMovementState == StateType.Crouch_State or nLastMovementState == StateType.Crawl_State
    local bCurrentUpright = nCurrentMovementState == StateType.UpRight_State

    if bCurrentUpright and bIsRecoverFromBlendState then 
        return true
    end
    if bIsCurrentBlendState then 
        return true
    end
    return false
end

return CameraGameHelper