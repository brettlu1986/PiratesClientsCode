#include "Components/HumanMountMovementComponent.h"
#include "Common.h"
#include "AIController.h"
#include "Components/HumanMovementComponent.h"

DEFINE_LOG_CATEGORY_STATIC(LogHumanMountMovementComponent, Log, All);

UHumanMountMovementComponent::UHumanMountMovementComponent(const FObjectInitializer& ObjectInitializer)
    :Super(ObjectInitializer)
    , MaxAccelerationSlowDown(100)
    , bIsDead(false)
    , bDeadMoveEnd(false)
    , Driver(nullptr)
    , CollisionCheckBox(FVector(90, 32, 2))
    , CollisionOffset(20)
    , ForwardCollisionOffset(20)
    , bBlocked(false)
    , bInOcean(false)
{
    PrimaryComponentTick.bCanEverTick = true;
    PrimaryComponentTick.bStartWithTickEnabled = false;
    PrimaryComponentTick.TickGroup = TG_PrePhysics;
    bAutoActivate = 0;
    DrawCollisionDebug = EDrawDebugTrace::None;
    LastVelocity = FVector::ZeroVector;
    CollisionRadios = 32;
    CollisionZOffset = 0;
    TotalDistance = 0.f;
    CollisionCheckBoxSlide = FVector(90, 32, 2);
    AdjustPitchForwardCheck = 100;
    AdjustPitchBackCheck = 100;
	LastPawnYaw = 0.f;
	MinOffsetYaw = 0.5f;
}

bool UHumanMountMovementComponent::HandleHit(const FVector& Dir, FHitResult& OutHit)
{
    if (Dir != FVector::ZeroVector)
    {
        FVector StartTrace;


        TArray<AActor*> ActorsToIgnore;
        ActorsToIgnore.Add(PawnOwner);
        if (Driver)
            ActorsToIgnore.Add(Driver);

        FVector ForwardDir = PawnOwner->K2_GetActorRotation().Vector();
        FVector MeshRotation = CharacterOwner->GetMesh()->GetComponentRotation().Vector();
        float FixValue = FVector::DotProduct(ForwardDir, Dir) >= 0 ? 1 : -1;

        ForwardDir.Normalize();
        ForwardDir *= FixValue;

        StartTrace = PawnOwner->GetActorLocation() + ForwardDir * ForwardCollisionOffset;
        StartTrace.Z += CollisionZOffset;

        FVector RealDir = Dir;
        RealDir.Z = MeshRotation.Z * FixValue;
        FVector EndTrace = StartTrace + RealDir * CollisionOffset;

        return UKismetSystemLibrary::SphereTraceSingleForObjects(PawnOwner, StartTrace, EndTrace, CollisionRadios, CollisionObjectTypes, true, ActorsToIgnore, DrawCollisionDebug, OutHit, true);
    }
    return false;
}

bool UHumanMountMovementComponent::HandleDriverHit(const FVector& Dir, FHitResult& OutHit)
{
    if (Dir != FVector::ZeroVector && Driver)
    {

        TArray<AActor*> ActorsToIgnore;
        ActorsToIgnore.Add(PawnOwner);
        ActorsToIgnore.Add(Driver);

        FVector StartTrace = PawnOwner->GetActorLocation();

        StartTrace += DriverCollisionOffset;

        if (UKismetSystemLibrary::CapsuleTraceSingleForObjects(PawnOwner, StartTrace, StartTrace, DriverCollisionRadius, DriverCollisionHalfHeight, CollisionObjectTypes, true, ActorsToIgnore, DrawCollisionDebug, OutHit, true))
        {
            OutHit.ImpactNormal = OutHit.ImpactNormal.GetSafeNormal2D();
            UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("DriverCollision ImpactNormal=%s"), *OutHit.ImpactNormal.ToString());
            if (DrawCollisionDebug != EDrawDebugTrace::None)
            {
                UKismetSystemLibrary::DrawDebugArrow(GWorld, CharacterOwner->GetActorLocation(), CharacterOwner->GetActorLocation() + Dir * 150, 5, FColor::Green, 3, 2);
                UKismetSystemLibrary::DrawDebugArrow(GWorld, OutHit.ImpactPoint, OutHit.ImpactPoint + OutHit.ImpactNormal * 150, 5, FColor::Blue, 3, 2);
            }
            OutHit.bBlockingHit = FVector::DotProduct(Dir, OutHit.ImpactNormal) < 0;
        }

        return OutHit.bBlockingHit;
    }
    return false;
}

void UHumanMountMovementComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction * ThisTickFunction)
{
    FHitResult HitResult;
    if (PawnOwner && PawnOwner->GetLocalRole() == ROLE_AutonomousProxy)
    {
        if (!CharacterOwner->Controller)
        {
            PawnOwner->SetRole(ROLE_SimulatedProxy);
            //UE_LOG(LogHumanMountMovementComponent, Error, TEXT("Vehicle Controller and GetLocalRole() is Error."));
            return;
        }
        FVector Dir = GetPendingInputVector();
        Dir.Normalize();
        bBlocked = false;
    }
    else if(PawnOwner && PawnOwner->GetLocalRole() == ROLE_SimulatedProxy)
    {
        if (Driver && CharacterOwner->Controller)
        {
            // 偶现人骑马时, 服务器将RemoteRole设为Autonomous后, 客户端Role未同步为Autonomous. 此时会导致马无法移动. 手动设置一下以解决这个问题.
            PawnOwner->SetRole(ROLE_AutonomousProxy);
            // 然后要把bWasSimulatingRootMotion清掉，不然下马位置会出问题
            bWasSimulatingRootMotion = false;
            UE_LOG(LogHumanMountMovementComponent, Log, TEXT("Manually setting vehicle local role from simulated to autonomous."));
        }
    }


    if (!IsNetMode(NM_Client) && !CharacterOwner->Controller && CharacterOwner->GetLocalRole() == ROLE_Authority)
    {
        if (bInOcean)
        {
            if (!bIsFrightened)
            {
                ConsumeInputVector();
                Velocity = FVector::ZeroVector;
                bBlocked = true;
                return;
            }
            else if(bBlocked)
            {
                bBlocked = false;
            }
        }

        if (LastVelocity.IsNearlyZero() && !Velocity.IsNearlyZero())
        {
            bRunPhysicsWithNoController = true;
            LastVelocity = Velocity;
            //UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("LastVelocity=Velocity, Last %s, Vel = %s"), *LastVelocity.ToString(), *Velocity.ToString());
        }

        if (/*(bIsDead && !bDeadMoveEnd) || */bIsFrightened)
        {
            float MaxSpeed = GetMaxSpeed();
            MaxSpeed = MaxSpeed * AnalogInputModifier;
            Velocity += CharacterOwner->GetActorRotation().Vector() * MaxSpeed * DeltaTime;
            FRotator rotator = CharacterOwner->GetActorRotation();

            Velocity = Velocity.GetClampedToMaxSize(MaxSpeed);
            LastVelocity = Velocity;
            //UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("Velocity %s MaxSpeed %f AnalogInputModifier %f DeltaTime %f GetActorRotation %s"), *Velocity.ToString(), MaxSpeed, AnalogInputModifier, DeltaTime, *rotator.ToString());
        }
        else if (LastVelocity.SizeSquared2D() > SMALL_NUMBER)
        {
            const float MaxAccel = MaxAccelerationSlowDown;
            float Z = Velocity.Z;
            Acceleration = MaxAccel * Velocity.GetSafeNormal()* DeltaTime;

            if (LastVelocity.SizeSquared2D() < Acceleration.SizeSquared2D())
            {
                bRunPhysicsWithNoController = false;
                LastVelocity = FVector::ZeroVector;
            }
            else
            {
                LastVelocity -= Acceleration;
            }
            LastVelocity.Z = Z;
            //UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("Velocity =%s, LastVelocity=%s, Acceleration=%s, Velocity Angle = %f, Forward angle = %f"), *Velocity.ToString(), *LastVelocity.ToString(), *Acceleration.ToString(), FMath::Acos(FVector::DotProduct(LastVelocity.GetSafeNormal(), Velocity.GetSafeNormal())), FMath::Acos(FVector::DotProduct(LastVelocity.GetSafeNormal(), CharacterOwner->GetActorForwardVector().GetSafeNormal())));
            Velocity = LastVelocity;
        }
        else if (FMath::Abs(LastVelocity.Z) > SMALL_NUMBER)
        {
            LastVelocity.Z = 0;
            Velocity = LastVelocity;
        }
    }

    UCharacterMovementComponent::TickComponent(DeltaTime, TickType, ThisTickFunction);
}


void UHumanMountMovementComponent::SimulateMovement(float DeltaSeconds)
{
    if (!HasValidData() || UpdatedComponent->Mobility != EComponentMobility::Movable || UpdatedComponent->IsSimulatingPhysics())
    {
        return;
    }

    const bool bIsSimulatedProxy = (CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy);

    // Workaround for replication not being updated initially
    if (bIsSimulatedProxy &&
        CharacterOwner->GetReplicatedMovement().Location.IsZero() &&
        CharacterOwner->GetReplicatedMovement().Rotation.IsZero() &&
        CharacterOwner->GetReplicatedMovement().LinearVelocity.IsZero())
    {
        return;
    }

    // If base is not resolved on the client, we should not try to simulate at all
    if (CharacterOwner->GetReplicatedBasedMovement().IsBaseUnresolved())
    {
        UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("Base for simulated character '%s' is not resolved on client, skipping SimulateMovement"), *CharacterOwner->GetName());
        // 模拟移动时，有时候会找不到base，所以在这里主动去设置一下。
        if (MovementMode == MOVE_Walking)
        {
            if (CurrentFloor.IsWalkableFloor())
            {
                SetBaseFromFloor(CurrentFloor);
                AdjustFloorHeight();
                UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("%s reset base from floor"), *CharacterOwner->GetName());
            }
            else
            {
                FindFloor(UpdatedComponent->GetComponentLocation(), CurrentFloor, false);
                UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("%s update floor from adjustment."), *CharacterOwner->GetName());
            }
            // Adjust after find floor
            AdjustRotationMatchSlope(DeltaSeconds);
        }
        return;
    }

    UCharacterMovementComponent::SimulateMovement(DeltaSeconds);

    if (!Driver && CharacterOwner->GetReplicatedMovement().LinearVelocity.IsZero() && bNetworkSmoothingComplete)
    {
        UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("SimulateMovement, forcing %s to stop because server do not have velocity."), *CharacterOwner->GetName());
        Velocity = FVector::ZeroVector;
    }


    // Adjust after find floor
    AdjustRotationMatchSlope(DeltaSeconds);
}

