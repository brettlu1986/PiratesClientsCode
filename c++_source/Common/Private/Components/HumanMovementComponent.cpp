#include "Components/HumanMovementComponent.h"
#include "Common.h"
#include "Pawns/PiratesHumanCharacter.h"
#include "Game/GameCommon.h"
#include "GameFramework/GameNetworkManager.h"
#include "Game/Delegates/PiratesMovementDelegate.h"
#include "Net/UnrealNetwork.h"
#include "Shell/CommonShell.h"
#include "Game/Delegates/GameDelegateManager.h"
#include "Kismet/KismetMathLibrary.h"

DEFINE_LOG_CATEGORY_STATIC(LogHumanMovement, Log, All);
DEFINE_LOG_CATEGORY_STATIC(LogHumanMovementSmooth, Log, All);


static float StuckWarningPeriod = 1.f;
FAutoConsoleVariableRef CVarHumanStuckWarningPeriod(
    TEXT("p.HumanStuckWarningPeriod"),
    StuckWarningPeriod,
    TEXT("How often (in seconds) we are allowed to log a message about being stuck in geometry.\n")
    TEXT("<0: Disable, >=0: Enable and log this often, in seconds."),
    ECVF_Default);

int32 CVar_HumanMovementSmoothMode = 1;
static FAutoConsoleVariableRef CVarHumanMovementSmoothMode(TEXT("HumanMovement.SmoothMode"), CVar_HumanMovementSmoothMode, TEXT(""), ECVF_Default);

// int32 CVar_HumanMovementLog = 0;
// static FAutoConsoleVariableRef CVarHumanMovementLog(TEXT("HumanMovement.Log"), CVar_HumanMovementLog, TEXT(""), ECVF_Default);


UHumanMovementComponent::UHumanMovementComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
    , CollisionCheckBox(FVector(90, 32, 2))
{
    PrimaryComponentTick.bCanEverTick = true;
    PrimaryComponentTick.bStartWithTickEnabled = false;
    PrimaryComponentTick.TickGroup = TG_PrePhysics;
    bAutoActivate = 0;

    bUpdateNavAgentWithOwnersCollision = true;
    SetIsReplicatedByDefault(true);

    AnalogInputCurrent = 0;
    AnalogInputAlpha = 0;
    AnalogInputCurve = nullptr;
    RootBoneName = FName("root");
}

void UHumanMovementComponent::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
    Super::GetLifetimeReplicatedProps(OutLifetimeProps);
    DOREPLIFETIME_CONDITION(UHumanMovementComponent, HumanJumpMode, COND_SimulatedOnly);
}

void UHumanMovementComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction * ThisTickFunction)
{
    if (!HasValidData())
    {
        return;
    }

    if (IsRootMotionMovement)
    {
        TickRootMotion(DeltaTime);
        ConsumeInputVector();
    }

    //检查InputVector，在位移之前先检查特殊状态的输入
    CheckConsumeInputVector();

    //todo: @lihui rootmotion相关的
    SaveDeltaTime = DeltaTime;

    FVector OldLocation = UpdatedComponent->GetComponentLocation();
    if (IsHumanPathMove())
    {
        // 直接处理寻路的移动
        ProcessPathMove();

        PerformMovement(DeltaTime);
    }
    else
    {
        UKMCharacterMovementComponent::TickComponent(DeltaTime, TickType, ThisTickFunction);
    }

    // 处理人移动的特殊状态
    ProcessHumanMovementState();

    // 处理爬行
    ProcessCrawlMove();

    // 设置是否正在移动
    SetHumanMoveState();

    // 统计移动距离
    SetTotalDistance(OldLocation);

    // 非法移动检测
    CheckMovementIllegal(DeltaTime);

    // 设置地面物理材质
    SetAlongSurfaceType();
}

void UHumanMovementComponent::CheckConsumeInputVector()
{
    if (CharacterOwner->GetLocalRole() == ROLE_AutonomousProxy)
    {
        HandleCrawlHit();
        HandleSwimmingHit();
    }
}

void UHumanMovementComponent::ProcessHumanMovementState()
{
    if (CharacterOwner->GetLocalRole() != ROLE_Authority)
    {
        return;
    }

    // 处理游泳状态的切换
    if (bPerSwimState)
    {
        if (MovementMode == EMovementMode::MOVE_Swimming && bFindSwimFloor)
        {
            SetMovementMode(EMovementMode::MOVE_Walking);
        }
        else if (CheckCanSwim())
        {
            SetMovementMode(EMovementMode::MOVE_Swimming);
            bPerSwimState = false;
        }
    }

    // 处理跳的状态
    if (MovementMode != MOVE_Falling)
    {
        HumanJumpMode = 0;
    }
}

void UHumanMovementComponent::ProcessCrawlMove()
{
    if (IsHumanPathMove())
    {
        return;
    }

    //计算角度，判断是否卧倒锁定
    ComputeHumanMoveAngle();

    //根据地形角度调整Rotation
    AdjustRotationMatchSlope();
}

void UHumanMovementComponent::SetTotalDistance(FVector OldLocation)
{
    if (bStartTotalDistance && CharacterOwner->GetLocalRole() == ROLE_Authority)
    {
        FVector LocDiff = UpdatedComponent->GetComponentLocation() - OldLocation;
        if (LocDiff != FVector::ZeroVector)
        {
            TotalDistance += FMath::Sqrt(LocDiff.SizeSquared());
        }
    }
}

void UHumanMovementComponent::SetAlongSurfaceType()
{
    if ((CharacterOwner->GetLocalRole() == ROLE_AutonomousProxy || CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy) && MOVE_Walking == MovementMode && CurrentFloor.IsWalkableFloor())
    {
        AlongSurfaceType = UPhysicalMaterial::DetermineSurfaceType(CurrentFloor.HitResult.PhysMaterial.Get());
    }
}

void UHumanMovementComponent::CalcFallingVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration)
{
    // Do not update velocity when using root motion or when SimulatedProxy - SimulatedProxy are repped their Velocity
    if (!HasValidData() || HasAnimRootMotion() || DeltaTime < MIN_TICK_TIME || (CharacterOwner && CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy))
    {
        return;
    }

    Friction = FMath::Max(0.f, Friction);
    const float MaxAccel = GetMaxAcceleration();
    float MaxSpeed = GetMaxSpeed();

    const bool bZeroAcceleration = Acceleration.IsZero();
    const bool bVelocityOverMax = IsExceedingMaxSpeed(MaxSpeed);
	const FVector AccelDir = Acceleration.GetSafeNormal();

    if (!bZeroAcceleration)
    {
        // Friction affects our ability to change direction. This is only done for input acceleration, not path following.
        const float VelSize = Velocity.Size();
        Velocity = Velocity - (Velocity - AccelDir * VelSize) * FMath::Min(DeltaTime * Friction, 1.f);
        CurrentFallingLateralAcceleration += HumanFallConfig.LateralAcceleration * DeltaTime;
    }
    else
    {
        CurrentFallingLateralAcceleration = 0;
    }

    // Apply acceleration
    const float NewMaxSpeed = (IsExceedingMaxSpeed(MaxSpeed)) ? Velocity.Size() : MaxSpeed;

    if (!bZeroAcceleration && Velocity.Size() == 0)
    {
        Velocity = AccelDir * HumanFallConfig.DefaultOriginSpeed;
    }

    FVector ActualAcceleration = AccelDir * CurrentFallingLateralAcceleration - Velocity.GetSafeNormal() * HumanFallConfig.AirDragCoefficient;
    Velocity += ActualAcceleration * DeltaTime;
    Velocity = Velocity.GetClampedToMaxSize(NewMaxSpeed);

    if (bUseRVOAvoidance)
    {
        CalcAvoidanceVelocity(DeltaTime);
    }
}

void UHumanMovementComponent::CalcVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration)
{
    // 直接修正为最大输入状态，不需要移动加速的过程
    if (AnalogInputModifier > 0.f)
    {
        AnalogInputModifier = 1.f;
    }

    if (AnalogInputCurve && AnalogInputCurrent != AnalogInputModifier)
    {
        //UE_LOG(LogHumanMovement, Verbose, TEXT("CalcVelocity ****** Name %s AnalogInputAlpha = %f, AnalogInputModifier = %f, AnalogInputCurrent = %f"), *GetNameSafe(CharacterOwner), AnalogInputAlpha, AnalogInputModifier, AnalogInputCurrent);

        if (AnalogInputModifier < AnalogInputCurrent)
        {
            AnalogInputAlpha = AnalogInputAlpha - DeltaTime;
        }
        else
        {
            AnalogInputAlpha = AnalogInputAlpha + DeltaTime;
        }
        float MinTime, MaxTime;
        AnalogInputCurve->GetTimeRange(MinTime, MaxTime);
        AnalogInputAlpha = FMath::Clamp(AnalogInputAlpha, MinTime, MaxTime);
        //UE_LOG(LogHumanMovement, Verbose, TEXT("CalcVelocity ++++++ Name %s AnalogInputAlpha = %f, MinTime = %f, MaxTime = %f"), *GetNameSafe(CharacterOwner),  AnalogInputAlpha, MinTime, MaxTime);
        AnalogInputModifier = AnalogInputCurve->GetFloatValue(AnalogInputAlpha);
        AnalogInputModifier = FMath::Clamp(AnalogInputModifier, 0.0f, 1.0f);
        AnalogInputCurrent = AnalogInputModifier;
        //UE_LOG(LogHumanMovement, Verbose, TEXT("CalcVelocity ------ Name %s AnalogInputCurrent = %f , AnalogInputAlpha = %f, DeltaTime = %f, AnalogInputModifier = %f"), *GetNameSafe(CharacterOwner),  AnalogInputCurrent, AnalogInputAlpha, DeltaTime, AnalogInputModifier);
    }

    // Jump速度的计算
    // todo: @chenyixin 可以把这里重新封装一下
    if (IsFalling() && bUseNewJump)
    {
        bJustTeleported = true;
        FallLandingStunTime = HumanFallConfig.LandStunTime;
        MaxWalkSpeed = CurrentMaxWalkSpeed;
        CalcFallingVelocity(DeltaTime, Friction, bFluid, BrakingDeceleration);
    }
    else
    {
        if (FallLandingStunTime > 0)
        {
            FallLandingStunTime -= DeltaTime;
            CurrentFallingLateralAcceleration = 0;
        }
        else
        {
            FallLandingStunTime = -1;
            MaxWalkSpeed = CurrentMaxWalkSpeed;
        }

        if (IsHumanPathMove())
        {
            this->Velocity = this->Acceleration * GetMaxSpeed();
        }
        else
        {
            UCharacterMovementComponent::CalcVelocity(DeltaTime, Friction, bFluid, BrakingDeceleration);
        }
    }
    if(AnalogInputModifier != 0)
    { 
        UE_LOG(LogHumanMovement, Verbose, TEXT("CalcVelocity ****** Name %s Velocity %s "), *GetNameSafe(CharacterOwner), *Velocity.ToString());
    }

}

FVector UHumanMovementComponent::NewFallVelocity(const FVector& InitialVelocity, const FVector& Gravity, float DeltaTime) const
{
    if (!bUseHumanFallingTerminalVelocity)
    {
        return UCharacterMovementComponent::NewFallVelocity(InitialVelocity, Gravity, DeltaTime);
    }

    // 处理simulate客户端在跳伞时，不同状态下的速度
    FVector Result = InitialVelocity;
    if (DeltaTime > 0.f)
    {
        const float TerminalLimit = -FMath::Abs(FallingTerminalVelocity);
        if (bFallingDeceleration)
        {
            Result -= Gravity * DeltaTime;
            if (Result.Z > TerminalLimit)
            {
                Result.Z = TerminalLimit;
                bFallingDeceleration = false;
            }
        }
        else
        {
            Result += Gravity * DeltaTime;
            if (Result.Z < TerminalLimit)
            {
                Result.Z = TerminalLimit;
            }
        }
    }

    return Result;
}