bool UHumanMountMovementComponent::CheckCanSlide(const FVector& Dir)
{
    FVector PawnOwnerLocation = PawnOwner->GetActorLocation();
    FVector BoxStartTrace = PawnOwnerLocation + Dir.GetSafeNormal() * (CollisionCheckBoxSlide.X / 2);
    FVector HalfCollisionCheckBoxSlide = CollisionCheckBoxSlide;
    HalfCollisionCheckBoxSlide.X /= 2;
    TArray<AActor*> ActorsToIgnore;

    if(Driver)
        ActorsToIgnore.Add(Driver);
    FHitResult HitResult;
    TArray<TEnumAsByte<EObjectTypeQuery> >  ObjectTypes;
    ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));

    if (UKismetSystemLibrary::BoxTraceSingleForObjects(PawnOwner, BoxStartTrace, BoxStartTrace, HalfCollisionCheckBoxSlide, Dir.Rotation(), ObjectTypes, false, ActorsToIgnore, DrawCollisionDebug, HitResult, true))
    {
        return false;
    }

    return true;
}

void UHumanMountMovementComponent::MoveAlongFloor(const FVector& InVelocity, float DeltaSeconds, FStepDownResult* OutStepDownResult)
{
    if (!CurrentFloor.IsWalkableFloor())
    {
        return;
    }

    // Move along the current floor
    const FVector Delta = FVector(InVelocity.X, InVelocity.Y, 0.f) * DeltaSeconds;
    FHitResult Hit(1.f);
    FHitResult DriverHit(1.f);
    FVector Dir = InVelocity;
    Dir.Normalize();
    HandleHit(Dir, Hit);
    HandleDriverHit(Dir, DriverHit);
    FVector RampVector = ComputeGroundMovementDelta(Delta, CurrentFloor.HitResult, CurrentFloor.bLineTrace);

    if (!(Hit.bBlockingHit || DriverHit.bBlockingHit) || (!Driver && CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy && !bIsFrightened))
    {
        SafeMoveUpdatedComponent(RampVector, UpdatedComponent->GetComponentQuat(), true, Hit);
        UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("MoveAlongFloor, SafeMoveUpdatedComponent, GetLocalRole() = %d, RampVector = %s, current location = %s, current speed = %f."), CharacterOwner->GetLocalRole(), *RampVector.ToString(), *CharacterOwner->GetActorLocation().ToString(), Velocity.Size());
    }
    else if (Hit.bBlockingHit != DriverHit.bBlockingHit)
    {
        if (DriverHit.bBlockingHit)
        {
            Hit = DriverHit;
        }

        if (!Driver && !IsNetMode(NM_Client) && CharacterOwner->GetLocalRole() == ROLE_Authority && !bIsFrightened)
        {
            Velocity = FVector::ZeroVector;
            if (CharacterOwner->Controller)
            {
                AAIController* AIController = Cast<AAIController>(CharacterOwner->Controller);
                if (AIController)
                {
                    AIController->StopMovement();
                    AIController->OnMoveCompleted(FAIRequestID::CurrentRequest, FPathFollowingResult(EPathFollowingResult::Aborted));
                }
            }
            return;
        }
        // 要求撞到障碍物之后不降低速度, 将bJustTeleported设为true以跳过CharacterMovementComponent::PhysWalking中基于实际位移重新计算速度。
        bJustTeleported = true;
        HandleImpact(Hit);

        FVector SlideDelta = ComputeSlideVector(Delta, 1.f, Hit.Normal, Hit);

        if ((Driver != nullptr || bIsFrightened) && CheckCanSlide(SlideDelta))
        {
            SlideAlongSurface(Delta, 1.f, Hit.Normal, Hit, true);
        }

        return;
    }
    else
    {
        bJustTeleported = true;
        HandleImpact(Hit);
        HandleImpact(DriverHit);
        return;
    }

    /*以下是CharacterMovementComponent中的逻辑*/
    float LastMoveTimeSlice = DeltaSeconds;

    if (Hit.bStartPenetrating)
    {
        // Allow this hit to be used as an impact we can deflect off, otherwise we do nothing the rest of the update and appear to hitch.
        HandleImpact(Hit);
        SlideAlongSurface(Delta, 1.f, Hit.Normal, Hit, true);

        if (Hit.bStartPenetrating)
        {
            OnCharacterStuckInGeometry(&Hit);
        }
    }
    else if (Hit.IsValidBlockingHit())
    {
        // We impacted something (most likely another ramp, but possibly a barrier).
        float PercentTimeApplied = Hit.Time;
        if ((Hit.Time > 0.f) && (Hit.Normal.Z > KINDA_SMALL_NUMBER) && IsWalkable(Hit))
        {
            // Another walkable ramp.
            const float InitialPercentRemaining = 1.f - PercentTimeApplied;
            RampVector = ComputeGroundMovementDelta(Delta * InitialPercentRemaining, Hit, false);
            LastMoveTimeSlice = InitialPercentRemaining * LastMoveTimeSlice;
            SafeMoveUpdatedComponent(RampVector, UpdatedComponent->GetComponentQuat(), true, Hit);

            const float SecondHitPercent = Hit.Time * InitialPercentRemaining;
            PercentTimeApplied = FMath::Clamp(PercentTimeApplied + SecondHitPercent, 0.f, 1.f);
        }

        if (Hit.IsValidBlockingHit())
        {
            if (CanStepUp(Hit) || (CharacterOwner->GetMovementBase() != NULL && CharacterOwner->GetMovementBase()->GetOwner() == Hit.GetActor()))
            {
                // hit a barrier, try to step up
                const FVector GravDir(0.f, 0.f, -1.f);
                if (!StepUp(GravDir, Delta * (1.f - PercentTimeApplied), Hit, OutStepDownResult))
                {
                    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("- StepUp (ImpactNormal %s, Normal %s"), *Hit.ImpactNormal.ToString(), *Hit.Normal.ToString());
                    HandleImpact(Hit, LastMoveTimeSlice, RampVector);
                    SlideAlongSurface(Delta, 1.f - PercentTimeApplied, Hit.Normal, Hit, true);
                }
                else
                {
                    // Don't recalculate velocity based on this height adjustment, if considering vertical adjustments.
                    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("+ StepUp (ImpactNormal %s, Normal %s"), *Hit.ImpactNormal.ToString(), *Hit.Normal.ToString());
                    bJustTeleported |= !bMaintainHorizontalGroundVelocity;
                }
            }
            else if (Hit.Component.IsValid() && !Hit.Component.Get()->CanCharacterStepUp(CharacterOwner))
            {
                HandleImpact(Hit, LastMoveTimeSlice, RampVector);
                SlideAlongSurface(Delta, 1.f - PercentTimeApplied, Hit.Normal, Hit, true);
            }
        }
    }
}


// For custom jump.
void UHumanMountMovementComponent::SetHumanMountFallConfig(const FHumanMountFallConfig& InConfig)
{
    HumanMountFallConfig = InConfig;
    GravityScale = HumanMountFallConfig.CustomGravityScale;
    JumpZVelocity = HumanMountFallConfig.JumpZVelocity;
}

FHumanMountFallConfig UHumanMountMovementComponent::GetHumanMountFallConfig()
{
    return HumanMountFallConfig;
}

void UHumanMountMovementComponent::CalcFallingVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration)
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
        CurrentFallingLateralAcceleration += HumanMountFallConfig.LateralAcceleration * DeltaTime;
    }
    else
    {
        CurrentFallingLateralAcceleration = 0;
    }

    // Apply acceleration
    const float NewMaxSpeed = (IsExceedingMaxSpeed(MaxSpeed)) ? Velocity.Size() : MaxSpeed;

    FVector ActualAcceleration = AccelDir * CurrentFallingLateralAcceleration - Velocity.GetSafeNormal() * HumanMountFallConfig.AirDragCoefficient;
    Velocity += ActualAcceleration * DeltaTime;
    Velocity = Velocity.GetClampedToMaxSize(NewMaxSpeed);

    // stop if will collide with world static to avoid stuck
    FVector Dir = Velocity.IsZero() ? CharacterOwner->GetActorForwardVector() : Velocity;
    if (!CheckJumpCanMoveForward(Dir))
    {
        Velocity = FVector::ZeroVector;
    }

    if (bUseRVOAvoidance)
    {
        CalcAvoidanceVelocity(DeltaTime);
    }
}

bool UHumanMountMovementComponent::CheckJumpCanMoveForward(const FVector& Dir)
{
    FVector PawnOwnerLocation = PawnOwner->GetActorLocation();
    FVector BoxStartTrace = PawnOwnerLocation + Dir.GetSafeNormal() * (JumpCollisionCheckBox.X / 2);
    FVector HalfCollisionCheckBoxJump = JumpCollisionCheckBox;
    HalfCollisionCheckBoxJump.X /= 2;

    TArray<AActor*> ActorsToIgnore;
    if (Driver)
    {
        ActorsToIgnore.Add(Driver);
    }

    TArray<TEnumAsByte<EObjectTypeQuery> >  ObjectTypes;
    ObjectTypes.Add(UEngineTypes::ConvertToObjectType(ECollisionChannel::ECC_WorldStatic));

    FHitResult HitResult;

    if (UKismetSystemLibrary::BoxTraceSingleForObjects(PawnOwner, BoxStartTrace, BoxStartTrace, HalfCollisionCheckBoxJump, Dir.Rotation(), ObjectTypes, false, ActorsToIgnore, DrawCollisionDebug, HitResult, true))
    {
        UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("CheckJumpCanMoveForward Returns false. PawnOwnerLocation=%s, Dir=%s"), *PawnOwnerLocation.ToString(), *Dir.ToString());
        return false;
    }
    return true;
}
// For custom jump end.

void UHumanMountMovementComponent::CalcVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration)
{

    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("CalcVelocity, Velocity=%s, Acceleration=%s, IsFalling=%d, bIsFrightened=%d"), *Velocity.ToString(), *Acceleration.ToString(), IsFalling(), bIsFrightened);
    if (!CharacterOwner->Controller)
    {
        if (!CharacterOwner->Controller && CharacterOwner->GetLocalRole() == ROLE_Authority && !bIsFrightened)
        {
            LastVelocity.Z = Velocity.Z;
            Velocity = LastVelocity;
            return;
        }
        UCharacterMovementComponent::CalcVelocity(DeltaTime, Friction, bFluid, BrakingDeceleration);
        return;
    }


    if (IsFalling())
    {
        CalcFallingVelocity(DeltaTime, Friction, bFluid, BrakingDeceleration);
        return;
    }

    UCharacterMovementComponent::CalcVelocity(DeltaTime, Friction, bFluid, BrakingDeceleration);
    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("CalcVelocity %s Acceleration %s"), *Velocity.ToString(), *Acceleration.ToString());
    return;
}