void UHumanMovementComponent::MoveSmooth(const FVector& InVelocity, const float DeltaSeconds, FStepDownResult* OutStepDownResult)
{
    if (!UsePiratesSmoothMode())
    {
        UCharacterMovementComponent::MoveSmooth(InVelocity, DeltaSeconds, OutStepDownResult);
        return;
    }

    float deltaTime = DeltaSeconds;
    FVector thisVelocity = InVelocity;
    if (MovementMode == MOVE_Falling)
    {
        if (deltaTime > SmoothMoveMaxDeltaTime)
        {
            deltaTime = SmoothMoveMaxDeltaTime;
        }

        //处理跳伞下落的速度
        if (FallingTerminalVelocity > 0.f && SmoothCorrectionDeltaZ > FallingTerminalVelocity * SmoothMoveMaxDeltaTime)
        {
            thisVelocity.Z = InVelocity.Z / 2.f;
        }
    }
    else
    {
        if (deltaTime > (SmoothMoveMaxDeltaTime / 3.f))
        {
            deltaTime = SmoothMoveMaxDeltaTime / 3.f;
        }

        //处理下个数据包没到之前，因为修改最大速度导致的位移差
        if (MovementMode == MOVE_Walking && !Velocity.IsNearlyZero() && MaxWalkSpeed != 0.f)
        {
            float VelRate = MaxWalkSpeed / FMath::Sqrt(Velocity.SizeSquared());
            thisVelocity = InVelocity * VelRate;
        }
    }
    UCharacterMovementComponent::MoveSmooth(thisVelocity, deltaTime, OutStepDownResult);
}


//TODO:@liujifang 需要梳理一下同步修正算法
void UHumanMovementComponent::SmoothCorrection(const FVector& OldLocation, const FQuat& OldRotation, const FVector& NewLocation, const FQuat& NewRotation)
{
    if (MovementMode == MOVE_Falling && CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy && !Velocity.IsNearlyZero() && !Acceleration.IsNearlyZero())
    {
        float currentTime = GetWorld()->GetTimeSeconds();
        float deltaTime = currentTime - SmoothCorrectionTimestamp;
        if (deltaTime < SmoothMoveMaxDeltaTime * 2)
        {
            return;
        }
        SmoothCorrectionDirection = NewLocation;
        SmoothCorrectionDeltaZ = NewLocation.Z - OldLocation.Z;
        float maxFallVelocityZ = FallingTerminalVelocity * SmoothMoveMaxDeltaTime * 4;
        FVector newLocation = NewLocation;
        if (SmoothCorrectionDeltaZ > 0.f && SmoothCorrectionDeltaZ < maxFallVelocityZ)
        {
            newLocation.Z = OldLocation.Z;
        }

        UCharacterMovementComponent::SmoothCorrection(OldLocation, OldRotation, newLocation, NewRotation);
        return;
    }

    if (!HasValidData())
    {
        return;
    }

    // We shouldn't be running this on a server that is not a listen server.
    if (GetNetMode() == NM_DedicatedServer || GetNetMode() == NM_Standalone)
    {
        return;
    }
    //     checkSlow(GetNetMode() != NM_DedicatedServer);
    //     checkSlow(GetNetMode() != NM_Standalone);

        // Only client proxies or remote clients on a listen server should run this code.
    const bool bIsSimulatedProxy = (CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy);
    const bool bIsRemoteAutoProxy = (CharacterOwner->GetRemoteRole() == ROLE_AutonomousProxy);
    ensure(bIsSimulatedProxy || bIsRemoteAutoProxy);

    // Getting a correction means new data, so smoothing needs to run.
    bNetworkSmoothingComplete = false;

    //如果当前已经被客户端裁剪，看不到模型了，就直接设置location和Rotation
    if (!CharacterOwner->WasRecentlyRendered())
    {
        UE_LOG(LogHumanMovementSmooth, VeryVerbose, TEXT("%s is SetWorldLocationAndRotation, vel=%s"), *CharacterOwner->GetName(), *Velocity.ToString());
        UpdatedComponent->SetWorldLocationAndRotation(NewLocation, NewRotation, false, nullptr, ETeleportType::TeleportPhysics);
        bNetworkSmoothingComplete = true;
        return;
    }

    if (!UsePiratesSmoothMode())
    {
        UCharacterMovementComponent::SmoothCorrection(OldLocation, OldRotation, NewLocation, NewRotation);
        return;
    }

    // Handle selected smoothing mode.
    if (NetworkSmoothingMode == ENetworkSmoothingMode::Replay)
    {
        // Replays use pure interpolation in this mode, all of the work is done in SmoothClientPosition_Interpolate
        return;
    }
    else if (NetworkSmoothingMode == ENetworkSmoothingMode::Disabled)
    {
        UpdatedComponent->SetWorldLocationAndRotation(NewLocation, NewRotation, false, nullptr, ETeleportType::TeleportPhysics);
        bNetworkSmoothingComplete = true;
    }
    else if (FNetworkPredictionData_Client_Character* ClientData = GetPredictionData_Client_Character())
    {
        const UWorld* MyWorld = GetWorld();
        if (!ensure(MyWorld != nullptr))
        {
            return;
        }

        //把直接插值，替换成不同情况下的插值，避免一次插值出现瞬移的情况
        FVector InterpLocation = OldLocation;
        FVector NewToOldVector = (OldLocation - NewLocation);
        bool bForceCorrection = true;
        if (!CharacterOwner->GetReplicatedBasedMovement().IsBaseUnresolved())
        {
            SmoothCorrectionDirection = NewLocation;
            float NewDistSq = NewToOldVector.SizeSquared();
            bForceCorrection = false;
            float MaxSmoothMoveTime = 1.f / GEngine->GetMaxFPS();
            float MaxInterpSpeed = 800.f;
            if (NewDistSq < 40000.f)
            {
                InterpLocation = FMath::VInterpTo(OldLocation, NewLocation, MaxSmoothMoveTime, MaxInterpSpeed);
                UE_LOG(LogHumanMovement, Verbose, TEXT("/// %s SmoothCorrection linear interp 1 dis=(%.2f), vel=%s"), *GetNameSafe(CharacterOwner), FMath::Sqrt(NewDistSq), *Velocity.ToString());
            }
            else if (NewDistSq >= 40000.f && NewDistSq < 160000.f)
            {
                InterpLocation = FMath::VInterpTo(OldLocation, NewLocation, MaxSmoothMoveTime, MaxInterpSpeed * 1.5f);
                UE_LOG(LogHumanMovement, Verbose, TEXT("/// %s SmoothCorrection linear interp 2 dis=(%.2f), vel=%s"), *GetNameSafe(CharacterOwner), FMath::Sqrt(NewDistSq), *Velocity.ToString());
            }
            else if (NewDistSq >= 160000.f)
            {
                //InterpLocation = NewLocation;
                InterpLocation = FMath::VInterpTo(OldLocation, NewLocation, MaxSmoothMoveTime, MaxInterpSpeed * 3.f);
                bForceCorrection = true;
                SmoothCorrectionDirection = FVector::ZeroVector;
                UE_LOG(LogHumanMovement, Verbose, TEXT("/// %s SmoothCorrection linear interp 3 dis=(%.2f), vel=%s"), *GetNameSafe(CharacterOwner), FMath::Sqrt(NewDistSq), *Velocity.ToString());
            }
            else
            {
                UE_LOG(LogHumanMovement, Verbose, TEXT("/// %s SmoothCorrection linear no interp dis=(%.2f), vel=%s, loc=%s, time=%f, speed=%f, newdis=(%.2f)"), *GetNameSafe(CharacterOwner), FMath::Sqrt(NewDistSq), *Velocity.ToString(), *NewLocation.ToString());
            }
            NewToOldVector = (OldLocation - InterpLocation);
        }
        else
        {
            InterpLocation = NewLocation;
            SmoothCorrectionDirection = FVector::ZeroVector;
        }

        // The mesh doesn't move, but the capsule does so we have a new offset.
        if (bIsNavWalkingOnServer && FMath::Abs(NewToOldVector.Z) < NavWalkingFloorDistTolerance)
        {
            // ignore smoothing on Z axis
            // don't modify new location (local simulation result), since it's probably more accurate than server data
            // and shouldn't matter as long as difference is relatively small
            NewToOldVector.Z = 0;
        }

        const float DistSq = NewToOldVector.SizeSquared();
        if (DistSq > FMath::Square(ClientData->MaxSmoothNetUpdateDist))
        {
            ClientData->MeshTranslationOffset = (DistSq > FMath::Square(ClientData->NoSmoothNetUpdateDist))
                ? FVector::ZeroVector
                : ClientData->MeshTranslationOffset + ClientData->MaxSmoothNetUpdateDist * NewToOldVector.GetSafeNormal();

        }
        else
        {
            ClientData->MeshTranslationOffset = ClientData->MeshTranslationOffset + NewToOldVector;
        }

        UE_LOG(LogHumanMovement, VeryVerbose, TEXT("Proxy %s SmoothCorrection(%.2f)"), *GetNameSafe(CharacterOwner), FMath::Sqrt(DistSq));
        if (NetworkSmoothingMode == ENetworkSmoothingMode::Linear)
        {
            ClientData->OriginalMeshTranslationOffset = ClientData->MeshTranslationOffset;

            // Remember the current and target rotation, we're going to lerp between them
            ClientData->OriginalMeshRotationOffset = OldRotation;
            ClientData->MeshRotationOffset = OldRotation;
            ClientData->MeshRotationTarget = NewRotation;

            // Move the capsule, but not the mesh.
            // Note: we don't change rotation, we lerp towards it in SmoothClientPosition.
            if (InterpLocation != OldLocation && (bForceCorrection || (Acceleration != FVector::ZeroVector && Velocity != FVector::ZeroVector)))
            {
                const FScopedPreventAttachedComponentMove PreventMeshMove(CharacterOwner->GetMesh());
                auto moveloc = (InterpLocation - OldLocation).SizeSquared();
                UpdatedComponent->SetWorldLocation(InterpLocation, false, nullptr, GetTeleportType());
                if (moveloc >= 10000.f)
                {
                    UE_LOG(LogHumanMovement, Log, TEXT("%s SmoothCorrection set location dis=(%.2f), vel=%s, loc=%s, ct=%f, st=%f, lastdt=%f"), *GetNameSafe(CharacterOwner), FMath::Sqrt(moveloc), 
                        *Velocity.ToString(), *OldLocation.ToString(), ClientData->SmoothingClientTimeStamp, ClientData->SmoothingServerTimeStamp, ClientData->LastCorrectionTime, (MyWorld->GetTimeSeconds() - ClientData->LastCorrectionTime));
                }
            }
        }
        else
        {
            // Calc rotation needed to keep current world rotation after UpdatedComponent moves.
            // Take difference between where we were rotated before, and where we're going
            ClientData->MeshRotationOffset = (NewRotation.Inverse() * OldRotation) * ClientData->MeshRotationOffset;
            ClientData->MeshRotationTarget = FQuat::Identity;

            const FScopedPreventAttachedComponentMove PreventMeshMove(CharacterOwner->GetMesh());
            UpdatedComponent->SetWorldLocationAndRotation(NewLocation, NewRotation, false, nullptr, GetTeleportType());
        }

        //////////////////////////////////////////////////////////////////////////
        // Update smoothing timestamps

        // If running ahead, pull back slightly. This will cause the next delta to seem slightly longer, and cause us to lerp to it slightly slower.
        if (ClientData->SmoothingClientTimeStamp > ClientData->SmoothingServerTimeStamp)
        {
            const double OldClientTimeStamp = ClientData->SmoothingClientTimeStamp;
            ClientData->SmoothingClientTimeStamp = FMath::LerpStable(ClientData->SmoothingServerTimeStamp, OldClientTimeStamp, 0.5);

            UE_LOG(LogHumanMovement, VeryVerbose, TEXT("SmoothCorrection: Pull back client from ClientTimeStamp: %.6f to %.6f, ServerTimeStamp: %.6f for %s"),
                OldClientTimeStamp, ClientData->SmoothingClientTimeStamp, ClientData->SmoothingServerTimeStamp, *GetNameSafe(CharacterOwner));
        }

        // Using server timestamp lets us know how much time actually elapsed, regardless of packet lag variance.
        double OldServerTimeStamp = ClientData->SmoothingServerTimeStamp;
        if (bIsSimulatedProxy)
        {
            // This value is normally only updated on the server, however some code paths might try to read it instead of the replicated value so copy it for proxies as well.
            ServerLastTransformUpdateTimeStamp = CharacterOwner->GetReplicatedServerLastTransformUpdateTimeStamp();
        }
        ClientData->SmoothingServerTimeStamp = ServerLastTransformUpdateTimeStamp;

        // Initial update has no delta.
        if (ClientData->LastCorrectionTime == 0)
        {
            ClientData->SmoothingClientTimeStamp = ClientData->SmoothingServerTimeStamp;
            OldServerTimeStamp = ClientData->SmoothingServerTimeStamp;
        }

        // Don't let the client fall too far behind or run ahead of new server time.
        const double ServerDeltaTime = ClientData->SmoothingServerTimeStamp - OldServerTimeStamp;
        const double MaxOffset = ClientData->MaxClientSmoothingDeltaTime;
        const double MinOffset = FMath::Min(double(ClientData->SmoothNetUpdateTime), MaxOffset);

        // MaxDelta is the farthest behind we're allowed to be after receiving a new server time.
        const double MaxDelta = FMath::Clamp(ServerDeltaTime * 1.25, MinOffset, MaxOffset);
        ClientData->SmoothingClientTimeStamp = FMath::Clamp(ClientData->SmoothingClientTimeStamp, ClientData->SmoothingServerTimeStamp - MaxDelta, ClientData->SmoothingServerTimeStamp);

        // Compute actual delta between new server timestamp and client simulation.
        ClientData->LastCorrectionDelta = ClientData->SmoothingServerTimeStamp - ClientData->SmoothingClientTimeStamp;
        ClientData->LastCorrectionTime = MyWorld->GetTimeSeconds();

        UE_LOG(LogHumanMovement, VeryVerbose, TEXT("SmoothCorrection: WorldTime: %.6f, ServerTimeStamp: %.6f, ClientTimeStamp: %.6f, Delta: %.6f for %s"),
            MyWorld->GetTimeSeconds(), ClientData->SmoothingServerTimeStamp, ClientData->SmoothingClientTimeStamp, ClientData->LastCorrectionDelta, *GetNameSafe(CharacterOwner));

    }
}


void UHumanMovementComponent::ClearAllSavedMoves()
{
    FNetworkPredictionData_Client_Character* ClientData = GetPredictionData_Client_Character();
    if (ClientData)
    {
        UE_LOG(LogNetPlayerMovement, Log, TEXT("Clear all saved moves"));
        while (ClientData->SavedMoves.Num() > 0)
        {
            ClientData->SavedMoves.Pop();
        }
    }
}


void UHumanMovementComponent::ForceUpdateBasedMovement()
{
    SaveBaseLocation();
}

void UHumanMovementComponent::ResetNetworkSmoothingComplete()
{
    bNetworkSmoothingComplete = true;
}

void UHumanMovementComponent::ResetNetworkMovementModeChanged()
{
    bNetworkMovementModeChanged = false;
}

void UHumanMovementComponent::VerifyLocalRole()
{
    if (IsNetMode(NM_Client) && CharacterOwner->Controller)
    {
        if (CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy)
        {
            CharacterOwner->SetRole(ROLE_AutonomousProxy);
        }
    }
}

void UHumanMovementComponent::AdjustHeightAccordingToCapsuleHalfHeight(float TargetCapsuleHalfHeight)
{
    FVector StartTrace = CharacterOwner->GetActorLocation();
    FVector EndTrace = StartTrace - CharacterOwner->GetActorUpVector() * 200;
    TArray<AActor*> ActorsToIgnore;
    ActorsToIgnore.Add(PawnOwner);
    TArray<TEnumAsByte<EObjectTypeQuery>> ObjectTypes;
    ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));
    FHitResult HitResult;
    if (UKismetSystemLibrary::LineTraceSingleForObjects(PawnOwner, StartTrace, EndTrace, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true))
    {
        StartTrace.Z -= (HitResult.Distance - TargetCapsuleHalfHeight);
        CharacterOwner->SetActorLocation(StartTrace, false, nullptr, ETeleportType::TeleportPhysics);
        UE_LOG(LogHumanMovement, Log, TEXT("AdjustHeightAccordingToCapsuleHalfHeight, TargetCapsuleHalfHeight=%f, setting actor to location %s."), TargetCapsuleHalfHeight, *StartTrace.ToString());
    }
}


bool UHumanMovementComponent::DoJump(bool bReplayingMoves)
{
    if (CharacterOwner && CharacterOwner->CanJump())
    {
        // Don't jump if we can't move up/down.
        if (!bConstrainToPlane || FMath::Abs(PlaneConstraintNormal.Z) != 1.f)
        {
            // 这里原本处理了两种跳的模式，跑跳和站立跳
            // TODO:@chenyixin 这里需要看是否还需要HumanJumpMode
            if (IsHumanRunJump())
            {
                Velocity *= HumanFallConfig.JumpLateralSpeedRatio;
                if (CharacterOwner->GetLocalRole() == ROLE_Authority)
                {
                    HumanJumpMode = 1;
                }
            }
            else
            {
                if (CharacterOwner->GetLocalRole() == ROLE_Authority)
                {
                    HumanJumpMode = 2;
                }
            }

            Velocity.Z = FMath::Max(Velocity.Z, JumpZVelocity);
            SetMovementMode(MOVE_Falling);
            return true;
        }
    }

    return false;
}


void UHumanMovementComponent::OnRep_JumpMode()
{
    if (HumanJumpMode > 0)
    {
        Velocity *= HumanFallConfig.JumpLateralSpeedRatio;
        Velocity.Z = FMath::Max(Velocity.Z, JumpZVelocity);
    }
}

// 这里完全重写了游泳的移动
void UHumanMovementComponent::PhysSwimming(float deltaTime, int32 Iterations)
{
    if (deltaTime < MIN_TICK_TIME)
    {
        return;
    }

    RestorePreAdditiveRootMotionVelocity();

    float OriginalAccelZ = Acceleration.Z;
    Iterations++;
    FVector OldLocation = UpdatedComponent->GetComponentLocation();
    if (!HasAnimRootMotion() && !CurrentRootMotion.HasOverrideVelocity())
    {
        CalcVelocity(deltaTime, 8.f, false, GetMaxBrakingDeceleration());
    }

    ApplyRootMotionToVelocity(deltaTime);

    FHitResult Hit(1.f);
    FVector Adjusted = Velocity * deltaTime;

    if (!bFlotageLocationZEnable)
    {
        Adjusted.Z = SwimLocationZ - OldLocation.Z;
    }

    SafeMoveUpdatedComponent(Adjusted, UpdatedComponent->GetComponentQuat(), true, Hit);

    float remainingTime = 0.f;
    if (Hit.Time < 1.f && CharacterOwner && Acceleration != FVector::ZeroVector)
    {
        Velocity.Z = 1.f;

        // allow upward velocity at surface if against obstacle
        Velocity.Z += OriginalAccelZ * deltaTime;
        Adjusted = Velocity * (1.f - Hit.Time)*deltaTime;
        SafeMoveUpdatedComponent(Adjusted, UpdatedComponent->GetComponentQuat(), true, Hit);
        if (!IsSwimming())
        {
            StartNewPhysics(remainingTime, Iterations);
            return;
        }

        if (Hit.Normal.Z >= GetWalkableFloorZ())
        {
            //adjust and try again
            HandleImpact(Hit, deltaTime, Adjusted);
            SlideAlongSurface(Adjusted, (1.f - Hit.Time), Hit.Normal, Hit, true);
        }
    }

    // 在位移过程中，判断是否踩到了地面，是否需要切换为walk的状态
    if (PawnOwner->GetLocalRole() >= ROLE_AutonomousProxy)
    {
        FFindFloorResult thisFloor;
        auto thisloc = UpdatedComponent->GetComponentLocation();
        if (bFlotageLocationZEnable)
        {
            thisloc.Z = SwimLocationZ;
        }
        FindFloor(thisloc, thisFloor, false, NULL);
        bool bFindFloor = thisFloor.bBlockingHit && thisFloor.bWalkableFloor && (thisloc.Z > SwimLocationZ);;
        IsFindSwimFloor(bFindFloor);
        if (bFlotageLocationZEnable)
        {
            thisloc.Z = FlotageLocationZ;
            UpdatedComponent->SetWorldLocation(thisloc, false, nullptr, ETeleportType::TeleportPhysics);
        }
    }

    //may have left water - if so, script might have set new physics mode
    if (!IsSwimming())
    {
        StartNewPhysics(remainingTime, Iterations);
    }
}

void UHumanMovementComponent::IsFindSwimFloor(bool bFind)
{
    if (bFindSwimFloor != bFind)
    {
        bFindSwimFloor = bFind;
        OnHumanFindSwimFloor.Broadcast(bFind);
    }
}

bool UHumanMovementComponent::CheckCanSwim()
{
    if (MovementMode == EMovementMode::MOVE_Swimming)
    {
        return false;
    }

    FVector Location = UpdatedComponent->GetComponentLocation();
    if (Location.Z < SwimLocationZ)
    {
        return true;
    }

    if (MovementMode == EMovementMode::MOVE_Walking && !CurrentFloor.IsWalkableFloor())
    {
        return true;
    }

    return false;
}

bool UHumanMovementComponent::UsePiratesSmoothMode()
{
    if (CVar_HumanMovementSmoothMode == 2 || MovementMode != MOVE_Walking || GetWorld()->GetWorldSettings()->TimeDilation != 1.f
        || CharacterOwner->IsPlayingRootMotion() || Velocity.IsNearlyZero() || Acceleration.IsNearlyZero())
    {
        return false;
    }
    return true;
}

bool UHumanMovementComponent::StopHumanPathMove_Validate(EPathFollowingResult::Type Result)
{
    return true;
}

void UHumanMovementComponent::StopHumanPathMove_Implementation(EPathFollowingResult::Type Result)
{
    AbortHumanPathMove(Result);
}

bool UHumanMovementComponent::ServerStartHumanPathMove_Validate(const TArray<FVector>& InPath, float AcceptanceRadius)
{
    return true;
}

void UHumanMovementComponent::ServerStartHumanPathMove_Implementation(const TArray<FVector>& InPath, float AcceptanceRadius)
{
    StartHumanPathMove(InPath, AcceptanceRadius);
}