void UHumanMountMovementComponent::SmoothCorrection(const FVector& OldLocation, const FQuat& OldRotation, const FVector& NewLocation, const FQuat& NewRotation)
{

    //return UCharacterMovementComponent::SmoothCorrection(OldLocation, OldRotation, NewLocation, NewRotation);
    UE_LOG(LogHumanMountMovementComponent, Verbose,  TEXT("Vehicle OldLocation %s NewLocation %s"), *OldLocation.ToString(), *NewLocation.ToString());
 //   UE_LOG(LogHumanMountMovementComponent, Log, TEXT("Vehicle  OldBaseLocation%s ReplicatedBasedMovement.Location %s"), *OldBaseLocation.ToString(), *(CharacterOwner->GetReplicatedBasedMovement().Location.ToString()))
    //if (!CharacterOwner->Controller && !LastRotation.IsZero())
    //{

    //    //UE_LOG(LogHumanMountMovementComponent, Log, TEXT("Vehicle OldRotation %s NewRotation %s ActorRotation()%s"), *OldRotation.ToString(), *NewRotation.ToString(), *LastRotation.ToString());
    //    UCharacterMovementComponent::SmoothCorrection(OldLocation, OldRotation, NewLocation, FQuat(LastRotation));
    //}
    //else
    {
        //UCharacterMovementComponent::SmoothCorrection(OldLocation, OldRotation, NewLocation, NewRotation);

        if (!HasValidData())
        {
            return;
        }

        // We shouldn't be running this on a server that is not a listen server.
        if (GetNetMode() == NM_DedicatedServer || GetNetMode() == NM_Standalone)
        {
            return;
        }

        // Only client proxies or remote clients on a listen server should run this code.
        const bool bIsSimulatedProxy = (CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy);
        const bool bIsRemoteAutoProxy = (CharacterOwner->GetRemoteRole() == ROLE_AutonomousProxy);
        ensure(bIsSimulatedProxy || bIsRemoteAutoProxy);

        // Getting a correction means new data, so smoothing needs to run.
        bNetworkSmoothingComplete = false;

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

            FVector InterpLocation = OldLocation;
            FVector NewToOldVector = (OldLocation - NewLocation);
            bool bForceCorrection = true;
            if (!CharacterOwner->GetReplicatedBasedMovement().IsBaseUnresolved())
            {
                float NewDistSq = NewToOldVector.SizeSquared();
                bForceCorrection = false;
                float InterpDist1 = 400.f;
                float InterpDist2 = 10000.f;
                float InterpDist3 = 40000.f;
                float InterpDist4 = 160000.f;
                float MaxSmoothTime = 0.01f;
                if (NewDistSq > InterpDist1 && NewDistSq < InterpDist2)
                {
                    SmoothCorrectionDirection = NewLocation;
                    MaxSmoothTime = 0.5 / GEngine->GetMaxFPS();
                    InterpLocation = FMath::VInterpConstantTo(OldLocation, NewLocation, MaxSmoothTime, MaxWalkSpeed);
                    SmoothMoveLerpRate = 0.1f;
                    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("/// %s SmoothCorrection linear interp 1 dis=(%.2f)"), *GetNameSafe(CharacterOwner), FMath::Sqrt(NewDistSq));
                }
                else if (NewDistSq >= InterpDist2 && NewDistSq < InterpDist3)
                {
                    SmoothCorrectionDirection = NewLocation;
                    MaxSmoothTime = 1 / GEngine->GetMaxFPS();
                    InterpLocation = FMath::VInterpConstantTo(OldLocation, NewLocation, MaxSmoothTime, MaxWalkSpeed);
                    SmoothMoveLerpRate = 0.3f;
                    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("/// %s SmoothCorrection linear interp 2 dis=(%.2f)"), *GetNameSafe(CharacterOwner), FMath::Sqrt(NewDistSq));
                }
                else if (NewDistSq >= InterpDist3 && NewDistSq < InterpDist4)
                {
                    SmoothCorrectionDirection = NewLocation;
                    MaxSmoothTime = 1.5 / GEngine->GetMaxFPS();
                    InterpLocation = FMath::VInterpConstantTo(OldLocation, NewLocation, MaxSmoothTime, MaxWalkSpeed);
                    SmoothMoveLerpRate = 0.3f;
                    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("/// %s SmoothCorrection linear interp 3 dis=(%.2f)"), *GetNameSafe(CharacterOwner), FMath::Sqrt(NewDistSq));
                }
                //else if (NewDistSq >= InterpDist4)
                //{
                //    SmoothCorrectionDirection = FVector::ZeroVector;
                //    InterpLocation = NewLocation;
                //    SmoothMoveLerpRate = 0.1f;
                //    bForceCorrection = true;
                //    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("/// %s SmoothCorrection linear interp 4 dis=(%.2f)"), *GetNameSafe(CharacterOwner), FMath::Sqrt(NewDistSq));
                //}
                else
                {
                    SmoothCorrectionDirection = FVector::ZeroVector;
                    InterpLocation = NewLocation;
                    SmoothMoveLerpRate = 0.1f;
                    bForceCorrection = true;
                    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("/// %s SmoothCorrection linear interp dis=(%.2f)"), *GetNameSafe(CharacterOwner), FMath::Sqrt(NewDistSq));
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

            UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("Proxy %s SmoothCorrection(%.2f)"), *GetNameSafe(CharacterOwner), FMath::Sqrt(DistSq));
            if (NetworkSmoothingMode == ENetworkSmoothingMode::Linear)
            {
                ClientData->OriginalMeshTranslationOffset = ClientData->MeshTranslationOffset;

                // Remember the current and target rotation, we're going to lerp between them
                ClientData->OriginalMeshRotationOffset = OldRotation;
                ClientData->MeshRotationOffset = OldRotation;
                ClientData->MeshRotationTarget = NewRotation;

                // Move the capsule, but not the mesh.
                // Note: we don't change rotation, we lerp towards it in SmoothClientPosition.
//                 if (NewLocation != OldLocation)
//                 {
//                     const FScopedPreventAttachedComponentMove PreventMeshMove(CharacterOwner->GetMesh());
//                     UpdatedComponent->SetWorldLocation(NewLocation, false, nullptr, GetTeleportType());
//                 }
                if (InterpLocation != OldLocation && (bForceCorrection || (Acceleration != FVector::ZeroVector && Velocity != FVector::ZeroVector)))
                {
                    const FScopedPreventAttachedComponentMove PreventMeshMove(CharacterOwner->GetMesh());
                    auto moveloc = InterpLocation - OldLocation;
                    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("/// %s SmoothCorrection linear interp dis=(%.2f) - (%.2f), vel=%s, acc=%s, move=%s"), *GetNameSafe(CharacterOwner), FMath::Sqrt((NewLocation - OldLocation).SizeSquared()), FMath::Sqrt(DistSq),
                        *Velocity.ToString(), *Acceleration.ToString(), *moveloc.ToString());
                    UpdatedComponent->SetWorldLocation(InterpLocation, false, nullptr, GetTeleportType());
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

                UE_LOG(LogHumanMountMovementComponent, VeryVerbose, TEXT("SmoothCorrection: Pull back client from ClientTimeStamp: %.6f to %.6f, ServerTimeStamp: %.6f for %s"),
                    OldClientTimeStamp, ClientData->SmoothingClientTimeStamp, ClientData->SmoothingServerTimeStamp, *GetNameSafe(CharacterOwner));
            }

            // Using server timestamp lets us know how much time actually elapsed, regardless of packet lag variance.
            double OldServerTimeStamp = ClientData->SmoothingServerTimeStamp;
            ClientData->SmoothingServerTimeStamp = (bIsSimulatedProxy ? CharacterOwner->GetReplicatedServerLastTransformUpdateTimeStamp() : ServerLastTransformUpdateTimeStamp);

            // Initial update has no delta.
            if (ClientData->LastCorrectionTime == 0)
            {
                ClientData->SmoothingClientTimeStamp = ClientData->SmoothingServerTimeStamp;
                OldServerTimeStamp = ClientData->SmoothingServerTimeStamp;
            }

            // Don't let the client fall too far behind or run ahead of new server time.
            const double ServerDeltaTime = ClientData->SmoothingServerTimeStamp - OldServerTimeStamp;
            const double MaxDelta = FMath::Clamp(ServerDeltaTime * 1.25, 0.0, ClientData->MaxMoveDeltaTime * 2.0);
            ClientData->SmoothingClientTimeStamp = FMath::Clamp(ClientData->SmoothingClientTimeStamp, ClientData->SmoothingServerTimeStamp - MaxDelta, ClientData->SmoothingServerTimeStamp);

            // Compute actual delta between new server timestamp and client simulation.
            ClientData->LastCorrectionDelta = ClientData->SmoothingServerTimeStamp - ClientData->SmoothingClientTimeStamp;
            ClientData->LastCorrectionTime = MyWorld->GetTimeSeconds();

            UE_LOG(LogHumanMountMovementComponent, VeryVerbose, TEXT("SmoothCorrection: WorldTime: %.6f, ServerTimeStamp: %.6f, ClientTimeStamp: %.6f, Delta: %.6f for %s"),
                MyWorld->GetTimeSeconds(), ClientData->SmoothingServerTimeStamp, ClientData->SmoothingClientTimeStamp, ClientData->LastCorrectionDelta, *GetNameSafe(CharacterOwner));
        }
    }
}