void UHumanMovementComponent::ClientAdjustPosition_Implementation
(
    float TimeStamp,
    FVector NewLocation,
    FVector NewVelocity,
    UPrimitiveComponent* NewBase,
    FName NewBaseBoneName,
    bool bHasBase,
    bool bBaseRelativePosition,
    uint8 ServerMovementMode
)
{
    if (!HasValidData() || !IsActive())
    {
        return;
    }

    if (!EnableMovementSyncLocal)
    {
        AdjustPositionInfo->Set(TimeStamp, NewLocation, NewVelocity, NewBase, NewBaseBoneName, bHasBase, bBaseRelativePosition, ServerMovementMode);
        return;
    }

    FNetworkPredictionData_Client_Character* ClientData = GetPredictionData_Client_Character();
    check(ClientData);

    // Make sure the base actor exists on this client.
    const bool bUnresolvedBase = bHasBase && (NewBase == NULL);
    if (bUnresolvedBase)
    {
        if (bBaseRelativePosition)
        {
            UE_LOG(LogNetPlayerMovement, Warning, TEXT("ClientAdjustPosition_Implementation could not resolve the new relative movement base actor, ignoring server correction!"));
            return;
        }
        else
        {
            UE_LOG(LogNetPlayerMovement, Verbose, TEXT("ClientAdjustPosition_Implementation could not resolve the new absolute movement base actor, but WILL use the position!"));
        }
    }

    // Ack move if it has not expired.
    int32 MoveIndex = ClientData->GetSavedMoveIndex(TimeStamp);
    if (MoveIndex == INDEX_NONE)
    {
        if (ClientData->LastAckedMove.IsValid())
        {
            UE_LOG(LogNetPlayerMovement, Log, TEXT("ClientAdjustPosition_Implementation could not find Move for TimeStamp: %f, LastAckedTimeStamp: %f, CurrentTimeStamp: %f"), TimeStamp, ClientData->LastAckedMove->TimeStamp, ClientData->CurrentTimeStamp);
        }
        return;
    }
    ClientData->AckMove(MoveIndex, *this);

    FVector WorldShiftedNewLocation;
    //  Received Location is relative to dynamic base
    if (bBaseRelativePosition)
    {
        FVector BaseLocation;
        FQuat BaseRotation;
        MovementBaseUtility::GetMovementBaseTransform(NewBase, NewBaseBoneName, BaseLocation, BaseRotation); // TODO: error handling if returns false
        WorldShiftedNewLocation = NewLocation + BaseLocation;
    }
    else
    {
        WorldShiftedNewLocation = FRepMovement::RebaseOntoLocalOrigin(NewLocation, this);
    }

    FVector OldLocation = UpdatedComponent->GetComponentLocation();
    const FVector LocDiff = WorldShiftedNewLocation - OldLocation;
    const AGameNetworkManager* GameNetworkManager = (const AGameNetworkManager*)(AGameNetworkManager::StaticClass()->GetDefaultObject());
    bool bAdjust = true;
    if (GameNetworkManager->ExceedsAllowablePositionError(LocDiff) == false)
    {
        OldLocation.Z = WorldShiftedNewLocation.Z;
        //WorldShiftedNewLocation = OldLocation;
        bAdjust = false;
    }
    // Trigger event
    OnClientCorrectionReceived(*ClientData, TimeStamp, WorldShiftedNewLocation, NewVelocity, NewBase, NewBaseBoneName, bHasBase, bBaseRelativePosition, ServerMovementMode);

    // Trust the server's positioning.
    if (bEnableClientAdjustPosition && UpdatedComponent)
    {
        if (bAdjust || (FMath::Abs(LocDiff.Z) > CorrectionAdjustZ && !CharacterOwner->IsPlayingRootMotion()))
        {
            // #if !UE_BUILD_SHIPPING
            //             const FVector VelocityCorrection = NewVelocity - Velocity;
            //             FVector LocDiffNew = WorldShiftedNewLocation - UpdatedComponent->GetComponentLocation();
            //             FString AdjustedDebugString = FString::Printf(TEXT("ClientAdjustPosition Correction(%s), (%s), (%f)"),
            //                 *VelocityCorrection.ToCompactString(), *LocDiffNew.ToCompactString(), (LocDiffNew | LocDiffNew));
            //             UKismetSystemLibrary::PrintWarning(AdjustedDebugString);
            // #endif
            FVector LocDiffNew = WorldShiftedNewLocation - UpdatedComponent->GetComponentLocation();
            UE_LOG(LogHumanMovement, Warning, TEXT("ClientAdjustPosition bAdjust=%i Correction(%f), LocDiff(%f), nloc=%s, oloc=%s"), (int)bAdjust,
                (LocDiffNew | LocDiffNew), LocDiff.Z, *WorldShiftedNewLocation.ToString(), *UpdatedComponent->GetComponentLocation().ToString());
            UpdatedComponent->SetWorldLocation(WorldShiftedNewLocation, false, nullptr, ETeleportType::TeleportPhysics);
        }
    }
    Velocity = NewVelocity;

    // Trust the server's movement mode
    UPrimitiveComponent* PreviousBase = CharacterOwner->GetMovementBase();
    ApplyNetworkMovementMode(ServerMovementMode);

    // Set base component
    UPrimitiveComponent* FinalBase = NewBase;
    FName FinalBaseBoneName = NewBaseBoneName;
    if (bUnresolvedBase)
    {
        check(NewBase == NULL);
        check(!bBaseRelativePosition);

        // We had an unresolved base from the server
        // If walking, we'd like to continue walking if possible, to avoid falling for a frame, so try to find a base where we moved to.
        if (PreviousBase && UpdatedComponent)
        {
            FindFloor(UpdatedComponent->GetComponentLocation(), CurrentFloor, false); //-V595
            if (CurrentFloor.IsWalkableFloor())
            {
                FinalBase = CurrentFloor.HitResult.Component.Get();
                FinalBaseBoneName = CurrentFloor.HitResult.BoneName;
            }
            else
            {
                FinalBase = nullptr;
                FinalBaseBoneName = NAME_None;
            }
        }
    }
    SetBase(FinalBase, FinalBaseBoneName);

    // Update floor at new location
    UpdateFloorFromAdjustment();
    bJustTeleported = true;

    // Even if base has not changed, we need to recompute the relative offsets (since we've moved).
    SaveBaseLocation();

    LastUpdateLocation = UpdatedComponent ? UpdatedComponent->GetComponentLocation() : FVector::ZeroVector;
    LastUpdateRotation = UpdatedComponent ? UpdatedComponent->GetComponentQuat() : FQuat::Identity;
    LastUpdateVelocity = Velocity;

    UpdateComponentVelocity();
    ClientData->bUpdatePosition = true;
}

bool UHumanMovementComponent::ServerExceedsAllowablePositionError(float ClientTimeStamp, float DeltaTime, const FVector& Accel, const FVector& ClientWorldLocation, const FVector& RelativeClientLocation, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode)
{
    // 加入了游泳和非法检测的判断。
    const FVector LocDiff = UpdatedComponent->GetComponentLocation() - ClientWorldLocation;
    if ((MovementMode != MOVE_Swimming && FMath::Abs(LocDiff.Z) > CorrectionAdjustZ) 
        || (bMovementIllegal && ((LocDiff | LocDiff) > MovementIllegalDiff)))
    {
        bNetworkLargeClientCorrection |= (LocDiff.SizeSquared() > FMath::Square(NetworkLargeClientCorrectionDistance));

        if (bMovementIllegal)
        {
            UE_LOG(LogHumanMovement, Log, TEXT("HumanMovement illegal ServerCheck %s locDiff=%f"),
                *GetNameSafe(CharacterOwner), (LocDiff | LocDiff));
        }
        return true;
    }

    return UCharacterMovementComponent::ServerExceedsAllowablePositionError(ClientTimeStamp, DeltaTime, Accel, ClientWorldLocation, RelativeClientLocation, ClientMovementBase, ClientBaseBoneName, ClientMovementMode);
}

float UHumanMovementComponent::GetMaxSpeed() const
{
    // 反外挂测试
    if (DebugIllegalSpeed > 0.f)
    {
        return DebugIllegalSpeed;
    }
    return UCharacterMovementComponent::GetMaxSpeed();
}

bool UHumanMovementComponent::CheckMovementIllegal(float DeltaTime)
{
    if (!PawnOwner || PawnOwner->GetLocalRole() != ROLE_Authority || !CharacterOwner->IsPlayerControlled())
    {
        return false;
    }

    if (Acceleration.IsNearlyZero() || Velocity.IsNearlyZero())
    {
        return false;
    }

    //TODO：这里需要处理跳伞的速度
    if (/*MovementMode == MOVE_Falling || */!bStartTotalDistance)
    {
        return false;
    }

    MovementIllegalTime += DeltaTime;
    if (MovementIllegalTime < 1.f)
    {
        return false;
    }

    float CurrentSpeed = FMath::Max(GetMaxSpeed(), InitWalkSpeed);
    float MaxSpeed = FMath::Min(CheckMaxSpeed, CurrentSpeed);
    float MaxMovementDiff = MaxSpeed * MovementIllegalRate * MovementIllegalTime;
    FVector CurLocation = UpdatedComponent->GetComponentLocation();
    FVector LocDiffVector = CurLocation - LastCheckLocation;
    float LocDiff = LocDiffVector.Size();
    LastCheckLocation = CurLocation;
    MovementIllegalTime = 0.f;
    if (LocDiff > MaxMovementDiff && !Velocity.IsNearlyZero())
    {
        MovementIllegalCount++;
        UE_LOG(LogHumanMovement, Log, TEXT("HumanMovement illegal %s LocDiff=%f, count=%i, maxSpeed=%f, maxDiff=%f, bI=%i, loc=%s, mode=%i, vel=%s"), 
            *GetNameSafe(CharacterOwner), LocDiff, MovementIllegalCount, MaxSpeed, MaxMovementDiff, bMovementIllegal, 
            *CurLocation.ToString(), (int)MovementMode, *Velocity.ToString());
        if (MovementIllegalCount >= CheckIllegalCount && bMovementIllegal == 0)
        {
            bMovementIllegal = 1;
            auto DelegateManger = UCommonShell::GetCommon(GWorld)->GetGameDelegateManager();
            DelegateManger->Movement->OnMovementIllegalDetection.Broadcast(HumanCharacter);
            return true;
        }
    }
    else if (bMovementIllegal)
    {
        // 为避免误报，隔一段时间再检测一次
        MovementIllegalCount--;
        if (MovementIllegalCount <= ResetMovementCount)
        {
            bMovementIllegal = 0;
            MovementIllegalCount = CheckIllegalCount - 1;
        }
    }
    else
    {
        MovementIllegalCount = 0;
    }
    return false;
}

#if WITH_EDITOR
void UHumanMovementComponent::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
    Super::PostEditChangeProperty(PropertyChangedEvent);

    const FProperty* PropertyThatChanged = PropertyChangedEvent.MemberProperty;
    if (PropertyThatChanged && PropertyThatChanged->GetFName() == GET_MEMBER_NAME_CHECKED(UHumanMovementComponent, CrawlMoveAlongFloorAngle))
    {
        SetCrawlMoveAlongFloorAngle(CrawlMoveAlongFloorAngle);
    }
}
#endif