void UHumanMountMovementComponent::MoveSmooth(const FVector& InVelocity, const float DeltaSeconds, FStepDownResult* OutStepDownResult /*= NULL*/)
{

    return UCharacterMovementComponent::MoveSmooth(InVelocity, DeltaSeconds, OutStepDownResult);
    float deltaTime = DeltaSeconds;
    if (deltaTime > 0.04f)
    {
        deltaTime = 0.04f;
    }

    FVector thisVelocity = InVelocity;
    FVector OldLocation = UpdatedComponent->GetComponentLocation();
    if (SmoothCorrectionDirection != FVector::ZeroVector)
    {
        FVector CorrectionLocation = SmoothCorrectionDirection - OldLocation;
        float DistSq = CorrectionLocation.SizeSquared();
        if (FMath::Sqrt(DistSq) > 40.f && InVelocity != FVector::ZeroVector)
        {
            if ((CorrectionLocation | thisVelocity) > 0.f)
            {
                FVector InterpLocation = FMath::VInterpConstantTo(OldLocation, SmoothCorrectionDirection, 0.033f, MaxWalkSpeed) - OldLocation;
                thisVelocity += InterpLocation * SmoothMoveLerpRate;
                UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("%s movesmooth DistSq=%f, vel = %s, oldvel=%s, Interp = %s, oldvel=%s"),
                    *GetNameSafe(CharacterOwner), FMath::Sqrt(DistSq), *thisVelocity.ToString(), *InVelocity.ToString(), *InterpLocation.GetSafeNormal2D().ToString(), *Velocity.ToString());
            }
            else
            {
                UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("%s movesmooth reset, old=%s, new=%s, vel=%s, oldvel=%s"),
                    *GetNameSafe(CharacterOwner), *OldLocation.ToString(), *SmoothCorrectionDirection.ToString(), *InVelocity.ToString(), *Velocity.ToString());
                SmoothCorrectionDirection = FVector::ZeroVector;
                thisVelocity = FVector::ZeroVector;
                Velocity = thisVelocity;
            }
        }
        else if (InVelocity == FVector::ZeroVector)
        {
            if (FMath::Sqrt(DistSq) > 5.f)
            {
                FVector InterpLocation = FMath::VInterpConstantTo(OldLocation, SmoothCorrectionDirection, 0.033f, MaxWalkSpeed) - OldLocation;
                thisVelocity = InterpLocation / 0.033f;
                thisVelocity.Z = InVelocity.Z;
                UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("%s movesmooth vel=%s, oldvel=%s"), *GetNameSafe(CharacterOwner), *thisVelocity.ToString(), *Velocity.ToString());
                Velocity = thisVelocity;
            }
            else
            {
                UpdatedComponent->SetWorldLocation(SmoothCorrectionDirection, false, nullptr, GetTeleportType());
                SmoothCorrectionDirection = FVector::ZeroVector;
                thisVelocity = FVector::ZeroVector;
                Velocity = thisVelocity;
                UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("%s movesmooth SetWorldLocation dis=%f, oldvel=%s"), *GetNameSafe(CharacterOwner), FMath::Sqrt(DistSq), *Velocity.ToString());
                //return;
            }
        }
        thisVelocity.Z = InVelocity.Z;
    }

    UCharacterMovementComponent::MoveSmooth(thisVelocity, deltaTime, OutStepDownResult);