void UHumanMovementComponent::HandleSwimmingHit()
{
    if (IsSwimming())
    {
        FVector Dir = GetPendingInputVector();
        if (Dir != FVector::ZeroVector)
        {
            Dir.Normalize();
            FVector StartTrace = PawnOwner->GetActorLocation();
            FVector EndTrace = StartTrace + Dir * 5;
            TArray<AActor*> ActorsToIgnore;
            ActorsToIgnore.Add(PawnOwner);
            FHitResult HitResult;
            TArray<TEnumAsByte<EObjectTypeQuery> >  ObjectTypes;
            ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_Vehicle));
            if (UKismetSystemLibrary::BoxTraceSingleForObjects(PawnOwner, StartTrace, EndTrace, CollisionCheckBox, PawnOwner->K2_GetActorRotation(), ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true))
            {
                float DotP = Dir | HitResult.Normal;
                if (DotP < 0.f)
                {
                    ConsumeInputVector();
                }
            }
        }
    }
}

void UHumanMovementComponent::HandleCrawlHit()
{
    if (bCrawlState)
    {
        FVector Dir = GetPendingInputVector();
        if (Dir != FVector::ZeroVector)
        {
            Dir.Normalize();
            FVector StartTrace = PawnOwner->GetActorLocation();
            FVector EndTrace = StartTrace + Dir * 10;
            TArray<AActor*> ActorsToIgnore;
            ActorsToIgnore.Add(PawnOwner);
            FHitResult HitResult;
            TArray<TEnumAsByte<EObjectTypeQuery> >  ObjectTypes;
            ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));
            if (UKismetSystemLibrary::BoxTraceSingleForObjects(PawnOwner, EndTrace, EndTrace, CollisionCheckBox, PawnOwner->K2_GetActorRotation(), ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true))
            {
                ConsumeInputVector();
            }
        }
    }
}

void UHumanMovementComponent::StopHumanMovementImmediately()
{
    Super::StopMovementImmediately();
    if (PawnOwner->GetLocalRole() == ROLE_Authority)
    {
        ClientSendStopMovement();
    }
    FVector OldInputVector = ConsumeInputVector();
    FVector DeltaVector = FVector::ZeroVector - OldInputVector;
    HumanCharacter->Internal_AddMovementInput(DeltaVector, true);
}

void UHumanMovementComponent::ClientSendStopMovement_Implementation()
{
    if (HumanCharacter && HumanCharacter->Controller)
    {
        HumanCharacter->Controller->SetIgnoreMoveInput(true);
        OnHumanStopMovementImmediately.Broadcast();
    }
}

void UHumanMovementComponent::InitData(const FHumanMovementConfig& InConfig, const FHumanFallConfig& InFallConfig)
{
    // ================================= character movement =================================
    // We set MaxAcceleration and BrakeAcceleration to very large to make velocity
    // can be increase to max or decrease to 0 within one tick.
    //MaxAcceleration = 100000.f;
    //BrakingDecelerationWalking = MaxAcceleration;
    GroundFriction = 0.f;
    bUseSeparateBrakingFriction = 0;
    bForceMaxAccel = 0;
    bMaintainHorizontalGroundVelocity = 1;
    AirControl = 1.f;
    FallingTerminalVelocity = GetPhysicsVolume()->TerminalVelocity;
    bFallingDeceleration = false;

    // Negative value means infinite rotation rate and instant turns.
    RotationRate = FRotator(0.f, -1.f, 0.f);
    //bOrientRotationToMovement = 1;
    bUseControllerDesiredRotation = 0;

    bRunPhysicsWithNoController = 1;
    MaxSimulationIterations = 1;
    // =======================================================================================

    HumanCharacter = Cast<APiratesHumanCharacter>(PawnOwner);
    check(HumanCharacter != nullptr);

    Config = InConfig;
    SetHumanFallConfig(InFallConfig);

    bRequestPathMove = 0;
    CurrentPathMoveVector = FVector::ZeroVector;
    CurrentPathIndex = -1;
    MaxPathIndex = -1;
    CheckFinalRadiusIndex = -1;
    FinalAcceptanceRadiusSq = 0.f;
    IntermedialAcceptanceRadiusSq = 0.f;

    HumanHalfHeight = UpdatedComponent->Bounds.BoxExtent.Z;

    CorrectionAdjustZ = 100.f;

    SmoothCorrectionTimestamp = 0.f;
    SmoothCorrectionDeltaZ = 0.f;
    SmoothCorrectionDirection = FVector::ZeroVector;
    SmoothMoveMaxDeltaTime = 0.125f;
    SmoothMoveCorrection = 40.f;

    bHumanMoving = false;
    AlongSurfaceType = EPhysicalSurface::SurfaceType_Default;

    bCrawlState = false;
    bCrawlStateChanged = false;
    LastAdjustLoction = FVector::ZeroVector;
    LastAdjustRotator = FRotator::ZeroRotator;
    bFindSwimFloor = true;
    bFlotageLocationZEnable = false;
    FlotageLocationZ = 0.f;

    bMoveAngleLessThan = true;

    bPerSwimState = false;

    bStartTotalDistance = false;
    TotalDistance = 0.f;

    MovementIllegalTime = 0.f;
    bMovementIllegal = 0;
    MovementIllegalDiff = 100.f;
    MovementIllegalCount = 0;
    LastCheckLocation = FVector::ZeroVector;
    DebugIllegalSpeed = 0.f;
    CheckMaxSpeed = 650.f;

    SetMovementMode(MOVE_Walking);

    if (HasBegunPlay())
    {
        Activate();
    }
    else
    {
        bAutoActivate = 1;
    }
}

void UHumanMovementComponent::ClientTeleportHuman_Implementation(FVector Location, float Yaw)
{
    UE_LOG(LogHumanMovement, Log, TEXT("ClientTeleportHuman"));

    TeleportHuman(Location, Yaw, false, true);
}

void UHumanMovementComponent::TeleportHuman(const FVector& Location, float Yaw, bool bResetMovement, bool bAdjustZ, bool bSynClient)
{
    FVector Loc = Location;
    if (bAdjustZ)
    {
        Loc.Z += HumanHalfHeight;
    }

    FRotator Rot = UpdatedComponent->GetComponentRotation();
    Rot.Yaw = Yaw;
    UpdatedComponent->SetWorldLocationAndRotation(Loc, Rot, false, nullptr, ETeleportType::TeleportPhysics);

    // Find floor at current location
    UpdateFloorFromAdjustment();

    // Validate it. We don't want to pop down to walking mode from very high off the ground, but we'd like to keep walking if possible.
    UPrimitiveComponent* OldBase = CharacterOwner->GetMovementBase();
    UPrimitiveComponent* NewBase = NULL;

    if (OldBase && CurrentFloor.IsWalkableFloor() && CurrentFloor.FloorDist <= MAX_FLOOR_DIST && Velocity.Z <= 0.f)
    {
        // Close enough to land or just keep walking.
        NewBase = CurrentFloor.HitResult.Component.Get();
    }
    else
    {
        CurrentFloor.Clear();
    }

    if (bResetMovement)
    {
        //InputData.Reset();
        Acceleration = FVector::ZeroVector;
        Velocity = FVector::ZeroVector;
    }

    if (!CurrentFloor.IsWalkableFloor() || (OldBase && !NewBase))
    {
        SetMovementMode(MOVE_Falling);
    }
    else
    {
        SetMovementMode(MOVE_Walking);
    }

    if (ROLE_Authority == CharacterOwner->GetLocalRole())
    {
        if (bSynClient)
        {
            ClientTeleportHuman(Loc, Yaw);
        }

        //teleport以后重置非法检测的数据
        MovementIllegalCount = 0;
        bMovementIllegal = 0;
    }
}

void UHumanMovementComponent::TeleportToSafeLocation()
{
    FVector OldLocation = UpdatedComponent->GetComponentLocation();
    float randX = FMath::RandRange(-Config.SafeTeleportMinDistance, Config.SafeTeleportMaxDistance);
    float randY = FMath::RandRange(-Config.SafeTeleportMinDistance, Config.SafeTeleportMaxDistance);
    FVector NewRandLocation = FVector(OldLocation.X + randX, OldLocation.Y + randY, OldLocation.Z + HumanHalfHeight * 2);
    FVector NewLocation = OldLocation;
    if (HumanCharacter->GetNearestSafeLocation(NewRandLocation, Config.SafeTeleportMinDistance, NewLocation))
    {
        TeleportHuman(NewLocation, UpdatedComponent->GetComponentRotation().Yaw, true, true, true);
        UE_LOG(LogHumanMovement, Log, TEXT("UHumanMovementComponent::TeleportToSafeLocation 1, old=%s, new=%s"), *OldLocation.ToString(), *UpdatedComponent->GetComponentLocation().ToString());
    }
    else
    {
        randX = FMath::RandRange(-Config.SafeTeleportMinDistance, Config.SafeTeleportMaxDistance);
        randY = FMath::RandRange(-Config.SafeTeleportMinDistance, Config.SafeTeleportMaxDistance);
        NewRandLocation = FVector(OldLocation.X + randX, OldLocation.Y + randY, OldLocation.Z + HumanHalfHeight * 2);
        TeleportHuman(NewRandLocation, UpdatedComponent->GetComponentRotation().Yaw, true, true, true);
        UE_LOG(LogHumanMovement, Log, TEXT("UHumanMovementComponent::TeleportToSafeLocation 2, old=%s, new=%s"), *OldLocation.ToString(), *UpdatedComponent->GetComponentLocation().ToString());
    }
}

void UHumanMovementComponent::TeleportBot()
{
    float Radius = 500.f;
    FVector OldLocation = UpdatedComponent->GetComponentLocation();
    FVector NewLocation = OldLocation;
    if (HumanCharacter->GetNearestSafeLocation(OldLocation, Radius, NewLocation))
    {
        TeleportHuman(NewLocation, UpdatedComponent->GetComponentRotation().Yaw, true);
        UE_LOG(LogHumanMovement, Log, TEXT("UHumanMovementComponent::TeleportAI 1 old=%s, new=%s"), *OldLocation.ToString(), *UpdatedComponent->GetComponentLocation().ToString());
    }
    else
    {
        float randX = FMath::RandRange(-Radius, Radius);
        float randY = FMath::RandRange(-Radius, Radius);
        FVector NewRandLocation = FVector(OldLocation.X + randX, OldLocation.Y + randY, OldLocation.Z + HumanHalfHeight * 2);
        if (HumanCharacter->GetNearestSafeLocation(NewRandLocation, Radius, NewRandLocation))
        {
            TeleportHuman(NewRandLocation, UpdatedComponent->GetComponentRotation().Yaw, true);
            UE_LOG(LogHumanMovement, Log, TEXT("UHumanMovementComponent::TeleportAI 2, old=%s, new=%s"), *OldLocation.ToString(), *UpdatedComponent->GetComponentLocation().ToString());
        }
        else
        {
            randX = FMath::RandRange(-Radius, Radius);
            randY = FMath::RandRange(-Radius, Radius);
            NewRandLocation = FVector(OldLocation.X + randX, OldLocation.Y + randY, OldLocation.Z + HumanHalfHeight * 2);
            HumanCharacter->GetNearestSafeLocation(NewRandLocation, Radius, NewRandLocation);
            TeleportHuman(NewRandLocation, UpdatedComponent->GetComponentRotation().Yaw, true);
            UE_LOG(LogHumanMovement, Log, TEXT("UHumanMovementComponent::TeleportAI 3, old=%s, new=%s"), *OldLocation.ToString(), *UpdatedComponent->GetComponentLocation().ToString());
        }
    }
}