//     if (thisVelocity != FVector::ZeroVector)
//     {
//         auto newloc = UpdatedComponent->GetComponentLocation();
//         auto moveloc = newloc - OldLocation;
//         UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("%s movesmooth new=%s, old=%s, move=%s"), *GetNameSafe(CharacterOwner), *newloc.ToString(), *OldLocation.ToString(), *moveloc.ToString());
//     }
}


void UHumanMountMovementComponent::PerformMovement(float DeltaTime)
{
    AdjustRotationMatchSlope(DeltaTime);
    FVector OldLocation = UpdatedComponent->GetComponentLocation();
    UCharacterMovementComponent::PerformMovement(DeltaTime);
    if (CharacterOwner && CharacterOwner->GetLocalRole() == ROLE_Authority)
    {
        FVector LocDiff = UpdatedComponent->GetComponentLocation() - OldLocation;
        if (LocDiff != FVector::ZeroVector)
        {
            TotalDistance += FMath::Sqrt(LocDiff.SizeSquared());
        }
    }
}

void UHumanMountMovementComponent::SetActorLocationAndUpdateBasedMovement(FVector NewLocation)
{
    CharacterOwner->SetActorLocation(NewLocation);
    SaveBaseLocation();
}

void UHumanMountMovementComponent::AdjustRotationMatchSlope(float DeltaTime)
{
    AdjustRotationMatchSlope(DeltaTime, CurrentFloor.HitResult);
}

void UHumanMountMovementComponent::AdjustRotationMatchSlope(float DeltaTime, const FHitResult HitResult)
{
    if (!IsWalking())
        return;

    const FVector UpVector = CharacterOwner->GetActorUpVector();
    if (DrawCollisionDebug != EDrawDebugTrace::None)
    {
        UKismetSystemLibrary::DrawDebugArrow(GWorld, CharacterOwner->GetActorLocation(), CharacterOwner->GetActorLocation() + UpVector * 150, 5, FColor::Emerald, 3, 2);
        UKismetSystemLibrary::DrawDebugArrow(GWorld, HitResult.ImpactPoint, HitResult.ImpactPoint + HitResult.Normal * 150, 5, FColor::Purple, 3, 2);
    }
    FVector RotationAxis = FVector::CrossProduct(UpVector, HitResult.Normal);
    RotationAxis.Normalize();
    float RotationAngleRad = FMath::Acos(FVector::DotProduct(UpVector, HitResult.Normal));
    FRotator OldRotation = CharacterOwner->GetMesh()->GetRelativeRotation();
    if (FMath::IsNearlyZero(RotationAngleRad) && FMath::IsNearlyZero(OldRotation.Pitch))
    {
        return;
    }
    FQuat Quat = FQuat(RotationAxis, RotationAngleRad);
    FQuat NewQuat = Quat * CharacterOwner->GetActorQuat();
    FRotator NewRotator = NewQuat.Rotator();
    OldRotation.Roll = 0;
    float DeltaPitch = NewRotator.Pitch - OldRotation.Pitch;
    float AdjustmentPitch = AdjustRotationRate;



    if (!Driver)
    {
        OldRotation.Pitch = NewRotator.Pitch;
    }
    else if (DeltaPitch > AdjustmentPitch)
    {
        OldRotation.Pitch += AdjustmentPitch;
    }
    else if (DeltaPitch < -AdjustmentPitch)
    {
        OldRotation.Pitch -= AdjustmentPitch;
    }

    CharacterOwner->GetMesh()->SetRelativeRotation(OldRotation);
}

void UHumanMountMovementComponent::SetHumanMountMovementConfig(const FHumanMountMovementConfig &InHumanMountMovementConfig)
{
    HumanMountMovementConfig = InHumanMountMovementConfig;
}

void UHumanMountMovementComponent::ResetNetworkSmoothingComplete()
{
    bNetworkSmoothingComplete = true;
}

void UHumanMountMovementComponent::ResetLastVelocity()
{
    LastVelocity = FVector::ZeroVector;
}

void UHumanMountMovementComponent::ClearDriverBase(ACharacter* InDriver)
{
    if (InDriver)
    {
        InDriver->SetBase(nullptr);
        UHumanMovementComponent *HumanMovement = Cast<UHumanMovementComponent>(InDriver->GetCharacterMovement());
        if (HumanMovement)
        {
            HumanMovement->CurrentFloor = CurrentFloor;
        }
    }
}

bool UHumanMountMovementComponent::CheckNeedStop(float InAxisValue, float CurrentSpeed)
{
    if (InAxisValue < 0 && CurrentAxisValue > 0 && CurrentSpeed > 0)
    {
        if (!bImmediateStopReady && CurrentAxisValue > HumanMountMovementConfig.ImmediateStopReadySpeed)
        {
            bImmediateStopReady = true;
            bImmediateStopTriggered = false;
        }
    }
    else
    {
        bImmediateStopReady = false;
        bImmediateStopTriggered = false;
    }

    if (bImmediateStopReady && CurrentAxisValue < HumanMountMovementConfig.TriggerImmediateStopSpeed)
    {
        bImmediateStopTriggered = true;
        bImmediateStopReady = false;
    }
    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("CheckNeedStop, In=%f, Cur=%f, Speed=%f, read=%d, triggered=%d"), InAxisValue, CurrentAxisValue, CurrentSpeed, bImmediateStopReady, bImmediateStopTriggered);
    return bImmediateStopTriggered;
}

float UHumanMountMovementComponent::CalcAxisValueInterpolation(float InAxisValue)
{
    float AxisValueInterpolation = HumanMountMovementConfig.ForwardAccelerateCoefficient;

    if (InAxisValue > 0)
    {
        if (CurrentAxisValue < 0)
        {
            AxisValueInterpolation = HumanMountMovementConfig.BackwardBrakeDecelerateCoefficient;
        }
    }
    else if (InAxisValue < 0)
    {
        if (CurrentAxisValue > 0)
        {
            AxisValueInterpolation = HumanMountMovementConfig.ForwardBrakeDecelerateCoefficient;
        }
        else
        {
            AxisValueInterpolation = HumanMountMovementConfig.BackwardAccelerateCoefficient;
        }
    }
    else
    {
        if (CurrentAxisValue >= 0)
        {
            AxisValueInterpolation = HumanMountMovementConfig.ForwardNaturalDecelerateCoefficient;
        }
        else
        {
            AxisValueInterpolation = HumanMountMovementConfig.BackwardNaturalDecelerateCoefficient;
        }
    }

    return AxisValueInterpolation;
}

float UHumanMountMovementComponent::LerpAxisValue(float InAxisValue, float DeltaTime)
{
    float CurrentSpeed = Velocity.Size2D();
    if (FMath::Abs(CurrentAxisValue - InAxisValue) < SMALL_NUMBER)
    {
        CurrentAxisValue = InAxisValue;
        return CurrentAxisValue;
    }

    if (CheckNeedStop(InAxisValue, CurrentSpeed))
    {
        CurrentAxisValue = 0;
        return CurrentAxisValue;
    }

    float AxisValueInterpolation = CalcAxisValueInterpolation(InAxisValue);
    const float FixValue = InAxisValue >= CurrentAxisValue ? 1 : -1;
    AxisValueInterpolation *= FixValue;
    UE_LOG(LogHumanMountMovementComponent, Verbose, TEXT("LerpAxisValue, In=%f, Cur=%f, AxisValueInterpolation=%f"), InAxisValue, CurrentAxisValue, AxisValueInterpolation);

    float ResultAxisValue = CurrentAxisValue + AxisValueInterpolation * DeltaTime;

    if (InAxisValue > 0 && ResultAxisValue > InAxisValue)
    {
        ResultAxisValue = InAxisValue;
    }
    else if (InAxisValue < 0 && ResultAxisValue < InAxisValue)
    {
        ResultAxisValue = InAxisValue;
    }
    else if (InAxisValue == 0 && ResultAxisValue * CurrentAxisValue < 0)
    {
        ResultAxisValue = InAxisValue;
    }

    CurrentAxisValue = ResultAxisValue;
    return CurrentAxisValue;
}