void UHumanMovementComponent::StartHumanPathMove(const TArray<FVector>& InPath, float AcceptanceRadius)
{
    if (InPath.Num() == 0)
    {
        return;
    }

    StopHumanMovementImmediately();

    IntermedialAcceptanceRadiusSq = FMath::Square(NavAgentProps.AgentRadius);
    FinalAcceptanceRadiusSq = FMath::Square(AcceptanceRadius);
    if (FinalAcceptanceRadiusSq < IntermedialAcceptanceRadiusSq)
    {
        FinalAcceptanceRadiusSq = IntermedialAcceptanceRadiusSq;
    }

    NavPath.Empty(InPath.Num());
    NavPath.Append(InPath);

    int32 N = NavPath.Num();
    MaxPathIndex = N - 1;
    CurrentPathIndex = 0;
    CheckFinalRadiusIndex = N;

    const FVector& Dest = NavPath[N - 1];
    for (int32 i = MaxPathIndex - 1; i > -1; --i)
    {
        if ((Dest - NavPath[i]).SizeSquared2D() > FinalAcceptanceRadiusSq)
        {
            CheckFinalRadiusIndex = i;
            break;
        }
    }
    if (CheckFinalRadiusIndex > MaxPathIndex)
    {
        CheckFinalRadiusIndex = -1;
    }
    else if (CheckFinalRadiusIndex > MaxPathIndex - 2)
    {
        CheckFinalRadiusIndex = N;
    }

    CurrentPathMoveVector = NavPath[0] - GetHumanFeetLocation();
    RotationRate.Yaw = -1.f;
    bRequestPathMove = 1;

    if (PawnOwner && PawnOwner->GetLocalRole() == ROLE_AutonomousProxy)
    {
        ServerStartHumanPathMove(InPath, AcceptanceRadius);
    }
}

void UHumanMovementComponent::AbortHumanPathMove(EPathFollowingResult::Type Result)
{
    if (IsHumanPathMove())
    {
        OnPathMoveFinished(Result);
    }
}

void UHumanMovementComponent::SetActorLocationAndUpdateBasedMovement(FVector NewLocation)
{
    CharacterOwner->SetActorLocation(NewLocation);
    SaveBaseLocation();
}

void UHumanMovementComponent::SetActorRotationAndUpdateBasedMovement(FRotator NewRotation)
{
    CharacterOwner->SetActorRotation(NewRotation);
    SaveBaseLocation();
}

void UHumanMovementComponent::UpdateFlotage(float LocationZ)
{
    if (bFlotageLocationZEnable)
    {
        FlotageLocationZ = LocationZ;
    }
}

void UHumanMovementComponent::SetFallingTerminalVelocity(const float TerminalVelocity)
{
    if (FMath::Abs(TerminalVelocity) < FMath::Abs(Velocity.Z))
    {
        bFallingDeceleration = true;
    }
    else
    {
        bFallingDeceleration = false;
    }
    FallingTerminalVelocity = TerminalVelocity;
}

const float UHumanMovementComponent::GetFallingTerminalVelocity() const
{
    return FallingTerminalVelocity;
}

void UHumanMovementComponent::SetHumanFallConfig(const FHumanFallConfig& InFallConfig)
{
    HumanFallConfig = InFallConfig;
    GravityScale = HumanFallConfig.CustomGravityScale;
    JumpZVelocity = HumanFallConfig.JumpZVelocity;
}

FHumanFallConfig UHumanMovementComponent::GetHumanFallConfig()
{
    return HumanFallConfig;
}

void UHumanMovementComponent::SetMaxWalkSpeed(float InSpeed)
{
    MaxWalkSpeed = InSpeed;
    CurrentMaxWalkSpeed = InSpeed;
}

void UHumanMovementComponent::OnPathMoveFinished(EPathFollowingResult::Type Result)
{
    bRequestPathMove = 0;
    OnHumanPathMoveFinished.Broadcast(Result);
    if (PawnOwner->GetLocalRole() == ROLE_AutonomousProxy)
    {
        StopHumanPathMove(Result);
    }
}

void UHumanMovementComponent::ProcessPathMove()
{
//     if (!IsHumanPathMove())
//     {
//         return;
//     }

    if (NavPath.Num() <= 0)
    {
        return;
    }

    FVector CurrentLocation = GetHumanFeetLocation();
    if (CurrentPathIndex > CheckFinalRadiusIndex)
    {
        if ((CurrentLocation - NavPath[MaxPathIndex]).SizeSquared2D() < FinalAcceptanceRadiusSq)
        {
            OnPathMoveFinished(EPathFollowingResult::Type::Success);
            return;
        }
    }

    FVector TargetLocation = NavPath[CurrentPathIndex];
    FVector CurrentMoveVector = TargetLocation - CurrentLocation;

    bool bIsLast = (CurrentPathIndex == MaxPathIndex);
    float CurrentAcceptanceRadiusSq = bIsLast ? FinalAcceptanceRadiusSq : IntermedialAcceptanceRadiusSq;

    bool bHasReached = false;
    if (FMath::Abs(CurrentMoveVector.Z) < HumanHalfHeight)
    {
        if (CurrentMoveVector.SizeSquared2D() < CurrentAcceptanceRadiusSq)
        {
            bHasReached = true;
        }
        else if (!bIsLast)
        {
            bHasReached = (CurrentPathMoveVector | CurrentMoveVector) < 0.f;
        }
    }

    if (bHasReached)
    {
        if (bIsLast)
        {
            OnPathMoveFinished(EPathFollowingResult::Type::Success);
            return;
        }

        TargetLocation = NavPath[++CurrentPathIndex];
        CurrentPathMoveVector = TargetLocation - NavPath[CurrentPathIndex - 1];
        CurrentMoveVector = TargetLocation - CurrentLocation;
    }

    Acceleration = CurrentMoveVector.GetSafeNormal2D();
}


FVector UHumanMovementComponent::GetHumanFeetLocation() const
{
    FVector Loc = UpdatedComponent->GetComponentLocation();
    if (MovementMode == EMovementMode::MOVE_Swimming)
    {
        Loc.Z = SwimLocationZ;
    }
    else
    {
        Loc.Z -= HumanHalfHeight;
    }
    return Loc;
}

void UHumanMovementComponent::SetHumanMoveState()
{
    bool bMoving = false;
    if (IsWalking() && Velocity != FVector::ZeroVector)
    {
        bMoving = true;
    }
    if (bHumanMoving == bMoving)
    {
        return;
    }
    bHumanMoving = bMoving;
    OnHumanMoveStateChanged.Broadcast(bHumanMoving);
}

bool UHumanMovementComponent::IsHumanRunJump()
{
    if (Velocity.SizeSquared() > FMath::Square(CheckRunJumpSpeed))
        return true;

    return false;
}

void UHumanMovementComponent::SetCrawlState(bool bCraw)
{
    if (bCraw == bCrawlState)
    {
        return;
    }
    bCrawlState = bCraw;
    bCrawlStateChanged = true;
}

void UHumanMovementComponent::AdjustRotationMatchSlope()
{
    if (PawnOwner->GetLocalRole() == ROLE_SimulatedProxy)
    {
        return;
    }

    if (!IsWalking())
        return;

    if (!bEnableAdjustRotationMatchSlope)
        return;

    if (!bCrawlState)
    {
        if (!bCrawlStateChanged)
            return;

        FRotator NormalRotator = UpdatedComponent->GetComponentRotation();
        NormalRotator.Pitch = 0.f;
        NormalRotator.Roll = 0.f;
        UpdatedComponent->SetRelativeRotation(NormalRotator);
        bCrawlStateChanged = false;
    }
    else if (CurrentFloor.HitResult.ImpactNormal.Z >= CrawlMoveAlongFloorZ)
    {
        auto thisLocation = UpdatedComponent->GetComponentLocation();
        FRotator thisRotator = UpdatedComponent->GetComponentRotation();
        if (LastAdjustLoction == thisLocation && LastAdjustRotator == thisRotator)
        {
            return;
        }

        const FVector UpVector = UpdatedComponent->GetUpVector();
        FVector RotationAxis = FVector::CrossProduct(UpVector, CurrentFloor.HitResult.Normal);
        float OldPitch = UpdatedComponent->GetComponentRotation().Pitch;
        float RotationAngleRad = FMath::Acos(FVector::DotProduct(UpVector, CurrentFloor.HitResult.Normal));
        if (FMath::IsNearlyZero(RotationAngleRad) || OldPitch > CrawlMoveAlongFloorAngle)
        {
            return;
        }
        FQuat Quat = FQuat(RotationAxis, RotationAngleRad);
        FQuat NewQuat = Quat * UpdatedComponent->GetComponentQuat();
        FRotator NewRotator = NewQuat.Rotator();
        NewRotator.Roll = 0.f;

        float DeltaPitch = NewRotator.Pitch - OldPitch;
        if (DeltaPitch > 5.f)
        {
            NewRotator.Pitch = OldPitch + 5.f;
        }
        else if (DeltaPitch < -5.f)
        {
            NewRotator.Pitch = OldPitch - 5.f;
        }

        if (NewRotator.Pitch > CrawlMoveAlongFloorAngle)
        {
            NewRotator.Pitch = OldPitch;
        }
        UpdatedComponent->SetRelativeRotation(NewRotator);
        LastAdjustLoction = UpdatedComponent->GetComponentLocation();
        LastAdjustRotator = UpdatedComponent->GetComponentRotation();
    }
}

void UHumanMovementComponent::SetCrawlMoveAlongFloorAngle(float MoveAngle)
{
    float MoveFloorAngle = FMath::Clamp(MoveAngle, 0.f, 90.0f);
    CrawlMoveAlongFloorZ = FMath::Cos(FMath::DegreesToRadians(MoveFloorAngle));
}

void UHumanMovementComponent::ComputeHumanMoveAngle()
{
    if (CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
    {
        return;
    }

    if (!CurrentFloor.IsWalkableFloor())
    {
        return;
    }

    //计算当前的地面角度，用来判断是否能卧倒
    if (CurrentFloor.HitResult.ImpactNormal.Z >= CrawlMoveAlongFloorZ)
    {
        if (bMoveAngleLessThan == false)
        {
            OnHumanMoveAngleChanged.Broadcast(true);
            bMoveAngleLessThan = true;
        }
    }
    else
    {
        if (bMoveAngleLessThan == true && CurrentFloor.HitResult.Distance < 40.f)
        {
            OnHumanMoveAngleChanged.Broadcast(false);
            bMoveAngleLessThan = false;
        }
    }
}

void UHumanMovementComponent::OnRegister()
{
    const ENetMode NetMode = GetNetMode();
    if (bUseRVOAvoidance && NetMode == NM_Client)
    {
        bUseRVOAvoidance = false;
    }

    Super::OnRegister();

#if WITH_EDITOR
    SetCrawlMoveAlongFloorAngle(CrawlMoveAlongFloorAngle);
#endif
}

float UHumanMovementComponent::GetClientNetSendDeltaTime(const APlayerController* PC, const FNetworkPredictionData_Client_Character* ClientData, const FSavedMovePtr& NewMove) const
{
    const UPlayer* Player = (PC ? PC->Player : nullptr);
    const UWorld* MyWorld = GetWorld();
    const AGameStateBase* const GameState = MyWorld->GetGameState();
    const AGameNetworkManager* GameNetworkManager = (const AGameNetworkManager*)(AGameNetworkManager::StaticClass()->GetDefaultObject());
    float NetMoveDelta = GameNetworkManager->ClientNetSendMoveDeltaTime;

    if (PC && Player)
    {
        // send moves more frequently in small games where server isn't likely to be saturated
        if ((Player->CurrentNetSpeed > GameNetworkManager->ClientNetSendMoveThrottleAtNetSpeed) && (GameState != nullptr) && (GameState->PlayerArray.Num() <= GameNetworkManager->ClientNetSendMoveThrottleOverPlayerCount))
        {
            NetMoveDelta = GameNetworkManager->ClientNetSendMoveDeltaTime;
        }
        else
        {
            NetMoveDelta = FMath::Max(GameNetworkManager->ClientNetSendMoveDeltaTimeThrottled, 2 * GameNetworkManager->MoveRepSize / Player->CurrentNetSpeed);
        }

        // Lower frequency for standing still and not rotating camera
        if (Acceleration.IsZero() && Velocity.IsZero() && ClientData->LastAckedMove.IsValid()
            && ClientData->LastAckedMove->Acceleration.IsZero() //修改点：保证当前没有速度，同时上一次ack的位移也是没有速度的
            && ClientData->LastAckedMove->StartControlRotation.Equals(PC->GetControlRotation()))
        {
            NetMoveDelta = FMath::Max(GameNetworkManager->ClientNetSendMoveDeltaTimeStationary, NetMoveDelta);
        }
    }

    return NetMoveDelta;
}

float UHumanMovementComponent::SlideAlongSurface(const FVector& Delta, float Time, const FVector& Normal, FHitResult& Hit, bool bHandleImpact)
{
    if (!bEnableSlideAlongSurface || IsRootMotionMovement)
        return 0.0f;

    return Super::SlideAlongSurface(Delta, Time, Normal, Hit, bHandleImpact);
}

FVector UHumanMovementComponent::ConstrainAnimRootMotionVelocity(const FVector& RootMotionVelocity, const FVector& CurrentVelocity) const
{
    FVector Result = UCharacterMovementComponent::ConstrainAnimRootMotionVelocity(RootMotionVelocity, CurrentVelocity);

    // 重新计算rootmotion的z轴
    if(bCorrectiveRootMotion && Result.Z < 0 && !IsFalling())
    {
        float CapsuleHalfHeight = CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleHalfHeight();
        FVector ActorLocation = PawnOwner->GetActorLocation();
        FVector StartTrace = ActorLocation + FVector(0, 0, CapsuleHalfHeight);
        FVector EndTrace = StartTrace + FVector(0, 0, -200);
        TArray<AActor*> ActorsToIgnore;
        ActorsToIgnore.Add(PawnOwner);
        FHitResult HitResult;
        TArray<TEnumAsByte<EObjectTypeQuery> >  ObjectTypes;
        ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));
        if (UKismetSystemLibrary::LineTraceSingleForObjects(PawnOwner, StartTrace, EndTrace, ObjectTypes, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true))
        {
            float z = (HitResult.ImpactPoint.Z + CapsuleHalfHeight - ActorLocation.Z) / SaveDeltaTime;
           // UE_LOG(LogHumanMovement, Warning, TEXT("ConstrainAnimRootMotionVelocity %s  ActorLocation %s  Z %f  Result %s tttt %f"), *HitResult.ImpactPoint.ToString(), *ActorLocation.ToString(), z, *Result.ToString(), HitResult.ImpactPoint.Z + CapsuleHalfHeight - ActorLocation.Z);
            if ((StartTrace.Z > HitResult.ImpactPoint.Z + 25) && (z > Result.Z))
            {
//                UE_LOG(LogHumanMovement, Verbose, TEXT("ConstrainAnimRootMotionVelocity*************************"));
                Result.Z = z;
            }
        }
    }
    return Result;
}

void UHumanMovementComponent::OnLanded(const FHitResult & Hit)
{
    if (Hit.bBlockingHit && bUseNewJump && Hit.Component->GetCollisionObjectType() == ECollisionChannel::ECC_WorldStatic)
    {
        Velocity *= HumanFallConfig.LandStunSpeedPreservation;
        MaxWalkSpeed = Velocity.Size2D();
    }
}

#define ANIM_ROOT_FRAME_SCALE 1
#define ONE_SECOND_FRAME 30.0f

void UHumanMovementComponent::PlayRootMotion(const TArray<FVector>& RootMotionSouce, float ScaleZ, const FVector& StartPos, const FRotator& StartRotator, bool ResetReplicateMovement, float PlayRate)
{
    //ReturnIfNullUObject(RootMotionSouce);
    //UE_LOG(LogHumanMovement, Verbose, TEXT("RootMotionTotalDeltaTime %f RootMotionFrameIndex %d RootMotionTotalNum %d"), RootMotionTotalDeltaTime, RootMotionFrameIndex, RootMotionSouce.Num());
    InitPlayRootMotion(RootMotionSouce, PlayRate);
    bResetReplicateMovement = ResetReplicateMovement;
    RootMotionStartTransform = GetCharacterOwner()->GetActorTransform();
    if (!StartRotator.IsNearlyZero())
    {
        IsLerpRotator = true;
        RootMotionStartTransform.SetRotation(FQuat(StartRotator));
    }
    if (!StartPos.IsNearlyZero())
    {
        TargetRootMotionStartTransform = RootMotionStartTransform;
        TargetRootMotionStartTransform.SetLocation(StartPos);
        bUseTargetRootMotionStartTransform = true;
    }

    UE_LOG(LogHumanMovement, Verbose, TEXT("RootMotionMovement StartPlayRootMotion LocalRole = %d RootMotionFrame = %d StartPosition = %s StartRotation = %s Character %s StartPos %s"), CharacterOwner->GetLocalRole(), RootMotionPositions.Num(), *(RootMotionStartTransform.GetLocation().ToString()), *(RootMotionStartTransform.GetRotation().ToString()), *GetNameSafe(CharacterOwner), *StartPos.ToString());
}

void UHumanMovementComponent::StopRootMotion()
{
    UnInitPlayRootMotion();
    UE_LOG(LogHumanMovement, Verbose, TEXT("RootMotionMovement StopRootMotion LocalRole = %d CurrentPosition %s"), CharacterOwner->GetLocalRole(), *(CharacterOwner->GetActorLocation().ToString()));
}

void UHumanMovementComponent::PlayRootMotionWithDeltaCorrection(const TArray<FVector>& RootMotionSouce, const FTransform& ExpectStartPos, float fStartCorrectTime, const FVector2D& FinalCorrectTimeRange, const FTransform& FinalTargetPos, float fPlayRate /*= 1.0*/, bool bSafeMoveLocation /*= true*/)
{
    UE_LOG(LogHumanMovementSmooth, Log, TEXT("PlayRootMotionWithDeltaCorrection RootMotionSouce: %d"), RootMotionSouce.Num());
    UE_LOG(LogHumanMovementSmooth, Log, TEXT("PlayRootMotionWithDeltaCorrection ExpectStartPos: %s"), *ExpectStartPos.ToString());
    UE_LOG(LogHumanMovementSmooth, Log, TEXT("PlayRootMotionWithDeltaCorrection fStartCorrectTime: %f"), fStartCorrectTime);
    UE_LOG(LogHumanMovementSmooth, Log, TEXT("PlayRootMotionWithDeltaCorrection FinalCorrectTimeRange: %f, %f"), FinalCorrectTimeRange.X, FinalCorrectTimeRange.Y);
    UE_LOG(LogHumanMovementSmooth, Log, TEXT("PlayRootMotionWithDeltaCorrection FinalTargetPos: %s"), *FinalTargetPos.ToString());
    UE_LOG(LogHumanMovementSmooth, Log, TEXT("PlayRootMotionWithDeltaCorrection fPlayRate: %f"), fPlayRate);

    InitPlayRootMotion(RootMotionSouce, fPlayRate);

    bPlayingCorrectRootMotion = true;
    bSafeMove = bSafeMoveLocation;
    RootMotionStartTransform = GetCharacterOwner()->GetActorTransform();
    TargetRootMotionStartTransform = ExpectStartPos;
    bUseTargetRootMotionStartTransform = true;
    RootMotionStartCorrectTime = fStartCorrectTime;
    RootMotionCorrectTimeRange = FinalCorrectTimeRange;
    RootMotionFinalTargetTransform = FinalTargetPos;
}

void UHumanMovementComponent::SafeMoveRootMotion(const FVector& DestPosition, const FQuat& NewQuat, float DeltaSeconds)
{
    //if (!CurrentFloor.IsWalkableFloor())
    //{
    //    return;
    //}
    FStepDownResult StepDownResult;

    FHitResult Hit(1.f);
    FVector Delta = DestPosition - UpdatedComponent->GetComponentLocation();
    const bool bZeroDelta = Delta.IsNearlyZero();
    if (bZeroDelta)
    {
        return;
    }
    FVector RampVector = ComputeGroundMovementDelta(Delta, CurrentFloor.HitResult, CurrentFloor.bLineTrace);

    SafeMoveUpdatedComponent(RampVector, NewQuat, true, Hit);

    // 攀爬
    if (MovementMode == EMovementMode::MOVE_Flying)
    {
        return;
    }

    float LastMoveTimeSlice = DeltaSeconds;

    //if (Hit.bStartPenetrating)
    //{
    //    // Allow this hit to be used as an impact we can deflect off, otherwise we do nothing the rest of the update and appear to hitch.
    //    HandleImpact(Hit);
    //    SlideAlongSurface(Delta, 1.f, Hit.Normal, Hit, true);

    //    if (Hit.bStartPenetrating)
    //    {
    //        OnCharacterStuckInGeometry(&Hit);
    //    }
    //}
    //else 
    if (!Hit.bStartPenetrating && Hit.IsValidBlockingHit())
    {
        // We impacted something (most likely another ramp, but possibly a barrier).
        float PercentTimeApplied = Hit.Time;
        if ((Hit.Time > 0.f) && (Hit.Normal.Z > KINDA_SMALL_NUMBER) && IsWalkable(Hit))
        {
            // Another walkable ramp.
            const float InitialPercentRemaining = 1.f - PercentTimeApplied;
            RampVector = ComputeGroundMovementDelta(Delta * InitialPercentRemaining, Hit, false);
            LastMoveTimeSlice = InitialPercentRemaining * LastMoveTimeSlice;
            SafeMoveUpdatedComponent(RampVector, NewQuat, true, Hit);

            const float SecondHitPercent = Hit.Time * InitialPercentRemaining;
            PercentTimeApplied = FMath::Clamp(PercentTimeApplied + SecondHitPercent, 0.f, 1.f);
        }

        if (Hit.IsValidBlockingHit())
        {
            if (CanStepUp(Hit) || (CharacterOwner->GetMovementBase() != NULL && CharacterOwner->GetMovementBase()->GetOwner() == Hit.GetActor()))
            {
                // hit a barrier, try to step up
                const FVector GravDir(0.f, 0.f, -1.f);
                if (StepUp(GravDir, Delta * (1.f - PercentTimeApplied), Hit, &StepDownResult))
                {
                    // Don't recalculate velocity based on this height adjustment, if considering vertical adjustments.
                    UE_LOG(LogHumanMovement, Verbose, TEXT("+ StepUp (ImpactNormal %s, Normal %s LocalRole = %d "), *Hit.ImpactNormal.ToString(), *Hit.Normal.ToString(), CharacterOwner->GetLocalRole());
                    bJustTeleported |= !bMaintainHorizontalGroundVelocity;
                }
            }
        }
    }

    if (StepDownResult.bComputedFloor)
    {
        CurrentFloor = StepDownResult.FloorResult;
    }
    else
    {
        FindFloor(UpdatedComponent->GetComponentLocation(), CurrentFloor, bZeroDelta, NULL);
        AdjustFloorHeight();
        SetBaseFromFloor(CurrentFloor);
    }

    SaveBaseLocation();
}

void UHumanMovementComponent::InitPlayRootMotion(const TArray<FVector>& RootMotionSouce, float fRate)
{
    RootMotionFrameIndex = 0;
    RootMotionDeltaTime = 0;
    RootMotionTotalDeltaTime = 0;
    RootMotionPlayRate = fRate;
    RootMotionStartCorrectTime = 0.0f;
    RootMotionPositions = RootMotionSouce;

    bPlayingCorrectRootMotion = false;
    bSafeMove = true;
    bResetReplicateMovement = true;
    Velocity = FVector::ZeroVector;
    CharacterOwner->SetReplicateMovement(false);
    IsRootMotionMovement = true;
    IsLerpRotator = false;
    AbortHumanPathMove();
}

void UHumanMovementComponent::UnInitPlayRootMotion()
{
    IsRootMotionMovement = false;
    bPlayingCorrectRootMotion = false;
    RootMotionPlayRate = 1.0f;
    RootMotionStartCorrectTime = 0.0f;
    bSafeMove = true;

    RootMotionPositions.Empty();
    if (bResetReplicateMovement)
    {
        CharacterOwner->SetReplicateMovement(true);
    }
}

void UHumanMovementComponent::TickRootMotion(float DeltaTime)
{
    DeltaTime = DeltaTime * RootMotionPlayRate;

    if (bPlayingCorrectRootMotion)
    {
        TickCorrectRootMotion(DeltaTime);
    }
    else
    {
        TickCommonRootMotion(DeltaTime);
    }
}

void UHumanMovementComponent::TickCommonRootMotion(float DeltaTime)
{
    if (RootMotionFrameIndex >= RootMotionPositions.Num())
    {
        StopRootMotion();
        return;
    }
    DeltaTime *= RootMotionPlayRate;
    RootMotionDeltaTime += DeltaTime;
    RootMotionTotalDeltaTime += DeltaTime;
    float FrameTime = 1.0f / (ONE_SECOND_FRAME * ANIM_ROOT_FRAME_SCALE);

    if (RootMotionDeltaTime > FrameTime)
    {
        RootMotionFrameIndex += RootMotionDeltaTime / FrameTime;
        bool bLastFrame = false;
        if (RootMotionFrameIndex >= RootMotionPositions.Num() - 1)
        {
            bLastFrame = true;
            RootMotionFrameIndex = RootMotionPositions.Num() - 1;
        }
        //RootMotionDeltaTimeTemp = RootMotionDeltaTimeTemp + FrameTime;
        RootMotionDeltaTime = fmod(RootMotionDeltaTime, FrameTime);
        // if (CharacterOwner->GetLocalRole() != ENetRole::ROLE_Authority || bLastFrame)
        {
            FVector NewRelativeLocation = RootMotionPositions[RootMotionFrameIndex];
            FTransform StartTransform = RootMotionStartTransform;
            if (bUseTargetRootMotionStartTransform)
            {
                float Alpha = (RootMotionFrameIndex * FrameTime) / (RootMotionPositions.Num() * FrameTime);
                if (Alpha > 1)
                {
                    Alpha = 1;
                }
                StartTransform.Blend(RootMotionStartTransform, TargetRootMotionStartTransform, Alpha);
                if (IsLerpRotator)
                {
                    FRotator TargetRotator = RootMotionStartTransform.Rotator();
                    FRotator StartRotator = GetCharacterOwner()->GetActorRotation();
                    FRotator LerpRotator = UKismetMathLibrary::RLerp(StartRotator, TargetRotator, Alpha, true);
                    GetCharacterOwner()->SetActorRotation(LerpRotator);
                }
            }

            FVector NewLocation = StartTransform.TransformPosition(NewRelativeLocation);

            if (NewRelativeLocation.Z == 0)
            {
                NewLocation.Z = CharacterOwner->GetActorLocation().Z;
            }
            UE_LOG(LogHumanMovement, Verbose, TEXT("RootMotionMovement OnChangeFrame LocalRole = %d RootMotionFrameIndex = %d RootMotionDeltaTime = %f NewLocation = %s NewRelativeLocation = %s StartLocation %s CurrentLocation %s RootMotionTotalDeltaTime %f"), CharacterOwner->GetLocalRole(), RootMotionFrameIndex, RootMotionDeltaTime, *NewLocation.ToString(), *NewRelativeLocation.ToString(), *(StartTransform.GetLocation().ToString()), *(CharacterOwner->GetActorLocation().ToString()), RootMotionTotalDeltaTime);

            SafeMoveRootMotion(NewLocation, UpdatedComponent->GetComponentQuat(), FrameTime);
            if (bLastFrame)
            {
                StopRootMotion();
                return;
            }
        }
    }

    //if (CharacterOwner->GetLocalRole() != ENetRole::ROLE_Authority)
    {
        FVector LastPosition = RootMotionPositions[RootMotionFrameIndex];
        FVector NextPosition = RootMotionPositions[RootMotionFrameIndex + 1];

        float Alpha = RootMotionDeltaTime / FrameTime;
        FVector NewRelativeLocation = UKismetMathLibrary::VLerp(LastPosition, NextPosition, Alpha);


        //NewTransform.Blend(LastTransform, NextTransform, Alpha);
        FTransform StartTransform = RootMotionStartTransform;
        if (bUseTargetRootMotionStartTransform)
        {
            float StartPositionAlpha = (RootMotionFrameIndex * FrameTime) / (RootMotionPositions.Num() * FrameTime);
            if (StartPositionAlpha > 1)
            {
                StartPositionAlpha = 1;
            }
            StartTransform.Blend(RootMotionStartTransform, TargetRootMotionStartTransform, StartPositionAlpha);
            //UE_LOG(LogHumanMovement, Verbose, TEXT("RootMotionMovement OnTick StartPositionAlpha = %f Time = %f Length = %f"), StartPositionAlpha, RootMotionFrameIndex * FrameTime, RootMotionSequenceLength);
        }

        FVector NewLocation = StartTransform.TransformPosition(NewRelativeLocation);
        if (NewRelativeLocation.Z == 0)
        {
            NewLocation.Z = CharacterOwner->GetActorLocation().Z;
        }
        //UE_LOG(LogHumanMovement, Verbose, TEXT("RootMotionMovement OnTick LocalRole = %d RootMotionFrameIndex = %d RootMotionDeltaTime = %f NewLocation = %s NewRelativeLocation = %s, StartLocation %s"), CharacterOwner->GetLocalRole(), RootMotionFrameIndex, RootMotionDeltaTime, *NewLocation.ToString(), *NewRelativeLocation.ToString(), *(StartTransform.GetLocation().ToString()));
        SafeMoveRootMotion(NewLocation, UpdatedComponent->GetComponentQuat(), RootMotionDeltaTime);
    }
}

void UHumanMovementComponent::TickCorrectRootMotion(float DeltaTime)
{
    RootMotionTotalDeltaTime += DeltaTime;

    bool bLastFrame = false;
    FVector fCurRelativeLocation;

    if (!GetRootMotionRelativeLocationByTime(RootMotionTotalDeltaTime, fCurRelativeLocation, bLastFrame))
    {
        StopRootMotion();
        return;
    }

    if (bLastFrame || RootMotionTotalDeltaTime > RootMotionCorrectTimeRange.Y)
    {
        FVector fTargetLoc = RootMotionFinalTargetTransform.GetLocation();
        FQuat fQuat = RootMotionFinalTargetTransform.GetRotation();

        if (bSafeMove)
        {
            SafeMoveRootMotion(fTargetLoc, fQuat, DeltaTime);
        }
        else
        {
            UpdatedComponent->SetWorldLocationAndRotation(fTargetLoc, fQuat);
        }
        
        StopRootMotion();
        return;
    }
    else
    {
        FTransform FinalTransform;

        if (RootMotionTotalDeltaTime < RootMotionStartCorrectTime) //开始位置的矫正
        {
            float fAlpha = RootMotionTotalDeltaTime / RootMotionStartCorrectTime;

            FTransform StartTransform = RootMotionStartTransform;
            StartTransform.Blend(RootMotionStartTransform, TargetRootMotionStartTransform, fAlpha);

            FVector NewLocation = StartTransform.TransformPosition(fCurRelativeLocation);
            FinalTransform = StartTransform;
            FinalTransform.SetLocation(NewLocation);
        }
        else if (RootMotionTotalDeltaTime >= RootMotionCorrectTimeRange.X && RootMotionTotalDeltaTime <= RootMotionCorrectTimeRange.Y) //最终位置的矫正
        {

            FVector TargetRelativeLocation;
            bool bTemp = false;
            bool bRet = GetRootMotionRelativeLocationByTime(RootMotionCorrectTimeRange.Y, TargetRelativeLocation, bTemp);

            check(bRet);

            FTransform StartTransform = TargetRootMotionStartTransform;
            FVector ExpectTargetLocation = StartTransform.TransformPosition(TargetRelativeLocation);
            FTransform ExpectTargetTransform = StartTransform;
            ExpectTargetTransform.SetLocation(ExpectTargetLocation);

            //-0.1是为了保证在纠正最后能够使falpha = 1。
            float fAlpha = (RootMotionTotalDeltaTime - RootMotionCorrectTimeRange.X) / (RootMotionCorrectTimeRange.Y - RootMotionCorrectTimeRange.X - 0.1f);
            if (fAlpha > 1)
            {
                fAlpha = 1;
            }

            ExpectTargetTransform.Blend(ExpectTargetTransform, RootMotionFinalTargetTransform, fAlpha);

            FVector NewLocation = StartTransform.TransformPosition(fCurRelativeLocation);
            StartTransform.SetLocation(NewLocation);
            StartTransform.Blend(StartTransform, ExpectTargetTransform, fAlpha);
            FinalTransform = StartTransform;
        }
        else //正常不矫正
        {
            FTransform StartTransform = TargetRootMotionStartTransform;
            FVector NewLocation = StartTransform.TransformPosition(fCurRelativeLocation);

            FinalTransform = StartTransform;
            FinalTransform.SetLocation(NewLocation);
        }

        FVector FinalLocation = FinalTransform.GetLocation();
        FQuat FinalQuat = FinalTransform.GetRotation();

        // 旋转由外部镜头系统控制，至少对于攀爬来说是这样。
        FinalQuat = RootMotionFinalTargetTransform.GetRotation();
        if (bSafeMove)
        {
            SafeMoveRootMotion(FinalLocation, FinalQuat, DeltaTime);
        }
        else
        {
            UpdatedComponent->SetWorldLocationAndRotation(FinalLocation, FinalQuat);
        }
    }
}

bool UHumanMovementComponent::GetRootMotionRelativeLocationByTime(float fTimeFromPlayRootMotion, FVector& fCurRelativeLocation, bool& bLastFrame)
{
    float FrameTime = 1.0f / (ONE_SECOND_FRAME * ANIM_ROOT_FRAME_SCALE);

    int nLowIndex = FMath::FloorToInt(fTimeFromPlayRootMotion / FrameTime);

    if (nLowIndex >= RootMotionPositions.Num())
    {
        return false;
    }

    bLastFrame = false;
    if (nLowIndex == RootMotionPositions.Num() - 1)
    {
        bLastFrame = true;
        fCurRelativeLocation = RootMotionPositions[nLowIndex];
    }
    else
    {
        float fAlpha = (fTimeFromPlayRootMotion - (nLowIndex * FrameTime)) / FrameTime;

        FVector LastPosition = RootMotionPositions[nLowIndex];
        FVector NextPosition = RootMotionPositions[nLowIndex + 1];

        fCurRelativeLocation = UKismetMathLibrary::VLerp(LastPosition, NextPosition, fAlpha);
    }

    return true;
}
